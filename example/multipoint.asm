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


loadbe ETHERTYPE_ADDR, 0x10
cmpj proc_vlan, ETHERTYPE_VID, 0x10
j check_dst

proc_vlan:
loadbe (HEADER_START + 14), 0x10
andi 0xfff
// VID 64
cmpj check_smac, 0x40, 0x18
j proc_dmac_last

check_smac:
// load smac
loadbe SMAC_ADDR, 0x10
rol 0x20
orbe SMAC_ADDR+2, 0x20
cmpj proc_dmac_last, 0x43a021fac010, 0x30
j control_port

proc_dmac_last:
// load last 24 bits of DMAC
loadbe DMAC_ADDR, 0x20
ror 0x8
cmpj storedm_and_forward, 0x3a5bca, 0x18
j control_port

loadbe SMAC_ADDR, 0x10
rol 0x20
orbe SMAC_ADDR+2, 0x20

storedm_and_forward:
loadi 0x33b021fac010
storebe SMAC_ADDR+2, 0x20
ror 0x20
storebe SMAC_ADDR, 0x10
load METADATA_PORTMASK, 0x20
// add some port
ori 0x80
store METADATA_PORTMASK, 0x20
j finish

check_dst:
loadbe DMAC_ADDR, 0x10
cmpjn finish, 0xc0da, 0x10
loadbe SMAC_ADDR, 0x20
ror 0x8
cmpj check_vlan_bcast, 0xffffff, 0x18
j finish

check_vlan_bcast:
loadbe ETHERTYPE_ADDR, 0x10
cmpj proc_vlan_bcast, ETHERTYPE_VID, 0x10
j proc_bcast

proc_bcast:
loadi 0xffffffffffff
storebe DMAC_ADDR+4, 0x10
ror 0x10
storebe DMAC_ADDR, 0x20
load METADATA_PORTMASK, 0x20
// add some other port
ori 0x3
store METADATA_PORTMASK, 0x20
j finish


proc_vlan_bcast:
loadi 0xffffffffffff
storebe DMAC_ADDR+4, 0x10
ror 0x10
storebe DMAC_ADDR, 0x20
// replace vlan tag to vid 16
loadbe (HEADER_START + 14), 0x10
// pcp/dei bits are 0xf000
andi 0xf010
storebe (HEADER_START + 14), 0x10
load METADATA_PORTMASK, 0x20
// add some other port
ori 0x100
store METADATA_PORTMASK, 0x20
j finish

control_port:
load (METADATA_PORTMASK+0x7), 0x8
ori 0x80
store (METADATA_PORTMASK+0x7), 0x8
j finish

bail_out:
j finish

finish:
