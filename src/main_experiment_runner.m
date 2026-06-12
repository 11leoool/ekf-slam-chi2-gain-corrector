function results = main_experiment_runner(config)
% MAIN_EXPERIMENT_RUNNER - Orchestrates the full experimental grid
%
% Runs Monte Carlo trials across all combinations of:
%   - Trajectory type
%   - Landmark count
%   - Mismatch type
%   - Mismatch level (alpha)
%   - Filter (Nominal EKF, Sage-Husa, MLP, Proposed)
%
% INPUTS:
%   config - Struct with experimental settings (see DEFAULT CONFIG below).
%            Any field can be overridden; missing fields use defaults.
%
% OUTPUTS:
%   results - Nested struct of metric values, keyed by condition
%
% USAGE EXAMPLES:
%   % Full grid (warning: ~43,000 trials):
%   results = main_experiment_runner(struct());
%
%   % Single-scenario deep dive:
%   cfg.trajectories = {'circular'};
%   cfg.landmark_counts = [3];
%   cfg.mismatch_types = {'symmetric'};
%   results = main_experiment_runner(cfg);

    % ================================================================
    % DEFAULT CONFIGURATION
    % ================================================================
    defaults.trajectories      = {'circular', 'figure8', 'straight'};
    defaults.landmark_counts   = [3, 5, 10];
    defaults.mismatch_types    = {'symmetric', 'Q_only', 'R_only'};
    defaults.alpha_values      = [1, 3, 5, 7];
    defaults.filters           = {'nominal', 'sage_husa', 'mlp', 'proposed'};
    defaults.num_mc_trials     = 100;
    defaults.timesteps         = 200;
    defaults.dt                = 0.05;
    defaults.Q_nominal         = diag([0.01, 0.01, 0.001]);
    defaults.R_nominal         = diag([0.04, 0.0025]);

    % Merge user config with defaults
    if nargin < 1, config = struct(); end
    config = merge_config(defaults, config);

    % ================================================================
    % PROGRESS TRACKING
    % ================================================================
    n_conditions = length(config.trajectories) * length(config.landmark_counts) ...
                 * length(config.mismatch_types) * length(config.alpha_values);
    total_trials = n_conditions * length(config.filters) * config.num_mc_trials;
    fprintf('Total trials to run: %d\n', total_trials);
    fprintf('Conditions: %d\n', n_conditions);

    results = struct();
    cond_idx = 0;
    tic;

    % ================================================================
    % MAIN LOOP
    % ================================================================
    for ti = 1:length(config.trajectories)
        traj_type = config.trajectories{ti};

        % Generate trajectory once per type (reused across conditions)
        [waypoints, controls] = generate_trajectory(traj_type, ...
            config.timesteps, config.dt, struct());

        for li = 1:length(config.landmark_counts)
            n_landmarks = config.landmark_counts(li);
            landmarks = generate_landmarks(n_landmarks, waypoints, 'ring');

            for mi = 1:length(config.mismatch_types)
                mtype = config.mismatch_types{mi};

                for ai = 1:length(config.alpha_values)
                    alpha = config.alpha_values(ai);
                    cond_idx = cond_idx + 1;

                    [Q_true, R_true] = apply_mismatch(config.Q_nominal, ...
                        config.R_nominal, alpha, mtype);

                    % Storage for this condition
                    cond_results = init_condition_storage(config.filters, ...
                        config.num_mc_trials);

                    % --------------------------------------------------------
                    % Monte Carlo trials
                    % --------------------------------------------------------
                    for trial = 1:config.num_mc_trials
                        rng(trial, 'twister');  % reproducible seed

                        % Generate noisy data once, apply all filters to it
                        sim = simulate_trajectory(waypoints, controls, ...
                            landmarks, Q_true, R_true, config);

                        for fi = 1:length(config.filters)
                            filter_name = config.filters{fi};
                            tic_filter = tic;

                            [x_hist, P_hist, gate_active] = run_filter( ...
                                filter_name, sim, landmarks, ...
                                config.Q_nominal, config.R_nominal);

                            filter_time = toc(tic_filter);

                            % --- Compute metrics ---
                            cond_results.(filter_name).rmse(trial) = ...
                                compute_pose_rmse(waypoints, x_hist);
                            [cond_results.(filter_name).nees_avg(trial), ~, ...
                             cond_results.(filter_name).nees_bounded(trial)] = ...
                                compute_nees(waypoints, x_hist, P_hist);
                            cond_results.(filter_name).gate_pct(trial) = ...
                                mean(gate_active);
                            cond_results.(filter_name).time(trial) = filter_time;
                        end
                    end

                    % Store condition results
                    cond_key = sprintf('%s_lm%d_%s_a%d', ...
                        traj_type, n_landmarks, mtype, alpha);
                    results.(cond_key) = cond_results;

                    fprintf('  [%3d/%3d] %s: %.1fs elapsed\n', ...
                        cond_idx, n_conditions, cond_key, toc);
                end
            end
        end
    end

    fprintf('Done. Total time: %.1f min\n', toc / 60);

end

% ====================================================================
% HELPER: merge config struct with defaults
% ====================================================================
function out = merge_config(defaults, user)
    out = defaults;
    fields = fieldnames(user);
    for i = 1:length(fields)
        out.(fields{i}) = user.(fields{i});
    end
end

% ====================================================================
% HELPER: storage initialisation per condition
% ====================================================================
function out = init_condition_storage(filters, n_trials)
    out = struct();
    for i = 1:length(filters)
        f = filters{i};
        out.(f).rmse         = zeros(n_trials, 1);
        out.(f).nees_avg     = zeros(n_trials, 1);
        out.(f).nees_bounded = zeros(n_trials, 1);
        out.(f).gate_pct     = zeros(n_trials, 1);
        out.(f).time         = zeros(n_trials, 1);
    end
end


