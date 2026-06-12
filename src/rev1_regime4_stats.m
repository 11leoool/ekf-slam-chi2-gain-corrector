% REV1_REGIME4_STATS - Statistical analysis for Regime IV (R3)
%
% Same protocol as rev1_stats: t-based 95% CI; one-sided paired Wilcoxon
% (proposed < baseline), Holm-corrected within each (sub-regime x baseline)
% family. Plus association-quality and gate-calibration tables.
%
% Output: ../results/regime4_realistic/rev1_regime4_report.md

clear; clc;

S = load('../results/regime4_realistic/rev1_regime4_results.mat');
results = S.results; meta = S.meta;

FILTERS = {'nominal', 'sage_husa', 'strong_tracking', 'proposed'};
BASELINES = {'nominal', 'sage_husa', 'strong_tracking'};
ALPHAS = meta.alphas;

fid = fopen('../results/regime4_realistic/rev1_regime4_report.md', 'w');
fprintf(fid, '# Regime IV Statistical Report (R3: realistic validation)\n\n');
fprintf(fid, 'Setup: M=%d random landmarks, figure-8 %.0fx%.0f m field, max_range=%.1f m, FOV=180deg,\n', ...
    meta.M, 30, 18, meta.cfg.max_range);
fprintf(fid, 'NN data association (chi2(2) 99%% gate, no ground-truth correspondence),\n');
fprintf(fid, 'per-step adaptive tau(d) at 10%% target false-trigger rate. n=%d paired trials.\n\n', ...
    meta.num_trials);

%% ---------------- IV-a ----------------
fprintf(fid, '## IV-a: stationary symmetric mismatch\n\n');
fprintf(fid, '### Position RMSE (m), mean ± 95%% CI\n\n');
fprintf(fid, '| alpha | nominal | sage_husa | strong_tracking | proposed |\n|---|---|---|---|---|\n');
for a = ALPHAS
    k = sprintf('a%d', a);
    row = sprintf('| %d |', a);
    for f = FILTERS
        [m, h] = mean_ci(results.iva.(k).(f{1}).rmse);
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end

fprintf(fid, '\n### Pose NEES (target 3.0), mean ± 95%% CI\n\n');
fprintf(fid, '| alpha | nominal | sage_husa | strong_tracking | proposed |\n|---|---|---|---|---|\n');
for a = ALPHAS
    k = sprintf('a%d', a);
    row = sprintf('| %d |', a);
    for f = FILTERS
        [m, h] = mean_ci(results.iva.(k).(f{1}).nees);
        row = [row sprintf(' %.2f ± %.2f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end

fprintf(fid, '\n### Gate calibration & association quality (proposed)\n\n');
fprintf(fid, '| alpha | gate rate %% (target 10 @ a=1) | misassoc %% | dropped %% | mean N_t |\n|---|---|---|---|---|\n');
for a = ALPHAS
    k = sprintf('a%d', a);
    p = results.iva.(k).proposed;
    fprintf(fid, '| %d | %.1f | %.2f | %.2f | %.1f |\n', a, ...
        100*mean(p.gate_rate), 100*mean(p.mis_rate), ...
        100*mean(p.drop_rate), mean(p.mean_nvis));
end

fprintf(fid, '\n### Misassociation rate by filter (%%), mean\n\n');
fprintf(fid, '| alpha | nominal | sage_husa | strong_tracking | proposed |\n|---|---|---|---|---|\n');
for a = ALPHAS
    k = sprintf('a%d', a);
    row = sprintf('| %d |', a);
    for f = FILTERS
        row = [row sprintf(' %.2f |', 100*mean(results.iva.(k).(f{1}).mis_rate))];
    end
    fprintf(fid, '%s\n', row);
end

fprintf(fid, '\n### Paired Wilcoxon (proposed < baseline), RMSE, Holm within family\n\n');
fprintf(fid, '| baseline | alpha | mean diff | %% change | p (raw) | p (Holm) | sig |\n|---|---|---|---|---|---|---|\n');
for b = BASELINES
    na = numel(ALPHAS); praw = zeros(1, na); md = zeros(1, na); pc = zeros(1, na);
    for ai = 1:na
        k = sprintf('a%d', ALPHAS(ai));
        prop = results.iva.(k).proposed.rmse;
        base = results.iva.(k).(b{1}).rmse;
        praw(ai) = signrank(prop, base, 'tail', 'left');
        md(ai) = mean(prop - base);
        pc(ai) = 100 * md(ai) / mean(base);
    end
    padj = holm_adjust(praw);
    for ai = 1:na
        fprintf(fid, '| %s | %d | %+.4f | %+.1f%% | %.4g | %.4g | %s |\n', ...
            b{1}, ALPHAS(ai), md(ai), pc(ai), praw(ai), padj(ai), stars(padj(ai)));
    end
end

%% ---------------- IV-b ----------------
fprintf(fid, '\n## IV-b: non-stationary schedule 1 -> 5 -> 1 -> 3\n\n');
seg_names = {'a=1 matched', 'a=5 jump', 'a=1 recovery', 'a=3 mild'};
tr_names = {'after 1to5', 'after 5to1', 'after 1to3'};

fprintf(fid, '### RMSE (m), mean ± 95%% CI\n\n');
fprintf(fid, '| quantity | nominal | sage_husa | strong_tracking | proposed |\n|---|---|---|---|---|\n');
row = '| total |';
for f = FILTERS
    [m, h] = mean_ci(results.ivb.(f{1}).rmse_total);
    row = [row sprintf(' %.4f ± %.4f |', m, h)];
end
fprintf(fid, '%s\n', row);
for sgi = 1:4
    row = sprintf('| %s |', seg_names{sgi});
    for f = FILTERS
        [m, h] = mean_ci(results.ivb.(f{1}).rmse_per_seg(:, sgi));
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end
for ti = 1:3
    row = sprintf('| %s |', tr_names{ti});
    for f = FILTERS
        [m, h] = mean_ci(results.ivb.(f{1}).rmse_post_trans(:, ti));
        row = [row sprintf(' %.4f ± %.4f |', m, h)];
    end
    fprintf(fid, '%s\n', row);
end

fprintf(fid, '\n### Paired Wilcoxon (proposed < baseline), Holm within family (8 tests)\n\n');
fprintf(fid, '| baseline | quantity | mean diff | %% change | p (raw) | p (Holm) | sig |\n|---|---|---|---|---|---|---|\n');
qn = [{'total'}, seg_names, tr_names];
for b = BASELINES
    nq = 8; praw = zeros(1, nq); md = zeros(1, nq); pc = zeros(1, nq);
    Pv = cell(1, nq); Bv = cell(1, nq);
    Pv{1} = results.ivb.proposed.rmse_total;   Bv{1} = results.ivb.(b{1}).rmse_total;
    for sgi = 1:4
        Pv{1+sgi} = results.ivb.proposed.rmse_per_seg(:, sgi);
        Bv{1+sgi} = results.ivb.(b{1}).rmse_per_seg(:, sgi);
    end
    for ti = 1:3
        Pv{5+ti} = results.ivb.proposed.rmse_post_trans(:, ti);
        Bv{5+ti} = results.ivb.(b{1}).rmse_post_trans(:, ti);
    end
    for q = 1:nq
        praw(q) = signrank(Pv{q}, Bv{q}, 'tail', 'left');
        md(q) = mean(Pv{q} - Bv{q});
        pc(q) = 100 * md(q) / mean(Bv{q});
    end
    padj = holm_adjust(praw);
    for q = 1:nq
        fprintf(fid, '| %s | %s | %+.4f | %+.1f%% | %.4g | %.4g | %s |\n', ...
            b{1}, qn{q}, md(q), pc(q), praw(q), padj(q), stars(padj(q)));
    end
end

fclose(fid);
fprintf('REGIME4_STATS_DONE -> ../results/regime4_realistic/rev1_regime4_report.md\n');

%% ---------------- helpers ----------------
function [m, h] = mean_ci(v)
    v = v(:); n = numel(v);
    m = mean(v);
    h = tinv(0.975, n - 1) * std(v) / sqrt(n);
end

function padj = holm_adjust(p)
    [ps, order] = sort(p);
    k = numel(p); adj = zeros(1, k); running = 0;
    for i = 1:k
        running = max(running, (k - i + 1) * ps(i));
        adj(i) = min(running, 1);
    end
    padj = zeros(1, k); padj(order) = adj;
end

function s = stars(p)
    if p < 0.001, s = '***';
    elseif p < 0.01, s = '**';
    elseif p < 0.05, s = '*';
    else, s = 'ns';
    end
end
