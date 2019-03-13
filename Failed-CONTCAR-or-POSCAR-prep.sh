#!/bin/bash 

##################################################################################################################################
#                               Author : Mehdi Zare on 3/4/2019                                                                  #
#                               Purpose: To prepare CONTCAR file with metal atoms in order                                       #
#				 You need CONTCAR file format here
#################################################################################################################################

###  we have three parts here,
###  part1 : organizing atom with Z coord
###  part2 : orgainizing Z layers from part1 and organiz them based on Y coordinate
###  part3 : use organized atom of part 2 and arrange them with X coordinate

echo  $'\n' This code needs a CONTCAR format file, if you wish to use this code for your POSCAR, please rename it to CONTCAR $'\n'

# Check if CONTCAR exist
if [ ! -f "CONTCAR" ]; then echo $'\n' I have found CONTCAR file, please provide CONTCAR file  $'\n'; exit 1; fi

# Keep original CONTCAR
cp CONTCAR CONTCAR-original

sed  -i '/^[[:space:]]*$/,$d' CONTCAR

metalID=`head -6 CONTCAR | tail -1 | awk '{print $1}'`; metalnum=`head -7 CONTCAR | tail -1 | awk '{print $1}'`;
ads1ID=`head -6 CONTCAR | tail -1 | awk '{print $2}'` ; ads1num=`head -7 CONTCAR | tail -1 | awk '{print $2}'`;
ads2ID=`head -6 CONTCAR | tail -1 | awk '{print $3}'` ; ads2num=`head -7 CONTCAR | tail -1 | awk '{print $3}'`;
ads3ID=`head -6 CONTCAR | tail -1 | awk '{print $4}'` ; ads3num=`head -7 CONTCAR | tail -1 | awk '{print $4}'`;
#### FALG ####  echo $'\n' $metalID is $metalnum and $ads1ID is $ads1num and $ads2ID is $ads2num and and $ads3ID is $ads3num $'\n'

metallayer=$(($metalnum/4))
Adsorbnum=$(($ads1num+$ads2num+ads3num))

# Get metal atoms and put them in file named Metals
last=$((10+$metalnum-1)); head -n$last CONTCAR | tail -n$metalnum > Metals

# Get adsorbate atoms and put them in file named Adsorbate
first=$((10+$metalnum)); last=$(($first+$Adsorbnum-1)); head -n$last CONTCAR | tail -n$Adsorbnum > Adsorbate

# Get the first 9 lines of CONTCAR and put them in file named header
head -9 CONTCAR > header

# Work with metal atoms to separate layer
bot=`head -1 Metals | awk '{print $3}'`;
if [ $(echo "$bot < 0" | bc) -eq 1  ]; then bot=`awk "BEGIN { print $bot + 1.0}"`; fi;			 # for negative coordinate

top=`tail -1 Metals | awk '{print $3}'`;
if [ $(echo "$top < 0" | bc) -eq 1  ]; then top=`awk "BEGIN { print $top + 1.0}"`; fi;                   # for negative coordinate

diff=`awk "BEGIN { print $top - $bot}"`;
interlayer=`awk "BEGIN { print $diff / 3 }"`; limit=`awk "BEGIN { print $interlayer / 2  }"`
#### FALG #### echo $'\n' the heigth difference of your bottom and top layer is $diff $'\n' and the avarage distance between layers is about $interlayer $'\n'
# set limits for differnet layers
limit1=`awk "BEGIN { print $bot + (0*$interlayer) + $limit }"`; limit2=`awk "BEGIN { print $bot + (1*$interlayer) + $limit  }"`;
limit3=`awk "BEGIN { print $bot + (2*$interlayer) + $limit  }"`
#### FALG #### echo $'\n' limits are $limit1 ,  $limit2 ,  $limit3 $'\n'

# Arrange based on Z coordinate
line=1
while [ "$line" -le "$metalnum" ]; do 
    Zcoord=`head -n$line Metals | tail -1 | awk '{print $3}'`; #### FALG #### echo Zcoord is $Zcoord
    if [ $(echo "$Zcoord < 0" | bc) -eq 1  ]; then Zcoord=`awk "BEGIN { print $Zcoord + 1.0}"`; fi; # for negative coordinate
    if     [ $(echo "$Zcoord > $limit3" | bc) -eq 1  ]; then  head -n$line Metals | tail -1 >> layer4
    elif   [ $(echo "$Zcoord > $limit2 && $Zcoord < $limit3" | bc) -eq 1  ]; then  head -n$line Metals | tail -1 >> layer3
    elif   [ $(echo "$Zcoord > $limit1 && $Zcoord < $limit2" | bc) -eq 1  ]; then  head -n$line Metals | tail -1 >> layer2
    elif   [ $(echo "$Zcoord < $limit1" | bc) -eq 1  ]; then  head -n$line Metals | tail -1 >> layer1
    fi
line=$(($line+1))
done

# find the Xmax and Xmin and Ymax and Ymin in each layer
for layer in layer1 layer2 layer3 layer4; do
	line=1
         Ymax=0; Ymin=1;
	negflag=0    # to check if we have a nagative Y value
	flagtop=0    # for the case that Ydiff > 0.95
	while [ "$line" -le "$metallayer"  ]; do
		Ycoord=`head -n$line $layer | tail -1 | awk '{print $2}'`; #### FALG #### echo Ycoord is $Ycoord
		#if [ $(echo "$Ycoord < 0" | bc) -eq 1  ]; then Ycoord=`awk "BEGIN { print $Ycoord + 1.0}"`; fi; #### FALG #### echo Ycoord is $Ycoord # for negative coordinate
		if [ $(echo "$Ycoord < 0" | bc) -eq 1  ]; then negflag=1; fi;  # this atom belongs to the first Y layer
                if [ $(echo "$Ycoord > $Ymax" | bc) -eq 1 ]; then Ymax=$Ycoord; fi;
		if [ $(echo "$Ycoord < $Ymin" | bc) -eq 1 ]; then Ymin=$Ycoord; fi;
	line=$(($line+1))
	done
	
	
        echo $'\n'  Ymax for $layer is $Ymax and Ymin is $Ymin $'\n'
    # for negative atom coordinates which belong to the first layer
    if [ "$negflag" -eq 1  ]; then echo I found a nagative Y value in $layer; 
		Ymin=${Ymin#-}  # make absolot value of the negative number
		Ydiff=`awk "BEGIN { print $Ymax - $Ymin}"`;
	    	echo $'\n' Now Ymax for $layer is $Ymax and Ymin is $Ymin $'\n'
		if [ $(echo "$Ydiff > 0.95" | bc) -eq 1 ]; then flagtop=1; echo This negative value  corresponds to the forht Y layer
		# FIND THE NEW Ymin
			line=1
	        	while [ "$line" -le "$metallayer"  ]; do
                		Ycoord=`head -n$line $layer | tail -1 | awk '{print $2}'`;
                		crierion=`awk "BEGIN { print $Ymax - $Ycoord}"`;  # we do not need to take absolute of Ycoord, even for Ycoord < 0 the criterion is > 1.0
               			if [ $(echo "$crierion < 0.95" | bc) -eq 1 ]; then Ymin=$Ycoord;
                		else
                        		echo this $Ycoord belongs to top layer, its real coordinate is coordinte to 1.0 + $Ycoord $'\n';
					YcoordNew=`echo "1.0+$Ycoord" | bc` ;
                        		sed -i "s/$Ycoord/ 0$YcoordNew/g" $layer ;
                		# if the difference is above 0.95, it means that this atom belongs to top layer, I cahange its coordinate to 1+Ycoord
               			 fi
       			line=$(($line+1))
        		done
			Ydiff=`awk "BEGIN { print $Ymax - $Ymin}"` # change Ydiff, now Ymin is a positive number from the first real layer
        		echo $'\n' Now Ymax for $layer is $Ymax and Ymin is $Ymin $'\n'
					
		elif [ $(echo "$Ydiff < 0.95" | bc) -eq 1 ]; then echo This negative value  corresponds to the first Y layer
		# keep the value of Ydiff to what it is
		fi
    elif [ "$negflag" -eq 0  ]; then Ydiff=`awk "BEGIN { print $Ymax - $Ymin}"`; # the minimum value is a positive number, we don't need absolute of Ymin
		if [ $(echo "$Ydiff > 0.95" | bc) -eq 1 ]; then flagtop=1; echo I found a positive value  corresponds to the forht Y layer
		# FIND THE NEW Ymin
                        line=1
                        while [ "$line" -le "$metallayer"  ]; do
                                Ycoord=`head -n$line $layer | tail -1 | awk '{print $2}'`; 
                                crierion=`awk "BEGIN { print $Ymax - $Ycoord}"`;  # Ycoord in this case is always positive because the lowest value is Ymin which > 0
                                if [ $(echo "$crierion < 0.95" | bc) -eq 1 ]; then Ymin=$Ycoord;
                                else
                                        echo this $Ycoord belongs to top layer, its real coordinte is 1.0 - $Ycoord $'\n'; 
					YcoordNew=`echo "1.0-$Ycoord" | bc` ;
                                        sed -i "s/$Ycoord/0$YcoordNew/g" $layer ;
                                # if the difference is above 0.95, it means that this atom belongs to top layer, I cahange its coordinate to 1-Ycoord
                                 fi
                        line=$(($line+1))
                        done
			Ydiff=`awk "BEGIN { print $Ymax - $Ymin}"` # changing Ydiff
                        echo $'\n' Now Ymax for $layer is $Ymax and Ymin is $Ymin $'\n'
		elif [ $(echo "$Ydiff < 0.95" | bc) -eq 1 ]; then echo I have not found any nagative number nor any positive number from forth Y layer
		# kepp Ydiff to what it is
    		fi
    fi	
    # the output of this loop above gives us the real value for Ydiff and have changes the negative Y coordinates if they were correspondent to the forth Y layer 	
       
	Yinter=`awk "BEGIN { print $Ydiff / 3 }"`; limit=`awk "BEGIN { print $Yinter / 2  }"`;
	Ylimit1=`awk "BEGIN { print $Ymin + (0*$Yinter) + $limit }"`; Ylimit2=`awk "BEGIN { print $Ymin + (1*$Yinter) + $limit }"`
	Ylimit3=`awk "BEGIN { print $Ymin + (2*$Yinter) + $limit }"`; #### FALG #### echo $'\n' Ylimits for $layer is $Ylimit1 , $Ylimit2 and $Ylimit3 $'\n'
        
        # arrange atoms with lower Y
        line=1
        while [ "$line" -le "$metallayer"  ]; do
	Ycoord=`head -n$line $layer | tail -1 | awk '{print $2}'`; #### FALG #### echo Ycoord is $Ycoord

	# negative Y values automatically go to layer-Y1 because for sure its value is lower that limit1
	# the other negative values that were from Forth Y layer have already changed to a psoitive value
        	if     [ $(echo "$Ycoord > $Ylimit3" | bc) -eq 1  ]; then  head -n$line $layer | tail -1 >> $layer-Y4;
       	 	elif [ $(echo "$Ycoord > $Ylimit2 && $Ycoord < $Ylimit3" | bc) -eq 1  ]; then  head -n$line $layer | tail -1 >> $layer-Y3; 
		elif [ $(echo "$Ycoord > $Ylimit1 && $Ycoord < $Ylimit2" | bc) -eq 1  ]; then  head -n$line $layer | tail -1 >> $layer-Y2;
		elif [ $(echo "$Ycoord < $Ylimit1" | bc) -eq 1  ]; then  head -n$line $layer | tail -1 >> $layer-Y1;
		fi
	line=$(($line+1))
        done
        
	# Arrange atom with lower X from  Y files
	for i in $layer-Y1 $layer-Y2 $layer-Y3 $layer-Y4; do
		
	#	negflag=0
	#	flagtop=0
		Xmax=0; Xmin=1;
		for line in {1..4}; do 
		Xcoord=`head -n$line $i | tail -1 | awk '{print $1}'`;
                if [ $(echo "$Xcoord < 0" | bc) -eq 1  ]; then  Xcoord=`awk "BEGIN { print $Xcoord + 1.0}"`; fi; #### FALG #### echo Xcoord is $Xcoord # for negattive coordinate
		#negflag=1;
                if [ $(echo "$Xcoord > $Xmax" | bc) -eq 1 ]; then Xmax=$Xcoord; fi;
                if [ $(echo "$Xcoord < $Xmin" | bc) -eq 1 ]; then Xmin=$Xcoord; fi;
		done
 	### FLAG  echo $'\n' Xmax for $i is $Xmax and Xmin is $Xmin $'\n'

		#if [ "$negflag" -eq 1  ]; then echo I found a nagative X value in $i;
                #	Xmin=${Xmin#-}  # make absolot value of the negative number
                #	Xdiff=`awk "BEGIN { print $Xmax - $Xmin}"`;
                #	echo $'\n' Now Xmax for $i is $Xmax and Xmin is $Xmin $'\n' and Xdiff is $Xdiff
               	#	
		#	if [ $(echo "$Xdiff > 0.95" | bc) -eq 1 ]; then flagtop=1; echo This negative value  corresponds to the forht X atom
               	#	 # FIND THE NEW Xmin
		#		for line in {1..4}; do
		#			Xcoord=`head -n$line $i | tail -1 | awk '{print $1}'`;
	        #                       crierion=`awk "BEGIN { print $Xmax - $Xcoord}"`;  # we do not need to take absolute of Xcoord, even for Xcoord < 0 the criterion is > 1.0
                #               		if [ $(echo "$crierion < 0.95" | bc) -eq 1 ]; then Xmin=$Xcoord;
                #               	else
                #                        	echo this $Xcoord belongs to forth X atom, I am chanigin its coordinte to 1.0 + $Xcoord $'\n'; XcoordNew=`echo "1.0+$Xcoord" | bc` ;
                #                        	sed -i "s/$Xcoord/ 0$XcoordNew/g" $i ;
                #                	# if the difference is above 0.95, it means that this atom belongs to forth X atom, I cahange its coordinate to 1+Xcoord
                #                 	fi
		#		done
		#	Xdiff=`awk "BEGIN { print $Xmax - $Xmin}"`; # change the value of Xdiff based of the new Xmin
		#	echo now Xmin is $Xmin

		#	elif [ $(echo "$Xdiff < 0.95" | bc) -eq 1 ]; then
		#		# keep Xdiff to what it was
		#		echo This negative value is the first X atom
		#	fi
		#elif [ "$negflag" -eq 0  ]; then Xdiff=`awk "BEGIN { print $Xmax - $Xmin}"`; # we have no negative value
		#	if [ $(echo "$Xdiff > 0.95" | bc) -eq 1 ]; then flagtop=1; echo I have found a positive Xvalue corresponds to the forth X atom
		#	# FIND THE NEW Xmin
		#		for line in {1..4}; do
                #                       Xcoord=`head -n$line $i | tail -1 | awk '{print $1}'`;
                #                      crierion=`awk "BEGIN { print $Xmax - $Xcoord}"`;  # the X value is always positive in this case
                #                        if [ $(echo "$crierion < 0.95" | bc) -eq 1 ]; then Xmin=$Xcoord;
                #                        else
                #                                echo this $Xcoord belongs to forth X atom, I am chanigin its coordinte to 1.0 - $Xcoord $'\n'; XcoordNew=`echo "1.0-$Xcoord" | bc` ;
                #                                sed -i "s/$Xcoord/0$XcoordNew/g" $i ;
                #                        # if the difference is above 0.95, it means that this atom belongs to forth X atom, I cahange its coordinate to 1-Xcoord
                #                        fi
                #                done
                #        Xdiff=`awk "BEGIN { print $Xmax - $Xmin}"`; # change the value of Xdiff based of the new Xmin
		#	echo now Xmin is $Xmin
		#	
		#	elif [ $(echo "$Xdiff < 0.95" | bc) -eq 1 ]; then echo I have not found any negative X nor any positive X corresponding to the forth X atom
		#	# keep Xdiff to what it is
		#	fi
		#fi
		 
	# the above if clause return Xdiff value for us		
		Xdiff=`awk "BEGIN { print $Xmax - $Xmin}"`
		Xinter=`awk "BEGIN { print $Xdiff / 3 }"`; limit=`awk "BEGIN { print $Xinter / 2  }"`;
	        Xlimit1=`awk "BEGIN { print $Xmin + (0*$Xinter) + $limit }"`; Xlimit2=`awk "BEGIN { print $Xmin + (1*$Xinter) + $limit }"`;
        	Xlimit3=`awk "BEGIN { print $Xmin + (2*$Xinter) + $limit }"`; #### FALG #### echo $'\n' Xlimits for $layer is $Xlimit1 , $Xlimit2 and $Xlimit3 $'\n'
		
		for line in {1..4};do
		Xcoord=`head -n$line $i | tail -1 | awk '{print $1}'`; #### FALG #### echo Xcoord is $Xcoord
		if [ $(echo "$Xcoord < 0" | bc) -eq 1  ]; then Xcoord=`awk "BEGIN { print $Xcoord + 1.0}"`; fi; # for negative coordinate
		if     [ $(echo "$Xcoord < $Xlimit1" | bc) -eq 1  ]; then  head -n$line $i | tail -1 >> $i-X1;
		elif   [ $(echo "$Xcoord > $Xlimit1 && $Xcoord < $Xlimit2" | bc) -eq 1  ]; then  head -n$line $i | tail -1 >> $i-X2;
		elif   [ $(echo "$Xcoord > $Xlimit2 && $Xcoord < $Xlimit3" | bc) -eq 1  ]; then  head -n$line $i | tail -1 >> $i-X3;
		elif   [ $(echo "$Xcoord > $Xlimit3" | bc) -eq 1  ]; then  head -n$line $i | tail -1 >> $i-X4;
		fi
		done
		
	done
done

# Change the negeative coordinates with positve one
for i in layer*Y*X*; do
    Xcoord=`head -1 $i | awk '{print $1}'`; 
   # Ycoord=`head -1 $i | awk '{print $2}'`;
   # Zcoord=`head -1 $i | awk '{print $3}'`;
    if     [ $(echo "$Xcoord < 0" | bc) -eq 1  ]; then XcoordNew=`echo "$Xcoord+1.0" | bc` ; sed -i "s/$Xcoord/ 0$XcoordNew/g" $i;fi
    #if   [ $(echo "$Ycoord < 0" | bc) -eq 1  ]; then YcoordNew=`echo "$Ycoord+1.0" | bc` ; sed -i "s/$Ycoord/ 0$YcoordNew/g" $i;fi
#    elif   [ $(echo "$Zcoord < 0" | bc) -eq 1  ]; then ZcoordNew=`echo "$Zcoord+1.0" | bc` ; sed -i "s/$Zcoord/ 0$ZcoordNew/g" $i;
   
done
#########   Collect the data and creat the new CONTCAR with arranaged atoms  ########
cat layer*Y*X* > Metal-arranged
cat header Metal-arranged Adsorbate > CONTCAR-new
mv CONTCAR-new CONTCAR

echo $'\n' Your final result is in CONTCAR file, just in case that anything went wrong $'\n' you can find your original CONTCAR in CONTCARorginal $'\n'

## Clean up 
rm Adsorbate header Metal* layer*


