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

loadbe ETHERTYPE_ADDR, 0x10
cmpj ip4_proc, ETHERTYPE_IP4, 0x10
cmpj arp_proc, ETHERTYPE_ARP, 0x10
j finish

ip4_proc:
// check srcip
loadbe (HEADER_START+26), 0x10
rol 0x10
orbe (HEADER_START+28), 0x10
// 192.168.1.1? or tree with _exact_ ipv4 matches
cmpj check_dst, 0xc0010101, 0x20
j control_port

arp_proc:
// check tpa
loadbe (HEADER_START+38), 0x10
rol 0x10
orbe (HEADER_START+40), 0x10
// 172.112.192.1
cmpj check_dst_arp, 0xb070c001, 0x20
j control_port

check_dst_arp:
// spa
loadbe (HEADER_START+28), 0x10
rol 0x10
orbe (HEADER_START+30), 0x10
// 176.112.200.221
cmpj forward_port_arpmatch, 0xb070c8dd, 0x20
j control_port

check_dst:
loadbe (HEADER_START+30), 0x10
rol 0x10
orbe (HEADER_START+32), 0x10
// 192.168.1.2?
cmpj forward_port_ipmatch, 0xc0010102, 0x20
j control_port

forward_port_ipmatch:
// primitive which writes portmask and exits,
// in real world portmask is attached to a tree leaf
// and fires upon successful match, see L2 samples for this
load METADATA_PORTMASK, 0x20
ori 0x100
store METADATA_PORTMASK, 0x20
j finish

forward_port_arpmatch:
// primitive which writes portmask and exits,
// in real world portmask is attached to a tree leaf
// and fires upon successful match, see L2 samples for this
load METADATA_PORTMASK, 0x20
ori 0x80
store METADATA_PORTMASK, 0x20
j finish

control_port:
load (METADATA_PORTMASK+0x7), 0x8
ori 0x80
store (METADATA_PORTMASK+0x7), 0x8
j finish

finish:
