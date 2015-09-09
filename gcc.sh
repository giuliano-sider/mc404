#!/bin/bash
file=$1
if [ ! -d "./bin" ]; then
    mkdir "./bin"
fi
file="./bin/${file%.*}"
arm-none-eabi-gcc  -Wa,-aghls="$file-listing.txt" -mcpu=cortex-m3 -mthumb --specs=rdimon.specs $2 -lc -lrdimon -g $1 -o $file
if [ $? -ne 0 ] ; then 
    echo "arm-none-eabi-gcc exited with error. no file generated"
    exit
fi
file $file	# exibe o tipo do executavel ($file) gerado 
arm-none-eabi-objdump -D $file > $file.txt # "disassembla" o executavel no arquivo $file.txt a partir do rótulo "main:"
