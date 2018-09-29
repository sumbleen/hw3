#!/bin/bash
for i in `seq 5`; do
RSFgen \
	-nt 300 \
	-num_stimts 3 \
	-nreps 1 20 \
	-nreps 2 20 \
	-nreps 3 20 \
	-seed  $i \
	-prefix stim_${i}_

make_stim_times.py \
	-files stim_${i}_*.1D \
	-prefix stimt_${i} \
	-nt 300 \
	-tr 1 \
	-nruns 1

3dDeconvolve -nodata 300 1 -polort 1 \
	-num_stimts 3 \
	-stim_times 1 stimt_${i}.01.1D 'GAM' -stim_label 1 'A' \
	-stim_times 2 stimt_${i}.02.1D 'GAM' -stim_label 2 'B' \
	-stim_times 3 stimt_${i}.03.1D 'GAM' -stim_label 3 'C' \
	-gltsym "SYM: A -B" -gltsym "SYM: A -C" > 3dDeconv.stimt_${i}.output.txt

eff=`python scripts/efficiency_parser.py 3dDeconv.stimt_${i}.output.txt`

echo "$eff $i" >> seed_eff_out.txt
done
sort -n -k 1 seed_eff_out.txt > sorted_output.txt
best_design=(`head -n 1 sorted_output.txt`)

# ${best_design[1]}