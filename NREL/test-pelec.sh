#!/bin/bash -l

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

set -e

printf "$(date)\n"
printf "======================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "======================================================\n"
printf "\n"

cmd "module unuse ${MODULEPATH}"
cmd "module use /opt/compilers/modules"
cmd "module use /opt/utilities/modules"
cmd "module use /opt/software/modules/gcc-7.3.0"
cmd "module purge"
cmd "module load gcc/7.3.0"
cmd "module load openmpi"
cmd "module load python/3.6.5"
cmd "module load git"
cmd "module load rsync"
cmd "module load masa"
TESTING_DIR=/projects/ecp/combustion/pelec-testing

cmd "export AMREX_HOME=${TESTING_DIR}/amrex"
cmd "export AMREX_TESTING=${TESTING_DIR}/amrex_testing"
cmd "export PELEC_HOME=${TESTING_DIR}/PeleC"
cmd "export PELE_PHYSICS_HOME=${TESTING_DIR}/PelePhysics"
cmd "export MASA_HOME=${MASA_ROOT_DIR}"

printf "======================================================\n"
printf "Outputting module list:\n"
printf "======================================================\n"
cmd "module list"
printf "======================================================\n"
printf "\n"
printf "======================================================\n"
printf "Running tests:\n"
printf "======================================================\n"
set +e
cmd "python -u ${AMREX_TESTING}/regtest.py pelec-tests.ini 2>&1"
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
chgrp -R exact ${TESTING_DIR}

printf "\n\nDone posting test results.\n"
printf "$(date)\n"

