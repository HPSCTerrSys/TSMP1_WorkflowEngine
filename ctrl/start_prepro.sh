#!/bin/bash
#
# USAGE: 
# >> ./$0 startDate
# >> ./start_prepro.sh $startDate

###############################################################################
# Prepare
###############################################################################
startDate=$1
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation    init-date: ${initDate}"
echo "---              start-data: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "---             COMBINATION: ${COMBINATION}"
echo "--- HOST:  $(hostname)"

echo "--- source helper scripts"
source $BASE_CTRLDIR/start_helper.sh

# clear $? before continue
echo $?

echo "DEBUG: setup environment"
source ${BASE_CTRLDIR}/start_helper.sh
export INT2LM_BINDIR="${BASE_SRCDIR}/int2lm3.00"
export INT2LM_EXNAME="int2lm3.00"
source ${BASE_ENVSDIR}/loadenv_int2lm


h0=$(date -u -d "$startDate" '+%H')
d0=$(date -u -d "$startDate" '+%d')
m0=$(date -u -d "$startDate" '+%m')
y0=$(date -u -d "$startDate" '+%Y')
# NWR 20221201                                                                  
# Write out everything in ISO-8601. Otherwise this may screwe up with different 
# timezones and switch between CET and MESZ
formattedStartDate=$(date -u -d "${startDate}" ${dateString})
echo "DEBUG NOW: formattedStartDate: $formattedStartDate"                       
startDate_m1=$(date -u -d -I "+${startDate} - ${simLength}")                    
formattedStartDate_m1=$(date -u -d "${startDate_m1}" ${dateString})             
echo "DEBUG NOW: formattedStartDate_m1: $formattedStartDate_m1"                 
startDate_p1=$(date -u -d -I "+${startDate} + ${simLength}")                    
formattedStartDate_p1=$(date -u -d "${startDate_p1}" ${dateString})             
echo "DEBUG NOW: formattedStartDate_p1: $formattedStartDate_p1"

# Calulate number of hours to simulate by taking into account leap days
numLeapDays_p1=$(get_numLeapDays "$startDate" "$startDate_p1")                   
echo "numLeapDays_p1: ${numLeapDays_p1}"
numHours=$(datediff_inhour "${startDate}" "${startDate_p1}")                    
if [[ ${numLeapDays_p1} -gt 0 ]]; then
  echo "DEBUG: HANDLING A DAY. startDate: ${startDate}"       
  numHours=$((numHours - (numLeapDays_p1)*24))
fi
                                                                                
echo "DEBUG NOW: simLength=$simLength"                                          
echo "DEBUG NOW: startDate=$startDate"                                          
echo "DEBUG NOW: startDate_p1=$startDate_p1"                                    
echo "DEBUG NOW: numHours=$numHours"                                            

###############################################################################
# Pre-Pro INT2LM
###############################################################################
int2lm_LmCatDir="${BASE_FORCINGDIR}/laf_lbfd/${formattedStartDate}"
##tmpRawCafFiles="${BASE_FORCINGDIR}/tmpRawCafFiles/${formattedStartDate}"
rundir="${BASE_RUNDIR}/INT2LM_${formattedStartDate}"
# Remove rundir and int2lm_LmCatDir in case already exisit, to avoid conflicts.               
# E.g. from some simulation before.                                             
if [[ -d ${rundir} ]]; then
  rm -rv ${rundir}
fi
if [[ -d ${int2lm_LmCatDir} ]]; then
  rm -rv ${int2lm_LmCatDir}
fi
##if [[ -d ${tmpRawCafFiles} ]]; then
##  rm -rv ${tmpRawCafFiles}
##fi
mkdir -pv ${int2lm_LmCatDir}
mkdir -pv ${rundir}
##mkdir -pv ${tmpRawCafFiles}

# Copy, unzip, and change time.calendar of orig caf files to prepare to use by
# INT2LM.
# Luckily the raw files are stored in monthly chunks and does contain the first
# of the next month...
#... copying and unzipping will be done in parallel chunks
MAXPP=${SLURM_NTASKS}
COUNTPP=0
cafFilesTar="${BASE_FORCINGDIR}/cafFilesTar/year${y0}/${DRS_GCMMODEL}_${DRS_EXPERIMENT_NAME}_${DRS_ENSEMBLEME_MBER}_${y0}_${m0}.tar"
cafFilesIn="${BASE_FORCINGDIR}/cafFilesIn/${y0}/${y0}_${m0}"
#
# # for MPI-ESM-HR
#mkdir -pv ${cafFilesIn}
#tar -xvf ${cafFilesTar} -C ${cafFilesIn}
#
# Use find and POSIX-Extended_Regular_Expressions 
# > https://en.wikibooks.org/wiki/Regular_Expressions/POSIX-Extended_Regular_Expressions
# to copy only needed files.
# In our case we need the forcing for every 3 hours only.
FILELIST=$(find ${cafFilesIn} -regextype posix-extended -regex '.*cas[0-9]{8}(00|03|06|09|12|15|18|21)\.ncz' -print)
#FILELIST=$(find ${cafFilesIn} -regextype posix-extended -regex '.*caf[0-9]{8}(00|06|12|18)\.ncz' -print) # MPI-ESM-HR
for FILE in ${FILELIST}
  do
    FILEBASE=$(basename ${FILE} .ncz)
    nccopy -k 2 ${cafFilesIn}/${FILEBASE}.ncz ${rundir}/${FILEBASE}.nc &
    ##nccopy -k 2 ${cafFilesIn}/${FILEBASE}.ncz ${tmpRawCafFiles}/${FILEBASE}.nc &
    (( COUNTPP=COUNTPP+1 ))
    if [[ ${COUNTPP} -ge ${MAXPP} ]]
    then
      COUNTPP=0
      wait
    fi
  done
wait
# ... change time.calendar in parallel
FILELIST=$(ls -1 ${rundir}/*.nc)
##FILELIST=$(ls -1 ${tmpRawCafFiles}/*.nc)
COUNTPP=0
for FILE in ${FILELIST}
do
  ncatted -O -a calendar,time,o,c,"${CaseCalendar}" ${FILE} &
  (( COUNTPP=COUNTPP+1 ))
  if [[ ${COUNTPP} -ge ${MAXPP} ]]
  then
    COUNTPP=0
    wait
  fi
done
wait

# Creating HISTORY.txt (reusability etc.)
################################################################################
histfile=${int2lm_LmCatDir}/HISTORY.txt
echo "DEBUG: creating HISTORY.txt (reusability etc.)"
cd ${INT2LM_BINDIR}
TAG_INT2LM=$(git describe --tags)
COMMIT_INT2LM=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_INT2LM=$(git log --pretty=format:'author: %an' -n 1)
DATE_INT2LM=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_INT2LM=$(git log --pretty=format:'subject: %s' -n 1)
URL_INT2LM=$(git config --get remote.origin.url)
cd ${BASE_CTRLDIR}
TAG_WORKFLOW=$(git describe --tags)
COMMIT_WORKFLOW=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_WORKFLOW=$(git log --pretty=format:'author: %an' -n 1)
DATE_WORKFLOW=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_WORKFLOW=$(git log --pretty=format:'subject: %s' -n 1)
URL_WORKFLOW=$(git config --get remote.origin.url)
/bin/cat <<EOM >$histfile
###############################################################################
date executed: $(date)
The following setup was used:
###############################################################################
INT2LM version
-- REPO:
${URL_INT2LM}
-- LOG: 
tag: ${TAG_INT2LM}
${COMMIT_INT2LM}
${AUTHOR_INT2LM}
${DATE_INT2LM}
${SUBJECT_INT2LM}
###############################################################################
WORKFLOW (for INT2LM namelist etc)
-- REPO:
${URL_WORKFLOW}
-- LOG:
tag: ${TAG_WORKFLOW}
${COMMIT_WORKFLOW}
${AUTHOR_WORKFLOW}
${DATE_WORKFLOW}
${SUBJECT_WORKFLOW}
###############################################################################
EOM
check4error $? "--- ERROR while creating HISTORY.txt"

echo "DEBUG: copy INT2LM executable to rundir"
cp -v ${INT2LM_BINDIR}/${INT2LM_EXNAME} ${rundir}/
int2lm_start_date=${y0}${m0}${d0}${h0}
echo "DEBUG: int2lm_start_date: ${int2lm_start_date}"
inExtFile=$(cd ${rundir} && ls *.nc | head -1)
##inExtFile=$(ls ${tmpRawCafFiles} | head -1)
echo "DEBUG: inExtFile=${inExtFile}"

echo "DEBUG: copy namelist"
cp ${BASE_NAMEDIR}/INPUT ${rundir}/INPUT

echo "DEBUG: modify namelist (sed inserts etc.)"
sed "s,__start_date__,${int2lm_start_date},g" -i ${rundir}/INPUT
sed "s,__init_date__,${int2lm_start_date},g" -i ${rundir}/INPUT
sed "s,__hstop__,${numHours},g" -i ${rundir}/INPUT
sed "s,__lm_ext_dir__,${BASE_GEODIR}/int2lm,g" -i ${rundir}/INPUT
sed "s,__lm_ext_file__,EUR-11_TSMP_FZJ-IBG3_464x452_EXTPAR.nc,g" -i ${rundir}/INPUT
sed "s,__in_ext_dir__,${rundir},g" -i ${rundir}/INPUT
##sed "s,__in_ext_dir__,${tmpRawCafFiles},g" -i ${rundir}/INPUT
sed "s,__in_ext_file__,${inExtFile},g" -i ${rundir}/INPUT
sed "s,__in_cat_dir__,${rundir},g" -i ${rundir}/INPUT
##sed "s,__in_cat_dir__,${tmpRawCafFiles},g" -i ${rundir}/INPUT
sed "s,__lm_cat_dir__,${int2lm_LmCatDir},g" -i ${rundir}/INPUT
sed "s,__nprocx_int2lm__,${PROCX_INT2LM},g" -i ${rundir}/INPUT
sed "s,__nprocy_int2lm__,${PROCY_INT2LM},g" -i ${rundir}/INPUT
sed "s,__nprocio_int2lm__,${PROCIO_INT2LM},g" -i ${rundir}/INPUT

echo "DEBUG: enter INT2LM rundir and start INT2LM"
cd ${rundir}
# just to be sure, clean rundir before starting (e.g. in case of restart)
rm -rf YU*  
srun --threads-per-core=1 ./${INT2LM_EXNAME}
# exit script, if something crashed int2lm
if [[ $? != 0 ]] ; then exit 1 ; fi
# Clean up
rm -rf ${rundir}
##rm -rf ${tmpRawCafFiles}
wait

exit 0
