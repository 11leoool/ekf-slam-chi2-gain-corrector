% RUN_RAIN_TABLE - Rain-scenario table for the manuscript (Batch A, 2026-07-21).
%
% Known-map EKF localization (3 landmarks, commanded circle, T = 600,
% dt = 0.1 s) with range-bearing measurements degraded by the Goodin et
% al. (Electronics 2019) rain model: range noise inflation
% sigma_rain = 0.02 z (1 - e^-R)^2 plus detection dropout; bearing keeps
% clear-weather noise (no published rain dependence). The FILTER always
% assumes the clear-weather R -- rain is the miscalibration it does not
% know about. Policies match the constant-gain ablation table of the
% manuscript: nominal EKF, chi2 corrector (tau = 1.45, s_min = 0.15),
% constant s = 0.15, constant s = 0.35. Paired seeds, n = 100.
%
% SMART rainfall categories: light < 2.5, moderate 2.5-7.6, heavy > 7.6 mm/h.
clear; clc;

C = thrun_params(3);
rates = [0 1 2.5 7.6 10 25];        % mm/h
seeds = 1:100;
nr = numel(rates); ns = numel(seeds);

rmse = zeros(nr, 4, ns);            % policies: ekf | chi2 | c0.15 | c0.35
detf = zeros(nr, ns);
act  = zeros(nr, ns);               % chi2 gate activation

for ri = 1:nr
    for si = 1:ns
        D = sim_truth_rain(C, seeds(si), rates(ri));
        detf(ri, si) = D.detfrac;
        o = ekf_localization_rain_corr(C, D, 'ekf');
        rmse(ri, 1, si) = o.rmse_pos;
        o = ekf_localization_rain_corr(C, D, 'chi2');
        rmse(ri, 2, si) = o.rmse_pos;
        act(ri, si) = mean(o.s_hist < 1);
        o = ekf_localization_rain_corr(C, D, 'const', 0.15);
        rmse(ri, 3, si) = o.rmse_pos;
        o = ekf_localization_rain_corr(C, D, 'const', 0.35);
        rmse(ri, 4, si) = o.rmse_pos;
    end
    fprintf('rate %.1f mm/h done\n', rates(ri));
end

ci = @(x) 1.984 * std(x) / sqrt(numel(x));
lbl = {'nominal', 'chi2', 'const 0.15', 'const 0.35'};

fprintf('\n=== Rain table (mean position RMSE, m; n=100 paired) ===\n');
fprintf('%-7s %-6s', 'mm/h', 'det%%');
fprintf(' %-18s', lbl{:}); fprintf(' %-10s %-12s %-12s\n', 'act%%', 'p chi2-ekf', 'p chi2-c15');
for ri = 1:nr
    x = squeeze(rmse(ri, :, :))';   % ns x 4
    p_ekf = signrank(x(:,2), x(:,1));
    p_c15 = signrank(x(:,2), x(:,3));
    fprintf('%-7.1f %-6.1f', rates(ri), 100*mean(detf(ri,:)));
    for pi_ = 1:4, fprintf(' %.4f +- %.4f  ', mean(x(:,pi_)), ci(x(:,pi_))); end
    fprintf(' %-10.1f %-12.3g %-12.3g\n', 100*mean(act(ri,:)), p_ekf, p_c15);
end

fprintf('\n=== LaTeX rows (rate & det & nominal & chi2 & c15 & c35) ===\n');
for ri = 1:nr
    x = squeeze(rmse(ri, :, :))';
    fprintf('%g & %.0f & %.3f $\\pm$ %.3f & %.3f $\\pm$ %.3f & %.3f $\\pm$ %.3f & %.3f $\\pm$ %.3f \\\\\n', ...
        rates(ri), 100*mean(detf(ri,:)), ...
        mean(x(:,1)), ci(x(:,1)), mean(x(:,2)), ci(x(:,2)), ...
        mean(x(:,3)), ci(x(:,3)), mean(x(:,4)), ci(x(:,4)));
end

save rain_table_results.mat rmse detf act rates seeds C lbl
fprintf('\nRAIN_TABLE_DONE\n');
