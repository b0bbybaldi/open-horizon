#!/usr/local/bin/python3

###
### requirements: matplotlib numpy scipy pydub
###

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

## initialize matplotlib to use Agg rendering to a Tk canvas (requires TkInter)
matplotlib.use('TkAgg')

## packages
from scipy import signal
from scipy.io import wavfile
from scipy.fftpack import fft, fftfreq
from pydub import AudioSegment

###
### MAIN
###

## collect input
wav_filename = "square.wav"
samplerate, data = wavfile.read(wav_filename)

total_samples = len(data)
limit = int((total_samples /2)-1)

fft_abs = abs(fft(data))
freqs = fftfreq(total_samples,1/samplerate)

# comment out if you dont want both before and after to display
# plt.plot(freqs[:limit], fft_abs[:limit])

## do high-pass butterworth filter (order, ??); returns a?, b?
b, a = signal.butter(3, 0.05)
data_filtered = signal.filtfilt(b, a, data)
fft_abs_filtered = abs(fft(data_filtered))
freqs_filtered = fftfreq(total_samples,1/samplerate)

## create image output
plt.plot(freqs_filtered[:limit], fft_abs_filtered[:limit])
plt.savefig('square-fft.png')

## create date output
