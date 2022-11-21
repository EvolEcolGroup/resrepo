# Code

The code for your analysis goes here. Scripts should use relative paths to find data (e.g. `../data/raw/defaults/my_data.txt`) as well as to write to results (e.g. `../results/Fig_1png`).
If you have many scripts, it is often better to have them writing results into separate sub-directories
under `results`, as it helps tracking where each result file comes from. This strategy also allows to have a simple command at the beginning of a script which wipes the results directory before generating the new set of results (thus avoiding the risk of having old files from obsolete analysis floating around the repository)

It is good practice to add a metafile that tells what every script does (e.g. you can add this info here in the readme).
