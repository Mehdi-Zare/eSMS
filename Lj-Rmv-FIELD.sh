#!/bin/sh

# This script is written by Mehdi Zare
# it provide FIELD files for removing Lennard jones potential

# adding delat value
 for i in {011..029} 030-LJ-OFF/; do cd $i/03*;sed -i "s/C    Ow   slj    0.264   3.491    0.000   0.000/C    Ow   slj    0.264   3.491    0.000  12.184/" FIELD; cd ../../; done
 for i in {011..029} 030-LJ-OFF/; do cd $i/03*;sed -i "s/O    Ow   slj    0.651   3.136    0.000   0.000/O    Ow   slj    0.651   3.136    0.000   9.831/" FIELD; cd ../../; done

# Adding lambda value 

j=0
for i in {011..029} 030-LJ-OFF/;
  do cd $i/03*
  j=`echo $j + 0.050 | bc`
  sed -i "s/C    Ow   slj    0.264   3.491    0.000  12.184/C    Ow   slj    0.264   3.491    0$j  12.184/" FIELD
  sed -i "s/O    Ow   slj    0.651   3.136    0.000   9.831/O    Ow   slj    0.651   3.136    0$j   9.831/" FIELD
  cd ../../
 done



