#include "npu_de_defines.h"

// load last byte of portmask
load (METADATA_PORTMASK+0x7), 0x8
// zeroing all except 62th bit in portmask
andi 0x40
cmpjg proc, 0, 0x8
ori 0x40
store (METADATA_PORTMASK+0x7), 0x8
j select_mirror_port

select_mirror_port:
load METADATA_PORTMASK, PORTMASK_SIZE
// 1st and 3rd port for incoming traffic mirroring
ori 0x5
store METADATA_PORTMASK, PORTMASK_SIZE
j finish

proc:
// clear port bits
andi 0
store (METADATA_PORTMASK+0x7), 0x8
load METADATA_PORTMASK, PORTMASK_SIZE
andi 0
store METADATA_PORTMASK, PORTMASK_SIZE
// regular processing goes here
j finish

finish:
