from csbdeep.utils import normalize
from stardist.models import StarDist3D
import os

def initialize_model(model_dir, prob_threshold, nms_threshold):
    """Initialize the stardist 3D model with user specified model and thresholds
    Args:
        model_dir: Directory with model training output.
        prob_threshold: User specified probability threshold.
        nms_threshold: User specified nms threshold.
    Returns:
        Stardist 3D model
    Raises:
        ValueError: if the path is not found.
    """
    model_name = os.path.basename(model_dir)
    print('Loading model: ', model_name)
    model = StarDist3D(None, name=model_name, basedir=os.path.dirname(model_dir))
    print("Original thresholds:", model._thresholds)

    # Here prob is the threshold beyond which the possible candidates for NMS are considered
    # nms is the NMS threshold, if there is overlap beyond this threshold the NMS suppresses
    # the overlapping nuclei note that model._thresholds is a tuple, must use
    # model._thresholds._replace(prob=0.1, nms=0.3) to change the values, a
    # simple assignment will throw an error. The results are very sensitive to prob threshold,
    # and not very sensitive to nms threshold prob=0.1, nms=0.3 work the best for visual inspection

    model._thresholds = model._thresholds._replace(prob=prob_threshold, nms=nms_threshold)
    print("User modified thresholds:", model._thresholds)
    return model

def run_3D_stardist(model, Xi, axis_norm, split_predict, prob_threshold_post, nms_threshold_post):
    """Run inference with the stardist 3d model
    Args:
        model: stardist model.
        Xi: N-dimensional numpy array.
        axis_norm: Axis for normalization.
        split_predict: split prediction and post-processing to apply different thresholds.
        prob_threshold_post: post-processing probability threshold.
        nms_threshold_post: post-processing nms threshold.
    Returns:
        labels: segmentation label.
        details: segmentation details.
    """
    if split_predict:
        prob_mat, dist_mat = model.predict(normalize(Xi, 1, 99.8, axis=axis_norm))

        # This is the post processing involving nms suppression
        labels, details = model._instances_from_prediction(img_shape=Xi.shape,
                                                           prob=prob_mat,
                                                           dist=dist_mat,
                                                           points=None,
                                                           prob_class=None,
                                                           prob_thresh=prob_threshold_post,
                                                           nms_thresh=nms_threshold_post)

    else:
        labels, details = model.predict_instances(normalize(Xi, 1, 99.8, axis=axis_norm))

    return labels, details
