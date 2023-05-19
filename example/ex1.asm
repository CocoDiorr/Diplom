#include "npu_de_defines.h"

// loading lower 48 bits from beginning of the packet to the accumulator
// so we would have DMAC value in the accumulator:
load HEADER_START, MACADDR_SIZE
// comparing value in the accumulator to lower 48 bits of the literal:
cmpj zero_dst, BCAST_MACADDR, MACADDR_SIZE
// if packet hasn't been matched, stop processing
j finish 
// since we haven't implemented portmask field yet, let's change mac to
// all zeros, it should not pass most of the networking equipment
// xoring lower 48 bits to bcast
zero_dst:
xor bcast, MACADDR_SIZE
// write first 48 bits of the packet back
store HEADER_START, MACADDR_SIZE
// ... and we're done
j finish
bcast:
0xffffffffffff
sub_val:
4
finish:
