function landmarks = generate_landmarks(count, trajectory, layout)
% GENERATE_LANDMARKS - Place landmarks around a trajectory
%
% Generates landmark positions that surround a given trajectory at a
% reasonable distance for range/bearing observation. Supports fixed,
% random, and ring layouts.
%
% INPUTS:
%   count      - Number of landmarks (3, 5, 10, etc.)
%   trajectory - [T x 3] ground truth trajectory (used for centering)
%   layout     - 'ring' (default) | 'random' | 'corners'
%
% OUTPUTS:
%   landmarks  - [count x 2] landmark positions [l_x, l_y]

    if nargin < 3
        layout = 'ring';
    end

    % Trajectory centroid and rough extent
    center = mean(trajectory(:, 1:2), 1);
    extent = max(max(trajectory(:, 1:2)) - min(trajectory(:, 1:2))) / 2;
    placement_radius = extent * 1.8;

    switch lower(layout)

        % ----------------------------------------------------------------
        case 'ring'
            % Evenly spaced around the trajectory at a fixed radius
            angles = linspace(0, 2*pi, count + 1);
            angles = angles(1:end-1);
            landmarks = zeros(count, 2);
            for i = 1:count
                landmarks(i, 1) = center(1) + placement_radius * cos(angles(i));
                landmarks(i, 2) = center(2) + placement_radius * sin(angles(i));
            end

        % ----------------------------------------------------------------
        case 'random'
            % Random placement within an annulus around the trajectory
            rng_state = rng;            % preserve user RNG state
            rng(42, 'twister');         % fixed seed for reproducibility
            angles = 2 * pi * rand(count, 1);
            radii  = placement_radius * (0.8 + 0.4 * rand(count, 1));
            landmarks = [center(1) + radii .* cos(angles), ...
                         center(2) + radii .* sin(angles)];
            rng(rng_state);             % restore

        % ----------------------------------------------------------------
        case 'corners'
            % Place at the "corners" of a bounding box around trajectory
            bb_x = [min(trajectory(:,1)) - 2, max(trajectory(:,1)) + 2];
            bb_y = [min(trajectory(:,2)) - 2, max(trajectory(:,2)) + 2];
            corners = [bb_x(1), bb_y(1);
                       bb_x(2), bb_y(1);
                       bb_x(2), bb_y(2);
                       bb_x(1), bb_y(2)];
            if count <= 4
                landmarks = corners(1:count, :);
            else
                % Add intermediate points
                landmarks = zeros(count, 2);
                landmarks(1:4, :) = corners;
                for i = 5:count
                    landmarks(i, :) = [bb_x(1) + rand*(bb_x(2)-bb_x(1)), ...
                                       bb_y(1) + rand*(bb_y(2)-bb_y(1))];
                end
            end

        otherwise
            error('Unknown landmark layout: %s', layout);
    end

end
