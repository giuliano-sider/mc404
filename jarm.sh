#/bin/sh

file=$1
file="./bin/${file%.*}" # 

if [ "$2" == "-c" ] ; then
	jarmopt="-c"
elif [ "$2" == "-d" ] ; then
	jarmopt="-d $3"
else 
	echo "USAGE: jarm.sh [ -c | -l ] <src_file>.s"
	exit
fi

if [ -z "$1" ] ; then
	echo "USAGE: jarm.sh [ -c | -l ] <src_file>.s"
	exit
fi

if [ ! -d "./bin" ]; then
    mkdir "./bin"
fi


#~/mc404/jarm/arm-none-eabi-linux-as  -aghls="$file-listing.txt"  $1 -o $file.elf
arm-none-eabi-linux-as  -aghls="$file-listing.txt"  $1 -o $file.elf

# -mcpu=cortex-m3 -mthumb --specs=rdimon.specs -lc -lrdimon -g ### this is for arm-none-eabi-gcc

if [ $? -ne 0 ] ; then 

    echo "arm-none-eabi-linux-as exited with error. no file generated"
    exit
fi
file $file.elf	# exibe o tipo do executavel ($file) gerado
arm-none-eabi-objdump -D $file.elf > $file.txt # "disassembla" o executavel no arquivo $file.txt a partir do rótulo "main:"

# add '-c' switch to run jarm for console based I/O. '-d' for devices. it uses devices.txt
#jarm -d devices.txt -l $pathtofiles$1.elf config file in folder with jarm

#~/mc404/jarm/jarm $jarmopt -l $file.elf
jarm $jarmopt -l $file.elf

#note: add the jarm folder to my path in bashrc (or bash profile??) at home.
