#!/bin/bash  +x

# This script is written by Mehdi Zare and it divides the History file which contains 14,500 (725 ps sampling) water conformation
# to 10 History file each contains 1000 conformations and skip 500 conformation (25 ps) in between. All your HISTORY files are in Bin-01 to Bin-10 directory
# In addition, this scripts creates a CONFIG file in each Bin directory which is the first conformation of each 
# HISTORY file in that directory. You need to have head*.CONFIG file in the directory that your origiinal HISTORY
# 10,000 exists.

NumConf=`head -2 HISTORY | tail -1 | awk '{print $4}'`                   # Total number of conformations in HISTORY
lines=`head -2 HISTORY | tail -1 | awk '{print $5}'`    		 # Total number of HISTORY's lines
OneConf=$((($lines-2)/$NumConf))                                         # Number of line in one conformation
conflines=$(($OneConf*1000))                 				 # Total number of each 1000-HISTORY lines without header(2 lines)
headlines=$(($conflines+2))                 				 # Total number of each 1000-HISTORY lines with header(2 lines)
head -2 HISTORY > head.HISTORY              				 # Get header to modify it for 1000-HISTORY files
sed -i "s/14500/1000/" head.HISTORY          				 # Modifying number of conformations in header
sed -i "s/$lines/$headlines/" head.HISTORY   				 # Modifying number of lines in header

ii=0                                         				 # This 'ii' index controls the skip of 500 conformation
conf500=$(($OneConf*500))                                                # Number of lines in 500 conformations
for k in {1..10}                                          	         # For loop for creating 10 HISTORY files
   do  his1000=$((($conflines*$k)+2+($conf500*$ii)))           		 # Get 1000 conformation subsequently from 10,000-HISTORY with skip of 500 conf. in between
   head -n$his1000 HISTORY | tail -n$conflines > Bin-$k         
   cat head.HISTORY Bin-$k > HISTORY-$k                       	         # Adding header
   ii=$(($ii+1))
done

rm head.HISTORY                                                 	 # Clean up
rm Bin-*

ali=1                                                             	 # 'ali' is index for HISTORY files and 'i' is index for Bin directories
oneconf=$OneConf                                             	         # Total number of lines in one conformation
oneconfplushead=$(($oneconf+2))                                 	 # Above plus header
oneconfCONFIG=$(($oneconf-4))                                  		 # Total number of lines in one conformation in CONFIG (the 4 lines of HISTORY is the differenc)
for i in {01..10}                                             		 # For loop for 10 Bins
   do mkdir Bin-$i                                                
   mv HISTORY-$ali Bin-$i/                                     
   cd Bin-$i/
   mv HISTORY-$ali HISTORY
# create HISTORY of the first conformation
   head -2 HISTORY > header
   sed -i 's/1000/1/' header
   sed -i "s/$headlines/$oneconfplushead/" header
   head -n$oneconfplushead HISTORY | tail -n$oneconf > temp 
   cat header temp > HISTORY.first
   rm header temp;
# create CONFIG of the first conformation
   head -n$oneconfplushead HISTORY | tail -n$oneconfCONFIG > First
   cp ../head*.CONFIG .
   cat head*.CONFIG First > CONFIG
   dlpoly-relocate-config-coordinates -f CONFIG > CONFIG.first
   rm First  head*.CONFIG CONFIG
   cd ../
   ali=$(($ali+1))
done

