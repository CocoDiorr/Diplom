#include "npu_de_defines.h"

// Similar to ex1, but with metadata manipulation

// loading lower 48 bits from beginning of the packet to the accumulator
// so we would have DMAC value in the accumulator:
load    HEADER_START, MACADDR_SIZE
// comparing value in the accumulator to lower 48 bits of the literal:
cmpj    zero_dst, BCAST_MACADDR, MACADDR_SIZE
// if packet hasn't been matched, send it to port 0
j       port0_dst

zero_dst:
// just write zeroes to metadata portmask
loadi   0
j       set_portmask

port0_dst:
// just write 1 to metadata portmask
loadi   1

set_portmask:
store   METADATA_PORTMASK, PORTMASK_SIZE

finish:
