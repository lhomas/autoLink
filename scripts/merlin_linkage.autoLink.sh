#!/bin/bash

usage()
{
echo "
# Script to run genetic linkage as part of the autoLink analysis pipeline
# 
# USAGE: $0 -o output_prefix -a auxilary_sample_list.txt -w /path/to/workDir -C /path/to/file.cfg
# 
# OPTIONS
# -o REQUIRED. output_prefix - The prefix that will be used to create all of the output files
# -a REQUIRED. /path/to/auxilery_samples_list.txt - Path to text file containing list of samples to be included in the auxilary pedigrees (One sample per line). 
## NOTE: You only need to include individual lowest in the lineage on the pedigree, all parents will be filled in automatically by the script (e.g. if you want to inlcude both a mtoher and a daughter, you only need include the daughter in the sample file).
# -w REQUIRED. /path/to/workDir/ - The directory where all output will created.
# -C REQUIRED. /path/to/file.cfg - I
# -h or --help Prints this message. This message will also appear if you don't use the script properly.
#
# Created: 6th April 2022.
"
}


## Setting Variables ##

while [ "$1" != "" ]; do
	case $1 in
        -o	)           shift
                        prefix=$1
                        ;;
        -a  )           shift
                        auxSamples=$1
                        ;;
        -w  )           shift
                        workDir=$1
                        ;;
        -C  )           shift
                        config=$1
                        ;;
        -h | --help )   usage
                        exit 0
                        ;;
        * )	            usage
                        echo "## ERROR ## Wrong option used"
                        exit 1
    esac
    shift
done


## Checking Varaibles ##

if [ -z "${prefix}" ]; then # If no output location is specified do not continue
	usage
	echo "## ERROR ## You need to specify output prefix for the files being made."
	exit 1
fi

if [ -z "${auxSamples}" ]; then # If list of samples to be included in auxilary pedigrees is not specified do not continue
	usage
	echo "## ERROR ## You need to specify which smaples to include in auxilary pedigrees."
	exit 1
fi

if [ -z "${workDir}" ]; then # If no workDir has been specified, do not continue
    usage
    echo "## ERROR ## You need to tell me where to put all the output files"
    exit 1
fi

if [ ! -d ${workDir} ]; then # Create directory for output pedigree if it doesn't exist
	mkdir -p ${workDir}
fi

if [ ! -e ${config} ]; then # If no config file is specified, do not continue
    usage
    echo "## ERROR ## You need to specify a config file"
    exit 1
fi 
source ${config}
source activate base
conda activate ${merlinEnv}

cd ${workDir}/merlin
cp ${paramTbl} ./param.tbl
seq 1 23 | while read n; do
    bash merlin_${n}_${prefix}_core.in
done

cat ${auxSamples} | while read s; do
    cd ${workDir}/${prefix}_${s}/merlin
    cp ${paramTbl} ./param.tbl
    seq 1 23 | while read n; do
        bash merlin_${n}_${prefix}_${s}.in
    done
done

conda deactivate
