% BROAD_SCAN - Run experiment across all mismatch types and alpha levels
%
% Grid:
%   Trajectory:    circular only (keep landmarks fixed for clean comparison)
%   Landmarks:     3
%   Mismatch:      symmetric, Q_only, R_only
%   Alpha:         1, 3, 5, 7
%   Filters:       nominal, sage_husa, proposed (MLP skipped if not trained)
%   Trials:        30 per condition
%
% Total: 3 mismatch x 4 alpha x 3 filters x 30 trials = 1,080 filter runs
% Expected runtime: 1-3 minutes
%
% After running, call:
%   summarise_scan(results)

clear; clc;
addpath(genpath(pwd));

% --- Configuration ---
cfg.trajectories    = {'circular'};
cfg.landmark_counts = [3];
cfg.mismatch_types  = {'symmetric', 'Q_only', 'R_only'};
cfg.alpha_values    = [1, 3, 5, 7];
cfg.filters         = {'nominal', 'sage_husa', 'proposed'};
cfg.num_mc_trials   = 30;
cfg.timesteps       = 200;
cfg.dt              = 0.05;
cfg.Q_nominal       = diag([0.01, 0.01, 0.001]);
cfg.R_nominal       = diag([0.04, 0.0025]);
cfg.max_range       = 50.0;
cfg.visibility_fov  = 2*pi;

fprintf('=== Broad scan: 12 conditions x 3 filters x 30 trials ===\n');
fprintf('Mismatch types: %s\n', strjoin(cfg.mismatch_types, ', '));
fprintf('Alpha values: %s\n\n', mat2str(cfg.alpha_values));

% --- Run ---
results = main_experiment_runner(cfg);

% --- Save for later analysis ---
save('broad_scan_results.mat', 'results', 'cfg');
fprintf('\nResults saved to broad_scan_results.mat\n\n');

% --- Summarise ---
summarise_scan(results);
