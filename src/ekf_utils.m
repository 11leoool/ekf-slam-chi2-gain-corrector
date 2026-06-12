% EKF_UTILS - Shared utility functions for EKF-SLAM filters
%
% These functions are called by run_nominal_ekf, run_proposed_corrector,
% run_mlp_corrector, and run_sage_husa_full. Place them on the MATLAB path
% as a single file, or split into individual files of the same names.

% ====================================================================
% PREDICT STEP
% ====================================================================
function [x_pred, P_pred] = ekf_predict_step(x, P, u, Q, dt) %#ok<DEFNU>
    % Unicycle motion model. Only the pose (first 3 dims) evolves.
    v = u(1); omega = u(2); theta = x(3);
    state_dim = length(x);
    M = (state_dim - 3) / 2;

    % State prediction
    x_pred = x;
    x_pred(1) = x(1) + v * cos(theta) * dt;
    x_pred(2) = x(2) + v * sin(theta) * dt;
    x_pred(3) = wrapToPiLocal(x(3) + omega * dt);

    % Jacobian F (state transition)
    F = eye(state_dim);
    F(1, 3) = -v * sin(theta) * dt;
    F(2, 3) =  v * cos(theta) * dt;

    % Process noise mapping (only affects pose)
    G = zeros(state_dim, 3);
    G(1:3, 1:3) = eye(3);

    P_pred = F * P * F' + G * Q * G';
    P_pred = 0.5 * (P_pred + P_pred');
end

% ====================================================================
% INNOVATION (no update applied) - used by gate-then-correct logic
% ====================================================================
function [nu, S, K, H] = ekf_innovation(x, P, z, lm_idx, R) %#ok<DEFNU>
    state_dim = length(x);
    pose = x(1:3);
    lm = x(3 + 2*lm_idx - 1 : 3 + 2*lm_idx);

    dx = lm(1) - pose(1);
    dy = lm(2) - pose(2);
    q = dx^2 + dy^2;
    r = sqrt(q);

    % Predicted measurement
    z_pred = [r; wrapToPiLocal(atan2(dy, dx) - pose(3))];

    % Innovation (wrap bearing)
    nu = z - z_pred;
    nu(2) = wrapToPiLocal(nu(2));

    % Measurement Jacobian (2 x state_dim)
    H = zeros(2, state_dim);
    H(1, 1) = -dx/r;
    H(1, 2) = -dy/r;
    H(1, 3 + 2*lm_idx - 1) = dx/r;
    H(1, 3 + 2*lm_idx)     = dy/r;
    H(2, 1) =  dy/q;
    H(2, 2) = -dx/q;
    H(2, 3) = -1;
    H(2, 3 + 2*lm_idx - 1) = -dy/q;
    H(2, 3 + 2*lm_idx)     =  dx/q;

    S = H * P * H' + R;
    K = P * H' / S;
end

% ====================================================================
% UPDATE STEP (standard)
% ====================================================================
function [x_post, P_post] = ekf_update_step(x, P, z, lm_idx, R) %#ok<DEFNU>
    [nu, ~, K, H] = ekf_innovation(x, P, z, lm_idx, R);
    state_dim = length(x);

    x_post = x + K * nu;
    x_post(3) = wrapToPiLocal(x_post(3));  % wrap heading

    % Joseph form for numerical stability
    I_KH = eye(state_dim) - K * H;
    P_post = I_KH * P * I_KH' + K * R * K';
    P_post = 0.5 * (P_post + P_post');
end

% ====================================================================
% UPDATE STEP WITH GAIN SCALING (for proposed and MLP correctors)
% ====================================================================
function [x_post, P_post] = ekf_update_step_scaled(x, P, z, lm_idx, R, s) %#ok<DEFNU>
    [nu, ~, K, H] = ekf_innovation(x, P, z, lm_idx, R);
    state_dim = length(x);

    K_scaled = s * K;
    x_post = x + K_scaled * nu;
    x_post(3) = wrapToPiLocal(x_post(3));

    % Joseph form with scaled gain
    I_KH = eye(state_dim) - K_scaled * H;
    P_post = I_KH * P * I_KH' + K_scaled * R * K_scaled';
    P_post = 0.5 * (P_post + P_post');
end

% ====================================================================
% HELPER
% ====================================================================
function a = wrapToPiLocal(a) %#ok<DEFNU>
    a = atan2(sin(a), cos(a));
end
