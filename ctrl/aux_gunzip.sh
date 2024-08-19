#!/bin/bash
#
#SBATCH --job-name="AUX_gunzip"
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --ntasks-per-node=128
#SBATCH --threads-per-core=1
#SBATCH --time=00:30:00
#SBATCH --partition=dc-cpu
#SBATCH --account=jjsc39
#
# USAGE: 
# >> sbatch ./$0 TARGET/FILES/WILDCARDS/ARE/POSSIBL*
# for use in workflow
# sbatch aux_gunzip.sh $WORKFLOWPATH/simres/ProductionV1/$DATE/{clm,cosmo,parflow}/{*/*,*}

parallelGzip() (
  # Simple run gzip on inFile
  tmpInFile=$1
  gunzip ${tmpInFile} 
)

MAX_PARALLEL=${SLURM_NTASKS}
echo "MAX_PARALLEL: $MAX_PARALLEL"
inFiles=$@
echo "${inFiles[@]}"
tmp_parallel_counter=0
for inFile in $(find $inFiles -type f -wholename "*.gz")
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

exit 0
