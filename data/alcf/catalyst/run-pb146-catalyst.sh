#!/bin/bash -l
#PBS -A SENSEI
#PBS -q debug-scaling
#PBS -l walltime=00:30:00
#PBS -k doe
 
NNODES=`wc -l < $PBS_NODEFILE`
NRANKS=4
NDEPTH=8
NTOTRANKS=$(( NNODES * NRANKS ))
 
#cd $PBS_O_WORKDIR
module restore 
module swap PrgEnv-nvhpc PrgEnv-gnu
module load cudatoolkit-standalone
module load cmake
module unload cray-libsci
module list
nvidia-smi
export CRAY_ACCEL_TARGET=nvidia80
export MPICH_GPU_SUPPORT_ENABLED=1
 
export FI_OFI_RXM_RX_SIZE=8192

. /lus/grand/projects/visualization/mvictoras/spack/polaris/share/spack/setup-env.sh
spack env activate deleteme2
module use $GRAND/spack/polaris/share/spack/modules/cray-sles15-zen3
module load libtheora-1.1.1-gcc-11.2.0-ti2fyke
#spack load libtheora
#spack env activate nekrs-sensei2
#spack load paraview@5.9.1

ulimit -s unlimited 
export NEKRS_HOME=$GRAND/install/polaris/nekrs-polaris
export NEKRS_GPU_MPI=1 
export ROMIO_HINTS=$NEKRS_HOME/examples/pb146/.romio_hint
export LD_LIBRARY_PATH=/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen3/gcc-11.2.0/libtheora-1.1.1-ti2fykehk5bzeq6zkjjindjyrgc54k6b/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen3/gcc-11.2.0/mesa-22.1.2-ivqpmbkywtr2v2kqndzsy232rbxevyqz/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen3/gcc-11.2.0/netcdf-c-4.8.1-mumtwbnl63zqczqmdmn7zjofscymjnwm/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen3/gcc-11.2.0/python-3.9.13-xn5ccoy5cjt6eul342ffy6tk33i2c7oy/lib:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH=/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/pugixml-1.11.4-qpvlpudoqmryp75cdr3gtvxia4jba7xz/lib64:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/libjpeg-turbo-2.1.3-cld4zbepheuc6xvbxwxd3tknstdtjr5j/lib64:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/hdf5-1.12.2-xnzockili3cujm5stn4bsjbhamqqdtql/lib:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/netcdf-c-4.8.1-usmtdtasguy254tsskrq3qfn5szdnnuh/lib:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/glew-2.2.0-orqx3akpjppdfksmvccphrxdyzvxozlx/lib64:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/jsoncpp-1.9.4-73iuuglt4eectg2zco3qd6ynur42x7g2/lib64:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/libtheora-1.1.1-2g6nslk266wqcs5d7l73hnqgrrrrfm6l/lib:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/protobuf-21.1-luaunvl7dcjxosxe3nuvjtjz65orlwwm/lib64:/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/paraview-5.9.1-u3yks44oo5ckqjlcyupsdrrrxf25whg4/lib64:/soft/compilers/cudatoolkit/cuda-11.6.2/lib64:/opt/cray/pe/gcc/11.2.0/snos/lib64:/opt/cray/pe/papi/6.0.0.14/lib64:/opt/cray/libfabric/1.11.0.4.125/lib64:/lus/theta-fs0/projects/visualization/vray/lib:/dbhome/db2cat/sqllib/lib64:/dbhome/db2cat/sqllib/lib64/gskit:/dbhome/db2cat/sqllib/lib32:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH=/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/mesa-22.1.2-f7lvn3brulaicxx5zydz32qmckigotiq/lib:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH=/lus/grand/projects/visualization/mvictoras/spack/polaris/opt/spack/cray-sles15-zen2/gcc-11.2.0/python-3.9.13-jfbz5sblim6mys7666pj6vsr2xeaxitw/lib:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH=$NEKRS_HOME/lib:$LD_LIBRARY_PATH
date
export PROFILER_ENABLE=3 PROFILER_LOG_FILE=WriterTimes-pb146-${NTOTRANKS}.csv MEMPROF_LOG_FILE=WriterMemProf-pb146-${NTOTRANKS}.csv
#export PATH=/lus/grand/projects/visualization/mvictoras/src/polaris/valgrind-3.19.0/coregrind:$PATH
#module load valgrind4hpc
#valgrind4hpc -n1 /home/mvictoras/.local/nekrs-polaris/bin/nekrs -- --backend CUDA --setup pb
#mpiexec -np 1 --cpu-bind depth $NEKRS_HOME/bin/nekrs --backend CUDA --setup pb
#mpiexec -np 1 --cpu-bind depth valgrind --leak-check=yes --show-reachable=yes --num-callers=100 --trace-children=yes $NEKRS_HOME/bin/nekrs --backend CUDA --setup pb
cd /lus/grand/projects/visualization/mvictoras/install/polaris/nekrs-polaris/examples/pb146

mpiexec -np $NTOTRANKS -ppn $NRANKS -d $NDEPTH --cpu-bind depth $NEKRS_HOME/bin/nekrs --backend CUDA --setup pb
#mpiexec -np $NTOTRANKS /lus/grand/projects/visualization/mvictoras/src/polaris/SENSEI/install/bin/oscillator -t 1 -b $NTOTRANKS -g 1 -f oscillator_catalyst2.xml.in /lus/grand/projects/visualization/mvictoras/src/polaris/SENSEI/miniapps/oscillators/testing/simple.osc
