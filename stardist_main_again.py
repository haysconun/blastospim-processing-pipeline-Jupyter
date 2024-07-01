import argparse
import io_utils
import stardist_functions
import os
import numpy as np
from io_utils import get_filename_components

def wrapper_run_model(image_path, output_dir, early_model_dir, early_prob_thresh, early_nms_thresh, late_model_dir, late_prob_thresh, late_nms_thresh, timepoint_switch, output_format):
    #image_path = "/mnt/home/hnunley/revised_code_for_pipeline/data/smallImages"
    assert os.path.exists(image_path)
    #output_dir = "/mnt/home/hnunley/revised_code_for_pipeline/output"
    assert os.path.exists(output_dir)
    #early_model_dir = "/mnt/home/hnunley/revised_code_for_pipeline/models/early_embryo_model"
    assert os.path.exists(early_model_dir)
    #early_prob_thresh = 0.5
    assert 0 < early_prob_thresh < 1
    #early_nms_thresh = 0.3
    assert 0 < early_nms_thresh < 1
    #late_model_dir = "/mnt/home/hnunley/revised_code_for_pipeline/models/late_blastocyst_model"
    assert os.path.exists(late_model_dir)
    #late_prob_thresh = 0.451
    assert 0 < late_prob_thresh < 1
    #late_nms_thresh = 0.5
    assert 0 < late_nms_thresh < 1
    #timepoint_switch = 22
    #output_format = "tif"
    assert output_format in ['klb','h5','tif','npy']
    no_8bit_shift = 0
    gen_roi = 0
    

    # Load model
    early_model = stardist_functions.initialize_model(early_model_dir, early_prob_thresh, early_nms_thresh)

    late_model = stardist_functions.initialize_model(late_model_dir, late_prob_thresh, late_nms_thresh)

    if os.path.isdir(image_path):
        result = [os.path.join(dp, f)
                  for dp, dn, filenames in os.walk(image_path)
                  for f in filenames if (os.path.splitext(f)[1] == '.klb' or
                                         os.path.splitext(f)[1] == '.h5' or
                                         os.path.splitext(f)[1] == '.tif' or
                                         os.path.splitext(f)[1] == '.npy')]
        for image_file in result:
            print("Processing image:", image_file)
            file_base, file_prefix, file_ext, time_index = get_filename_components(image_file)
            Xi = io_utils.read_image(image_file, not no_8bit_shift)
            axis_norm = (0, 1, 2)  # normalize channels independently
            if (timepoint_switch >= 0 and time_index < timepoint_switch) or timepoint_switch == -1:
                print("Segmenting with early stage model.")
                label, detail = stardist_functions.run_3D_stardist(early_model,
                                                                   Xi, axis_norm, False,
                                                                   early_prob_thresh, early_nms_thresh)
            else:
                print("Segmenting with late stage model.")
                label, detail = stardist_functions.run_3D_stardist(late_model, Xi,
                                                                   axis_norm, False,
                                                                   late_prob_thresh, late_nms_thresh)

            out_image_name = os.path.splitext(os.path.basename(image_file))[0] + ".label"
            out_image_path = os.path.join(output_dir,out_image_name)
            io_utils.write_image(label, out_image_path, output_format, gen_roi)
    else:
        print("Processing image:", image_path)
        Xi = io_utils.read_image(image_path, not no_8bit_shift)
        axis_norm = (0, 1, 2)  # normalize channels independently
        label, detail = stardist_functions.run_3D_stardist(early_model, Xi, axis_norm, False,
                                                           early_prob_thresh, early_nms_thresh)

        out_image_name = os.path.splitext(os.path.basename(image_path))[0] + ".label"
        out_image_path = os.path.join(output_dir,out_image_name)
        io_utils.write_image(label, out_image_path, output_format, gen_roi)
