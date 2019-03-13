#!/bin/bash 

##################################################################################################################################
#				Author : Mehdi Zare on 3/4/2019                                                                  #
# 				Purpose: to make 51 atom cluster out of CONTCAR							 #
#
#
#################################################################################################################################

###  INSTRUCTION 
echo $'\n' This code need the CONTCAR file and create for you your cluster file containes 51 metal plus adsorbate $'\n'
echo $'\n' In addition you need to have CONTCAR-or-POSCAR-prep.sh file in your path because this code call it first $'\n'
#####################################  FLAG ######################################
echo  $'\n' do you have this script in your path, yes or no $'\n'
read answer
if [ "$answer" = "yes" ]
  then
      echo "alright, Let's continue" 
elif [ "$answer" = "no" ]
  then
      echo $'\n' please talk to Mehdi or modify this code $'\n'
      exit 1
  else
     echo "please insert the correct word"
      exit 1
 fi
##################################  END OF FLAG ####################################

### prepare CONTCAR atoms to be in correct order
CONTCAR-or-POSCAR-prep.sh

# This part is just for cleaning up the CONTCAR file

sed  -i '/^[[:space:]]*$/,$d' CONTCAR


###First Part-Creating an expanded surface###

vasp-build-supercell-from-poscar -f CONTCAR -o XYZ -X 5 -Y 5 > expanded.xyz

head -2 expanded.xyz > first-header
totatom=`head -1 expanded.xyz`   # total atoms in your 5x5 supercell 
sed '1,2 d' expanded.xyz > No-header    # remove header of the xyz file

### Remove the first two bottom layers
var=32      # number of atoms in two bottom layers
totcell=25  # total number of cells

cellnum=1   # cell number, we have 25 cells because we used 5x5=25
j=0	     # index for the controling the loop
while [ "$cellnum" -le "$totcell"  ]
   do idfirst=$((($j*$var)+1)); idlast=$((($j+1)*$var))
   echo cellnumber is $cellnum , idfirst is $idfirst and idlast is $idlast
   sed -i "$idfirst,$idlast s/$/ remove/" No-header                  # tag corresponding atoms
   cellnum=$(($cellnum+1))
   j=$(($j+2))                      # 2 because we want to skip 32 Pt atoms of top two layers
done

#sed -i '/remove/d' No-header            # remove all lines with remove tag

### end of removing two first bottom layers

### remove all adsorbates and keeep adsorbate in the middile cell (13th cell)
varC=2       # number of carbon atoms of the adsorbate
varO=2       # number of oxygen atoms of the adsorbate
varH=6	     # number of Hydrogen atoms of the adsorbate

cellnum=0
j=-1
while [ "$cellnum" -le "24"  ]                            # for cell #1 to cell #12 and cell number 14 to 25
   do cellnum=$(($cellnum+1))                             # the first cell is cell #1
      j=$(($j+1))                                         # the first index is zero
      if [ "$cellnum" -eq 13 ]; then continue; fi             # in order to skip cell #13
      Cidfirst=$((1600+($j*$varC)+1)); Cidlast=$(($Cidfirst+$varC-1))     			# carbon atoms id starts from after all Pt atoms (64x25)=1600
      Oidfirst=$((1600+(25*$varC)+($j*$varO)+1)); Oidlast=$(($Oidfirst+$varO-1))     		# oxygen atoms id starts from after all Pt atoms (64x25)=1600 and all carbon atoms (25x2)
      Hidfirst=$((1600+(25*$varC)+(25*$varO)+($j*$varH)+1)); Hidlast=$(($Hidfirst+$varH-1)) # hydroge  atoms id starts from after all Pt atoms (64x25)=1600 and all carbon atoms (25x2) and all Oxygen(25x2)  
     echo cellnumber is $cellnum , Cidfirst is $Cidfirst and Cidlast is $Cidlast
     echo cellnumber is $cellnum , Oidfirst is $Oidfirst and Oidlast is $Oidlast
     echo cellnumber is $cellnum , Hidfirst is $Hidfirst and Hidlast is $Hidlast
   sed -i "$Cidfirst,$Cidlast s/$/ remove/" No-header                  # tag Carbon  corresponding atoms
   sed -i "$Oidfirst,$Oidlast s/$/ remove/" No-header                  # tag Oxygen corresponding atoms
   sed -i "$Hidfirst,$Hidlast s/$/ remove/" No-header                  # tag Hydrogen corresponding atoms
