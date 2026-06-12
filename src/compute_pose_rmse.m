function rmse = compute_pose_rmse(waypoints, x_hist)
% COMPUTE_POSE_RMSE - Root mean square error of pose against ground truth
%
% INPUTS:
%   waypoints - [T x 3] ground truth poses
%   x_hist    - [T x state_dim] estimated state history (pose in first 3 cols)
%
% OUTPUTS:
%   rmse      - Scalar RMSE in metres (position-only, x and y components)
%
% NOTES:
%   This is the position RMSE (sqrt of mean squared (x,y) error). For
%   full pose RMSE including heading, modify accordingly. Heading errors
%   are not directly comparable to position errors in metres.

    T = size(waypoints, 1);
    err_x = waypoints(:, 1) - x_hist(:, 1);
    err_y = waypoints(:, 2) - x_hist(:, 2);

    sq_err = err_x.^2 + err_y.^2;
    rmse = sqrt(mean(sq_err));
end
