% REV1_REGIME4_V2 - Ablation of the v2 corrector extensions in Regime IV
%
% Variants (all 'proposed' mode of run_filter_da with opts toggles):
%   v2_full : D (chi2-widened association gate) + B (two-sided gain gate)
%   v2_D    : D only
%   v2_B    : B only
%
% Same scene/seeds/conditions as rev1_regime4 (n set by NUM_TRIALS_OVERRIDE,
% default 100 to match the stored v1 results). Compares paired against the
% stored v1 results (proposed + sage_husa) in
% ../results/regime4_realistic/rev1_regime4_results.mat.
%
% Saves ../results/regime4_realistic/rev1_regime4_v2_results.mat
% and prints a comparison summary.

if ~exist('NUM_TRIALS_OVERRIDE', 'var'), NUM_TRIALS_OVERRIDE = 100; end
NT = NUM_TRIALS_OVERRIDE;
clearvars -except NT; clc;
addpath(genpath(pwd));
% Divergence is handled by run_filter_da's guard (diverged flag); the
% singular-matrix warnings are redundant noise at 100 trials.
warning('off', 'MATLAB:singularMatrix');
warning('off', 'MATLAB:nearlySingularMatrix');
warning('off', 'MATLAB:illConditionedMatrix');

V1 = load('../results/regime4_realistic/rev1_regime4_results.mat');
assert(V1.meta.num_trials == NT, 'v1 results have n=%d, this run n=%d', ...
    V1.meta.num_trials, NT);

VAR = struct( ...
    'v2_full', struct('da_widen', true,  'two_sided', true), ...
    'v2_D',    struct('da_widen', true,  'two_sided', false), ...
    'v2_B',    struct('da_widen', false, 'two_sided', true));
VNAMES = fieldnames(VAR);

T = 400; dt = 0.05;
Q_nominal = diag([0.01, 0.01, 0.001]);
R_nominal = diag([0.04, 0.0025]);
alphas = [1, 3, 5, 7];
cfg = V1.meta.cfg;
landmarks = V1.meta.landmarks;
traj_params = V1.meta.traj_params;
[waypoints, controls] = generate_trajectory('figure8', T, dt, traj_params);

fprintf('=== Regime IV v2 ablation: %s | n=%d ===\n', strjoin(VNAMES', ', '), NT);

results = struct();

%% IV-a stationary
tic;
for ai = 1:numel(alphas)
    alpha = alphas(ai); akey = sprintf('a%d', alpha);
    [Q_true, R_true] = apply_mismatch(Q_nominal, R_nominal, alpha, 'symmetric');
    for v = VNAMES'
        results.iva.(akey).(v{1}).rmse = zeros(NT, 1);
        results.iva.(akey).(v{1}).nees = zeros(NT, 1);
        results.iva.(akey).(v{1}).mis_rate = zeros(NT, 1);
        results.iva.(akey).(v{1}).drop_rate = zeros(NT, 1);
        results.iva.(akey).(v{1}).diverged = false(NT, 1);
    end
    for trial = 1:NT
        rng(trial, 'twister');
        sim = simulate_trajectory(waypoints, controls, landmarks, Q_true, R_true, cfg);
        for v = VNAMES'
            o = run_filter_da('proposed', sim, landmarks, Q_nominal, R_nominal, VAR.(v{1}));
            r = results.iva.(akey).(v{1});
            r.rmse(trial) = compute_pose_rmse(waypoints, o.x_hist);
            r.nees(trial) = compute_nees(waypoints, o.x_hist, o.P_pose_hist);
            r.mis_rate(trial) = sum(o.n_misassoc) / max(sum(o.n_assigned), 1);
            r.drop_rate(trial) = sum(o.n_dropped) / max(sum(o.n_visible), 1);
            r.diverged(trial) = o.diverged;
            results.iva.(akey).(v{1}) = r;
        end
    end
    fprintf('  IV-a alpha=%d done (%.0fs)\n', alpha, toc);
end

%% IV-b non-stationary
alpha_schedule = V1.meta.alpha_schedule;
segments = [1 100; 101 200; 201 300; 301 400];
trans = [101, 201, 301];
for v = VNAMES'
    results.ivb.(v{1}).rmse_total = zeros(NT, 1);
    results.ivb.(v{1}).rmse_per_seg = zeros(NT, 4);
    results.ivb.(v{1}).rmse_post_trans = zeros(NT, 3);
    results.ivb.(v{1}).mis_rate = zeros(NT, 1);
    results.ivb.(v{1}).drop_rate = zeros(NT, 1);
    results.ivb.(v{1}).diverged = false(NT, 1);
end
for trial = 1:NT
    rng(trial, 'twister');
    sim = simulate_trajectory_nonstationary(waypoints, controls, landmarks, ...
        Q_nominal, R_nominal, alpha_schedule, 'symmetric', cfg);
    for v = VNAMES'
        o = run_filter_da('proposed', sim, landmarks, Q_nominal, R_nominal, VAR.(v{1}));
        r = results.ivb.(v{1});
        err = waypoints(:, 1:2) - o.x_hist(:, 1:2);
        per_step = sqrt(sum(err.^2, 2));
        r.rmse_total(trial) = compute_pose_rmse(waypoints, o.x_hist);
        for sgi = 1:4
            r.rmse_per_seg(trial, sgi) = compute_pose_rmse( ...
                waypoints(segments(sgi,1):segments(sgi,2), :), ...
                o.x_hist(segments(sgi,1):segments(sgi,2), :));
        end
        for ti = 1:3
            r.rmse_post_trans(trial, ti) = mean(per_step(trans(ti):trans(ti)+19));
        end
        r.mis_rate(trial) = sum(o.n_misassoc) / max(sum(o.n_assigned), 1);
        r.drop_rate(trial) = sum(o.n_dropped) / max(sum(o.n_visible), 1);
        r.diverged(trial) = o.diverged;
        results.ivb.(v{1}) = r;
    end
    if mod(trial, 20) == 0, fprintf('  IV-b trial %d/%d (%.0fs)\n', trial, NT, toc); end
end

save('../results/regime4_realistic/rev1_regime4_v2_results.mat', 'results');

%% ===================== comparison summary =====================
SH = V1.results; % contains sage_husa + proposed (v1)
fprintf('\n================ IV-a RMSE: variant vs sage_husa / vs v1 ================\n');
fprintf('%-8s %-9s %10s %10s %12s %12s %9s %9s\n', 'variant', 'alpha', ...
    'mean', 'vs SH %', 'p(<SH)', 'p(<v1)', 'mis%', 'drop%');
for v = VNAMES'
    for ai = 1:numel(alphas)
        akey = sprintf('a%d', alphas(ai));
        x = results.iva.(akey).(v{1}).rmse;
        sh = SH.iva.(akey).sage_husa.rmse;
        v1 = SH.iva.(akey).proposed.rmse;
        fprintf('%-8s a=%-7d %10.4f %+9.1f%% %12.3g %12.3g %8.2f%% %8.2f%% div=%d\n', ...
            v{1}, alphas(ai), mean(x), 100*(mean(x)-mean(sh))/mean(sh), ...
            signrank(x, sh, 'tail', 'left'), signrank(x, v1, 'tail', 'left'), ...
            100*mean(results.iva.(akey).(v{1}).mis_rate), ...
            100*mean(results.iva.(akey).(v{1}).drop_rate), ...
            sum(results.iva.(akey).(v{1}).diverged));
    end
end

fprintf('\n================ IV-b RMSE: variant vs sage_husa / vs v1 ================\n');
qn = {'total', 'seg matched', 'seg jump', 'seg recovery', 'seg mild', ...
      'after 1to5', 'after 5to1', 'after 1to3'};
for v = VNAMES'
    X = cell(1, 8); B = cell(1, 8); P1 = cell(1, 8);
    X{1} = results.ivb.(v{1}).rmse_total;
    B{1} = SH.ivb.sage_husa.rmse_total;  P1{1} = SH.ivb.proposed.rmse_total;
    for sgi = 1:4
        X{1+sgi} = results.ivb.(v{1}).rmse_per_seg(:, sgi);
        B{1+sgi} = SH.ivb.sage_husa.rmse_per_seg(:, sgi);
        P1{1+sgi} = SH.ivb.proposed.rmse_per_seg(:, sgi);
    end
    for ti = 1:3
        X{5+ti} = results.ivb.(v{1}).rmse_post_trans(:, ti);
        B{5+ti} = SH.ivb.sage_husa.rmse_post_trans(:, ti);
        P1{5+ti} = SH.ivb.proposed.rmse_post_trans(:, ti);
    end
    fprintf('--- %s (IV-b mis=%.2f%%, drop=%.2f%%, diverged=%d/%d) ---\n', v{1}, ...
        100*mean(results.ivb.(v{1}).mis_rate), 100*mean(results.ivb.(v{1}).drop_rate), ...
        sum(results.ivb.(v{1}).diverged), NT);
    for q = 1:8
        fprintf('  %-14s mean=%.4f  vsSH %+6.1f%% p=%-9.3g  vsV1 %+6.1f%% p=%-9.3g\n', ...
            qn{q}, mean(X{q}), 100*(mean(X{q})-mean(B{q}))/mean(B{q}), ...
            signrank(X{q}, B{q}, 'tail', 'left'), ...
            100*(mean(X{q})-mean(P1{q}))/mean(P1{q}), ...
            signrank(X{q}, P1{q}, 'tail', 'left'));
    end
end
fprintf('\nREGIME4_V2_DONE\n');
