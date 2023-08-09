#!/bin/bash
#
#SBATCH --job-name="AUX_gzip"
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --ntasks-per-node=128
#SBATCH --threads-per-core=1
#SBATCH --time=01:00:00
#SBATCH --partition=dc-cpu
#SBATCH --account=jjsc39
#
# USAGE: 
# >> sbatch ./$0 TARGET/FILES/WILDCARDS/ARE/POSSIBL*
# >> sbatch ./aux_gzip_general.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run_TSMP/laf_lbfd/201[8,9]

# Some hardcoding due to COSMO subdirectories needed in conjunction with 
# the passing of positional parameters to the script

parallelGzip() (
  # Simple run gzip on inFile
  tmpInFile=$1
  gzip ${tmpInFile} 
)

MAX_PARALLEL=${SLURM_NTASKS}
echo "MAX_PARALLEL: $MAX_PARALLEL"
##inFiles=$@
##echo "${inFiles[@]}"
tmp_parallel_counter=0
##for inFile in $inFiles
for inFile in $(find /p/scratch/cjjsc39/goergen1/sim/DETECT_EUR-11_ECMWF-ERA5_evaluation_r1i1p1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline/simres/ProductionV1/1979100100/{clm,parflow,restarts,cosmo}/ -type f -name '*')
do
  echo "DEBUG: inFile ${inFile}"
  parallelGzip ${inFile} &
  # Count how many tasks are already started, and wait if MAX_PARALLEL
  # (set to max number of available CPU) is reached.
  (( tmp_parallel_counter++ ))
  if [ $tmp_parallel_counter -ge $MAX_PARALLEL ]; then
    # If MAX_PARALLEL is reached wait for all tasks to finsh before continue
    wait
    tmp_parallel_counter=0
  fi
done
wait
