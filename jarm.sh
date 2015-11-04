#!/bin/sh

file=$2
file="./bin/${file%.*}" # rips the extension off the file

if [ "$1" == "-c" ] ; then
	jarmopt="-c" # just use the console without any devices described in a 'devices.txt' configuration file
elif [ "$1" == "-d" ] ; then
	jarmopt="-d devices.txt" # load device file for JARM; we use the default here of devices.txt
else 
	echo "USAGE: jarm.sh -c|-d <src_file>.s"
	exit
fi

if [ -z "$2" ] ; then
	echo "USAGE: jarm.sh -c|-d <src_file>.s"
	exit
fi

if [ ! -d "./bin" ]; then
    mkdir "./bin"
fi


#~/mc404/jarm/arm-none-eabi-linux-as  -aghls="$file-listing.txt"  $1 -o $file.elf
arm-none-eabi-linux-as  -aghls="$file-listing.txt"  $2 -o $file.elf

# -mcpu=cortex-m3 -mthumb --specs=rdimon.specs -lc -lrdimon -g ### this is for arm-none-eabi-gcc

if [ $? -ne 0 ] ; then 
    echo "arm-none-eabi-linux-as exited with error. no file generated"
    exit
fi
file $file.elf	# exibe o tipo do executavel ($file) gerado
arm-none-eabi-objdump -D $file.elf > $file.txt # "disassembla" o executavel no arquivo $file.txt a partir do rótulo "main:"

# add '-c' switch to run jarm for console based I/O. '-d' for devices. it uses devices.txt (in the same dir) as a default


#~/mc404/jarm/jarm $jarmopt -l $file.elf
jarm $jarmopt -l $file.elf # uses -c or -d devices.txt # -l is for our executable file.

#note: add the jarm folder to my path in bashrc (or bash profile??) at home.