done

### end of remving adsorbates except for cell #13

### remove Pt atoms of cells which are loacated on sides (1-5, 21-25, 6,11,16, 10,15,20)
var=32      # number of atoms in two top layers

for cellnum in {1..5} {21..25} 6 11 16 10 15 20
   do k=$(($cellnum-1))          # index for the controling the difference between cellnum and j index 
      j=$(($cellnum+k))          # this index controls the id of Pt atoms
   idfirst=$((($j*$var)+1)); idlast=$((($j+1)*$var))
   echo cellnumber is $cellnum , idfirst is $idfirst and idlast is $idlast
   sed -i "$idfirst,$idlast s/$/ remove/" No-header                  # tag corresponding atoms

done

### end of removing Pt atoms of cells which are located on sides

sed -i '/remove/d' No-header            # remove all lines with remove tag


# remove file Order if it exist
 if [ -f "Order.xyz"  ];then echo I found file name Order and It will be overwritten by the new one; rm Order.xyz;fi
 if [ -f "cluster.xyz"  ]; then echo $'\n'  I found cluster.xyz file, this will ber overwritten by the new one $'\n'; rm cluster.xyz; fi
#### have atoms in order , first, the bottom pt Layer, then the top layer and then adsorbate
var=32
atoms=4                 # number of atoms in one layer

for L in {1..2}         # we have bottom layer and top layer
  do
    for row in {1..3}; do    # total number of rows in x direection (we have 3 rows of cells)

	for layer in {1..4}     # for 4 layers of atoms in each cell
  	 do
      		for i in {1..3}       # the first 3 cells in each row
    			do cellnum=$(($i+(3*($row-1))))     # real cellnumber 
 			j=$(($cellnum-1))
     			first=$((($j*$var)+(($layer-1)*$atoms)+(($L-1)*16)+1)); last=$(($first+$atoms-1))      # in each top and bottom layers we have 16 atoms
        		echo  readl layer is $L and row is $row cellnumber is $cellnum and layer is $layer and first is $first and last is $last
       			sed -i "$first,$last s/$/order/" No-header                  # tag corresponding atoms
     		        sed -ne '/order/ p' No-header >> Order.xyz
        		sed -i 's/order//'   No-header
      		done
	done

     done

done

# add adsorbates

first=$((($var*9)+1)); last=$(($first+$varC+$varO+$varH-1))
echo first $first last$last
sed -i "$first,$last s/$/order/" No-header                  # tag corresponding atoms
sed -ne '/order/ p' No-header >> Order.xyz
sed -i 's/order//'   No-header
sed -i 's/order//' Order.xyz

#### end of  having atoms in order

###  get cluste atoms of bottom and top layer


# Get atom id from user
# top layer
echo  $'\n' please enter two middle atoms of your desired cluster in x direction order from file Order.xyz $'\n'
#####################################  FLAG ######################################
echo  $'\n' do you have these numbers, yes or no $'\n'
read answer
if [ "$answer" = "yes" ]
  then
      echo $'\n' alright, Lets continue $'\n' pelase enter middle atom numbers $'\n'
elif [ "$answer" = "no" ]
  then
     echo $'\n' please open Order.xyz file in Vesta and choose the atom numbers $'\n'
     sed -i  "1 i\298\nORDER"  Order.xyz
     exit 1
  else
     echo $'\n' please insert the correct word $'\n'
     sed -i  "1 i\298\nORDER"  Order.xyz
      exit 1
 fi
##################################  END OF FLAG ####################################

read one
read two

# bottom layer 
echo $'\n' please enter the atom id under and in the middle of the two atoms you just entered $'\n'
#####################################  FLAG ######################################
echo  $'\n' do you have this number, yes or no $'\n'
read answer
if [ "$answer" = "yes" ]
  then
      echo $'\n' alright, Lets continue $'\n' please enter the the center bottom atom number $'\n'
elif [ "$answer" = "no" ]
  then
     echo  $'\n' please open Order.xyz file in Vesta and give me the atom number $'\n'
     sed -i  "1 i\298\nORDER"  Order.xyz
     exit 1
  else
     echo  $'\n' please insert the correct word $'\n'
      sed -i  "1 i\298\nORDER"  Order.xyz
      exit 1
 fi
##################################  END OF FLAG ####################################

read center

# FOR BOTTOM LAYER
Q=$(($center/12))
R=$(($center%12))

if [ "$R" -eq  0  ]; then
      rownum=$(($Q))   
      atomnum=12
      echo you are in the $atomnum th atom of row number $rownum
elif [ "$R" -ne  0  ]; then
      rownum=$(($Q+1))
      atomnum=$R
      echo you are in the $atomnum th atom of row number $rownum
fi

cornerone=$(($center-2)); cornertwo=$(($center+2))    # the first and last atom number of middile row of cluster
# find out that we are in an odd row or an even row number
Rrownum=$(($rownum%2))

# We have 2 option here, we need to check the coordinate of the first atom of second row and first row, it means atom #1 and atom #13
Xcoord1=`head -1 Order.xyz | awk '{ print $2 }'`; Xcoord13=`head -13 Order.xyz | tail -1 |  awk '{ print $2 }'`;
Xcoord25=`head -25 Order.xyz | tail -1 |  awk '{ print $2 }'`;
diff=`awk "BEGIN { print $Xcoord13 - $Xcoord1 }"`; diff1=`awk "BEGIN { print $Xcoord25 - $Xcoord13 }"`

echo $'\n' Bottom layer $'\n'
echo $'\n' X1 is $Xcoord1 and X13 is $Xcoord13 $'\n' and the diff is $diff $'\n' and diff1 is $diff1

#### these are possiblities that I have seen so far, if there is another one, you need to add it in if clause here
#### #   To understand what I am talking about, you can take a look at file Order.xyz atoms 1, 13, 25

if [ $(echo "$diff < 0" | bc) -eq 1  ] && [ $(echo "$diff1 > 0" | bc) -eq 1 ]; then      # single Zig Zag in bottom layer with atom 13 on the left side of atom 1
											 # and atom 25 on the right side of atom 13
	if [ "$Rrownum"  -ne  0  ]; then
   		plus1=$(($cornerone+12+1));  minus1=$(($cornerone-12+1)); 
   		plus2=$(($plus1+12));        minus2=$(($minus1-12));      
   		minus3=$(($minus2-12+1)); 
	elif [ "$Rrownum"  -eq  0  ]; then
  		plus1=$(($cornerone+12));    minus1=$(($cornerone-12));   
   		plus2=$(($plus1+12+1));      minus2=$(($minus1-12+1));    
   		minus3=$(($minus2-12));      
	fi
        plus1end=$(($plus1+3)); minus1end=$(($minus1+3)); plus2end=$(($plus2+2)); minus2end=$(($minus2+2));
        minus3end=$(($minus3+1));
        sed -i "$minus3,$minus3end s/$/cluster/" Order.xyz;
        sed -i "$minus2,$minus2end s/$/cluster/" Order.xyz; sed -i "$minus1,$minus1end s/$/cluster/" Order.xyz;
        sed -i "$cornerone,$cornertwo s/$/cluster/" Order.xyz; sed -i "$plus1,$plus1end s/$/cluster/" Order.xyz;
	sed -i "$plus2,$plus2end s/$/cluster/" Order.xyz;
        sed -ne '/cluster/ p' Order.xyz >> cluster.xyz
        sed -i 's/cluster//'  Order.xyz

elif [ $(echo "$diff < 0" | bc) -eq 1  ] && [ $(echo "$diff1 < 0" | bc) -eq 1 ]; then     # double Zig Zag in bottom layer with atom 13 on the right side of atom 1
        if [ "$rownum"  -eq  4  ] || [ "$rownum"  -eq  8  ]; then			  # and atom 25 on the left side of atom 13
                plus1=$(($cornerone+12));  minus1=$(($cornerone-12+1)); 
                plus2=$(($plus1+12+1));        minus2=$(($minus1-12));      
                plus3=$(($plus2+12+1)); 
        elif [ "$rownum"  -eq  5  ] || [ "$rownum"  -eq  9  ]; then
                plus1=$(($cornerone+12+1));    minus1=$(($cornerone-12+1));   
                plus2=$(($plus1+12+1));      minus2=$(($minus1-12+1));    
                plus3=$(($plus2+12));      
        elif [ "$rownum"  -eq  6  ]; then
                plus1=$(($cornerone+12+1));    minus1=$(($cornerone-12));
                plus2=$(($plus1+12));      minus2=$(($minus1-12+1));    
                plus3=$(($plus2+12));  
        elif [ "$rownum"  -eq  7  ]; then
                plus1=$(($cornerone+12));    minus1=$(($cornerone-12+1));
                plus2=$(($plus1+12));      minus2=$(($minus1-12));  
                plus3=$(($plus2+12+1));
       else
       		echo $'\n' your row number is either lower thatn 4 or higher than 9, you cannot have a 51 cluster $'\n'
		exit 1
       fi
        plus1end=$(($plus1+3)); minus1end=$(($minus1+3)); plus2end=$(($plus2+2)); minus2end=$(($minus2+2));
        plus3end=$(($plus3+1));
        sed -i "$minus2,$minus2end s/$/cluster/" Order.xyz; sed -i "$minus1,$minus1end s/$/cluster/" Order.xyz;
        sed -i "$cornerone,$cornertwo s/$/cluster/" Order.xyz; sed -i "$plus1,$plus1end s/$/cluster/" Order.xyz;
        sed -i "$plus2,$plus2end s/$/cluster/" Order.xyz;
        sed -i "$plus3,$plus3end s/$/cluster/" Order.xyz;
	sed -ne '/cluster/ p' Order.xyz >> cluster.xyz
        sed -i 's/cluster//'  Order.xyz

	
elif [ $(echo "$diff > 0" | bc) -eq 1   ] && [ $(echo "$diff1 < 0" | bc) -eq 1 ]; then     # single zig zag with atom 13 on the right side of atom 1
        if [ "$Rrownum"  -eq  0  ]; then						   # and atom 25 on the left side of atom 13
                plus1=$(($cornerone+12+1));  minus1=$(($cornerone-12+1)); 
                plus2=$(($plus1+12));      minus2=$(($minus1-12));      
                minus3=$(($minus2-12+1)); 
        elif [ "$Rrownum"  -ne  0  ]; then
                plus1=$(($cornerone+12));    minus1=$(($cornerone-12));   
                plus2=$(($plus1+12+1));      minus2=$(($minus1-12+1));    
                minus3=$(($minus2-12));      
        fi
	plus1end=$(($plus1+3)); minus1end=$(($minus1+3)); plus2end=$(($plus2+2)); minus2end=$(($minus2+2));
	minus3end=$(($minus3+1));
	sed -i "$minus3,$minus3end s/$/cluster/" Order.xyz;
	sed -i "$minus2,$minus2end s/$/cluster/" Order.xyz; sed -i "$minus1,$minus1end s/$/cluster/" Order.xyz;
	sed -i "$cornerone,$cornertwo s/$/cluster/" Order.xyz; sed -i "$plus1,$plus1end s/$/cluster/" Order.xyz; 
	sed -i "$plus2,$plus2end s/$/cluster/" Order.xyz;
	sed -ne '/cluster/ p' Order.xyz >> cluster.xyz
	sed -i 's/cluster//'  Order.xyz
fi

# tag cluster atoms of bottom layers


echo $'\n' Bottom layer $'\n'
echo cornerone is $cornerone and cornertwo is $cornertwo
echo plus1 is $plus1 plus2 is $plus2 plus3 is $plus3
echo minus1 is $minus1 minus2 is $minus2 minus3 is $minus3

# FOR TOP LAYER
# find the postition of the atoms
Q=$((one/12))     # now we have 12 atoms in each row of each layer, the quotient
R=$((one%12))     # Get the remainder

if [ "$R" -eq  0  ]; then
      rownum=$(($Q-12))           # the row number of in top laye, we have to subtract from 12 becasue we have 12 row of bottom layer
      atomnum=12
      echo you are in the $atomnum th atom of row number $rownum
elif [ "$R" -ne  0  ]; then
      rownum=$(($Q-12+1))
      atomnum=$R
      echo you are in the $atomnum th atom of row number $rownum
fi

cornerone=$(($one-2)); cornertwo=$(($two+2))    # the first and last atom number of middile row of cluster
# find out that we are in an odd row or an even row number
Rrownum=$(($rownum%2))

# We have 2 option here, we need to check the coordinate of the first atom of second row and first row, it means atom #145 and atom #157
Xcoord145=`head -145 Order.xyz | tail -1 |  awk '{ print $2 }'`; Xcoord157=`head -157 Order.xyz | tail -1 |  awk '{print $2}'`
diff=`awk "BEGIN {print $Xcoord157 - $Xcoord145}"`; 

echo $'\n' TOP layer $'\n'
echo $'\n' X145 is $Xcoord145 and X157 is $Xcoord157 $'\n' and the diff is $diff $'\n'

#   For TOP layer I only considered single zig zag possiblites, if you think there are other possiblities, do it like what I did for bottom layer
#   To understand what I am talking about, you can take a look at file Order.xyz, atoms 145 and atom 157

if [ $(echo "$diff > 0" | bc) -eq 1   ]; then
	if [ "$Rrownum"  -eq  0  ]; then
   		plus1=$(($cornerone+12+1))
  		minus1=$(($cornerone-12+1))
   		plus2=$(($plus1+12))
   		minus2=$(($minus1-12))
   		plus3=$(($plus2+12+1))
   		minus3=$(($minus2-12+1))
	elif [ "$Rrownum"  -ne  0  ]; then
   		plus1=$(($cornerone+12))
   		minus1=$(($cornerone-12))
   		plus2=$(($plus1+12+1))
   		minus2=$(($minus1-12+1))
   		plus3=$(($plus2+12))
   		minus3=$(($minus2-12))
	fi
elif [ $(echo "$diff < 0" | bc) -eq 1   ]; then
        if [ "$Rrownum"  -ne  0  ]; then
                plus1=$(($cornerone+12+1))
                minus1=$(($cornerone-12+1))
                plus2=$(($plus1+12))
                minus2=$(($minus1-12))
                plus3=$(($plus2+12+1))
                minus3=$(($minus2-12+1))
        elif [ "$Rrownum"  -eq  0  ]; then
                plus1=$(($cornerone+12))
                minus1=$(($cornerone-12))
                plus2=$(($plus1+12+1))
                minus2=$(($minus1-12+1))
                plus3=$(($plus2+12))
                minus3=$(($minus2-12))
        fi
fi
# tag cluster atoms of bottom layers
plus1end=$(($plus1+4)); minus1end=$(($minus1+4)); plus2end=$(($plus2+3)); minus2end=$(($minus2+3)); plus3end=$(($plus3+2));minus3end=$(($minus3+2))
sed -i "$minus3,$minus3end s/$/cluster/" Order.xyz; sed -i "$minus2,$minus2end s/$/cluster/" Order.xyz; sed -i "$minus1,$minus1end s/$/cluster/" Order.xyz;
sed -i "$cornerone,$cornertwo s/$/cluster/" Order.xyz; sed -i "$plus1,$plus1end s/$/cluster/" Order.xyz; sed -i "$plus2,$plus2end s/$/cluster/" Order.xyz;
sed -i "$plus3,$plus3end s/$/cluster/" Order.xyz;
sed -ne '/cluster/ p' Order.xyz >> cluster.xyz
sed -i 's/cluster//'  Order.xyz

echo $'\n' Top layer $'\n'
echo cornerone is $cornerone and cornertwo is $cornertwo
echo plus1 is $plus1 plus2 is $plus2 plus3 is $plus3
echo minus1 is $minus1 minus2 is $minus2 minus3 is $minus3

# Add adsorbates to the cluster.xyz
first=$((($var*9)+1)); last=$(($first+$varC+$varO+$varH-1))
echo first $first last$last
sed -i "$first,$last s/$/cluster/" Order.xyz                  # tag corresponding atoms
sed -ne '/cluster/ p' Order.xyz >> cluster.xyz
sed -i 's/cluster//'   Order.xyz


# clean up cluster file
sed -i 's/cluster//'   cluster.xyz

# FLAG FOR CHECKING THE BUMBER OF CLUSTER ATOMS
  clusatom=`wc -l cluster.xyz | awk '{print $1}'`
  suppose=$((51+$varC+$varO+$varH))
  echo the number of cluster atoms are $clusatom and it must be $suppose  

sed -i "1 i\61\nCLUSTER" cluster.xyz
sed -i  "1 i\298\nORDER"  Order.xyz












