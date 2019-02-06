#!/bin/bash


#####  This code collect the energy and Temperature from STATIS file fo a DL_POLY calculations   #####
#####  It is written by Mehdi Zare in 6/29/2018  ####
touch ENERGY
echo "  E(Kjule/m)               T" >  ENERGY
nline=`wc -l  STATIS | awk '{print $1}'`
l=$(($nline-8))
for i in $(seq 4 10 $l); do echo $i; sed -n "${i}p"  STATIS > ali ; awk '{ print $1"     "$2}' ali  >> ENERGY; rm ali; done
