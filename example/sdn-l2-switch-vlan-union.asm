// Defines for emulator.
#define MEMORY_SIZE       0x80000
#define METADATA_SIZE     0x40
#define METADATA_START    (MEMORY_SIZE - METADATA_SIZE)
#define METADATA_INPORT   (METADATA_START + 16)
#define METADATA_PORTMASK (METADATA_START + 8)
#define HEADER_SIZE       0x80
#define HEADER_START      (METADATA_START - HEADER_SIZE)

#define COUNTER_INC(id)

// Defines for header fields.
#define ETH_DST_ADDR HEADER_START
#define ETH_SRC_ADDR (HEADER_START + 6)
#define ETHERTYPE_ADDR (HEADER_START + 12)

// Macros for actions.
#define PUSH_SET_VLAN(value) load HEADER_START, 32; /* Move the beginning of the header to push tag. */ \
                             store (HEADER_START - 4), 32;\
                             load (HEADER_START + 4), 32;\
                             store HEADER_START, 32;\
                             load (HEADER_START + 8), 32;\
                             store (HEADER_START + 4), 32;\
                             loadi 0x8100; /* Write TPID. */ \
                             storebe (ETHERTYPE_ADDR - 4), 16;\
                             loadi (value); /* Write VID. */ \
                             storebe (ETHERTYPE_ADDR - 2), 16;\
                             setsz (HEADER_SIZE + 4)

// Defines for ports.
#define CTRL_PORT 63

