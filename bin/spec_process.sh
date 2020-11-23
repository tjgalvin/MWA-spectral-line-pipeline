#! /bin/bash

#! /bin/bash

usage()
{
echo "spec_process.sh [-p project] [-a account] obsnum
  -p project : project, (must be specified, no default)
  obsnum     : the obsid to spec_process" 1>&2;
exit 1;
}

scratch="/astro"
group="/group"

# parse args and set options
while getopts ':p:' OPTION
do
    case "$OPTION" in
    p)
        project=${OPTARG}
        ;;
    ? | : | h)
        usage
        ;;
  esac
done
# set the obsid to be the first non option
shift  "$(($OPTIND -1))"
obsnum=$1

if [[ -z ${obsnum} ]] || [[ -z $project ]]
then
    usage
fi

if [[ ! -z ${GXSLACCOUNT} ]]
then
    account="--account=${GXSLACCOUNT}"
fi


queue="-p ${GXSTANDARDQ}"
base="${GXSLSCRATCH}/${project}"

script="${GXSLSCRIPT}/spec_${obsnum}.sh"
cat ${GXSLBASE}/bin/chain.tmpl | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:PROJECT:${project}:g" \
                                  > ${script}

chmod +x ${script}
${script}
