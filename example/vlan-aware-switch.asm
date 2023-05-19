// note that all masks for jump branches are unnecessary,
// but since we don't have packed ISA, we use them anyway
//
// we have three mac addresses in untagged segment and four ports:
// 0x00e04c61ebbf - port 0
// 0xac3743e0fffb - port 0
// 0x40b4cd1eda2d - port 2
// 
//
// and four in vlan 5:
// 0xac3743e0fffb - port 0
// 0x00e04c61ebbf - port 0
// 0x283737160b8f - port 3
// 0x10f1f288ef2f - port 1
//

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
// we will use empty space within the port mask to store conditionals
// untagged segment distinguisher
#define ARP_TAGGED   0xc0
#define UNTAGGED     0x20
#define TAGGED       0x40
#define ARP          0x80
#define FIRSTRUN     0x100
#define PHYSICAL_PORTS 0xffffff


// load ethertype into accumulator
loadbe ETHERTYPE_ADDR, 0x10
cmpj tag_proc, ETHERTYPE_VID, 0x10
cmpj untag_proc, ETHERTYPE_IP4, 0x10
cmpj untag_proc, ETHERTYPE_ARP, 0x10
j flood_all_ports

tag_proc:
// loading vlan id
loadbe (HEADER_START + 14), 0x10
andi 0xfff
cmpj proc_vlan5, 0x5, 0xc
// we don't have other active vlan segments, so stopping
j finish

proc_vlan5:
loadbe ETHERTYPE_ADDR_TAG, 0x10
cmpj proc_vlan5_known_v4, ETHERTYPE_IP4, 0x10
cmpj proc_vlan5_known_arp, ETHERTYPE_ARP, 0x10
j flood_all_ports

proc_vlan5_known_v4:
load (METADATA_PORTMASK+0x4), 0x10
ori TAGGED
store (METADATA_PORTMASK+0x4), 0x10
j proc_vlan5_common

proc_vlan5_known_arp:
load (METADATA_PORTMASK+0x4), 0x10
ori ARP_TAGGED
store (METADATA_PORTMASK+0x4), 0x10
j proc_vlan5_common

proc_vlan5_common:
load (METADATA_PORTMASK+0x4), 0x10
cmpjg src_process_vlan5, (FIRSTRUN + TAGGED - 1), 0x10
cmpjg arp_dest_process_vlan5, (ARP_TAGGED - 1), 0x10
loadbe DMAC_ADDR, 0x20
rol 0x10
orbe DMAC_ADDR+4, 0x10
cmpj broadcast_dmac, BROADCAST_ADDR, 0x30
j search_mac_vlan5

src_process_vlan5:
loadbe SMAC_ADDR, 0x10
rol 0x20
orbe SMAC_ADDR+2, 0x20
j search_mac_vlan5

arp_dest_process_vlan5:
loadbe DMAC_ADDR, 0x20
rol 0x10
orbe DMAC_ADDR+4, 0x10
cmpj broadcast_dmac, BROADCAST_ADDR, 0x30
j search_mac_vlan5

untag_proc:
loadbe ETHERTYPE_ADDR, 0x10
cmpj proc_known_v4, ETHERTYPE_IP4, 0x10
// taking a shortcut as we analyzed ethertype already on this branch
j proc_known_arp

proc_known_v4:
load (METADATA_PORTMASK+0x4), 0x10
ori UNTAGGED
store (METADATA_PORTMASK+0x4), 0x10
j proc_common

proc_known_arp:
load (METADATA_PORTMASK+0x4), 0x10
ori ARP
store (METADATA_PORTMASK+0x4), 0x10
j proc_common

proc_common:
cmpjg src_process, (FIRSTRUN + ARP - 1), 0x10
cmpjg arp_dest_process, (ARP - 1), 0x10
loadbe DMAC_ADDR, 0x20
rol 0x10
orbe DMAC_ADDR+4, 0x10
cmpj broadcast_dmac, BROADCAST_ADDR, 0x30
j search_mac

src_process:
loadbe SMAC_ADDR, 0x10
rol 0x20
orbe SMAC_ADDR+2, 0x20
j search_mac

