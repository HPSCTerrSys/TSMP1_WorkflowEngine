#!/bin/bash
#
#SBATCH --job-name="AUX_sah512sum"
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --ntasks-per-node=128
#SBATCH --time=01:00:00
#SBATCH --partition=dc-cpu-devel
#SBATCH --account=slts
#
# USAGE: 
# >> sbatch ./$0 TARGET/FILES/WILDCARDS/ARE/POSSIBL*
# >> sbatch ./aux_sha512sum.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run_TSMP/laf_lbfd/201[8,9]

calc_sha512sum() (
  # Simple calculates the sha512 sum for given file.
  # Assuming to get abs. paths to file, spliting into PATH and FILE to cd into
  # PATH first to get proper stats in CheckSum.sha512
  inFile=$1
  inFilePath="${inFile%/*}"
  inFileName="${inFile##*/}"
  cd ${inFilePath}
  sha512sum ${inFileName} >> "checksum.sha512"
)

MAX_PARALLEL=${SLURM_NTASKS}
echo "MAX_PARALLEL: $MAX_PARALLEL"
inFiles=$@
echo "${inFiles[@]}"
# set some helper-vars
tmp_parallel_counter=0
for inFile in $inFiles
do
  echo "DEBUG: inFile ${inFile}"
  calc_sha512sum ${inFile} &
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
