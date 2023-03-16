#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Mar  8 22:48:08 2023

@author: rob
"""

import scipy.io
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit


mat = scipy.io.loadmat('psfData.mat')



def sigmoid(x, a, b, c, d):
    y = a + (b - a) / (1 + np.exp(-c * (x - d)));
    return y 



x = mat['psfData']['x'][0][0].flatten()
y = mat['psfData']['y'][0][0].flatten()

guess = [0.4,0, 1,0] # Initial guess for the parameters

popt, pcov = curve_fit(sigmoid, x, y, p0=guess)

if False:
    plt.plot(x, y, 'o', label='data')
    plt.plot(x, sigmoid(x, *popt), label='fit')
    plt.legend()
    plt.show()


# Generate the PSF
x_psf = np.linspace(x.min(), x.max(),1000);

PDF = np.diff(sigmoid(x_psf, *popt)) / np.diff(x_psf);
PDF = PDF*-1; # TODO: hard-coded and assumes we go from high to low

x_psf = x_psf[1::]

# Centre the curve at zero
ind = np.argmax(PDF)
x_psf = x_psf - x_psf[ind]
x_psf = x_psf * 1E3; # convert to microns
plt.plot(x_psf,PDF,'-k')
plt.grid(True)

# Get the FWHM
halfCurve = PDF[0:ind]
halfMax = PDF[ind]/2
ind = np.argmin(abs(halfCurve-halfMax))
FWHM = np.round(abs(x_psf[ind])*2)
plt.title('FWHM = %d microns!' % FWHM)
