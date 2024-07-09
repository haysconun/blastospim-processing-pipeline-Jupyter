
# BLASTOSPIM Segmentation and Tracking Pipeline (Jupyter notebook running on CPU)

## Step 1: Installing MATLAB & Python and downloading sample files

### Download code via git clone (from terminal).

```
git clone https://github.com/haysconun/blastospim-processing-pipeline-Jupyter
```

TODO: make this into an FI or Princeton git repo.

### Install Python 3.9, pip, and MATLAB.
Note: Installing any other version of python will likely result in errors during subsequent installation steps.

pip should be automatically installed with Python 3.9, but if it is not, install pip.

Download and install MATLAB.

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

### Download sample data and Stardist-3D models (by running python script).
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

### In notebook, in Cell 1, replace /path/to/your/blastospim-processing-pipeline-Jupyter/ with your specific path
```
path_to_code = '/path/to/your/blastospim-processing-pipeline-Jupyter/'
```

### Optional: In notebook, in Cell 5, replace the timepoint = '24' with your chosen time index to display.

### In notebook, in Cell 6, replace the call to MATLAB with the appropriate call for your operating system
```
!/Applications/MATLAB_R2022a.app/bin/matlab -nosplash -nodesktop -r "1+1 == 2; exit"
```

For Linux, you should be able to replace /Applications/MATLAB_R2022a.app/bin/matlab with matlab.

For mac, you should replace /Applications/MATLAB_R2022a.app/bin/matlab with the path to the matlab installation on your machine.

For the rest of the matlab calls, replace /Applications/MATLAB_R2022a.app/bin/matlab accordingly.

### In notebook, Cell 7 is a reminder to open the config.yaml from within the Jupyter interface and ensure the settings there are correct for registration and tracking.

output_dir specifies where the results are written out.

After the full notebook is run, the file ending in '_graph.mat' saves the lineage tree.

'combined_mat_..._....csv' saves aligned point clouds from consecutive timepoints.

'node_info_..._....csv' show nuclear centroids (aligned from timepoint to consecutive timepoint).

'test_transforms.json' saves information about the rigid transformation estimated during registration (from timepoint to the following timepoint).

### Note potential issue for Cell 8: setup CPD

If running the lineage construction script fails because of an error with respect to compilation of code. See below.

1. Open MATLAB and navigate to the code directory called `lineage_track`. Then add the `CPD2` folder and subfolders to PATH. 

2. Then navigate inside the `CPD2` directory and run the command:

```
cpd_make
```

*On MAC OSX you will need to install Xcode from the App store and run Xcode once to accept the license aggrement.*

### Cells 10, 11 (OPTIONAL): visualize 3D point clouds for two adjacent timepoints

Specify timeindex1, the first time index in a pair of consecutive frames.

This loads results from Cell 9.

### Note potential issue

This has only been tested for mac and linux machines.

## Correction of segmentation and tracking

See documentation of ImageJ plugin tool AnnotatorJ version 1.6 ( https://github.com/PrincetonUniversity/blastospim-processing-pipeline ).

Tree visualization and correction tool -- Aaron's?

TODO: Enable some limited visualization of the tracking within the Jupyter notebook

# Training BlastoSPIM-trained models on other Ground-truth Datasets (Jupyter notebook running on GPU)

## WARNING: install procedure depends on configuration of your university / institute's computing environment

You need a device with cuda-capable GPU(s) for this fine-tuning notebook.

This assumes that you have installed requirements as outlined in the steps above (pip installing requirements).

The commands below specify how a jupyter notebook is run on the Flatiron cluster (rusty). 

Because it is not possible to predict how other universities / institutes might manage their jupyter environments (for example, via JupyterHub), these Flatiron-specific steps are not meant to be totally prescriptive. Instead, they are meant to guide the user to consult their own university / institute's documentation for running Jupyter notebooks on GPUs.

If the user is unable to launch Jupyter lab to run on a machine with GPU(s), the user should consult our other documentation (ADD LINK HERE) for how to train neural networks via SLURM script (using sbatch).

## Download sample data and models for training.

```
source path/to/venv/bin/activate

cd path/to/your/blastospim-processing-pipeline-Jupyter

python3 download_data_and_models_for_finetune.py
```

2022_64x256x256_Platynereis contain the example data for finetuning the model.

models_for_finetuning contain copies of our models (for training them further on the Platynereis data.

data_for_evaluating_finetune contains other Platynereis ground-truth data for evaluating the models.

## Download jupyter notebooks for finetuning and evaluating

TODO: These will actually be included in this same git repo. (both the finetuning and evaluating)
TODO: Probably include MakeTrainSet function
TODO: Put these codes in their own directory in git repo

## Guide to loading jupyter notebook properly on Flatiron Cluster

```
module load modules/2.2-20230808

module load gcc/11.4.0 python3

module load slurm cuda/11.8.0 cudnn/8.9.2.26-11.x
```

### Replace path/to/venv below with your chosen path and name of your virtual environment!!

```
source path/to/venv/bin/activate

module load jupyter-kernels
```

### Replace kernel_name_finetune with the chosen name of your kernel.

```
python -m make-custom-kernel kernel_name_finetune
```

### Open jupyter hub, request gpu, and choose kernel

Load from your internet browser 

```
https://jupyter.flatironinstitute.org/
```

For the environment, select "jupyterlab (modules/2.2)".

For the job, select "gpu node (4 hours)".

Click Start.

Open the jupyter notebook for finetuning.

Choose the kernel you made above ( see the make-custom-kernel command above ) in the top right.

Evaluate the cells to fine-tune on an example dataset.

