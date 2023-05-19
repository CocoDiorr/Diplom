// Defines for emulator.
#define MEMORY_SIZE       0x80000
#define METADATA_SIZE     0x40
#define METADATA_START    (MEMORY_SIZE - METADATA_SIZE)
#define METADATA_INPORT   (METADATA_START + 16)
#define METADATA_PORTMASK (METADATA_START + 8)
#define HEADER_SIZE       0x80
#define HEADER_START      (METADATA_START - HEADER_SIZE)
#define ACC_SIZE 128

#define COUNTER_INC(id)

// Defines for header fields.
#define ETH_DST_ADDR HEADER_START
#define ETH_SRC_ADDR (HEADER_START + 6)
#define ETHERTYPE_ADDR (HEADER_START + 12)
#define ETH_DST_ADDR_TAGGED (HEADER_START - 4)
#define ETHERTYPE_ADDR_TAGGED ((HEADER_START + 12) - 4)

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

//First flow table.
/* +-------------------+----------+----------+------------------------------------+
   |      ETH_SRC      | VLAN_VID | Priority |            Instructions            |
   |                   |          |          |                                    |
   +-------------------+----------+----------+------------------------------------+
   | :1                | 2        | 1        | goto_table 1                       |
   +-------------------+----------+----------+------------------------------------+
   | :2                | 3        | 1        | goto_table 1                       |
   +-------------------+----------+----------+------------------------------------+
   | :3                | 10       | 1        | goto_table 1                       |
   +-------------------+----------+----------+------------------------------------+
   | :3                | 20       | 1        | goto_table 1                       |
   +-------------------+----------+----------+------------------------------------+
   | :4                | NONE     | 1        | Push-Tag 0x8100,                   |
   |                   |          |          | Set-Field VLAN_VID 3, goto_table 1 |
   +-------------------+----------+----------+------------------------------------+
   | :5                | 2        | 1        | goto_table 1                       |
   +-------------------+----------+----------+------------------------------------+
   | *                 | *        | 0        | output CTRL, goto_table 1          |
   +-------------------+----------+----------+------------------------------------+
*/
loadi 0
storemeta 8, 32
// Load ETH_SRC and VLAN_VID fields.
loadbe ETH_SRC_ADDR, 16
rol 32
orbe (ETH_SRC_ADDR + 2), 32
rcr 48
orbe ETHERTYPE_ADDR, 16
cmpj untagged, 0x0800, 16
xorbe ETHERTYPE_ADDR, 16
orbe (ETHERTYPE_ADDR + 2), 16
ori (1 << 12)
rcl 48
j tree_1_1
untagged:
ror (ACC_SIZE - 48)

//tree_1 consists of 2 tables:
/*      tree_meta_1_1                   tree_meta_1_2
   +---------+------------+        +----------+------------+
   | ETH_SRC |    lab     |        |   lab +  |    lab     |
   |         |            |        | VLAN_VID |            |
   +---------+------------+        +----------+------------+
   |:1       | l_1_0      |        | 0 2      | l_1_0_0    |
   +---------+------------+        +----------+------------+
   |:2       | l_1_1      |        | 1 3      | l_1_1_0    |
   +---------+------------+        +----------+------------+
   |:3       | l_1_2      |        | 2 10     | l_1_2_0    |
   +---------+------------+        +----------+------------+
   |:4       | l_1_3      |        | 2 20     | l_1_2_1    |
   +---------+------------+        +----------+------------+
   |:5       | l_1_4      |        | 3 NONE   | l_1_3_0    |
   +---------+------------+        +----------+------------+
                                   | 4 2      | l_1_4_0    |
                                   +----------+------------+
*/

tree_1_1:
tree_in "Tree/tree_lab_1_1"
j table_0_miss
l_1_0:                      // lab l_1_0
rcr 48
ori (0 << 16)
j tree_1_2
l_1_1:                       //lab l_1_1
rcr 48
ori (1 << 16)
j tree_1_2
l_1_2:                       //lab l_1_2
rcr 48
ori (2 << 16)
j tree_1_2
l_1_3:                       //lab l_1_3
rcr 48
ori (3 << 16)
j tree_1_2
l_1_4:                       //lab l_1_4
rcr 48
ori (4 << 16)

tree_1_2:
tree_in "Tree/tree_lab_1_2"
j table_0_miss
l_1_0_0:
COUNTER_INC(1)
j table_2
l_1_1_0:
COUNTER_INC(2)
j table_2
l_1_2_0:
COUNTER_INC(3)
j table_2
l_1_2_1:
COUNTER_INC(4)
j table_2
l_1_3_0:
COUNTER_INC(5)
PUSH_SET_VLAN(3)
loadi 1
storemeta 8, 32 // Set tagged bit.
j table_2
l_1_4_0:
COUNTER_INC(6)
j table_2
table_0_miss:
// Add control port to port mask
setxmask (1 << CTRL_PORT)
COUNTER_INC(1000)

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

table_2:
// Load ETH_DST and VLAN_VID fields.
loadmeta 8, 32
cmpj was_tagged, 1, 32 // HEADER_START was moved.
loadoffi 4
was_tagged:
loadbe ETH_DST_ADDR_TAGGED, 32
rol 16
orbe (ETH_DST_ADDR_TAGGED + 4), 16
rcr 48
orbe ETHERTYPE_ADDR_TAGGED, 16
cmpj untagged_, 0x0800, 16
xorbe ETHERTYPE_ADDR_TAGGED, 16
orbe (ETHERTYPE_ADDR_TAGGED + 2), 16
ori (1 << 12)
rcl 48
j tree_2_1
untagged_:
ror (ACC_SIZE - 48)

//tree_2 consists of 2 tables:
/*      tree_meta_1_1                   tree_meta_1_2
   +---------+------------+        +----------+------------+
   | ETH_DST |    lab     |        |   lab +  |    lab     |
   |         |            |        | VLAN_VID |            |
   +---------+------------+        +----------+------------+
   |:1       | l_2_0      |        | 0 2      | l_2_0_0    |
   +---------+------------+        +----------+------------+
   |:2       | l_2_1      |        | 1 3      | l_2_1_0    |
   +---------+------------+        +----------+------------+
   |:3       | l_2_2      |        | 2 10     | l_2_2_0    |
   +---------+------------+        +----------+------------+
   |:4       | l_2_3      |        | 2 20     | l_2_2_1    |
   +---------+------------+        +----------+------------+
   |:5       | l_2_4      |        | 3 3      | l_2_3_0    |
   +---------+------------+        +----------+------------+
   |* (6)    | l_2_5      |        | 4 2      | l_2_4_0    |
   +---------+------------+        +----------+------------+
                                   | 5 2      | l_2_5_0    |
                                   +----------+------------+
                                   | 1 2      | l_2_5_0    |
                                   +----------+------------+
                                   | 2 2      | l_2_5_0    |
                                   +----------+------------+
                                   | 3 2      | l_2_5_0    |
                                   +----------+------------+
                                   | 5 3      | l_2_5_1    |
                                   +----------+------------+
                                   | 0 3      | l_2_5_1    |
                                   +----------+------------+
                                   | 2 3      | l_2_5_1    |
                                   +----------+------------+
                                   | 4 3      | l_2_5_1    |
                                   +----------+------------+
                                   | 5 10     | l_2_5_2    |
                                   +----------+------------+
                                   | 0 10     | l_2_5_2    |
                                   +----------+------------+
                                   | 1 10     | l_2_5_2    |
                                   +----------+------------+
                                   | 3 10     | l_2_5_2    |
                                   +----------+------------+
                                   | 4 10     | l_2_5_2    |
                                   +----------+------------+
                                   | 5 20     | l_2_5_3    |
                                   +----------+------------+
                                   | 0 20     | l_2_5_3    |
                                   +----------+------------+
                                   | 1 20     | l_2_5_3    |
                                   +----------+------------+
                                   | 3 20     | l_2_5_3    |
                                   +----------+------------+
                                   | 4 20     | l_2_5_3    |
                                   +----------+------------+
*/

tree_2_1:
loadoffi 0
tree_in "Tree/tree_lab_2_1"
j l_2_5
l_2_0:                      // lab l_2_0
rcr 48
ori (0 << 16)
j tree_2_2
l_2_1:                      // lab l_2_1
rcr 48
ori (1 << 16)
j tree_2_2
l_2_2:                      // lab l_2_2
rcr 48
ori (2 << 16)
j tree_2_2
l_2_3:                      // lab l_2_3
rcr 48
ori (3 << 16)
j tree_2_2
l_2_4:                      // lab l_2_4
rcr 48
ori (4 << 16)
j tree_2_2
l_2_5:                      // lab l_2_5
rcr 48
ori (5 << 16)

tree_2_2:
tree_in "Tree/tree_lab_2_2"
j table_1_miss
table_1_miss:
COUNTER_INC(2000)
// Add control port to port mask.
setxmask (1 << CTRL_PORT)
j finish
act_0:
COUNTER_INC(2001)
setmask (1 << 0)
j finish
act_1:
COUNTER_INC(2002)
setmask (1 << 1)
j finish
act_2:
COUNTER_INC(2003)
setmask (1 << 2)
j finish
act_3:
COUNTER_INC(2004)
setmask (1 << 2)
j finish
act_4:
COUNTER_INC(2005)
setmask (1 << 3)
j finish
act_5:
COUNTER_INC(2006)
setmask (1 << 4)
j finish
act_6:
COUNTER_INC(2007)
// Group 0.
COUNTER_INC(10000)
load METADATA_INPORT, 8
cmpj not_0, 0, 8
setmask (1 << 0)
not_0:
load METADATA_INPORT, 8
cmpj finish, 4, 8
setmask (1 << 4)
j finish
act_7:
COUNTER_INC(2008)
// Group 1.
COUNTER_INC(10001)
load METADATA_INPORT, 8
cmpj not_1, 1, 8
setmask (1 << 1)
not_1:
load METADATA_INPORT, 8
cmpj finish, 3, 8
setmask (1 << 3)
j finish
act_8:
COUNTER_INC(2009)
// Group 2.
j group_2
act_9:
COUNTER_INC(2010)
// Group 2.
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
