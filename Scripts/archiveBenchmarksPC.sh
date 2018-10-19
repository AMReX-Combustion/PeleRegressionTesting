#!/bin/bash

export DATE=`date | sed -e 's/ /_/g'`
export DIR=TestData/PeleC/PeleC-benchmarks
export PASSWD=${HOME}/.archive.passwd
export ARCHIVE_DIR=/home/m/marcd/Pele/RegressionTestBenchmarks/godzilla

export BENCHMARK_DIR=`dirname ${DIR}`
export BENCHMARKS=`basename ${DIR}`

cd ${BENCHMARK_DIR}; find ${BENCHMARKS} | cpio -o -Hcrc 2>/dev/null | ncftpput -d ncftpput.errlog -f ${PASSWD} -W 'ALLO6 250032619520' -c ${ARCHIVE_DIR}/${BENCHMARKS}.cpio-${DATE}

echo "Go to archive.nersc.gov and do \"ln -s ${ARCHIVE_DIR}/${BENCHMARKS}.cpio-${DATE} ${ARCHIVE_DIR}/${BENCHMARKS}.cpio-latest"


