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
j finish

proc_vlan:
loadbe (HEADER_START + 14), 0x10
andi 0xfff
// VID 64
cmpj check_dmac, 0x40, 0x18
j finish

check_dmac:
loadbe DMAC_ADDR, 0x20
rol 0x10
orbe DMAC_ADDR+4, 0x10
cmpj send_out_dm, 0x43a021fac010, 0x30
j check_smac

check_smac:
loadbe SMAC_ADDR, 0x10
rol 0x20
orbe SMAC_ADDR+2, 0x20
cmpj send_out_sm, 0x40c020fac010, 0x30
// or, if we have different input group, to port+vlan output queue...
j control_port

send_out_dm:
load METADATA_PORTMASK, 0x20
// add some port
ori 0x80
store METADATA_PORTMASK, 0x20
j finish

send_out_sm:
load METADATA_PORTMASK, 0x20
ori 0x22
store METADATA_PORTMASK, 0x20
j finish

control_port:
load (METADATA_PORTMASK+0x7), 0x8
ori 0x80
store (METADATA_PORTMASK+0x7), 0x8
j finish

finish:
