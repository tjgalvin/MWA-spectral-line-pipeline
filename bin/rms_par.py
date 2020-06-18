#!/usr/bin/env python

#import sys
import os
from astropy.io import fits
import numpy as np
from glob import glob
import argparse
# Parallelise the code
import multiprocessing
# multiple cores support
import pprocess

''' calculate image RMS'''

def calc_rms(image):
    rmsimage = image.replace(".fits", "_rms.fits")
#    if not os.path.exists(rmsimage):
    hdu = fits.open(image)
    rms = np.nanstd(hdu[0].data)
# Give blank images very large RMS
    if rms == 0.0:
        rms = 2.**126
    rms_map = rms*np.ones(hdu[0].data.shape,dtype="float32")
    hdu[0].data = rms_map
    hdu.writeto(rmsimage, overwrite=True)
    hdu.close()
    return [rmsimage]

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group1 = parser.add_argument_group("required arguments:")
    group1.add_argument('--images', type=str, dest="images", default=None, \
                        help="The image files to calculate the RMS for (no default, use globbing)")
    options = parser.parse_args()

    imagelist = glob(options.images)

    cores = multiprocessing.cpu_count()
    results = pprocess.Map(limit=cores)
    calc = results.manage(pprocess.MakeParallel(calc_rms))

    for image in imagelist:
        print image
        calc(image)

# Maybe this makes it finish??
    rmslist = map(list, zip(*results))
