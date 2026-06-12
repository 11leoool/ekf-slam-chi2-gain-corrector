% REV1_STATS - Revision-1 statistical analysis (revision item R1)
%
% Operates on the rev1_*.mat files produced by rev1_run_all.m.
% For every paper table cell: mean +/- 95% CI (t-based, n=30).
% Paired one-sided Wilcoxon signed-rank tests (proposed < baseline) for
% baseline in {nominal, sage_husa, strong_tracking}, Holm-corrected within
% each (regime x baseline) family.
% TOST equivalence test (+/-5% of Sage-Husa mean) for the Regime I
% "within 5%" claim.
%
% Output: ../results/rev1_statistics_report.md

clear; clc;

R1 = load('../results/regime1_stationary/rev1_stationary_results.mat');
R2 = load('../results/regime2_nonstationary/rev1_nonstationary_results.mat');
R3 = load('../results/regime3_short/rev1_short_results.mat');

FILTERS = {'nominal', 'sage_husa', 'strong_tracking', 'proposed'};
BASELINES = {'nominal', 'sage_husa', 'strong_tracking'};
ALPHAS = [1 3 5 7];

fid = fopen('../results/rev1_statistics_report.md', 'w');
fprintf(fid, '# Revision-1 Statistical Report (R1 + R2)\n\n');
fprintf(fid, 'Generated %s. n = 30 paired Monte Carlo trials throughout;\n', datestr(now));
fprintf(fid, 'identical seeds across filters (rng(trial)), so all tests are paired.\n');
fprintf(fid, 'CI: t-based 95%%. Wilcoxon: one-sided (proposed < baseline), Holm-corrected\n');
fprintf(fid, 'within each regime x baseline family. TOST: +/-5%% of Sage-Husa mean.\n\n');

%% ================= Regime I =============================================
fprintf(fid, '## Regime I — Stationary symmetric mismatch (T=200)\n\n');
fprintf(fid, '### RMSE (m), mean ± 95%% CI\n\n');
fprintf(fid, '| alpha | nominal | sage_husa | strong_tracking | proposed |\n');
fprintf(fid, '|---|---|---|---|---|\n');
for a = ALPHAS
    key = sprintf('circular_lm3_symmetric_a%d', a);
    row = sprintf('| %d |', a);
    for fi = 1:4
        v = R1.results.(key).(FILTERS{fi}).rmse;
        [m, h] = mean_ci(v);
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end

fprintf(fid, '\n### NEES, mean ± 95%% CI (target 3.0)\n\n');
fprintf(fid, '| alpha | nominal | sage_husa | strong_tracking | proposed |\n');
fprintf(fid, '|---|---|---|---|---|\n');
for a = ALPHAS
    key = sprintf('circular_lm3_symmetric_a%d', a);
    row = sprintf('| %d |', a);
    for fi = 1:4
        v = R1.results.(key).(FILTERS{fi}).nees_avg;
        [m, h] = mean_ci(v);
        row = [row sprintf(' %.2f ± %.2f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end

fprintf(fid, '\n### Gate activation rate (%% of steps), mean\n\n');
fprintf(fid, '| alpha | strong_tracking | proposed |\n|---|---|---|\n');
for a = ALPHAS
    key = sprintf('circular_lm3_symmetric_a%d', a);
    fprintf(fid, '| %d | %.1f | %.1f |\n', a, ...
        100*mean(R1.results.(key).strong_tracking.gate_pct), ...
        100*mean(R1.results.(key).proposed.gate_pct));
end

% --- Wilcoxon per baseline, Holm across the 4 alphas ---
fprintf(fid, '\n### Paired Wilcoxon (proposed < baseline), RMSE, Holm-corrected\n\n');
fprintf(fid, '| baseline | alpha | mean diff | %% change | p (raw) | p (Holm) | sig |\n');
fprintf(fid, '|---|---|---|---|---|---|---|\n');
for bi = 1:3
    b = BASELINES{bi};
    praw = zeros(1,4); md = zeros(1,4); pc = zeros(1,4);
    for ai = 1:4
        key = sprintf('circular_lm3_symmetric_a%d', ALPHAS(ai));
        prop = R1.results.(key).proposed.rmse;
        base = R1.results.(key).(b).rmse;
        praw(ai) = signrank(prop, base, 'tail', 'left');
        md(ai) = mean(prop - base);
        pc(ai) = 100*mean(prop - base)/mean(base);
    end
    padj = holm_adjust(praw);
    for ai = 1:4
        fprintf(fid, '| %s | %d | %+.4f | %+.1f%% | %.4g | %.4g | %s |\n', ...
            b, ALPHAS(ai), md(ai), pc(ai), praw(ai), padj(ai), stars(padj(ai)));
    end
end

% --- TOST equivalence proposed vs sage_husa, +/-5% bounds ---
fprintf(fid, '\n### TOST equivalence (proposed vs sage_husa, bounds ±5%% of SH mean)\n\n');
fprintf(fid, '| alpha | mean diff | bound | p(TOST) | equivalent at 5%%? |\n|---|---|---|---|---|\n');
for a = ALPHAS
    key = sprintf('circular_lm3_symmetric_a%d', a);
    prop = R1.results.(key).proposed.rmse;
    sage = R1.results.(key).sage_husa.rmse;
    d = prop - sage;
    delta = 0.05 * mean(sage);
    p_tost = tost_paired(d, delta);
    fprintf(fid, '| %d | %+.4f | ±%.4f | %.4g | %s |\n', a, mean(d), delta, ...
        p_tost, verdict(p_tost < 0.05));
end

%% ================= Regime II ============================================
fprintf(fid, '\n## Regime II — Non-stationary schedule 1→5→1→3 (T=400)\n\n');
seg_names = {'alpha=1 matched', 'alpha=5 jump', 'alpha=1 recovery', 'alpha=3 mild'};
fprintf(fid, '### Per-segment / total RMSE (m), mean ± 95%% CI\n\n');
fprintf(fid, '| segment | nominal | sage_husa | strong_tracking | proposed |\n');
fprintf(fid, '|---|---|---|---|---|\n');
for s = 1:4
    row = sprintf('| %s |', seg_names{s});
    for fi = 1:4
        v = R2.results.(FILTERS{fi}).rmse_per_segment(:, s);
        [m, h] = mean_ci(v);
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end
row = '| **total** |';
for fi = 1:4
    v = R2.results.(FILTERS{fi}).rmse_total;
    [m, h] = mean_ci(v);
    row = [row sprintf(' %.4f ± %.4f |', m, h)];
end
fprintf(fid, '%s\n', row);

% post-transition windows
trans = [101, 201, 301];
tnames = {'after 1to5', 'after 5to1', 'after 1to3'};
fprintf(fid, '\n### Post-transition RMSE (20 steps), mean ± 95%% CI\n\n');
fprintf(fid, '| window | nominal | sage_husa | strong_tracking | proposed |\n');
fprintf(fid, '|---|---|---|---|---|\n');
for ti = 1:3
    row = sprintf('| %s |', tnames{ti});
    for fi = 1:4
        v = mean(R2.results.(FILTERS{fi}).rmse_per_step(:, trans(ti):trans(ti)+19), 2);
        [m, h] = mean_ci(v);
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end

% Wilcoxon: 8 quantities (total + 4 segments + 3 windows) per baseline
fprintf(fid, '\n### Paired Wilcoxon (proposed < baseline), Holm-corrected (8 tests/family)\n\n');
fprintf(fid, '| baseline | quantity | mean diff | %% change | p (raw) | p (Holm) | sig |\n');
fprintf(fid, '|---|---|---|---|---|---|---|\n');
qnames = [{'total'}, seg_names, tnames];
for bi = 1:3
    b = BASELINES{bi};
    nq = 8; praw = zeros(1,nq); md = zeros(1,nq); pc = zeros(1,nq);
    Pv = cell(1,nq); Bv = cell(1,nq);
    Pv{1} = R2.results.proposed.rmse_total;        Bv{1} = R2.results.(b).rmse_total;
    for s = 1:4
        Pv{1+s} = R2.results.proposed.rmse_per_segment(:, s);
        Bv{1+s} = R2.results.(b).rmse_per_segment(:, s);
    end
    for ti = 1:3
        Pv{5+ti} = mean(R2.results.proposed.rmse_per_step(:, trans(ti):trans(ti)+19), 2);
        Bv{5+ti} = mean(R2.results.(b).rmse_per_step(:, trans(ti):trans(ti)+19), 2);
    end
    for q = 1:nq
        praw(q) = signrank(Pv{q}, Bv{q}, 'tail', 'left');
        md(q) = mean(Pv{q} - Bv{q});
        pc(q) = 100*mean(Pv{q} - Bv{q})/mean(Bv{q});
    end
    padj = holm_adjust(praw);
    for q = 1:nq
        fprintf(fid, '| %s | %s | %+.4f | %+.1f%% | %.4g | %.4g | %s |\n', ...
            b, qnames{q}, md(q), pc(q), praw(q), padj(q), stars(padj(q)));
    end
end

%% ================= Regime III ===========================================
fprintf(fid, '\n## Regime III — Short trajectory (T=50)\n\n');
fprintf(fid, '### Full-trajectory RMSE (m), mean ± 95%% CI\n\n');
fprintf(fid, '| alpha | nominal | sage_husa | strong_tracking | proposed |\n');
fprintf(fid, '|---|---|---|---|---|\n');
for a = ALPHAS
    key = sprintf('a%d', a);
    row = sprintf('| %d |', a);
    for fi = 1:4
        v = R3.results.(key).(FILTERS{fi}).rmse;
        [m, h] = mean_ci(v);
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end
fprintf(fid, '\n### First-10-step RMSE (m), mean ± 95%% CI\n\n');
fprintf(fid, '| alpha | nominal | sage_husa | strong_tracking | proposed |\n');
fprintf(fid, '|---|---|---|---|---|\n');
for a = ALPHAS
    key = sprintf('a%d', a);
    row = sprintf('| %d |', a);
    for fi = 1:4
        v = R3.results.(key).(FILTERS{fi}).rmse_first10;
        [m, h] = mean_ci(v);
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end

fprintf(fid, '\n### Paired Wilcoxon (proposed < baseline), Holm-corrected (8 tests/family)\n\n');
fprintf(fid, '| baseline | quantity | mean diff | %% change | p (raw) | p (Holm) | sig |\n');
fprintf(fid, '|---|---|---|---|---|---|---|\n');
for bi = 1:3
    b = BASELINES{bi};
    nq = 8; praw = zeros(1,nq); md = zeros(1,nq); pc = zeros(1,nq); qn = cell(1,nq);
    idx = 0;
    for a = ALPHAS
        key = sprintf('a%d', a);
        idx = idx + 1;
        prop = R3.results.(key).proposed.rmse; base = R3.results.(key).(b).rmse;
        praw(idx) = signrank(prop, base, 'tail', 'left');
        md(idx) = mean(prop - base); pc(idx) = 100*md(idx)/mean(base);
        qn{idx} = sprintf('rmse a=%d', a);
    end
    for a = ALPHAS
        key = sprintf('a%d', a);
        idx = idx + 1;
        prop = R3.results.(key).proposed.rmse_first10; base = R3.results.(key).(b).rmse_first10;
        praw(idx) = signrank(prop, base, 'tail', 'left');
        md(idx) = mean(prop - base); pc(idx) = 100*md(idx)/mean(base);
        qn{idx} = sprintf('first10 a=%d', a);
    end
    padj = holm_adjust(praw);
    for q = 1:nq
        fprintf(fid, '| %s | %s | %+.4f | %+.1f%% | %.4g | %.4g | %s |\n', ...
            b, qn{q}, md(q), pc(q), praw(q), padj(q), stars(padj(q)));
    end
end

fclose(fid);
fprintf('REV1_STATS_DONE -> ../results/rev1_statistics_report.md\n');

%% ================= helpers ==============================================
function [m, h] = mean_ci(v)
    v = v(:); n = numel(v);
    m = mean(v);
    h = tinv(0.975, n-1) * std(v) / sqrt(n);
end

function padj = holm_adjust(p)
    [ps, order] = sort(p);
    k = numel(p);
    adj = zeros(1, k);
    running = 0;
    for i = 1:k
        running = max(running, (k - i + 1) * ps(i));
        adj(i) = min(running, 1);
    end
    padj = zeros(1, k);
    padj(order) = adj;
end

function s = stars(p)
    if p < 0.001, s = '***';
    elseif p < 0.01, s = '**';
    elseif p < 0.05, s = '*';
    else, s = 'ns';
    end
end

function p = tost_paired(d, delta)
    % Paired TOST: H1 = |mean(d)| < delta. p = max of the two one-sided ps.
    d = d(:); n = numel(d);
    se = std(d) / sqrt(n);
    t1 = (mean(d) - delta) / se;    % H1: mean(d) < +delta  -> left tail
    t2 = (mean(d) + delta) / se;    % H1: mean(d) > -delta  -> right tail
    p1 = tcdf(t1, n-1);
    p2 = 1 - tcdf(t2, n-1);
    p = max(p1, p2);
end

function s = verdict(tf)
    if tf, s = 'YES'; else, s = 'no'; end
end
