#! /bin/bash

#set -x

usage()
{
echo "obs_sub.sh [-p project] [-d dep] [-a account] [-t] obsnum
  -p project : project, no default
  -d dep     : job number for dependency (afterok)
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

dep=
tst=

# parse args and set options
while getopts ':td:a:p:' OPTION
do
    case "$OPTION" in
	d)
	    dep=${OPTARG}
	    ;;
	p)
	    project=${OPTARG}
	    ;;
	t)
	    tst=1
	    ;;
	? | : | h)
	    usage
	    ;;
  esac
done
# set the obsid to be the first non option
shift  "$(($OPTIND -1))"
obsnum=$1

# if obsid or project are empty then just pring help
if [[ -z ${obsnum} || -z ${project} ]]
then
    usage
fi

if [[ ! -z ${GXSLACCOUNT} ]]
then
    account="--account=${GXSLACCOUNT}"
fi

# set dependency
if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi

queue="-p ${GXSTANDARDQ}"
datadir="${GXSLSCRATCH}/${project}"

script="${GXSLSCRIPT}/sub_${obsnum}.sh"

cat ${GXSLBASE}/bin/sub.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                   -e "s:DATADIR:${datadir}:g" > ${script}

output="${GXSLLOG}/sub_${obsnum}.o%A"
error="${GXSLLOG}/sub_${obsnum}.e%A"

chmod 775 "${script}"

echo '#!/bin/bash' > ${script}.sbatch
echo "singularity run ${GXCONTAINER} ${script}" >> ${script}.sbatch

sub="sbatch --export=ALL  --time=2:00:00 --mem=${GXABSMEMORY}G -M ${GXCOMPUTER} --output=${output} --error=${error}"
sub="${sub} ${GXNCPULINE} ${account} ${GXSLTASKLINE} ${depend} ${queue} ${script}.sbatch"
if [[ ! -z ${tst} ]]
then
    echo "script is ${script}"
    echo "submit via:"
    echo "${sub}"
    exit 0
fi

# submit job
jobid=($(${sub}))
jobid=${jobid[3]}
taskid=1

# rename the err/output files as we now know the jobid
error=$(echo ${error} | sed "s/%A/${jobid}/")
output=$(echo ${output} | sed "s/%A/${jobid}/")

echo "Submitted ${script} as ${jobid} . Follow progress here:"
echo "${output}"
echo "${error}"

