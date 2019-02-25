#!/bin/bash -x

############################################################################################################################################################
#                                                                                                                                                          #
#                                                               Author: Mehdi Zare                                                                         #
#                                                                                                                                                          #
#               Purpose : It get the number of conformation from user and create Height distribution 							   #
#                         file in DISTRIBUTION file. It needs head.CONFIG file that is the header of CONFIG file 					   #
#			   in your current directory as well as HISTORY file in the above directory.							   #
#		Note    : This scripts assume that the number of cluster atoms are 51. if you have different cluster size, 				   #
#			  you need to modify this code				 						                           #
#                                                                                                                                                          #
############################################################################################################################################################

#echo " How many Conformation do you want to use to make height distribution?"
#read Mehdi
Mehdi=14500

NumConf=`head -2 ../HISTORY | tail -1 | awk '{print $4}'`                   # Total number of conformations in HISTORY
lines=`head -2 ../HISTORY | tail -1 | awk '{print $5}'`                     # Total number of HISTORY's lines
OneConf=$((($lines-2)/$NumConf))                                         # Number of line in one conformation without header
OneConfhead=$(($OneConf+2))						 # Number of line in one conformation with header
conflines=$(($OneConf*$Mehdi))                                           # Total lines of desired conformations without header(2 lines)
headlines=$(($conflines+2))                                              # Total lines of desired conformatinos with header(2 lines)

head -n$OneConfhead ../HISTORY > histone				 # One conformatino to analyse it to get number of metals, water, and adsorbates
metal=`grep "Pt " histone  | wc -l`                                      # Total number of metal atoms in one conformation
metalQM=51  								 # Number of metal cluster atoms (QM metal atoms)
metalMM=$(($metal-$metalQM))                                             # Number of MM metal atoms
carbon=`grep "C " histone | wc -l`  
hydrogen=`grep "H " histone | wc -l`
oxygen=`grep "O " histone | wc -l`
adsorb=$(($carbon+$hydrogen+$oxygen))                                    # Number of adsorbate atoms in one conformation 
cluster=$(($metalQM+$adsorb))                                            # Number of cluster atoms in one conformation
water=`grep -e 'Hw ' -e 'Ow '  histone  | wc -l`                         # Number of water atoms in one conformatinos

oldheadCONFIG=$(($water+$metal+$adsorb))                                 # Number of atoms in header of your head.CONFIG
newheadCONFIG=$((($water*$Mehdi)+$metal+$adsorb))                        # Number of atoms in xyz file based on desired conformations 
sed  "s/$oldheadCONFIG/$newheadCONFIG/g" head*CONFIG  > newhead

head -n$headlines ../HISTORY > HISTORY
metalname=`head -7 HISTORY | tail -1 | awk '{print $1}'`                 # Get metal I.D
metMM=$(($metalMM*2))							 # Number of lines in one conformation realted to MM metal without header 
metMMhead=$(($metMM+4+2))                                                # Number of lines in one conformation realted to MM metal with header (2+4)
head -n$metMMhead HISTORY | tail -n$metMM > head.QM                      # Get the number of lines assigned to metal MM in one conformation
clus=$(($cluster*2))							 # Number of lines in one conformation realted to QM cluster (metalQM and adsorbate)
tail -n$clus  HISTORY > tail.QM

head -n$headlines HISTORY | tail -n$conflines > New.HISTORY              # Remove header (2 lines)
mv New.HISTORY HISTORY

#  removing all Pt, C, O, and H, atoms plus the dimension and information of trajectory to have just water conformations
sed -i -e "/timestep/,+3 d" -i -e "/$metalname/,+1 d" -i -e  "/^C /,+1 d" -i -e  "/^O /,+1 d" -i -e  "/^H /,+1 d"   HISTORY  
cat head.QM HISTORY tail.QM > HISTORY.mix

cp newhead  HISTORY.finale
awk 'NR==1 {A=$2} NR%2 {$2=A++} 1' OFS="\t"   HISTORY.mix >> HISTORY.finale

dlpoly-relocate-config-coordinates -f HISTORY.finale > CONFIG.last
dlpoly-convert-config-to-geometry-xyz -f CONFIG.last -k 0 -p > image.last

sed '1,2d' image.last > noheader
sed -i -e  "/^$metalname / d" -i -e  "/^C / d" -i -e  "/^O / d" -i -e  "/^H / d" -i -e "/^Hw / d" noheader
awk '{print $4}' noheader > OxygenZcoord

rm HISTORY* tail.QM head.QM histone noheader newhead

heightDistribution
