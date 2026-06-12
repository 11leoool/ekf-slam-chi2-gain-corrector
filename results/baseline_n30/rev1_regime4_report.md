# Regime IV Statistical Report (R3: realistic validation)

Setup: M=50 random landmarks, figure-8 30x18 m field, max_range=8.0 m, FOV=180deg,
NN data association (chi2(2) 99% gate, no ground-truth correspondence),
per-step adaptive tau(d) at 10% target false-trigger rate. n=30 paired trials.

## IV-a: stationary symmetric mismatch

### Position RMSE (m), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.1034 ± 0.0022 | 0.1121 ± 0.0021 | 0.1097 ± 0.0027 | 0.1031 ± 0.0022 |
| 3 | 0.1701 ± 0.0050 | 0.1462 ± 0.0049 | 0.2260 ± 0.0070 | 0.1548 ± 0.0042 |
| 5 | 0.2446 ± 0.0092 | 0.1824 ± 0.0063 | 0.3884 ± 0.0865 | 0.1945 ± 0.0068 |
| 7 | 0.5174 ± 0.3769 | 0.2314 ± 0.0127 | 2.4974 ± 1.0032 | 0.2994 ± 0.1387 |

### Pose NEES (target 3.0), mean ± 95% CI

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 1.86 ± 0.06 | 1.56 ± 0.05 | 2.05 ± 0.08 | 1.85 ± 0.06 |
| 3 | 4.97 ± 0.28 | 2.19 ± 0.16 | 8.18 ± 0.47 | 3.74 ± 0.17 |
| 5 | 9.01 ± 0.65 | 3.15 ± 0.20 | 25.12 ± 20.05 | 5.24 ± 0.27 |
| 7 | 107.34 ± 187.71 | 4.58 ± 0.47 | 1141.23 ± 728.20 | 17.52 ± 21.62 |

### Gate calibration & association quality (proposed)

| alpha | gate rate % (target 10 @ a=1) | misassoc % | dropped % | mean N_t |
|---|---|---|---|---|
| 1 | 0.7 | 0.00 | 0.20 | 7.2 |
| 3 | 45.6 | 0.19 | 10.92 | 7.2 |
| 5 | 62.2 | 0.94 | 25.10 | 7.2 |
| 7 | 65.8 | 3.51 | 36.23 | 7.2 |

### Misassociation rate by filter (%), mean

| alpha | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| 1 | 0.00 | 0.01 | 0.00 | 0.00 |
| 3 | 0.30 | 0.40 | 0.22 | 0.19 |
| 5 | 1.22 | 1.71 | 2.13 | 0.94 |
| 7 | 5.97 | 4.15 | 27.03 | 3.51 |

### Paired Wilcoxon (proposed < baseline), RMSE, Holm within family

| baseline | alpha | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | 1 | -0.0003 | -0.3% | 8.361e-05 | 8.361e-05 | *** |
| nominal | 3 | -0.0153 | -9.0% | 1.238e-06 | 3.713e-06 | *** |
| nominal | 5 | -0.0501 | -20.5% | 9.127e-07 | 3.651e-06 | *** |
| nominal | 7 | -0.2180 | -42.1% | 1.487e-05 | 2.975e-05 | *** |
| sage_husa | 1 | -0.0090 | -8.0% | 9.127e-07 | 3.651e-06 | *** |
| sage_husa | 3 | +0.0086 | +5.9% | 0.9999 | 1 | ns |
| sage_husa | 5 | +0.0122 | +6.7% | 0.998 | 1 | ns |
| sage_husa | 7 | +0.0679 | +29.4% | 0.871 | 1 | ns |
| strong_tracking | 1 | -0.0066 | -6.1% | 9.127e-07 | 3.651e-06 | *** |
| strong_tracking | 3 | -0.0712 | -31.5% | 9.127e-07 | 3.651e-06 | *** |
| strong_tracking | 5 | -0.1938 | -49.9% | 9.127e-07 | 3.651e-06 | *** |
| strong_tracking | 7 | -2.1980 | -88.0% | 5.905e-06 | 5.905e-06 | *** |

## IV-b: non-stationary schedule 1 -> 5 -> 1 -> 3

### RMSE (m), mean ± 95% CI

