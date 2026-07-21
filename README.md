# Chi-squared Innovation Gating for Adaptive Kalman Gain Correction in EKF-SLAM

MATLAB simulation code, Monte Carlo results, and figure-generation scripts for the paper:

> Dun Liu and Liuping Wang, *Chi-squared Innovation Gating for Adaptive Kalman Gain Correction in EKF-SLAM under Non-Stationary Noise*, submitted to MDPI Robotics, 2026.

The paper proposes a closed-form Kalman-gain corrector for EKF-SLAM: at each update, the normalised innovation squared (NIS) over visible landmarks is compared against a chi-squared gate, and when it fires the gain is scaled by `s = clamp(1/chi2_global, 0.15, 1)`. No noise-statistics estimation, no sliding window, no warm-up, no training data. An estimation-free extension reuses the same statistic to widen the data-association gate ("Proposed (kappa)"). The evaluation covers four simulation regimes (stationary, non-stationary, short-trajectory, and a realistic 50-landmark setting with nearest-neighbour data association), a constant-gain ablation that discloses the benchmark's structural bias toward gain reduction, and a physically modelled rain scenario (Goodin lidar-degradation model) probing where gated adaptivity beats any fixed gain scale and where it correctly stands down.

![Chi-squared gated gain correction under non-stationary noise](media/corrector_animation.gif)

*The median non-stationary trial (Regime II, seed 14 — the median-improvement seed of the paper's 100-trial run, deliberately not a favourable draw): the true measurement noise jumps by a factor alpha of 1 -> 5 -> 1 -> 3 (shaded segments in the lower panel). The chi-squared statistic reacts within a step, the gate engages exactly inside the mismatch segments (orange dots), and the corrected filter (blue) stays closer to the true path while the nominal EKF (orange) over-trusts its noisy measurements. Position RMSE on this trial: nominal 0.267 m, corrected 0.211 m (21% — the 100-seed mean is 23%). Regenerate with `media/make_readme_animation.m`.*

<details>
<summary><b>Animation: exact simulation conditions</b> (click to expand)</summary>

Both filters run on the **identical noise realisation** (`rng(14,'twister')`), so the comparison is paired. The setup replicates the paper's Regime II exactly.

| Item | Value | Plain meaning |
|---|---|---|
| Robot and path | Unicycle model, commanded circle (radius ≈ 5 m), T = 400 steps, dt = 0.05 s | The robot drives laps of a circle for 20 simulated seconds |
| Landmarks and sensor | 3 landmarks on a ring; range + bearing to each; always visible; known identity | The robot measures distance and direction to three known posts at every step |
| Assumed process noise **Q** | diag(0.01, 0.01, 0.001) on [x, y, theta], added each prediction | How much motion error the filter *budgets* per step |
| Assumed measurement noise **R** | diag(0.04, 0.0025) — sigma = 0.2 m range, ~3 deg bearing | How noisy the filter *believes* its sensor is |
| Injected noise (the truth) | Gaussian noise on the controls [v, omega] with covariance alpha·diag(0.01, 0.01), and on the measurements with covariance alpha·R | What the simulator *actually* adds — note the process noise physically enters on the 2-D controls, not the 3-D pose |
| Mismatch schedule | alpha = 1 (t 1–100) → **5** (101–200) → 1 (201–300) → **3** (301–400) | The sensor silently becomes 5x, then 3x, noisier than the filter believes — the shaded segments. The filter is never told |
| Filter initialisation | Pose at truth (P0 = 0.001·I3); landmarks at surveyed positions (prior variance 1.0) | The paper's published convention, disclosed in its limitations section |
| Corrector | Gate threshold tau = 1.45 on the normalised NIS over all visible landmarks (d = 6); when exceeded, gain scaled by s = clamp(1/chi2_global, 0.15, 1); Joseph-form update | Acts only when the innovations are statistically too large for the assumed noise, and scales the gain down in proportion to the excess |
| Trial selection | Seed 14 = the **median**-improvement trial of the paper's n = 100 run (21.1% vs 20.5% median, 23.2% mean) | Deliberately typical; verify the ranking yourself from `results/regime2_nonstationary/rev1_nonstationary_results.mat` |

One honest footnote: the filter assumes its process noise as an additive 3x3 **Q** on the pose (the common convention in this literature), while the simulator injects it on the 2-D controls — a claimed-versus-injected distinction the paper's limitations section discloses and quantifies via a constant-gain ablation.

</details>

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
