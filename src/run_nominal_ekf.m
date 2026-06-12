function [x_hist, P_hist, gate_active] = run_nominal_ekf(sim, landmarks, Q, R)
% RUN_NOMINAL_EKF - Standard EKF-SLAM with no adaptive correction
%
% INPUTS:
%   sim       - Output of simulate_trajectory (includes initial_pose, dt)
%   landmarks - [M x 2] true landmark positions (used for init only)
%   Q, R      - Filter's assumed noise covariances
%
% OUTPUTS:
%   x_hist      - [T x (3+2M)] state estimate history
%   P_hist      - [(3+2M) x (3+2M) x T] covariance history
%   gate_active - [T x 1] always false (no gate in nominal filter)

    [T, M, ~] = size(sim.observations);
    state_dim = 3 + 2*M;
    dt = sim.dt;

    % --- Initialise state and covariance ---
    x = zeros(state_dim, 1);
    x(1:3) = sim.initial_pose;                      % start at ground truth pose
    x(4:end) = reshape(landmarks', [], 1);          % initialise landmarks at true pos
    P = blkdiag(0.001*eye(3), 1.0*eye(2*M));

    x_hist = zeros(T, state_dim);
    P_hist = zeros(state_dim, state_dim, T);
    gate_active = false(T, 1);

    for t = 1:T
        u = sim.controls_noisy(t, :)';
        [x, P] = ekf_predict_step(x, P, u, Q, dt);

        for i = 1:M
            if sim.visibility(t, i)
                z = squeeze(sim.observations(t, i, :));
                [x, P] = ekf_update_step(x, P, z, i, R);
            end
        end

        x_hist(t, :) = x';
        P_hist(:, :, t) = P;
    end
end
