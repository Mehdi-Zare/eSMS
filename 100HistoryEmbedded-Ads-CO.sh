#!/bin/bash -x

head -1576802 ../HISTORY > HISTORY               # Get all HISTORY file(100 conformations)
head -2464 HISTORY | tail -2458 > head.QM        # Get 1229 Pt atoms(the first 6 lines is header=1229x2+6=2464)
tail -106  HISTORY > tail.QM                     # Get QM atoms ((51Pt+3ads(C+O))x2=106

#sed -i -e '1,2d' HISTORY
head -1576802 HISTORY | tail -1576800 > New.HISTORY  # Get all conformations without header(2 lines)
mv New.HISTORY HISTORY

# next line would get all lines corresponding to water atoms (delete all lines start with "O", "C" "Pt"
sed -i -e '/timestep/,+3 d' -i -e '/Pt/,+1 d' -i -e  '/^C /,+1 d' -i -e  '/^O /,+1 d'  HISTORY
cat head.QM HISTORY tail.QM > HISTORY.mix # This is for making embedded in this order: 1229MMPt...(6600x2x100=)1320000Water...(51x2+2x2)=106QMcluster

cp ConfigTypeEmbeddedHead HISTORY.finale
awk 'NR==1 {A=$2} NR%2 {$2=A++} 1' OFS="\t"   HISTORY.mix >> HISTORY.finale

dlpoly-relocate-config-coordinates -f HISTORY.finale > CONFIG.last       # relocate HISTORY format with header.CONFIG to have CONFIG format
dlpoly-convert-config-to-geometry-xyz -f CONFIG.last -k 0 -p > image.last  # convert config format to xyz

cat head.embedded > embedded    # First, header of embedded file 
tail -n 661282 image.last | head -n 661229 >> embedded  # Second, adding 1229 Pt, and 6600x100 water : Get the tail part(1229Pt+6600x100+51+2=661282) and then head of that tail 
tail -n 53 image.last >> embedded     #(Adding QM atoms (51+2)            
cat mid.embedded >> embedded
tail -n 53 image.last >> embedded     # Adding QM atoms again at the end of embedded
echo "  end" >> embedded

sed -i 's/^Pt/Qs/g' embedded
sed -i 's/^C /Cx/g' embedded
sed -i 's/^O /Ox/g' embedded

## Clean up the mess, save diskspace, save yourself 
## from the wrath of TACC

rm HISTORY* tail.QM head.QM 

