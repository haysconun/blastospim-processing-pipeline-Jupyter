import zipfile
from zipfile import ZipFile
import gdown
import os
import tarfile
import requests, io

cwd = os.getcwd()
path = 'models_for_finetuning'
path = os.path.join(cwd, path) 
os.mkdir(path)
os.chdir(path)

## specify link from which to download both models
## Download early model
r = requests.get("https://blastospim.flatironinstitute.org/html/early_embryo_model.zip")
z = zipfile.ZipFile(io.BytesIO(r.content))
z.extractall('.')

## Download late model
r = requests.get("https://blastospim.flatironinstitute.org/html/late_blastocyst_model.zip")
z = zipfile.ZipFile(io.BytesIO(r.content))
z.extractall('.')

os.chdir(cwd)

## These links should probably hosted from Flatiron or Princeton
## specify link from which to download necessary data
all_data_link = 'https://drive.google.com/uc?export=download&id=15KgatcUbHQfvygwHc-8m5wNDhNBF6JPk'
output = "data_for_finetune.zip"
gdown.download(url=all_data_link, output=output, fuzzy=True)
pathzipfile = os.path.join(cwd, output)

# loading the temp.zip and creating a zip object 
with ZipFile(pathzipfile, 'r') as zObject: 
    # Extracting all the members of the zip  
    # into a specific location. 
    zObject.extractall(path=cwd) 

os.chdir(cwd)
os.remove(output)

## These links should probably hosted from Flatiron or Princeton
## specify link from which to download necessary data
all_data_link = 'https://drive.google.com/uc?export=download&id=1l0ByhVPgMBjL2WoSL7grzdUruWN8Ct8r'
output = "data_for_evaluating_finetune.zip"
gdown.download(url=all_data_link, output=output, fuzzy=True)
pathzipfile = os.path.join(cwd, output)

# loading the temp.zip and creating a zip object 
with ZipFile(pathzipfile, 'r') as zObject: 
    # Extracting all the members of the zip  
    # into a specific location. 
    zObject.extractall(path=cwd) 

os.chdir(cwd)
os.remove(output)


## These links should probably hosted from Flatiron or Princeton
## specify link from which to download necessary data
all_data_link = 'https://drive.google.com/uc?export=download&id=1XvHCCQz2JTB7t1o3q0h4xFUFudWf4h4d'
output = "data_for_evaluating_finetune_2.zip"
gdown.download(url=all_data_link, output=output, fuzzy=True)
pathzipfile = os.path.join(cwd, output)

# loading the temp.zip and creating a zip object 
with ZipFile(pathzipfile, 'r') as zObject: 
    # Extracting all the members of the zip  
    # into a specific location. 
    zObject.extractall(path=cwd) 

os.chdir(cwd)
os.remove(output)






