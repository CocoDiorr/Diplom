import os

classic_data = dict()
incr_data = dict()

for dir_name in os.listdir('./diplom'):
    if dir_name != 'pics':
        if os.path.isdir('diplom/' + dir_name):
            classic_data[dir_name] = []
            incr_data[dir_name] = []

            with open('diplom/' + dir_name + '/classic.txt', 'r') as classic:
                for line in classic:
                    classic_data[dir_name].append(eval(line)[0])
            
            with open('diplom/' + dir_name + '/incr.txt', 'r') as incr:
                for line in incr:
                    incr_data[dir_name].append(eval(line)[0])

for k, v in classic_data.items():
    tmp = 0
    for pair in v:
        tmp += pair[1]
    
    classic_data[k] = (v[0][0], tmp // len(v))

for k, v in incr_data.items():
    tmp = 0
    for pair in v:
        tmp += pair[1]
    
    incr_data[k] = (v[0][0], tmp // len(v))

for dir_name, result in classic_data.items():
    with open('diplom/' + dir_name + '/classic_result.txt', 'w') as classic:
        classic.write(str(result))

for dir_name, result in incr_data.items():
    with open('diplom/' + dir_name + '/incr_result.txt', 'w') as incr:
        incr.write(str(result))