// First flow table.
/* +----+-------------------+----------+----------+------------------------------------+
   | No |      ETH_SRC      | VLAN_VID | Priority |            Instructions            |
   |    |                   |          |          |                                    |
   +----+-------------------+----------+----------+------------------------------------+
   | 0  | :1                | 2        | 1        | goto_table 1                       |
   +----+-------------------+----------+----------+------------------------------------+
   | 1  | :2                | 3        | 1        | goto_table 1                       |
   +----+-------------------+----------+----------+------------------------------------+
   | 2  | :3                | 10       | 1        | goto_table 1                       |
   +----+-------------------+----------+----------+------------------------------------+
   | 3  | :3                | 20       | 1        | goto_table 1                       |
   +----+-------------------+----------+----------+------------------------------------+
   | 4  | :4                | NONE     | 1        | Push-Tag 0x8100,                   |
   |    |                   |          |          | Set-Field VLAN_VID 3, goto_table 1 |
   +----+-------------------+----------+----------+------------------------------------+
   | 5  | :5                | 2        | 1        | goto_table 1                       |
   +----+-------------------+----------+----------+------------------------------------+
   | 6  | *                 | *        | 0        | output CTRL, goto_table 1          |
   +----+-------------------+----------+----------+------------------------------------+
*/
// Second flow table.
/* +----+-------------------+----------+----------+------------------------------------+
   | No |      ETH_DST      | VLAN_VID | Priority |            Instructions            |
   |    |                   |          |          |                                    |
   +----+-------------------+----------+----------+------------------------------------+
   | 0  | :1                | 2        | 2        | output 0                           |
   +----+-------------------+----------+----------+------------------------------------+
   | 1  | :2                | 3        | 2        | output 1                           |
   +----+-------------------+----------+----------+------------------------------------+
   | 2  | :3                | 10       | 2        | output 2                           |
   +----+-------------------+----------+----------+------------------------------------+
   | 3  | :3                | 20       | 2        | output 2                           |
   +----+-------------------+----------+----------+------------------------------------+
   | 4  | :4                | 3        | 2        | output 3                           |
   +----+-------------------+----------+----------+------------------------------------+
   | 5  | :5                | 2        | 2        | output 4                           |
   +----+-------------------+----------+----------+------------------------------------+
   | 6  | *                 | 2        | 1        | group 0                            |
   +----+-------------------+----------+----------+------------------------------------+
   | 7  | *                 | 3        | 1        | group 1                            |
   +----+-------------------+----------+----------+------------------------------------+
   | 8  | *                 | 10       | 1        | group 2                            |
   +----+-------------------+----------+----------+------------------------------------+
   | 9  | *                 | 20       | 1        | group 2                            |
   +----+-------------------+----------+----------+------------------------------------+
   | 10 | *                 | *        | 0        | output CTRL                        |
   +----+-------------------+----------+----------+------------------------------------+
*/
// Group table.
/* +----------+------------+------------------------+
   | Group ID | Group Type |     Action Buckets     |
   |          |            |                        |
   +----------+------------+------------------------+
   | 0        | ALL        | {output 0}, {output 4} |
   +----------+------------+------------------------+ 
   | 1        | ALL        | {output 1}, {output 3} |
   +----------+------------+------------------------+ 
   | 2        | ALL        | {output 2}, {output 5} |
   +----------+------------+------------------------+    
*/
// Union flow table.
/* +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | No1 | No2 | ETH_DST | ETH_SRC | VLAN_VID | Priority1 | Priority2 |            Instructions            |
   |     |     |         |         |          |           |           |                                    |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 0   | 0   | :1      | :1      | 2        | 1         | 2         | output 0                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 5   | 0   | :1      | :5      | 2        | 1         | 2         | output 0                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 0   | :1      | *       | 2        | 0         | 2         | output 0, output CTRL              |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 1   | 1   | :2      | :2      | 3        | 1         | 2         | output 1                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 4   | 1   | :2      | :4      | NONE     | 1         | 2         | Push-Tag 0x8100,                   |
   |     |     |         |         |          |           |           | Set-Field VLAN_VID 3, output 1     |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 1   | :2      | *       | 3        | 0         | 2         | output 1, output CTRL              |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 2   | 2   | :3      | :3      | 10       | 1         | 2         | output 2                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 3   | 3   | :3      | :3      | 20       | 1         | 2         | output 2                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 2   | :3      | *       | 10       | 0         | 2         | output 2, output CTRL              |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 3   | :3      | *       | 20       | 0         | 2         | output 2, output CTRL              |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 4   | 4   | :4      | :4      | NONE     | 1         | 2         | Push-Tag 0x8100,                   |
   |     |     |         |         |          |           |           | Set-Field VLAN_VID 3, output 3     |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 1   | 4   | :4      | :2      | 3        | 1         | 2         | output 3                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 4   | :4      | *       | 3        | 0         | 2         | output 3, output CTRL              |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 0   | 5   | :5      | :1      | 2        | 1         | 2         | output 4                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 5   | 5   | :5      | :5      | 2        | 1         | 2         | output 4                           |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 5   | :5      | *       | 2        | 0         | 2         | output 4, output CTRL              |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 0   | 6   | *       | :1      | 2        | 1         | 1         | group 0                            |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 1   | 7   | *       | :2      | 3        | 1         | 1         | group 1                            |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 2   | 8   | *       | :3      | 10       | 1         | 1         | group 2                            |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 3   | 9   | *       | :3      | 20       | 1         | 1         | group 2                            |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 4   | 7   | *       | :4      | NONE     | 1         | 1         | Push-Tag 0x8100,                   |
   |     |     |         |         |          |           |           | Set-Field VLAN_VID 3, group 1      |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 5   | 6   | *       | :5      | 2        | 1         | 1         | group 0                            |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 6   | *       | *       | 2        | 0         | 1         | group 0, output CTRL               |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 7   | *       | *       | 3        | 0         | 1         | group 1, output CTRL               |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 8   | *       | *       | 10       | 0         | 1         | group 2, output CTRL               |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 9   | *       | *       | 20       | 0         | 1         | group 2, output CTRL               |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
   | 6   | 10  | *       | *       | *        | 0         | 0         | output CTRL                        |
   +-----+-----+---------+---------+----------+-----------+-----------+------------------------------------+
*/
// Load ETH_DST, ETH_SRC and VLAN_VID fields in accumulator.
loadbe ETHERTYPE_ADDR, 16
cmpjn tagged, 0x0800, 16
loadi 0
j eth_src
tagged:
xorbe ETHERTYPE_ADDR, 16 // Set accumulator to zero back.
orbe (ETHERTYPE_ADDR + 2), 16
ori (1 << 12) // Valid VLAN bit.
rol 16
eth_src:
orbe ETH_SRC_ADDR, 16
rol 32
orbe (ETH_SRC_ADDR + 2), 32
rol 32
orbe ETH_DST_ADDR, 32
rol 16
orbe (ETH_DST_ADDR + 4), 16
// Now accumulator value is <valid bit, VLAN_VID, ETH_SRC, ETH_DST> (big-endian notation).
tree_in "Tree_union/union"
ror 48
tree_in "Tree_union/union_0"
ror 48
tree_in "Tree_union/union_0_0"
j entry_6_10
l_0_1:
ror 48
tree_in "Tree_union/union_0_1"
j entry_6_10
l_0_2:
ror 48
tree_in "Tree_union/union_0_2"
j entry_6_10
l_0_3:
ror 48
tree_in "Tree_union/union_0_3"
j entry_6_10
l_0_4:
ror 48
tree_in "Tree_union/union_0_4"
j entry_6_10
l_0_5:
ror 48
tree_in "Tree_union/union_0_5"
j entry_6_10
l_1:
ror 48
tree_in "Tree_union/union_1"
ror 48
tree_in "Tree_union/union_1_0"
j entry_6_10
l_1_1:
ror 48
tree_in "Tree_union/union_1_1"
j entry_6_10
l_1_2:
ror 48
tree_in "Tree_union/union_1_2"
j entry_6_10
l_1_3:
ror 48
tree_in "Tree_union/union_1_3"
j entry_6_10
l_1_4:
ror 48
tree_in "Tree_union/union_1_4"
j entry_6_10
l_1_5:
ror 48
tree_in "Tree_union/union_1_5"
j entry_6_10
l_2:
ror 48
tree_in "Tree_union/union_2"
ror 48
tree_in "Tree_union/union_2_0"
j entry_6_10
l_2_1:
ror 48
tree_in "Tree_union/union_2_1"
j entry_6_10
l_2_2:
ror 48
tree_in "Tree_union/union_2_2"
j entry_6_10
l_2_3:
ror 48
tree_in "Tree_union/union_2_3"
j entry_6_10
l_2_4:
ror 48
tree_in "Tree_union/union_2_4"
j entry_6_10
l_2_5:
ror 48
tree_in "Tree_union/union_2_5"
j entry_6_10
l_3:
ror 48
tree_in "Tree_union/union_3"
ror 48
tree_in "Tree_union/union_3_0"
j entry_6_10
l_3_1:
ror 48
tree_in "Tree_union/union_3_1"
j entry_6_10
l_3_2:
ror 48
tree_in "Tree_union/union_3_2"
j entry_6_10
l_3_3:
ror 48
tree_in "Tree_union/union_3_3"
j entry_6_10
l_3_4:
ror 48
tree_in "Tree_union/union_3_4"
j entry_6_10
l_3_5:
ror 48
tree_in "Tree_union/union_3_5"
j entry_6_10
l_4:
ror 48
tree_in "Tree_union/union_4"
ror 48
tree_in "Tree_union/union_4_0"
j entry_6_10
l_4_1:
ror 48
tree_in "Tree_union/union_4_1"
j entry_6_10
l_4_2:
ror 48
tree_in "Tree_union/union_4_2"
j entry_6_10
l_4_3:
ror 48
tree_in "Tree_union/union_4_3"
j entry_6_10
l_4_4:
ror 48
tree_in "Tree_union/union_4_4"
j entry_6_10
l_4_5:
ror 48
tree_in "Tree_union/union_4_5"
j entry_6_10
l_5:
ror 48
tree_in "Tree_union/union_5"
ror 48
tree_in "Tree_union/union_5_0"
j entry_6_10
l_5_1:
ror 48
tree_in "Tree_union/union_5_1"
j entry_6_10
l_5_2:
ror 48
tree_in "Tree_union/union_5_2"
j entry_6_10
l_5_3:
ror 48
tree_in "Tree_union/union_5_3"
j entry_6_10
l_5_4:
ror 48
tree_in "Tree_union/union_5_4"
j entry_6_10
l_5_5:
ror 48
tree_in "Tree_union/union_5_5"
j entry_6_10
entry_0_0:
COUNTER_INC(0)
COUNTER_INC(1000)
setmask (1 << 0)
j finish
entry_5_0:
COUNTER_INC(5)
COUNTER_INC(1000)
setmask (1 << 0)
j finish
entry_6_0:
COUNTER_INC(6)
COUNTER_INC(1000)
setmask (1 << 0 | 1 << CTRL_PORT)
j finish
entry_1_1:
COUNTER_INC(1)
COUNTER_INC(1001)
setmask (1 << 1)
j finish
entry_4_1:
COUNTER_INC(4)
COUNTER_INC(1001)
PUSH_SET_VLAN(3)
setmask (1 << 1)
j finish
entry_6_1:
COUNTER_INC(6)
COUNTER_INC(1001)
setmask (1 << 1 | 1 << CTRL_PORT)
j finish
entry_2_2:
COUNTER_INC(2)
COUNTER_INC(1002)
setmask (1 << 2)
j finish
entry_3_3:
COUNTER_INC(3)
COUNTER_INC(1003)
setmask (1 << 2)
j finish
entry_6_2:
COUNTER_INC(6)
COUNTER_INC(1002)
setmask (1 << 2 | 1 << CTRL_PORT)
j finish
entry_6_3:
COUNTER_INC(6)
COUNTER_INC(1003)
setmask (1 << 2 | 1 << CTRL_PORT)
j finish
entry_4_4:
COUNTER_INC(4)
COUNTER_INC(1004)
PUSH_SET_VLAN(3)
setmask (1 << 3)
j finish
entry_1_4:
COUNTER_INC(1)
COUNTER_INC(1004)
setmask (1 << 3)
j finish
entry_6_4:
COUNTER_INC(6)
COUNTER_INC(1004)
setmask (1 << 3 | 1 << CTRL_PORT)
j finish
entry_0_5:
COUNTER_INC(0)
COUNTER_INC(1005)
setmask (1 << 4)
j finish
entry_5_5:
COUNTER_INC(5)
COUNTER_INC(1005)
setmask (1 << 4)
j finish
entry_6_5:
COUNTER_INC(6)
COUNTER_INC(1005)
setmask (1 << 4 | 1 << CTRL_PORT)
j finish
entry_0_6:
COUNTER_INC(0)
COUNTER_INC(1006)
j group_0
entry_1_7:
COUNTER_INC(1)
COUNTER_INC(1007)
j group_1
entry_2_8:
COUNTER_INC(2)
COUNTER_INC(1008)
j group_2
entry_3_9:
COUNTER_INC(3)
COUNTER_INC(1009)
j group_2
entry_4_7:
COUNTER_INC(4)
COUNTER_INC(1007)
PUSH_SET_VLAN(3)
j group_1
entry_5_6:
COUNTER_INC(5)
COUNTER_INC(1006)
j group_0
entry_6_6:
COUNTER_INC(6)
COUNTER_INC(1006)
setmask (1 << CTRL_PORT)
j group_0
entry_6_7:
COUNTER_INC(6)
COUNTER_INC(1007)
setmask (1 << CTRL_PORT)
j group_1
entry_6_8:
COUNTER_INC(6)
COUNTER_INC(1008)
setmask (1 << CTRL_PORT)
j group_2
entry_6_9:
COUNTER_INC(6)
COUNTER_INC(1009)
setmask (1 << CTRL_PORT)
j group_2
entry_6_10:
COUNTER_INC(6)
COUNTER_INC(1010)
setmask (1 << CTRL_PORT)
j finish

group_0:
COUNTER_INC(10000)
load METADATA_INPORT, 8
cmpj not_0, 0, 8
setmask (1 << 0)
not_0:
load METADATA_INPORT, 8
cmpj finish, 4, 8
setmask (1 << 4)
j finish
group_1:
COUNTER_INC(10001)
load METADATA_INPORT, 8
cmpj not_1, 1, 8
setmask (1 << 1)
not_1:
load METADATA_INPORT, 8
cmpj finish, 3, 8
setmask (1 << 3)
j finish
group_2:
COUNTER_INC(10002)
load METADATA_INPORT, 8
cmpj not_2, 2, 8
setmask (1 << 2)
not_2:
load METADATA_INPORT, 8
cmpj finish, 5, 8
setmask (1 << 5)
finish: