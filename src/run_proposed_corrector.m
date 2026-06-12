function [x_hist, P_hist, gate_active] = run_proposed_corrector(sim, landmarks, Q, R, opts)
% RUN_PROPOSED_CORRECTOR - EKF-SLAM with chi-squared gated gain correction
%
% INPUTS:
%   sim        - output of simulate_trajectory or simulate_trajectory_nonstationary
%   landmarks  - [M x 2] true landmark positions (init only)
%   Q, R       - nominal noise covariances
%   opts       - (optional) struct with the following fields:
%                  .gate_threshold  scalar threshold tau (default 1.45)
%                  .clamp_min       lower bound on gain multiplier s (default 0.15)
%                  .clamp_max       upper bound on gain multiplier s (default 1.00)
%                  .meas_dim        measurement dimension per landmark (default 2)
%
% OUTPUTS:
%   x_hist, P_hist, gate_active - standard outputs (see run_nominal_ekf)
%
% NOTE:
%   The gate threshold tau corresponds to a quantile of chi-squared(d)/d under
%   matched noise, with d = meas_dim * N_t (effective measurement dimension).
%   The default tau = 1.45 was empirically calibrated for d = 6 (three 2D
%   landmark observations). For other d, use compute_gate_threshold.m to
%   pick an appropriate tau.
%
% BACKWARD COMPATIBILITY:
%   Existing callers using the 4-argument signature continue to work unchanged.

    % --- Optional argument handling ---
    if nargin < 5, opts = struct(); end
    if ~isfield(opts, 'gate_threshold'), opts.gate_threshold = 1.45; end
    if ~isfield(opts, 'clamp_min'),      opts.clamp_min      = 0.15; end
    if ~isfield(opts, 'clamp_max'),      opts.clamp_max      = 1.00; end
    if ~isfield(opts, 'meas_dim'),       opts.meas_dim       = 2;    end

    tau      = opts.gate_threshold;
    s_min    = opts.clamp_min;
    s_max    = opts.clamp_max;
    meas_dim = opts.meas_dim;

    % --- Setup ---
    [T, M, ~] = size(sim.observations);
    state_dim = 3 + 2*M;
    dt = sim.dt;

    x = zeros(state_dim, 1);
    x(1:3) = sim.initial_pose;
    x(4:end) = reshape(landmarks', [], 1);
    P = blkdiag(0.001*eye(3), 1.0*eye(2*M));

    x_hist = zeros(T, state_dim);
    P_hist = zeros(state_dim, state_dim, T);
    gate_active = false(T, 1);

    for t = 1:T
        % --- Predict ---
        u = sim.controls_noisy(t, :)';
        [x, P] = ekf_predict_step(x, P, u, Q, dt);

        % --- First pass: normalised global NIS ---
        nis_sum = 0;
        total_dof = 0;
        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [nu, S, ~, ~] = ekf_innovation(x, P, z, i, R);
                nis_sum = nis_sum + nu' * (S \ nu);
                total_dof = total_dof + meas_dim;
            end
        end

        if total_dof > 0
            chi2_global = nis_sum / total_dof;
        else
            chi2_global = 0;
        end

        % --- Gate decision ---
        if chi2_global >= tau
            s = max(min(1/chi2_global, s_max), s_min);
            gate_active(t) = true;
        else
            s = 1.0;
        end

        % --- Second pass: apply scaled updates (Joseph form inside) ---
        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [x, P] = ekf_update_step_scaled(x, P, z, i, R, s);
            end
        end

        x_hist(t, :) = x';
        P_hist(:, :, t) = P;
    end
end
