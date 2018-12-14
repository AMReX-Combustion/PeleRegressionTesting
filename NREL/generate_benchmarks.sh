#!/bin/bash -l

#PBS -N pelec_benchmarks
#PBS -l nodes=1:ppn=24,walltime=2:00:00,feature=haswell
#PBS -A exact
#PBS -q short
#PBS -o pelec_benchmarks.log
#PBS -j oe
#PBS -W umask=002

# Control over printing and executing commands
print_cmds=true
execute_cmds=true

# Function for printing and executing commands
cmd() {
  if ${print_cmds}; then echo "+ $@"; fi
  if ${execute_cmds}; then eval "$@"; fi
}

set -e

# Assuming only Peregrine at the moment
if [ ! -z "${PBS_JOBID}" ]; then
  MACHINE_NAME=peregrine
  PROPER_MACHINE_NAME=Peregrine
fi

if [ ${MACHINE_NAME} == 'peregrine' ]; then
  cmd "module purge"
  cmd "module load gcc/7.3.0"
  cmd "module load openmpi/3.1.3"
  cmd "module load python/2.7.15"
  cmd "module load git"
  cmd "module load masa"
  TESTING_DIR=/projects/ExaCT/Pele/PeleTests
else
  printf "\nMachine name not recognized.\n\n"
fi

cmd "export AMREX_HOME=${TESTING_DIR}/AMReX"
cmd "export AMREX_TESTING=${TESTING_DIR}/AMReX_testing"
cmd "export PELEC_HOME=${TESTING_DIR}/PeleC"
cmd "export PELE_PHYSICS_HOME=${TESTING_DIR}/PelePhysics"
cmd "export MASA_HOME=${MASA_ROOT_DIR}"

cmd "python -u ${AMREX_TESTING}/regtest.py --make_benchmarks 'Benchmarks 20181204' PeleC-tests-${MACHINE_NAME}.ini 2>&1"

