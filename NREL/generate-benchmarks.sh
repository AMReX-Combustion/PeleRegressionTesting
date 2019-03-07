#!/bin/bash -l

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

TESTING_DIR=/projects/ecp/combustion/pelec-testing

cmd "module unuse ${MODULEPATH}"
cmd "module use /opt/compilers/modules"
cmd "module use /opt/utilities/modules"
cmd "module use /opt/software/modules/gcc-7.3.0"
cmd "module purge"
cmd "module load gcc/7.3.0"
cmd "module load openmpi"
cmd "module load python/3.6.5"
cmd "module load git"
cmd "module load masa"

cmd "export AMREX_HOME=${TESTING_DIR}/amrex"
cmd "export AMREX_TESTING=${TESTING_DIR}/amrex_testing"
cmd "export PELEC_HOME=${TESTING_DIR}/PeleC"
cmd "export PELE_PHYSICS_HOME=${TESTING_DIR}/PelePhysics"
cmd "export MASA_HOME=${MASA_ROOT_DIR}"

cmd "python -u ${AMREX_TESTING}/regtest.py --make_benchmarks 'Benchmarks 20190307' pelec-tests.ini 2>&1"

