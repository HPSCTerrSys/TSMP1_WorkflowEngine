#!/usr/bin/bash
#
# Description:
# This script does tar given sourc-dir(s) to given target-dir, 
# removes the original directory(s), and links the created tar-ball form 
# target-dir to the location of the original directory.
#
# USAGE:
# bash ./$0 TARGET/DIR SOURCE/DIR/pattern*
# nohup bash ./aux_MigrateFromScratch.sh     /p/arch2/jjsc39/jjsc3900/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_v1/simres/ProductionV1  /p/scratch/cjjsc39/goergen1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_v1R/simres/ProductionV1/19790[1,2]* >> nohup_simres.out &
# nohup bash ./aux_MigrateFromScratch.sh /p/largedata2/detectdata/CentralDB/projects/d02/working_directory/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_v1/postpro/ProductionV1 /p/scratch/cjjsc39/goergen1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_v1R/postpro/ProductionV1/19790[1,2]* >> nohup_postpro.out &


TARGET=$1
# .. and assumes every further argument as SOURCES (there is a plural s!)
shift 1
SOURCES=$@

for SOURCE in $SOURCES; do
  # skip if targetdir is not a directory
  if [[ ! -d $SOURCE ]]; then continue; fi
  source_name=${SOURCE##*/}
  echo "-- taring"
  cd ${SOURCE%/*} && pwd
  echo "working on: $source_name"
  echo "taring to: ${TARGET}/${source_name}.tar"
  tar -cvf ${TARGET}/${source_name}.tar ${source_name}
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- remove source"
  #mv ${source_name} REMOVE_${source_name} 
  rm -rf ${source_name}
  echo "-- linking"
  ln -sf ${TARGET}/${source_name}.tar ./
  echo "-- done"
done
