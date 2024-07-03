
# BLASTOSPIM Instance Segmentation and Tracking Pipeline for your own machine (Jupyter notebook running on CPU)

## Step 1: Installing MATLAB & Python and downloading sample files

### Download code via git clone (from terminal) -- probably port this into an FI or Princeton git repo
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

For example, on a mac, you will likely have to change directory to your local installation of matlab. --TODO code example
Then, from that directory, run:
./matlab -nosplash -nodesktop -r "1+1 == 2; exit"

## Step 2: Make virtual environment, pip install requirements, & open Jupyter.

### Install virtualenv, if not already installed.
https://virtualenv.pypa.io/en/latest/installation.html

### In terminal, create a new virtual environment AND check the python version of the virtual environment.
### When creating the virtual environment, replace the path /path/to/your/python39/installation with the actual path to your python 3.9 installation.
virtualenv -p /path/to/your/python39/installation pyenvname_39
MAYBE REPLACE virtualenv for ease of use

### Activate your new virtual environment and check python version
source pyenvname_39/bin/activate

python --version

### pip install from requirements file. Replace the /path/to/requirements_file.txt with the path to the requirements in your cloned directory.
pip install -r /path/to/requirements_file.txt

### Separately, pip install pyklb. pyklb may not install correctly on your machine, but this is NOT required. If this install fails, ignore. 
pip install git+https://github.com/bhoeckendorf/pyklb.git@skbuild

### Change directory to cloned directory.
cd blastospim-processing-pipeline-Jupyter

### Download sample data and Stardist-3D models (by running python script) -- probably change google drive link to blastospim link for data
python3 download_data_and_models.py

### Install Jupyter lab or notebook AND load
pip install jupyterlab

### Open an instance of Jupyter
jupyter lab

### Open the jupyter notebook called 'pipeline_notebook.ipynb'
### Evaluate the cells in the notebook to perform segmentation and tracking on the sample data.

# BLASTOSPIM Instance Segmentation and Tracking Pipeline (Jupyter notebook) for a machine with GPUs

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
