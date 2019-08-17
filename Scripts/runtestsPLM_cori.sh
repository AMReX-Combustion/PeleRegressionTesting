#!/bin/bash

TESTPARAMS=Scripts/PeleLM-tests.ini
PARAMSORIG=${PELELM_HOME}/Testing/Regression/PeleLM-tests_cori.ini

echo "Generating ${TESTPARAMS} from ${PARAMSORIG}"

myPWD="${PWD//\//\\/}"
cmd="sed -e 's/PELEREGTESTHOME/${myPWD}/g' ${PARAMSORIG} > ${TESTPARAMS}"
eval $cmd

echo "Running regression tests"
${AMREX_REGTEST_HOME}/regtest.py --no_update All --tests "COVO2_MU0" ${TESTPARAMS}
