#!/usr/bin/env python

# Plot the MFS image RMSs to look for any bad images

from glob import glob
from astropy.io import fits
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter
import numpy as np

# Publication-quality plotting
from matplotlib import rc

# rc('text', usetex=True)
rc("font", **{"family": "serif", "serif": ["serif"]})


ns = [1, 2, 3]

MFS = {}
peak = {}

for n in ns:
    MFS[n] = sorted(glob("1?????????/1?????????_fine-MFS" + str(n) + "-dirty.fits"))
    peak[n] = []

    for f in MFS[n]:
        hdu = fits.open(f)
        peak[n].append(1.0e3 * hdu[0].data[:, :, 127, 127])
        hdu.close()

obsids = [float(x[0:10]) for x in MFS[n]]

fig = plt.figure(figsize=(12, 3))
ax = fig.add_subplot(111)
ax.set_ylabel("Peak (mJy/beam)")
# ax.set_xlabel("Observation number")
ax.set_xlabel("Epoch")
xr = range(0, len(obsids))
ax.scatter(xr, peak[1], label="208-217 MHz", color="red", alpha=0.5)
ax.scatter(xr, peak[2], label="218-227 MHz", color="green", alpha=0.5)
ax.scatter(xr, peak[3], label="228-237 MHz", color="blue", alpha=0.5)
ax.xaxis.set_major_formatter(FormatStrFormatter("%10.0f"))
for n in ns:
    std = np.std(peak[n])
    ii = np.where(np.abs(peak[n]) > 5 * std)
    i = ii[0]
    for ind in i:
        ax.text(xr[ind], peak[n][ind], "{0:10.0f}".format(obsids[ind]))
fig.savefig("MFS_peak.pdf", bbox_inches="tight")
