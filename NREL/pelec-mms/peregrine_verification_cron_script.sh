#!/bin/bash -l

set -e

cd /projects/ExaCT/Pele/PeleTests/PeleRegressionTesting/NREL/pelec-mms && qsub run_verification.sh
