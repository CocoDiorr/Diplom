#include "npu_de_defines.h"

#define ETHERTYPE_IP4 0x800
#define ETHERTYPE_ARP 0x806
#define ETHERTYPE_VID 0x8100
#define ETHERTYPE_IP6 0x86dd
#define ETHERTYPE_ADDR      (HEADER_START+12)
#define ETHERTYPE_ADDR_TAG  (HEADER_START+16)
#define DMAC_ADDR     HEADER_START
#define SMAC_ADDR     (HEADER_START+6)
#define BROADCAST_ADDR 0xffffffffffff
#define OUTER_MAC_1 0x324a
#define OUTER_MAC_2 0x51fa
#define OUTER_MAC_3 0xfbfc
#define HOP_A_MAC_1 0xa0cb
#define HOP_A_MAC_2 0x2cfc
#define HOP_A_MAC_3 0xfbfa
#define HOP_B_MAC_1 0x10fa
#define HOP_B_MAC_2 0x54ff
#define HOP_B_MAC_3 0xaa11


// subnets are: 10.0.0.0/8 (a), 10.0.0.0/16 (b), 
// 172.16.1.0/24 (b) and 8.8.8.8/32 (a)
// distributed between two nexthops, nexthop B is tagged with 8021
// if nh is not covered, bail out

// load ethertype into accumulator
loadbe ETHERTYPE_ADDR, 0x10
cmpjn switch_to_l2, ETHERTYPE_IP4, 0x10
// load daddr value
loadbe (HEADER_START+30), 0x10
rol 0x10
orbe (HEADER_START+32), 0x10
//                   0x0b000000
//                 /            \
//       1_0x09ffffff         2_0xac100100
//       /         \              |     \
// = 3_0x08080808? 4_0x0a00ffff  nm    5_0xac1001ff
// n       y      /       |              /       \
// nm match_32  match_16 match_8      match_24  nm
cmpjlge label_1, label_2, 0xb000000
label_1:
cmpjlge label_3, label_4, 0x09ffffff
label_2:
cmpjlge switch_to_l2, label_5, 0xac100100
label_3:
cmpjn switch_to_l2, 0x08080808, 0x20
j nexthop_a
label_4:
cmpjl nexthop_b, 0x0a010000, 0x20
j nexthop_a
label_5:
cmpjl nexthop_b, 0xac100200, 0x20
j switch_to_l2

nexthop_a:
loadi HOP_A_MAC_1
storebe DMAC_ADDR, 0x10
loadi HOP_A_MAC_2
storebe (DMAC_ADDR+2), 0x10
loadi HOP_A_MAC_3
storebe (DMAC_ADDR+4), 0x10
load METADATA_PORTMASK, 0x20
ori 0x1
store METADATA_PORTMASK, 0x20
j mpls_push_first

nexthop_b:
loadi HOP_B_MAC_1
storebe DMAC_ADDR, 0x10
loadi HOP_B_MAC_2
storebe (DMAC_ADDR+2), 0x10
loadi HOP_B_MAC_3
storebe (DMAC_ADDR+4), 0x10
load METADATA_PORTMASK, 0x20
ori 0x2
store METADATA_PORTMASK, 0x20
// set the control bit for tagging
loadi 0x1
store (METADATA_PORTMASK+0x4), 0x8
j mpls_push_first

// TBD - set crc recalc flag/offset
// move L2 stuff left
mpls_push_first:
// set SMAC
loadi OUTER_MAC_1
storebe SMAC_ADDR, 0x10
loadi OUTER_MAC_2
storebe (SMAC_ADDR+2), 0x10
loadi OUTER_MAC_3
storebe (SMAC_ADDR+4), 0x10
// ..and move bytes
load HEADER_START, 0x20
store (HEADER_START-4), 0x20
load (HEADER_START+4), 0x20
store (HEADER_START), 0x20
load (HEADER_START+8), 0x20
store (HEADER_START+4), 0x20
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
loadi 0x8847
storebe (ETHERTYPE_ADDR-4), 0x10
loadi 0x400
// add BoS bit
ori 0x10000
rcr 0x18
// copy ttl from IP field
orbe (HEADER_START+22), 0x8
rcl 0x18
// and save mpls header...
store (ETHERTYPE_ADDR-2), 0x10
ror 0x10
store (ETHERTYPE_ADDR), 0x10
// just in case
j needs_tagging

needs_tagging:
load (METADATA_PORTMASK+0x4), 0x8
cmpj finish, 0, 0x8
load (HEADER_START-4), 0x20
store (HEADER_START-8), 0x20
load HEADER_START, 0x20
store (HEADER_START-4), 0x20
load (HEADER_START+4), 0x20
store HEADER_START, 0x20
loadi 0x8100
storebe (HEADER_START+4), 0x10
loadi 0x1005
storebe (HEADER_START+6), 0x10
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
j finish


switch_to_l2:
// delete control bits
loadi 0
store (METADATA_PORTMASK+0x4), 0x8
// placeholder for entire l2sw+unicast scenario
j finish

finish:
