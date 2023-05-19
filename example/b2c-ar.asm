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

loadbe ETHERTYPE_ADDR, 0x10
cmpj tag_proc, ETHERTYPE_VID, 0x10
j finish

tag_proc:
// loading vlan id
loadbe (HEADER_START + 14), 0x10
andi 0xfff
cmpjn finish, 0x4f, 0x10
load METADATA_PORTMASK, 0x20
ori 0x200
store METADATA_PORTMASK, 0x20
j finish

finish:
