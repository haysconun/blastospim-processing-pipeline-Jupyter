
# BLASTOSPIM Instance Segmentation and Tracking Pipeline (Jupyter notebook running on CPU)

## Step 1: Installing MATLAB & Python and downloading sample files

### Download code via git clone (from terminal).

```
git clone https://github.com/haysconun/blastospim-processing-pipeline-Jupyter
```

TODO: make this into an FI or Princeton git repo.

### Install Python 3.9 and pip, if not installed.
Installing any later version of python will likely result in errors during later installation steps.

pip should be automatically installed with Python 3.9, but if not, install pip.

### Download and install MATLAB.
Learn how to run MATLAB from terminal.

https://www.mathworks.com/help/matlab/ref/matlabmacos.html.   [for Mac]

https://www.mathworks.com/help/matlab/ref/matlablinux.html    [for Linux]

Within the Jupyter notebook, you will replace the matlab command by whatever the local path is to that matlab executable on your machine.
Check that this works by running a matlab command from terminal like:

```
matlab -nosplash -nodesktop -r "1+1 == 2; exit"
```

For example, on a mac, you will likely have to change directory to your local installation of matlab.
Then, from that directory, run:

```
./matlab -nosplash -nodesktop -r "1+1 == 2; exit"
```

There is a test example in the jupyter notebook.

## Step 2: Make virtual environment, pip install the requirements file, & open Jupyter.

### Make a virtual environment (with Python 3.9)
In terminal, create a new virtual environment.
Replace path/to/venv below with your chosen path and name of your virtual environment -- this will create a new folder.

```
python3.9 -m venv path/to/venv
```

### Activate your virtual environment and check python version.
The command below activates your python environment. Replace path/to/venv below with your chosen path and name of your virtual environment.

```
source path/to/venv/bin/activate

python --version
```

### pip install from requirements file. Replace the /path/to/requirements_file.txt with the path to the requirements in your cloned directory.
```
pip install -r /path/to/requirements_file.txt
```

### Optional install: pip install pyklb.
```
pip install git+https://github.com/bhoeckendorf/pyklb.git@skbuild
```

Note: pyklb may not install correctly on your machine, but this is only required for reading and writing images in the klb format.

### Optional install: visualization code. See https://github.com/AaronWatters/volume_gizmos for more details.
```
git clone https://github.com/AaronWatters/volume_gizmos

cd volume_gizmos

pip install -e .
```

### Change directory to cloned directory. Replace path/to/your/blastospim-processing-pipeline-Jupyter with the path to your cloned folder.
```
cd path/to/your/blastospim-processing-pipeline-Jupyter
```

### Download sample data and Stardist-3D models (by running python script) -- probably change google drive link to blastospim link for data
```
python3 download_data_and_models.py
```

TODO: change google drive link to blastospim link for data

### Install Jupyter lab or notebook AND open jupyter while your virtual environment is activated.
```
pip install jupyterlab

jupyter lab
```

### Open the jupyter notebook called 'pipeline_notebook.ipynb'

Evaluate the cells in the notebook to perform segmentation and tracking on the sample data.

### In notebook, in the first cell, replace /path/to/your/blastospim-processing-pipeline-Jupyter/ with your specific path
```
path_to_code = '/path/to/your/blastospim-processing-pipeline-Jupyter/'
```

TODO: minimize number of specified paths
TODO: suppress output from the volume_track_nuclei_divisions code 


### Potential issue: setup CPD

If running the lineage construction script fails because of an error with respect to compilation of code. See below.

1. Open MATLAB and navigate to the code directory called `lineage_track`. Then add the `CPD2` folder and subfolders to PATH. 

2. Then navigate inside the `CPD2` directory and run the command:

```
cpd_make
```

*On MAC OSX you will need to install Xcode from the App store and run Xcode once to accept the license aggrement.*

