# Gif_generator_3view_data
This is an ImageJ script that I have written to generate gifs from the data stacks that I have generated on the Gatan 3view.


The script is not perfect, but it works fine for what I need.

The general concept is that I have too many 3view data stacks (as well as odd images dotted around), but I want to be able
to find an old data stack visually.
The script is meant to scan through all of my folders and create a gif for each folder that it examines.  The gif will contain
all of the dm4 images in tha folder and will play for approx 5seconds.
Some header information is also collected for each gif based on the data that was examined. 

The current script assumes that hte folder structure is the way that i have mine setup

My folder structure has a base folder called something like "3view Data"
within this folder are subfolders, each one representing an individual user.
Each user folder has a range of sub folders, or raw data depending on how their project evolved.

Therefore the current script does not look for images in the first folder examined.  
The script copies the sub folders from the first folder examined (re-generating these folders in the output folder).
It then works through all of the sub-folders recursively to generate a gif per sub-folder (and sub-sub etc).
It also generates one gif-information files per user folder.

Hopefully the comments in the gif 
