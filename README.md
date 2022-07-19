# autoLink
A series of scripts to automate iterative linkage analysis using LINKDATAGEN and Merlin. See below for a more detailed explanation of this very niche linkage analysis tool.

# Motivation
This script came about from doing linkage analysis for a trait on an incredibly large pedigree. This pedigree had to be split into 4 "sub-pedigrees" to allow the analysis to be run without going over the pedigree complexity limit (BitSize = 24) of Merlin. A clear interval could be identified in 2 of the 4 sub-pedigrees. However, the other 2 had suggestions of linkage intervals but there were clearly some individuals reducing the strenght of the LOD score in this region, preventing the significance threshold form being achieved.

My previous experience with linkage analysis lead me to beleive that there was likely only a few inddividuals from the pedigree causing the discrepencies in the linkage interval. However, manually checking each of these would be a rediculously time consuming task, thus autoLink was born.

# Explantion
AutoLink is very niche in that it requires a very speficic situation to be useful. That is, it requires a "core" set of individuals from the linkage analysis taht are 100% known to have the phenotype of interested, while all others are suspected to have the phenotype, but are not 100% confirmed.

Along with the list of "core" individuals, a list of auxiliary individuals is needed. For each individual in this "auxiliary" list, an interation of the linkage analysis will be completed with a given individual being added to the core list, a pedigree being constructed, and linkage analysis ebing run with LINKDATAGEN and Merlin.

The final think that is required for this series of scripts is a "complete" pedigree file that contains a every individual from the "core" and "auxiliary" lists. This pedigree should be in linkage format and have an additional column on the end that is equivalent to the map file used by LINKDATAGEN.

