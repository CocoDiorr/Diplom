#include "npu_de_defines.h"

#define ETHERTYPE_IP4 0x800
#define ETHERTYPE_VID 0x8100
#define ETHERTYPE_IP6 0x86dd
#define ETHERTYPE_ADDR      (HEADER_START+12)
#define ETHERTYPE_ADDR_TAG  (HEADER_START+16)
#define DMAC_ADDR     HEADER_START
#define SMAC_ADDR     (HEADER_START+6)

// determine how we should collect a hash
// for IP4/IP6/8021Q IP4/8021Q IP6 use saddr-daddr-smac tuple
// otherwise, use L2 smac/dmac/ethertype tuple
loadbe ETHERTYPE_ADDR, 0x10
cmpj tag_proc, ETHERTYPE_VID, 0x10
cmpj ip4_hash, ETHERTYPE_IP4, 0x10
cmpj ip6_hash, ETHERTYPE_IP6, 0x10
cmpj lacpdu_frame, 0x8809, 0x10
j l2_hash

lacpdu_frame:
load METADATA_PORTMASK, 0x10
// select fifth port which points to control plane
ori 0x10
store METADATA_PORTMASK, 0x10
j finish

tag_proc:
loadbe ETHERTYPE_ADDR_TAG, 0x10
cmpj ip4_hash_tagged, ETHERTYPE_IP4, 0x10
cmpj ip6_hash_tagged, ETHERTYPE_IP6, 0x10
j l2_hash_tagged

ip4_hash:
// check if tcp4/udp4, jump to port selection procedure
//32-33, 28-31, 26-27
loadbe HEADER_START+23, 0x8
cmpj ip4_tcpudp, 0x6, 0x8
cmpj ip4_tcpudp, 0x11, 0x8
loadbe HEADER_START+32, 0x10
rol 0x20
orbe HEADER_START+28, 0x20
rol 0x10
orbe HEADER_START+26, 0x10
// add 4 bytes from MSB SMAC/DMAC as well
xor DMAC_ADDR, 0x20
xor (SMAC_ADDR+2), 0x20
modi 3
j select_port

ip6_hash:
// check if tcp4/udp4, jump to port selection procedure
// 22..37 - SA 38..53 - DA
xorbe (HEADER_START+44), 0x20
xorbe (HEADER_START+48), 0x10
xorbe (HEADER_START+40), 0x20
xorbe (HEADER_START+36), 0x20
xorbe (HEADER_START+32), 0x20
xorbe (HEADER_START+28), 0x20
xorbe (HEADER_START+24), 0x20
xorbe (HEADER_START+22), 0x10
// lower 4 bytes of DMAC
xor DMAC_ADDR, 0x20
// lower 4 bytes of SMAC
xor (SMAC_ADDR+2), 0x20
modi 3
j select_port

ip4_hash_tagged:
// check if tcp4/udp4, jump to port selection procedure
//32-33, 28-31, 26-27
loadbe HEADER_START+27, 0x8
cmpj ip4_tcpudp_tagged, 0x6, 0x8
cmpj ip4_tcpudp_tagged, 0x11, 0x8
loadbe HEADER_START+36, 0x10
rol 0x20
orbe HEADER_START+32, 0x20
rol 0x10
orbe HEADER_START+30, 0x10
// add 4 bytes from MSB SMAC/DMAC as well
xor DMAC_ADDR, 0x20
xor (SMAC_ADDR+2), 0x20
modi 3
j select_port

ip4_tcpudp:
// xoring with existing proto num
xorbe (HEADER_START+28), 0x20
xorbe (HEADER_START+32), 0x20
xorbe (HEADER_START+36), 0x10
xorbe (HEADER_START+26), 0x10
modi 3
j select_port

ip4_tcpudp_tagged:
// xoring with existing proto num
xorbe (HEADER_START+32), 0x20
xorbe (HEADER_START+36), 0x20
xorbe (HEADER_START+40), 0x10
xorbe (HEADER_START+30), 0x10
modi 3
j select_port

ip6_hash_tagged:
xorbe (HEADER_START+48), 0x20
xorbe (HEADER_START+52), 0x10
xorbe (HEADER_START+44), 0x20
xorbe (HEADER_START+40), 0x20
xorbe (HEADER_START+36), 0x20
xorbe (HEADER_START+32), 0x20
xorbe (HEADER_START+28), 0x20
xorbe (HEADER_START+26), 0x10
// lower 4 bytes of DMAC
xor DMAC_ADDR, 0x20
// lower 4 bytes of SMAC
xor (SMAC_ADDR+2), 0x20
modi 3
j select_port

l2_hash:
//load smac/dmac
loadbe (HEADER_START), 0x20
xorbe (HEADER_START+4), 0x20
xorbe (HEADER_START+8), 0x20
xorbe ETHERTYPE_ADDR, 0x10
// select over three ports
modi 3
j select_port

l2_hash_tagged:
//load smac/dmac
loadbe (HEADER_START), 0x20
xorbe (HEADER_START+4), 0x20
xorbe (HEADER_START+8), 0x20
xorbe ETHERTYPE_ADDR_TAG, 0x10
// select over three ports
modi 3
j select_port

select_port:
cmpjg port_3, 0x1, 0x3
cmpjg port_2, 0x0, 0x3
load METADATA_PORTMASK, 0x10
ori 0x1 // defined by active LACP logic
store METADATA_PORTMASK, 0x10
j finish

port_3:
load METADATA_PORTMASK, 0x10
ori 0x4 // defined by active LACP logic
store METADATA_PORTMASK, 0x10
j finish

port_2:
load METADATA_PORTMASK, 0x10
ori 0x2 // defined by active LACP logic
store METADATA_PORTMASK, 0x10
j finish

finish:
