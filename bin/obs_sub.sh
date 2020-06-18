#! /bin/bash

#set -x

usage()
{
echo "obs_sub.sh [-p project] [-d dep] [-a account] [-t] obsnum
  -p project : project, no default
  -d dep     : job number for dependency (afterok)
  -a account : computing account, default pawsey0272
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
    a)
        account=${OPTARG}
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

if [[ -z ${account} ]]
then
    account=pawsey0272
fi

# Supercomputer options
if [[ "${HOST:0:4}" == "zeus" ]]
then
    computer="zeus"
    standardq="workq"
    ncpus=28
    taskline="#SBATCH --ntasks=${ncpus}"
#    standardq="gpuq"
elif [[ "${HOST:0:4}" == "magn" ]]
then
    computer="magnus"
    standardq="workq"
    taskline=""
fi

codedir="/group/mwasci/$USER/MWA-spectral-line-pipeline/"
queue="-p $standardq"
datadir=/astro/mwasci/$USER/$project

# set dependency
if [[ ! -z ${dep} ]]
then
    depend="--dependency=afterok:${dep}"
fi

script="${codedir}queue/sub_${obsnum}.sh"

cat ${codedir}bin/sub.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                     -e "s:DATADIR:${datadir}:g" \
                                     -e "s:HOST:${computer}:g" \
                                     -e "s:TASKLINE:${taskline}:g" \
                                     -e "s:STANDARDQ:${standardq}:g" \
                                     -e "s:ACCOUNT:${account}:g" > ${script}

output="${codedir}queue/logs/sub_${obsnum}.o%A"
error="${codedir}queue/logs/sub_${obsnum}.e%A"

sub="sbatch -M $computer --output=${output} --error=${error} ${depend} ${queue} ${script}"

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
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted ${script} as ${jobid} . Follow progress here:"
echo $output
echo $error

