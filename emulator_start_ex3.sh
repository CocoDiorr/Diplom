#!/bin/sh

LOGLEVEL="INFO"

if [ "$#" -gt "0" ]; then
    if [ "$1" == "-v" ]; then
        LOGLEVEL="DEBUG"
        shift
    fi
fi

virt_env/env/bin/python3 -m emulator --config example/config.json --log-level $LOGLEVEL --in-fifo example/ex1/ --out-fifo example/ex1/ --de-code example/ex3.asm $@
