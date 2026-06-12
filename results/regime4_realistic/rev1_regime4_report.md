# Regime IV Statistical Report (R3: realistic validation)

Setup: M=50 random landmarks, figure-8 30x18 m field, max_range=8.0 m, FOV=180deg,
NN data association (chi2(2) 99% gate, no ground-truth correspondence),
per-step adaptive tau(d) at 10% target false-trigger rate. n=100 paired trials.

## IV-a: stationary symmetric mismatch

### Position RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.1024 ± 0.0013 | 0.1113 ± 0.0012 | 0.1087 ± 0.0016 | 0.1022 ± 0.0013 |
| 3 | 0.1705 ± 0.0026 | 0.1446 ± 0.0022 | 0.2257 ± 0.0040 | 0.1542 ± 0.0023 |
| 5 | 0.2501 ± 0.0149 | 0.1813 ± 0.0031 | 0.3796 ± 0.0461 | 0.1943 ± 0.0034 |
| 7 | 0.4930 ± 0.1585 | 0.2601 ± 0.0394 | 2.6330 ± 0.7158 | 0.2862 ± 0.0703 |

### Pose NEES (target 3.0), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 1.84 ± 0.04 | 1.55 ± 0.03 | 2.04 ± 0.05 | 1.83 ± 0.04 |
| 3 | 4.96 ± 0.14 | 2.14 ± 0.06 | 8.26 ± 0.27 | 3.74 ± 0.09 |
| 5 | 10.22 ± 2.45 | 3.07 ± 0.09 | 25.09 ± 11.59 | 5.22 ± 0.14 |
| 7 | 68.47 ± 62.09 | 6.92 ± 3.21 | 1380.22 ± 606.63 | 16.08 ± 12.99 |

### Gate calibration & association quality (proposed)

| alpha | gate rate % (target 10 @ a=1) | misassoc % | dropped % | mean N_t |
|---|---|---|---|---|
| 1 | 0.7 | 0.00 | 0.19 | 7.2 |
| 3 | 45.3 | 0.19 | 10.86 | 7.2 |
| 5 | 62.1 | 0.90 | 24.94 | 7.2 |
| 7 | 65.9 | 3.43 | 36.13 | 7.2 |

### Misassociation rate by filter (%), mean

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.00 | 0.01 | 0.00 | 0.00 |
| 3 | 0.27 | 0.36 | 0.29 | 0.19 |
| 5 | 1.40 | 1.64 | 2.20 | 0.90 |
| 7 | 5.60 | 4.75 | 24.10 | 3.43 |

### Paired Wilcoxon (proposed < baseline), RMSE, Holm within family

| baseline | alpha | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | 1 | -0.0002 | -0.2% | 3.825e-10 | 3.825e-10 | *** |
| nominal | 3 | -0.0163 | -9.6% | 2.443e-18 | 7.912e-18 | *** |
| nominal | 5 | -0.0558 | -22.3% | 1.978e-18 | 7.912e-18 | *** |
| nominal | 7 | -0.2068 | -41.9% | 5.596e-16 | 1.119e-15 | *** |
| sage_husa | 1 | -0.0091 | -8.2% | 1.978e-18 | 7.912e-18 | *** |
| sage_husa | 3 | +0.0096 | +6.6% | 1 | 1 | ns |
| sage_husa | 5 | +0.0130 | +7.2% | 1 | 1 | ns |
| sage_husa | 7 | +0.0260 | +10.0% | 0.9915 | 1 | ns |
| strong_tracking | 1 | -0.0065 | -6.0% | 2.3e-18 | 7.912e-18 | *** |
| strong_tracking | 3 | -0.0715 | -31.7% | 1.978e-18 | 7.912e-18 | *** |
| strong_tracking | 5 | -0.1853 | -48.8% | 1.978e-18 | 7.912e-18 | *** |
| strong_tracking | 7 | -2.3468 | -89.1% | 1.181e-16 | 1.181e-16 | *** |

## IV-b: non-stationary schedule 1 -> 5 -> 1 -> 3

### RMSE (m), mean ± 95% CI

| quantity | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| total | 0.1554 ± 0.0022 | 0.1330 ± 0.0016 | 0.2413 ± 0.0723 | 0.1368 ± 0.0016 |
| a=1 matched | 0.1172 ± 0.0031 | 0.1213 ± 0.0031 | 0.1233 ± 0.0034 | 0.1171 ± 0.0031 |
| a=5 jump | 0.2026 ± 0.0039 | 0.1591 ± 0.0029 | 0.2872 ± 0.0094 | 0.1677 ± 0.0038 |
| a=1 recovery | 0.1108 ± 0.0047 | 0.0996 ± 0.0026 | 0.1860 ± 0.1044 | 0.1031 ± 0.0037 |
| a=3 mild | 0.1689 ± 0.0033 | 0.1424 ± 0.0027 | 0.2818 ± 0.1037 | 0.1465 ± 0.0032 |
| after 1to5 | 0.1654 ± 0.0055 | 0.1604 ± 0.0064 | 0.2401 ± 0.0071 | 0.1416 ± 0.0063 |
| after 5to1 | 0.1084 ± 0.0076 | 0.0835 ± 0.0046 | 0.1577 ± 0.0533 | 0.0980 ± 0.0062 |
| after 1to3 | 0.1567 ± 0.0071 | 0.1453 ± 0.0052 | 0.2718 ± 0.1200 | 0.1332 ± 0.0056 |

### Paired Wilcoxon (proposed < baseline), Holm within family (8 tests)

| baseline | quantity | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | total | -0.0186 | -11.9% | 1.978e-18 | 1.582e-17 | *** |
| nominal | a=1 matched | -0.0002 | -0.2% | 0.009591 | 0.009591 | ** |
| nominal | a=5 jump | -0.0349 | -17.2% | 3.204e-18 | 1.922e-17 | *** |
| nominal | a=1 recovery | -0.0077 | -6.9% | 3.399e-08 | 1.02e-07 | *** |
| nominal | a=3 mild | -0.0223 | -13.2% | 2.166e-18 | 1.582e-17 | *** |
| nominal | after 1to5 | -0.0238 | -14.4% | 1.324e-15 | 5.298e-15 | *** |
| nominal | after 5to1 | -0.0104 | -9.6% | 2.732e-05 | 5.463e-05 | *** |
| nominal | after 1to3 | -0.0235 | -15.0% | 9.241e-16 | 4.621e-15 | *** |
| sage_husa | total | +0.0038 | +2.9% | 0.9999 | 1 | ns |
| sage_husa | a=1 matched | -0.0042 | -3.5% | 8.614e-17 | 6.892e-16 | *** |
| sage_husa | a=5 jump | +0.0086 | +5.4% | 1 | 1 | ns |
| sage_husa | a=1 recovery | +0.0035 | +3.6% | 0.9935 | 1 | ns |
| sage_husa | a=3 mild | +0.0041 | +2.9% | 0.9957 | 1 | ns |
| sage_husa | after 1to5 | -0.0188 | -11.7% | 1.341e-09 | 9.384e-09 | *** |
| sage_husa | after 5to1 | +0.0145 | +17.4% | 1 | 1 | ns |
| sage_husa | after 1to3 | -0.0121 | -8.3% | 9.681e-06 | 5.809e-05 | *** |
| strong_tracking | total | -0.1044 | -43.3% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | a=1 matched | -0.0063 | -5.1% | 1.442e-16 | 4.327e-16 | *** |
| strong_tracking | a=5 jump | -0.1195 | -41.6% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | a=1 recovery | -0.0828 | -44.5% | 2.029e-16 | 4.327e-16 | *** |
| strong_tracking | a=3 mild | -0.1352 | -48.0% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | after 1to5 | -0.0985 | -41.0% | 1.978e-18 | 1.582e-17 | *** |
| strong_tracking | after 5to1 | -0.0597 | -37.9% | 2.902e-13 | 2.902e-13 | *** |
| strong_tracking | after 1to3 | -0.1386 | -51.0% | 2.3e-18 | 1.582e-17 | *** |
