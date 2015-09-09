#!/bin/sh
file=$1
extension="${file##*.}"
file="${file%.*}"
#if [ $extension = "c" ]; then
arm-none-eabi-objdump -d $file > $file.lst 

