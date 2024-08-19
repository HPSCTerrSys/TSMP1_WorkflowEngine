#!/bin/bash
#
# USAGE: 
# >> sbatch --export=ALL,startDate=$startDate,NoS=6 \
#           -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
#           --mail-user=$userEmail --account=$computeAcount \
#           start_postpro.sh

# IMPORTANT the following variables HAVE TO be set via the
# sbatch --export command
# 1) ALL (ensure exported variables are passed to each subse. called script)
# 2) startDate (tell the program for which date to start the simulation)
# 3) NoS (tell the programm how many simulaitons to start)

echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- pwd: $(pwd)"
echo "--- Simulation    init-date: ${initDate}"
echo "---              start-date: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "--- HOST:  $(hostname)"

loop_counter=1
while [ $loop_counter -le $NoS ]
do
  cd $BASE_CTRLDIR
  ./start_postpro.sh $startDate
  if [[ $? != 0 ]] ; then exit 1 ; fi
  startDate=$(date -u -d "${startDate} + ${simLength}" "+%Y-%m-%dT%H:%MZ")
  ((loop_counter++))
  wait
done

exit 0
