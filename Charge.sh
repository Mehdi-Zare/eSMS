#!/bin/sh 


# this script will replace the charges wich are in CHARGES file already to in the FIELD file
# it is specifilcyat written for CO adsorbed on the 51 metal atoms 

cp FIELD_TEMPLATE FIELD;

for i in {01..53}
	do atom=`head -n$i CHARGES | tail -1`
	if [ $( echo "$atom >= 0" | bc) -eq 1 ]; then
		sed -i "s/MMS_ATOM_0000$i/ $atom/g" FIELD    #if the number was negative, it would put a space before that
	else
		sed -i "s/MMS_ATOM_0000$i/$atom/g" FIELD
	fi
done
