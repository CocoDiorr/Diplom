loadbe ((((0x80000)-(0x40))-(0x80))+12), 0x10
cmpj tag_proc, 0x8100, 0x10
j finish
tag_proc:
loadbe ((((0x80000)-(0x40))-(0x80)) + 14), 0x10
andi 0xfff
cmpjn finish, 0x4f, 0x10
load (((0x80000)-(0x40))+8), 0x20
ori 0x200
store (((0x80000)-(0x40))+8), 0x20
j finish
finish:
