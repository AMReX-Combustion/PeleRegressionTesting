#!/bin/bash -l

set -e

cd /projects/ExaCT/Pele/PeleTests/PeleRegressionTesting && qsub run_tests.sh
