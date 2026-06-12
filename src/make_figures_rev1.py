"""Regenerate manuscript figures 1-5 with the strong-tracking baseline and
95% CI error bars, from the rev1 .mat result files.

Run from revision-prep/src:  python make_figures_rev1.py
Outputs overwrite ../../figures/figure_{1..5}.pdf (originals backed up in
figures/v4_originals/).
"""
import numpy as np
from scipy import stats
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

RESULTS = Path("../results")
FIGDIR = Path("../../figures")

FILTERS = ["nominal", "sage_husa", "strong_tracking", "proposed"]
LABELS = {"nominal": "Nominal EKF", "sage_husa": "Sage--Husa",
          "strong_tracking": "Strong tracking", "proposed": "Proposed"}
COLORS = {"nominal": "#7f7f7f", "sage_husa": "#1f77b4",
          "strong_tracking": "#ff9933", "proposed": "#d62728"}
ALPHAS = [1, 3, 5, 7]

plt.rcParams.update({
    "font.size": 12, "axes.spines.top": False, "axes.spines.right": False,
    "axes.labelsize": 13, "legend.frameon": False, "pdf.fonttype": 42,
})


def ci95(v):
    v = np.asarray(v, dtype=float).ravel()
    n = v.size
    return stats.t.ppf(0.975, n - 1) * v.std(ddof=1) / np.sqrt(n)


def load(p):
    return loadmat(p, squeeze_me=True, struct_as_record=False)


R1 = load(RESULTS / "regime1_stationary" / "rev1_stationary_results.mat")["results"]
R2 = load(RESULTS / "regime2_nonstationary" / "rev1_nonstationary_results.mat")
R3 = load(RESULTS / "regime3_short" / "rev1_short_results.mat")["results"]


def cond(mtype, a):
    return getattr(R1, f"circular_lm3_{mtype}_a{a}")


# ====================================================================
# Figure 1 - stationary RMSE grouped bars + 95% CI
# ====================================================================
fig, ax = plt.subplots(figsize=(8.2, 5.2))
width = 0.2
x = np.arange(len(ALPHAS))
for k, f in enumerate(FILTERS):
    means = [np.mean(getattr(cond("symmetric", a), f).rmse) for a in ALPHAS]
    cis = [ci95(getattr(cond("symmetric", a), f).rmse) for a in ALPHAS]
    pos = x + (k - 1.5) * width
    ax.bar(pos, means, width * 0.92, yerr=cis, capsize=3,
           color=COLORS[f], label=LABELS[f], error_kw={"lw": 1.1})
    for xx, m, c in zip(pos, means, cis):
        ax.text(xx, m + c + 0.015, f"{m:.3f}", ha="center", va="bottom",
                fontsize=8, rotation=90)
ax.set_xticks(x)
ax.set_xticklabels([rf"$\alpha$ = {a}" for a in ALPHAS])
ax.set_xlabel(r"Mismatch factor $\alpha$")
ax.set_ylabel("Mean position RMSE (m)")
ax.set_ylim(0, 1.0)
ax.legend(ncol=2, loc="upper left")
fig.tight_layout()
fig.savefig(FIGDIR / "figure_1.pdf")
plt.close(fig)

# ====================================================================
# Figure 2 - stationary NEES, log scale, target line
# ====================================================================
fig, ax = plt.subplots(figsize=(6.8, 4.6))
for f in FILTERS:
    means = [np.mean(getattr(cond("symmetric", a), f).nees_avg) for a in ALPHAS]
    cis = [ci95(getattr(cond("symmetric", a), f).nees_avg) for a in ALPHAS]
    ax.errorbar(ALPHAS, means, yerr=cis, marker="o", ms=5, capsize=3,
                color=COLORS[f], label=LABELS[f], lw=1.8)
ax.axhline(3.0, ls="--", color="k", lw=1, alpha=0.7)
ax.text(1.05, 3.25, "consistency target (3.0)", fontsize=9, alpha=0.8)
ax.set_yscale("log")
ax.set_xticks(ALPHAS)
ax.set_xlabel(r"Mismatch factor $\alpha$")
ax.set_ylabel("Mean pose NEES (log scale)")
ax.legend(ncol=2, loc="upper left", fontsize=10)
fig.tight_layout()
fig.savefig(FIGDIR / "figure_2.pdf")
plt.close(fig)

