#!/bin/bash

TESTPARAMS=Scripts/IAMR-tests.ini
PARAMSORIG=${IAMR_HOME}/Test/IAMR-tests.ini

echo "Generating ${TESTPARAMS} from ${PARAMSORIG}"

myPWD="${PWD//\//\\/}"
cmd="sed -e 's/PELEREGTESTHOME/${myPWD}/g' ${PARAMSORIG} > ${TESTPARAMS}"
eval $cmd

echo "Generating regression benchmarks"
${AMREX_REGTEST_HOME}/regtest.py --no_update All --make_benchmarks "$1" ${TESTPARAMS}
