#!/bin/bash -x

head -1578402 ../HISTORY > HISTORY
head -2464 HISTORY | tail -2458 > head.QM
tail -122  HISTORY > tail.QM

#sed -i -e '1,2d' HISTORY
head -1578402 HISTORY | tail -1578400 > New.HISTORY
mv New.HISTORY HISTORY

sed -i -e '/timestep/,+3 d' -i -e '/Pt/,+1 d' -i -e  '/^C /,+1 d' -i -e  '/^O /,+1 d' -i -e  '/^H /,+1 d' HISTORY
cat head.QM HISTORY tail.QM > HISTORY.mix

cp ConfigTypeEmbeddedHead HISTORY.finale
awk 'NR==1 {A=$2} NR%2 {$2=A++} 1' OFS="\t"   HISTORY.mix >> HISTORY.finale

dlpoly-relocate-config-coordinates -f HISTORY.finale > CONFIG.last
dlpoly-convert-config-to-geometry-xyz -f CONFIG.last -k 0 -p > image.last

cat head.embedded > embedded
tail -n 661290 image.last | head -n 661229 >> embedded
tail -n 61 image.last >> embedded
cat mid.embedded >> embedded
tail -n 61 image.last >> embedded
echo "  end" >> embedded

sed -i 's/^Pt/Qs/g' embedded
sed -i 's/^C /Cx/g' embedded
sed -i 's/^O /Ox/g' embedded
sed -i 's/^H /Hx/g' embedded

## Clean up the mess, save diskspace, save yourself 
## from the wrath of TACC

rm HISTORY* tail.QM head.QM 

