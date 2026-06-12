# Revision-1 Statistical Report (R1 + R2)

Generated 11-Jun-2026 15:47:30. n = 30 paired Monte Carlo trials throughout;
identical seeds across filters (rng(trial)), so all tests are paired.
CI: t-based 95%. Wilcoxon: one-sided (proposed < baseline), Holm-corrected
within each regime x baseline family. TOST: +/-5% of Sage-Husa mean.

## Regime I — Stationary symmetric mismatch (T=200)

### RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.2153 ± 0.0181 | 0.2199 ± 0.0189 | 0.2453 ± 0.0272 | 0.2156 ± 0.0206 |
| 3 | 0.3615 ± 0.0305 | 0.3248 ± 0.0345 | 0.5051 ± 0.0524 | 0.3390 ± 0.0485 |
| 5 | 0.4767 ± 0.0418 | 0.4090 ± 0.0477 | 0.6794 ± 0.0682 | 0.4268 ± 0.0647 |
| 7 | 0.5724 ± 0.0528 | 0.4800 ± 0.0600 | 0.8095 ± 0.0805 | 0.4808 ± 0.0713 |

### NEES, mean ± 95% CI (target 3.0)

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 2.01 ± 0.34 | 1.64 ± 0.30 | 3.99 ± 0.91 | 2.00 ± 0.36 |
| 3 | 5.09 ± 0.78 | 3.00 ± 0.60 | 18.59 ± 3.74 | 3.86 ± 0.94 |
| 5 | 8.69 ± 1.29 | 4.31 ± 0.90 | 32.06 ± 6.02 | 5.25 ± 1.40 |
| 7 | 12.66 ± 1.90 | 5.51 ± 1.20 | 45.02 ± 8.30 | 5.87 ± 1.47 |

### Gate activation rate (% of steps), mean

| alpha | strong_tracking | proposed |
|---|---|---|
| 1 | 28.5 | 6.2 |
| 3 | 96.4 | 62.4 |
| 5 | 99.4 | 82.6 |
| 7 | 99.5 | 90.3 |

### Paired Wilcoxon (proposed < baseline), RMSE, Holm-corrected

| baseline | alpha | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | 1 | +0.0003 | +0.1% | 0.3108 | 0.3108 | ns |
| nominal | 3 | -0.0226 | -6.2% | 0.07496 | 0.1499 | ns |
| nominal | 5 | -0.0499 | -10.5% | 0.03846 | 0.1154 | ns |
| nominal | 7 | -0.0916 | -16.0% | 0.00719 | 0.02876 | * |
| sage_husa | 1 | -0.0043 | -1.9% | 0.1048 | 0.4192 | ns |
| sage_husa | 3 | +0.0142 | +4.4% | 0.6964 | 1 | ns |
| sage_husa | 5 | +0.0178 | +4.4% | 0.7642 | 1 | ns |
| sage_husa | 7 | +0.0008 | +0.2% | 0.5164 | 1 | ns |
| strong_tracking | 1 | -0.0297 | -12.1% | 1.628e-05 | 1.628e-05 | *** |
| strong_tracking | 3 | -0.1662 | -32.9% | 9.127e-07 | 3.651e-06 | *** |
| strong_tracking | 5 | -0.2526 | -37.2% | 9.127e-07 | 3.651e-06 | *** |
| strong_tracking | 7 | -0.3287 | -40.6% | 9.127e-07 | 3.651e-06 | *** |

### TOST equivalence (proposed vs sage_husa, bounds ±5% of SH mean)

| alpha | mean diff | bound | p(TOST) | equivalent at 5%? |
|---|---|---|---|---|
| 1 | -0.0043 | ±0.0110 | 0.03753 | YES |
| 3 | +0.0142 | ±0.0162 | 0.4349 | no |
| 5 | +0.0178 | ±0.0204 | 0.4411 | no |
| 7 | +0.0008 | ±0.0240 | 0.1916 | no |

## Regime II — Non-stationary schedule 1→5→1→3 (T=400)

### Per-segment / total RMSE (m), mean ± 95% CI

| segment | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| alpha=1 matched | 0.1849 ± 0.0198 | 0.1938 ± 0.0195 | 0.2225 ± 0.0218 | 0.1822 ± 0.0197 |
| alpha=5 jump | 0.3995 ± 0.0622 | 0.3219 ± 0.0539 | 0.4602 ± 0.0194 | 0.2505 ± 0.0291 |
| alpha=1 recovery | 0.3224 ± 0.0690 | 0.2556 ± 0.0512 | 0.2419 ± 0.0267 | 0.2097 ± 0.0274 |
| alpha=3 mild | 0.2859 ± 0.0236 | 0.2400 ± 0.0224 | 0.3608 ± 0.0169 | 0.2248 ± 0.0195 |
| **total** | 0.3148 ± 0.0423 | 0.2621 ± 0.0349 | 0.3375 ± 0.0160 | 0.2212 ± 0.0200 |

### Post-transition RMSE (20 steps), mean ± 95% CI

| window | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| after 1to5 | 0.3102 ± 0.0499 | 0.2974 ± 0.0460 | 0.4049 ± 0.0277 | 0.2246 ± 0.0390 |
| after 5to1 | 0.3384 ± 0.0846 | 0.2593 ± 0.0686 | 0.2428 ± 0.0300 | 0.2029 ± 0.0339 |
| after 1to3 | 0.3044 ± 0.0454 | 0.2554 ± 0.0330 | 0.3264 ± 0.0203 | 0.2189 ± 0.0261 |

### Paired Wilcoxon (proposed < baseline), Holm-corrected (8 tests/family)

| baseline | quantity | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | total | -0.0936 | -29.7% | 1.238e-06 | 8.664e-06 | *** |
| nominal | alpha=1 matched | -0.0027 | -1.5% | 0.004498 | 0.004498 | ** |
| nominal | alpha=5 jump | -0.1490 | -37.3% | 1.369e-06 | 8.664e-06 | *** |
| nominal | alpha=1 recovery | -0.1127 | -35.0% | 7.699e-05 | 0.000231 | *** |
| nominal | alpha=3 mild | -0.0611 | -21.4% | 1.011e-06 | 8.085e-06 | *** |
| nominal | after 1to5 | -0.0856 | -27.6% | 3.327e-06 | 1.663e-05 | *** |
| nominal | after 5to1 | -0.1355 | -40.0% | 0.0001725 | 0.0003451 | *** |
| nominal | after 1to3 | -0.0854 | -28.1% | 3.665e-06 | 1.663e-05 | *** |
| sage_husa | total | -0.0409 | -15.6% | 7.699e-05 | 0.0003849 | *** |
| sage_husa | alpha=1 matched | -0.0115 | -6.0% | 5.372e-06 | 4.298e-05 | *** |
| sage_husa | alpha=5 jump | -0.0714 | -22.2% | 3.598e-05 | 0.0002159 | *** |
| sage_husa | alpha=1 recovery | -0.0459 | -18.0% | 0.005379 | 0.01521 | * |
| sage_husa | alpha=3 mild | -0.0152 | -6.3% | 0.00507 | 0.01521 | * |
| sage_husa | after 1to5 | -0.0728 | -24.5% | 1.781e-05 | 0.0001246 | *** |
| sage_husa | after 5to1 | -0.0564 | -21.7% | 0.03358 | 0.03358 | * |
| sage_husa | after 1to3 | -0.0365 | -14.3% | 0.003113 | 0.01245 | * |
| strong_tracking | total | -0.1163 | -34.5% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | alpha=1 matched | -0.0403 | -18.1% | 4.441e-06 | 1.332e-05 | *** |
| strong_tracking | alpha=5 jump | -0.2097 | -45.6% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | alpha=1 recovery | -0.0322 | -13.3% | 0.001746 | 0.003492 | ** |
| strong_tracking | alpha=3 mild | -0.1360 | -37.7% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | after 1to5 | -0.1803 | -44.5% | 1.011e-06 | 7.301e-06 | *** |
| strong_tracking | after 5to1 | -0.0400 | -16.5% | 0.001746 | 0.003492 | ** |
| strong_tracking | after 1to3 | -0.1075 | -32.9% | 1.011e-06 | 7.301e-06 | *** |

## Regime III — Short trajectory (T=50)

### Full-trajectory RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.4932 ± 0.0209 | 0.4919 ± 0.0212 | 0.5220 ± 0.0320 | 0.4911 ± 0.0207 |
| 3 | 0.5624 ± 0.0372 | 0.5591 ± 0.0380 | 0.6553 ± 0.0491 | 0.5332 ± 0.0326 |
| 5 | 0.6298 ± 0.0493 | 0.6226 ± 0.0510 | 0.7767 ± 0.0603 | 0.5727 ± 0.0408 |
| 7 | 0.6949 ± 0.0596 | 0.6826 ± 0.0624 | 0.8836 ± 0.0693 | 0.5948 ± 0.0450 |

### First-10-step RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.5998 ± 0.0208 | 0.5998 ± 0.0208 | 0.6206 ± 0.0338 | 0.5976 ± 0.0204 |
| 3 | 0.6294 ± 0.0360 | 0.6294 ± 0.0360 | 0.7175 ± 0.0590 | 0.6051 ± 0.0321 |
| 5 | 0.6575 ± 0.0467 | 0.6575 ± 0.0467 | 0.8031 ± 0.0722 | 0.6152 ± 0.0354 |
| 7 | 0.6851 ± 0.0558 | 0.6851 ± 0.0558 | 0.8840 ± 0.0811 | 0.6193 ± 0.0373 |

### Paired Wilcoxon (proposed < baseline), Holm-corrected (8 tests/family)

| baseline | quantity | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | rmse a=1 | -0.0020 | -0.4% | 0.1086 | 0.2172 | ns |
| nominal | rmse a=3 | -0.0292 | -5.2% | 0.01183 | 0.0355 | * |
| nominal | rmse a=5 | -0.0571 | -9.1% | 0.0009488 | 0.006641 | ** |
| nominal | rmse a=7 | -0.1001 | -14.4% | 5.996e-05 | 0.0004797 | *** |
| nominal | first10 a=1 | -0.0022 | -0.4% | 0.2005 | 0.2172 | ns |
| nominal | first10 a=3 | -0.0243 | -3.9% | 0.007611 | 0.03044 | * |
| nominal | first10 a=5 | -0.0423 | -6.4% | 0.002924 | 0.01462 | * |
| nominal | first10 a=7 | -0.0658 | -9.6% | 0.001865 | 0.01119 | * |
| sage_husa | rmse a=1 | -0.0008 | -0.2% | 0.371 | 0.4009 | ns |
| sage_husa | rmse a=3 | -0.0259 | -4.6% | 0.05432 | 0.163 | ns |
| sage_husa | rmse a=5 | -0.0499 | -8.0% | 0.00719 | 0.03595 | * |
| sage_husa | rmse a=7 | -0.0877 | -12.9% | 0.0005774 | 0.004619 | ** |
| sage_husa | first10 a=1 | -0.0022 | -0.4% | 0.2005 | 0.4009 | ns |
| sage_husa | first10 a=3 | -0.0243 | -3.9% | 0.007611 | 0.03595 | * |
| sage_husa | first10 a=5 | -0.0423 | -6.4% | 0.002924 | 0.01755 | * |
| sage_husa | first10 a=7 | -0.0658 | -9.6% | 0.001865 | 0.01306 | * |
| strong_tracking | rmse a=1 | -0.0309 | -5.9% | 0.001865 | 0.00373 | ** |
| strong_tracking | rmse a=3 | -0.1220 | -18.6% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | rmse a=5 | -0.2040 | -26.3% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | rmse a=7 | -0.2887 | -32.7% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | first10 a=1 | -0.0230 | -3.7% | 0.009519 | 0.009519 | ** |
| strong_tracking | first10 a=3 | -0.1124 | -15.7% | 7.824e-06 | 2.347e-05 | *** |
| strong_tracking | first10 a=5 | -0.1878 | -23.4% | 3.665e-06 | 1.466e-05 | *** |
| strong_tracking | first10 a=7 | -0.2647 | -29.9% | 1.672e-06 | 8.361e-06 | *** |
