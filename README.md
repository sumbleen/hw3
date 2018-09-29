# Homework 3
Due by midnight of 9/17.

## General directions
As usual, fork this repository, clone your fork, add and commit your changes, push, and open a pull request to submit your work.

For each question (Q#), write a short narrative answer. Your answers should be written in [Markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) and saved in a `README.md` file in a `results` subdirectory of this repository. Clearly indicate question numbers by using headings.

For Mac users, you can use [MacDown](https://macdown.uranusjr.com) to see how the document will be formatted. For Windows (or Mac) users, Siri recommends [Texts](http://texts.io).


## Part I: Using RSFgen

### Write the loop

Complete a slightly improved version of the script we started in class by write a shell script `rsf_gen_timing_01.sh` that:

1. Generates a random stimulus order
2. Converts the RSFgen output to times
3. Evaluates the design using 3dDeconvolve (redirecting the output to a file)
4. Runs the provided `efficiency_parser.py` script on the 3dDeconvolve output file. This script will parse the 3dDeconvolve output and print out the average efficiency of any contrasts you have specified. 
5. Prints out two columns for each design, the first containing the efficiency and the second containing the seed. Hint: Use `` ` ` `` to store the output `efficiency_parser.py` in a variable. You can print the required values with something like `echo "$efficiency $i"`. 
5. Takes a command line argument (e.g. `$1`) that specifies the number of times to run the loop. The loop should run over the integers from 1 to $1.


Make sure you organize your files so that:

- Scripts are in the `scripts` directory
- Intermediate output files are saved in `times`
- Your results are saved in `results`

The relevant commands from class are:

```bash
RSFgen \
-nt 300 \
-num_stimts 3 \
-nreps 1 20 \
-nreps 2 20 \
-nreps 3 20 \
-seed N \
-prefix stim_
```

```bash
make_stim_times.py \
-files stim_*.1D \
-prefix stimt \
-nt 300 \
-tr 1 \
-nruns 1
```


```bash
3dDeconvolve -nodata 300 1 -polort 1 \
-num_stimts 3 \
-stim_times 1 stimt.01.1D 'GAM' -stim_label 1 'A' \
-stim_times 2 stimt.02.1D 'GAM' -stim_label 2 'B' \
-stim_times 3 stimt.03.1D 'GAM' -stim_label 3 'C' \
-gltsym "SYM: A -B" -gltsym "SYM: A -C" 
```


### What is the best design?
Run your `rsf_gen_timing_01.sh` script for 500 iterations. Your script should print out the efficiency and random seed (on the same line) for each iteration. You should save this output to a file. Identify the best design and corresponding random seed.

HINT: You can sort the first column of a file in numeric order with `sort -n -k 1`. `tail` and `head` can be used to select the last or first line of the sorted output.

Rerun `RSFgen` with the best seed and adding the `-one_file` option. This will create a single `1d` file with the stimuli onsets in three columns, one per condition.

Plot this design using

```bash
1dplot -one -png design.png stim.1D

```
where `stim.1D` is your file produced by `RSFgen` with the `-one_file` option. `design.png` will show when each stimulus occurs.

**Q1**: What do you observe about the timing structure of the best design? Why is this? It may be helpful to plot some of the less efficient designs for comparison.

## Part II: `make_random_timing.py`

While completing Part I you may have noticed some undesirable limitations of `RSFgen`. Most of these are addressed in the more sophisticated `make_random_timing.py` command from AFNI. With `make_random_timing.py`, we can:

- specify ordering constraints on different conditions
- create designs that are not timelocked to the TR
- control the minimum and maximum ISI
- and more! (run `make_random_timing.py -help` for details)


### Reproduce RSFgen

The command

```bash
make_random_timing.py -num_stim 3 -num_runs 1 \
-run_time 300 \
-stim_labels A B C \
-num_reps 20 \
-prefix stimt \
-stim_dur 1 \
-seed N
```

will reproduce your `RSFgen` results. With `make_random_timing.py`, the outputs will be stimulus onset times, so the `make_stim_times.py` step is not necessary. Note that the files be named differently (including the condition labels, rather than condition numbers).

Create a new script `mrt_timing_01.sh` that replicates Part 1 using `make_random_timing.py` instead of `RSFgen`.

### Control ITI
`make_random_timing.py` permits control over the the interval between trials. In `make_random_timing.py`, the ITI can be controlled by setting a stimulus duration (`-stim_dur`) and a minimum and maximum rest duration between trials (`-min_rest`, `-max_rest`). The ITI then ranges from `stim_dur` + `min_rest` to `stim_dur` + `max_rest` 

Copy your `mrt_timing_01.sh` script to a new file and modify the script to generate timings for trials with a 2 second stimulus duration and 1 to 5 seconds of rest following the stimulus (so the mean trial duration is approximately 5 seconds).

Run your script for 5,000 iterations and plot the best design. You can create a file containing a single column of all events using

```bash
timing_tool.py -multi_timing mrt_times/stimt_${i}_*.1D \
-multi_timing_to_events mrt_times.1d -tr 1 -multi_stim_dur 1 \
-min_frac .5  -run_len 300
```

where `mrt_times/stimt_${i}_*.1D` is an expression matching the desired timing files.


**Q2**: What do you observe about the timing structure of the best design compared to the best `RSFgen` design? Why is this?



### Limit the number of repetitions
We often want to pseudorandomize condition order so that runs of consecutive stimuli of the same type are shorter than they would be [by chance](https://en.wikipedia.org/wiki/Gambler%27s_fallacy).

The `-max_consec` option to `make_random_timing.py` can be used to limit the number of consecutive presentations of the same stimulus type. This can be specified as either a single limit for all classes (e.g. `-max_consec 2`) or a limit for every class (e.g. `-max_consec 2 2 2`). Rerun your script, adding the option `-max_consec 1`, which will eliminate runs of stimuli from the same condition.

**Q3**: What do you observe about the timing structure of the best design compared to the best `RSFgen` design? Why is this?

**Q4**: What generalizations can you make about optimal designs from your observations in Q1-3?


Note:
It is generally easier to use `make_random_timing.py` for generating timing files but `RSFgen` does allow more precise control over the conditional probabilities between different stimulus types via the `-markov` option, which allows you to specify a transition probability matrix.


## Part 3: Block Designs

### Defining block designs
AFNI uses stimulus timing files that specify the onsets of the stimuli or blocks in seconds as a space-separated list, one row per run and one file per condition. For this part, you may find it easiest to create the required timing files by hand. An example of the required timing files for 50 second blocks is in `block_times`.

To evaluate the efficiency of a block design, we modify the `3dDeconvolve` command to convolve onsets with a step function instead of an HRF.

The critical change is to substitute `'GAM'` with `BLOCK(t)`, where `t` is the length of the block in seconds. For example, the line

```
-stim_times 1 stimt.01.1D 'GAM' -stim_label 1 'A' \
```

would change to 

```
-stim_times 1 stimt.01.1D 'BLOCK(20)' -stim_label 1 'A' \
```

for a 20 second block.



### Evaluate block designs

Construct blocks of 20, 50, and 100 seconds and evaluate the efficiency of the A-B and A-C contrasts. In each case, order the blocks as ABC, repeating as needed, and keep the total duration of each condition constant (i.e. 1 100 second block for each condition or 5 20-second blocks for each condition). Each design should have the same duration (300 seconds) and TR (1 second).

**Q5**: How does design efficiency for each of the contrasts change using different block durations? Is there an efficiency difference for A-B vs A-C? Why?

**Q6**: Using a block duration of 50 seconds, change the value of the `-polort` `3dDeconvolve` option to 2, 6 and 12 and compare the efficiency of these three cases. What do you think the `-polort` option does and why does this change the efficiency? Would the same pattern emerge for a block duration of 20 seconds?

Include your block design timing files and `3dDeconvolve` commands in your submission.


---
*Do not use simulations to answer the last two questions.*


**Q7**: You want to design an experiment that contrasts *2* different visual conditions. In general terms, what is the best design for this experiment? Why?

**Q8**: You want to design an experiment that contrasts *7* different visual conditions. In general terms, what is the best design for this experiment? Why?


## Part 4: Start Learning Python

Although shell scripting is a useful tool that we will continue to rely on, some things are better done in a more powerful language such as Python. Complete the free modules of the [Python Code Academy course](https://www.codecademy.com/learn/learn-python). 

Your homework will use a Python script, but it is not necessary for you to know Python or complete the course before attempting the rest of the homework. You do not need to finish the course by the due date and should prioritize completing Parts 1-3 on time.


