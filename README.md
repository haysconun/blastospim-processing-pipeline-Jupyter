
# BLASTOSPIM Instance Segmentation and Tracking Pipeline (Jupyter notebook) for your own machine (no GPU)

## Step 1: Installing MATLAB & Python and downloading sample files

### Download sample data and Stardist-3D models.

### Download code via git clone.

### Download and install MATLAB.

### Make sure that you have installed Python 3.9.

### pip should be automatically installed with Python 3.9, but if not, install pip.

## Step 2: Make virtual environment, pip install requirements, & open Jupyter.

### Install virtualenv, if not already installed.

### In terminal, create a new virtual environment AND check the python version of the virtual environment.

### Install Jupyter lab or notebook AND load
pip install jupyterlab
jupyter lab



# BLASTOSPIM Instance Segmentation and Tracking Pipeline (Jupyter notebook)

## Step 1: Installing dependencies and downloading sample files


### On the Flatiron cluster, MATLAB is already installed and can be loaded by "module load matlab" (see below)

### Download sample data files and code necessary for segmentation and tracking.
### Just download the whole folder ( revised_code_for_pipeline ) at one time
### [I currently have these stored in a google drive, but they will be loaded into an updated git repo so that git clone can be used.]

### Different versions of python and pip are already installed
### virtualenv is already installed

### The command above should make a virtual environment and store it in your current directory
### This uses the path to python 3.9 installation 
### can be found by using module avail (to find the python 3.9 installation name) then module show
virtualenv -p /mnt/sw/nix/store/lq18vwc5g47301xpm32i8hx1z2n199bd-python-3.9.16-view/bin/python3.9 pyenvname_blastospim_39

### The command above activates your virtual environment
source pyenvname_blastospim_39/bin/activate

### Install requirements via pip
### replace the path with the actual path to the requirements file you downloaded
pip install -r /path/to/requirements_file.txt
pip install git+https://github.com/bhoeckendorf/pyklb.git@skbuild

## Step 2: Set up custom kernel and load Jupyter
pip install ipykernel

### Make custom kernel.
### [make sure your virtual environment is activated]
### Replace mykernel below with whatever you would like to call it.
module load gcc python3 matlab
source /mnt/home/hnunley/pyenvname_blastospim_39_again/bin/activate
module load jupyter-kernels
python -m make-custom-kernel mykernel

### Load JupyterHub and locate the notebook
https://jupyter.flatironinstitute.org/

## Step 3: Run the cells in the Jupyter notebook

### Once jupyter lab loads, open the .ipynb that I provided.
### pipeline_notebook.ipynb in revised_code_for_pipeline
### There should be an option at the top right of the notebook to choose a kernel.
### Select your custom kernel you just made.
### Follow the instructions in the Jupyter notebook
### Code may output some warnings; that is okay.
### Check that it can segment, register and track.
