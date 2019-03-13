#!/bin/bash

#  you need to have CONTCAR-clean, CONTCAR-IS, CONTCAR-FS, and CONTCAR-TS in Template directory
#  And you need to have OSZICAR-IS, OSZICAR-TS, OSZICAR-FS in your Template directory as well
#  And I need header.POSCAR , INCAR , job-script-hyperion  ,POTCAR,  KPOINTS to set up the calculations 
#  I am assuming that you have fixed you anchor atom's coordinates
#  I assume that you have nebmake.pl in this path  ~/Vtst-Scripts/ 

echo $'\n' !!! Purpose : Insert images between IS to TS and TS to FS	             		 !!!
echo $'\n' !!! Required: a directory called Template with these files inside                     !!!
echo $'\n' !!! CONTCAR-IS, CONTCAR-FS, CONTCAR-TS, CONTCAR-clean, header.POSCAR, INCAR   	 !!! 
echo $'\n' !!! job-* which is vasp job-script, KPOINTS, POTCAR				 	 !!!
echo $'\n' !!! The best way is to copy the Template directory after performing RxnCoordPrep.sh   !!!
echo $'\n' !!! I assume that you have nebmake.pl in this path available ~/Vtst-Scripts/ $'\n'    !!!

# FLAG
curdir=`pwd`; if [ ! -d "$curdir/Template" ]; then echo I have not found Template directory in currecnt directory, please try later; exit 1;fi
# end of FLAG

cp -r Template Original-Template-before-NEB

cd Template;

# FLAG
mv job-* job-script

for i in CONTCAR-clean  CONTCAR-FS  CONTCAR-IS  CONTCAR-TS  header.POSCAR  INCAR  job-script  KPOINTS  OSZICAR-FS  OSZICAR-IS  OSZICAR-TS  POTCAR;
    do file=$i; if [ ! -f "$file"  ]; then echo I have not found $i in Template directory; exit 1; fi
done

if [ ! -d "$HOME/Vtst-Scripts" ]; then echo I have not found Vtst-Scripts directory in your home directory, please try later; exit 1;fi
# end of FLAG




# Get energies from OSZICARs
scfIS=`tail -1 OSZICAR-IS | awk '{print $5}'`; scfTS=`tail -1 OSZICAR-TS | awk '{print $5}'`;scfFS=`tail -1 OSZICAR-FS | awk '{print $5}'`

# calculate the number of images we need between IS to TS and TS to FS
kb=8.61733502e-5;
echo  $'\n' please enter your desired Temperature $'\n'
read T
kbT=`awk "BEGIN { print $kb * $T}"`;

dEf=`awk "BEGIN { print $scfTS - $scfIS}"`; dEr=`awk "BEGIN { print $scfTS - $scfFS}"`

NumImgf=`awk "BEGIN { print int($dEf / $kbT) }"`
NumImgr=`awk "BEGIN { print int($dEr / $kbT) }"`

# FLAG
echo EnergyIS is $scfIS , EnergyTS is $scfTS, and EnergyFS is $scfFS $'\n'
echo forward barrier is $dEf and reverse barrier is $dEr $'\n'
echo number of images from Reactant to Transition state are $NumImgf $'\n'
echo number of images from Transition state to Product are $NumImgr $'\n'

echo " do these numbers make sense to you? yes or no " $'\n'
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
cd ../

mkdir IS-to-TS TS-to-FS
cp Template*/{CONTCAR-IS,CONTCAR-TS} IS-to-TS/;
cp Template*/{CONTCAR-TS,CONTCAR-FS} TS-to-FS/;

# Creating Images from IS to TS
cd IS-to-TS/
  perl ~/Vtst-Scripts/nebmake.pl CONTCAR-IS CONTCAR-TS $NumImgf
  last=$(($NumImgf+1));first=10  ;while [ "$last" -ge "$first" ]; do j=$(($last+1)); mv $last $j; last=$(($last-1)); done
  last=9;first=0  ;while [ "$last" -ge "$first" ]; do j=$(($last+1)); mv 0$last 0$j; last=$(($last-1)); done; mv 010 10
  rm CONTCAR*
  for i in *; do cd $i; cp ../../Template*/{INCAR,KPOINTS,POTCAR,header.POSCAR,job-*} . ; sed -i '1,5d' POSCAR; cat header.POSCAR POSCAR > ali; mv ali POSCAR; cd ../; done 

# Creating Images from TS FS
cd ../TS-to-FS/
  perl ~/Vtst-Scripts/nebmake.pl CONTCAR-TS CONTCAR-FS $NumImgr
  last=$(($NumImgr+1));first=10  ;while [ "$last" -ge "$first" ]; do j=$(($last+1)); mv $last $j; last=$(($last-1)); done
  last=9;first=0  ;while [ "$last" -ge "$first" ]; do j=$(($last+1)); mv 0$last 0$j; last=$(($last-1)); done; mv 010 10
  rm CONTCAR*
  for i in *; do cd $i; cp ../../Template*/{INCAR,KPOINTS,POTCAR,header.POSCAR,job-*} . ; sed -i '1,5d' POSCAR; cat header.POSCAR POSCAR > ali; mv ali POSCAR; cd ../; done
cd ../ 


echo $'\n' everything is ready for you, to make sure evergything is correct I recommend $'\n'
echo       to check all directories, headers, sdiff random POSCARs, check NSW in INCAR, check that you have $'\n'
echo       all files inside each directory, the number of directories, anchor atoms, the number of Fixed atoms, $'\n'
echo       the number of relaxed atoms and so on $'\n'
