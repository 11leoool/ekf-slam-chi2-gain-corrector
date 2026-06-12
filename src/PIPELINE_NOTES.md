# Experimental pipeline for the EKF-SLAM gain corrector paper

This folder contains the MATLAB scripts to run the strengthened experimental
study for the journal submission.

## File layout

### Top-level
- `main_experiment_runner.m` — orchestrates the full grid of conditions
- `sanity_check.m` — minimal experiment to verify the pipeline works

### Data generation
- `generate_trajectory.m` — circular / figure-8 / straight-line
- `generate_landmarks.m` — ring / random / corners
- `apply_mismatch.m` — symmetric / Q-only / R-only mismatch
- `simulate_trajectory.m` — produces noisy observations from ground truth

### Filters
- `run_filter.m` — dispatcher
- `run_nominal_ekf.m` — baseline EKF-SLAM (no correction)
- `run_sage_husa_full.m` — Sage-Husa adaptive baseline
- `run_mlp_corrector.m` — MLP gain corrector (needs trained model)
- `run_proposed_corrector.m` — proposed chi-squared gated corrector

### EKF utilities
- `ekf_utils.m` — shared predict / update / innovation / scaled-update functions

### Metrics
- `compute_pose_rmse.m` — pose RMSE against ground truth
- `compute_nees.m` — NEES consistency metric

## Quick start

1. Place all `.m` files on the MATLAB path (or `cd` into this folder)
2. Run the sanity check:

   ```matlab
   sanity_check
   ```

3. If it completes without errors and the proposed corrector achieves
   lower RMSE than nominal at alpha=3, the pipeline is working.

4. Train the MLP corrector and save it as `mlp_corrector.mat`
   (containing a variable `net` for `run_mlp_corrector` to load)

5. Run the full grid (warning: ~43,000 trials, several hours):

   ```matlab
   results = main_experiment_runner(struct());
   save('results_full_grid.mat', 'results');
   ```

## Configuration overrides

Pass any subset of these fields to override defaults:

```matlab
cfg.trajectories    = {'circular', 'figure8', 'straight'};
cfg.landmark_counts = [3, 5, 10];
cfg.mismatch_types  = {'symmetric', 'Q_only', 'R_only'};
cfg.alpha_values    = [1, 3, 5, 7];
cfg.filters         = {'nominal', 'sage_husa', 'mlp', 'proposed'};
cfg.num_mc_trials   = 100;
cfg.timesteps       = 200;
cfg.dt              = 0.05;
cfg.Q_nominal       = diag([0.01, 0.01, 0.001]);
cfg.R_nominal       = diag([0.04, 0.0025]);
```

## Important notes

- **`ekf_utils.m` contains multiple functions in one file.** MATLAB only
  recognises functions in a single file if it is being called as a script
  with subfunctions. To use these as separately callable functions, you
  may need to split them into individual `.m` files of the same names:
  `ekf_predict_step.m`, `ekf_innovation.m`, `ekf_update_step.m`,
  `ekf_update_step_scaled.m`. The function bodies are ready to copy.

- **Filter initialisation** assumes landmarks are initialised at their
  true positions with moderate uncertainty. Adjust in each `run_*.m` if
  your initialisation strategy is different.

- **MLP loading** assumes a trained model in `mlp_corrector.mat`. If you
  don't have one, exclude `'mlp'` from `cfg.filters` and the pipeline
  will still run for the other three filters.

- **`compute_pose_rmse.m` is position-only** (sqrt of mean (dx^2 + dy^2)).
  If your existing pipeline uses full pose RMSE, swap this function out.
