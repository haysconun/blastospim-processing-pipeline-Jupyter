
# BLASTOSPIM Instance Segmentation and Tracking Pipeline for your own machine (Jupyter notebook running on CPU)

## Step 1: Installing MATLAB & Python and downloading sample files

### Download code via git clone (from terminal) -- TODO: probably make this into an FI or Princeton git repo
git clone https://github.com/haysconun/blastospim-processing-pipeline-Jupyter

### Install Python 3.9, if not installed.
### pip should be automatically installed with Python 3.9, but if not, install pip.

### Download and install MATLAB.
### Learn how to run MATLAB from command line
https://www.mathworks.com/help/matlab/ref/matlabmacos.html.   [for Mac]

https://www.mathworks.com/help/matlab/ref/matlabwindows.html  [for Windows]

https://www.mathworks.com/help/matlab/ref/matlablinux.html    [for Linux]

Within the Jupyter notebook, you will replace the matlab command by whatever the local path is to that matlab executable on your machine.
Check that this works by running a matlab command from terminal like:
matlab -nosplash -nodesktop -r "1+1 == 2; exit"

For example, on a mac, you will likely have to change directory to your local installation of matlab. TODO: code example
Then, from that directory, run:
./matlab -nosplash -nodesktop -r "1+1 == 2; exit"

The way that the single line (in the screenshot) works is: open matlab and passes it a line of code to run and exits (all at once).
There is a test example in the jupyter notebook below.

## Step 2: Make virtual environment, pip install requirements, & open Jupyter.

### make a virtual environment (with Python 3.9)
### In terminal, create a new virtual environment AND check the python version of the virtual environment.
### Replace path/to/venv with the path and name of your virtual environment -- this will create a new folder
### Then, your new virtual environment and check python version
python3.9 -m venv path/to/venv

source path/to/venv/bin/activate

python --version

### pip install from requirements file. Replace the /path/to/requirements_file.txt with the path to the requirements in your cloned directory.
pip install -r /path/to/requirements_file.txt

### Optional: pip install pyklb. pyklb may not install correctly on your machine, but this is NOT required. If this install fails, ignore. 
pip install git+https://github.com/bhoeckendorf/pyklb.git@skbuild

### Change directory to cloned directory. Replace path/to/your/blastospim-processing-pipeline-Jupyter with the path to your cloned folder.
cd path/to/your/blastospim-processing-pipeline-Jupyter

### Setup CPD 

1. Open MATLAB and navigate to the code directory called `lineage_track`. Then add the `CPD2` folder and subfolders to PATH. 

2. Then navigate inside the `CPD2` directory and run the command:

```
cpd_make
```

*On MAC OSX you will need to install Xcode from the App store and run Xcode once to accept the license aggrement.*

### Optional: install visualization code. See https://github.com/AaronWatters/volume_gizmos
git clone https://github.com/AaronWatters/volume_gizmos
cd volume_gizmos
pip install -e .

### Download sample data and Stardist-3D models (by running python script) -- probably change google drive link to blastospim link for data
python3 download_data_and_models.py

### Install Jupyter lab or notebook AND load
pip install jupyterlab

### Open an instance of Jupyter
jupyter lab

### Open the jupyter notebook called 'pipeline_notebook.ipynb'
### Evaluate the cells in the notebook to perform segmentation and tracking on the sample data.

### In notebook, replace with appropriate paths.
