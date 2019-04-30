#!/bin/bash  -x

############################################################################################################################################################
#																			   #
# 								Author: Mehdi Zare                                                                         #
# 			Update-1; I make it faster by dividing HIS3000 to 10 parts since it makes it faster for head | tail command																			   #
#		Purpose : It divides the History file which contains 14,500 (725 ps sampling) water conformations to 3 HISTORY				   #
# 	          files each contains 3000 conformations(150ps) and it skips 2500(125ps) conformations in between.					   #
#		   it then use 3000 HISTORY and get 1000 conformation, each 150fs apart(skip 2 conformatinos in between).				   #
#		     All your HISTORY files are in Bin-01 to Bin-10 directories. In addition, this script creates a CONFIG file in each Bin		   #
#		     directory which is the first conformation of each HISTORY file in that directory. You need to have					   #
#		        head*.CONFIG file in the directory that your original HISTORY (14,500 conformations) exists.				  	   #
#																			   #
############################################################################################################################################################

NumConf=`head -2 HISTORY | tail -1 | awk '{print $4}'`                   # Total number of conformations in HISTORY
lines=`head -2 HISTORY | tail -1 | awk '{print $5}'`    		 # Total number of HISTORY's lines
OneConf=$((($lines-2)/$NumConf))                                         # Number of line in one conformation
conflines=$(($OneConf*3000))                 				 # Total number of each 3000-HISTORY lines without header(2 lines)
headlines=$((($OneConf*1000)+2))                 		         # Total number of each 1000-HISTORY lines with header(2 lines)


head -2 HISTORY > head.HISTORY              				 # Get header to modify it for 1000-HISTORY files
sed -i "s/14500/1000/" head.HISTORY          				 # Modifying number of conformations in header
sed -i "s/$lines/$headlines/" head.HISTORY   				 # Modifying number of lines in header

ii=0                                         				 # This 'ii' index controls the skip of 2500 conformation
conf2500=$(($OneConf*2500))                                              # Number of lines in 2500 conformations
for kk in {1..3}                                          	         # For loop for creating 3 HISTORY files
   do  his3000=$((($conflines*$kk)+2+($conf2500*$ii)))                    # Get 1000 conformation subsequently from 10,000-HISTORY with skip of 500 conf. in between
   head -n$his3000 HISTORY | tail -n$conflines > HIS3000
   # Create 1000 HISTIRY out of 3000 HISTORY(150ps) with 150 fs apart
      conf300=$(($OneConf*300))
      for m in {1..10}; do his300=$(($conf300*$m)); head -n$his300 HIS3000 | tail -n$conf300 > histemp.$m; done
      for m in {1..10};
         do j=1;
            for q in {1..100}; do k=$(($OneConf*$j)); head -n$k histemp.$m | tail -n$OneConf >> HIS1000; j=$(($j+3)); done 
      done

#   j=1; for i in {1..1000}; do k=$((($OneConf*$j)));head -n$k HIS3000 | tail -n$OneConf >> HIS1000; j=$(($j+3)); done

   cat head.HISTORY HIS1000 > HISTORY-$kk                       	         # Adding header
   rm HIS3000 HIS1000 histemp.*
   ii=$(($ii+1))
done

rm head.HISTORY                                                 	 # Clean up

ali=1                                                             	 # 'ali' is index for HISTORY files and 'i' is index for Bin directories
oneconf=$OneConf                                             	         # Total number of lines in one conformation
oneconfplushead=$(($oneconf+2))                                 	 # Above plus header
oneconfCONFIG=$(($oneconf-4))                                  		 # Total number of lines in one conformation in CONFIG (the 4 lines of HISTORY is the differenc)
for i in {01..03}                                             		 # For loop for 10 Bins
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

