function [nees_avg, nees_per_step, in_bounds_fraction] = compute_nees(x_true_hist, x_est_hist, P_hist, conf_level)
% COMPUTE_NEES - Normalised Estimation Error Squared for pose consistency
%
% Computes the standard SLAM consistency metric NEES for the pose subset
% of the state vector. Under a consistent filter with N Monte Carlo runs,
% the average NEES should fall within the chi-squared confidence bounds
% with N*pose_dim degrees of freedom.
%
% INPUTS:
%   x_true_hist - [T x state_dim] ground truth state history
%   x_est_hist  - [T x state_dim] estimated state history
%   P_hist      - [state_dim x state_dim x T] covariance history
%   conf_level  - Confidence level (e.g., 0.95)
%
% OUTPUTS:
%   nees_avg            - Mean NEES across all timesteps
%   nees_per_step       - [T x 1] NEES at each timestep
%   in_bounds_fraction  - Fraction of timesteps within chi-squared bounds
%
% NOTES:
%   - Operates on the first 3 state dimensions (pose: x, y, theta)
%   - Heading angle differences are wrapped to [-pi, pi]
%   - A consistent filter has NEES ~ chi-squared(pose_dim) per step

    if nargin < 4
        conf_level = 0.95;
    end

    T = size(x_true_hist, 1);
    pose_dim = 3;
    nees_per_step = zeros(T, 1);

    for t = 1:T
        % Pose error (first 3 dims)
        err = x_true_hist(t, 1:3)' - x_est_hist(t, 1:3)';

        % Wrap heading error to [-pi, pi]
        err(3) = atan2(sin(err(3)), cos(err(3)));

        % Pose covariance (top-left 3x3 block)
        P_pose = P_hist(1:3, 1:3, t);

        % Regularise for numerical safety
        P_pose = P_pose + 1e-9 * eye(3);

        % NEES at this step
        nees_per_step(t) = err' * (P_pose \ err);
    end

    nees_avg = mean(nees_per_step);

    % Chi-squared bounds for single-step NEES
    alpha = 1 - conf_level;
    lower_bound = chi2inv(alpha/2, pose_dim);
    upper_bound = chi2inv(1 - alpha/2, pose_dim);

    in_bounds = (nees_per_step >= lower_bound) & (nees_per_step <= upper_bound);
    in_bounds_fraction = mean(in_bounds);

end
