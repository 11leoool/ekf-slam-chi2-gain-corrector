function [nu, S, K, H] = ekf_innovation(x, P, z, lm_idx, R)
% EKF_INNOVATION - Compute innovation, innovation covariance, gain, and Jacobian
%
% For a single landmark observation. Does NOT apply the update.
% Used by gate-then-correct logic and by the standard update.
%
% INPUTS:
%   x       - Current state [n x 1]
%   P       - Current covariance [n x n]
%   z       - Observation [range; bearing]
%   lm_idx  - Landmark index (1-based)
%   R       - Measurement noise covariance (2x2)
%
% OUTPUTS:
%   nu - Innovation (with bearing wrapped to [-pi, pi])
%   S  - Innovation covariance
%   K  - Kalman gain (standard, before any scaling)
%   H  - Measurement Jacobian

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

function a = wrapToPiLocal(a)
    a = atan2(sin(a), cos(a));
end
