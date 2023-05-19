#include "npu_de_defines.h"

#define ETHERTYPE_ADDR      (HEADER_START+12)
// HEADER_START is at 0xff60
// header_start_size are three bytes at (METADATA+2)
// if ethertype is not 0x8100, add tag, jump to end otherwise

loadbe ETHERTYPE_ADDR, 0x10
cmpj port_0, 0x8100, 0x10
load HEADER_START, 0x20
store (HEADER_START-4), 0x20
load (HEADER_START+4), 0x20
store (HEADER_START), 0x20
load (HEADER_START+8), 0x20
store (HEADER_START+4), 0x20
loadi 0x8100
storebe (ETHERTYPE_ADDR-4), 0x10
loadi 0x1005
storebe (ETHERTYPE_ADDR-2), 0x10
// packet size increment
load METADATA_START, 0x10
addi 0x4
store METADATA_START, 0x10
// header size increment
load (METADATA_START+2), 0x10
addi 0x4
store (METADATA_START+2), 0x10
// header_start decrement, 3rd byte is unused anyway
load (METADATA_START+4), 0x10
subi 0x4
store (METADATA_START+4), 0x10
j port_0

port_0:
load METADATA_PORTMASK, 0x10
ori 0x1
store METADATA_PORTMASK, 0x10
j finish

finish:
