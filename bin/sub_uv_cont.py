#!/usr/bin/env python

import sys
import numpy as np
from casacore.tables import table
import argparse

__author__ = "Natasha Hurley-Walker"
__date__ = "2020-05-01"


def continuum_subtract(msfile, binwidth):
    """Apply a box-car average and subtract from visibility

    Args:
        msfile (str): Path to measurement set to process
        binwidth (int): width of box-car average filter
    """
    mset = table("{0}".format(options.msfile), readonly=True)
    # Have to make a copy first
    mset_sub = mset.copy(msfile.replace(".ms", "_sub.ms"), deep=True)

    data = mset.getcol(options.datacolumn)
    flag = mset.getcol("FLAG")
    nchans = data.shape[1]  # 2 time and baseline, 1 channel, 0 pol
    ## There are also values set to NaN that are not in the flag table
    new_flags = np.isnan(data)
    # If the data is NaN OR the data are flagged then we want to flag it
    total_flags = np.logical_or(flag, new_flags)
    mdata = np.ma.masked_array(data, mask=total_flags, dtype="complex64")
    avg = np.ma.zeros(mdata.shape, dtype="complex64")
    avg.mask = total_flags

    # Calculate the moving average
    for i in range(binwidth / 2, nchans - binwidth / 2):
        avg[:, i, :] = np.ma.mean(
            mdata[:, i - binwidth / 2 : i + binwidth / 2, :], axis=1
        )

    # Handle the edges with a single mean across (half the binwidth) channels
    avg_start = np.ma.mean(mdata[:, 0 : binwidth / 2, :], axis=1)
    avg_end = np.ma.mean(mdata[:, nchans - binwidth / 2 : nchans, :], axis=1)
    for i in range(0, binwidth / 2):
        avg[:, i, :] = avg_start
    for i in range(nchans - binwidth / 2, nchans):
        avg[:, i, :] = avg_end

    mset_sub = table(msfile.replace(".ms", "_sub.ms"), readonly=False)
    new_data = mdata - avg
    mset_sub.putcol(options.datacolumn, new_data)
    mset_sub.close()
    mset.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group1 = parser.add_argument_group("Input/output files")
    group1.add_argument(
        "--msfile",
        dest="msfile",
        type=str,
        default=None,
        help="Name of the input visibilities to be continuum-subtracted.",
    )
    group1.add_argument(
        "--datacolumn",
        dest="datacolumn",
        type=str,
        default="DATA",
        help="Column to subtract from (default = DATA).",
    )
    group1.add_argument(
        "--binwidth",
        dest="binwidth",
        type=int,
        default=16,
        help="Number of channels in each bin (default = 16).",
    )
    options = parser.parse_args()

    if len(sys.argv) <= 1 or options.msfile is None:
        parser.print_help()
        sys.exit()

    continuum_subtract(options.msfile, options.binwidth)
