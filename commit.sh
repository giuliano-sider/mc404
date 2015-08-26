#!/bin/sh
#USAGE: ../commit.sh <name of program that is stored in the homonymous directory which contains program.s as the source.>
echo -e "\n$1/$1" >> ~/mc404/.gitignore
git add $1.s
git commit -m "added assembler program $1.s to the project"
