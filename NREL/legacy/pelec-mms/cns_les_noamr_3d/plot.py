#!/usr/bin/env python3

# ========================================================================
#
# Imports
#
# ========================================================================
import argparse
import sys
import os
import numpy as np
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
import glob

# ========================================================================
#
# Some defaults variables
#
# ========================================================================
plt.rc('text', usetex=True)
plt.rc('font', family='serif', serif='Times')
cmap_med = ['#F15A60', '#7AC36A', '#5A9BD4', '#FAA75B',
            '#9E67AB', '#CE7058', '#D77FB4', '#737373']
cmap = ['#EE2E2F', '#008C48', '#185AA9', '#F47D23',
        '#662C91', '#A21D21', '#B43894', '#010202']
dashseq = [(None, None), [10, 5], [10, 4, 3, 4], [
    3, 3], [10, 4, 3, 4, 3, 4], [3, 3], [3, 3]]
markertype = ['s', 'd', 'o', 'p', 'h']


# ========================================================================
#
# Function definitions
#
# ========================================================================
def get_ic(fdir):
    """Get some normalizing quantities."""

    fname = glob.glob(os.path.join(fdir, 'mms.o*'))

    with open(fname[0]) as f:

        for line in f:
            if line.startswith('rho_0 is set to'):
                rho0 = float(line.split()[-1])

            if line.startswith('u_0 is set to'):
                u0 = float(line.split()[-1])

            if line.startswith('p_0 is set to'):
                p0 = float(line.split()[-1])

            if line.startswith('L is set to'):
                L = float(line.split()[-1])

    return rho0, u0, p0, L


