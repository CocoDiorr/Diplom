table_2:
loadbe ((0x80000 - 0x40) - 0x80), 32
rol 16
orbe (((0x80000 - 0x40) - 0x80) + 4), 16
rcr 48
orbe (((0x80000 - 0x40) - 0x80) + 12), 16
cmpj untagged_, 0x0800, 16
xorbe (((0x80000 - 0x40) - 0x80) + 12), 16
orbe ((((0x80000 - 0x40) - 0x80) + 12) + 2), 16
ori (1 << 12)
rcl 48
j tree_2
untagged_:
ror (128 - 48)
tree_2:
loadoffi 0
_0:
cmpjl _3, 0x3, 48
cmpjl _2, 0x4, 48
cmpjl _1, 0x5, 48
cmpj l_6, 0x5, 48
j _0_miss
_1:
cmpj l_5, 0x4, 48
j _0_miss
_2:
cmpj l_4, 0x3, 48
j _0_miss
_3:
cmpjl _4, 0x2, 48
cmpj l_3, 0x2, 48
j _0_miss
_4:
cmpj l_2, 0x1, 48
j _0_miss
_0_miss:
rcr 48
_5:
cmpjl _7, 0x100a, 48
cmpjl _6, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _5_miss
_6:
cmpj entry_8, 0x100a, 48
j _5_miss
_7:
cmpjl _8, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _5_miss
_8:
cmpj entry_6, 0x1002, 48
j _5_miss
_5_miss:
j table_1_miss
l_2:
rcr 48
_9:
cmpjl _11, 0x100a, 48
cmpjl _10, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _9_miss
_10:
cmpj entry_8, 0x100a, 48
j _9_miss
_11:
cmpjl _12, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _9_miss
_12:
cmpj entry_0, 0x1002, 48
j _9_miss
_9_miss:
j table_1_miss
l_3:
rcr 48
_13:
cmpjl _15, 0x100a, 48
cmpjl _14, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _13_miss
_14:
cmpj entry_8, 0x100a, 48
j _13_miss
_15:
cmpjl _16, 0x1003, 48
cmpj entry_1, 0x1003, 48
j _13_miss
_16:
cmpj entry_6, 0x1002, 48
j _13_miss
_13_miss:
j table_1_miss
l_4:
rcr 48
_17:
cmpjl _19, 0x100a, 48
cmpjl _18, 0x1014, 48
cmpj entry_3, 0x1014, 48
j _17_miss
_18:
cmpj entry_2, 0x100a, 48
j _17_miss
_19:
cmpjl _20, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _17_miss
_20:
cmpj entry_6, 0x1002, 48
j _17_miss
_17_miss:
j table_1_miss
l_5:
rcr 48
_21:
cmpjl _23, 0x100a, 48
cmpjl _22, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _21_miss
_22:
cmpj entry_8, 0x100a, 48
j _21_miss
_23:
cmpjl _24, 0x1003, 48
cmpj entry_4, 0x1003, 48
j _21_miss
_24:
cmpj entry_6, 0x1002, 48
j _21_miss
_21_miss:
j table_1_miss
l_6:
rcr 48
_25:
cmpjl _27, 0x100a, 48
cmpjl _26, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _25_miss
_26:
cmpj entry_8, 0x100a, 48
j _25_miss
_27:
cmpjl _28, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _25_miss
_28:
cmpj entry_5, 0x1002, 48
j _25_miss
_25_miss:
j table_1_miss
table_1_miss:
setxmask (1 << 63)
j finish
entry_0:
setmask (1 << 0)
j finish
entry_1:
setmask (1 << 1)
j finish
entry_2:
setmask (1 << 2)
j finish
entry_3:
setmask (1 << 2)
j finish
entry_4:
setmask (1 << 3)
j finish
entry_5:
setmask (1 << 4)
j finish
entry_6:
load ((0x80000 - 0x40) + 16), 8
cmpj not_0, 0, 8
setmask (1 << 0)
not_0:
load ((0x80000 - 0x40) + 16), 8
cmpj finish, 4, 8
setmask (1 << 4)
j finish
entry_7:
load ((0x80000 - 0x40) + 16), 8
cmpj not_1, 1, 8
setmask (1 << 1)
not_1:
load ((0x80000 - 0x40) + 16), 8
cmpj finish, 3, 8
setmask (1 << 3)
j finish
entry_8:
j group_2
entry_9:
group_2:
load ((0x80000 - 0x40) + 16), 8
cmpj not_2, 2, 8
setmask (1 << 2)
not_2:
load ((0x80000 - 0x40) + 16), 8
cmpj finish, 5, 8
setmask (1 << 5)
finish:
