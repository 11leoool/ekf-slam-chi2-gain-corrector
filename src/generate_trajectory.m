function [waypoints, controls] = generate_trajectory(type, T, dt, params)
% GENERATE_TRAJECTORY - Produce ground-truth path and control inputs
%
% Generates a smooth trajectory of T timesteps and the corresponding
% (v, omega) control inputs for a unicycle robot.
%
% INPUTS:
%   type   - 'circular' | 'figure8' | 'straight'
%   T      - Number of timesteps
%   dt     - Timestep duration (seconds)
%   params - Struct with type-specific parameters:
%              .radius (for circular)
%              .a, .b (for figure8 amplitudes)
%              .v0 (for straight-line speed)
%
% OUTPUTS:
%   waypoints - [T x 3] ground truth poses [x, y, theta]
%   controls  - [T x 2] control inputs [v, omega]

    if nargin < 4
        params = struct();
    end

    waypoints = zeros(T, 3);
    controls  = zeros(T, 2);

    switch lower(type)

        % ----------------------------------------------------------------
        case 'circular'
            if ~isfield(params, 'radius'), params.radius = 5.0; end
            R     = params.radius;
            v     = 2 * pi * R / (T * dt);     % full lap in T steps
            omega = v / R;
            theta = 0;
            x = R; y = 0;                       % start at (R, 0)
            for t = 1:T
                waypoints(t, :) = [x, y, theta];
                controls(t, :)  = [v, omega];
                x = x + v * cos(theta) * dt;
                y = y + v * sin(theta) * dt;
                theta = wrapToPi(theta + omega * dt);
            end

        % ----------------------------------------------------------------
        case 'figure8'
            if ~isfield(params, 'a'), params.a = 5.0; end
            if ~isfield(params, 'b'), params.b = 2.5; end
            a = params.a; b = params.b;
            for t = 1:T
                s = 2 * pi * t / T;             % parameter along curve
                x =  a * sin(s);
                y =  b * sin(2 * s);
                % Heading from path tangent
                dx =  a * cos(s) * (2*pi/T);
                dy =  b * 2 * cos(2*s) * (2*pi/T);
                theta = atan2(dy, dx);
                waypoints(t, :) = [x, y, theta];
            end
            % Compute v, omega from differences
            for t = 1:T-1
                dpos = norm(waypoints(t+1, 1:2) - waypoints(t, 1:2));
                controls(t, 1) = dpos / dt;
                dtheta = wrapToPi(waypoints(t+1, 3) - waypoints(t, 3));
                controls(t, 2) = dtheta / dt;
            end
            controls(T, :) = controls(T-1, :);

        % ----------------------------------------------------------------
        case 'straight'
            if ~isfield(params, 'v0'), params.v0 = 1.0; end
            v = params.v0;
            omega = 0;
            theta = 0;
            x = 0; y = 0;
            for t = 1:T
                waypoints(t, :) = [x, y, theta];
                controls(t, :)  = [v, omega];
                x = x + v * cos(theta) * dt;
                y = y + v * sin(theta) * dt;
            end

        otherwise
            error('Unknown trajectory type: %s', type);
    end

end

function a = wrapToPi(a)
    a = atan2(sin(a), cos(a));
end