arp_dest_process:
loadbe DMAC_ADDR, 0x20
rol 0x10
orbe DMAC_ADDR+4, 0x10
cmpj broadcast_dmac, BROADCAST_ADDR, 0x30
j search_mac

broadcast_dmac:
load METADATA_PORTMASK, 0x20
ori PHYSICAL_PORTS
store METADATA_PORTMASK, 0x20
load (METADATA_PORTMASK+0x4), 0x10
ori FIRSTRUN
j select_second

search_mac_vlan5:
//
//                     0x1c9494cf7d5f
//                     /             \
//           0_0x8E91f756d77        1_0x6a373d7b85c5
//            /        |              |              \
// 2_0x00e04c61ebbf 3_0x10f1f288ef2f 4_0x283737160b8f 5_0xac3743e0fffb
cmpjl compare5_0, 0x1c9494cf7d5f, 0x30
cmpjl compare5_4, 0x6a373d7b85c5, 0x30
cmpj port_0, 0xac3743e0fffb, 0x30
j mac_not_found
compare5_0:
cmpjl compare5_2, 0x8E91f756d77, 0x30
cmpj port_1, 0x10f1f288ef2f, 0x30
j mac_not_found
compare5_2:
cmpj port_0, 0xe04c61ebbf, 0x30
j mac_not_found
compare5_4:
cmpj port_3, 0x283737160b8f, 0x30
j mac_not_found

port_0:
load METADATA_PORTMASK, PORTMASK_SIZE
ori 0x1
j store_dport
port_1:
load METADATA_PORTMASK, PORTMASK_SIZE
ori 0x2
j store_dport
port_2:
load METADATA_PORTMASK, PORTMASK_SIZE
ori 0x4
j store_dport
port_3:
load METADATA_PORTMASK, PORTMASK_SIZE
ori 0x8
j store_dport

search_mac:
//             0x20ca8cc062f6
//            /              \
//   0_0xe04c61ebbf  1_0x7676087fEd14
//                    /              \
//            2_0x40b4cd1eda2d 3_0xac3743e0fffb
cmpjl compare_0, 0x20ca8cc062f6, 0x30
cmpjl compare_2, 0x7676087fEd14, 0x30
cmpj port_0, 0xac3743e0fffb, 0x30
j mac_not_found
compare_0:
cmpj port_0, 0xe04c61ebbf, 0x30
j mac_not_found
compare_2:
cmpj port_2, 0x40b4cd1eda2d, 0x30
j mac_not_found

store_dport:
// add 0x100, portmask for physical port and reprocess
// for known smac on second run, just stop
store METADATA_PORTMASK, 0x20
load (METADATA_PORTMASK+0x4), 0x10
cmpjg finish, FIRSTRUN, 0x10
ori FIRSTRUN
j select_second

mac_not_found:
// add control port
load (METADATA_PORTMASK+0x7), 0x8
ori 0x80
store (METADATA_PORTMASK+0x7), 0x8
// check if we are eligible for a second run..
load (METADATA_PORTMASK+0x4), 0x10
cmpjg finish, FIRSTRUN, 0x10
// on first run, also increment run counter
// and store mask for unknown dmac
ori FIRSTRUN
store (METADATA_PORTMASK+0x4), 0x10
load METADATA_PORTMASK, 0x20
ori PHYSICAL_PORTS
store METADATA_PORTMASK, 0x20
load (METADATA_PORTMASK+0x4), 0x10
j select_second

select_second:
store (METADATA_PORTMASK+0x4), 0x10
cmpjg proc_vlan5_common, (FIRSTRUN + ARP_TAGGED - 1), 0x10
cmpjg proc_common, (FIRSTRUN + ARP - 1), 0x10
cmpjg proc_vlan5_common, (FIRSTRUN + TAGGED - 1), 0x10
j proc_common

// for unknown protocols, don't do tree search and stuff
flood_all_ports:
loadi PHYSICAL_PORTS
store METADATA_PORTMASK, 0x20
load (METADATA_PORTMASK+0x7), 0x8
ori 0x80
store (METADATA_PORTMASK+0x7), 0x8
j finish

finish:
// clear temporary bits
load (METADATA_PORTMASK+0x4), 0x10
andi 0
store (METADATA_PORTMASK+0x4), 0x10
