#!/usr/bin/bash
#
# Description:
# This script does link given sourc-dir(s) to given target-dir, 
# rename the original directory(s).
#
# USAGE:
# >> bash ./$0 TARGET/DIR SOURCE/DIR/pattern*
#  bash ./aux_LinkToScratch.sh /p/largedata/jjsc39/goergen1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline/simres/ProductionV1/ /p/scratch/cjjsc39/poll1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline/simres/ProductionV1/1950[01,02,03,04,05,06,07,08,09,10,11,12]* 
#  bash ./aux_LinkToScratch.sh /p/largedata/jjsc39/goergen1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline/postpro/ProductionV1/ /p/scratch/cjjsc39/poll1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline/postpro/ProductionV1/1950[01,02,03,04,05,06,07,08,09,10,11,12]*
#  bash ./aux_LinkToScratch.sh /p/arch2/jjsc39/jjsc3900/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_v1/simres/ProductionV1 /p/scratch/cjjsc39/poll1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline/simres/ProductionV1/196[1,2][01,02,03,04,05,06,07,08,09,10,11,12]*

TARGET=$1
# .. and assumes every further argument as SOURCES (there is a plural s!)
shift 1
SOURCES=$@

for SOURCE in $SOURCES; do
  # skip if targetdir is not a directory
  if [[ ! -d $SOURCE ]]; then continue; fi
  source_name=${SOURCE##*/}
  echo "-- change dir"
  cd ${SOURCE%/*} && pwd
  echo "working on: $source_name"
  echo "-- linking"
  ln -sf ${TARGET}/${source_name}.tar ./
#
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- rename source"
  if [[ -f ${TARGET}/${source_name}.tar ]]; then 
    mv ${source_name} REMOVE_${source_name} 
  else 
     echo "-- WARNING: File "${TARGET}"/"${source_name}".tar does not exist"
     echo "-- do not rename source"
  fi
  echo "-- done"
done
