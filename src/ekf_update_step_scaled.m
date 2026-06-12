function [x_post, P_post] = ekf_update_step_scaled(x, P, z, lm_idx, R, s)
% EKF_UPDATE_STEP_SCALED - EKF-SLAM measurement update with scaled Kalman gain
%
% Multiplies the Kalman gain by scalar s before applying the update.
% Used by the proposed chi-squared corrector and the MLP corrector.
%
% INPUTS:
%   x, P, z, lm_idx, R - See ekf_innovation
%   s                  - Scalar gain multiplier in (0, 1]
%
% OUTPUTS:
%   x_post - Updated state
%   P_post - Updated covariance

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

function a = wrapToPiLocal(a)
    a = atan2(sin(a), cos(a));
end
