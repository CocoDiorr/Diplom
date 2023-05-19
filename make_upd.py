import json
from random import randint, choice
import argparse

parser = argparse.ArgumentParser()

parser.add_argument(
    '--type', '-t',
    type=str
)
parser.add_argument(
    '--dir_name', '-d'
)
parser.add_argument(
    '--wildcard', '-w',
    action='store_true',
    default=False
)

args = parser.parse_args()


data = dict()
_type = args.type
data['type'] = _type
dir_name = args.dir_name

with open('diplom/' + dir_name + '/data.json') as f:
    content = json.load(f)

if _type == 'add':
    value = "%02x:%02x:%02x:%02x:%02x:%02x" % (
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255)
                )
    while value in content:
        value = "%02x:%02x:%02x:%02x:%02x:%02x" % (
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255),
                    randint(0, 255)
                )
    data['value'] = value
    data['action'] = 'outport:' + str(randint(0, 24))
else:
    # wildcard = input('Use for all or use for one: ')
    wildcard = args.wildcard
    if wildcard:
        data['value'] = '***'
    else:
        data['value'] = choice(tuple(content.keys()))
    if _type == 'mod':
        data['action'] = 'outport:' + str(randint(0, 24))

with open('diplom/' + dir_name + '/upd.json', 'w') as output:
    json.dump(data, output, indent=4)
