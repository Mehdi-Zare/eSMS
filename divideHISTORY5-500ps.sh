#!/bin/bash  +x

# This script is written by Mehdi Zare and it divides the History file which contains 10,000 (500 ps sampling) water conformation
# to 5 History file each contains 2000 conformations.
# All your HISTORY files are named HISTORY.1 to HISTORY.5
# in addition, this code creates the HISTORY and CONFIG files of the first conformation for RefimgSdir
# it needs HISTORY file and head*.CONFIG file in your working directory

NumConf=`head -2 HISTORY | tail -1 | awk '{print $4}'`                   # Total number of conformations in HISTORY
lines=`head -2 HISTORY | tail -1 | awk '{print $5}'`    		 # Total number of HISTORY's lines
OneConf=$((($lines-2)/$NumConf))                                         # Number of line in one conformation
conflines=$(($OneConf*2000))                 				 # Total number of each 2000-HISTORY lines without header(2 lines)
headlines=$(($conflines+2))                 				 # Total number of each 2000-HISTORY lines with header(2 lines)
head -2 HISTORY > head.HISTORY              				 # Get header to modify it for 1000-HISTORY files
sed -i "s/10000/2000/" head.HISTORY          				 # Modifying number of conformations in header
sed -i "s/$lines/$headlines/" head.HISTORY   				 # Modifying number of lines in header

for k in {1..5}                                          	         # For loop for creating 5 HISTORY files
   do  his2000=$((($conflines*$k)+2))           	  		 # Get 2000 conformation subsequently from 14,500-HISTORY using the first 10,000 confs.
   head -n$his2000 HISTORY | tail -n$conflines > Bin-$k         
   cat head.HISTORY Bin-$k > HISTORY.$k                       	         # Adding header
done

rm head.HISTORY                                                 	 # Clean up
rm Bin-*

oneconf=$OneConf                                                         # Total number of lines in one conformation
oneconfplushead=$(($oneconf+2))                                          # Above plus header
oneconfCONFIG=$(($oneconf-4))                                            # Total number of lines in one conformation in CONFIG (the 4 lines of HISTORY is the differenc)

# create HISTORY of the first conformation
   head -2 HISTORY.1 > header
   sed -i 's/2000/1/' header
   sed -i "s/$headlines/$oneconfplushead/" header
   head -n$oneconfplushead HISTORY.1 | tail -n$oneconf > temp 
   cat header temp > HISTORY.first
   rm header temp;
# create CONFIG of the first conformation
   head -n$oneconfplushead HISTORY.1 | tail -n$oneconfCONFIG > First
   cat head*.CONFIG First > CONFIG.1
   dlpoly-relocate-config-coordinates -f CONFIG.1 > CONFIG.first
   rm First  CONFIG.1
# store HISTORYs and CONFIG.first and HISTRY.first in directory called historys
mkdir historys
mv HISTORY.* CONFIG.first historys/
