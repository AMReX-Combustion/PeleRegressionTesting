#!/usr/bin/env python3

# ========================================================================
#
# Imports
#
# ========================================================================
import sys
import os
import re
import numpy as np
import numpy.testing as npt
import matplotlib as mpl

mpl.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
import glob
import unittest

# ========================================================================
#
# Some defaults variables
#
# ========================================================================
# plt.rc('text', usetex=True)
# plt.rc('font', family='serif', serif='Times')
cmap_med = [
    "#F15A60",
    "#7AC36A",
    "#5A9BD4",
    "#FAA75B",
    "#9E67AB",
    "#CE7058",
    "#D77FB4",
    "#737373",
]
cmap = [
    "#EE2E2F",
    "#008C48",
    "#185AA9",
    "#F47D23",
    "#662C91",
    "#A21D21",
    "#B43894",
    "#010202",
]
dashseq = [
    (None, None),
    [10, 5],
    [10, 4, 3, 4],
    [3, 3],
    [10, 4, 3, 4, 3, 4],
    [3, 3],
    [3, 3],
]
markertype = ["s", "d", "o", "p", "h"]


# ========================================================================
#
# Function definitions
#
# ========================================================================
def get_ic(fdir):
    """Get some normalizing quantities."""

    with open(os.path.join(fdir, "mms.out")) as f:

        for line in f:
            if line.startswith("rho_0 is set to"):
                rho0 = float(line.split()[-1])

            if line.startswith("u_0 is set to"):
                u0 = float(line.split()[-1])

            if line.startswith("p_0 is set to"):
                p0 = float(line.split()[-1])

            if line.startswith("L is set to"):
                L = float(line.split()[-1])

    return rho0, u0, p0, L


def load_pelec_error(fdir, theory_order):
    """Load the error for each resolution"""
    lst = []
    resolutions = sorted(
        [
            int(f)
            for f in os.listdir(fdir)
            if os.path.isdir(os.path.join(fdir, f)) and re.match("^[0-9]+$", f)
        ],
        key=int,
    )
    resdirs = [os.path.join(fdir, str(res)) for res in resolutions]

    for k, (res, resdir) in enumerate(zip(resolutions, resdirs)):

        fname = os.path.join(resdir, "mmslog")
        df = pd.read_csv(fname, delim_whitespace=True)

        rho0, u0, p0, L = get_ic(resdir)

        idx = -1
        print(
            "Loading {0:d} at t = {1:e} (step = {2:d})".format(
                res, df["time"].iloc[idx], df.index[idx]
            )
        )
        lst.append(
            [
                res,
                1. / res,
                df["rho_mms_err"].iloc[idx] / rho0,
                df["u_mms_err"].iloc[idx],
                df["v_mms_err"].iloc[idx],
                df["w_mms_err"].iloc[idx],
                df["p_mms_err"].iloc[idx] / p0,
            ]
        )

    edf = pd.DataFrame(
        lst,
        columns=[
            "resolution",
            "dx",
            "rho_mms_err",
            "u_mms_err",
            "v_mms_err",
            "w_mms_err",
            "p_mms_err",
        ],
    )

    # Theoretical error
    idx = 1
    edf["rho_theory"] = (
        edf["rho_mms_err"].iloc[idx]
        * (edf["resolution"].iloc[idx] / edf["resolution"]) ** theory_order
    )
    edf["u_theory"] = (
        edf["u_mms_err"].iloc[idx]
        * (edf["resolution"].iloc[idx] / edf["resolution"]) ** theory_order
    )
    edf["v_theory"] = (
        edf["v_mms_err"].iloc[idx]
        * (edf["resolution"].iloc[idx] / edf["resolution"]) ** theory_order
    )
    edf["w_theory"] = (
        edf["w_mms_err"].iloc[idx]
        * (edf["resolution"].iloc[idx] / edf["resolution"]) ** theory_order
    )
    edf["p_theory"] = (
        edf["p_mms_err"].iloc[idx]
        * (edf["resolution"].iloc[idx] / edf["resolution"]) ** theory_order
    )

    return edf.loc[:, (edf != 0).any(axis=0)]


def calculate_ooa(edf):
    """Calculate the order of accuracy given an error dataframe."""

    sfx_mms = "_mms_err"
    fields = [re.sub(sfx_mms, "", col) for col in edf.columns if col.endswith(sfx_mms)]

    columns = []
    data = np.zeros((len(edf["resolution"]) - 1, len(fields)))
    for k, field in enumerate(fields):
        columns.append(field + "_ooa")
        data[:, k] = -np.diff(np.log(edf[field + sfx_mms])) / np.diff(
            np.log(edf["resolution"])
        )
    ooa = pd.DataFrame(data, columns=columns)

    return ooa.dropna(axis=1, how="any")


