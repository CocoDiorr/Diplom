#!/bin/sh

LOGLEVEL="DEBUG"

#if [ "$#" -gt "0" ]; then
#    if [ "$1" == "-v" ]; then
#        LOGLEVEL="DEBUG"
#        shift
#    fi
#fi

virt_env/env/bin/python3 -m emulator --config example/config.json --log-level $LOGLEVEL --in-fifo example/ex1 --out-fifo example/ex1 --de-code example/ex1.asm $@ --OF-Agent example/ex1.asm
