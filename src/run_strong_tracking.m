function [x_hist, P_hist, gate_active] = run_strong_tracking(sim, landmarks, Q, R, opts)
% RUN_STRONG_TRACKING - EKF-SLAM with a suboptimal fading factor (STF)
%
% Immediate-response analytical baseline from the strong-tracking /
% adaptive-fading family (Zhou & Frank 1996; Kim et al. 2009; Liang et
% al. 2018 for SLAM). At each step a fading factor lambda_t >= 1
% inflates the predicted covariance before the measurement updates:
%
%     P_t^- <- lambda_t * P_t^-
%
% lambda_t uses the textbook trace-ratio (suboptimal fading factor) with
% the standard exponential forgetting on the innovation power:
%
%     n_t      = sum_i ( nu_i' nu_i ) - N_t * tr(R)       (innovation power
%                                                          in excess of R)
%     n_bar_t  = (rho * n_bar_{t-1} + n_t) / (1 + rho)    (forgetting, rho=0.95)
%     m_t      = sum_i tr( H_i P_t^- H_i' )
%     lambda_t = min( max(1, n_bar_t / m_t), lambda_max )
%
% This is covariance matching on the HPH' term: lambda has a stable fixed
% point (lambda -> 1 once tr(HPH') accounts for the observed innovation
% power), responds within ~2 steps (effective memory of the forgetting
% recursion), needs no warm-up and no window. It is the immediate-response
% member of the classical adaptive family, in contrast to Sage-Husa's
% 30-step warm-up + 20-step window (revision item R2).
%
% Actuation contrast with the proposed corrector:
%     strong_tracking : inflate P  (gain indirectly adjusted via S)
%     proposed        : scale K by 1/chi2 (gain directly shrunk)
%
% INPUTS:
%   sim        - output of simulate_trajectory / *_nonstationary
%   landmarks  - [M x 2] true landmark positions (init only)
%   Q, R       - nominal noise covariances
% Fading is applied to the ROBOT POSE BLOCK only (cross-covariances scaled
% by sqrt(lambda) via D*P*D' with D = diag(sqrt(lambda)*I3, I), which keeps
% P positive semidefinite). Inflating the full SLAM covariance, landmark
% blocks included, is known to corrupt the map and destabilise the filter;
% pose-block (partial / multiple) fading is the standard remedy in the
% STF-SLAM literature (Liang et al. 2018).
%
%   opts       - (optional) .rho        forgetting factor (default 0.95)
%                           .lambda_max cap on fading factor (default 5)
%
% OUTPUTS: same signature as run_nominal_ekf; gate_active(t) is true when
%          lambda_t > 1 was applied.

    if nargin < 5, opts = struct(); end
    if ~isfield(opts, 'rho'),        opts.rho        = 0.95; end
    if ~isfield(opts, 'lambda_max'), opts.lambda_max = 5;    end

    rho        = opts.rho;
    lambda_max = opts.lambda_max;

    [T, M, ~] = size(sim.observations);
    state_dim = 3 + 2*M;
    dt = sim.dt;
    trR = trace(R);

    x = zeros(state_dim, 1);
    x(1:3) = sim.initial_pose;
    x(4:end) = reshape(landmarks', [], 1);
    P = blkdiag(0.001*eye(3), 1.0*eye(2*M));

    x_hist = zeros(T, state_dim);
    P_hist = zeros(state_dim, state_dim, T);
    gate_active = false(T, 1);

    n_bar = 0;            % smoothed excess innovation power
    have_nbar = false;

    for t = 1:T
        % --- Predict ---
        u = sim.controls_noisy(t, :)';
        [x, P] = ekf_predict_step(x, P, u, Q, dt);

        % --- Fading factor from stacked innovations (prior P) ---
        n_t = 0;          % innovation power in excess of R
        m_t = 0;          % tr(H P- H') aggregated over visible landmarks
        n_vis = 0;
        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [nu, ~, ~, H] = ekf_innovation(x, P, z, i, R);
                n_t = n_t + (nu' * nu);
                m_t = m_t + trace(H * P * H');
                n_vis = n_vis + 1;
            end
        end

        lambda = 1.0;
        if n_vis > 0
            n_t = max(n_t - n_vis * trR, 0);
            if have_nbar
                n_bar = (rho * n_bar + n_t) / (1 + rho);
            else
                n_bar = n_t;
                have_nbar = true;
            end
            if m_t > 0
                lambda = min(max(1, n_bar / m_t), lambda_max);
            end
        end

        % --- Inflate pose block of the predicted covariance (partial STF) ---
        if lambda > 1
            d = ones(state_dim, 1);
            d(1:3) = sqrt(lambda);
            P = (d * d') .* P;          % D*P*D' with D = diag(d)
            P = 0.5 * (P + P');
            gate_active(t) = true;
        end

        % --- Sequential measurement updates (Joseph form) ---
        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [nu, ~, K, H] = ekf_innovation(x, P, z, i, R);
                x = x + K * nu;
                x(3) = atan2(sin(x(3)), cos(x(3)));
                I_KH = eye(state_dim) - K * H;
                P = I_KH * P * I_KH' + K * R * K';
                P = 0.5 * (P + P');
            end
        end

        x_hist(t, :) = x';
        P_hist(:, :, t) = P;
    end
end
