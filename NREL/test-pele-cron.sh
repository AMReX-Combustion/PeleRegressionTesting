#!/bin/bash -l

#Script that runs the nightly Pele tests at NREL on Rhodes, Mac, or Eagle

#Since MacOS doesn't have crontab, use `sudo launchctl load -w /Library/LaunchDaemons/com.whatever.plist`
#to load the scheduled command and "unload" to remove it.

set -e

# Decide what machine we are on
if [ "${NREL_CLUSTER}" == 'eagle' ]; then
  MACHINE_NAME=eagle
elif [ $(hostname) == 'jrood-31712s.nrel.gov' ]; then
  MACHINE_NAME=mac
elif [ $(hostname) == 'rhodes.hpc.nrel.gov' ]; then
  MACHINE_NAME=rhodes
fi
  
# Set root testing directory
if [ "${MACHINE_NAME}" == 'eagle' ]; then
  PELEC_TESTING_ROOT_DIR=/scratch/jrood/pelec-testing
  PELELM_TESTING_ROOT_DIR=/scratch/jrood/pelelm-testing
elif [ "${MACHINE_NAME}" == 'mac' ]; then
  PELEC_TESTING_ROOT_DIR=${HOME}/pelec-testing
  PELELM_TESTING_ROOT_DIR=${HOME}/pelelm-testing
elif [ "${MACHINE_NAME}" == 'rhodes' ]; then
  PELEC_TESTING_ROOT_DIR=/projects/ecp/combustion/pelec-testing
  PELELM_TESTING_ROOT_DIR=/projects/ecp/combustion/pelelm-testing
fi

PELEC_LOG_DIR=${PELEC_TESTING_ROOT_DIR}/logs
PELELM_LOG_DIR=${PELELM_TESTING_ROOT_DIR}/logs
PELEC_TEST_SCRIPT=${PELEC_TESTING_ROOT_DIR}/PeleRegressionTesting/NREL/test-pelec.sh
PELELM_TEST_SCRIPT=${PELEC_TESTING_ROOT_DIR}/PeleRegressionTesting/NREL/test-pelelm.sh

# Run test script 
if [ "${MACHINE_NAME}" == 'eagle' ]; then
  cd ${PELEC_LOG_DIR} && sbatch -J test-pelec -N 1 -t 1:00:00 -A exact -p debug -o "%x.o%j" --gres=gpu:2 ${PELEC_TEST_SCRIPT}
  cd ${PELELM_LOG_DIR} && sbatch -J test-pelelm -N 1 -t 1:00:00 -A exact -p debug -o "%x.o%j" --gres=gpu:2 ${PELELM_TEST_SCRIPT}
elif [ "${MACHINE_NAME}" == 'mac' ]; then
  cd ${PELEC_LOG_DIR} && nice ${PELEC_TEST_SCRIPT} &> "test-pelec-$(date +%Y-%m-%d).log"
  cd ${PELELM_LOG_DIR} && nice ${PELELM_TEST_SCRIPT} &> "test-pelelm-$(date +%Y-%m-%d).log"
elif [ "${MACHINE_NAME}" == 'rhodes' ]; then
  cd ${PELEC_LOG_DIR} && nice -n19 ionice -c3 ${PELEC_TEST_SCRIPT} &> "test-pelec-$(date +%Y-%m-%d).log"
  cd ${PELELM_LOG_DIR} && nice -n19 ionice -c3 ${PELELM_TEST_SCRIPT} &> "test-pelelm-$(date +%Y-%m-%d).log"
fi
