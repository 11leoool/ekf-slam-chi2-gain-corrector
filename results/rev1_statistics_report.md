# Revision-1 Statistical Report (R1 + R2)

Generated 12-Jun-2026 01:08:22. n = 30 paired Monte Carlo trials throughout;
identical seeds across filters (rng(trial)), so all tests are paired.
CI: t-based 95%. Wilcoxon: one-sided (proposed < baseline), Holm-corrected
within each regime x baseline family. TOST: +/-5% of Sage-Husa mean.

## Regime I — Stationary symmetric mismatch (T=200)

### RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.2113 ± 0.0093 | 0.2207 ± 0.0095 | 0.2508 ± 0.0123 | 0.2127 ± 0.0104 |
| 3 | 0.3531 ± 0.0185 | 0.3239 ± 0.0186 | 0.4929 ± 0.0253 | 0.3296 ± 0.0205 |
| 5 | 0.4661 ± 0.0269 | 0.4115 ± 0.0272 | 0.6585 ± 0.0338 | 0.4060 ± 0.0287 |
| 7 | 0.5613 ± 0.0344 | 0.4869 ± 0.0349 | 0.7868 ± 0.0408 | 0.4557 ± 0.0337 |

### NEES, mean ± 95% CI (target 3.0)

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 1.88 ± 0.14 | 1.56 ± 0.12 | 4.04 ± 0.40 | 1.88 ± 0.16 |
| 3 | 4.73 ± 0.36 | 2.84 ± 0.27 | 17.90 ± 1.84 | 3.55 ± 0.37 |
| 5 | 8.13 ± 0.66 | 4.17 ± 0.44 | 30.60 ± 3.15 | 4.69 ± 0.57 |
| 7 | 11.97 ± 1.07 | 5.45 ± 0.65 | 43.36 ± 4.55 | 5.30 ± 0.66 |

### Gate activation rate (% of steps), mean

| alpha | strong_tracking | proposed |
|---|---|---|
| 1 | 29.1 | 6.6 |
| 3 | 96.5 | 62.3 |
| 5 | 99.4 | 82.8 |
| 7 | 99.5 | 90.3 |

### Paired Wilcoxon (proposed < baseline), RMSE, Holm-corrected

| baseline | alpha | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | 1 | +0.0014 | +0.6% | 0.3293 | 0.3293 | ns |
| nominal | 3 | -0.0235 | -6.7% | 0.007284 | 0.01457 | * |
| nominal | 5 | -0.0601 | -12.9% | 0.0002432 | 0.0007295 | *** |
| nominal | 7 | -0.1056 | -18.8% | 3.7e-06 | 1.48e-05 | *** |
| sage_husa | 1 | -0.0080 | -3.6% | 2.772e-05 | 0.0001109 | *** |
| sage_husa | 3 | +0.0057 | +1.8% | 0.9005 | 1 | ns |
| sage_husa | 5 | -0.0056 | -1.4% | 0.72 | 1 | ns |
| sage_husa | 7 | -0.0313 | -6.4% | 0.3109 | 0.9326 | ns |
| strong_tracking | 1 | -0.0381 | -15.2% | 1.52e-15 | 1.52e-15 | *** |
| strong_tracking | 3 | -0.1632 | -33.1% | 1.978e-18 | 7.912e-18 | *** |
| strong_tracking | 5 | -0.2525 | -38.3% | 1.978e-18 | 7.912e-18 | *** |
| strong_tracking | 7 | -0.3311 | -42.1% | 1.978e-18 | 7.912e-18 | *** |

### TOST equivalence (proposed vs sage_husa, bounds ±5% of SH mean)

| alpha | mean diff | bound | p(TOST) | equivalent at 5%? |
|---|---|---|---|---|
| 1 | -0.0080 | ±0.0110 | 0.06766 | no |
| 3 | +0.0057 | ±0.0162 | 0.0922 | no |
| 5 | -0.0056 | ±0.0206 | 0.1447 | no |
| 7 | -0.0313 | ±0.0243 | 0.6381 | no |

## Regime II — Non-stationary schedule 1→5→1→3 (T=400)

### Per-segment / total RMSE (m), mean ± 95% CI

| segment | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| alpha=1 matched | 0.1892 ± 0.0106 | 0.1956 ± 0.0107 | 0.2261 ± 0.0120 | 0.1884 ± 0.0106 |
| alpha=5 jump | 0.3945 ± 0.0252 | 0.2938 ± 0.0223 | 0.4674 ± 0.0129 | 0.2564 ± 0.0154 |
| alpha=1 recovery | 0.3016 ± 0.0316 | 0.2359 ± 0.0235 | 0.2450 ± 0.0171 | 0.2151 ± 0.0161 |
| alpha=3 mild | 0.2765 ± 0.0121 | 0.2366 ± 0.0114 | 0.3530 ± 0.0093 | 0.2231 ± 0.0105 |
| **total** | 0.3053 ± 0.0183 | 0.2476 ± 0.0153 | 0.3395 ± 0.0102 | 0.2252 ± 0.0112 |

### Post-transition RMSE (20 steps), mean ± 95% CI

| window | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| after 1to5 | 0.2979 ± 0.0197 | 0.2820 ± 0.0203 | 0.4132 ± 0.0160 | 0.2295 ± 0.0185 |
| after 5to1 | 0.3150 ± 0.0400 | 0.2231 ± 0.0298 | 0.2460 ± 0.0204 | 0.2044 ± 0.0193 |
| after 1to3 | 0.2860 ± 0.0220 | 0.2504 ± 0.0160 | 0.3236 ± 0.0122 | 0.2132 ± 0.0149 |

### Paired Wilcoxon (proposed < baseline), Holm-corrected (8 tests/family)

| baseline | quantity | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | total | -0.0802 | -26.3% | 5.923e-17 | 3.554e-16 | *** |
| nominal | alpha=1 matched | -0.0008 | -0.4% | 0.006813 | 0.006813 | ** |
| nominal | alpha=5 jump | -0.1381 | -35.0% | 4.324e-18 | 3.459e-17 | *** |
| nominal | alpha=1 recovery | -0.0865 | -28.7% | 3.885e-08 | 9.263e-08 | *** |
| nominal | alpha=3 mild | -0.0534 | -19.3% | 2.203e-17 | 1.542e-16 | *** |
| nominal | after 1to5 | -0.0685 | -23.0% | 3.572e-16 | 1.786e-15 | *** |
| nominal | after 5to1 | -0.1106 | -35.1% | 3.088e-08 | 9.263e-08 | *** |
| nominal | after 1to3 | -0.0728 | -25.5% | 1.131e-14 | 4.523e-14 | *** |
| sage_husa | total | -0.0224 | -9.1% | 5.766e-07 | 2.306e-06 | *** |
| sage_husa | alpha=1 matched | -0.0072 | -3.7% | 7.9e-10 | 5.53e-09 | *** |
| sage_husa | alpha=5 jump | -0.0374 | -12.7% | 4.064e-07 | 2.032e-06 | *** |
| sage_husa | alpha=1 recovery | -0.0208 | -8.8% | 0.01288 | 0.02576 | * |
| sage_husa | alpha=3 mild | -0.0136 | -5.7% | 1.893e-06 | 5.678e-06 | *** |
| sage_husa | after 1to5 | -0.0525 | -18.6% | 1.142e-12 | 9.139e-12 | *** |
| sage_husa | after 5to1 | -0.0187 | -8.4% | 0.3243 | 0.3243 | ns |
| sage_husa | after 1to3 | -0.0372 | -14.9% | 1.953e-09 | 1.172e-08 | *** |
| strong_tracking | total | -0.1144 | -33.7% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | alpha=1 matched | -0.0377 | -16.7% | 6.618e-16 | 1.985e-15 | *** |
| strong_tracking | alpha=5 jump | -0.2110 | -45.1% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | alpha=1 recovery | -0.0299 | -12.2% | 1.145e-06 | 1.145e-06 | *** |
| strong_tracking | alpha=3 mild | -0.1299 | -36.8% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | after 1to5 | -0.1838 | -44.5% | 2.039e-18 | 1.582e-17 | *** |
| strong_tracking | after 5to1 | -0.0415 | -16.9% | 1.661e-07 | 3.322e-07 | *** |
| strong_tracking | after 1to3 | -0.1104 | -34.1% | 5.021e-18 | 2.008e-17 | *** |

## Regime III — Short trajectory (T=50)

### Full-trajectory RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.4902 ± 0.0103 | 0.4903 ± 0.0105 | 0.5224 ± 0.0152 | 0.4887 ± 0.0104 |
| 3 | 0.5527 ± 0.0190 | 0.5497 ± 0.0192 | 0.6487 ± 0.0251 | 0.5292 ± 0.0175 |
| 5 | 0.6135 ± 0.0259 | 0.6061 ± 0.0264 | 0.7611 ± 0.0309 | 0.5560 ± 0.0220 |
| 7 | 0.6729 ± 0.0318 | 0.6606 ± 0.0326 | 0.8610 ± 0.0357 | 0.5694 ± 0.0253 |

### First-10-step RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.5892 ± 0.0119 | 0.5892 ± 0.0119 | 0.6131 ± 0.0200 | 0.5867 ± 0.0120 |
| 3 | 0.6110 ± 0.0200 | 0.6110 ± 0.0200 | 0.7031 ± 0.0354 | 0.5916 ± 0.0184 |
| 5 | 0.6342 ± 0.0251 | 0.6342 ± 0.0251 | 0.7883 ± 0.0430 | 0.5925 ± 0.0192 |
| 7 | 0.6579 ± 0.0290 | 0.6579 ± 0.0290 | 0.8696 ± 0.0486 | 0.5913 ± 0.0192 |

### Paired Wilcoxon (proposed < baseline), Holm-corrected (8 tests/family)

| baseline | quantity | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | rmse a=1 | -0.0014 | -0.3% | 0.04642 | 0.04642 | * |
| nominal | rmse a=3 | -0.0234 | -4.2% | 0.0002109 | 0.0006328 | *** |
| nominal | rmse a=5 | -0.0575 | -9.4% | 4.193e-08 | 2.096e-07 | *** |
| nominal | rmse a=7 | -0.1035 | -15.4% | 1.935e-13 | 1.548e-12 | *** |
| nominal | first10 a=1 | -0.0026 | -0.4% | 0.005429 | 0.01086 | * |
| nominal | first10 a=3 | -0.0194 | -3.2% | 1.674e-05 | 6.698e-05 | *** |
| nominal | first10 a=5 | -0.0417 | -6.6% | 1.447e-08 | 8.682e-08 | *** |
| nominal | first10 a=7 | -0.0666 | -10.1% | 2.744e-10 | 1.921e-09 | *** |
| sage_husa | rmse a=1 | -0.0015 | -0.3% | 0.0685 | 0.0685 | ns |
| sage_husa | rmse a=3 | -0.0204 | -3.7% | 0.001651 | 0.004954 | ** |
| sage_husa | rmse a=5 | -0.0501 | -8.3% | 1.956e-06 | 9.782e-06 | *** |
| sage_husa | rmse a=7 | -0.0912 | -13.8% | 4.012e-11 | 3.21e-10 | *** |
| sage_husa | first10 a=1 | -0.0026 | -0.4% | 0.005429 | 0.01086 | * |
| sage_husa | first10 a=3 | -0.0194 | -3.2% | 1.674e-05 | 6.698e-05 | *** |
| sage_husa | first10 a=5 | -0.0417 | -6.6% | 1.447e-08 | 8.682e-08 | *** |
| sage_husa | first10 a=7 | -0.0666 | -10.1% | 2.744e-10 | 1.921e-09 | *** |
| strong_tracking | rmse a=1 | -0.0337 | -6.4% | 2.435e-12 | 4.87e-12 | *** |
| strong_tracking | rmse a=3 | -0.1194 | -18.4% | 3.017e-18 | 1.81e-17 | *** |
| strong_tracking | rmse a=5 | -0.2051 | -26.9% | 2.166e-18 | 1.582e-17 | *** |
| strong_tracking | rmse a=7 | -0.2916 | -33.9% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | first10 a=1 | -0.0264 | -4.3% | 1.425e-06 | 1.425e-06 | *** |
| strong_tracking | first10 a=3 | -0.1115 | -15.9% | 3.456e-15 | 1.037e-14 | *** |
| strong_tracking | first10 a=5 | -0.1958 | -24.8% | 1.692e-17 | 6.768e-17 | *** |
| strong_tracking | first10 a=7 | -0.2783 | -32.0% | 3.402e-18 | 1.81e-17 | *** |
