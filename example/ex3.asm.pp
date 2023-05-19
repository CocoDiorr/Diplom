load (((0x80000)-(0x40))-(0x80)), (0x30)
cmpj zero_dst, (0xffffffffffff), (0x30)
j port0_dst
zero_dst:
loadi 0
j set_portmask
port0_dst:
loadi 1
set_portmask:
store (((0x80000)-(0x40))+8), (0x40)
finish:
