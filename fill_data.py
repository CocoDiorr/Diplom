import json
import os
from random import randint
import argparse

parser = argparse.ArgumentParser()

parser.add_argument(
    '--number', '-n',
    type=int
)
parser.add_argument(
    '--dir_name', '-d'
)

# n = int(input('number of rules: '))
args = parser.parse_args()
n = args.number
dir_to_write = args.dir_name

table = dict()

for _ in range(n):
    mac_addr = "%02x:%02x:%02x:%02x:%02x:%02x" % (
                randint(0, 255),
                randint(0, 255),
                randint(0, 255),
                randint(0, 255),
                randint(0, 255),
                randint(0, 255)
            )

    table[mac_addr] = 'outport:' + str(randint(0, 24))

# dir_to_write = input('dir for ex: ')

if not os.path.exists('diplom/' + dir_to_write + '_' + str(n)):
    os.mkdir('diplom/' + dir_to_write + '_' + str(n))

with open('diplom/' + dir_to_write + '_' + str(n) + '/data.json', 'w') as output:
    json.dump(table, output, indent=4)
