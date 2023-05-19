// Defines for emulator.
#define MEMORY_SIZE       0x80000
#define METADATA_SIZE     0x40
#define METADATA_START    (MEMORY_SIZE - METADATA_SIZE)
#define METADATA_PORTMASK (METADATA_START + 8)
#define HEADER_SIZE       0x80
#define HEADER_START      (METADATA_START - HEADER_SIZE)

#define COUNTER_INC(id)

// Defines for header fields.
#define ETH_DST_ADDR HEADER_START
#define ETH_SRC_ADDR (HEADER_START + 6)

// Defines ports.
#define CTRL_PORT 63

// First flow table.
/* +-------------------+---------------------------+
   |      ETH_SRC      |       Instructions        |
   |                   |                           |
   +-------------------+---------------------------+
   | :1                | goto_table 1              |
   +-------------------+---------------------------+
   | :2                | goto_table 1              |
   +-------------------+---------------------------+
   | :3                | goto_table 1              |
   +-------------------+---------------------------+
   | :4                | goto_table 1              |
   +-------------------+---------------------------+
   | :5                | goto_table 1              |
   +-------------------+---------------------------+
   | *                 | output CTRL, goto_table 1 | - The lowest priority.
   +-------------------+---------------------------+
*/
loadbe ETH_SRC_ADDR, 16
rol 32
orbe (ETH_SRC_ADDR + 2), 32
tree_in "Tree/tree_1"
// Table miss.
// Add control port to port mask.
setxmask (1 << CTRL_PORT)
COUNTER_INC(1000)
j table_2
l_1_0:
COUNTER_INC(1)
j table_2
l_1_1:
COUNTER_INC(2)
j table_2
l_1_2:
COUNTER_INC(3)
j table_2
l_1_3:
COUNTER_INC(4)
j table_2
l_1_4:
COUNTER_INC(5)
// Second flow table.
/* +-------------------+---------------------------+
   |      ETH_DST      |       Instructions        |
   |                   |                           |
   +-------------------+---------------------------+
   | :1                | output 1                  |
   +-------------------+---------------------------+
   | :2                | output 2                  |
   +-------------------+---------------------------+
   | :3                | output 3                  |
   +-------------------+---------------------------+
   | :4                | output 4                  |
   +-------------------+---------------------------+
   | :5                | output 5                  |
   +-------------------+---------------------------+
   | *                 | output CTRL               |
   +-------------------+---------------------------+
*/
table_2:
loadbe ETH_DST_ADDR, 32
rol 16
orbe (ETH_DST_ADDR + 4), 16
tree_in "Tree/tree_2"
// Table miss.
// Add control port to port mask.
setxmask (1 << CTRL_PORT)
COUNTER_INC(2000)
j finish
l_2:
setmask (1 << 1)
COUNTER_INC(1001)
j finish
l_3:
setmask (1 << 2)
COUNTER_INC(1002)
j finish
l_4:
setmask (1 << 3)
COUNTER_INC(1003)
j finish
l_5:
setmask (1 << 4)
COUNTER_INC(1004)
j finish
l_6:
setmask (1 << 5)
COUNTER_INC(1005)
finish:
