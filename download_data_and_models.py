import zipfile
from zipfile import ZipFile
import gdown
import os
import tarfile
import requests, io

cwd = os.getcwd()
path = 'models'
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
all_data_link = 'https://drive.google.com/uc?export=download&id=1rA1qN73572aMOCewy7FrEHZBE-DszW64'
output = "data.zip"
gdown.download(url=all_data_link, output=output, fuzzy=True)
pathzipfile = os.path.join(cwd, output)

# loading the temp.zip and creating a zip object 
with ZipFile(pathzipfile, 'r') as zObject: 
    # Extracting all the members of the zip  
    # into a specific location. 
    zObject.extractall(path=cwd) 

os.chdir(cwd)
os.remove(output)

