#!/bin/bash

#  you need to have CONTCAR-clean, CONTCAR-IS, CONTCAR-FS, and CONTCAR-TS in Template directory
#  This code prepare your CONTCARS-IS, TS, FS before fixing anchor atoms.
#  What it does: 1: change the header to clean slab's header 2: fixed all metal atoms

echo $'\n' !!! Purpose : change the header to clean slab header, and fix all metal atoms !!!
echo $'\n' !!! Required: a directory called Template with these files inside             !!!
echo $'\n' !!! CONTCAR-IS, CONTCAR-FS, CONTCAR-TS, CONTCAR-clean $'\n'                   !!! 

# FLAG
curdir=`pwd`; if [ ! -d "$curdir/Template" ]; then echo I have not found Template directory in currecnt directory, please try later; exit 1;fi
# end of FLAG

cp -r Template Original-Template-before-RxnCoordPrep

cd Template;

# FLAG
for i in CONTCAR-clean  CONTCAR-FS  CONTCAR-IS  CONTCAR-TS;
    do file=$i; if [ ! -f "$file"  ]; then echo I have not found $i in Template directory; exit 1; fi
done

# end of FLAG


# Get the header of clean surface
head -5 CONTCAR-clean > header.POSCAR   

# replace headers with clean surface's header
for i in CONTCAR-IS CONTCAR-FS CONTCAR-TS;
 do sed -i '1,5d' $i; cat header.POSCAR $i > ali; mv ali $i;
done

# Get the number of metal, Carbon, Oxygen and Hydrogen in your system
metalID=`head -6  CONTCAR-IS | tail -1 | awk '{print $1}'` ; metalNum=`head -7  CONTCAR-IS | tail -1 | awk '{print $1}'`;
atom1ID=`head -6  CONTCAR-IS | tail -1 | awk '{print $2}'` ; atom1Num=`head -7  CONTCAR-IS | tail -1 | awk '{print $2}'`;
atom2ID=`head -6  CONTCAR-IS | tail -1 | awk '{print $3}'` ; atom2Num=`head -7  CONTCAR-IS | tail -1 | awk '{print $3}'`;
atom3ID=`head -6  CONTCAR-IS | tail -1 | awk '{print $4}'` ; atom3Num=`head -7  CONTCAR-IS | tail -1 | awk '{print $4}'`;

#  FLAG
 echo $'\n' $metalID $metalNum; echo $atom1ID $atom1Num; echo $atom2ID $atom2Num; echo $atom3ID $atom3Num $'\n';
  
 echo " Is the data correct? yes or no"
 read answer
 if [ "$answer" = "yes" ]
   then
       echo "alright, Let's continue"
 elif [ "$answer" = "no" ]
   then
      exit 1
   else
      echo "please insert the correct word"
       exit 1  
  fi
# end of FLAG

# fix all metal atoms
firstline=$((($metalNum/2)+10))    # the first line that shows the first metal coordinate of layer 3, 10 is the first line of coordinates
lastline=$(($metalNum+10-1))       # the last line of matal coordinates

# FLAG
echo "this is one of your lines which shows a relaxes atom in your CONTCAR-IS $'\n'"
head -n$lastline CONTCAR-IS | tail -1;
echo "this is one of your lines which shows a relaxes atom in your CONTCAR-FS $'\n'"
head -n$lastline CONTCAR-TS | tail -1
echo "this is one of your lines which shows a relaxes atom in your CONTCAR-FS $'\n'"
head -n$lastline CONTCAR-FS | tail -1

echo -e  " I assuem that the end of coordinates has three spaces between T   T   T It is like this? yes or no"
 read answer
 if [ "$answer" = "yes" ]
   then
       echo "alright, Let's continue"
 elif [ "$answer" = "no" ]
   then
      echo "please modify your CONTCARS and try this code again"
      exit 1
   else
      echo "please insert the correct word"
       exit 1
  fi
# end of FLAG

for i in CONTCAR-IS CONTCAR-FS CONTCAR-TS;
 do sed -i "$firstline,$lastline s/T   T   T/F   F   F/g" $i;
 fixed=`grep "F   F   F" $i | wc -l`;
 echo number of fixed metal atoms in $i is $fixed now, it should be $metalNum $'\n';
done

#FLAG
echo "do you want to continue? yes or no"
   read answer
   if [ "$answer" = "yes" ]
   then
       echo "alright, Let's continue"
 elif [ "$answer" = "no" ]
   then
      echo "please modify your CONTCARS and try this code again"
      exit 1
   else
      echo "please insert the correct word"
       exit 1
  fi
# end of FLAG 

cd ../

echo  " The next step should be fixing anchor atoms manually and perfor NEB code to get images using RxnCoordNEB.sh script $'\n'";
echo  " Just in case that this code has not done what you expexted, your original files are in Original-Template directory $'\n'";



