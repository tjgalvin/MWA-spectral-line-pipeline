#!/usr/bin/env python

import sys
from beam_value_at_radec import beam_value
from beam_value_at_radec import parse_metafits
from astropy.io import fits
from astropy import wcs
from astropy import units as u
from astropy.coordinates import SkyCoord
from glob import glob
import numpy as np
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group1 = parser.add_argument_group("required arguments:")
    group1.add_argument('--ra', type=float, dest="ra", default=None, \
                        help="The RA in decimal degrees (default = centre of image)")
    group1.add_argument('--dec', type=float, dest="dec", default=None, \
                        help="The declination in decimal degrees (default = centre of image)")
    group1.add_argument('--metafits', type=str, dest="metafits", default=None, \
                        help="The metafits file for your observation (no default)")
    group1.add_argument('--images', type=str, dest="images", default=None, \
                        help="The image files to adjust bscale (no default, use globbing)")
    options = parser.parse_args()

    if options.metafits is None or options.images is None:
        print("Need to select both metafits file and image(s).")
        sys.exit(1)

    t, delays, freq = parse_metafits(options.metafits)

    imagelist = glob(options.images)

# Get vital stats from first image in list
    hdu = fits.open(imagelist[0])
    if options.ra is None or options .dec is None:
        w = wcs.WCS(hdu[0].header, naxis=2)
        ra, dec = w.wcs_pix2world([[hdu[0].header["NAXIS1"]/2,hdu[0].header["NAXIS2"]/2]],0).transpose()
    else:
       ra = options.ra
       dec = options.dec

    val = beam_value(ra, dec, t, delays, freq)

    bscale = 2.0 / (val[0] + val[1])
    hdu.close()

# Apply to all images
    for image in imagelist:
        hdu = fits.open(image)
        hdu[0].header["BSCALE"] = bscale
        hdu.writeto(image, overwrite=True)
        hdu.close()
