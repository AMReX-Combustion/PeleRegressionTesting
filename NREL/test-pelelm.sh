#!/bin/bash -l

# Script for running nightly regression tests for PeleLM on a particular set 
# of machines with a list of configurations for each machine using Spack
# to satisfy dependencies and submitting results to CDash

# Function for printing and executing commands
cmd() {
  echo "+ $@";
  eval "$@";
}

# Function for testing a single configuration
test_configuration() {
  COMPILER_ID="${COMPILER_NAME}@${COMPILER_VERSION}"
  printf "************************************************************\n"
  printf "Testing PeleLM with:\n"
  printf "${COMPILER_ID}\n"
  printf "OPENMP_ENABLED: ${OPENMP_ENABLED}\n"
  printf "LIST_OF_TPLS: ${LIST_OF_TPLS}\n"
  printf "at $(date)\n"
  printf "************************************************************\n"
  printf "\n"

  # Logic for building up some constraints for use on Spack commands
  MPI_ID=''
  BLAS_ID=''
  if [ "${COMPILER_NAME}" == 'gcc' ] || [ "${COMPILER_NAME}" == 'clang' ]; then
    MPI_ID="openmpi"
    if [ "${MACHINE_NAME}" == 'eagle' ]; then
      MPI_ID="mpt"
    fi
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    # For intel, we want to build against intel-mpi and intel-mkl
    MPI_ID="intel-mpi"
    BLAS_ID="intel-mkl"
  fi

  #CUDA version used for tests on Eagle
  CUDA_VERSION="10.2.89"

  cmd "cd ${PELELM_TESTING_ROOT_DIR}"

  printf "\nLoading modules...\n"
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /opt/compilers/modules-2020-07"
    cmd "module use /opt/utilities/modules-2020-07"
    cmd "module use /opt/software/modules-2020-07/gcc-8.4.0"
    cmd "module load unzip"
    cmd "module load patch"
    cmd "module load bzip2"
    cmd "module load git"
    cmd "module load flex"
    cmd "module load bison"
    cmd "module load wget"
    cmd "module load bc"
    cmd "module load cppcheck"
    cmd "module load binutils"
    cmd "module load cmake"
    cmd "module load rsync"
    cmd "module load python"
    cmd "module load py-matplotlib"
    cmd "module load py-six"
    cmd "module load py-numpy"
    cmd "module load py-cycler"
    cmd "module load py-python-dateutil"
    cmd "module load py-bottleneck"
    cmd "module load py-cython"
    cmd "module load py-nose"
    cmd "module load py-numexpr"
    cmd "module load py-packaging"
    cmd "module load py-pandas"
    cmd "module load py-pillow"
    cmd "module load py-pytz"
    cmd "module load py-setuptools"
    cmd "module load py-kiwisolver"
    cmd "module load py-pyparsing"

    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'clang' ]; then
      cmd "module load gcc"
      cmd "module load llvm/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "module load gcc"
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    cmd "module purge"
    cmd "module unuse ${MODULEPATH}"
    cmd "module use /nopt/nrel/ecom/hpacf/compilers/modules-2020-07"
    cmd "module use /nopt/nrel/ecom/hpacf/utilities/modules-2020-07"
    cmd "module use /nopt/nrel/ecom/hpacf/software/modules-2020-07/gcc-8.4.0"
    cmd "module load cuda/${CUDA_VERSION}"
    cmd "module load python"
    cmd "module load git"
    cmd "module load cppcheck"
    cmd "module load binutils"
    cmd "module load cmake"
    cmd "module load rsync"
    cmd "module load mpt"
    if [ "${COMPILER_NAME}" == 'gcc' ]; then
      cmd "module load ${COMPILER_NAME}/${COMPILER_VERSION}"
    elif [ "${COMPILER_NAME}" == 'intel' ]; then
      cmd "module load ${INTEL_COMPILER_MODULE}"
    fi
  fi

  # Set the TMPDIR to disk so it doesn't run out of space
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    printf "\nMaking and setting TMPDIR to disk...\n"
    cmd "mkdir -p /scratch/${USER}/.tmp"
    cmd "export TMPDIR=/scratch/${USER}/.tmp"
  fi

  # Uninstall packages we want to track; it's an error if they don't exist yet, but a soft error
  #printf "\nUninstalling MASA (this is fine to error when tests are first run or building MASA has previously failed)...\n"
  #cmd "spack uninstall -a -y masa %${COMPILER_ID} || true"

  # Update packages we want to track; it's an error if they don't exist yet, but a soft error
  #printf "\nUpdating MASA (this is fine to error when tests are first run)...\n"
  #cmd "spack cd masa %${COMPILER_ID} && pwd && git fetch --all && git reset --hard origin/master && git clean -df && git status -uno || true"

  cmd "cd ${PELELM_TESTING_ROOT_DIR}" # Change directories to avoid any stale file handles

  #TPL_VARIANTS=''
  TPLS=(${LIST_OF_TPLS//;/ })
  #for TPL in ${TPLS[*]}; do
  #  TPL_VARIANTS+="+${TPL}"
  #done

  if [ "${MACHINE_NAME}" != 'mac' ]; then
    cmd "module list"
  fi

  printf "\nInstalling PeleLM dependencies if necessary using ${COMPILER_ID}...\n"
  spack find ${MPI_ID} %${COMPILER_ID}
  if [ $? -ne 0 ]; then
    cmd "spack install ${MPI_ID} %${COMPILER_ID}"
  fi

  # Refresh available modules (this is only really necessary on the first run of this script
  # because cmake and openmpi will already have been built and module files registered in subsequent runs)
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

  printf "\nLoading Spack modules into environment for CMake and MPI to use during CTest...\n"
  cmd "spack load --first ${MPI_ID} %${COMPILER_ID}"

  printf "\nSetting variables to pass to CTest...\n"
  CMAKE_CONFIGURE_ARGS=''
  for TPL in ${TPLS[*]}; do
    if [ "${TPL}" == 'masa' ]; then
      spack find masa %${COMPILER_ID}
      if [ $? -ne 0 ]; then
        cmd "spack install masa %${COMPILER_ID}"
      fi
      MASA_DIR=$(spack location -i masa %${COMPILER_ID})
      CMAKE_CONFIGURE_ARGS="-DPELELM_ENABLE_MASA:BOOL=ON -DMASA_DIR:PATH=${MASA_DIR} ${CMAKE_CONFIGURE_ARGS}"
      printf "MASA_DIR=${MASA_DIR}\n"
    fi
    if [ "${TPL}" == 'sundials' ]; then
      CMAKE_CONFIGURE_ARGS="-DPELELM_ENABLE_SUNDIALS:BOOL=ON ${CMAKE_CONFIGURE_ARGS}"
    fi
  done

  # Default cmake build type
  CMAKE_BUILD_TYPE=RelWithDebInfo

  # Set the extra identifiers for CDash build description
  EXTRA_BUILD_NAME="-${COMPILER_NAME}-${COMPILER_VERSION}"

  # Set CUDA stuff for Eagle
  if [ "${MACHINE_NAME}" == 'eagle' ]; then
    EXTRA_BUILD_NAME="-nvcc-${CUDA_VERSION}${EXTRA_BUILD_NAME}"
    CMAKE_CONFIGURE_ARGS="-DPELELM_ENABLE_CUDA:BOOL=ON -DAMReX_CUDA_ARCH:STRING=7.0 -DGPUS_PER_NODE:STRING=2 -DGPUS_PER_SOCKET:STRING=1 ${CMAKE_CONFIGURE_ARGS}"
    CTEST_ARGS="-DUNSET_TMPDIR_VAR:BOOL=TRUE -DCTEST_DISABLE_OVERLAPPING_TESTS:BOOL=TRUE ${CTEST_ARGS}"
  fi

  if [ ! -z "${PELELM_DIR}" ]; then
    printf "\nCleaning PeleLM directory...\n"
    cmd "cd ${PELELM_DIR} && git clean -df && git submodule foreach --recursive git clean -df"
    cmd "cd ${PELELM_DIR} && git reset --hard origin/development && git submodule foreach --recursive git reset --hard"
    cmd "cd ${PELELM_DIR} && git submodule update --init --recursive"
    cmd "cd ${PELELM_DIR} && git status -uno"
    cmd "mkdir -p ${PELELM_DIR}/build || true"
    cmd "cd ${PELELM_DIR}/build && rm -rf ${PELELM_DIR}/build/*"
    cmd "ln -s ${HOME}/combustion/PeleLMGoldFiles ${PELELM_DIR}/Testing/PeleLMGoldFiles"
    if [ "${USE_LATEST_AMREX}" == 'true' ]; then
      CTEST_ARGS="-DUSE_LATEST_AMREX:BOOL=TRUE ${CTEST_ARGS}"
      EXTRA_BUILD_NAME="${EXTRA_BUILD_NAME}-amrex_dev"
    fi
  fi

  # Turn on address sanitizer for clang build on rhodes
  if [ "${COMPILER_NAME}" == 'clang' ]; then
    printf "\nSetting up address sanitizer in Clang...\n"
    export CXXFLAGS="-fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer"
    printf "export CXXFLAGS=${CXXFLAGS}\n"
    (set -x; printf "leak:libopen-pal\nleak:libmpi\nleak:libmasa\nleak:libc++\nleak:hwloc_bitmap_alloc" > ${PELELM_DIR}/build/asan.supp)
    cmd "export LSAN_OPTIONS=suppressions=${PELELM_DIR}/build/asan.supp"
    # Can't run ASAN with optimization
    CMAKE_BUILD_TYPE=Debug
    # Also run static analysis on this build
    cmd "cd ${PELELM_DIR}/build && ln -s ${CPPCHECK_ROOT_DIR}/cfg/std.cfg"
    CMAKE_CONFIGURE_ARGS="-DPELELM_ENABLE_CPPCHECK:BOOL=ON -DPELELM_ENABLE_CLANG_TIDY:BOOL=ON -DPELELM_ENABLE_FPE_TRAP_FOR_TESTS:BOOL=OFF ${CMAKE_CONFIGURE_ARGS}"
    CTEST_ARGS="-DRUN_CODE_ANALYSIS:BOOL=TRUE ${CTEST_ARGS}"
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    CMAKE_CONFIGURE_ARGS="-DPELELM_ENABLE_FPE_TRAP_FOR_TESTS:BOOL=OFF ${CMAKE_CONFIGURE_ARGS}"
  else
    CMAKE_CONFIGURE_ARGS="-DPELELM_ENABLE_FPE_TRAP_FOR_TESTS:BOOL=ON ${CMAKE_CONFIGURE_ARGS}"
  fi

  # Explicitly set compilers
  if [ "${COMPILER_NAME}" == 'gcc' ]; then
    CXX_COMPILER=g++
    C_COMPILER=gcc
    FORTRAN_COMPILER=gfortran
    MPI_CXX_COMPILER=mpicxx
    MPI_C_COMPILER=mpicc
    MPI_FORTRAN_COMPILER=mpifort
  elif [ "${COMPILER_NAME}" == 'clang' ]; then
    CXX_COMPILER=clang++
    C_COMPILER=clang
    FORTRAN_COMPILER=gfortran
    MPI_CXX_COMPILER=mpicxx
    MPI_C_COMPILER=mpicc
    MPI_FORTRAN_COMPILER=mpifort
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    CXX_COMPILER=icpc
    C_COMPILER=icc
    FORTRAN_COMPILER=ifort
    MPI_CXX_COMPILER=mpiicpc
    MPI_C_COMPILER=mpiicc
    MPI_FORTRAN_COMPILER=mpiifort
  fi

  # Give CMake a hint to find Python3
  PYTHON_EXE=$(which python3)

  printf "\nListing cmake and MPI that will be used in ctest...\n"
  cmd "which mpiexec"
  cmd "which cmake"

  # CMake configure arguments testing options
  CMAKE_CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=${CXX_COMPILER} -DCMAKE_C_COMPILER=${C_COMPILER} -DCMAKE_Fortran_COMPILER=${FORTRAN_COMPILER} -DMPI_CXX_COMPILER=${MPI_CXX_COMPILER} -DMPI_C_COMPILER=${MPI_C_COMPILER} -DMPI_Fortran_COMPILER=${MPI_FORTRAN_COMPILER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DPELELM_ENABLE_MPI:BOOL=ON -DPYTHON_EXECUTABLE=${PYTHON_EXE} -DPELELM_ENABLE_FCOMPARE_FOR_TESTS:BOOL=ON ${CMAKE_CONFIGURE_ARGS}"

  # Set essential arguments for ctest
  CTEST_ARGS="-DTESTING_ROOT_DIR=${PELELM_TESTING_ROOT_DIR} -DPELELM_DIR=${PELELM_DIR} -DTEST_LOG=${LOGS_DIR}/pelelm-test-log.txt -DHOST_NAME=${HOST_NAME} -DEXTRA_BUILD_NAME=${EXTRA_BUILD_NAME} ${CTEST_ARGS}"

  # Allow for oversubscription in OpenMPI
  if [ "${COMPILER_NAME}" != 'intel' ] && [ "${MACHINE_NAME}" != 'eagle' ]; then
    CMAKE_CONFIGURE_ARGS="-DMPIEXEC_PREFLAGS:STRING=--oversubscribe ${CMAKE_CONFIGURE_ARGS}"
  fi

  if [ "${MACHINE_NAME}" != 'mac' ]; then
    cmd "module list"
    printf "\n"
  fi

  cmd "cd ${PELELM_DIR}/build"

  printf "\nRunning CTest at $(date)...\n"
  cmd "ctest ${CTEST_ARGS} -DCMAKE_CONFIGURE_ARGS=\"${CMAKE_CONFIGURE_ARGS}\" -VV -S ${PELELM_DIR}/Testing/CTestNightlyScript.cmake"
  printf "Returned from CTest at $(date)\n"

  printf "\nGoing to delete these gold files older than 30 days:\n"
  cmd "cd ${GOLDS_DIR} && find . -mtime +30 -not -path '*/\.*'"
  printf "\nDeleting the files...\n"
  cmd "cd ${GOLDS_DIR} && find . -mtime +30 -not -path '*/\.*' -delete"
  printf "\n"

  # Here we create a CMake project on the fly to have it write its OS/compiler info to a file
  printf "Organizing gold files from multiple tests into a single directory...\n"
  if [ ! -z "${PELELM_DIR}" ]; then
    cmd "mkdir -p ${PELELM_DIR}/build/id/build"
  fi
  printf "\nWriting CMake ID project CMakeLists.txt...\n"
  ID_CMAKE_LISTS=${PELELM_DIR}/build/id/CMakeLists.txt
  cat >${ID_CMAKE_LISTS} <<'EOL'
cmake_minimum_required(VERSION 3.11)
project(ID CXX)
file(WRITE ${CMAKE_BINARY_DIR}/id.txt ${CMAKE_SYSTEM_NAME}/${CMAKE_CXX_COMPILER_ID}/${CMAKE_CXX_COMPILER_VERSION})
EOL
  printf "\nRunning CMake on ID project...\n"
  unset CMAKE_CXX
  if [ "${MACHINE_NAME}" == 'mac' ] && [ "${COMPILER_NAME}" == 'gcc' ]; then
    CMAKE_CXX="CXX=g++-9"
  elif [ "${COMPILER_NAME}" == 'intel' ]; then
    CMAKE_CXX="CXX=icpc"
  fi
  cmd "cd ${PELELM_DIR}/build/id/build && ${CMAKE_CXX} cmake .."
  ID_FILE=$(cat ${PELELM_DIR}/build/id/build/id.txt)

  printf "\nID_FILE contains: ${ID_FILE}\n"

  printf "\nCopying fcompare golds to organized directory...\n"
  cmd "mkdir -p ${PELELM_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}"
  (set -x; rsync -avm --include="*/" --include="plt00010**" --exclude="*" ${PELELM_DIR}/build/Exec/RegTests/ ${PELELM_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/)
  # This only works on Linux
  #(set -x; cd ${PELELM_DIR}/build/Testing/test_files && find . -type d -name *plt00010* -exec cp -R --parents {} ${PELELM_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/ \;)
  #printf "\nCopying fextrema golds to organized directory...\n"
  #(set -x; rsync -avm --include="*/" --include="*.ext.gold" --include="*.ext" --exclude="*" ${PELELM_DIR}/build/Testing/test_files/ ${PELELM_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/)
  # This only works on Linux
  #(set -x; cd ${PELELM_DIR}/build/Testing/test_files && find . -type f -name *.ext -exec cp -R --parents {} ${PELELM_TESTING_ROOT_DIR}/temp_golds/${ID_FILE}/ \;)

  printf "\n"
  printf "************************************************************\n"
  printf "Done testing PeleLM with:\n"
  printf "${COMPILER_ID}\n"
  printf "OPENMP_ENABLED: ${OPENMP_ENABLED}\n"
  printf "LIST_OF_TPLS: ${LIST_OF_TPLS}\n"
  printf "at $(date)\n"
  printf "************************************************************\n"
}

# Main function for assembling configurations to test
main() {
  printf "============================================================\n"
  printf "$(date)\n"
  printf "============================================================\n"
  printf "Job is running on ${HOSTNAME}\n"
  printf "============================================================\n"

  # Decide what machine we are on
  if [ "${NREL_CLUSTER}" == 'eagle' ]; then
    MACHINE_NAME=eagle
  elif [ $(hostname) == 'rhodes.hpc.nrel.gov' ]; then
    MACHINE_NAME=rhodes
  elif [ $(hostname) == 'jrood-31712s.nrel.gov' ]; then
    MACHINE_NAME=mac
    # Disable testing on this machine for now
    exit 0
  fi
    
  HOST_NAME="${MACHINE_NAME}.hpc.nrel.gov"
 
  # Set configurations to test for each machine
  declare -a CONFIGURATIONS
  #CONFIGURATION[n]='compiler_name:compiler_version:openmp_enabled:use_latest_amrex:list_of_tpls'
  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    CONFIGURATIONS[0]='intel:18.0.4:false:false:sundials'
    CONFIGURATIONS[1]='clang:10.0.0:false:false:sundials'
    CONFIGURATIONS[2]='gcc:8.4.0:false:true:sundials'
    CONFIGURATIONS[3]='gcc:8.4.0:false:false:sundials'
    PELELM_TESTING_ROOT_DIR=/projects/ecp/combustion/pelelm-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  elif [ "${MACHINE_NAME}" == 'eagle' ]; then
    CONFIGURATIONS[0]='gcc:8.4.0:false:true:sundials'
    CONFIGURATIONS[1]='gcc:8.4.0:false:false:sundials'
    PELELM_TESTING_ROOT_DIR=/scratch/jrood/pelelm-testing
    INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2018.4
  #elif [ "${MACHINE_NAME}" == 'mac' ]; then
  #  CONFIGURATIONS[0]='clang:12.0.0-apple:false:false:sundials'
  #  PELELM_TESTING_ROOT_DIR=${HOME}/pelelm-testing
  else
    printf "\nMachine name not recognized.\n"
    exit 1
  fi
 
  PELELM_DIR=${PELELM_TESTING_ROOT_DIR}/pelelm
  SPACK_CONFIGS_DIR=${PELELM_TESTING_ROOT_DIR}/spack-configs
  #PELE_REGRESSION_TESTING_DIR=${PELELM_TESTING_ROOT_DIR}/PeleRegressionTesting
  LOGS_DIR=${PELELM_TESTING_ROOT_DIR}/logs
  GOLDS_DIR=${PELELM_TESTING_ROOT_DIR}/golds
  cmd "export SPACK_ROOT=${PELELM_TESTING_ROOT_DIR}/spack"
 
  printf "============================================================\n"
  printf "HOST_NAME: ${HOST_NAME}\n"
  printf "PELELM_TESTING_ROOT_DIR: ${PELELM_TESTING_ROOT_DIR}\n"
  printf "PELELM_DIR: ${PELELM_DIR}\n"
  printf "SPACK_CONFIGS_DIR: ${SPACK_CONFIGS_DIR}\n"
  printf "LOGS_DIR: ${LOGS_DIR}\n"
  printf "GOLDS_DIR: ${GOLDS_DIR}\n"
  printf "SPACK_ROOT: ${SPACK_ROOT}\n"
  printf "Testing configurations:\n"
  printf " compiler_name:compiler_version:openmp_enabled:use_latest_amrex:list_of_tpls\n"
  for CONFIGURATION in "${CONFIGURATIONS[@]}"; do
    printf " ${CONFIGURATION}\n"
  done
  printf "============================================================\n"
 
  if [ ! -d "${PELELM_TESTING_ROOT_DIR}" ]; then
    set -e
    printf "============================================================\n"
    printf "Top level testing directory doesn't exist.\n"
    printf "Creating everything from scratch...\n"
    printf "============================================================\n"

    printf "Creating top level testing directory...\n"
    cmd "mkdir -p ${PELELM_TESTING_ROOT_DIR}"
 
    printf "\nCloning Spack repo...\n"
    cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"
 
    printf "\nConfiguring Spack...\n"
    cmd "git clone https://github.com/jrood-nrel/spack-configs.git ${SPACK_CONFIGS_DIR}"
    cmd "cd ${SPACK_CONFIGS_DIR}/scripts && ./setup-spack.sh"
 
    # Checkout PeleLM
    printf "\nCloning PeleLM repo...\n"
    cmd "git clone --recursive https://github.com/AMReX-Combustion/PeleLM.git ${PELELM_DIR}"
    cmd "mkdir -p ${PELELM_DIR}/build || true"

    # Checkout PeleRegressionTesting repo
    #printf "\nCloning PeleRegressionTesting repo...\n"
    #cmd "git clone -b development https://github.com/AMReX-Combustion/PeleRegressionTesting.git ${PELE_REGRESSION_TESTING_DIR}"
 
    printf "\nMaking job output directory...\n"
    cmd "mkdir -p ${LOGS_DIR}"

    printf "\nMaking golds archive directory...\n"
    cmd "mkdir -p ${GOLDS_DIR}"
 
    printf "============================================================\n"
    printf "Done setting up testing directory\n"
    printf "============================================================\n"
    set +e
  fi
 
  printf "\nLoading Spack...\n"
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

  printf "\nMaking common directory across all tests in which to organize and save gold files...\n"
  if [ ! -z "${PELELM_TESTING_ROOT_DIR}" ]; then
    cmd "mkdir -p ${PELELM_TESTING_ROOT_DIR}/temp_golds"
  fi

  printf "\n"
  printf "============================================================\n"
  printf "Starting testing loops...\n"
  printf "============================================================\n"
 
  # Test PeleLM for the list of configurations
  for CONFIGURATION in "${CONFIGURATIONS[@]}"; do
    CONFIG=(${CONFIGURATION//:/ })
    COMPILER_NAME=${CONFIG[0]}
    COMPILER_VERSION=${CONFIG[1]}
    OPENMP_ENABLED=${CONFIG[2]}
    USE_LATEST_AMREX=${CONFIG[3]}
    LIST_OF_TPLS=${CONFIG[4]}

    printf "\nRemoving previous test log for uploading to CDash...\n"
    cmd "rm ${LOGS_DIR}/pelelm-test-log.txt"
    printf "\n"
    (test_configuration) 2>&1 | tee -i ${LOGS_DIR}/pelelm-test-log.txt
  done

  printf "============================================================\n"
  printf "Done with testing loops\n"
  printf "============================================================\n"
  printf "============================================================\n"
  printf "Final steps\n"
  printf "============================================================\n"

  printf "\nSaving gold files...\n"
  (set -x; tar -czf ${GOLDS_DIR}/pelelm_golds-$(date +%Y-%m-%d-%H-%M).tar.gz -C ${PELELM_TESTING_ROOT_DIR}/temp_golds .)

  printf "\nRemoving temporary golds...\n"
  if [ ! -z "${PELELM_TESTING_ROOT_DIR}" ]; then
    cmd "rm -rf ${PELELM_TESTING_ROOT_DIR}/temp_golds"
  fi

  if [ "${MACHINE_NAME}" == 'eagle' ] || [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting permissions...\n"
    cmd "chmod -R a+rX,go-w ${PELELM_TESTING_ROOT_DIR}"
  fi

  if [ "${MACHINE_NAME}" == 'rhodes' ]; then
    printf "\nSetting group...\n"
    cmd "chgrp -R exact ${PELELM_TESTING_ROOT_DIR}"
  fi

  printf "============================================================\n"
  printf "Done!\n"
  printf "$(date)\n"
  printf "============================================================\n"
}

main "$@"