| quantity | nominal | sage_husa | strong_tracking | proposed |
|---|---|---|---|---|
| total | 0.1561 ± 0.0035 | 0.1328 ± 0.0030 | 0.3273 ± 0.2480 | 0.1357 ± 0.0028 |
| a=1 matched | 0.1181 ± 0.0061 | 0.1215 ± 0.0061 | 0.1246 ± 0.0065 | 0.1180 ± 0.0061 |
| a=5 jump | 0.2051 ± 0.0065 | 0.1591 ± 0.0055 | 0.2963 ± 0.0274 | 0.1681 ± 0.0070 |
| a=1 recovery | 0.1070 ± 0.0078 | 0.0988 ± 0.0046 | 0.3089 ± 0.3580 | 0.0973 ± 0.0056 |
| a=3 mild | 0.1706 ± 0.0063 | 0.1422 ± 0.0050 | 0.4071 ± 0.3555 | 0.1457 ± 0.0059 |
| after 1to5 | 0.1673 ± 0.0101 | 0.1608 ± 0.0111 | 0.2394 ± 0.0138 | 0.1416 ± 0.0104 |
| after 5to1 | 0.1035 ± 0.0116 | 0.0807 ± 0.0080 | 0.2221 ± 0.1809 | 0.0896 ± 0.0077 |
| after 1to3 | 0.1579 ± 0.0134 | 0.1416 ± 0.0103 | 0.4144 ± 0.4112 | 0.1307 ± 0.0105 |

### Paired Wilcoxon (proposed < baseline), Holm within family (8 tests)

| baseline | quantity | mean diff | % change | p (raw) | p (Holm) | sig |
|---|---|---|---|---|---|---|
| nominal | total | -0.0203 | -13.0% | 9.127e-07 | 7.301e-06 | *** |
| nominal | a=1 matched | -0.0001 | -0.1% | 0.1719 | 0.1719 | ns |
| nominal | a=5 jump | -0.0369 | -18.0% | 1.369e-06 | 8.213e-06 | *** |
| nominal | a=1 recovery | -0.0098 | -9.1% | 3.598e-05 | 0.0001079 | *** |
| nominal | a=3 mild | -0.0249 | -14.6% | 9.127e-07 | 7.301e-06 | *** |
| nominal | after 1to5 | -0.0258 | -15.4% | 2.04e-06 | 1.02e-05 | *** |
| nominal | after 5to1 | -0.0139 | -13.5% | 0.0008249 | 0.00165 | ** |
| nominal | after 1to3 | -0.0272 | -17.2% | 3.019e-06 | 1.208e-05 | *** |
| sage_husa | total | +0.0029 | +2.2% | 0.9434 | 1 | ns |
| sage_husa | a=1 matched | -0.0035 | -2.9% | 1.947e-05 | 0.0001558 | *** |
| sage_husa | a=5 jump | +0.0090 | +5.7% | 0.9955 | 1 | ns |
| sage_husa | a=1 recovery | -0.0015 | -1.6% | 0.1938 | 0.9691 | ns |
| sage_husa | a=3 mild | +0.0035 | +2.5% | 0.9094 | 1 | ns |
| sage_husa | after 1to5 | -0.0192 | -11.9% | 0.0001068 | 0.0007478 | *** |
| sage_husa | after 5to1 | +0.0089 | +11.0% | 0.9829 | 1 | ns |
| sage_husa | after 1to3 | -0.0109 | -7.7% | 0.006409 | 0.03846 | * |
| strong_tracking | total | -0.1916 | -58.5% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | a=1 matched | -0.0067 | -5.3% | 9.42e-06 | 9.42e-06 | *** |
| strong_tracking | a=5 jump | -0.1281 | -43.3% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | a=1 recovery | -0.2116 | -68.5% | 1.119e-06 | 7.301e-06 | *** |
| strong_tracking | a=3 mild | -0.2614 | -64.2% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | after 1to5 | -0.0978 | -40.9% | 9.127e-07 | 7.301e-06 | *** |
| strong_tracking | after 5to1 | -0.1326 | -59.7% | 2.251e-06 | 7.301e-06 | *** |
| strong_tracking | after 1to3 | -0.2837 | -68.5% | 9.127e-07 | 7.301e-06 | *** |
