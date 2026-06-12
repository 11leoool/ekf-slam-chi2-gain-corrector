function tau = compute_gate_threshold(d, false_trigger_rate)
% COMPUTE_GATE_THRESHOLD - Pick a gate threshold for the desired false-trigger rate
%
% Under matched noise and Gaussian assumptions, the normalised global NIS
% statistic chi2_global = (1/d) * sum(chi^2_per_landmark) follows the
% scaled distribution chi-squared(d) / d. This helper returns the value of
% tau such that P(chi2_global >= tau | matched noise) = false_trigger_rate.
%
% INPUTS:
%   d                   - effective measurement dimension = meas_dim * N_t
%                         For range-and-bearing observations of N landmarks,
%                         d = 2 * N.
%   false_trigger_rate  - desired probability of gate activation under matched
%                         noise. Typical values: 0.05 to 0.10.
%
% OUTPUT:
%   tau                 - threshold to pass to run_proposed_corrector as
%                         opts.gate_threshold.
%
% EXAMPLES:
%   compute_gate_threshold(6, 0.10)   ->  1.77  (d=6, 90th percentile)
%   compute_gate_threshold(6, 0.05)   ->  2.10  (d=6, 95th percentile)
%   compute_gate_threshold(2, 0.10)   ->  2.30  (d=2, single 2D landmark)
%   compute_gate_threshold(20, 0.10)  ->  1.42  (d=20, ten 2D landmarks)
%
%   Use:
%     opts.gate_threshold = compute_gate_threshold(2 * num_landmarks, 0.10);
%     [x, P, gate] = run_proposed_corrector(sim, landmarks, Q, R, opts);
%
% NOTE:
%   The result assumes the filter is consistent and innovations are Gaussian.
%   In practice the empirical false-trigger rate may differ slightly from the
%   target due to filter inconsistency, non-Gaussianity, or time correlations.

    if nargin < 2
        false_trigger_rate = 0.10;
    end

    if d <= 0
        error('Measurement dimension d must be positive');
    end
    if false_trigger_rate <= 0 || false_trigger_rate >= 1
        error('false_trigger_rate must be in (0, 1)');
    end

    tau = chi2inv(1 - false_trigger_rate, d) / d;
end
