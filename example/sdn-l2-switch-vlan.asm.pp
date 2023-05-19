loadi 0
storemeta 8, 32
loadbe (((0x80000 - 0x40) - 0x80) + 6), 16
rol 32
orbe ((((0x80000 - 0x40) - 0x80) + 6) + 2), 32
rcr 48
orbe (((0x80000 - 0x40) - 0x80) + 12), 16
cmpj untagged, 0x0800, 16
xorbe (((0x80000 - 0x40) - 0x80) + 12), 16
orbe ((((0x80000 - 0x40) - 0x80) + 12) + 2), 16
ori (1 << 12)
rcl 48
j tree_1
untagged:
ror (128 - 48)
tree_1:
_36:
cmpjl _39, 0x3, 48
cmpjl _38, 0x4, 48
cmpjl _37, 0x5, 48
cmpj l_1_4, 0x5, 48
j _36_miss
_37:
cmpj l_1_3, 0x4, 48
j _36_miss
_38:
cmpj l_1_2, 0x3, 48
j _36_miss
_39:
cmpjl _40, 0x2, 48
cmpj l_1_1, 0x2, 48
j _36_miss
_40:
cmpj l_1_0, 0x1, 48
j _36_miss
_36_miss:
j table_0_miss
l_1_0:
rcr 48
cmpjn table_0_miss, 0x1002, 13
j table_2
l_1_1:
rcr 48
cmpjn table_0_miss, 0x1003, 13
j table_2
l_1_2:
rcr 48
_41:
cmpjl _42, 0x1014, 48
cmpj l_1_2_1, 0x1014, 48
j _41_miss
_42:
cmpj l_1_2_0, 0x100a, 48
j _41_miss
_41_miss:
j table_0_miss
l_1_2_0:
j table_2
l_1_2_1:
j table_2
l_1_3:
rcr 48
cmpjn table_0_miss, 0x0, 13
load ((0x80000 - 0x40) - 0x80), 32
store (((0x80000 - 0x40) - 0x80) - 4), 32
load (((0x80000 - 0x40) - 0x80) + 4), 32
store ((0x80000 - 0x40) - 0x80), 32
load (((0x80000 - 0x40) - 0x80) + 8), 32
store (((0x80000 - 0x40) - 0x80) + 4), 32
loadi 0x8100
storebe ((((0x80000 - 0x40) - 0x80) + 12) - 4), 16
loadi (3)
storebe ((((0x80000 - 0x40) - 0x80) + 12) - 2), 16
setsz (0x80 + 4)
loadi 1
storemeta 8, 32
j table_2
l_1_4:
rcr 48
cmpjn table_0_miss, 0x1002, 13
j table_2
table_0_miss:
setxmask (1 << 63)
table_2:
loadmeta 8, 32
cmpj was_tagged, 1, 32
loadoffi 4
was_tagged:
loadbe (((0x80000 - 0x40) - 0x80) - 4), 32
rol 16
orbe ((((0x80000 - 0x40) - 0x80) - 4) + 4), 16
rcr 48
orbe ((((0x80000 - 0x40) - 0x80) + 12) - 4), 16
cmpj untagged_, 0x0800, 16
xorbe ((((0x80000 - 0x40) - 0x80) + 12) - 4), 16
orbe (((((0x80000 - 0x40) - 0x80) + 12) - 4) + 2), 16
ori (1 << 12)
rcl 48
j tree_2
untagged_:
ror (128 - 48)
tree_2:
loadoffi 0
_43:
cmpjl _46, 0x3, 48
cmpjl _45, 0x4, 48
cmpjl _44, 0x5, 48
cmpj l_6, 0x5, 48
j _43_miss
_44:
cmpj l_5, 0x4, 48
j _43_miss
_45:
cmpj l_4, 0x3, 48
j _43_miss
_46:
cmpjl _47, 0x2, 48
cmpj l_3, 0x2, 48
j _43_miss
_47:
cmpj l_2, 0x1, 48
j _43_miss
_43_miss:
rcr 48
_48:
cmpjl _50, 0x100a, 48
cmpjl _49, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _48_miss
_49:
cmpj entry_8, 0x100a, 48
j _48_miss
_50:
cmpjl _51, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _48_miss
_51:
cmpj entry_6, 0x1002, 48
j _48_miss
_48_miss:
j table_1_miss
l_2:
rcr 48
_52:
cmpjl _54, 0x100a, 48
cmpjl _53, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _52_miss
_53:
cmpj entry_8, 0x100a, 48
j _52_miss
_54:
cmpjl _55, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _52_miss
_55:
cmpj entry_0, 0x1002, 48
j _52_miss
_52_miss:
j table_1_miss
l_3:
rcr 48
_56:
cmpjl _58, 0x100a, 48
cmpjl _57, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _56_miss
_57:
cmpj entry_8, 0x100a, 48
j _56_miss
_58:
cmpjl _59, 0x1003, 48
cmpj entry_1, 0x1003, 48
j _56_miss
_59:
cmpj entry_6, 0x1002, 48
j _56_miss
_56_miss:
j table_1_miss
l_4:
rcr 48
_60:
cmpjl _62, 0x100a, 48
cmpjl _61, 0x1014, 48
cmpj entry_3, 0x1014, 48
j _60_miss
_61:
cmpj entry_2, 0x100a, 48
j _60_miss
_62:
cmpjl _63, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _60_miss
_63:
cmpj entry_6, 0x1002, 48
j _60_miss
_60_miss:
j table_1_miss
l_5:
rcr 48
_64:
cmpjl _66, 0x100a, 48
cmpjl _65, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _64_miss
_65:
cmpj entry_8, 0x100a, 48
j _64_miss
_66:
cmpjl _67, 0x1003, 48
cmpj entry_4, 0x1003, 48
j _64_miss
_67:
cmpj entry_6, 0x1002, 48
j _64_miss
_64_miss:
j table_1_miss
l_6:
rcr 48
_68:
cmpjl _70, 0x100a, 48
cmpjl _69, 0x1014, 48
cmpj entry_9, 0x1014, 48
j _68_miss
_69:
cmpj entry_8, 0x100a, 48
j _68_miss
_70:
cmpjl _71, 0x1003, 48
cmpj entry_7, 0x1003, 48
j _68_miss
_71:
cmpj entry_5, 0x1002, 48
j _68_miss
_68_miss:
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
