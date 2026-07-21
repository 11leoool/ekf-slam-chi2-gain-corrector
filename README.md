# Chi-squared Innovation Gating for Adaptive Kalman Gain Correction in EKF-SLAM

MATLAB simulation code, Monte Carlo results, and figure-generation scripts for the paper:

> Dun Liu and Liuping Wang, *Chi-squared Innovation Gating for Adaptive Kalman Gain Correction in EKF-SLAM under Non-Stationary Noise*, submitted to MDPI Robotics, 2026.

The paper proposes a closed-form Kalman-gain corrector for EKF-SLAM: at each update, the normalised innovation squared (NIS) over visible landmarks is compared against a chi-squared gate, and when it fires the gain is scaled by `s = clamp(1/chi2_global, 0.15, 1)`. No noise-statistics estimation, no sliding window, no warm-up, no training data. An estimation-free extension reuses the same statistic to widen the data-association gate ("Proposed (kappa)"). The evaluation covers four simulation regimes (stationary, non-stationary, short-trajectory, and a realistic 50-landmark setting with nearest-neighbour data association), a constant-gain ablation that discloses the benchmark's structural bias toward gain reduction, and a physically modelled rain scenario (Goodin lidar-degradation model) probing where gated adaptivity beats any fixed gain scale and where it correctly stands down.

## Requirements

- MATLAB (tested on a recent release) with the **Statistics and Machine Learning Toolbox** (`chi2inv`, `signrank`, `tinv`)
- Python 3 with `numpy`, `scipy`, `matplotlib` (figure generation only)

## Repository layout

```
src/              All MATLAB sources + the Python figure script
results/          Saved .mat result files and the statistical reports used in the paper
                  (regime1_stationary, regime2_nonstationary, regime3_short,
                   regime4_realistic; baseline_n30 holds the earlier 30-trial runs)
rain_experiment/  Rain-scenario study (paper Sec. 4.7): known-map EKF localization
                  under the Goodin et al. (2019) lidar rain model (range-noise
                  inflation + detection dropout), filter assuming clear weather
```

Key sources in `src/`:

| File | Role |
|---|---|
| `run_proposed_corrector.m` | The proposed chi-squared gated gain corrector (Regimes I–III) |
| `run_sage_husa_full.m` | Sage–Husa adaptive baseline (window 20, warm-up 30, floor 0.25) |
| `run_strong_tracking.m` | Strong-tracking / adaptive-fading baseline (pose-block fading) |
| `run_nominal_ekf.m`, `run_filter.m` | Nominal EKF and the filter dispatcher |
| `run_filter_da.m` | Unified Regime-IV runner with nearest-neighbour data association; `opts.da_widen` enables the "Proposed (kappa)" association-gate extension |
| `compute_gate_threshold.m` | tau(d) recalibration recipe (Sec. 3.4.2 of the paper) |
| `rev1_run_all.m`, `rev1_stats.m` | Regimes I–III experiments + statistics |
| `rev1_regime4.m`, `rev1_regime4_stats.m` | Regime IV experiments + statistics |
| `rev1_regime4_v2.m` | Ablation of the extension (D = gate widening, B = two-sided gain gate; B is rejected in the paper) |
| `make_figures_rev1.py` | Regenerates Figures 1–5 from the .mat files |

## Reproducing the paper

All experiments use fixed seeds (`rng(trial, 'twister')`), so every table value reproduces exactly. From `src/`:

```matlab
% Regimes I–III  ->  Tables 1–6, statistical report
NUM_TRIALS_OVERRIDE = 100; rev1_run_all; rev1_stats

% Regime IV      ->  Tables 7–9
NUM_TRIALS_OVERRIDE = 100; rev1_regime4; rev1_regime4_stats

% Extension ablation (Sec. 3.4.4 / 5.3)
rev1_regime4_v2
```

```matlab
% Rain scenario -> Table 11 (run from rain_experiment/)
run_rain_table
```

```bash
# Figures 1–5 (after the MATLAB runs)
python make_figures_rev1.py
```

Outputs land in `../results/` (reports as Markdown, raw per-trial data as .mat). Runtime on a desktop CPU: Regimes I–III about a minute; Regime IV roughly 20–40 minutes at 100 trials.

## Statistical protocol

Paired one-sided Wilcoxon signed-rank tests (all filters share the noise realisation within a trial — common random numbers), Holm-corrected within each regime-by-baseline family; t-based 95% CIs; TOST equivalence at ±5% for the stationary comparison; two-sided and reversed-direction tests for the do-no-harm assessment at matched noise and under Q-only mismatch. See `results/rev1_statistics_report.md` and `results/regime4_realistic/rev1_regime4_report.md`.

## License

MIT — see [LICENSE](LICENSE).
