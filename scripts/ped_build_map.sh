#!/bin/bash

usage()
{
echo "
# A script to create a pedigree only subset of individuals from a larger pedigree
# NOTE: This script will continue until it reaches the founders at the top of the pedigree.
## This means you may need to do some minor edits to the output pedigree to exclude inviduals that are superfluous to subsequent analyses.
## A fix to this issue may be included at some point, but not right now. 
# 
# USAGE: $0 -p complete.ped -o output.ped -s samples.txt
# 
# OPTIONS
# -p REQUIRED. /path/to/complete.ped - This pedigree needs to a valid linkage format pedigree with all individuals from family.
# -o REQUIRED. /path/to/output.ped
# -l CONDITIONAL. /path/to/list_of_samples.txt - Path to text file containing list of samples to be included in sub-pedigree (One sample per line). (Do not use if using -S)
# -S CONDITiONAL. sample - Single sample to be added to pedigree. (Do not use if using -s)
# -c OPTIONAL. /path/to/core.ped - Path to core pedigree to which samples are to be added. 
## NOTE: You only need to include individual lowest in the lineage on the pedigree, all parents will be filled in automaticall by the script (e.g. if you want to inlcude both a mtoher and a daughter, you only need include the daughter in the sample file).
# -h or --help Prints this message. This message will also appear if you don't use the script properly.
#
# Created: 5th April 2022.
"
}


## Setting Variables ##

while [ "$1" != "" ]; do
	case $1 in
        -p	)           shift
                        compPed=$1
                        ;;
        -o	)           shift
                        outPed=$1
                        ;;
        -l	)           shift
                        list=$1
                        ;;
		-s	)			shift
						sample=$1
						;;
		-c	)			shift
						corePed=$1
						;;
        -h | --help )   usage
                        exit 0
                        ;;
        * )	            usage
                        exit 1
    esac
    shift
done


## Checking Varaibles ##

if [ -z "${compPed}" ]; then # If no pedigree is specified do not continue
	usage
	echo "## ERROR ## You need to provide a pedigree to subset."
	exit 1
fi

if [ -z "${outPed}" ]; then # If no output location is specified do not continue
	usage
	echo "## ERROR ## You need to specify output file location."
	exit 1
fi

if [ ! -d $(dirname ${outPed}) ]; then # create directory for output pedigree if it doesn't exist
	mkdir -p $(dirname ${outPed})
fi

if [ -z "${list}" ] && [ -z "${sample}" ] ; then # If list of samples or single sample to be included in sub-pedigree is not specified do not continue
	usage
	echo "## ERROR ## You need to specify which smaples to include in sub-pedigree using either -s or -S."
	exit 1
elif [[ -n "${list}" ]] && [[ -n "${sample}" ]] ; then # If both of -s and -S have been used, do not continue
	usage
	echo "## ERRROR ## You can't use both -s and -S, please use only one of these options"
	exit 1
fi


## Creating Recursive Function to Build Sub-Pedigree ##

build_ped()
{
	if [[ ! $(awk '{if ($8 !~ "MF" && $8 !~ "FM") print $0}' ${outPed} | wc -l) -eq 0 ]]; then	
		cat ${outPed} | while read s; do 
			RENTS=$(echo $s | awk '{print $8}')
			if [[ !  "${RENTS}" =~ "FM" && ! "${RENTS}" =~ "MF" ]]; then
				SAMP=$(echo $s | awk '{print $2}')
				PAT=$(echo $s | awk '{print $3}')
				MAT=$(echo $s | awk '{print $4}')
				if [ ${PAT} == 0 ] || [ ${MAT} == 0 ]; then
					if [ ${PAT} == 0 ] && [ ${MAT} == 0 ]; then
						awk -v samp=${SAMP} \
						'{if ($2 ~ samp) {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tFM"} else {print $0}}' \
						${outPed} >> tmp.ped && mv tmp.ped ${outPed}
						RENTS=$(awk -v samp=${SAMP} ' $2 == samp {print $8}')
					elif [[ ${PAT} == 0 && ${MAT} != "0" ]] || [[ ${PAT} != 0 && ${MAT} == "0" ]]; then
						echo "##ERROR## ${SAMP} does not have both parents in pedigree"
						exit 1
					fi
				fi

				if [ ${PAT} != 0 ] && [ ${MAT} != 0 ]; then
				# Extracting Father from pedigree
					if [[ ! ${RENTS} =~ [F] ]]; then
						if [[ -n "$(awk -v PAT=${PAT} '$2 == PAT' ${outPed})" ]]; then
							if [[ ${RENTS} == "0" ]]; then
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tF"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							else
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $0"F"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							fi
						elif [[ -z "$(awk -v PAT=${PAT} '$2 == PAT' ${compPed})" ]]; then
							echo "##ERROR## ${SAMP} does not have Father in pedigree"
							exit 1;
						else
							if [[ ${RENTS} == "0" ]]; then
								awk -v PAT=${PAT} '$2 == PAT {print $0"\t0"}' ${compPed} >> ${outPed}
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tF"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							else
								awk -v PAT=${PAT} '{if ($2 ~ PAT) print $0"\t0"}' ${compPed} >> ${outPed}
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $0"F"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							fi
						fi
					fi

				# Extracting Mother from pedigree
					if [[ ! ${RENTS} =~ [M] ]]; then
						if [[ -n "$(awk -v MAT=${MAT} '$2 == MAT' ${outPed})" ]]; then
							if [[ ${RENTS} == "0" ]]; then
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tM"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							else
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $0"M"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							fi
						elif 	[[ -z "$(awk -v MAT=${MAT} '{if ($2 == MAT) print $0}' ${compPed})" ]]; then
							echo "##ERROR## ${SAMP} does not have Mother in pedigree"
							exit 1;
						else
							if [[ ${RENTS} == "0" ]]; then
								awk -v MAT=${MAT} '{if ($2 == MAT) print $0"\t0"}' ${compPed} >> ${outPed}
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\tM"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							else
								awk -v MAT=${MAT} '{if ($2 == MAT) print $0"\t0"}' ${compPed} >> ${outPed}
								awk -v samp=${SAMP} \
								'{if ($2 == samp) {print $0"M"} else {print $0}}' \
								${outPed} >> tmp.ped && mv tmp.ped ${outPed}
								RENTS=$(awk -v samp=${SAMP} '$2 == samp {print $8}' ${outPed})
							fi
						fi
					fi
				fi
			fi
		done
		build_ped
	else
		awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}' ${outPed} >> tmp.ped && mv tmp.ped ${outPed}
	fi
}


## Put Pedigree Rows from Sample List into Sub-Pedigree ##
if [[ ${list} != ${blank} ]]; then
	cat ${list} | while read s; do 
		awk -v samp=$s '{if ($2==samp) print $0"\t0"}' ${compPed}; 
	done > ${outPed}
elif [ -n ${sample} ]; then
	awk -v samp=${sample} '{if ($2==samp) print $0"\t0"}' ${compPed} > ${outPed}
fi


## Adding Core Pedigree to outPed (if -c has been used) ##

if [ ! -z ${corePed} ]; then # if -c option has been used add the core pedigree (with MF added to each line) to the outPed
	awk '{ print $0"\tMF"}' ${corePed} >> $outPed
fi


## Run build_ped Funtion to Fill in Sub-Pedigree ##

build_ped

## Housekeeping ##

unset list
unset sample