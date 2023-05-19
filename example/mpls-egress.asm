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
// the logic a little bit weird, as we kinda unconditionally
// rewrap the traffic in the 0x800 ethertype 

loadbe DMAC_ADDR, 0x20
rol 0x10
orbe DMAC_ADDR+4, 0x10
// are we L2 designated receiver?
cmpjn switch_to_l2, 0x324a51fafbfc, 0x30
loadbe ETHERTYPE_ADDR, 0x10
cmpj proc_vlan, ETHERTYPE_VID, 0x10
cmpj proc_mpls, 0x8847, 0x10
j switch_to_l2

proc_vlan:
load (HEADER_START), 0x20
store (HEADER_START+4), 0x20
load (HEADER_START+4), 0x20
store (HEADER_START+8), 0x20
load (HEADER_START+8), 0x20
store (HEADER_START+12), 0x20
// packet size decrement
load METADATA_START, 0x10
subi 0x4
store METADATA_START, 0x10
// header size decrement
load (METADATA_START+2), 0x10
subi 0x4
store (METADATA_START+2), 0x10
// header_start increment
load (METADATA_START+4), 0x10
addi 0x4
store (METADATA_START+4), 0x10
loadbe (ETHERTYPE_ADDR+4), 0x10
cmpj proc_mpls_tagged, 0x8847, 0x10
j switch_to_l2

proc_mpls_tagged:
loadi 1
store (METADATA_PORTMASK+0x4), 0x8
loadoffi 4
j proc_mpls

proc_mpls:
// load TTL
loadbe (HEADER_START+17), 0x8
// TTL <= 1?
cmpjl control_plane, 0x2, 0x8
subi 1
storebe (HEADER_START+17), 0x8
// TODO: alignment is fucked up, we will do 2+1 instead 4+ror
loadbe (HEADER_START+14), 0x10
rol 0x8
loadbe (HEADER_START+16), 0x8
ror 0x4
// processing label, simple non-tree structure for exact match
cmpj label_1, 0x3a, 0x14
cmpj label_2, 0x20, 0x14
cmpj label_3, 0x2, 0x14
// welp no luck
j finish

label_1:
loadoffi 0
load METADATA_PORTMASK, 0x20
ori 0x4
store METADATA_PORTMASK, 0x20
j pop_label_p

label_2:
loadoffi 0
load METADATA_PORTMASK, 0x20
ori 0x10
store METADATA_PORTMASK, 0x20
j pop_label_p

label_3:
loadoffi 0
load METADATA_PORTMASK, 0x20
ori 0x1000
store METADATA_PORTMASK, 0x20
j pop_label_p

pop_label_p:
load (METADATA_PORTMASK+0x4), 0x8
cmpj pop_label, 0, 0x8
loadoffi 4
j pop_label

pop_label:
// check BoS bit
loadbe (HEADER_START+16), 0x10
andi 0x80
cmpj check_ttl_last, 1, 0x10
// just strip the tag and go away
j strip_upper_tag_pretty

check_ttl_last:
loadbe (HEADER_START+16), 0x10
sub (HEADER_START+26), 0x10
// simple overflow check, mpls < ip
cmpjg 0xfe00, copy_ttl_last, 0x10
j strip_upper_tag

copy_ttl_last:
loadbe (HEADER_START+16), 0x10
subi 0x1
storebe (HEADER_START+26), 0x10
j strip_upper_tag

strip_upper_tag:
// since we don't have alignment information, move two-byte chunks
loadbe (HEADER_START+12), 0x10
storebe (HEADER_START+16), 0x10
loadbe (HEADER_START+10), 0x10
storebe (HEADER_START+14), 0x10
loadbe (HEADER_START+8), 0x10
storebe (HEADER_START+12), 0x10
loadbe (HEADER_START+6), 0x10
storebe (HEADER_START+10), 0x10
loadbe (HEADER_START+4), 0x10
storebe (HEADER_START+8), 0x10
loadbe (HEADER_START+2), 0x10
storebe (HEADER_START+6), 0x10
loadbe (HEADER_START), 0x10
storebe (HEADER_START), 0x10
loadi ETHERTYPE_IP4
storebe (ETHERTYPE_ADDR+4), 0x10
loadoffi 0
j shrink_headers

strip_upper_tag_pretty:
// since we don't have alignment information, move two-byte chunks
loadbe (HEADER_START+12), 0x10
storebe (HEADER_START+16), 0x10
loadbe (HEADER_START+10), 0x10
storebe (HEADER_START+14), 0x10
loadbe (HEADER_START+8), 0x10
storebe (HEADER_START+12), 0x10
loadbe (HEADER_START+6), 0x10
storebe (HEADER_START+10), 0x10
loadbe (HEADER_START+4), 0x10
storebe (HEADER_START+8), 0x10
loadbe (HEADER_START+2), 0x10
storebe (HEADER_START+6), 0x10
loadbe (HEADER_START), 0x10
storebe (HEADER_START), 0x10
loadi ETHERTYPE_IP4
storebe (ETHERTYPE_ADDR+4), 0x10
loadoffi 0
j shrink_headers

shrink_headers:
load METADATA_START, 0x10
subi 0x4
store METADATA_START, 0x10
// header size increment
load (METADATA_START+2), 0x10
subi 0x4
store (METADATA_START+2), 0x10
// header_start decrement, 3rd byte is unused anyway
load (METADATA_START+4), 0x10
addi 0x4
store (METADATA_START+4), 0x10
j finish

control_plane:
loadoffi 0
load (METADATA_PORTMASK+0x7), 0x8
ori 0x80
store (METADATA_PORTMASK+0x7), 0x8
j finish

switch_to_l2:
j finish

finish:
