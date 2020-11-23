#! /bin/bash -l

# The MWA Spectral Processing pipeline borrows heavily from the GLEAM-X pipeline, but a set of stages
# are currently separated and stored in a separate repository. This template profile is specific to 
# this separate repository. 
echo "loading gleam-x pectral line profile"

# Any system module file should be loaded here. Aside from singularity and slurm there are
# no additional modules that are expected to be needed
module load singularity

if [[ -z ${GXBASE} ]]
then
    echo "Ensure the GLEAM-X profile has been loaded correctly. GXBASE was not found. "
    return 1
fi

export GXSLVERSION='1.0'        # Version number of the pipeline. This should not be changed. Currently it is defined here but not used.  
export GXSLACCOUNT=             # The SLURM account jobs will be run under. e.g. 'pawsey0272'. Empty will not pass through a 
                                # corresponding --account=${GXACCOUNT} to the slurm submission. Only relevant if SLURM is tracking time usage 
export GXSLBASE="/not/actual/path" # Path to base of GLEAM-X spectral line pipeline where the repository was 'git clone' into including the name of the repository foldername, e.g. "/astro/mwasci/tgalvin/GLEAM-X-pipeline" 
export GXSLSCRATCH="/astro/${GXUSER}"      # Path to your scratch space used for processing on the HPC environment, e.g. /scratch
                                   # Within pawsey this is /astro/mwas/${GXUSER}

# SLURM job submission details 
export GXSLTASKLINE=                                # Reserved space for additional slurm sbatch options, if needed. This is passed to all SLURM sbatch calls. 
export GXSLLOG="${GXSLBASE}/log_${GXCLUSTER}"       # Path to output task logs, e.g. ${GXBASE}/queue/log_${GXCLUSTER}. It is recommended that this is cluster specific. 
export GXSLSCRIPT="${GXSLBASE}/script_${GXCLUSTER}" # Path to place generated template scripts. e.g. "${GXBASE}/script_${GXCLUSTER}". It is recommended that this is cluster specific.

# Singularity bind paths
# This describes a set of paths that need to be available within the container for all processing tasks. Depending on the system
# and pipeline configuration it is best to have these explicitly set across all tasks. For each 'singularity run' command this
# SINGULARITY_BINDPATHS will be used to mount against. 
export SINGULARITY_BINDPATH="${GXSLLOG},${GXSLSCRIPT},${GXSLBASE},${GXSLSCRATCH},${SINGULARITY_BINDPATH}"

export PATH="${PATH}:${GXSLBASE}/bin" # Adds the obs_* script to the searchable path. 

# Check that required variables have a value. This perfoms a simple 'is empty' check
for var in GXSLLOG GXSLSCRIPT
do
    if [[ -z ${!var} ]]
    then
        echo "${var} is currently not configured, please ensure it was a valid value"
        return 1
    fi
done

# Check that the following values that point to a path actually exist. These are ones that (reasonably) should not
# automatically be created
for var in GXSLBASE GXSLSCRATCH
do
    if [[ ! -d ${!var} ]]
    then
        echo "The ${var} configurable has the path ${!var}, which appears to not exist. Please ensure it is a valid path."
        return 1
    fi
done

# Creates directories as needed below for the mandatory paths if they do not exist
if [[ ! -d "${GXSLLOG}" ]]
then
    mkdir -p "${GXSLLOG}"
fi

if [[ ! -d "${GXSLSCRIPT}" ]]
then
    mkdir -p "${GXSLSCRIPT}"
fi
