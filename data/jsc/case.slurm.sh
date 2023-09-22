#!/bin/bash -x
#SBATCH --account=dems
#SBATCH --job-name="case_sensei_64.16"
#SBATCH --nodes=80
#SBATCH --partition=booster
#SBATCH --time=01:00:00
#SBATCH --output=%x_out.%j
#SBATCH --error=%x_err.%j
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=12
#SBATCH --gres=gpu:4
#SBATCH --gpu-bind=closest
#SBATCH --distribution=block:cyclic:fcyclic

# devide the nodes for simulation and endpoint
export SIMNODES_FACTOR=5 # << edit this to change the ratio of endpoint-nodes vs simulation-nodes
export TASKS_PER_NODE=$(echo "$SLURM_TASKS_PER_NODE" | sed -e  's/^\([0-9][0-9]*\).*$/\1/')
export EPOINT_NODES=$((${SLURM_JOB_NUM_NODES}/${SIMNODES_FACTOR}))
export EPOINT_NTASKS=${EPOINT_NODES}
export SIM_NODES=$(($SLURM_JOB_NUM_NODES-${EPOINT_NODES}))
export SIM_NTASKS=$(($SIM_NODES * ${TASKS_PER_NODE}))

ulimit -s unlimited

source /p/project/dems/goebbert1/load_modules.booster-2023
module list

# system information
nvidia-smi
ucx_info -f      &> UCX_info-$SLURM_JOB_ID
export IB_WITH_IP=$(ibv_devices | grep $(ip link show ib0 | grep -m1 link | cut -c57-79 | sed s/:/''/g) | awk '{print $1}')
ibv_devices      &>  IBV_info-$SLURM_JOB_ID
echo "ib device with IP: $IB_WITH_IP" &>> IBV_info-$SLURM_JOB_ID
ibv_devinfo      &>> IBV_info-$SLURM_JOB_ID

# IO settings
export ROMIO_HINTS="$(pwd)/.romio_hint"
if [ ! -f "$ROMIO_HINTS" ]; then
  echo "romio_no_indep_rw true"    >  $ROMIO_HINTS
  echo "cb_buffer_size 67108864"   >> $ROMIO_HINTS
  echo "romio_cb_alltoall disable" >> $ROMIO_HINTS
  echo "romio_cb_read enable"      >> $ROMIO_HINTS
  echo "romio_cb_write enable"     >> $ROMIO_HINTS
  echo "romio_ds_read disable"     >> $ROMIO_HINTS
  echo "romio_ds_write disable"    >> $ROMIO_HINTS
  echo "IBM_largeblock_io true"    >> $ROMIO_HINTS
  echo "cb_config_list *:1"        >> $ROMIO_HINTS
fi

# nekRS settings
# export NEKRS_HOME=<set by nekRS module>
export OCCA_CXX=g++
export OCCA_CXXFLAGS="-O2 -ftree-vectorize -funroll-loops -march=native -mtune=native"
export NEKRS_GPU_MPI=1
export NEKRS_CACHE_BCAST=0
if [ $NEKRS_CACHE_BCAST -eq 1 ]; then
  export NEKRS_LOCAL_TMP_DIR=$TMPDIR/nrs
  mkdir $NEKRS_LOCAL_TMP_DIR
fi

#################################
#################################
source /p/project/dems/goebbert1/load_modules.booster-2023
export NEKRS_CACHE_DIR=$(pwd)/../cache/cache-ntasks${SIM_NTASKS}

## precompilation (to $NEKRS_CACHE_DIR/) if required
srun -N1 --ntasks=1 --cpus-per-task=48 --cpu-bind=verbose,cores ${NEKRS_HOME}/bin/nekrs --backend CUDA --device-id 0 --setup case.par --build-only ${SIM_NTASKS}
sleep 10

#################################
# no transport
#################################
# source /p/project/dems/goebbert1/load_modules-nosensei.booster-2023
source /p/project/dems/goebbert1/load_modules.booster-2023

export RUNID=.nosensei
sed -i 's/^elapsedTime =.*/elapsedTime = 10.0/' case.par

# SENSEI settings
export PROFILER_ENABLE=3
export MEMPROF_INTERVAL=20
conn="$(pwd)/info$RUNID"
sed -e "s|<CWD>|$conn|" -e "s|<DTRANSP>|UCX|" -e "s|<MMETH>|BP|" -e "s|<ONOFF>|0|" ./sensei-transport.xml.tmpl > ./sensei-transport.xml$RUNID
ln -sf sensei-transport.xml$RUNID case.xml  # for nekrs

# run simulation WITHOUT sensei
echo "Starting nekRS simulation (without SENSEI)"    &>  "srun-$SLURM_JOB_ID.nekRS$RUNID"
date                                &>> "srun-$SLURM_JOB_ID.nekRS$RUNID"
readlink -f $(which nekrs)          &>> "srun-$SLURM_JOB_ID.nekRS$RUNID"
export PROFILER_LOG_FILE=WriterTimes-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-nekRS${RUNID}.csv
export MEMPROF_LOG_FILE=WriterMemProf-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-nekRS${RUNID}.csv
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun -N${SIM_NODES} --ntasks=${SIM_NTASKS} --cpus-per-task=${SLURM_CPUS_PER_TASK} --cpu-bind=verbose,cores ${NEKRS_HOME}/bin/nekrs --backend CUDA --device-id 0 --setup case.par &>> "srun-$SLURM_JOB_ID.nekRS$RUNID"
sleep 5

mv timings.csv timings.csv$RUNID
mv data.csv data.csv$RUNID
sleep 10

#################################
# Posthoc
#################################
source /p/project/dems/goebbert1/load_modules.booster-2023

export RUNID=.1
sed -i 's/^elapsedTime =.*/elapsedTime = 10.0/' case.par

# SENSEI settings
export PROFILER_ENABLE=3
export MEMPROF_INTERVAL=20
conn="$(pwd)/info$RUNID"
sed -e "s|<CWD>|$conn|" -e "s|<DTRANSP>|UCX|" -e "s|<MMETH>|BP|" -e "s|<ONOFF>|1|" ./sensei-transport.xml.tmpl > ./sensei-transport.xml$RUNID
ln -sf sensei-transport.xml$RUNID case.xml  # for nekrs
sed -e "s|<POSTHOCIO>|1|" -e "s|<CATALYST>|0|" ./sensei-endpoint.xml.tmpl > ./sensei-endpoint.xml$RUNID

# ADIOS settings (only UCX works!)
export SstCPVerbose=5
export SstVerbose=5

# run simulation
# (SENSEI will be initialized with case.xml->sensei-transport.xml)
echo "Starting nekRS simulation"    &>  "srun-$SLURM_JOB_ID.nekRS$RUNID"
date                                &>> "srun-$SLURM_JOB_ID.nekRS$RUNID"
readlink -f $(which nekrs)          &>> "srun-$SLURM_JOB_ID.nekRS$RUNID"
export PROFILER_LOG_FILE=WriterTimes-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-nekRS${RUNID}.csv
export MEMPROF_LOG_FILE=WriterMemProf-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-nekRS${RUNID}.csv
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun -N${SIM_NODES} --ntasks=${SIM_NTASKS} --cpus-per-task=${SLURM_CPUS_PER_TASK} --cpu-bind=verbose,cores ${NEKRS_HOME}/bin/nekrs --backend CUDA --device-id 0 --setup case.par &>> "srun-$SLURM_JOB_ID.nekRS$RUNID" &
sim_pid=$!

# (the endpoints waits for 3min for the file info.1.sst and exits then - even though we set the timeout to 1800s and not 180s)
# Loop until the connection file appears
timeout_duration="300"
start_time=$(date +%s)
while [ ! -f "${conn}.sst" ]; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ "$elapsed_time" -ge "$timeout_duration" ]; then
        break
    fi
    sleep 1
    echo "waiting for the connection file ${conn}.sst ..."
done
# srun -N${EPOINT_NODES} --ntasks=${EPOINT_NODES} cat ${conn}.sst

# run endpoint
mkdir -p ./post
echo "Starting SENSEI Endpoint"     &>  "srun-$SLURM_JOB_ID.endpoint$RUNID"
date                                &>> "srun-$SLURM_JOB_ID.endpoint$RUNID"
readlink -f $(which SENSEIEndPoint) &>> "srun-$SLURM_JOB_ID.endpoint$RUNID"
export PROFILER_LOG_FILE=WriterTimes-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-endpoint${RUNID}.csv
export MEMPROF_LOG_FILE=WriterMemProf-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-endpoint${RUNID}.csv
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun -N${EPOINT_NODES} --ntasks=${EPOINT_NTASKS} --cpus-per-task=48 --cpu-bind=verbose,cores SENSEIEndPoint -t ./sensei-transport.xml$RUNID -a ./sensei-endpoint.xml$RUNID &>> "srun-$SLURM_JOB_ID.endpoint$RUNID" &
endp_pid=$!

wait
mv timings.csv timings.csv$RUNID
mv data.csv data.csv$RUNID
mv datasets datasets$RUNID
mv post post$RUNID

#################################
# Catalyst
#################################
source /p/project/dems/goebbert1/load_modules.booster-2023

export RUNID=.2
sed -i 's/^elapsedTime =.*/elapsedTime = 10.0/' case.par

# SENSEI settings
export PROFILER_ENABLE=3
export MEMPROF_INTERVAL=20
conn="$(pwd)/info$RUNID"
sed -e "s|<CWD>|$conn|" -e "s|<DTRANSP>|UCX|" -e "s|<MMETH>|BP|" -e "s|<ONOFF>|1|" ./sensei-transport.xml.tmpl > ./sensei-transport.xml$RUNID
ln -sf sensei-transport.xml$RUNID case.xml  # for nekrs
sed -e "s|<POSTHOCIO>|0|" -e "s|<CATALYST>|1|" ./sensei-endpoint.xml.tmpl > ./sensei-endpoint.xml$RUNID

# ADIOS settings (only UCX works!)
export SstCPVerbose=5
export SstVerbose=5

# run simulation
# (SENSEI will be initialized with case.xml->sensei-transport.xml)
echo "Starting nekRS simulation"    &>  "srun-$SLURM_JOB_ID.nekRS$RUNID"
date                                &>> "srun-$SLURM_JOB_ID.nekRS$RUNID"
readlink -f $(which nekrs)          &>> "srun-$SLURM_JOB_ID.nekRS$RUNID"
export PROFILER_LOG_FILE=WriterTimes-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-nekRS${RUNID}.csv
export MEMPROF_LOG_FILE=WriterMemProf-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-nekRS${RUNID}.csv
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun -N${SIM_NODES} --ntasks=${SIM_NTASKS} --cpus-per-task=${SLURM_CPUS_PER_TASK} --cpu-bind=verbose,cores ${NEKRS_HOME}/bin/nekrs --backend CUDA --device-id 0 --setup case.par &>> "srun-$SLURM_JOB_ID.nekRS$RUNID" &
sim_pid=$!

# (the endpoints waits for 3min for the file info.1.sst and exits then - even though we set the timeout to 1800s and not 180s)
# Loop until the connection file appears
timeout_duration="300"
start_time=$(date +%s)
while [ ! -f "${conn}.sst" ]; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ "$elapsed_time" -ge "$timeout_duration" ]; then
        break
    fi
    sleep 1
    echo "waiting for the connection file ${conn}.sst ..."
done
# srun -N${EPOINT_NODES} --ntasks=${EPOINT_NODES} cat ${conn}.sst

# run endpoint
mkdir -p ./post
echo "Starting SENSEI Endpoint"     &>  "srun-$SLURM_JOB_ID.endpoint$RUNID"
date                                &>> "srun-$SLURM_JOB_ID.endpoint$RUNID"
readlink -f $(which SENSEIEndPoint) &>> "srun-$SLURM_JOB_ID.endpoint$RUNID"
export PROFILER_LOG_FILE=WriterTimes-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-endpoint${RUNID}.csv
export MEMPROF_LOG_FILE=WriterMemProf-meso-${SIM_NODES}.${SIM_NTASKS}+${EPOINT_NODES}.${EPOINT_NTASKS}-${SLURM_JOB_ID}-endpoint${RUNID}.csv
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun -N${EPOINT_NODES} --ntasks=${EPOINT_NTASKS} --cpus-per-task=48 --cpu-bind=verbose,cores SENSEIEndPoint -t ./sensei-transport.xml$RUNID -a ./sensei-endpoint.xml$RUNID &>> "srun-$SLURM_JOB_ID.endpoint$RUNID" &
endp_pid=$!

wait
mv timings.csv timings.csv$RUNID
mv data.csv data.csv$RUNID
mv datasets datasets$RUNID
mv post post$RUNID

##################################
