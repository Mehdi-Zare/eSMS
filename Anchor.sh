#!/bin/bash

echo  $'\n' please enter your  anchor atom numbers, I am assuming you want to anchor two atoms 
read num1
read num2

if [ "$num1" == "0"  ] || [ "$num2" == "0"  ]; then
   echo you cannot have zero value for the number
   exit 1
fi

for i in $num1 $num2

do line=$((10+$i-1))

echo  $'\n' do you want to fix x coordinate, y coordinate or both coorintates of atom $i , 1 for x, 2 for y, and 3 for both
read coord

if [ "$coord" == "1"  ]; then
       sed -i "$line s/T   T   T/F   T   T/" CONTCAR-IS
       sed -i "$line s/T   T   T/F   T   T/" CONTCAR-FS
       sed -i "$line s/T   T   T/F   T   T/" CONTCAR-TS
elif [ "$coord" == "2"  ]; then
       sed -i "$line s/T   T   T/T   F   T/" CONTCAR-IS
       sed -i "$line s/T   T   T/T   F   T/" CONTCAR-FS
       sed -i "$line s/T   T   T/T   F   T/" CONTCAR-TS
elif [ "$coord" == "3"  ]; then
       sed -i "$line s/T   T   T/F   F   T/" CONTCAR-IS
       sed -i "$line s/T   T   T/F   F   T/" CONTCAR-FS
       sed -i "$line s/T   T   T/F   F   T/" CONTCAR-TS
fi

done
