function out = run_filter_da(mode, sim, landmarks, Q, R, opts)
% RUN_FILTER_DA - Unified EKF-SLAM runner with nearest-neighbour data association
%
% Regime IV (realistic validation) runner: the filter receives the per-step
% observation SET without correspondence and must associate each observation
% to a landmark itself via Mahalanobis nearest-neighbour with a chi2(2) gate.
% True identities are used ONLY to score misassociation, never by the filter.
%
% Supports all four filters in one loop (they differ only in actuation):
%   'nominal'         - plain EKF
%   'sage_husa'       - sliding-window R adaptation (W=20 innov., warmup 30,
%                       rate 0.05, eigenvalue floor 0.25*R) [run_sage_husa_full]
%   'strong_tracking' - immediate trace-ratio fading factor, pose-block-only
%                       inflation (rho_f=0.95, lambda_max=5) [run_strong_tracking]
%   'proposed'        - chi-squared gated gain corrector, with the gate
%                       threshold recalibrated per step to the effective
%                       measurement dimension d = 2*N_t via
%                       compute_gate_threshold (Sec. 3.4.2 recipe)
%
% INPUTS:
%   mode      - filter name (above)
%   sim       - output of simulate_trajectory / *_nonstationary
%   landmarks - [M x 2] true landmark positions (state init only)
%   Q, R      - nominal noise covariances
%   opts      - optional struct:
%                 .da_gate        chi2 gate for association (default chi2inv(0.99,2))
%                 .ftr            target false-trigger rate for tau(d) (default 0.10)
%                 .adaptive_tau   recalibrate tau per step (default true)
%                 .tau_fixed      fixed tau if adaptive_tau=false (default 1.45)
%                 .clamp_min      gain floor (default 0.15)
%                 .rho_f          STF forgetting (default 0.95)
%                 .lambda_max     STF cap (default 5)
%
% OUTPUT struct:
%   .x_hist       [T x n] state history
%   .P_pose_hist  [3 x 3 x T] pose covariance history (for compute_nees)
%   .gate_active  [T x 1] corrector / fading engaged
%   .n_assigned, .n_misassoc, .n_dropped, .n_visible   per-step counts [T x 1]

    if nargin < 6, opts = struct(); end
    if ~isfield(opts, 'da_gate'),      opts.da_gate      = chi2inv(0.99, 2); end
    if ~isfield(opts, 'ftr'),          opts.ftr          = 0.10; end
    if ~isfield(opts, 'adaptive_tau'), opts.adaptive_tau = true; end
    if ~isfield(opts, 'tau_fixed'),    opts.tau_fixed    = 1.45; end
    if ~isfield(opts, 'clamp_min'),    opts.clamp_min    = 0.15; end
    if ~isfield(opts, 'rho_f'),        opts.rho_f        = 0.95; end
    if ~isfield(opts, 'lambda_max'),   opts.lambda_max   = 5; end
    % --- v2 extensions (default OFF: behaviour identical to v1) ---
    % D: widen the association gate by the previous step's chi2_global
    %    (same mismatch signal, second actuation point; no estimation).
    if ~isfield(opts, 'da_widen'),     opts.da_widen     = false; end
    if ~isfield(opts, 'kappa_max'),    opts.kappa_max    = 10; end
    % B: two-sided gate — amplify the gain when chi2_global is far BELOW 1
    %    (measurements trusted too little), s in (1, s_max].
    %    Conservative defaults: the gate's own selection effect fattens the
    %    LOWER tail of chi2_global (Sec. 3.4.2), so the lower threshold uses
    %    a much stricter quantile than the upper one, and the amplification
    %    is capped low — s_max = 3 with ftr_lo = 0.10 diverges.
    if ~isfield(opts, 'two_sided'),    opts.two_sided    = false; end
    if ~isfield(opts, 's_max'),        opts.s_max        = 1.5; end
    if ~isfield(opts, 'ftr_lo'),       opts.ftr_lo       = 0.02; end

    [T, M, ~] = size(sim.observations);
    n = 3 + 2 * M;
    dt = sim.dt;
    trR = trace(R);

    % --- Sage-Husa adaptation parameters (mirror run_sage_husa_full) ---
    SH_WINDOW = 20; SH_WARMUP = 30; SH_RATE = 0.05; SH_FLOOR = 0.25;

    if ~isfield(opts, 'P_lm0'), opts.P_lm0 = 0.1; end   % landmark prior var (m^2)
    x = zeros(n, 1);
    x(1:3) = sim.initial_pose;
    x(4:end) = reshape(landmarks', [], 1);
    % Landmark prior: surveyed map with ~0.3 m std. A loose 1 m prior (as in
    % the known-correspondence regimes) makes the chi2(2) association gate
    % accept 2-3 m neighbours and the experiment measures DA collapse rather
    % than noise adaptation.
    P = blkdiag(0.001 * eye(3), opts.P_lm0 * eye(2 * M));

    R_hat = R;
    R_floor_eigs = SH_FLOOR * diag(R);
    nu_buf = zeros(2, SH_WINDOW); hph_buf = zeros(2, 2, SH_WINDOW);
    buf_n = 0; buf_i = 0;

    n_bar = 0; have_nbar = false;          % STF smoothed excess power

    % tau(d) cache: tau_cache(N) for N assigned landmarks (d = 2N)
    tau_cache = zeros(1, M);
    tau_lo_cache = zeros(1, M);
    for N = 1:M
        tau_cache(N) = compute_gate_threshold(2 * N, opts.ftr);
        tau_lo_cache(N) = chi2inv(opts.ftr_lo, 2 * N) / (2 * N);   % lower tail
    end
    chi2_prev = 1.0;     % previous step's chi2_global (for da_widen)

    out.x_hist      = zeros(T, n);
    out.P_pose_hist = zeros(3, 3, T);
    out.gate_active = false(T, 1);
    out.n_assigned  = zeros(T, 1);
    out.n_misassoc  = zeros(T, 1);
    out.n_dropped   = zeros(T, 1);
    out.n_visible   = zeros(T, 1);
    out.diverged    = false;

    for t = 1:T
        % ---------- Predict ----------
        u = sim.controls_noisy(t, :)';
        [x, P] = ekf_predict_step(x, P, u, Q, dt);

        vis = find(sim.visibility(t, :));
        nv = numel(vis);
        out.n_visible(t) = nv;

        if nv == 0
            out.x_hist(t, :) = x';
            out.P_pose_hist(:, :, t) = P(1:3, 1:3);
            continue;
        end

        Z = reshape(sim.observations(t, vis, :), nv, 2);   % [nv x 2]
        R_eff = R; if strcmp(mode, 'sage_husa'), R_eff = R_hat; end

        % ---------- Candidate predictions for ALL landmarks (prior) ----------
        zp = zeros(2, M); Sc = zeros(2, 2, M); hph_tr = zeros(1, M);
        for i = 1:M
            [zp(:, i), Hs, idx] = predict_meas(x, i);
            Sc(:, :, i) = Hs * P(idx, idx) * Hs' + R_eff;
            hph_tr(i) = trace(Sc(:, :, i)) - trace(R_eff);
        end

        % ---------- Greedy Mahalanobis NN association (one-to-one) ----------
        % v2-D: widen the gate by the previous step's chi2_global (clamped),
        % i.e. test nu' (kappa*S)^-1 nu <= gamma  <=>  d2 <= gamma * kappa.
        if opts.da_widen
            gate_thr = opts.da_gate * min(max(chi2_prev, 1), opts.kappa_max);
        else
            gate_thr = opts.da_gate;
        end
        assign = zeros(nv, 1);            % landmark index or 0 (dropped)
        d2_a = zeros(nv, 1);
        nu_a = zeros(2, nv);
        taken = false(M, 1);
        for j = 1:nv
            best_d2 = inf; best_i = 0; best_nu = [0; 0];
            for i = 1:M
                if taken(i), continue; end
                nu = Z(j, :)' - zp(:, i);
                nu(2) = atan2(sin(nu(2)), cos(nu(2)));
                d2 = nu' * (Sc(:, :, i) \ nu);
                if d2 < best_d2
                    best_d2 = d2; best_i = i; best_nu = nu;
                end
            end
            if best_i > 0 && best_d2 <= gate_thr
                assign(j) = best_i; taken(best_i) = true;
                d2_a(j) = best_d2; nu_a(:, j) = best_nu;
            end
        end

        A = find(assign > 0);
        N_a = numel(A);
        out.n_assigned(t) = N_a;
        out.n_dropped(t) = nv - N_a;
        out.n_misassoc(t) = sum(assign(A) ~= vis(A)');

        % ---------- Mode-specific pre-update actuation ----------
        s = 1.0;
        if N_a > 0
            chi2g = sum(d2_a(A)) / (2 * N_a);
            chi2_prev = chi2g;
            switch mode
                case 'proposed'
                    if opts.adaptive_tau
                        tau_t = tau_cache(N_a);
                    else
                        tau_t = opts.tau_fixed;
                    end
                    if chi2g >= tau_t
                        s = max(min(1 / chi2g, 1.0), opts.clamp_min);
                        out.gate_active(t) = true;
                    elseif opts.two_sided && chi2g > 0 && chi2g <= tau_lo_cache(N_a)
                        % v2-B: measurements trusted too little -> amplify gain
                        s = min(1 / chi2g, opts.s_max);
                        out.gate_active(t) = true;
                    end
                case 'strong_tracking'
                    n_t = 0;
                    for j = A'
                        n_t = n_t + nu_a(:, j)' * nu_a(:, j);
                    end
                    n_t = max(n_t - N_a * trR, 0);
                    if have_nbar
                        n_bar = (opts.rho_f * n_bar + n_t) / (1 + opts.rho_f);
                    else
                        n_bar = n_t; have_nbar = true;
                    end
                    m_t = sum(hph_tr(assign(A)));
                    if m_t > 0
                        lam = min(max(1, n_bar / m_t), opts.lambda_max);
                        if lam > 1
                            d = ones(n, 1); d(1:3) = sqrt(lam);
                            P = (d * d') .* P;
                            P = 0.5 * (P + P');
                            out.gate_active(t) = true;
                        end
                    end
            end
        end

        % ---------- Sequential updates over associated pairs ----------
        P_prior_hph = zeros(2, 2, N_a);    % for Sage-Husa buffer (prior HPH')
        for k = 1:N_a
            j = A(k); i = assign(j);
            P_prior_hph(:, :, k) = Sc(:, :, i) - R_eff;

            [zpi, Hs, idx] = predict_meas(x, i);
            nu = Z(j, :)' - zpi;
            nu(2) = atan2(sin(nu(2)), cos(nu(2)));
            HP = Hs * P(idx, :);                 % 2 x n
            S = HP(:, idx) * Hs' + R_eff;
            K = HP' / S;                         % n x 2
            x = x + s * (K * nu);
            x(3) = atan2(sin(x(3)), cos(x(3)));
            KHP = K * HP;
            P = P - s * KHP - s * KHP' + (s^2) * (K * S * K');
            P = 0.5 * (P + P');

            if strcmp(mode, 'sage_husa')
                buf_i = mod(buf_i, SH_WINDOW) + 1;
                nu_buf(:, buf_i) = nu;
                hph_buf(:, :, buf_i) = P_prior_hph(:, :, k);
                buf_n = min(buf_n + 1, SH_WINDOW);
            end
        end

        % ---------- Sage-Husa R adaptation ----------
        if strcmp(mode, 'sage_husa') && t > SH_WARMUP && buf_n >= SH_WINDOW
            nu_nu = (nu_buf * nu_buf') / buf_n;
            hph_avg = mean(hph_buf(:, :, 1:buf_n), 3);
            R_new = nu_nu - hph_avg;
            R_new = 0.5 * (R_new + R_new');
            [V, D] = eig(R_new);
            dd = max(diag(D), R_floor_eigs);
            R_new = V * diag(dd) * V';
            R_new = 0.5 * (R_new + R_new');
            R_hat = (1 - SH_RATE) * R_hat + SH_RATE * R_new;
            R_hat = 0.5 * (R_hat + R_hat');
        end

        % ---------- Divergence guard ----------
        % If the state or covariance has gone non-finite, freeze at the last
        % finite estimate for the rest of the run. Divergence then shows up
        % as a large-but-finite RMSE plus the diverged flag, instead of NaNs
        % poisoning downstream statistics.
        if ~all(isfinite(x)) || ~all(isfinite(P(:)))
            out.diverged = true;
            if t > 1
                x_frozen = out.x_hist(t - 1, :);
                P_frozen = out.P_pose_hist(:, :, t - 1);
            else
                x_frozen = zeros(1, n);
                P_frozen = eye(3);
            end
            for tt = t:T
                out.x_hist(tt, :) = x_frozen;
                out.P_pose_hist(:, :, tt) = P_frozen;
            end
            return;
        end

        out.x_hist(t, :) = x';
        out.P_pose_hist(:, :, t) = P(1:3, 1:3);
    end
end

% ====================================================================
function [z_pred, Hs, idx] = predict_meas(x, lm_idx)
% Predicted range-bearing measurement + sparse 2x5 Jacobian for landmark i.
    idx = [1, 2, 3, 3 + 2 * lm_idx - 1, 3 + 2 * lm_idx];
    dx = x(idx(4)) - x(1);
    dy = x(idx(5)) - x(2);
    q = dx^2 + dy^2;
    r = sqrt(q);
    b = atan2(dy, dx) - x(3);
    z_pred = [r; atan2(sin(b), cos(b))];
    Hs = [-dx/r, -dy/r,  0,  dx/r, dy/r;
           dy/q, -dx/q, -1, -dy/q, dx/q];
end
