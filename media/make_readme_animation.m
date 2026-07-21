% MAKE_README_ANIMATION - Animated GIF for the repository front page.
%
% One Regime-II trial (non-stationary schedule alpha: 1 -> 5 -> 1 -> 3,
% T = 400): nominal EKF vs the chi-squared gated corrector on the same
% noise realisation. Top panel: the 2D scene as it unfolds. Bottom panel:
% the corrector's normalised NIS statistic against the gate threshold,
% with the true noise schedule shaded. Colours: Okabe-Ito.
clear; clc;
addpath('../src');

T = 400; dt = 0.05;
Q_nominal = diag([0.01, 0.01, 0.001]);
R_nominal = diag([0.04, 0.0025]);
scfg.dt = dt; scfg.max_range = 50.0; scfg.visibility_fov = 2*pi;
alpha_schedule = ones(T, 1);
alpha_schedule(101:200) = 5;
alpha_schedule(201:300) = 1;
alpha_schedule(301:400) = 3;

[waypoints, controls] = generate_trajectory('circular', T, dt, struct());
landmarks = generate_landmarks(3, waypoints, 'ring');

SEED = 7;
rng(SEED, 'twister');
sim = simulate_trajectory_nonstationary(waypoints, controls, landmarks, ...
    Q_nominal, R_nominal, alpha_schedule, 'symmetric', scfg);

% ---- nominal EKF ----
[xn, ~, ~] = run_nominal_ekf(sim, landmarks, Q_nominal, R_nominal);

% ---- corrector, instrumented (records chi2_global and s per step) ----
[M, ~] = size(landmarks);
sd = 3 + 2*M;
x = zeros(sd, 1); x(1:3) = sim.initial_pose;
x(4:end) = reshape(landmarks', [], 1);
P = blkdiag(0.001*eye(3), 1.0*eye(2*M));
tau = 1.45; smin = 0.15;
xp = zeros(T, sd); chi2h = zeros(T, 1); sh = ones(T, 1);
for t = 1:T
    u = sim.controls_noisy(t, :)';
    [x, P] = ekf_predict_step(x, P, u, Q_nominal, dt);
    nis = 0; dof = 0;
    for i = 1:M
        if sim.visibility(t, i)
            z = squeeze(sim.observations(t, i, :));
            [nu, S, ~, ~] = ekf_innovation(x, P, z, i, R_nominal);
            nis = nis + nu' * (S \ nu);
            dof = dof + 2;
        end
    end
    if dof > 0, chi2h(t) = nis / dof; end
    s = 1.0;
    if chi2h(t) >= tau, s = max(min(1/chi2h(t), 1.0), smin); end
    sh(t) = s;
    for i = 1:M
        if sim.visibility(t, i)
            z = squeeze(sim.observations(t, i, :));
            [x, P] = ekf_update_step_scaled(x, P, z, i, R_nominal, s);
        end
    end
    xp(t, :) = x';
end

% ---- colours (Okabe-Ito) ----
cTrue = [0.35 0.35 0.35]; cNom = [0.90 0.60 0.00]; cProp = [0.00 0.45 0.70];
cLm = [0.00 0.62 0.45]; cShade = [0.80 0.47 0.65];

fig = figure('Visible', 'off', 'Position', [50 50 880 660], 'Color', 'w');
ax1 = subplot('Position', [0.09 0.42 0.86 0.50]);
ax2 = subplot('Position', [0.09 0.08 0.86 0.24]);

giffile = 'corrector_animation.gif';
step = 2; delay = 0.05;
segs = [1 100 1; 101 200 5; 201 300 1; 301 400 3];

for t = 4:step:T
    % ---------- scene ----------
    cla(ax1); hold(ax1, 'on');
    plot(ax1, waypoints(:,1), waypoints(:,2), ':', 'Color', cTrue, 'LineWidth', 0.8);
    plot(ax1, landmarks(:,1), landmarks(:,2), 's', 'Color', cLm, ...
        'MarkerFaceColor', cLm, 'MarkerSize', 9);
    plot(ax1, xn(1:t,1), xn(1:t,2), '-', 'Color', cNom, 'LineWidth', 1.6);
    plot(ax1, xp(1:t,1), xp(1:t,2), '-', 'Color', cProp, 'LineWidth', 1.6);
    plot(ax1, waypoints(1:t,1), waypoints(1:t,2), '-', 'Color', cTrue, 'LineWidth', 1.0);
    plot(ax1, waypoints(t,1), waypoints(t,2), 'o', 'Color', cTrue, ...
        'MarkerFaceColor', cTrue, 'MarkerSize', 6);
    plot(ax1, xn(t,1), xn(t,2), 'o', 'Color', cNom, 'MarkerFaceColor', cNom, 'MarkerSize', 6);
    plot(ax1, xp(t,1), xp(t,2), 'o', 'Color', cProp, 'MarkerFaceColor', cProp, 'MarkerSize', 6);
    axis(ax1, 'equal');
    xlim(ax1, [min(waypoints(:,1))-4, max(waypoints(:,1))+4]);
    ylim(ax1, [min(waypoints(:,2))-4, max(waypoints(:,2))+4]);
    a_now = alpha_schedule(t);
    title(ax1, {'\chi^2-gated gain correction under non-stationary noise', ...
        sprintf('t = %d/400   true noise \\alpha = %d   gate %s (s = %.2f)', ...
        t, a_now, ternary(sh(t) < 1, 'ACTIVE', 'closed'), sh(t))}, 'FontSize', 11);
    legend(ax1, {'true path (full)', 'landmarks', 'nominal EKF', ...
        'proposed corrector', 'true path'}, 'Location', 'northeastoutside', 'FontSize', 8);
    set(ax1, 'FontSize', 9);

    % ---------- statistic ----------
    cla(ax2); hold(ax2, 'on');
    for si = 1:4
        if segs(si,3) > 1
            patch(ax2, [segs(si,1) segs(si,2) segs(si,2) segs(si,1)], ...
                [0 0 8 8], cShade, 'FaceAlpha', 0.12 + 0.03*segs(si,3), 'EdgeColor', 'none');
        end
    end
    plot(ax2, 1:t, min(chi2h(1:t), 8), '-', 'Color', cProp, 'LineWidth', 1.0);
    yline(ax2, tau, '--', '\tau = 1.45', 'Color', [0.6 0 0], 'FontSize', 8, ...
        'LabelHorizontalAlignment', 'left');
    act = find(sh(1:t) < 1);
    plot(ax2, act, 0.25*ones(size(act)), '.', 'Color', [0.80 0.40 0.00], 'MarkerSize', 5);
    xlim(ax2, [1 T]); ylim(ax2, [0 8]);
    ylabel(ax2, '\chi^2_{global}', 'FontSize', 9);
    xlabel(ax2, 'timestep (shaded: injected mismatch; dots: gate active)', 'FontSize', 9);
    set(ax2, 'FontSize', 9);

    frame = getframe(fig);
    [A, map] = rgb2ind(frame2im(frame), 256);
    if t == 4
        imwrite(A, map, giffile, 'gif', 'LoopCount', Inf, 'DelayTime', delay);
    else
        imwrite(A, map, giffile, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
    end
end

% final-frame PNG for QA
print(fig, 'corrector_animation_lastframe.png', '-dpng', '-r110');
d = dir(giffile);
fprintf('GIF written: %s (%.1f MB)\n', giffile, d.bytes/1e6);
fprintf('RMSE this seed: nominal %.3f | proposed %.3f\n', ...
    sqrt(mean(sum((waypoints(:,1:2)-xn(:,1:2)).^2, 2))), ...
    sqrt(mean(sum((waypoints(:,1:2)-xp(:,1:2)).^2, 2))));
fprintf('ANIMATION_DONE\n');

function out = ternary(c, a, b)
if c, out = a; else, out = b; end
end
