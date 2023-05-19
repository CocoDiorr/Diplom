loadbe ((((0x80000)-(0x40))-(0x80))+12), 0x10
cmpj proc_vlan, 0x8100, 0x10
j check_dst
proc_vlan:
loadbe ((((0x80000)-(0x40))-(0x80)) + 14), 0x10
andi 0xfff
cmpj check_smac, 0x40, 0x18
j proc_dmac_last
check_smac:
loadbe ((((0x80000)-(0x40))-(0x80))+6), 0x10
rol 0x20
orbe ((((0x80000)-(0x40))-(0x80))+6)+2, 0x20
cmpj proc_dmac_last, 0x43a021fac010, 0x30
j control_port
proc_dmac_last:
loadbe (((0x80000)-(0x40))-(0x80)), 0x20
ror 0x8
cmpj storedm_and_forward, 0x3a5bca, 0x18
j control_port
loadbe ((((0x80000)-(0x40))-(0x80))+6), 0x10
rol 0x20
orbe ((((0x80000)-(0x40))-(0x80))+6)+2, 0x20
storedm_and_forward:
loadi 0x33b021fac010
storebe ((((0x80000)-(0x40))-(0x80))+6)+2, 0x20
ror 0x20
storebe ((((0x80000)-(0x40))-(0x80))+6), 0x10
load (((0x80000)-(0x40))+8), 0x20
ori 0x80
store (((0x80000)-(0x40))+8), 0x20
j finish
check_dst:
loadbe (((0x80000)-(0x40))-(0x80)), 0x10
cmpjn finish, 0xc0da, 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+6), 0x20
ror 0x8
cmpj check_vlan_bcast, 0xffffff, 0x18
j finish
check_vlan_bcast:
loadbe ((((0x80000)-(0x40))-(0x80))+12), 0x10
cmpj proc_vlan_bcast, 0x8100, 0x10
j proc_bcast
proc_bcast:
loadi 0xffffffffffff
storebe (((0x80000)-(0x40))-(0x80))+4, 0x10
ror 0x10
storebe (((0x80000)-(0x40))-(0x80)), 0x20
load (((0x80000)-(0x40))+8), 0x20
ori 0x3
store (((0x80000)-(0x40))+8), 0x20
j finish
proc_vlan_bcast:
loadi 0xffffffffffff
storebe (((0x80000)-(0x40))-(0x80))+4, 0x10
ror 0x10
storebe (((0x80000)-(0x40))-(0x80)), 0x20
loadbe ((((0x80000)-(0x40))-(0x80)) + 14), 0x10
andi 0xf010
storebe ((((0x80000)-(0x40))-(0x80)) + 14), 0x10
load (((0x80000)-(0x40))+8), 0x20
ori 0x100
store (((0x80000)-(0x40))+8), 0x20
j finish
control_port:
load ((((0x80000)-(0x40))+8)+0x7), 0x8
ori 0x80
store ((((0x80000)-(0x40))+8)+0x7), 0x8
j finish
bail_out:
j finish
finish:
