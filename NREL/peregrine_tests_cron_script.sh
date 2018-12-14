#!/bin/bash -l

set -e

cd /projects/ExaCT/Pele/PeleTests/PeleRegressionTesting/NREL && qsub run_tests.sh
