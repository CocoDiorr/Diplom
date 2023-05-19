#include "npu_de_defines.h"

#define ETHERTYPE_IP4 0x800
#define ETHERTYPE_ARP 0x806
#define ETHERTYPE_VID 0x8100
#define ETHERTYPE_IP6 0x86dd
#define ETHERTYPE_ADDR      (HEADER_START+12)
#define ETHERTYPE_ADDR_TAG  (HEADER_START+16)
#define DMAC_ADDR     HEADER_START
#define SMAC_ADDR     (HEADER_START+6)
#define BROADCAST_ADDR 0xffffff

// distinguish recirc from straight run
load (METADATA_PORTMASK+0x6), 0x8
cmpjn process_out, 0, 0x8

// load ethertype into accumulator
loadbe ETHERTYPE_ADDR, 0x10
cmpjn finish, ETHERTYPE_IP4, 0x10
loadbe (HEADER_START+23), 0x8
// is IGMP?
cmpj control_port, 0x2, 0x8
loadbe (HEADER_START+30), 0x10
rol 0x10
orbe (HEADER_START+32), 0x10
// groups 239.1.1.2, 238.1.1.1 and 237.20.1.2
// represented as 0xef010102, 0xee010101 and 0xed140102
// for small group count we will use linear iteration
//
// due to load-store bug we are using 16 ports max
cmpj group_1, 0xef010102, 0x20
cmpj group_2, 0xee010101, 0x20
cmpj group_3, 0xed140102, 0x20
// traffic from unregistered groups just vanish
j finish

group_1:
loadi 0x67
// read only portmask copy
store (METADATA_PORTMASK+0x4), 0x10
loadi 0x3
store (METADATA_PORTMASK+0x6), 0x8
j process_out

group_2:
loadi 0x8
// read only portmask copy
store (METADATA_PORTMASK+0x4), 0x10
loadi 0x3
store (METADATA_PORTMASK+0x6), 0x8
j process_out

group_3:
loadi 0x900
// read only portmask copy
store (METADATA_PORTMASK+0x4), 0x10
loadi 0x3
store (METADATA_PORTMASK+0x6), 0x8
j process_out

control_port:
loadi 0x80
store (METADATA_PORTMASK+0x7), 0x8
j finish

process_out:
// port 2 and 5 are tagged by vlan5, port 3 is tagged by vlan8, 
// the rest is untagged
cmpj process_vlan8, 3, 0x8
cmpj process_vlan5, 2, 0x8
j process_untagged

process_vlan8:
// first round, no size conditionals
load (METADATA_PORTMASK+0x4), 0x10
andi 0x4
store (METADATA_PORTMASK), 0x10
load (HEADER_START), 0x20
store (HEADER_START-4), 0x20
load (HEADER_START+4), 0x20
store (HEADER_START), 0x20
load (HEADER_START+8), 0x20
store (HEADER_START+4), 0x20
loadi 0x8100
storebe (ETHERTYPE_ADDR-4), 0x10
loadi 0x1008
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
// set recirc bit
load (METADATA_PORTMASK+0x7), 0x8
ori 0x40
// set 'tagged' bit
ori 0x1
store (METADATA_PORTMASK+0x7), 0x8
// set tagged bit
load (METADATA_PORTMASK+0x6), 0x8
subi 1
store (METADATA_PORTMASK+0x6), 0x8
j finish

process_vlan5:
load (METADATA_PORTMASK+0x4), 0x10
andi 0x10
store (METADATA_PORTMASK), 0x10
// header expanded already
loadi 0x1005
storebe (ETHERTYPE_ADDR-2), 0x10
load (METADATA_PORTMASK+0x6), 0x8
subi 1
store (METADATA_PORTMASK+0x6), 0x8
j complete_vlan

complete_vlan:
// set recirc bit
load (METADATA_PORTMASK+0x7), 0x8
ori 0x40
store (METADATA_PORTMASK+0x7), 0x8
j finish

process_untagged:
load (METADATA_PORTMASK+0x4), 0x10
andi 0x1
store (METADATA_PORTMASK), 0x10
loadi 0
store (METADATA_PORTMASK+0x6), 0x8
j shrink_header

shrink_header:
load (HEADER_START+4), 0x20
store (HEADER_START+8), 0x20
load (HEADER_START), 0x20
store (HEADER_START+4), 0x20
load (HEADER_START-4), 0x20
store (HEADER_START), 0x20
// packet size decrement
load METADATA_START, 0x10
subi 0x4
store METADATA_START, 0x10
// header size increment
load (METADATA_START+2), 0x10
subi 0x4
store (METADATA_START+2), 0x10
load (METADATA_START+4), 0x10
addi 0x4
store (METADATA_START+4), 0x10
j complete_run

complete_run:
store METADATA_PORTMASK, 0x20
// clear reprocess bit
loadi 0
store (METADATA_PORTMASK+0x7), 0x8
j finish

finish:
