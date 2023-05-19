#include "npu_de_defines.h"
#define ETHERTYPE_ADDR      (HEADER_START+12)
#define ETHERTYPE_VID 0x8100


// load last byte of portmask
load (METADATA_PORTMASK+0x7), 0x8
// zeroing all except 62th bit in portmask
andi 0x40
cmpjg proc, 0, 0x8
ori 0x40
store (METADATA_PORTMASK+0x7), 0x8
store (HEADER_START-0x10), 0x8
j select_mirror_port

select_mirror_port:
load METADATA_PORTMASK, PORTMASK_SIZE
// 1st and 3rd port for incoming traffic mirroring
ori 0x5
store METADATA_PORTMASK, PORTMASK_SIZE
j check_outer_vlan

check_outer_vlan:
loadbe ETHERTYPE_ADDR, 0x10
cmpj check_inner_vlan, 0x88a8, 0x10
cmpj single_tag, ETHERTYPE_VID, 0x10
j finish

check_inner_vlan:
loadbe (ETHERTYPE_ADDR+4), 0x10
cmpj nested_tag, ETHERTYPE_VID, 0x10
j finish

single_tag:
j finish

nested_tag:
j finish

proc:
// clear port bits
andi 0
store (METADATA_PORTMASK+0x7), 0x8
load (HEADER_START-0x10), 0x8
store METADATA_PORTMASK, 0x8
// regular processing goes here
j finish

finish:
