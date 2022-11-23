# Data

Store your data in one or more sub-directories within `raw` or `intermediate` (intermediate data are generated
from raw data, and subsequently used for further analysis). For each first level sub-directory within `raw` and `intermediate`, there should be an entry in the file `data_source_list.csv`. This file describes where the data can be found (e.g. Zenodo, OneDrive, directly tracked by git, etc.). 

By default, the git repository does not track data files (as they are often too large for git), and each sub-directory should have a remote source that will allow others using the repository to get the data. There should be one source for each first level subdirectory (e.g. `/data/raw/default` or `/data/intermediates/rnaseq`); you are then free to further structure (or not) your data within multiple, higher level sub-directories within each first level sub-dir. If your datasets are small and stored as text files, you might decide to track them within your git repository. In that case, set the "source"" and "url"" as "git" in the `data_source_list.csv` table for that sub-directory, and edit appropriately `.gitignore`.

Note that no files should be stored directly in `raw` or `intermediate`, they should always be put in a first level sub-directory. The template has a `default` subdir in 'data', but you are free to remove it and create alternative sub-directories; just make sure that the `data_source_list.csv` table is updated accordingly. If you are not generating any intermediate data, you can simply ignore `intermediate`.

For better compatibility across file systems, avoid using spaces (use underscores instead) or special symbols.
