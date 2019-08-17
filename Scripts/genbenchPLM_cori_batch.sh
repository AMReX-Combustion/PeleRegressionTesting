#!/bin/bash
#SBATCH -N 1
#SBATCH -C haswell
#SBATCH -q debug
#SBATCH -t 00:30:00
#SBATCH -A m3406

#OpenMP settings:
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=spread


#run the application:
. ${HOME}/bin/setCIvariables.sh
module swap PrgEnv-{intel,gnu}
./Scripts/genbenchPLM_cori.sh

