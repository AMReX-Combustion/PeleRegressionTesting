#!/usr/bin/env python3
#
#
"""@package plotting

"""
__author__ = 'Marc T. Henry de Frahan'

#=========================================================================
#
# Imports
#
#=========================================================================
import argparse
import sys
import os
import numpy as np
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.axis as axis
import pandas as pd


#=========================================================================
#
# Parse arguments
#
#=========================================================================
parser = argparse.ArgumentParser(
    description='A simple plot tool for the Taylor-Green vortex')
parser.add_argument('-s', '--show', help='Show the plots', action='store_true')
args = parser.parse_args()


#=========================================================================
#
# Some defaults variables
#
#=========================================================================
plt.rc('text', usetex=True)
plt.rc('font', family='serif', serif='Times')
cmap_med = ['#F15A60', '#7AC36A', '#5A9BD4', '#FAA75B',
            '#9E67AB', '#CE7058', '#D77FB4', '#737373']
cmap = ['#EE2E2F', '#008C48', '#185AA9', '#F47D23',
        '#662C91', '#A21D21', '#B43894', '#010202']
dashseq = [(None, None), [10, 5], [10, 4, 3, 4], [
    3, 3], [10, 4, 3, 4, 3, 4], [3, 3], [3, 3]]
markertype = ['s', 'd', 'o', 'p', 'h']

#=========================================================================
#
# Function definitions
#
#=========================================================================


#=========================================================================
#
# Problem setup
#
#=========================================================================

resolutions = [8, 16, 32, 64]

for k, res in enumerate(resolutions):
    fname = os.path.join(os.path.abspath(str(res)), 'mmslog')
    df = pd.read_csv(fname, delim_whitespace=True)
    cnt = 0

    #=========================================================================
    plt.figure(cnt, figsize=(14, 4))
    plt.subplot(131)
    p = plt.plot(df['time'], df['rho_mms_err'])
    plt.title('MMS error vs t')

    plt.subplot(132)
    p = plt.semilogy(df['time'], df['rho_residual'])
    plt.title('Iter. error vs t')

    plt.subplot(133)
    ax = plt.gca()
    ax.set_yscale('log')
    p = plt.scatter(df['rho_mms_err'], df['rho_residual'], c=df['time'])
    plt.title('Iter. error vs MMS error')
    plt.savefig('rho_diag.pdf', format='pdf')
    plt.savefig('rho_diag.png', format='png')
    cnt += 1

    #=========================================================================
    plt.figure(cnt, figsize=(14, 4))
    plt.subplot(131)
    p = plt.plot(df['time'], df['u_mms_err'])
    plt.title('MMS error vs t')

    plt.subplot(132)
    p = plt.semilogy(df['time'], df['rhou_residual'])
    plt.title('Iter. error vs t')

    plt.subplot(133)
    ax = plt.gca()
    ax.set_yscale('log')
    p = plt.scatter(df['u_mms_err'], df['rhou_residual'], c=df['time'])
    plt.title('Iter. error vs MMS error')
    plt.savefig('v_diag.pdf', format='pdf')
    plt.savefig('v_diag.png', format='png')
    cnt += 1

    #=========================================================================
    plt.figure(cnt, figsize=(14, 4))
    plt.subplot(131)
    p = plt.plot(df['time'], df['v_mms_err'])
    plt.title('MMS error vs t')

    plt.subplot(132)
    p = plt.semilogy(df['time'], df['rhov_residual'])
    plt.title('Iter. error vs t')

    plt.subplot(133)
    ax = plt.gca()
    ax.set_yscale('log')
    p = plt.scatter(df['v_mms_err'], df['rhov_residual'], c=df['time'])
    plt.title('Iter. error vs MMS error')
    plt.savefig('u_diag.pdf', format='pdf')
    plt.savefig('u_diag.png', format='png')
    cnt += 1

    #=========================================================================
    plt.figure(cnt, figsize=(14, 4))
    plt.subplot(131)
    p = plt.plot(df['time'], df['w_mms_err'])
    plt.title('MMS error vs t')

    plt.subplot(132)
    p = plt.semilogy(df['time'], df['rhow_residual'])
    plt.title('Iter. error vs t')

    plt.subplot(133)
    ax = plt.gca()
    ax.set_yscale('log')
    p = plt.scatter(df['w_mms_err'], df['rhow_residual'], c=df['time'])
    plt.title('Iter. error vs MMS error')
    plt.savefig('w_diag.pdf', format='pdf')
    plt.savefig('w_diag.png', format='png')
    cnt += 1

    #=========================================================================
    plt.figure(cnt, figsize=(14, 4))
    plt.subplot(131)
    p = plt.plot(df['time'], df['p_mms_err'])
    plt.title('MMS error vs t')

    plt.subplot(132)
    p = plt.semilogy(df['time'], df['rhoE_residual'])
    plt.title('Iter. error vs t')

    plt.subplot(133)
    ax = plt.gca()
    ax.set_yscale('log')
    p = plt.scatter(df['p_mms_err'], df['rhoE_residual'], c=df['time'])
    plt.title('Iter. error vs MMS error')
    plt.savefig('p_diag.pdf', format='pdf')
    plt.savefig('p_diag.png', format='png')
    cnt += 1


# plt.show()
