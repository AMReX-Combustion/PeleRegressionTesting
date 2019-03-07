#!/bin/bash -l

set -e

cd /projects/ecp/combustion/pelec-testing/PeleRegressionTesting/NREL/pelec-mms && \
nice -n19 ionice -c3 ./verify-pelec.sh &> "verify-pelec-$(date +%Y-%m-%d).log"
