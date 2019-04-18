#!/bin/bash
sox -d -e u-law --endian little -b 8 -c 1 -r 8000 -t ul - silence 1 0.3 1% 1 0.3 1%