# ========================================================================
#
# Main
#
# ========================================================================
if __name__ == '__main__':

    # ========================================================================
    # Parse arguments
    parser = argparse.ArgumentParser(
        description='A simple plot tool')
    parser.add_argument(
        '-s', '--show', help='Show the plots', action='store_true')
    args = parser.parse_args()

    # ======================================================================
    # Pele data
    resolutions = [8, 16, 32, 64]
    lst = []

    for k, res in enumerate(resolutions):
        fname = os.path.join(os.path.abspath(str(res)), 'mmslog')
        df = pd.read_csv(fname, delim_whitespace=True)

        rho0, u0, p0, L = get_ic(os.path.abspath(str(res)))
        u0 = 1

        idx = -1
        print('Loading {0:d} at t = {1:e} (step = {2:d})'.format(
            res, df['time'].iloc[idx], df.index[idx]))
        lst.append([res,
                    1. / res,
                    df['rho_mms_err'].iloc[idx] / rho0,
                    df['u_mms_err'].iloc[idx] / u0,
                    df['v_mms_err'].iloc[idx] / u0,
                    df['w_mms_err'].iloc[idx] / u0,
                    df['p_mms_err'].iloc[idx] / p0])

    edf = pd.DataFrame(lst,
                       columns=['resolution', 'dx', 'rho_mms_err', 'u_mms_err', 'v_mms_err', 'w_mms_err', 'p_mms_err'])

    # Get OOA
    data = np.zeros((len(edf['resolution']) - 1, 5))
    data[:, 0] = -np.diff(np.log(edf['rho_mms_err'])) / \
        np.diff(np.log(edf['resolution']))
    data[:, 1] = -np.diff(np.log(edf['u_mms_err'])) / \
        np.diff(np.log(edf['resolution']))
    data[:, 2] = -np.diff(np.log(edf['v_mms_err'])) / \
        np.diff(np.log(edf['resolution']))
    data[:, 3] = -np.diff(np.log(edf['w_mms_err'])) / \
        np.diff(np.log(edf['resolution']))
    data[:, 4] = -np.diff(np.log(edf['p_mms_err'])) / \
        np.diff(np.log(edf['resolution']))
    ooa = pd.DataFrame(data,
                       columns=['rho_ooa', 'u_ooa', 'v_ooa', 'w_ooa', 'p_ooa'])
    print(ooa)

    # Plot
    plt.figure(0)
    p = plt.loglog(edf['resolution'], edf['rho_mms_err'], ls='-', lw=2, color=cmap[0],
                   marker=markertype[0], mec=cmap[0], mfc=cmap[0], ms=10, label='Pele')
    p[0].set_dashes(dashseq[0])

    plt.figure(1)
    p = plt.loglog(edf['resolution'], edf['u_mms_err'], ls='-', lw=2, color=cmap[0],
                   marker=markertype[0], mec=cmap[0], mfc=cmap[0], ms=10, label='Pele')
    p[0].set_dashes(dashseq[0])

    plt.figure(2)
    p = plt.loglog(edf['resolution'], edf['v_mms_err'], ls='-', lw=2, color=cmap[0],
                   marker=markertype[0], mec=cmap[0], mfc=cmap[0], ms=10, label='Pele')
    p[0].set_dashes(dashseq[0])

    plt.figure(3)
    p = plt.loglog(edf['resolution'], edf['w_mms_err'], ls='-', lw=2, color=cmap[0],
                   marker=markertype[0], mec=cmap[0], mfc=cmap[0], ms=10, label='Pele')
    p[0].set_dashes(dashseq[0])

    plt.figure(4)
    p = plt.loglog(edf['resolution'], edf['p_mms_err'], ls='-', lw=2, color=cmap[0],
                   marker=markertype[0], mec=cmap[0], mfc=cmap[0], ms=10, label='Pele')
    p[0].set_dashes(dashseq[0])

    # ======================================================================
    # Theoretical error
    order = 2.0
    idx = 1
    edf['rho_theory'] = edf['rho_mms_err'].iloc[idx] * \
        (edf['resolution'].iloc[idx] / edf['resolution'])**order
    edf['u_theory'] = edf['u_mms_err'].iloc[idx] * \
        (edf['resolution'].iloc[idx] / edf['resolution'])**order
    edf['v_theory'] = edf['v_mms_err'].iloc[idx] * \
        (edf['resolution'].iloc[idx] / edf['resolution'])**order
    edf['w_theory'] = edf['w_mms_err'].iloc[idx] * \
        (edf['resolution'].iloc[idx] / edf['resolution'])**order
    edf['p_theory'] = edf['p_mms_err'].iloc[idx] * \
        (edf['resolution'].iloc[idx] / edf['resolution'])**order

    plt.figure(0)
    p = plt.loglog(edf['resolution'], edf['rho_theory'],
                   ls='-', lw=2, color=cmap[-1], label='2nd order')
    p[0].set_dashes(dashseq[0])

    plt.figure(1)
    p = plt.loglog(edf['resolution'], edf['u_theory'],
                   ls='-', lw=2, color=cmap[-1], label='2nd order')
    p[0].set_dashes(dashseq[0])

    plt.figure(2)
    p = plt.loglog(edf['resolution'], edf['v_theory'],
                   ls='-', lw=2, color=cmap[-1], label='2nd order')
    p[0].set_dashes(dashseq[0])

    plt.figure(3)
    p = plt.loglog(edf['resolution'], edf['w_theory'],
                   ls='-', lw=2, color=cmap[-1], label='2nd order')
    p[0].set_dashes(dashseq[0])

    plt.figure(4)
    p = plt.loglog(edf['resolution'], edf['p_theory'],
                   ls='-', lw=2, color=cmap[-1], label='2nd order')
    p[0].set_dashes(dashseq[0])

    # ======================================================================
    # Format the plots
    plt.figure(0)
    ax = plt.gca()
    plt.xlabel(r"$N$", fontsize=22, fontweight='bold')
    plt.ylabel(r"$e_\rho$", fontsize=22, fontweight='bold')
    plt.setp(ax.get_xmajorticklabels(), fontsize=18, fontweight='bold')
    plt.setp(ax.get_ymajorticklabels(), fontsize=18, fontweight='bold')
    legend = ax.legend(loc='best')
    plt.tight_layout()
    plt.savefig('rho_error.pdf', format='pdf')
    plt.savefig('rho_error.png', format='png')

    plt.figure(1)
    ax = plt.gca()
    plt.xlabel(r"$N$", fontsize=22, fontweight='bold')
    plt.ylabel(r"$e_u$", fontsize=22, fontweight='bold')
    plt.setp(ax.get_xmajorticklabels(), fontsize=18, fontweight='bold')
    plt.setp(ax.get_ymajorticklabels(), fontsize=18, fontweight='bold')
    legend = ax.legend(loc='best')
    plt.tight_layout()
    plt.savefig('u_error.pdf', format='pdf')
    plt.savefig('u_error.png', format='png')

    plt.figure(2)
    ax = plt.gca()
    plt.xlabel(r"$N$", fontsize=22, fontweight='bold')
    plt.ylabel(r"$e_v$", fontsize=22, fontweight='bold')
    plt.setp(ax.get_xmajorticklabels(), fontsize=18, fontweight='bold')
    plt.setp(ax.get_ymajorticklabels(), fontsize=18, fontweight='bold')
    legend = ax.legend(loc='best')
    plt.tight_layout()
    plt.savefig('v_error.pdf', format='pdf')
    plt.savefig('v_error.png', format='png')

    plt.figure(3)
    ax = plt.gca()
    plt.xlabel(r"$N$", fontsize=22, fontweight='bold')
    plt.ylabel(r"$e_w$", fontsize=22, fontweight='bold')
    plt.setp(ax.get_xmajorticklabels(), fontsize=18, fontweight='bold')
    plt.setp(ax.get_ymajorticklabels(), fontsize=18, fontweight='bold')
    legend = ax.legend(loc='best')
    plt.tight_layout()
    plt.savefig('w_error.pdf', format='pdf')
    plt.savefig('w_error.png', format='png')

    plt.figure(4)
    ax = plt.gca()
    plt.xlabel(r"$N$", fontsize=22, fontweight='bold')
    plt.ylabel(r"$e_p$", fontsize=22, fontweight='bold')
    plt.setp(ax.get_xmajorticklabels(), fontsize=18, fontweight='bold')
    plt.setp(ax.get_ymajorticklabels(), fontsize=18, fontweight='bold')
    legend = ax.legend(loc='best')
    plt.tight_layout()
    plt.savefig('p_error.pdf', format='pdf')
    plt.savefig('p_error.png', format='png')

    if args.show:
        plt.show()
