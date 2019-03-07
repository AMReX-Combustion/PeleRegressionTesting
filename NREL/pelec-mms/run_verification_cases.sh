#!/bin/bash

run_verification_cases () {
  (set -x; ls -alh ${PELE_MMS_EXE_3D})
  (set -x; ls -alh ${PELE_MMS_EXE_2D})
  (set -x; ls -alh ${PELE_MMS_EXE_1D})
  (set -x; ls -alh ${PELE_MMS_MOL_EXE_3D})

  # Symmetry
  CNS_DIR=${MMS_DIR}/symmetry_3d
  (set -x; cd ${CNS_DIR} && rm -rf chk* plt* datlog mmslog && \
  mpirun -report-bindings -n 4 ${PELE_MMS_EXE_3D} inputs_3d > mms.out 2>&1) &

  # CNS without AMR 1D
  CNS_DIR=${MMS_DIR}/cns_noamr_1d
  (set -x; rm ${CNS_DIR}/*.png || true)
  N=(8 16 32 64 128)
  NP=(1 1 1 2 4)
  for (( i=0; i<5; i++ ));
  do
    (set -x; cd ${CNS_DIR}/${N[${i}]} && rm -rf chk* plt* datlog mmslog && \
    mpirun -report-bindings -n ${NP[${i}]} ${PELE_MMS_EXE_1D} inputs_1d > mms.out 2>&1) &
  done
  wait

  # CNS without AMR 2D
  CNS_DIR=${MMS_DIR}/cns_noamr_2d
  (set -x; rm ${CNS_DIR}/*.png || true)
  N=(8 16 32 64)
  NP=(1 4 8 8)
  for (( i=0; i<4; i++ ));
  do
    (set -x; cd ${CNS_DIR}/${N[${i}]} && rm -rf chk* plt* datlog mmslog && \
    mpirun -report-bindings -n ${NP[${i}]} /bin/bash -c "ulimit -s 10240 && ${PELE_MMS_EXE_2D} inputs_2d" > mms.out 2>&1) &
  done
  wait

  # CNS without AMR 3D
  CNS_DIR=${MMS_DIR}/cns_noamr_3d
  (set -x; rm ${CNS_DIR}/*.png || true)
  N=(8 16 32 64)
  NP=(1 8 24 96)
  for (( i=0; i<4; i++ ));
  do
    (set -x; cd ${CNS_DIR}/${N[${i}]} && rm -rf chk* plt* datlog mmslog && \
    mpirun -report-bindings -n ${NP[${i}]} /bin/bash -c "ulimit -s 10240 && ${PELE_MMS_EXE_3D} inputs_3d" > mms.out 2>&1) &
  done
  wait

  # CNS without AMR 3D with MOL source term
  CNS_DIR=${MMS_DIR}/cns_noamr_mol_3d
  (set -x; rm ${CNS_DIR}/*.png || true)
  N=(8 16 32 64)
  NP=(1 8 24 96)
  for (( i=0; i<4; i++ ));
  do
    (set -x; cd ${CNS_DIR}/${N[${i}]} && rm -rf chk* plt* datlog mmslog && \
    mpirun -report-bindings -n ${NP[${i}]} /bin/bash -c "ulimit -s 10240 && ${PELE_MMS_MOL_EXE_3D} inputs_3d" > mms.out 2>&1) &
  done
  wait

  # CNS without AMR 2D with MOL source term
  CNS_DIR=${MMS_DIR}/cns_noamr_mol_2d
  (set -x; rm ${CNS_DIR}/*.png || true)
  N=(8 16 32 64)
  NP=(1 4 8 8)
  for (( i=0; i<4; i++ ));
  do
    (set -x; cd ${CNS_DIR}/${N[${i}]} && rm -rf chk* plt* datlog mmslog && \
    mpirun -report-bindings -n ${NP[${i}]} /bin/bash -c "ulimit -s 10240 && ${PELE_MMS_MOL_EXE_2D} inputs_2d" > mms.out 2>&1) &
  done
  wait

  # CNS with AMR 3D
  CNS_DIR=${MMS_DIR}/cns_amr_3d
  (set -x; rm ${CNS_DIR}/*.png || true)
  N=(8 16 32)
  NP=(1 16 96)
  for (( i=0; i<3; i++ ));
  do
    (set -x; cd ${CNS_DIR}/${N[${i}]} && rm -rf chk* plt* datlog mmslog && \
    mpirun -report-bindings -n ${NP[${i}]} /bin/bash -c "ulimit -s 10240 && ${PELE_MMS_EXE_3D} inputs_3d" > mms.out 2>&1) &
  done
  # This one takes 4 nodes about 24 hours
  #(set -x; cd ${CNS_DIR}/64 && rm -rf chk* plt* datlog mmslog && \
  #mpirun -report-bindings -n 96 /bin/bash -c "ulimit -s 10240 && ${PELE_MMS_EXE_3D} inputs_3d" > mms.out 2>&1)
  wait
}
