function [x_pred, P_pred] = ekf_predict_step(x, P, u, Q, dt)
% EKF_PREDICT_STEP - Unicycle motion prediction for EKF-SLAM
%
% Only the pose (first 3 dims) evolves; landmark positions are static.
%
% INPUTS:
%   x   - Current state [n x 1]
%   P   - Current covariance [n x n]
%   u   - Control input [v; omega]
%   Q   - Process noise covariance (3x3, pose only)
%   dt  - Timestep
%
% OUTPUTS:
%   x_pred - Predicted state
%   P_pred - Predicted covariance

    v = u(1); omega = u(2); theta = x(3);
    state_dim = length(x);

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

function a = wrapToPiLocal(a)
    a = atan2(sin(a), cos(a));
end
