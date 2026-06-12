function sim = simulate_trajectory_nonstationary(waypoints, controls, landmarks, ...
    Q_nominal, R_nominal, alpha_schedule, mismatch_type, config)
% SIMULATE_TRAJECTORY_NONSTATIONARY - Per-timestep mismatch generation
%
% Like simulate_trajectory but accepts a [T x 1] alpha_schedule that defines
% the mismatch factor at each timestep. Lets you study non-stationary noise:
% sudden changes, ramps, transient events.
%
% INPUTS:
%   waypoints       - [T x 3] ground truth poses
%   controls        - [T x 2] nominal control inputs [v, omega]
%   landmarks       - [M x 2] landmark positions
%   Q_nominal       - Filter's assumed process noise (3x3)
%   R_nominal       - Filter's assumed measurement noise (2x2)
%   alpha_schedule  - [T x 1] mismatch factor at each timestep
%   mismatch_type   - 'symmetric' | 'Q_only' | 'R_only' | 'none'
%   config          - .dt, .max_range, .visibility_fov
%
% OUTPUTS:
%   sim.observations    - [T x M x 2]
%   sim.visibility      - [T x M] logical
%   sim.controls_noisy  - [T x 2]
%   sim.initial_pose    - [3 x 1]
%   sim.dt              - scalar
%   sim.alpha_schedule  - [T x 1] (echoed for downstream analysis)

    T = size(waypoints, 1);
    M = size(landmarks, 1);

    if length(alpha_schedule) ~= T
        error('alpha_schedule length (%d) must match number of timesteps (%d)', ...
              length(alpha_schedule), T);
    end

    if ~isfield(config, 'max_range'),     config.max_range = 50.0; end
    if ~isfield(config, 'visibility_fov'), config.visibility_fov = 2*pi; end
    if ~isfield(config, 'dt'),            config.dt = 0.05; end

    sim.observations    = zeros(T, M, 2);
    sim.visibility      = false(T, M);
    sim.controls_noisy  = zeros(T, 2);
    sim.initial_pose    = waypoints(1, :)';
    sim.dt              = config.dt;
    sim.alpha_schedule  = alpha_schedule;

    for t = 1:T
        % --- Apply mismatch for this timestep ---
        [Q_t, R_t] = apply_mismatch(Q_nominal, R_nominal, alpha_schedule(t), mismatch_type);

        % --- Noisy control input ---
        L_Q = chol(Q_t(1:2, 1:2) + 1e-12*eye(2), 'lower');
        w = L_Q * randn(2, 1);
        sim.controls_noisy(t, :) = controls(t, :) + w';

        % --- Noisy observations ---
        L_R = chol(R_t + 1e-12*eye(2), 'lower');
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
