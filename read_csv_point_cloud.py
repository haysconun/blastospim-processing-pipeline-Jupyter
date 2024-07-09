import csv
import numpy as np
import os

def wrapper_read_csv_data(path_to_combined_mat, timeindex1):
    strval1 = str(timeindex1)
    strval1 = strval1.rjust(3, '0')
    timeindex2 = timeindex1 + 1
    strval2 = str(timeindex2)
    strval2 = strval2.rjust(3, '0')
    filename1 = 'combined_mat_' + strval1 + '_' + strval2 + '.csv'
    filename1 = os.path.join(path_to_combined_mat, filename1)
    assert os.path.isfile(filename1)

    counterval = 0
    with open(filename1, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=' ', quotechar='|')
        for row in spamreader:
            counterval = counterval + 1
        
    np_pt_cloud1 = np.zeros((counterval, 3), dtype=float)
    np_pt_cloud2 = np.zeros((counterval, 3), dtype=float)
    counterval = 0
    with open(filename1, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=' ', quotechar='|')
        for row in spamreader:
            otherrow = row[0]
            otherrowconconverted = np.fromstring(otherrow, dtype=float, sep=',')
            np_pt_cloud1[counterval, 0] = otherrowconconverted[0]
            np_pt_cloud1[counterval, 1] = otherrowconconverted[1]
            np_pt_cloud1[counterval, 2] = otherrowconconverted[2]
            np_pt_cloud2[counterval, 0] = otherrowconconverted[3]
            np_pt_cloud2[counterval, 1] = otherrowconconverted[4]
            np_pt_cloud2[counterval, 2] = otherrowconconverted[5]
            counterval = counterval + 1

    np_array_val1 = np.where(np_pt_cloud1[:,0]+np_pt_cloud1[:,1]+np_pt_cloud1[:,2]==0)
    np_array_val2 = np.where(np_pt_cloud2[:,0]+np_pt_cloud2[:,1]+np_pt_cloud2[:,2]==0)
    np_pt_cloud1 = np.delete(np_pt_cloud1, np.unique(np_array_val1[0]), 0)
    np_pt_cloud2 = np.delete(np_pt_cloud2, np.unique(np_array_val2[0]), 0)
    return np_pt_cloud1, np_pt_cloud2
