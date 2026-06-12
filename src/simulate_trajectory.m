function sim = simulate_trajectory(waypoints, controls, landmarks, Q_true, R_true, config)
% SIMULATE_TRAJECTORY - Generate noisy data along a ground-truth path
%
% INPUTS:
%   waypoints  - [T x 3] ground truth poses
%   controls   - [T x 2] nominal control inputs [v, omega]
%   landmarks  - [M x 2] landmark positions
%   Q_true     - True process noise covariance (3x3)
%   R_true     - True measurement noise covariance (2x2)
%   config     - Struct with .dt, .max_range, .visibility_fov
%
% OUTPUTS:
%   sim.observations    - [T x M x 2] range and bearing per landmark
%   sim.visibility      - [T x M] logical, true if landmark visible
%   sim.controls_noisy  - [T x 2] noisy control inputs
%   sim.initial_pose    - [3 x 1] first ground truth pose (for filter init)
%   sim.dt              - timestep duration (forwarded to filters)

    T = size(waypoints, 1);
    M = size(landmarks, 1);

    % Defaults
    if ~isfield(config, 'max_range'),     config.max_range = 50.0; end
    if ~isfield(config, 'visibility_fov'), config.visibility_fov = 2*pi; end
    if ~isfield(config, 'dt'),            config.dt = 0.05; end

    sim.observations    = zeros(T, M, 2);
    sim.visibility      = false(T, M);
    sim.controls_noisy  = zeros(T, 2);
    sim.initial_pose    = waypoints(1, :)';
    sim.dt              = config.dt;

    % --- Noisy control inputs ---
    L_Q = chol(Q_true(1:2, 1:2) + 1e-12*eye(2), 'lower');
    for t = 1:T
        w = L_Q * randn(2, 1);
        sim.controls_noisy(t, :) = controls(t, :) + w';
    end

    % --- Noisy observations per landmark per timestep ---
    L_R = chol(R_true + 1e-12*eye(2), 'lower');
    for t = 1:T
        pose = waypoints(t, :);
        for i = 1:M
            dx = landmarks(i, 1) - pose(1);
            dy = landmarks(i, 2) - pose(2);
            range = sqrt(dx^2 + dy^2);
            bearing = wrapToPiLocal(atan2(dy, dx) - pose(3));

            if range <= config.max_range && abs(bearing) <= config.visibility_fov/2
                v = L_R * randn(2, 1);
                sim.observations(t, i, 1) = range + v(1);
                sim.observations(t, i, 2) = wrapToPiLocal(bearing + v(2));
                sim.visibility(t, i) = true;
            end
        end
    end

end

function a = wrapToPiLocal(a)
    a = atan2(sin(a), cos(a));
end
