% REV1_RUN_ALL - Revision-1 experiments: all three regimes with the
% strong-tracking baseline added (revision item R2).
%
% Filters: nominal | sage_husa | strong_tracking | proposed
% Seeds identical to the original runs (rng(trial,'twister')), so the
% nominal / sage_husa / proposed columns must reproduce the paper exactly;
% strong_tracking is the only new column.
%
% Outputs (saved into ../results/):
%   regime1_stationary/rev1_stationary_results.mat
%   regime2_nonstationary/rev1_nonstationary_results.mat
%   regime3_short/rev1_short_results.mat

if ~exist('NUM_TRIALS_OVERRIDE', 'var'), NUM_TRIALS_OVERRIDE = 30; end
NT = NUM_TRIALS_OVERRIDE;
clearvars -except NT; clc;
addpath(genpath(pwd));

FILTERS = {'nominal', 'sage_husa', 'strong_tracking', 'proposed'};

%% ================= Regime I: stationary (via main_experiment_runner) ====
cfg.trajectories    = {'circular'};
cfg.landmark_counts = [3];
cfg.mismatch_types  = {'symmetric', 'Q_only', 'R_only'};
cfg.alpha_values    = [1, 3, 5, 7];
cfg.filters         = FILTERS;
cfg.num_mc_trials   = NT;
cfg.timesteps       = 200;
cfg.dt              = 0.05;
cfg.Q_nominal       = diag([0.01, 0.01, 0.001]);
cfg.R_nominal       = diag([0.04, 0.0025]);
cfg.max_range       = 50.0;
cfg.visibility_fov  = 2*pi;

fprintf('=== REV1 Regime I: stationary, 4 filters ===\n');
results = main_experiment_runner(cfg);
save('../results/regime1_stationary/rev1_stationary_results.mat', 'results', 'cfg');

%% ================= Regime II: non-stationary ============================
T = 400; dt = 0.05;
Q_nominal = diag([0.01, 0.01, 0.001]);
R_nominal = diag([0.04, 0.0025]);
num_trials = NT;
scfg.dt = dt; scfg.max_range = 50.0; scfg.visibility_fov = 2*pi;

alpha_schedule = ones(T, 1);
alpha_schedule(101:200) = 5;
alpha_schedule(201:300) = 1;
alpha_schedule(301:400) = 3;
segments = [1 100; 101 200; 201 300; 301 400];

[waypoints, controls] = generate_trajectory('circular', T, dt, struct());
landmarks = generate_landmarks(3, waypoints, 'ring');

n_seg = size(segments, 1);
results = struct();
for fi = 1:length(FILTERS)
    f = FILTERS{fi};
    results.(f).rmse_per_segment = zeros(num_trials, n_seg);
    results.(f).rmse_total       = zeros(num_trials, 1);
    results.(f).rmse_per_step    = zeros(num_trials, T);
    results.(f).gate_active_step = zeros(num_trials, T);
end

fprintf('\n=== REV1 Regime II: non-stationary, 4 filters ===\n');
for trial = 1:num_trials
    rng(trial, 'twister');
    sim = simulate_trajectory_nonstationary(waypoints, controls, landmarks, ...
        Q_nominal, R_nominal, alpha_schedule, 'symmetric', scfg);
    for fi = 1:length(FILTERS)
        f = FILTERS{fi};
        [x_hist, ~, gate_active] = run_filter(f, sim, landmarks, Q_nominal, R_nominal);
        err = waypoints(:, 1:2) - x_hist(:, 1:2);
        results.(f).rmse_per_step(trial, :) = sqrt(sum(err.^2, 2))';
        results.(f).gate_active_step(trial, :) = gate_active';
        for s = 1:n_seg
            results.(f).rmse_per_segment(trial, s) = ...
                compute_pose_rmse(waypoints(segments(s,1):segments(s,2), :), ...
                                   x_hist(segments(s,1):segments(s,2), :));
        end
        results.(f).rmse_total(trial) = compute_pose_rmse(waypoints, x_hist);
    end
end
save('../results/regime2_nonstationary/rev1_nonstationary_results.mat', ...
     'results', 'alpha_schedule', 'segments');
fprintf('Regime II done.\n');

%% ================= Regime III: short trajectory =========================
T = 50; num_trials = NT; alphas = [1, 3, 5, 7];
traj_params.radius = 5.0;
[waypoints, controls] = generate_trajectory('circular', T, dt, traj_params);
landmarks = generate_landmarks(3, waypoints, 'ring');

results = struct();
fprintf('\n=== REV1 Regime III: short trajectory, 4 filters ===\n');
for ai = 1:length(alphas)
    alpha = alphas(ai);
    alpha_key = sprintf('a%d', alpha);
    [Q_true, R_true] = apply_mismatch(Q_nominal, R_nominal, alpha, 'symmetric');
    for trial = 1:num_trials
        rng(trial, 'twister');
        sim = simulate_trajectory(waypoints, controls, landmarks, Q_true, R_true, scfg);
        for fi = 1:length(FILTERS)
            f = FILTERS{fi};
            [x_hist, ~, ~] = run_filter(f, sim, landmarks, Q_nominal, R_nominal);
            results.(alpha_key).(f).rmse(trial, 1) = compute_pose_rmse(waypoints, x_hist);
            results.(alpha_key).(f).rmse_first10(trial, 1) = ...
                compute_pose_rmse(waypoints(1:10,:), x_hist(1:10,:));
        end
    end
    fprintf('  alpha = %d done\n', alpha);
end
save('../results/regime3_short/rev1_short_results.mat', 'results', 'alphas');

fprintf('\nREV1_RUN_ALL_DONE\n');
