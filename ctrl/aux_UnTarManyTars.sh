#!/usr/bin/bash
#
# Description
# This script tars a given directory to tape, remove the original directory, 
# and links the created tar-ball form tape to the location of the original 
# directory.
# In addition this works for multiple files, which can be apssed with 
# wildcasts (*,?, etc) -- see USAGE
# This script is aimed for the scope of my usual workflow structur, meaning
# it is based on the usage of the 'export_paths.sh'. If this script should
# be used outsind this scope, you need to take care about paths set within 
# 'export_paths.sh' by your self.
#
# USAGE:
# >> ./$0 PATH/TO/TAR/BALS/patterns*
# >> ./aux_UnTarManyTars.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/postpro/1980*
#

tarballs=$@

for tarball in $tarballs; do
  tarRootDir=${tarball%/*}
  echo "tarRootDir: $tarRootDir"
  cd $tarRootDir
  # skip if $tarball does not contain tarball...
  if [[ ${tarball##*.} != 'tar' ]]; then continue; fi
  tarName=${tarball##*/}
  echo "working on: $tarName"
  echo "-- untaring"

  tarNameNoExtention=${tarName%.tar} 
  # the order of the -C flag is important!
  # ref: https://stackoverflow.com/questions/9249603/how-to-extract-a-single-file-from-tar-to-a-different-directory
  #tar --exclude=${tarNameNoExtention}/pressure.nc -xvf ./${tarName} -C /p/scratch/cslts/tsmpforecast/WADKlim/OBSrun/postpro ${tarNameNoExtention}/gwr.nc
  tar -xvf ./${tarName} -C ./
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- done"
done
