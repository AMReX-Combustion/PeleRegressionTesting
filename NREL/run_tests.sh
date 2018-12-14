#!/bin/bash -l

#PBS -N pelec_tests
#PBS -l nodes=1:ppn=24,walltime=4:00:00,feature=haswell
#PBS -A exact
#PBS -q short
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

printf "$(date)\n"
printf "======================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "======================================================\n"
if [ ! -z "${PBS_JOBID}" ]; then
  printf "PBS: Qsub is running on ${PBS_O_HOST}\n"
  printf "PBS: Originating queue is ${PBS_O_QUEUE}\n"
  printf "PBS: Executing queue is ${PBS_QUEUE}\n"
  printf "PBS: Working directory is ${PBS_O_WORKDIR}\n"
  printf "PBS: Execution mode is ${PBS_ENVIRONMENT}\n"
  printf "PBS: Job identifier is ${PBS_JOBID}\n"
  printf "PBS: Job name is ${PBS_JOBNAME}\n"
  printf "PBS: Node file is ${PBS_NODEFILE}\n"
  printf "PBS: Current home directory is ${PBS_O_HOME}\n"
  printf "PBS: PATH = ${PBS_O_PATH}\n"
  printf "======================================================\n"
  printf "\n"

  printf "======================================================\n"
  printf "Outputting module list:\n"
  printf "======================================================\n"
  cmd "module list"
  printf "======================================================\n"
fi
printf "\n"

# Assuming only Peregrine at the moment
if [ ! -z "${PBS_JOBID}" ]; then
  MACHINE_NAME=peregrine
fi

if [ ${MACHINE_NAME} == 'peregrine' ]; then
  cmd "module unuse /nopt/nrel/apps/modules/centos7/modulefiles"
  cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules"
  cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules"
  cmd "module use /nopt/nrel/ecom/hpacf/software/modules/gcc-7.3.0"
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

printf "\n"
printf "======================================================\n"
printf "Running tests:\n"
printf "======================================================\n"
set +e
cmd "python -u ${AMREX_TESTING}/regtest.py PeleC-tests-${MACHINE_NAME}.ini 2>&1"
set -e
printf "\nDone running tests.\n"
printf "======================================================\n"

# The following rsyncs the web directory to the test results git repo,
# then it removes files older than 7 days, then it creates
# an orphan branch, commits all the files, and then erases
# the master branch and renames the current branch to master,
# then cleans up all git history so we only ever have a single
# commit worth of history to keep the git repo from expanding
# to a large size. A 7 day moving window of files with no
# git history essentially. This breaks links for old builds.
printf "\n"
printf "======================================================\n"
printf "Pushing test results to github repo:\n"
printf "======================================================\n"
cmd "cd ${TESTING_DIR}/PeleCRegressionTestResults/"
cmd "git --version"
printf "\n\nDoing rsync to test results repo...\n"
cmd "rsync -avhW0R --exclude 'ChangeLog.*' --exclude '*.dat' --files-from=<(find ../web/./ -type f -mtime -7 -print0) ${TESTING_DIR}/ ${TESTING_DIR}/PeleCRegressionTestResults/"
printf "\n\nGoing to delete these files in test results repo:\n"
cmd "find . -mtime +7 -not -path '*/\.*'"
printf "\n\nDeleting the files...\n"
cmd "find . -mtime +7 -not -path '*/\.*' -delete"
printf "\n\nPerforming git history cleaning...\n"
cmd "git checkout --orphan newBranch"
cmd "git add -A"
cmd "git commit -m \"Adding test results for $(date)\""
cmd "git branch -D master"
cmd "git branch -m master"
cmd "git gc --aggressive --prune=all"
cmd "git push -f origin master"

chmod -R a+rX,go-w ${TESTING_DIR}
#chgrp -R exacthpc ${TESTING_DIR}

printf "\n\nDone posting test results.\n"
printf "$(date)\n"