# ====================================================================
# Figure 3 - gate activation rate (proposed) by mismatch type
# ====================================================================
fig, ax = plt.subplots(figsize=(6.8, 4.6))
mt_styles = {"symmetric": ("#d62728", "o", "Symmetric"),
             "R_only": ("#9467bd", "s", "R-only"),
             "Q_only": ("#2ca02c", "^", "Q-only")}
for mtype, (c, mk, lbl) in mt_styles.items():
    rates = [100 * np.mean(getattr(cond(mtype, a), "proposed").gate_pct) for a in ALPHAS]
    ax.plot(ALPHAS, rates, marker=mk, ms=6, color=c, label=lbl, lw=1.8)
ax.set_xticks(ALPHAS)
ax.set_xlabel(r"Mismatch factor $\alpha$")
ax.set_ylabel("Gate activation rate (%)")
ax.set_ylim(0, 100)
ax.legend(loc="center right", fontsize=10)
fig.tight_layout()
fig.savefig(FIGDIR / "figure_3.pdf")
plt.close(fig)

# ====================================================================
# Figure 4 - non-stationary per-step error
# ====================================================================
res2 = R2["results"]
T = 400


def smooth(v, w=5):
    return np.convolve(v, np.ones(w) / w, mode="same")


fig, ax = plt.subplots(figsize=(10.5, 4.8))
for f in FILTERS:
    per_step = np.mean(getattr(res2, f).rmse_per_step, axis=0)
    ax.plot(np.arange(1, T + 1), smooth(per_step), color=COLORS[f],
            label=LABELS[f], lw=1.7)
for tx in (100, 200, 300):
    ax.axvline(tx, ls=":", color="gray", lw=1, alpha=0.7)
ylo, yhi = ax.get_ylim()
for centre, lbl in ((50, r"$\alpha$ = 1"), (150, r"$\alpha$ = 5"),
                    (250, r"$\alpha$ = 1"), (350, r"$\alpha$ = 3")):
    ax.text(centre, ylo + 0.03 * (yhi - ylo), lbl, ha="center",
            fontsize=11, color="dimgray")
sage = smooth(np.mean(res2.sage_husa.rmse_per_step, axis=0))
ax.annotate("Sage--Husa\nadaptation lag", xy=(112, sage[111]),
            xytext=(30, ylo + 0.82 * (yhi - ylo)), fontsize=10, color="#1f77b4",
            arrowprops=dict(arrowstyle="->", color="#1f77b4", lw=1))
ax.set_xlabel("Timestep")
ax.set_ylabel("Position error (m)")
ax.set_xlim(1, T)
ax.legend(ncol=4, loc="upper right", fontsize=10)
fig.tight_layout()
fig.savefig(FIGDIR / "figure_4.pdf")
plt.close(fig)

# ====================================================================
# Figure 5 - short trajectory, two panels
# ====================================================================
fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.4), sharex=True)
for ax, field, title in ((axes[0], "rmse", "(a) Full trajectory ($T=50$)"),
                         (axes[1], "rmse_first10", "(b) First 10 timesteps")):
    for f in FILTERS:
        means = [np.mean(getattr(getattr(R3, f"a{a}"), f).__getattribute__(field))
                 for a in ALPHAS]
        cis = [ci95(getattr(getattr(R3, f"a{a}"), f).__getattribute__(field))
               for a in ALPHAS]
        ax.errorbar(ALPHAS, means, yerr=cis, marker="o", ms=5, capsize=3,
                    color=COLORS[f], label=LABELS[f], lw=1.8)
    ax.set_xticks(ALPHAS)
    ax.set_xlabel(r"Mismatch factor $\alpha$")
    ax.set_title(title, fontsize=12)
axes[0].set_ylabel("Mean position RMSE (m)")
axes[0].legend(fontsize=9, loc="upper left")
fig.tight_layout()
fig.savefig(FIGDIR / "figure_5.pdf")
plt.close(fig)

print("FIGURES_DONE:", sorted(p.name for p in FIGDIR.glob("figure_*.pdf")))