def plot_errors(fdir, edf):
    """Plot the error dataframe."""

    sfx_mms = "_mms_err"
    fields = [re.sub(sfx_mms, "", col) for col in edf.columns if col.endswith(sfx_mms)]

    plt.close("all")
    for k, field in enumerate(fields):

        plt.figure(k)
        p = plt.loglog(
            edf["resolution"],
            edf[field + sfx_mms],
            ls="-",
            lw=2,
            color=cmap[0],
            marker=markertype[0],
            mec=cmap[0],
            mfc=cmap[0],
            ms=10,
            label="Pele",
        )
        p = plt.loglog(
            edf["resolution"],
            edf[field + "_theory"],
            ls="-",
            lw=2,
            color=cmap[-1],
            label="2nd order",
        )

        # Format the plots
        ax = plt.gca()
        plt.xlabel(r"$N$", fontsize=22, fontweight="bold")
        plt.ylabel(
            r"$e_{0:s}$".format("{" + field + "}"), fontsize=22, fontweight="bold"
        )
        plt.setp(ax.get_xmajorticklabels(), fontsize=18, fontweight="bold")
        plt.setp(ax.get_ymajorticklabels(), fontsize=18, fontweight="bold")
        legend = ax.legend(loc="best")
        plt.tight_layout()
        plt.savefig(os.path.join(fdir, field + "_error.png"), format="png")


# ========================================================================
#
# Test definitions
#
# ========================================================================
class MMSTestCase(unittest.TestCase):
    """Tests for the order of accuracy in PeleC."""

    def setUp(self):

        self.theory_order = 2.0
        self.parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    def test_symmetry(self):
        """Is the MMS error symmetric with symmetric IC (u,v,w)?"""

        # Load the data
        fdir = os.path.abspath(os.path.join(self.parent_dir, "symmetry_3d"))
        fname = os.path.join(fdir, "mmslog")
        df = pd.read_csv(fname, delim_whitespace=True)
        npt.assert_allclose(df.u_mms_err, df.v_mms_err, rtol=1e-13)
        npt.assert_allclose(df.u_mms_err, df.w_mms_err, rtol=1e-13)
        npt.assert_allclose(df.rhou_residual, df.rhov_residual, rtol=1e-13)
        npt.assert_allclose(df.rhou_residual, df.rhow_residual, rtol=1e-13)

    def test_cns_noamr(self):
        """Is the CNS no AMR (3D) PeleC second order accurate?"""

        # Load the data
        fdir = os.path.abspath(os.path.join(self.parent_dir, "cns_noamr_3d"))
        edf = load_pelec_error(fdir, self.theory_order)
        ooa = calculate_ooa(edf)

        # Plot the errors
        plot_errors(fdir, edf)

        # Test against theoretical OOA
        npt.assert_allclose(np.array(ooa.iloc[-1]), self.theory_order, rtol=1e-2)

    def test_cns_noamr_mol(self):
        """Is the CNS no AMR (3D) with MOL PeleC second order accurate?"""

        # Load the data
        fdir = os.path.abspath(os.path.join(self.parent_dir, "cns_noamr_mol_3d"))
        edf = load_pelec_error(fdir, self.theory_order)
        ooa = calculate_ooa(edf)

        # Plot the errors
        plot_errors(fdir, edf)

        # Test against theoretical OOA
        npt.assert_allclose(np.array(ooa.iloc[-1]), self.theory_order, rtol=5e-2)

    def test_cns_noamr_2d(self):
        """Is the CNS no AMR (2D) PeleC second order accurate?"""

        # Load the data
        fdir = os.path.abspath(os.path.join(self.parent_dir, "cns_noamr_2d"))
        edf = load_pelec_error(fdir, self.theory_order)
        ooa = calculate_ooa(edf)

        # Plot the errors
        plot_errors(fdir, edf)

        # Test against theoretical OOA
        npt.assert_allclose(np.array(ooa.iloc[-1]), self.theory_order, rtol=5e-2)

    def test_cns_noamr_mol_2d(self):
        """Is the CNS no AMR (2D) with MOL PeleC second order accurate?"""

        # Load the data
        fdir = os.path.abspath(os.path.join(self.parent_dir, "cns_noamr_mol_2d"))
        edf = load_pelec_error(fdir, self.theory_order)
        ooa = calculate_ooa(edf)

        # Plot the errors
        plot_errors(fdir, edf)

        # Test against theoretical OOA
        npt.assert_allclose(np.array(ooa.iloc[-1]), self.theory_order, rtol=5e-2)

    def test_cns_noamr_1d(self):
        """Is the CNS no AMR (1D) PeleC second order accurate?"""

        # Load the data
        fdir = os.path.abspath(os.path.join(self.parent_dir, "cns_noamr_1d"))
        edf = load_pelec_error(fdir, self.theory_order)
        ooa = calculate_ooa(edf)

        # Plot the errors
        plot_errors(fdir, edf)

        # Test against theoretical OOA
        npt.assert_allclose(np.array(ooa.iloc[-1]), self.theory_order, rtol=2e-1)

    def test_cns_amr(self):
        """Is the CNS with AMR PeleC second order accurate?"""

        # Load the data
        fdir = os.path.abspath(os.path.join(self.parent_dir, "cns_amr_3d"))
        edf = load_pelec_error(fdir, self.theory_order)
        ooa = calculate_ooa(edf)

        # Plot the errors
        plot_errors(fdir, edf)

        # Test against theoretical OOA
        npt.assert_allclose(np.array(ooa.iloc[-1]), self.theory_order, rtol=2e-1)


# ========================================================================
#
# Main
#
# ========================================================================
if __name__ == "__main__":
    unittest.main()
