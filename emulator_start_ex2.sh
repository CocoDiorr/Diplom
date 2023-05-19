#!/bin/sh

LOGLEVEL="INFO"

if [ "$#" -gt "0" ]; then
    if [ "$1" == "-v" ]; then
        LOGLEVEL="DEBUG"
        shift
    fi
fi

virt_env/env/bin/python3 -m emulator --config example/config.json --log-level $LOGLEVEL --in-fifo example/ex2/tos-equals-9 --out-fifo example/ex2/tos-equals-9 --de-code example/ex2.asm --de-log example/ex2/de_{pl}_{de}.log $@
virt_env/env/bin/python3 -m emulator --config example/config.json --log-level $LOGLEVEL --in-fifo example/ex2/tos-equals-9-tagged --out-fifo example/ex2/tos-equals-9-tagged --de-code example/ex2.asm $@
