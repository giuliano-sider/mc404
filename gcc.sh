#!/bin/sh
file=$1
file="${file%.*}" 
arm-none-eabi-gcc  -mcpu=cortex-m3 -mthumb --specs=rdimon.specs -lc -lrdimon  -g $1 -o $file 
file $file	# exibe o tipo do executavel ($file) gerado 
arm-none-eabi-objdump -d $file > $file.txt # "disassembla" o executavel no arquivo $file.txt a partir do rótulo "main:"
