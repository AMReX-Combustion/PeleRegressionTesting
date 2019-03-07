#!/bin/bash -l

set -e

cd /projects/ecp/combustion/pelec-testing/PeleRegressionTesting/NREL && \
nice -n19 ionice -c3 ./test-pelec.sh &> "test-pelec-$(date +%Y-%m-%d).log"
