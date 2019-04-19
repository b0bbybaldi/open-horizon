#!/usr/bin/python3

###
### fft.py - perform FFT on WAV and calculate Butterworth filter
###
### pip3 install matplotlib numpy scipy pydub
###
### LOW-PASS BUTTERWORTH FILTER
### https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.lfilter.html

## system for command-line arguments
import sys

## matplotlib
import matplotlib
# configure to use Tk canvas
matplotlib.use('TkAgg')

import matplotlib.pyplot as plt
import numpy as np
import json, codecs

from scipy import signal
from scipy.io import wavfile

from scipy.fftpack import fft, fftfreq
from pydub import AudioSegment

## input
narg = len(sys.argv)

if narg > 1:
  filename = sys.argv[1]
else:
  filename = "square"

if narg > 2:
  butter_order = sys.argv[2]
else:
  butter_order = 3

if narg > 3:
  butter_level = sys.argv[3]
else:
  butter_level = 0.05

## get file
wav_filename = filename + '.wav'
samplerate, data = wavfile.read(wav_filename)

## size of data
total_samples = len(data)
limit = int((total_samples /2)-1)

## fft data
fft_abs = abs(fft(data))
freqs = fftfreq(total_samples,1/samplerate)

## plot frequencies
plt.plot(freqs[:limit], fft_abs[:limit])
plt.savefig(filename + '-raw.png')

## dump raw data
freqs.dump(filename + '-raw.nda')
freqs_list = freqs.tolist()
json.dump(freqs_list, codecs.open(filename + '-raw.json', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)

## BUTTERWORTH FILTER
b, a = signal.butter(butter_order, butter_level)

# filter signal with with butter (b, a)
data_filtered = signal.filtfilt(b, a, data)

## calculate new FFT
fft_abs_filtered = abs(fft(data_filtered))
freqs_filtered = fftfreq(total_samples,1/samplerate)

## plot butterworth PNG
plt.plot(freqs_filtered[:limit], fft_abs_filtered[:limit])
plt.savefig(filename + '-butter.png')

## dump butterworth data
freqs_filtered.dump(filename + '-butter.nda')
freqs_list = freqs_filtered.tolist()
json.dump(freqs_list, codecs.open(filename + '-butter.json', 'w', encoding='utf-8'), separators=(',', ':'), sort_keys=True, indent=2)
