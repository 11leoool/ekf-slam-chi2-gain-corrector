function [x_post, P_post] = ekf_update_step(x, P, z, lm_idx, R)
% EKF_UPDATE_STEP - Standard EKF-SLAM measurement update for one landmark
%
% Uses Joseph form covariance update for numerical stability.
%
% INPUTS:
%   x, P, z, lm_idx, R - See ekf_innovation
%
% OUTPUTS:
%   x_post - Updated state
%   P_post - Updated covariance

    [nu, ~, K, H] = ekf_innovation(x, P, z, lm_idx, R);
    state_dim = length(x);

    x_post = x + K * nu;
    x_post(3) = wrapToPiLocal(x_post(3));  % wrap heading

    % Joseph form for numerical stability
    I_KH = eye(state_dim) - K * H;
    P_post = I_KH * P * I_KH' + K * R * K';
    P_post = 0.5 * (P_post + P_post');
end

function a = wrapToPiLocal(a)
    a = atan2(sin(a), cos(a));
end
