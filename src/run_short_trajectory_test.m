% RUN_SHORT_TRAJECTORY_TEST - Short-trajectory experiment
%
% Tests filter performance over only 50 timesteps. Sage-Husa has a 30-step
% warm-up before adaptation begins, so the proposed corrector should have
% a clear advantage when the mission is shorter than the warm-up.

clear; clc;
addpath(genpath(pwd));

% --- Configuration ---
T = 50;
dt = 0.05;
Q_nominal = diag([0.01, 0.01, 0.001]);
R_nominal = diag([0.04, 0.0025]);
num_trials = 30;
mismatch_type = 'symmetric';
filters = {'nominal', 'sage_husa', 'proposed'};
alphas = [1, 3, 5, 7];

cfg.dt = dt;
cfg.max_range = 50.0;
cfg.visibility_fov = 2*pi;

% --- Use a circular trajectory but speed it up to cover ground in 50 steps ---
traj_params.radius = 5.0;
[waypoints, controls] = generate_trajectory('circular', T, dt, traj_params);
landmarks = generate_landmarks(3, waypoints, 'ring');

% --- Storage ---
results = struct();
for ai = 1:length(alphas)
    alpha_key = sprintf('a%d', alphas(ai));
    results.(alpha_key) = struct();
    for fi = 1:length(filters)
        results.(alpha_key).(filters{fi}).rmse = zeros(num_trials, 1);
        results.(alpha_key).(filters{fi}).rmse_first10 = zeros(num_trials, 1);
        results.(alpha_key).(filters{fi}).rmse_last10  = zeros(num_trials, 1);
    end
end

% --- Run experiments ---
fprintf('=== Short-trajectory test (T=50) ===\n');
fprintf('Filters: %s\n', strjoin(filters, ', '));
fprintf('Alpha values: %s\n', mat2str(alphas));
fprintf('Trials per (alpha, filter): %d\n\n', num_trials);

tic;
for ai = 1:length(alphas)
    alpha = alphas(ai);
    alpha_key = sprintf('a%d', alpha);
    [Q_true, R_true] = apply_mismatch(Q_nominal, R_nominal, alpha, mismatch_type);

    for trial = 1:num_trials
        rng(trial, 'twister');

        sim = simulate_trajectory(waypoints, controls, landmarks, Q_true, R_true, cfg);

        for fi = 1:length(filters)
            f = filters{fi};
            [x_hist, ~, ~] = run_filter(f, sim, landmarks, Q_nominal, R_nominal);

            results.(alpha_key).(f).rmse(trial) = compute_pose_rmse(waypoints, x_hist);
            results.(alpha_key).(f).rmse_first10(trial) = ...
                compute_pose_rmse(waypoints(1:10,:), x_hist(1:10,:));
            results.(alpha_key).(f).rmse_last10(trial) = ...
                compute_pose_rmse(waypoints(end-9:end,:), x_hist(end-9:end,:));
        end
    end
    fprintf('  alpha = %d done (%.1fs)\n', alpha, toc);
end

save('short_trajectory_results.mat', 'results', 'alphas', 'filters');

% ====================================================================
% PRINT SUMMARY
% ====================================================================
fprintf('\n=================================================================\n');
fprintf('  Full-Trajectory RMSE (T=50 steps)\n');
fprintf('=================================================================\n');
header = sprintf('  %-8s |', 'Alpha');
for fi = 1:length(filters)
    header = [header sprintf(' %12s |', filters{fi})];
end
fprintf('%s\n', header);
fprintf('  %s\n', repmat('-', 1, length(header) - 2));

for ai = 1:length(alphas)
    alpha_key = sprintf('a%d', alphas(ai));
    row = sprintf('  %-8d |', alphas(ai));
    for fi = 1:length(filters)
        v = mean(results.(alpha_key).(filters{fi}).rmse);
        row = [row sprintf(' %12.4f |', v)];
    end
    fprintf('%s\n', row);
end

fprintf('\n=================================================================\n');
fprintf('  RMSE on FIRST 10 steps (Sage-Husa warm-up disadvantage)\n');
fprintf('=================================================================\n');
fprintf('%s\n', header);
fprintf('  %s\n', repmat('-', 1, length(header) - 2));
for ai = 1:length(alphas)
    alpha_key = sprintf('a%d', alphas(ai));
    row = sprintf('  %-8d |', alphas(ai));
    for fi = 1:length(filters)
        v = mean(results.(alpha_key).(filters{fi}).rmse_first10);
        row = [row sprintf(' %12.4f |', v)];
    end
    fprintf('%s\n', row);
end

fprintf('\n=================================================================\n');
fprintf('  Win rate of Proposed vs each baseline (per-trial, full trajectory)\n');
fprintf('=================================================================\n');
baselines = setdiff(filters, {'proposed'});
header = sprintf('  %-8s |', 'Alpha');
for b = 1:length(baselines)
    header = [header sprintf(' vs %-12s |', baselines{b})];
end
fprintf('%s\n', header);
fprintf('  %s\n', repmat('-', 1, length(header) - 2));

for ai = 1:length(alphas)
    alpha_key = sprintf('a%d', alphas(ai));
    row = sprintf('  %-8d |', alphas(ai));
    for b = 1:length(baselines)
        wins = mean(results.(alpha_key).proposed.rmse < ...
                    results.(alpha_key).(baselines{b}).rmse);
        row = [row sprintf(' %12.0f%% |', 100*wins)];
    end
    fprintf('%s\n', row);
end

fprintf('\nDone. Saved to short_trajectory_results.mat.\n');
