#! /bin/bash

usage()
{
echo "obs_specimage.sh [-d dep] [-p project] [-a account] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -p project : project, (must be specified, no default)
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process" 1>&2;
exit 1;
}

#initial variables
dep=
tst=
# parse args and set options
while getopts ':td:p:' OPTION
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

# if obsid is empty then just print help
if [[ -z ${obsnum} ]] || [[ -z $project ]] 
then
    usage
fi

if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi

if [[ ! -z ${GXSLACCOUNT} ]]
then
    account="--account=${GXSLACCOUNT}"
fi

queue="-p ${GXSTANDARDQ}"
base="${GXSLSCRATCH}/${project}"

# start the real program

script="${GXSLSCRIPT}/specimage_${obsnum}.sh"
cat ${GXSLBASE}/bin/specimage.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                         -e "s:BASEDIR:${base}:g" > ${script}

output="${GXSLLOG}/specimage_${obsnum}.o%A"
error="${GXSLLOG}/specimage_${obsnum}.e%A"

chmod 755 "${script}"

# sbatch submissions need to start with a shebang
echo '#!/bin/bash' > ${script}.sbatch
echo "singularity run ${GXCONTAINER} ${script}" >> ${script}.sbatch

sub="sbatch --export=ALL  --time=12:00:00 --mem=${GXABSMEMORY}G -M ${GXCOMPUTER} --output=${output} --error=${error}"
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

echo "Submitted ${script} as ${jobid}. Follow progress here:"
echo "${output}"
echo "${error}"
