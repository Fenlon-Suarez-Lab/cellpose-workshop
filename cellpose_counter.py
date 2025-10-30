import os
import sys
import csv
import numpy as np
from cellpose import models
from cellpose.io import imread, masks_flows_to_seg, save_rois, save_masks

################# Cellpose SAM #################

def cellposeSAM_count(input_files, model = 'cpsam', outpath = None):
    # Initialise cellpose model
    cellpose = models.CellposeModel(gpu = True, 
                                 pretrained_model = model)
    images = [imread(f) for f in input_files]
    normalize_params = {
        "lowhigh" : None,
        "normalize" : True,
        "percentile" : [1.0,99.0],
        }
    # Alternative params to directly assign dynamic range
    # normalize_params = {
    #     "lowhigh" : [100,4000],
    #     }

    # Run cellpose model on file list
    masks, flows, _ = cellpose.eval(images,
                                 batch_size = 64,
                                 normalize = normalize_params)
    num_masks = [len(np.unique(mask)) - 1 for mask in masks]
    
    # Assign save paths
    basenames = [os.path.splitext(os.path.basename(f))[0] for f in input_files]
    npy_names = [os.path.splitext(f)[0] + '.npy' for f in input_files]
    png_names = [outpath + os.path.splitext(os.path.basename(f))[0] + '.png' for f in input_files]
    rois_names = [outpath + os.path.splitext(os.path.basename(f))[0] + '.zip' for f in input_files]
    
    # Write counts per file to csv
    with open(outpath + '/cellposeSAM_counts.csv', 'w' ,newline = '') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(['Image', 'Cell count'])
        for filename, cell_count in zip(basenames, num_masks):
            csvwriter.writerow([filename, cell_count])

    # Save other output files
    masks_flows_to_seg(images, masks, flows, npy_names)
    save_masks(images, masks, flows, png_names, png = True)
    for rois, filename in zip(masks, rois_names):
        save_rois(rois, filename)

################# Cellpose 3 #################

def cellpose3_count(input_files, diameter = 30, model = 'cyto3', outpath = None):
    # Initialise cellpose model
    cellpose = models.CellposeModel(gpu = True, 
                                 pretrained_model = model, 
                                 nchan = 2, 
                                 diam_mean = diameter)
    images = [imread(f) for f in input_files]
    normalize_params = {
        "lowhigh" : None,
        "normalize" : True,
        "percentile" : [1.0,99.0],
        }
    # Alternative params to directly assign dynamic range
    # normalize_params = {
    #     "lowhigh" : [100,4000],
    #     }

    # Run cellpose model on file list
    masks, flows, _ = cellpose.eval(images, 
                                 diameter = diameter, 
                                 channels = [0,0], 
                                 flow_threshold = 0.4, 
                                 do_3D = False, 
                                 normalize = normalize_params)
    num_masks = [len(np.unique(mask)) - 1 for mask in masks]

    # Assign save paths names
    basenames = [os.path.splitext(os.path.basename(f))[0] for f in input_files]
    npy_names = [os.path.splitext(f)[0] + '.npy' for f in input_files]
    png_names = [outpath + os.path.splitext(os.path.basename(f))[0] + '.png' for f in input_files]
    rois_names = [outpath + os.path.splitext(os.path.basename(f))[0] + '.zip' for f in input_files]
    
    # Write counts per file to csv
    with open(outpath + '/cellpose3_counts.csv', 'w', newline = '') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(['Image', 'Cell count'])
        for filename, cell_count in zip(basenames, num_masks):
            csvwriter.writerow([filename, cell_count])

    # Write other output files
    masks_flows_to_seg(images, masks, flows, npy_names, diams = diameter)
    save_masks(images, masks, flows, png_names, png = True)
    for rois, filename in zip(masks, rois_names):
        save_rois(rois, filename)

# Main guard (DEPRECATED for workshop)
if __name__=="__main__":
    cell_diameter = int(sys.argv[1])
    outpath = sys.argv[2]
    input_files = sys.argv[3:]
    
    cellposeSAM_count(input_files, outpath)
    # cellpose3_counter(input_files, cell_diameter, outpath)