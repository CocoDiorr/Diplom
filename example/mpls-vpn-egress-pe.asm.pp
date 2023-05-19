loadbe (((0x80000)-(0x40))-(0x80)), 0x20
rol 0x10
orbe (((0x80000)-(0x40))-(0x80))+4, 0x10
cmpjn switch_to_l2, 0x324a51fafbfc, 0x30
loadbe ((((0x80000)-(0x40))-(0x80))+12), 0x10
cmpj proc_vlan, 0x8100, 0x10
cmpj proc_mpls, 0x8847, 0x10
j switch_to_l2
proc_vlan:
load ((((0x80000)-(0x40))-(0x80))), 0x20
store ((((0x80000)-(0x40))-(0x80))+4), 0x20
load ((((0x80000)-(0x40))-(0x80))+4), 0x20
store ((((0x80000)-(0x40))-(0x80))+8), 0x20
load ((((0x80000)-(0x40))-(0x80))+8), 0x20
store ((((0x80000)-(0x40))-(0x80))+12), 0x20
load ((0x80000)-(0x40)), 0x10
subi 0x4
store ((0x80000)-(0x40)), 0x10
load (((0x80000)-(0x40))+2), 0x10
subi 0x4
store (((0x80000)-(0x40))+2), 0x10
load (((0x80000)-(0x40))+4), 0x10
addi 0x4
store (((0x80000)-(0x40))+4), 0x10
loadbe (((((0x80000)-(0x40))-(0x80))+12)+4), 0x10
cmpj proc_mpls_tagged, 0x8847, 0x10
j switch_to_l2
proc_mpls_tagged:
loadi 1
store ((((0x80000)-(0x40))+8)+0x4), 0x8
loadoffi 4
j proc_mpls
proc_mpls:
loadbe ((((0x80000)-(0x40))-(0x80))+17), 0x8
cmpjl control_plane, 0x2, 0x8
subi 1
storebe ((((0x80000)-(0x40))-(0x80))+17), 0x8
loadbe ((((0x80000)-(0x40))-(0x80))+14), 0x10
rol 0x8
loadbe ((((0x80000)-(0x40))-(0x80))+16), 0x8
ror 0x4
cmpj label_1, 0x3a, 0x14
cmpj label_2, 0x20, 0x14
cmpj label_3, 0x2, 0x14
j finish
label_1:
loadoffi 0
load (((0x80000)-(0x40))+8), 0x20
ori 0x4
store (((0x80000)-(0x40))+8), 0x20
j pop_label_p
label_2:
loadoffi 0
load (((0x80000)-(0x40))+8), 0x20
ori 0x10
store (((0x80000)-(0x40))+8), 0x20
j pop_label_p
label_3:
loadoffi 0
load (((0x80000)-(0x40))+8), 0x20
ori 0x1000
store (((0x80000)-(0x40))+8), 0x20
j pop_label_p
pop_label_p:
load ((((0x80000)-(0x40))+8)+0x4), 0x8
cmpj pop_label, 0, 0x8
loadoffi 4
j pop_label
pop_label:
loadbe ((((0x80000)-(0x40))-(0x80))+16), 0x10
andi 0x80
cmpj check_ttl_last, 1, 0x10
j strip_upper_tag_pretty
check_ttl_last:
loadbe ((((0x80000)-(0x40))-(0x80))+16), 0x10
sub ((((0x80000)-(0x40))-(0x80))+26), 0x10
cmpjg 0xfe00, copy_ttl_last, 0x10
j strip_upper_tag
copy_ttl_last:
loadbe ((((0x80000)-(0x40))-(0x80))+16), 0x10
subi 0x1
storebe ((((0x80000)-(0x40))-(0x80))+26), 0x10
j strip_upper_tag
strip_upper_tag:
loadbe ((((0x80000)-(0x40))-(0x80))+12), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+16), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+10), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+14), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+8), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+12), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+6), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+10), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+4), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+8), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+2), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+6), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))), 0x10
storebe ((((0x80000)-(0x40))-(0x80))), 0x10
loadi 0x800
storebe (((((0x80000)-(0x40))-(0x80))+12)+4), 0x10
loadoffi 0
load ((((0x80000)-(0x40))+8)+0x4), 0x8
ori 0x2
store ((((0x80000)-(0x40))+8)+0x4), 0x8
j shrink_headers
strip_upper_tag_pretty:
loadbe ((((0x80000)-(0x40))-(0x80))+12), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+16), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+10), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+14), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+8), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+12), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+6), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+10), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+4), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+8), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))+2), 0x10
storebe ((((0x80000)-(0x40))-(0x80))+6), 0x10
loadbe ((((0x80000)-(0x40))-(0x80))), 0x10
storebe ((((0x80000)-(0x40))-(0x80))), 0x10
loadi 0x800
storebe (((((0x80000)-(0x40))-(0x80))+12)+4), 0x10
loadoffi 0
j shrink_headers
shrink_headers:
load ((0x80000)-(0x40)), 0x10
subi 0x4
store ((0x80000)-(0x40)), 0x10
load (((0x80000)-(0x40))+2), 0x10
subi 0x4
store (((0x80000)-(0x40))+2), 0x10
load (((0x80000)-(0x40))+4), 0x10
addi 0x4
store (((0x80000)-(0x40))+4), 0x10
load ((((0x80000)-(0x40))+8)+0x4), 0x8
cmpj l3_proc_was_tagged, 0x3, 0x8
cmpj l3_proc, 0x2, 0x8
j finish
l3_proc_was_tagged:
loadoffi 8
j l3_nh
l3_proc:
loadoffi 4
j l3_nh
control_plane:
loadoffi 0
load ((((0x80000)-(0x40))+8)+0x7), 0x8
ori 0x80
store ((((0x80000)-(0x40))+8)+0x7), 0x8
j finish
l3_nh:
j finish
switch_to_l2:
j finish
finish:
