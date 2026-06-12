% REV1_REGIME4 - Regime IV: realistic validation (revision item R3)
%
% M=50 random landmarks over the field, figure-8 trajectory, limited sensing
% (max_range=8 m, FOV=180 deg) so the number of visible landmarks N_t varies
% per step, and nearest-neighbour data association WITHOUT ground-truth
% correspondence. The proposed corrector's gate threshold is recalibrated
% per step to d = 2*N_t via compute_gate_threshold (Sec. 3.4.2 recipe).
%
%   IV-a: stationary symmetric mismatch, alpha in {1,3,5,7}
%   IV-b: non-stationary schedule alpha: 1 -> 5 -> 1 -> 3 (T=400)
%
% Quick pre-run:  matlab -batch "NUM_TRIALS_OVERRIDE=3; ALPHA_OVERRIDE=[1 5]; rev1_regime4"
% Full run:       matlab -batch "rev1_regime4"
%
% Saves ../results/regime4_realistic/rev1_regime4_results.mat

if ~exist('NUM_TRIALS_OVERRIDE', 'var'), NUM_TRIALS_OVERRIDE = 30; end
if ~exist('ALPHA_OVERRIDE', 'var'),      ALPHA_OVERRIDE = [1, 3, 5, 7]; end

addpath(genpath(pwd));

FILTERS = {'nominal', 'sage_husa', 'strong_tracking', 'proposed'};
num_trials = NUM_TRIALS_OVERRIDE;
alphas = ALPHA_OVERRIDE;

T = 400; dt = 0.05;
Q_nominal = diag([0.01, 0.01, 0.001]);
R_nominal = diag([0.04, 0.0025]);
M = 50;

cfg.dt = dt;
cfg.max_range = 8.0;
cfg.visibility_fov = pi;          % 180 deg forward sensor

% --- Trajectory: figure-8 spanning ~24 x 12 m ---
traj_params.a = 12.0; traj_params.b = 6.0;
[waypoints, controls] = generate_trajectory('figure8', T, dt, traj_params);

% --- Landmarks: uniform over the field + margin, minimum separation 2.5 m
%     (rejection sampling; fixed seed, scene constant across trials) ---
MIN_SEP = 2.5;
rng_state = rng; rng(42, 'twister');
fx = [min(waypoints(:,1)) - 3, max(waypoints(:,1)) + 3];
fy = [min(waypoints(:,2)) - 3, max(waypoints(:,2)) + 3];
landmarks = zeros(M, 2);
placed = 0; guard = 0;
while placed < M && guard < 100000
    guard = guard + 1;
    cand = [fx(1) + (fx(2)-fx(1)) * rand, fy(1) + (fy(2)-fy(1)) * rand];
    if placed == 0 || min(sqrt(sum((landmarks(1:placed,:) - cand).^2, 2))) >= MIN_SEP
        placed = placed + 1;
        landmarks(placed, :) = cand;
    end
end
assert(placed == M, 'could not place %d landmarks with %.1f m separation', M, MIN_SEP);
rng(rng_state);

fprintf('=== Regime IV: realistic validation ===\n');
fprintf('M=%d landmarks, figure-8 %.0fx%.0f m, max_range=%.1f, FOV=180deg\n', ...
        M, fx(2)-fx(1), fy(2)-fy(1), cfg.max_range);
fprintf('Filters: %s | trials: %d\n\n', strjoin(FILTERS, ', '), num_trials);

results = struct();

%% ================= IV-a: stationary =====================================
fprintf('--- IV-a: stationary, alpha = %s ---\n', mat2str(alphas));
tic;
for ai = 1:length(alphas)
    alpha = alphas(ai);
    akey = sprintf('a%d', alpha);
    [Q_true, R_true] = apply_mismatch(Q_nominal, R_nominal, alpha, 'symmetric');
    for f = FILTERS
        results.iva.(akey).(f{1}).rmse        = zeros(num_trials, 1);
        results.iva.(akey).(f{1}).nees        = zeros(num_trials, 1);
        results.iva.(akey).(f{1}).gate_rate   = zeros(num_trials, 1);
        results.iva.(akey).(f{1}).mis_rate    = zeros(num_trials, 1);
        results.iva.(akey).(f{1}).drop_rate   = zeros(num_trials, 1);
        results.iva.(akey).(f{1}).mean_nvis   = zeros(num_trials, 1);
    end
    for trial = 1:num_trials
        rng(trial, 'twister');
        sim = simulate_trajectory(waypoints, controls, landmarks, Q_true, R_true, cfg);
        for f = FILTERS
            o = run_filter_da(f{1}, sim, landmarks, Q_nominal, R_nominal);
            r = results.iva.(akey).(f{1});
            r.rmse(trial) = compute_pose_rmse(waypoints, o.x_hist);
            r.nees(trial) = compute_nees(waypoints, o.x_hist, o.P_pose_hist);
            r.gate_rate(trial) = mean(o.gate_active);
            tot_assigned = sum(o.n_assigned);
            r.mis_rate(trial)  = sum(o.n_misassoc) / max(tot_assigned, 1);
            r.drop_rate(trial) = sum(o.n_dropped) / max(sum(o.n_visible), 1);
            r.mean_nvis(trial) = mean(o.n_visible);
            results.iva.(akey).(f{1}) = r;
        end
    end
    fprintf('  alpha = %d done (%.1fs)\n', alpha, toc);
end

%% ================= IV-b: non-stationary =================================
fprintf('--- IV-b: non-stationary 1 -> 5 -> 1 -> 3 ---\n');
alpha_schedule = ones(T, 1);
alpha_schedule(101:200) = 5;
alpha_schedule(201:300) = 1;
alpha_schedule(301:400) = 3;
segments = [1 100; 101 200; 201 300; 301 400];
n_seg = size(segments, 1);
trans = [101, 201, 301];

for f = FILTERS
    results.ivb.(f{1}).rmse_total      = zeros(num_trials, 1);
    results.ivb.(f{1}).rmse_per_seg    = zeros(num_trials, n_seg);
    results.ivb.(f{1}).rmse_post_trans = zeros(num_trials, numel(trans));
    results.ivb.(f{1}).rmse_per_step   = zeros(num_trials, T);
    results.ivb.(f{1}).mis_rate        = zeros(num_trials, 1);
    results.ivb.(f{1}).gate_rate       = zeros(num_trials, 1);
end
for trial = 1:num_trials
    rng(trial, 'twister');
    sim = simulate_trajectory_nonstationary(waypoints, controls, landmarks, ...
        Q_nominal, R_nominal, alpha_schedule, 'symmetric', cfg);
    for f = FILTERS
        o = run_filter_da(f{1}, sim, landmarks, Q_nominal, R_nominal);
        r = results.ivb.(f{1});
        err = waypoints(:, 1:2) - o.x_hist(:, 1:2);
        per_step = sqrt(sum(err.^2, 2));
        r.rmse_per_step(trial, :) = per_step';
        r.rmse_total(trial) = compute_pose_rmse(waypoints, o.x_hist);
        for sgi = 1:n_seg
            r.rmse_per_seg(trial, sgi) = compute_pose_rmse( ...
                waypoints(segments(sgi,1):segments(sgi,2), :), ...
                o.x_hist(segments(sgi,1):segments(sgi,2), :));
        end
        for ti = 1:numel(trans)
            r.rmse_post_trans(trial, ti) = mean(per_step(trans(ti):trans(ti)+19));
        end
        r.mis_rate(trial) = sum(o.n_misassoc) / max(sum(o.n_assigned), 1);
        r.gate_rate(trial) = mean(o.gate_active);
        results.ivb.(f{1}) = r;
    end
    if mod(trial, 5) == 0, fprintf('  trial %d/%d (%.1fs)\n', trial, num_trials, toc); end
end

%% ================= Save + quick summary =================================
meta.M = M; meta.T = T; meta.cfg = cfg; meta.alphas = alphas;
meta.traj_params = traj_params; meta.num_trials = num_trials;
meta.landmarks = landmarks; meta.alpha_schedule = alpha_schedule;
if ~exist('../results/regime4_realistic', 'dir'), mkdir('../results/regime4_realistic'); end
save('../results/regime4_realistic/rev1_regime4_results.mat', 'results', 'meta');

fprintf('\n--- IV-a mean RMSE (m) ---\n');
fprintf('%-8s', 'alpha'); fprintf('%18s', FILTERS{:}); fprintf('\n');
for ai = 1:length(alphas)
    akey = sprintf('a%d', alphas(ai));
    fprintf('%-8d', alphas(ai));
    for f = FILTERS, fprintf('%18.4f', mean(results.iva.(akey).(f{1}).rmse)); end
    fprintf('\n');
end
fprintf('\n--- IV-a mean NEES (target 3) / gate%% / mis%% (proposed) ---\n');
for ai = 1:length(alphas)
    akey = sprintf('a%d', alphas(ai));
    p = results.iva.(akey).proposed;
    fprintf('alpha=%d: NEES=%.2f gate=%.1f%% mis=%.2f%% drop=%.2f%% nvis=%.1f\n', ...
        alphas(ai), mean(p.nees), 100*mean(p.gate_rate), ...
        100*mean(p.mis_rate), 100*mean(p.drop_rate), mean(p.mean_nvis));
end
fprintf('\n--- IV-b total RMSE ---\n');
for f = FILTERS
    fprintf('%-18s %.4f\n', f{1}, mean(results.ivb.(f{1}).rmse_total));
end
fprintf('\nREGIME4_DONE\n');
