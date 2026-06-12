function [x_hist, P_hist, gate_active] = run_sage_husa_full(sim, landmarks, Q_init, R_init)
% RUN_SAGE_HUSA_FULL - EKF-SLAM with Sage-Husa adaptive R estimation
%
% Adapts the measurement noise covariance R online using a sliding-window
% Sage-Husa estimator with conservative safeguards. Q is held fixed
% (Q adaptation in SLAM is well-known to be unstable due to map-state
% contamination).
%
% Safeguards used in this implementation:
%   - Warm-up period before adaptation begins
%   - Sliding-window innovation aggregation (not single-sample)
%   - R_hat lower bound at fraction of R_init to prevent collapse
%   - Innovation statistics computed using prior P (not updated P)
%
% INPUTS/OUTPUTS: Same signature as run_nominal_ekf.
%
% REFERENCE:
%   Sage, A.P.; Husa, G.W. Adaptive Filtering with Unknown Prior Statistics.
%   Joint Automatic Control Conference, 1969.

    % --- Adaptation parameters ---
    WINDOW_SIZE   = 20;     % innovations in the sliding window
    WARMUP_STEPS  = 30;     % no adaptation before this
    UPDATE_RATE   = 0.05;   % small step toward new R estimate per timestep
    R_FLOOR_RATIO = 0.25;   % R_hat eigenvalues can't shrink below this fraction of R_init

    [T, M, ~] = size(sim.observations);
    state_dim = 3 + 2*M;
    dt = sim.dt;

    % --- Initialise state, covariance, and adaptive estimate ---
    x = zeros(state_dim, 1);
    x(1:3) = sim.initial_pose;
    x(4:end) = reshape(landmarks', [], 1);
    P = blkdiag(0.001*eye(3), 1.0*eye(2*M));

    Q_hat = Q_init;          % held fixed
    R_hat = R_init;          % adapts over time

    % Compute the floor (minimum allowable R) eigenvalues
    R_floor_eigs = R_FLOOR_RATIO * diag(R_init);

    x_hist = zeros(T, state_dim);
    P_hist = zeros(state_dim, state_dim, T);
    gate_active = false(T, 1);

    % --- Sliding buffer for innovations and H*P*H' values ---
    nu_buffer = zeros(2, WINDOW_SIZE);
    hph_buffer = zeros(2, 2, WINDOW_SIZE);
    buf_count = 0;          % how many slots filled so far
    buf_idx = 0;            % circular buffer index

    for t = 1:T
        % --- Predict ---
        u = sim.controls_noisy(t, :)';
        [x, P] = ekf_predict_step(x, P, u, Q_hat, dt);

        % --- Save prior P (before any landmark updates) ---
        P_prior = P;

        % --- Sequential measurement updates ---
        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [nu, ~, K, H] = ekf_innovation(x, P, z, i, R_hat);

                % --- Standard update ---
                x = x + K * nu;
                x(3) = atan2(sin(x(3)), cos(x(3)));
                I_KH = eye(state_dim) - K * H;
                P = I_KH * P * I_KH' + K * R_hat * K';   % Joseph form
                P = 0.5 * (P + P');

                % --- Save innovation stats for R adaptation ---
                % Use the prior P (before this update step) for HPH'
                buf_idx = mod(buf_idx, WINDOW_SIZE) + 1;
                nu_buffer(:, buf_idx) = nu;
                hph_buffer(:, :, buf_idx) = H * P_prior * H';
                buf_count = min(buf_count + 1, WINDOW_SIZE);
            end
        end

        % --- Adapt R_hat from sliding window ---
        if t > WARMUP_STEPS && buf_count >= WINDOW_SIZE
            % Empirical innovation covariance over the window
            nu_nu_avg = (nu_buffer * nu_buffer') / buf_count;

            % Average H*P*H' over the window
            hph_avg = mean(hph_buffer(:, :, 1:buf_count), 3);

            % Sage-Husa R estimate: E[nu*nu'] - E[H*P*H']
            R_new = nu_nu_avg - hph_avg;
            R_new = 0.5 * (R_new + R_new');

            % Floor eigenvalues at fraction of R_init
            [V, D] = eig(R_new);
            d = diag(D);
            d = max(d, R_floor_eigs);
            R_new = V * diag(d) * V';
            R_new = 0.5 * (R_new + R_new');

            % Slow exponential update toward the new estimate
            R_hat = (1 - UPDATE_RATE) * R_hat + UPDATE_RATE * R_new;
            R_hat = 0.5 * (R_hat + R_hat');
        end

        x_hist(t, :) = x';
        P_hist(:, :, t) = P;
    end
end
