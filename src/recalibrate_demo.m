% RECALIBRATE_DEMO - Demonstration of the threshold helper and configurable corrector
%
% Walks through three example use cases:
%   1) Print the calibrated threshold for several values of d
%   2) Run the proposed corrector with the DEFAULT threshold
%   3) Run the proposed corrector with a CUSTOM threshold from the helper
%
% Use this as a starting point if you want to deploy the corrector at a
% different number of landmarks, a different measurement dimension, or a
% different false-trigger rate.

clear; clc;
addpath(genpath(pwd));

% ====================================================================
% PART 1: Print the calibrated threshold for a range of d values
% ====================================================================
fprintf('=== Calibrated thresholds for several d values ===\n');
fprintf('%-6s | %-15s | %-15s | %-15s\n', 'd', 'tau (10%)', 'tau (5%)', 'tau (1%)');
fprintf('%s\n', repmat('-', 1, 60));
for d = [2, 4, 6, 8, 10, 14, 20, 40]
    fprintf('%-6d | %-15.4f | %-15.4f | %-15.4f\n', ...
        d, ...
        compute_gate_threshold(d, 0.10), ...
        compute_gate_threshold(d, 0.05), ...
        compute_gate_threshold(d, 0.01));
end
fprintf('\nNote: tau = 1.45 (paper default) sits between the 80th and 90th %%ile at d = 6.\n\n');

% ====================================================================
% PART 2: Run the corrector with the default threshold
% ====================================================================
fprintf('=== Running corrector with DEFAULT settings (tau = 1.45) ===\n');

cfg.dt = 0.05;
cfg.max_range = 50.0;
cfg.visibility_fov = 2*pi;
Q_nominal = diag([0.01, 0.01, 0.001]);
R_nominal = diag([0.04, 0.0025]);
alpha = 5;
T = 200;

[waypoints, controls] = generate_trajectory('circular', T, cfg.dt, struct());
landmarks = generate_landmarks(3, waypoints, 'ring');
[Q_true, R_true] = apply_mismatch(Q_nominal, R_nominal, alpha, 'symmetric');

rng(42);
sim = simulate_trajectory(waypoints, controls, landmarks, Q_true, R_true, cfg);

% Default call (4 arguments, opts not passed)
[x_default, ~, gate_default] = run_proposed_corrector(sim, landmarks, Q_nominal, R_nominal);
rmse_default = compute_pose_rmse(waypoints, x_default);
fprintf('RMSE = %.4f m, gate active = %.1f%% of steps\n\n', ...
        rmse_default, 100 * mean(gate_default));

% ====================================================================
% PART 3: Run the corrector with a CUSTOM threshold
% ====================================================================
fprintf('=== Running corrector with CUSTOM threshold ===\n');
num_landmarks = 3;
d = 2 * num_landmarks;          % measurement dim x landmarks
target_fr = 0.05;                % aim for 5% false-trigger rate

opts.gate_threshold = compute_gate_threshold(d, target_fr);
opts.clamp_min = 0.15;
opts.clamp_max = 1.00;

fprintf('  Effective d = %d\n', d);
fprintf('  Target false-trigger rate = %.0f%%\n', 100 * target_fr);
fprintf('  Calibrated tau = %.4f\n', opts.gate_threshold);

rng(42);  % same trial seed for fair comparison
sim = simulate_trajectory(waypoints, controls, landmarks, Q_true, R_true, cfg);
[x_custom, ~, gate_custom] = run_proposed_corrector(sim, landmarks, Q_nominal, R_nominal, opts);
rmse_custom = compute_pose_rmse(waypoints, x_custom);
fprintf('  RMSE = %.4f m, gate active = %.1f%% of steps\n', ...
        rmse_custom, 100 * mean(gate_custom));

% ====================================================================
% PART 4: Reproduce paper's stationary calibration check at alpha = 1
% ====================================================================
fprintf('\n=== Empirical check: gate rate at alpha = 1 with default tau ===\n');
[Q_true_1, R_true_1] = apply_mismatch(Q_nominal, R_nominal, 1, 'symmetric');
n_trials_check = 30;
gate_rates = zeros(n_trials_check, 1);
for trial = 1:n_trials_check
    rng(trial);
    sim_1 = simulate_trajectory(waypoints, controls, landmarks, Q_true_1, R_true_1, cfg);
    [~, ~, gate_1] = run_proposed_corrector(sim_1, landmarks, Q_nominal, R_nominal);
    gate_rates(trial) = mean(gate_1);
end
fprintf('Mean gate rate at alpha = 1, tau = 1.45 (default): %.1f%% (paper reports 6.2%%)\n', ...
        100 * mean(gate_rates));

fprintf('\nDone.\n');
