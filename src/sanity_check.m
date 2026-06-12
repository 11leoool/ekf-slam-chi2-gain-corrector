% SANITY_CHECK - Verifies the experimental pipeline runs end-to-end
%
% Runs a minimal experiment (1 trajectory type, 1 landmark count,
% 1 mismatch type, 1 alpha level, 5 MC trials, 4 filters) and prints
% the results. Use this before running the full grid.

clear; clc;

% Add all scripts to path (adjust to your folder layout)
addpath(genpath(pwd));

% Minimal configuration
cfg.trajectories    = {'circular'};
cfg.landmark_counts = [3];
cfg.mismatch_types  = {'symmetric'};
cfg.alpha_values    = [3];           % moderate mismatch
cfg.filters         = {'nominal', 'sage_husa', 'proposed'};  % skip MLP if not trained
cfg.num_mc_trials   = 5;
cfg.timesteps       = 200;
cfg.dt              = 0.05;
cfg.Q_nominal       = diag([0.01, 0.01, 0.001]);
cfg.R_nominal       = diag([0.04, 0.0025]);
cfg.max_range       = 50.0;
cfg.visibility_fov  = 2*pi;

fprintf('=== Sanity check: minimal experiment ===\n');
fprintf('Configuration:\n');
disp(cfg);

% Run
results = main_experiment_runner(cfg);

% Print summary
fprintf('\n=== Results ===\n');
key = fieldnames(results);
for i = 1:length(key)
    fprintf('\nCondition: %s\n', key{i});
    cond = results.(key{i});
    filter_names = fieldnames(cond);
    fprintf('  %-12s | %-10s | %-10s | %-10s | %-10s\n', ...
        'Filter', 'RMSE (m)', 'NEES avg', 'Gate %', 'Time (s)');
    fprintf('  %s\n', repmat('-', 1, 60));
    for f = 1:length(filter_names)
        fn = filter_names{f};
        fprintf('  %-12s | %-10.4f | %-10.2f | %-10.1f | %-10.4f\n', ...
            fn, ...
            mean(cond.(fn).rmse), ...
            mean(cond.(fn).nees_avg), ...
            100 * mean(cond.(fn).gate_pct), ...
            mean(cond.(fn).time));
    end
end

fprintf('\nSanity check complete.\n');
