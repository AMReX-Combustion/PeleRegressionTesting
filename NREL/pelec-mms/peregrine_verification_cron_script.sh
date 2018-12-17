#!/bin/bash -l

set -e

cd /projects/ExaCT/Pele/PeleTests/PeleRegressionTesting/pelec-mms && qsub run_verification.sh
