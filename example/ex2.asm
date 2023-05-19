#include "npu_de_defines.h"

#define ETHERTYPE_ADDR      (HEADER_START+12)
#define VLAN_ETHERTYPE_ADDR (HEADER_START+16)
#define TOS_ADDR            (HEADER_START+15)
#define VLAN_TOS_ADDR       (HEADER_START+19)

#define ETHERTYPE_IPV4      0x0800
#define ETHERTYPE_VLAN      0x8100

// first byte is a zero byte, header size is 128 bytes
// at the end of address space (0x4000 - 0x80)
// load ethertype in the accumulator (12-13th byte)
loadbe ETHERTYPE_ADDR, 0x10
// since value is already truncated, mask is omitted
cmpj vlan_proc, ETHERTYPE_VLAN, 0x10
cmpj ip4_proc, ETHERTYPE_IPV4, 0x10
j finish

// load vlan.ethertype in the accumulator (16-17th byte)
vlan_proc:
loadbe VLAN_ETHERTYPE_ADDR, 0x10
// if vlan.ethertype is not 0x0800, stop
cmpjn finish, ETHERTYPE_IPV4, 0x80
// load vlan.tos field to acc
load VLAN_TOS_ADDR, 0x08
// check if tos > 3
cmpjl finish, 0x4, 0x80
// load replacement value from given address
load tos_fixed, 0x08
// write vlan.tos header back and we are done
store VLAN_TOS_ADDR, 0x08
j finish

tos_fixed:
0x2
// load tos field to acc
ip4_proc:
load TOS_ADDR, 0x8
cmpjl finish, 0x4, 0x80
load tos_fixed, 0x08
// write tos header back
store TOS_ADDR, 0x08
finish:
