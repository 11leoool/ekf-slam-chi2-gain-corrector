% RUN_SIGNIFICANCE_TESTS - Paired Wilcoxon tests on non-stationary results
%
% Operates on nonstationary_results.mat (output of run_nonstationary_test.m).
% Tests whether the proposed corrector's per-trial RMSE is significantly
% lower than the Sage-Husa baseline's per-trial RMSE, in each of:
%   - the full trajectory
%   - each of the four segments
%   - each of the three post-transition windows (20 steps after a transition)
%
% Uses Wilcoxon signed-rank (signrank in MATLAB), the standard non-parametric
% paired test. Reports p-value, test statistic, effect size (median diff),
% and whether the result clears the conventional thresholds.

clear; clc;

if exist('nonstationary_results.mat', 'file') ~= 2
    error('nonstationary_results.mat not found. Run run_nonstationary_test.m first.');
end

S = load('nonstationary_results.mat');
results = S.results;

n_trials = length(results.proposed.rmse_total);

fprintf('=== Paired Wilcoxon signed-rank tests ===\n');
fprintf('H0: median(proposed - sage_husa) = 0\n');
fprintf('H1: median(proposed - sage_husa) < 0   (proposed has lower RMSE)\n');
fprintf('n = %d paired trials\n\n', n_trials);

% --------------------------------------------------------------------
% 1) Full-trajectory RMSE
% --------------------------------------------------------------------
prop = results.proposed.rmse_total(:);
sage = results.sage_husa.rmse_total(:);
print_test('Full trajectory', prop, sage);

% --------------------------------------------------------------------
% 2) Per-segment RMSE
% --------------------------------------------------------------------
seg_labels = {'Segment 1 (alpha=1, matched)', ...
              'Segment 2 (alpha=5, jump)', ...
              'Segment 3 (alpha=1, recovery)', ...
              'Segment 4 (alpha=3, mild)'};
for s = 1:4
    prop = results.proposed.rmse_per_segment(:, s);
    sage = results.sage_husa.rmse_per_segment(:, s);
    print_test(seg_labels{s}, prop, sage);
end

% --------------------------------------------------------------------
% 3) Post-transition windows (20 steps after each transition)
% --------------------------------------------------------------------
transitions = [101, 201, 301];
trans_labels = {'After alpha: 1 -> 5', 'After alpha: 5 -> 1', 'After alpha: 1 -> 3'};
for ti = 1:length(transitions)
    s_start = transitions(ti);
    s_end = s_start + 19;
    % Mean per-step RMSE for each trial in this window
    prop = mean(results.proposed.rmse_per_step(:, s_start:s_end), 2);
    sage = mean(results.sage_husa.rmse_per_step(:, s_start:s_end), 2);
    print_test(trans_labels{ti}, prop, sage);
end

fprintf('\nDone.\n');

% ====================================================================
% HELPER: run a single test and print a formatted line
% ====================================================================
function print_test(label, proposed, sage_husa)
    n = length(proposed);
    diff = proposed - sage_husa;
    median_diff = median(diff);
    mean_diff = mean(diff);
    pct_improvement = 100 * mean_diff / mean(sage_husa);   % negative if proposed is better

    % One-sided test: proposed < sage_husa
    [p, ~, stats] = signrank(proposed, sage_husa, 'tail', 'left');

    % Significance stars
    if     p < 0.001, stars = '***';
    elseif p < 0.01,  stars = '**';
    elseif p < 0.05,  stars = '*';
    else,             stars = 'ns';
    end

    fprintf('%-35s | n=%-3d | median diff=%+.4f | %+.1f%% | p=%.4g %s\n', ...
            label, n, median_diff, pct_improvement, p, stars);
end
