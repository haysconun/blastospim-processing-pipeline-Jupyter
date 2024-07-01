import os
import numpy as np
import h5py
try:
    import pyklb
except ImportError:
    print("pyklb install missing! All klb format operations will fail. ")
import tifffile as tif


def axes_dict(axes):
    """
    from axes string to dict
    """
    allowed = 'STCZYX'
    return {a: None if axes.find(a) == -1 else axes.find(a) for a in allowed}


def move_image_axes(x, fr, to, adjust_singletons=False):
    """
    x: ndarray
    fr,to: axes string (see `axes_dict`)
    """
    fr_initial = fr
    x_shape_initial = x.shape
    adjust_singletons = bool(adjust_singletons)
    if adjust_singletons:
        # remove axes not present in 'to'
        slices = [slice(None) for _ in x.shape]
        for i,a in enumerate(fr):
            if (a not in to) and (x.shape[i]==1):
                # remove singleton axis
                slices[i] = 0
                fr = fr.replace(a,'')
        x = x[tuple(slices)]
        # add dummy axes present in 'to'
        for i,a in enumerate(to):
            if (a not in fr):
                # add singleton axis
                x = np.expand_dims(x,-1)
                fr += a

    if set(fr) != set(to):
        _adjusted = '(adjusted to %s and %s) ' % (x.shape, fr) if adjust_singletons else ''
        raise ValueError(
            'image with shape %s and axes %s %snot compatible with target axes %s.'
            % (x_shape_initial, fr_initial, _adjusted, to)
        )

    ax_from, ax_to = axes_dict(fr), axes_dict(to)
    if fr == to:
        return x
    return np.moveaxis(x, [ax_from[a] for a in fr], [ax_to[a] for a in fr])


def read_image(image_path_file, perform_8bit_shift=True):
    """Read an image file in in klb/h5/tif/npy format.
    Args:
        image_path_file: Path to the image file in klb/h5/tif/npy format with the same extensions respectively.
    Returns:
        N-dimensional numpy array with the image pixels in 8-bit format
    Raises:
        ValueError: if the path is not found.
        ValueError: if the image is not in one of the required formats.
    """
    if not os.path.exists(image_path_file):
        raise ValueError(f"Image file not found '{image_path_file}'")
    elif not os.path.isfile(image_path_file):
        raise ValueError(f"Image not a file '{image_path_file}'")
    elif not (os.path.splitext(image_path_file)[1] == '.klb' or
              os.path.splitext(image_path_file)[1] == '.h5' or
              os.path.splitext(image_path_file)[1] == '.tif' or
              os.path.splitext(image_path_file)[1] == '.npy'):
        raise ValueError(f"Image file not in supported format with appropriate extension '{image_path_file}'")

    if image_path_file[-3:] == 'npy':
        Xi = np.load(image_path_file)
    elif image_path_file[-3:] == 'tif':
        Xi = tif.imread(image_path_file)
    elif (image_path_file[-2:] == 'h5'):
        him = h5py.File(image_path_file, 'r')
        Xi = him.get('Data')[:]
    elif (image_path_file[-3:] == 'klb'):
        Xi = pyklb.readfull(image_path_file)

    # convert to 8-bit by 4-bit shift
    if perform_8bit_shift:
        Xi = Xi >> 4
        Xi = Xi.astype(dtype=np.uint8)
    print('loaded image shape:', Xi.shape)
    return Xi

def crop_image(Xi, row_1, row_2, col_1, col_2):
    """Crop the X/Y dimension of the N-dimensional numpy array representing the image.
    Args:
        Xi: N-dimensional numpy array with the image pixels.
        row_1: starting row
        row_2: ending row
        col_1: starting column
        col_2: ending column
    Returns:
        N-dimensional numpy array with the cropped image pixels
    """
    return Xi[:, row_1:row_2, col_1:col_2]

def crop_frames(Xi, frame_1, frame_2):
    """Crop the X/Y dimension of the N-dimensional numpy array representing the image.
    Args:
        Xi: N-dimensional numpy array with the image pixels.
        frame_1: starting frame
        frame_2: ending frame
    Returns:
        N-dimensional numpy array with the cropped frames removed
    """
    return Xi[frame_1:frame_2, :, :]

def write_image(labels, out_image_file, output_format, gen_roi):
    """Writes a N-dimensional numpy array in tif format
    Args:
        labels:  N-dimensional numpy array
        out_image_file: Path to the output image file including name.
        output_format: The segmentation output format klb/h5/tif/npy.
        gen_roi: Generate ROI if true
    Raises:
        ValueError: if the path is invalid.
    """

    segmentation_file_name = ""
    if output_format.upper() == "KLB":
        segmentation_file_name = out_image_file + ".klb"
        pyklb.writefull(labels.astype('uint16'), segmentation_file_name)
    elif output_format.upper() == "H5":
        segmentation_file_name = out_image_file + ".h5"
        hf = h5py.File(segmentation_file_name, 'w')
        hf.create_dataset('Data', data=labels)
        hf.close()
    elif output_format.upper() == "NPY":
        segmentation_file_name = out_image_file + ".npy"
        np.save(segmentation_file_name,labels)
    else:
        segmentation_file_name = out_image_file + ".tif"
        img = labels.astype('uint16')
        img = move_image_axes(img, "ZYX", 'TZCYX', True)
        # save_tiff_imagej_compatible(segmentation_file_name, labels.astype('uint16'), axes='ZYX')
        tif.imwrite(segmentation_file_name, img, imagej=True,metadata={'axes': 'TZCYX'})

def get_filename_components(image_file_str):
    cur_name = os.path.basename(image_file_str)
    file_prefix = os.path.splitext(cur_name)[0]
    file_ext = os.path.splitext(cur_name)[1]
    file_base = os.path.basename(cur_name).split(os.extsep)
    time_index = int(file_base[0].split('_')[-1])
    return file_base, file_prefix, file_ext, time_index