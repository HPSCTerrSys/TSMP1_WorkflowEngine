#!/usr/bin/bash
#
# Description:
# This script link given sourc-dir(s) to given target-dir.
#
# USAGE:
# >> bash ./$0 SOURCE/DIR TARGET/DIR/pattern*
#  bash ./aux_LinkFromScratch.sh /p/scratch/cjjsc39/poll1/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline/simres/ProductionV1/ /p/arch2/jjsc39/jjsc3900/sim/DETECT_EUR-11_MPI-ESM1-2-HR_historical_r1i1p1f1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_v1/simres/ProductionV1/195[0,1][01,02,03,04,05,06,07,08,09,10,11,12]*

SOURCE=$1
# .. and assumes every further argument as TARGETS (there is a plural s!)
shift 1
TARGETS=$@

for TARGET in $TARGETS; do
  # skip if targetdir is not a directory
  if [[ ! -f $TARGET ]]; then continue; fi
  source_name=${TARGET##*/}
  echo "-- change dir"
  cd ${SOURCE} && pwd
  echo "working on: $source_name"
  echo "-- linking"
#
#  ln -sf ${TARGET}/${source_name} ./
  ln -sf ${TARGET} ./
#
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- done"
done
