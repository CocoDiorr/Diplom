loadbe ((((0x80000)-(0x40))-(0x80))+12), 0x10
cmpjn switch_to_l2, 0x800, 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+30), 0x10
rol 0x10
orbe ((((0x80000)-(0x40))-(0x80))+32), 0x10
cmpjlge label_1, label_2, 0xb000000
label_1:
cmpjlge label_3, label_4, 0x09ffffff
label_2:
cmpjlge switch_to_l2, label_5, 0xac100100
label_3:
cmpjn switch_to_l2, 0x08080808, 0x20
j nexthop_a
label_4:
cmpjl nexthop_b, 0x0a010000, 0x20
j nexthop_a
label_5:
cmpjl nexthop_b, 0xac100200, 0x20
j switch_to_l2
nexthop_a:
loadi 0xa0cb
storebe (((0x80000)-(0x40))-(0x80)), 0x10
loadi 0x2cfc
storebe ((((0x80000)-(0x40))-(0x80))+2), 0x10
loadi 0xfbfa
storebe ((((0x80000)-(0x40))-(0x80))+4), 0x10
load (((0x80000)-(0x40))+8), 0x20
ori 0x1
store (((0x80000)-(0x40))+8), 0x20
j mpls_push_first
nexthop_b:
loadi 0x10fa
storebe (((0x80000)-(0x40))-(0x80)), 0x10
loadi 0x54ff
storebe ((((0x80000)-(0x40))-(0x80))+2), 0x10
loadi 0xaa11
storebe ((((0x80000)-(0x40))-(0x80))+4), 0x10
load (((0x80000)-(0x40))+8), 0x20
ori 0x2
store (((0x80000)-(0x40))+8), 0x20
loadi 0x1
store ((((0x80000)-(0x40))+8)+0x4), 0x8
j mpls_push_first
mpls_push_first:
loadi 0x324a
storebe ((((0x80000)-(0x40))-(0x80))+6), 0x10
loadi 0x51fa
storebe (((((0x80000)-(0x40))-(0x80))+6)+2), 0x10
loadi 0xfbfc
storebe (((((0x80000)-(0x40))-(0x80))+6)+4), 0x10
load (((0x80000)-(0x40))-(0x80)), 0x20
store ((((0x80000)-(0x40))-(0x80))-4), 0x20
load ((((0x80000)-(0x40))-(0x80))+4), 0x20
store ((((0x80000)-(0x40))-(0x80))), 0x20
load ((((0x80000)-(0x40))-(0x80))+8), 0x20
store ((((0x80000)-(0x40))-(0x80))+4), 0x20
load ((0x80000)-(0x40)), 0x10
addi 0x4
store ((0x80000)-(0x40)), 0x10
load (((0x80000)-(0x40))+2), 0x10
addi 0x4
store (((0x80000)-(0x40))+2), 0x10
load (((0x80000)-(0x40))+4), 0x10
subi 0x4
store (((0x80000)-(0x40))+4), 0x10
loadi 0x8847
storebe (((((0x80000)-(0x40))-(0x80))+12)-4), 0x10
loadi 0x400
ori 0x10000
rcr 0x18
orbe ((((0x80000)-(0x40))-(0x80))+22), 0x8
rcl 0x18
store (((((0x80000)-(0x40))-(0x80))+12)-2), 0x10
ror 0x10
store (((((0x80000)-(0x40))-(0x80))+12)), 0x10
j needs_tagging
needs_tagging:
load ((((0x80000)-(0x40))+8)+0x4), 0x8
cmpj finish, 0, 0x8
load ((((0x80000)-(0x40))-(0x80))-4), 0x20
store ((((0x80000)-(0x40))-(0x80))-8), 0x20
load (((0x80000)-(0x40))-(0x80)), 0x20
store ((((0x80000)-(0x40))-(0x80))-4), 0x20
load ((((0x80000)-(0x40))-(0x80))+4), 0x20
store (((0x80000)-(0x40))-(0x80)), 0x20
loadi 0x8100
storebe ((((0x80000)-(0x40))-(0x80))+4), 0x10
loadi 0x1005
storebe ((((0x80000)-(0x40))-(0x80))+6), 0x10
load ((0x80000)-(0x40)), 0x10
addi 0x4
store ((0x80000)-(0x40)), 0x10
load (((0x80000)-(0x40))+2), 0x10
addi 0x4
store (((0x80000)-(0x40))+2), 0x10
load (((0x80000)-(0x40))+4), 0x10
subi 0x4
store (((0x80000)-(0x40))+4), 0x10
j finish
switch_to_l2:
loadi 0
store ((((0x80000)-(0x40))+8)+0x4), 0x8
j finish
finish:
