#!/usr/bin/bash
#
# Description
# This script is intened to get data on $ARCHIVE back to spinning disk 
# (restage) once they are really on tape.
# The restaging process is initiated automatically if any action is performed 
# on the data itselfe. So do a inventory of a tar-ball, print the tail or head,
# or copy the data automatically startes the process, but this needs time!
# So best practice would be to start a invetory or other fast taskes in the 
# background and wait until all data are back on spinning disk...
#
# USAGE:
# >> nohup ./$0 PATH/TO/SIMRES/DIR/TARpattern* &
# >> nohup /aux_restageTape.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/simres/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3_1980*.tar &
#

# Assumes every argument as DATASET
tarfiles=$@
cwd=$(pwd)

for tarfile in $tarfiles; do
  # come back to cwd after each loop
  cd ${cwd}
  # skip if $tarfile is not a file (or link to file)
  if [[ ! -f $tarfile ]]; then continue; fi
  tarfile_name=${tarfile##*/}
  tarfile_dir=${tarfile%/*}
  cd ${tarfile_dir}
  echo "working on: $tarfile"
  echo "-- inventoring"
  tar -tvf ${tarfile_name}
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- done"
done
