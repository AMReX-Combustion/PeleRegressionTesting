#!/bin/bash -l

#PBS -N pelec_verification
#PBS -l nodes=4:ppn=24,walltime=12:00:00,feature=haswell
#PBS -A exact
#PBS -q batch-h
#PBS -j oe
#PBS -W umask=002

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
  cmd "cat ${PBS_NODEFILE}"
  printf "======================================================\n"
  printf "\n"
fi

TESTING_DIR=/projects/ecp/combustion/pelec-testing

cmd "module unuse ${MODULEPATH}"
cmd "module use /opt/compilers/modules"
cmd "module use /opt/utilities/modules"
cmd "module use /opt/software/modules/gcc-7.3.0"
cmd "module purge"
cmd "module load gcc/7.3.0"
cmd "module load openmpi"
cmd "module load git"
cmd "module load rsync"
cmd "module load masa"
cmd "module load python/3.6.5"
cmd "module load py-matplotlib/2.2.3-py3"
cmd "module load py-six/1.11.0-py3"
cmd "module load py-numpy/1.14.3-py3"
cmd "module load py-pyparsing/2.2.0-py3"
cmd "module load py-cycler/0.10.0-py3"
cmd "module load py-dateutil/2.5.2-py3"
cmd "module load py-bottleneck/1.2.1-py3"
cmd "module load py-cython/0.29-py3"
cmd "module load py-nose/1.3.7-py3"
cmd "module load py-numexpr/2.6.5-py3"
cmd "module load py-packaging/17.1-py3"
cmd "module load py-pandas/0.23.4-py3"
cmd "module load py-pillow/5.1.0-py3"
cmd "module load py-pytz/2017.2-py3"
cmd "module load py-setuptools/40.4.3-py3"
cmd "module load py-kiwisolver/1.0.1-py3"

printf "======================================================\n"
printf "Outputting module list:\n"
printf "======================================================\n"
cmd "module list"
printf "======================================================\n"

cmd "export AMREX_HOME=${TESTING_DIR}/amrex"
cmd "export PELEC_HOME=${TESTING_DIR}/PeleC"
cmd "export PELE_PHYSICS_HOME=${TESTING_DIR}/PelePhysics"
cmd "export MASA_HOME=${MASA_ROOT_DIR}"

printf "\n"
printf "======================================================\n"
printf "Running verification:\n"
printf "======================================================\n"
# Document latest hashes
#cmd "${TESTING_DIR}/PeleRegressionTesting/NREL/pelec-mms/hashes.txt || true"
{
printf "PeleC: $(cd ${TESTING_DIR}/PeleC && git log --pretty=format:'%H' -n 1)\n"
printf "PelePhysics: $(cd ${TESTING_DIR}/PelePhysics && git log --pretty=format:'%H' -n 1)\n"
printf "AMReX: $(cd ${TESTING_DIR}/amrex && git log --pretty=format:'%H' -n 1)\n"
} > ${TESTING_DIR}/PeleRegressionTesting/NREL/pelec-mms/hashes.txt

# Find latest Pele MMS executables
PELE_MMS_EXE_3D="${TESTING_DIR}/PeleC-tests/$(ls -t ${TESTING_DIR}/PeleC-tests | head -1)/MMS1/PeleC3d.gnu.TEST.MPI.ex"
PELE_MMS_EXE_2D="${TESTING_DIR}/PeleC-tests/$(ls -t ${TESTING_DIR}/PeleC-tests | head -1)/MMS4/PeleC2d.gnu.TEST.MPI.ex"
PELE_MMS_EXE_1D="${TESTING_DIR}/PeleC-tests/$(ls -t ${TESTING_DIR}/PeleC-tests | head -1)/MMS5/PeleC1d.gnu.TEST.MPI.ex"
PELE_MMS_MOL_EXE_3D="${TESTING_DIR}/PeleC-tests/$(ls -t ${TESTING_DIR}/PeleC-tests | head -1)/MMS6/PeleC3d.gnu.TEST.MPI.ex"
PELE_MMS_MOL_EXE_2D="${TESTING_DIR}/PeleC-tests/$(ls -t ${TESTING_DIR}/PeleC-tests | head -1)/MMS7/PeleC2d.gnu.TEST.MPI.ex"

MMS_DIR=${TESTING_DIR}/PeleRegressionTesting/NREL/pelec-mms
# Need MMS_DIR and PELE_MMS_EXE_<N>D variables set before calling function
source ${TESTING_DIR}/PeleRegressionTesting/NREL/pelec-mms/run_verification_cases.sh
run_verification_cases

# Run the test suite and always exit with success
set +e;
(set -x; img=build-status.svg;
 cd ${MMS_DIR}; rm ${img}; nosetests;
 if [ $? -eq 0 ]
 then
     cp build-pass.svg ${img};
 else
     cp build-fail.svg ${img};
 fi)
set -e;

printf "======================================================\n"
printf "Done running verification.\n"
printf "======================================================\n"

# The following rsyncs the web directory to the test results git repo,
# then it creates an orphan branch, commits all the files, and then erases
# the master branch and renames the current branch to master,
# then cleans up all git history so we only ever have a single
# commit worth of history to keep the git repo from expanding
# to a large size.
printf "\n"
printf "======================================================\n"
printf "Pushing test results to github repo:\n"
printf "======================================================\n"
cmd "cd ${TESTING_DIR}/PeleVerificationResults-Peregrine/"
cmd "git --version"
printf "\n\nDoing rsync to verification results repo...\n"
(set -x; rsync -avhW0 \
      --include 'pelec_verification.o*' \
      --exclude '*8*' \
      --exclude '*16*' \
      --exclude '*32*' \
      --exclude '*64*' \
      --exclude '*128*' \
      --exclude '*.py*' \
      --exclude '*tests*' \
      --exclude '*.sh' \
      --exclude 'requirements*' \
      --exclude '*.pbs' \
      --exclude 'build-pass.svg' \
      --exclude 'build-fail.svg' \
      --exclude '.git' \
      --delete \
      ${TESTING_DIR}/PeleRegressionTesting/NREL/pelec-mms/ \
      ${TESTING_DIR}/PeleVerificationResults-Peregrine/)
printf "\n\nPerforming git history cleaning...\n"
cmd "git checkout --orphan newBranch"
cmd "git add -A"
cmd "git commit -m \"Adding verification results for $(date)\""
cmd "git branch -D master"
cmd "git branch -m master"
cmd "git gc --aggressive --prune=all"
cmd "git push -f origin master"

printf "\n\nDone posting test results.\n"
printf "$(date)\n"
