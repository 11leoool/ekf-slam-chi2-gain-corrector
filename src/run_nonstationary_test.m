% RUN_NONSTATIONARY_TEST - Non-stationary mismatch experiment
%
% Trajectory of 400 timesteps with a noise schedule:
%   Steps   1-100:  α = 1  (matched)
%   Steps 101-200:  α = 5  (sudden mismatch event)
%   Steps 201-300:  α = 1  (recovery)
%   Steps 301-400:  α = 3  (partial mismatch returns)
%
% Tests how quickly each filter adapts to non-stationary mismatch.
% Sage-Husa is expected to lag at each transition due to its sliding-window
% adaptation. The proposed corrector should react within one timestep.

clear; clc;
addpath(genpath(pwd));

% --- Configuration ---
T = 400;
dt = 0.05;
Q_nominal = diag([0.01, 0.01, 0.001]);
R_nominal = diag([0.04, 0.0025]);
num_trials = 30;
mismatch_type = 'symmetric';
filters = {'nominal', 'sage_husa', 'proposed'};

cfg.dt = dt;
cfg.max_range = 50.0;
cfg.visibility_fov = 2*pi;

% --- Noise schedule ---
alpha_schedule = ones(T, 1);
alpha_schedule(101:200) = 5;
alpha_schedule(201:300) = 1;
alpha_schedule(301:400) = 3;

% Segments for per-segment RMSE
segments = [1 100; 101 200; 201 300; 301 400];
seg_labels = {'α=1 (matched)', 'α=5 (jump)', 'α=1 (recover)', 'α=3 (mild)'};

% --- Generate trajectory once ---
[waypoints, controls] = generate_trajectory('circular', T, dt, struct());
landmarks = generate_landmarks(3, waypoints, 'ring');

% --- Storage ---
n_seg = size(segments, 1);
results = struct();
for fi = 1:length(filters)
    f = filters{fi};
    results.(f).rmse_per_segment = zeros(num_trials, n_seg);
    results.(f).rmse_total       = zeros(num_trials, 1);
    results.(f).rmse_per_step    = zeros(num_trials, T);
    results.(f).gate_active_step = zeros(num_trials, T);
end

% --- Monte Carlo trials ---
fprintf('=== Non-stationary mismatch test ===\n');
fprintf('Trajectory: 400 steps, schedule: 1 -> 5 -> 1 -> 3\n');
fprintf('Filters: %s\n', strjoin(filters, ', '));
fprintf('Trials per filter: %d\n\n', num_trials);

tic;
for trial = 1:num_trials
    rng(trial, 'twister');

    sim = simulate_trajectory_nonstationary(waypoints, controls, landmarks, ...
        Q_nominal, R_nominal, alpha_schedule, mismatch_type, cfg);

    for fi = 1:length(filters)
        f = filters{fi};
        [x_hist, ~, gate_active] = run_filter(f, sim, landmarks, Q_nominal, R_nominal);

        % Per-step RMSE
        err = waypoints(:, 1:2) - x_hist(:, 1:2);
        per_step_err = sqrt(sum(err.^2, 2));
        results.(f).rmse_per_step(trial, :) = per_step_err';
        results.(f).gate_active_step(trial, :) = gate_active';

        % Per-segment RMSE
        for s = 1:n_seg
            results.(f).rmse_per_segment(trial, s) = ...
                compute_pose_rmse(waypoints(segments(s,1):segments(s,2), :), ...
                                   x_hist(segments(s,1):segments(s,2), :));
        end
        results.(f).rmse_total(trial) = compute_pose_rmse(waypoints, x_hist);
    end
    if mod(trial, 5) == 0
        fprintf('  Trial %d/%d (%.1fs)\n', trial, num_trials, toc);
    end
end

save('nonstationary_results.mat', 'results', 'alpha_schedule', 'segments', 'seg_labels');

% ====================================================================
% PRINT SUMMARY
% ====================================================================
fprintf('\n=================================================================\n');
fprintf('  Per-segment Mean Pose RMSE (metres)\n');
fprintf('=================================================================\n');
header = sprintf('  %-22s |', 'Segment');
for fi = 1:length(filters)
    header = [header sprintf(' %12s |', filters{fi})];
end
fprintf('%s\n', header);
fprintf('  %s\n', repmat('-', 1, length(header) - 2));

for s = 1:n_seg
    row = sprintf('  %-22s |', seg_labels{s});
    for fi = 1:length(filters)
        v = mean(results.(filters{fi}).rmse_per_segment(:, s));
        row = [row sprintf(' %12.4f |', v)];
    end
    fprintf('%s\n', row);
end

% Total
row = sprintf('  %-22s |', 'TOTAL (full traj.)');
for fi = 1:length(filters)
    v = mean(results.(filters{fi}).rmse_total);
    row = [row sprintf(' %12.4f |', v)];
end
fprintf('%s\n', row);

% Win rates
fprintf('\n=================================================================\n');
fprintf('  Win rate of Proposed vs each baseline (per-segment, %% trials)\n');
fprintf('=================================================================\n');
baselines = setdiff(filters, {'proposed'});
header = sprintf('  %-22s |', 'Segment');
for b = 1:length(baselines)
    header = [header sprintf(' vs %-12s |', baselines{b})];
end
fprintf('%s\n', header);
fprintf('  %s\n', repmat('-', 1, length(header) - 2));

for s = 1:n_seg
    row = sprintf('  %-22s |', seg_labels{s});
    for b = 1:length(baselines)
        wins = mean(results.proposed.rmse_per_segment(:, s) < ...
                    results.(baselines{b}).rmse_per_segment(:, s));
        row = [row sprintf(' %12.0f%% |', 100*wins)];
    end
    fprintf('%s\n', row);
end

% Transition lag analysis
fprintf('\n=================================================================\n');
fprintf('  Post-transition RMSE (first 20 steps after each transition)\n');
fprintf('=================================================================\n');
transitions = [101, 201, 301];
trans_labels = {'After 1->5', 'After 5->1', 'After 1->3'};
header = sprintf('  %-22s |', 'Transition');
for fi = 1:length(filters)
    header = [header sprintf(' %12s |', filters{fi})];
end
fprintf('%s\n', header);
fprintf('  %s\n', repmat('-', 1, length(header) - 2));

for ti = 1:length(transitions)
    s_start = transitions(ti);
    s_end = s_start + 19;
    row = sprintf('  %-22s |', trans_labels{ti});
    for fi = 1:length(filters)
        err_post = results.(filters{fi}).rmse_per_step(:, s_start:s_end);
        v = mean(err_post(:));
        row = [row sprintf(' %12.4f |', v)];
    end
    fprintf('%s\n', row);
end

fprintf('\nDone. Saved to nonstationary_results.mat.\n');
fprintf('Per-step RMSE arrays available for plotting (rmse_per_step field).\n');
