#!/bin/sh
arm-none-eabi-gdb -ex "target ext localhost:6271"  $1
