#!/bin/bash

# AUTHOR: Klaus GOERGEN (KGo), FZJ/IBG-3, k.goergen@fz-juelich.de
# VERSION: 2023-10-29
# USAGE: ./$0 <year_to_check>(<month_to_check>) | less -S
# USAGE: for i in {2006..2014} ; do echo $i && echo "==================================" >> ttt && echo $i >> ttt && ./aux_checkCompleteness.sh $i >> ttt ; done
# PURPOSE: make manual checking of sims easier, stats and details still missing
#          check only on file-system level, number and size of files
#          directories exist, empty or not

echo $0
date
echo $USER
hostname
pwd

dateCheck=$1
CaseID="ProductionV1"
CTRLDIR=$(pwd)

source ${CTRLDIR}/SimInfo.sh
source ${CTRLDIR}/export_paths.sh
source ${BASE_CTRLDIR}/start_helper.sh
updatePathsForCASES ${BASE_CTRLDIR}/CASES.conf ${CaseID}

echo "################################################################################"
echo "checking the right experiment after all?"
echo "checking ${EXPID}"

echo "################################################################################"
echo "any dangling simulations? ToPostPro/ must be empty"
cd $BASE_RUNDIR && pwd
ls
cd ToPostPro && pwd
ls

declare -a check_result
declare -i array_counter=0

# loop over different output dirs
for i_procstep in {$BASE_SIMRESDIR,$BASE_POSTPRODIR} ; do
  echo "################################################################################"
  echo "number of files and size OK -> all processed? all finalized (gz)?"
  echo "simres: COSMO = 2006(31d)/1942(30d)/1814(28d) files/month (if 2002 files: checksum files missing -> no finalization), 122-127GB/month"
  echo "simres: CLM = 33(31d)/32(30d)/30(28d) files/month (if less files: checksum files missing -> no finalization), 13-14GB/month"
  echo "simres: ParFlow = 60(31d)/59(30d)/57(28d) files/month (if less files: checksum files missing -> no finalization), 58-68GB/month"
  echo "postpro: COSMO = 183 files/month, 61/65/67GB/month"
  echo "postpro: CLM = 36 files/month, 4.7-5.5GB/month"
  echo "postpro: ParFlow = 119(31d)/116(30d)/110(28d) files/month, 70-78GB/month"
  cd $i_procstep && pwd
  # loop over component models
  for i_mod in {cosmo,clm,parflow} ; do
    echo "========================================="
    fssumf=0.0
    fnsumf=0.0
    # loop over months per year
    # du uses [kB] as unit
    for i_path in ${dateCheck}*/${i_mod} ; do
      echo $i_mod
      dirname $i_path
      fs=$(du -s $i_path | cut -f1)
      fs=$(bc -l <<< "scale=2;$fs/1024^2")
      fss=$(du -sh $i_path | cut -f1)
      fn=$(ls -R1 $i_path | wc -l)
      echo $fss $fs
      echo $fn
      fssumf=$(bc -l <<< "scale=2;$fssumf+$fs")
      fnsumf=$(bc -l <<< "scale=2;$fnsumf+$fn")
      echo "--------------------"
    done
    # x2 cosmo 0 1, clm 2 3, parflow 4 5
    check_result[$((0+$array_counter*2))]=$fnsumf
    check_result[$((1+$array_counter*2))]=$fssumf
    ((array_counter++))
    echo ${check_result[@]}
  done
done

echo "################################################################################"
echo "monitoring worked?"
echo "monitoring: 21 files/month, about 3.5MB/month"
cd $BASE_MONITORINGDIR && pwd
echo "========================================="
fssumf=0.0
fnsumf=0.0
for i_path in ${dateCheck}* ; do
  echo $i_path
  fs=$(du -s $i_path | cut -f1)
  fs=$(bc -l <<< "scale=2;$fs/1024")
  fss=$(du -sh $i_path | cut -f1)
  fn=$(ls -R1 $i_path | wc -l)
  echo $fss $fs
  echo $fn
  fssumf=$(bc -l <<< "scale=2;$fssumf+$fs")
  fnsumf=$(bc -l <<< "scale=2;$fnsumf+$fn")
  echo "--------------------"
done
check_result[$((0+$array_counter*2))]=$fnsumf
check_result[$((1+$array_counter*2))]=$fssumf
echo "to check:" ${check_result[@]}

#diff array
array_counter=0
declare -a refvec
refvec=(23624.0 1487.0 389.0 149.0 713.0 726.0 2196.0 786.0 432.0 59.0 1407.0 884.0 252.0 41.0)
echo "reference:" ${refvec[@]}
for i in ${refvec[@]}
do
  echo $i ${check_result[$array_counter]}
  if (( $(echo "${check_result[$array_counter]} < $i" | bc -l) )); then
    echo "WARNING, number/size of files lower than expected, check ref:" ${check_result[$array_counter]} $i 
  fi
  ((array_counter++))
done

exit 0
