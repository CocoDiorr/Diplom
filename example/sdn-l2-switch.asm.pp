loadbe (((0x80000 - 0x40) - 0x80) + 6), 16
rol 32
orbe ((((0x80000 - 0x40) - 0x80) + 6) + 2), 32
_10:
cmpjl _13, 0x3, 48
cmpjl _12, 0x4, 48
cmpjl _11, 0x5, 48
cmpj l_1_4, 0x5, 48
j _10_miss
_11:
cmpj l_1_3, 0x4, 48
j _10_miss
_12:
cmpj l_1_2, 0x3, 48
j _10_miss
_13:
cmpjl _14, 0x2, 48
cmpj l_1_1, 0x2, 48
j _10_miss
_14:
cmpj l_1_0, 0x1, 48
j _10_miss
_10_miss:
setxmask (1 << 63)
j table_2
l_1_0:
j table_2
l_1_1:
j table_2
l_1_2:
j table_2
l_1_3:
j table_2
l_1_4:
table_2:
loadbe ((0x80000 - 0x40) - 0x80), 32
rol 16
orbe (((0x80000 - 0x40) - 0x80) + 4), 16
_15:
cmpjl _18, 0x3, 48
cmpjl _17, 0x4, 48
cmpjl _16, 0x5, 48
cmpj l_6, 0x5, 48
j _15_miss
_16:
cmpj l_5, 0x4, 48
j _15_miss
_17:
cmpj l_4, 0x3, 48
j _15_miss
_18:
cmpjl _19, 0x2, 48
cmpj l_3, 0x2, 48
j _15_miss
_19:
cmpj l_2, 0x1, 48
j _15_miss
_15_miss:
setxmask (1 << 63)
j finish
l_2:
setmask (1 << 1)
j finish
l_3:
setmask (1 << 2)
j finish
l_4:
setmask (1 << 3)
j finish
l_5:
setmask (1 << 4)
j finish
l_6:
setmask (1 << 5)
finish:
