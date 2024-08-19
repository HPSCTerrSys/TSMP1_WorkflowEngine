#!/bin/bash
#
# USAGE:
# >> ./$0 startDate
# >> ./starter_simulation.sh $startDate

################################################################################
# Prepare
################################################################################
startDate=$1
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation    init-date: ${initDate}"
echo "---              start-date: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "---             COMBINATION: ${COMBINATION}"
echo "---              sim_NTASKS: ${sim_NTASKS}"
echo "---               sim_NODES: ${sim_NODES}"
echo "--- HOST:  $(hostname)"
echo "--- SLURM_JOB_ID: ${SLURM_JOB_ID}"

echo "--- save script start time to calculate total runtime"
scriptStartTime=$(date -u "+%s")

echo "--- source helper scripts"
source $BASE_CTRLDIR/start_helper.sh

################################################################################
# Simulation
################################################################################
# Something TSMP related
# --> aks Abouzar if still needed
export PSP_RENDEZVOUS_OPENIB=-1

formattedStartDate=$(date -u -d "${startDate}" ${dateString})
echo "DEBUG NOW: formattedStartDate: $formattedStartDate"
# NWR 20221201
# Write out everything in ISO-8601. Otherwise this may screwe up with different
# timezones and switch between CET and MESZ
startDate_m1=$(date -u -d -I "+${startDate} - ${simLength}")
formattedStartDate_m1=$(date -u -d "${startDate_m1}" ${dateString})
echo "DEBUG NOW: formattedStartDate_m1: $formattedStartDate_m1"
startDate_p1=$(date -u -d -I "+${startDate} + ${simLength}")
# NWR 20221201
# Write out everything in ISO-8601. Otherwise this may screwe up with different
# timezones and switch between CET and MESZ
formattedStartDate_p1=$(date -u -d "${startDate_p1}" ${dateString})
echo "DEBUG NOW: formattedStartDate_p1: $formattedStartDate_p1"
m0=$(date -u -d "${startDate}" '+%m')
y0=$(date -u -d "${startDate}" '+%Y')
mp1=$(date -u -d "${startDate} + ${simLength}" '+%m')
yp1=$(date -u -d "${startDate} + ${simLength}" '+%Y')
rundir=${BASE_RUNDIR}/${formattedStartDate}
pfidb="ParFlow_EU11_${formattedStartDate}"
pfidb_m1="ParFlow_EU11_${formattedStartDate_m1}"

# Calculate the number of leap-days between initDate and startDate/currentDate
# Those are needed by COSMO to proper calculate start-hours
numLeapDays=$(get_numLeapDays "$initDate" "$startDate")
numLeapDays_p1=$(get_numLeapDays "$initDate" "$startDate_p1")
echo "numLeapDays: ${numLeapDays}"
echo "numLeapDays_p1: ${numLeapDays_p1}"

# Calculate number of hours to simulate
# by calculating the different of (datep1 - date) in hours
numHours=$(datediff_inhour "${startDate}" "${startDate_p1}")
if [[ ${numLeapDays} -lt ${numLeapDays_p1} ]]; then
  echo "DEBUG NOW: HANDLING A LEAP YEAR / MONTH. startDate: ${startDate}"
  echo "numLeapDays_p1 - numLeapDays: $((numLeapDays_p1 - numLeapDays))"
  numHours=$((numHours - (numLeapDays_p1 - numLeapDays)*24))
fi
hstart=$(datediff_inhour "${initDate}" "${startDate}")
hstart=$(( hstart - numLeapDays*24 ))
hstop=$((hstart+numHours))

echo "DEBUG NOW: simLength=$simLength"
echo "DEBUG NOW: numLeapDays=$numLeapDays"
echo "DEBUG NOW: startDate=$startDate"
echo "DEBUG NOW: startDate_p1=$startDate_p1"
echo "DEBUG NOW: numHours=$numHours"
echo "DEBUG NOW: hstart=$hstart"
echo "DEBUG NOW: hstop=$hstop"

################################################################################
# Create rundir
################################################################################
echo "--- try to remove ${rundir} in case already exists"
rm -vr ${rundir}
echo "--- create ${rundir}"
mkdir -vp ${rundir}
cd ${rundir}

################################################################################
# Prepare individual components
# by copying namlist, geo files, and binaries as well as
# modifying the namelists according to variables parts as e.g. the date etc.
################################################################################
source ${BASE_ENVSDIR}/env_simulation
echo "--- -- copying binaries, geo files, and namlists for"
IFS='-' read -ra components <<< "${COMBINATION}"
numComp=$(echo "${#components[@]}")
if [ ${numComp} -ne 1 ];then
  # OASIS coupler
  echo "--- -- - oasis"
  cp ${BASE_GEODIR}/oasis/* ${rundir}/
  cp ${BASE_NAMEDIR}/namcouple_${COMBINATION} ${rundir}/namcouple
  runTime=$((numHours*3600+TSTP_CLM))
  sed -i "s,__runTime__,${runTime},g" namcouple
fi

# model components
for component in "${components[@]}"; do
  # COSMO
  if [[ "${component}" == cos? ]]; then
	echo "--- -- - cos"
	mkdir -vp ${rundir}/cosmo_out/sfc
	mkdir -vp ${rundir}/cosmo_out/pl
	mkdir -vp ${rundir}/cosmo_out/ml
	mkdir -vp ${rundir}/cosmo_out/zl
  mkdir -vp ${BASE_RUNDIR}/restarts/cosmo
	cp -v ${BASE_NAMEDIR}/INPUT_* ${rundir}/
	sed -i "s,__hstart__,${hstart},g" INPUT_IO
	sed -i "s,__hstop__,${hstop},g" INPUT_IO
	sed -i "s,__cosmo_restart_dump_interval__,$hstop,g" INPUT_IO
	sed -i "s,__cosmo_ydir_restart_in__,${BASE_RUNDIR}/restarts/cosmo,g" INPUT_IO
	sed -i "s,__cosmo_ydir_restart_out__,${BASE_RUNDIR}/restarts/cosmo,g" INPUT_IO
	sed -i "s,__cosmo_ydirini__,${BASE_FORCINGDIR}/laf_lbfd/${formattedStartDate},g" INPUT_IO
	sed -i "s,__cosmo_ydirbd__,${BASE_FORCINGDIR}/laf_lbfd/${formattedStartDate},g" INPUT_IO
	sed -i "s,__cosmo_ydir__,${rundir}/cosmo_out,g" INPUT_IO

	cosmo_ydate_ini=$(date -u -d "${initDate}" '+%Y%m%d%H')
	sed -i "s,__hstart__,$hstart,g" INPUT_ORG
	sed -i "s,__hstop__,$hstop,g" INPUT_ORG
	cosmo_tstp_nml=$(awk 'sub(/.*dt/,""){print $0}' INPUT_ORG | tr -d -c 0-9)
        if [ ${cosmo_tstp_nml} -ne ${TSTP_COSMO} ]; then
           printf "WARNING: Timestep of workflow NOT equal to namelist settings! Take timestep of workflow! \n"
           printf "Timestep COSMO namelist: ${cosmo_tstp_nml}; timestep COSMO workflow: ${TSTP_COSMO} \n"
	   sed -i "s#^\([[:blank:]]*\)dt.*#\1dt=${TSTP_COSMO},#" INPUT_ORG
        fi
	sed -i "s,__cosmo_ydate_ini__,${cosmo_ydate_ini},g" INPUT_ORG
	sed -i "s,__nprocx_cos_bldsva__,${PROC_COSMO_X},g" INPUT_ORG
	sed -i "s,__nprocy_cos_bldsva__,${PROC_COSMO_Y},g" INPUT_ORG
	cp -v ${TSMP_BINDIR}/lmparbin_pur ${rundir}/

  # CLM
  elif [[ "${component}" == clm? ]]; then
	echo "--- -- - clm"
	cp -v ${BASE_NAMEDIR}/lnd.stdin ${rundir}/
	nelapse=$((numHours*3600/TSTP_CLM+1))
	sed -i "s,__nelapse__,${nelapse},g" lnd.stdin
	start_ymd=$(date -u -d "${startDate}" '+%Y%m%d')
	sed -i "s,__start_ymd__,${start_ymd},g" lnd.stdin
  # Do use `-` prefix for date string to avoid below error:
  # ERROR: value too great for base (error token is "09")
  # Solution found at: https://stackoverflow.com/a/65848366
	tmp_h=$(date -u -d "${startDate}" '+%-H')
	tmp_m=$(date -u -d "${startDate}" '+%-M')
	tmp_s=$(date -u -d "${startDate}" '+%-S')
	start_tod=$((tmp_h*60*60 + tmp_m*60 + tmp_s))
	sed -i "s,__start_tod__,${start_tod},g" lnd.stdin
	clm_restart_date=$(date -u -d "${startDate}" '+%Y-%m-%d')
  clm_restart_sec=$(printf "%05d" ${start_tod=})
	sed -i "s,__clm_restart__,clmoas.clm2.r.${clm_restart_date}-${clm_restart_sec}.nc,g" lnd.stdin
	clm_tstp_nml=$(awk 'sub(/.*dtime/,""){print $2}' lnd.stdin)
	if [ ${clm_tstp_nml} -ne ${TSTP_CLM} ]; then
	   printf "WARNING: Timestep of workflow NOT equal to namelist settings! Take timestep of workflow! \n"
	   printf "Timestep CLM namelist: ${clm_tstp_nml}; timestep CLM workflow: ${TSTP_CLM} \n"
	   sed -i "s,^\([[:blank:]]*\)dtime.*$,\1dtime          =  ${TSTP_CLM}," lnd.stdin
	   sed -E -i "s/^((CLM|COS).{5} {1,}(COS|CLM).{5} {1,}[0-9]{1,}) [0-9]{1,} /\1 ${TSTP_CLM} /" namcouple
	fi
	sed -i "s,__BASE_RUNDIR__,${BASE_RUNDIR},g" lnd.stdin
	sed -i "s,__BASE_FORCINGDIR__,${BASE_FORCINGDIR},g" lnd.stdin
	sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" lnd.stdin
	sed -i "s,__sim_rundir__,${rundir},g" lnd.stdin
	# Check if COMBINATION does contain "cos", so that COSMO ist 
	# used, wherefore CLM does NOT needs forcing files
  if [[ $COMBINATION == *"cos"* ]]; then
    # To make sure no offine forcing is accidentally read in:
	  # replace line matchin *offline_atmdir* with offline_atmdir = 'BULLSHIT'
	  sed -i "s,.*offline_atmdir.*, offline_atmdir = 'BULLSHIT',g" lnd.stdin
  fi
	# 
	cp -v ${TSMP_BINDIR}/clm ${rundir}/

  # ParFlow
  elif [[ "${component}" == pfl ]]; then
	echo "--- -- - pfl"
        # Export PARFLOW_DIR, which is equal to TSMP_BINDIR, but needed
        # by ParFlow as PARFLOW_DIR
        export PARFLOW_DIR=${TSMP_BINDIR}
	cp -v ${BASE_NAMEDIR}/coup_oas.tcl ${rundir}/
	cp -v ${BASE_GEODIR}/parflow/* ${rundir}/
	sed -i "s,__TimingInfo.StopTime__,${numHours},g" coup_oas.tcl
	parflow_tstp_nml=$(awk 'sub(/.*pfset TimeStep.Value/,""){print $0}' coup_oas.tcl | awk '{ gsub (" ", "", $0); print}')
        TSTP_PARFLOW_HR=$(echo "scale=4;${TSTP_PARFLOW}/3600" | bc)
	if (( $(echo "$parflow_tstp_nml != $TSTP_PARFLOW_HR" | bc -l) )); then
           printf "WARNING: Timestep of workflow NOT equal to namelist settings! Take timestep of workflow! \n"
           printf "Timestep PARFLOW namelist: ${parflow_tstp_nml}; timestep PARFLOW workflow: ${TSTP_PARFLOW_HR} \n"
	   sed -i "s,^\([[:blank:]]*\)pfset TimeStep.Value.*$,\1pfset TimeStep.Value                     ${TSTP_PARFLOW_HR}," coup_oas.tcl
	   sed -E -i "s/^((CLM|PFL).{5} {1,}(PFL|CLM).{5} {1,}[0-9]{1,}) [0-9]{1,} /\1 ${TSTP_PARFLOW} /" namcouple
        fi
  # Below test if restart file for ParFlow does exist is important!
  # If ParFlow is driven with netCDF files, a non existing ICPressure file
  # will not crash the program, but ParFlow is assuming init pressure of zero 
  # everywhere.
  # So check if file exist and force exit if needed.
  echo "test: ls -1 "${BASE_RUNDIR}/restarts/parflow/${pfidb_m1}.out.*.nc" | tail -1"
  # Just for cold start!
  pfl_restart_file=`ls -1 ${BASE_RUNDIR}/restarts/parflow/${pfidb_m1}.out.*.nc | tail -1`
  if [ -f "${pfl_restart_file}" ]; then
      cp -v ${pfl_restart_file} "${rundir}/"
  else
      echo "ParFlow restart file (${pfl_restart_file}) does not exist --> exit"
      exit 1
  fi
	ic_pressure=`ls -1 ${pfidb_m1}.out.*.nc | tail -1`
	sed -i "s,__ICPressure__,${ic_pressure},g" coup_oas.tcl
	sed -i "s,__pfidb__,${pfidb},g" coup_oas.tcl
	sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" coup_oas.tcl
	sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" coup_oas.tcl
	sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" coup_oas.tcl
	# Check if COMBINATION does NOT contain "clm", so that neither COSMO nor
  # CLM ist used, wherefore ParFlow needs forcing files
  if [[ $COMBINATION != *"clm"* ]]; then
	  # Adjust lines if ParFlow forcing is needed
	  evaptransfile="evaptrans_${formattedStartDate}.nc"
	  cp -v ${BASE_FORCINGDIR}/parflow/${evaptransfile} ${rundir}/
    sed -i "s,__EvapTransFile__,"True",g" coup_oas.tcl
    sed -i "s,__EvapTrans_FileName__,"${evaptransfile}",g" coup_oas.tcl
  else
	  # Remove lines if no ParFlow forcing is needed
	  sed -i '/__EvapTransFile__/d' coup_oas.tcl
	  sed -i '/__EvapTrans_FileName__/d' coup_oas.tcl
  fi

	echo "--- execute ParFlow distributeing tcl-scripts "
	sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" ascii2pfb_slopes.tcl
	sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" ascii2pfb_slopes.tcl
	tclsh ascii2pfb_slopes.tcl
	sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" ascii2pfb_SoilInd.tcl
	sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" ascii2pfb_SoilInd.tcl
	tclsh ascii2pfb_SoilInd.tcl
  srun --nodes=1 --ntasks=1 tclsh coup_oas.tcl
  #
	cp -v ${TSMP_BINDIR}/parflow ${rundir}/
  
  else
	echo "ERROR: unknown component ($component) --> Exit"
	exit 1
  fi
done

################################################################################
# Prepare slm_multiprog_mapping.conf
# prviding information which component to run at which CPUs
################################################################################
if [[ "$COMBINATION" == clm?-cos?-pfl ]]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_COSMO_X} * ${PROC_COSMO_Y})) "./lmparbin_pur" \
		$((${PROC_PARFLOW_P} * ${PROC_PARFLOW_Q})) "./parflow ${pfidb}" \
		${PROC_CLM} "./clm"
elif [[ "$COMBINATION" == clm?-pfl ]]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_PARFLOW_P} * ${PROC_PARFLOW_Q})) "./parflow ${pfidb}" \
		${PROC_CLM} "./clm"
elif [[ "$COMBINATION" == clm?-cos? ]]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_COSMO_X} * ${PROC_COSMO_Y})) "./lmparbin_pur" \
		${PROC_CLM} "./clm"
elif [[ "$COMBINATION" == cos? ]]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_COSMO_X} * ${PROC_COSMO_Y})) "./lmparbin_pur" 
elif [[ "$COMBINATION" == clm? ]]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		${PROC_CLM} "./clm"
elif [[ "$COMBINATION" == pfl ]]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
    $((${PROC_PARFLOW_P} * ${PROC_PARFLOW_Q})) "./parflow ${pfidb}"
fi

################################################################################
# Running the simulation
#
# unclear whether this has an impact due to the mapping with MPMD exec model
# previous default srun invocation before 2024-08-06 update
# supposed previous default, never explicitely set
# supposed new default, explicitely setting affinity
################################################################################
rm -rf YU*
echo "DEBUG: start simulation"
srun --multi-prog slm_multiprog_mapping.conf
#srun --cpu-bind=threads --distribution=block:cyclic:fcyclic --multi-prog slm_multiprog_mapping.conf
#srun --cpu-bind=threads --distribution=block:cyclic:cyclic --multi-prog slm_multiprog_mapping.conf

if [[ $? != 0 ]] ; then exit 1 ; fi
date
wait

################################################################################
# Moving model-output to simres and storing restart files
# for individual components
################################################################################
echo "--- create SIMRES dir (and sub-dirs) to store simulation results"
new_simres=${BASE_SIMRESDIR}/${formattedStartDate}
echo "--- new_simres: $new_simres"
# clean beforehand to avoid conflicts in case of a re-run
rm -rvf $new_simres
mkdir -p "$new_simres/log"
mkdir -p "$new_simres/nml"

echo "--- Moving model-output to simres/ and restarts/"
# looping over all component set in COMBINATION
IFS='-' read -ra components <<< "${COMBINATION}"
numComp=$(echo "${#components[@]}")
if [ ${numComp} -ne 1 ];then
  echo "--- - OASIS"
  # Move OASIS namelist to simres/nml
  cp -v ${rundir}/namcouple ${new_simres}/nml/
fi
for component in "${components[@]}"; do
  # COSMO
  if [[ "${component}" == cos? ]]; then
    echo "--- - COSMO"
    # Create component subdir
    mkdir -p "$new_simres/restarts/cosmo"
    mkdir -p "$new_simres/cosmo"
    mkdir -p -v ${BASE_RUNDIR}/restarts/cosmo
    # Save restart files for next simulation
    # -- COSMO does store the restart files in correct dir already
    # Move model-output to simres/
    cp -vr ${rundir}/cosmo_out/* $new_simres/cosmo
    # COSMO writs restart direct to ${BASE_RUNDIR}/restarts/cosmo/
    cosmoRestartFileDate=$(date -u -d "${startDate_p1}" "+%Y%m%d%H")
    cp -v ${BASE_RUNDIR}/restarts/cosmo/lrfd${cosmoRestartFileDate}o $new_simres/restarts/cosmo
    check4error $? "--- ERROR while moving COSMO model output to simres-dir"
    # Move COSMO logs to simres/log
    cp -v ${rundir}/YU* ${new_simres}/log/
    # Move COSMO namelist to simres/nml
    cp -v ${rundir}/INPUT_* ${new_simres}/nml/
  # CLM
  elif [[ "${component}" == clm? ]]; then
    echo "--- - CLM"
    # Create component subdir
    mkdir -p "$new_simres/restarts/clm"
    mkdir -p "$new_simres/clm"
    mkdir -p -v ${BASE_RUNDIR}/restarts/clm

    # Do use `-` prefix for date string to avoid below error:
    # ERROR: value too great for base (error token is "09")
    # Solution found at: https://stackoverflow.com/a/65848366
    tmp_h=$(date -u -d "${startDate_p1}" '+%-H')
    tmp_m=$(date -u -d "${startDate_p1}" '+%-M')
    tmp_s=$(date -u -d "${startDate_p1}" '+%-S')
    start_tod_p1=$((tmp_h*60*60 + tmp_m*60 + tmp_s))
    clm_restart_date_p1=$(date -u -d "${startDate_p1}" '+%Y-%m-%d')
    clm_restart_sec_p1=$(printf "%05d" ${start_tod_p1})
    clm_restart_fiel_p1="clmoas.clm2.r.${clm_restart_date_p1}-${clm_restart_sec_p1}.nc"
    
    # Create component subdir

    cp -v ${rundir}/${clm_restart_fiel_p1} ${BASE_RUNDIR}/restarts/clm/
    # Move model-output to simres/
    cp -v ${rundir}/clmoas.clm2.h?.*.nc $new_simres/clm/
    check4error $? "--- ERROR while moving CLM model output to simres-dir"
    cp -v ${BASE_RUNDIR}/restarts/clm/${clm_restart_fiel_p1} $new_simres/restarts/clm
    check4error $? "--- ERROR while moving CLM restart file to restart-dir"
    # Move CLM logs to simres/log
    cp -v ${rundir}/timing_all ${new_simres}/log/
    # Move CLM namelist to simres/nml
    cp -v ${rundir}/lnd.stdin ${new_simres}/nml/
  # PFL
  elif [[ "${component}" == pfl ]]; then
    echo "--- - PFL"
    # Create component subdir
    mkdir -p "$new_simres/restarts/parflow"
    mkdir -p "$new_simres/parflow"
    mkdir -p -v ${BASE_RUNDIR}/restarts/parflow
    # Save restart files for next simulation
    pfl_restart=`ls -1 ${rundir}/${pfidb}.out.?????.nc | tail -1`
    cp -v ${pfl_restart} ${BASE_RUNDIR}/restarts/parflow/
    # Move model-output to simres/
    cp -v ${rundir}/${pfidb}.out.* $new_simres/parflow
    cp -v ${BASE_RUNDIR}/restarts/parflow/${pfidb}.out.?????.nc $new_simres/restarts/parflow
    check4error $? "--- ERROR while moving ParFlow model output to simres-dir"
    # Move *kinsol.log to simres/log
    cp -v ${rundir}/*out.kinsol.log ${new_simres}/log/
    # Move ParFlow timing to simres/log
    cp -v ${rundir}/*out.timing* ${new_simres}/log/
    # Move ParFlow namelist to simres/nml
    cp -v ${rundir}/coup_oas.tcl ${new_simres}/nml/
  else
    echo "ERROR: unknown component ($component) --> Exit"
    exit 1
  fi
done
# add more files from rundir/ to log/
test -f ${rundir}/slm_multiprog_mapping.conf && cp ${rundir}/slm_multiprog_mapping.conf ${new_simres}/log/.

# Wait for all procs to finish than save simres and clean rundir
wait
echo "--- remove write permission from all files in simres"
find ${new_simres} -type f -exec chmod a-w {} \;
echo "--- clean/remove rundir"
rm -r ${rundir}

################################################################################
# Creating HISTORY.txt and store TSMP build log (reusability etc.)
################################################################################
echo "--- save script end time to calculate total runtime"
scriptEndTime=$(date -u "+%s")
totalRunTime_sec=$(($scriptEndTime - $scriptStartTime))
# Oneliner to convert second in %H:%M:%S taken from:
# https://stackoverflow.com/a/39452629
totalRunTime=$(printf '%02dh:%02dm:%02ds\n' $((totalRunTime_sec/3600)) $((totalRunTime_sec%3600/60)) $((totalRunTime_sec%60)))

echo "--- Moving TSMP log to simres/log"
TSMPLogFile=`ls -rt ${TSMP_BINDIR}/log_all* | tail -1`
cp -v ${TSMPLogFile} ${new_simres}/log/TSMP_BuildLog.txt

echo "--- Moving SLURM log to simres/log"
# testNewSlurmNewAffinityNewCtrl_sim_ssp370_2019010100.err.13066672
cp -v ${BASE_CTRLDIR}/logs/${CaseID}_sim_*.{err,out}.${SLURM_JOB_ID} $new_simres/log/.

histfile="HISTORY.txt"
logdir="${new_simres}/log"

cd ${BASE_CTRLDIR}
git diff HEAD > ${logdir}/GitDiffHead_workflow.diff
TAG_WORKFLOW=$(git describe --tags)
COMMIT_WORKFLOW=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_WORKFLOW=$(git log --pretty=format:'author: %an' -n 1)
DATE_WORKFLOW=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_WORKFLOW=$(git log --pretty=format:'subject: %s' -n 1)
URL_WORKFLOW=$(git config --get remote.origin.url)

/bin/cat <<EOM >"${logdir}/${histfile}"
###############################################################################
Author: ${AUTHOR_NAME}
e-mail: ${AUTHOR_MAIL}
version: $(date)
###############################################################################
MACHINE: $(cat /etc/FZJ/systemname)
SLURM_JOB_ID: ${SLURM_JOB_ID}
PARTITION: ${SIM_PARTITION}
CaseID: ${CaseID}
Total runtime: ${totalRunTime}
###############################################################################
The following setup was used: 
###############################################################################
WORKFLOW 
-- REPO:
${URL_WORKFLOW}
-- LOG: 
tag: ${TAG_WORKFLOW}
${COMMIT_WORKFLOW}
${AUTHOR_WORKFLOW}
${DATE_WORKFLOW}
${SUBJECT_WORKFLOW}

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of \`git diff HEAD\` is printed to \`GitDiffHead_workflow.diff\`.
###############################################################################
EOM
check4error $? "--- ERROR while creating HISTORY.txt"
# We need to escape \$path and \$toplevel as those variables are part of the 
# namespace from `git submodule foreach` and not from this script.
git submodule foreach "logSubmodule \$path ${logdir} ${histfile} || :"
check4error $? "--- ERROR while creating HISTORY.txt"

echo "###################################################"
echo "STOP Logging ($(date)):"
echo "--- exe: $0"
echo "###################################################"
exit 0
