#!/bin/sh

LOGLEVEL="INFO"

if [ "$#" -gt "0" ]; then
    if [ "$1" == "-v" ]; then
        LOGLEVEL="DEBUG"
        shift
    fi
fi

virt_env/env/bin/python3 -m emulator --config example/config.json --log-level $LOGLEVEL --in-fifo example/vlan-aware-switch/ --out-fifo example/vlan-aware-switch/ --de-code example/vlan-aware-switch.asm $@
