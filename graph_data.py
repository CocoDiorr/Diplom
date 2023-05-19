import os


def write_data(data, fpath):
    with open(fpath, 'w') as f:
        f.write('[\n')
        for d in data:
            f.write(str(d) + ',\n')
        f.write(']')

incr_add_data = []
classic_add_data = []

incr_mod_data = []
incr_mod_w_data = []
classic_mod_data = []
classic_mod_w_data = []

incr_del_data = []
incr_del_w_data = []
classic_del_data = []
classic_del_w_data = []

for dir_name in os.listdir('./diplom'):
    if dir_name != 'pics':
        if os.path.isdir('diplom/' + dir_name):
            with open('diplom/' + dir_name + '/incr_result.txt', 'r') as incr:
                if 'add' in dir_name:
                    incr_add_data.append(eval(incr.read()))
                elif 'mod_w' in dir_name:
                    incr_mod_w_data.append(eval(incr.read()))
                elif 'mod' in dir_name:
                    incr_mod_data.append(eval(incr.read()))
                elif 'del_w' in dir_name:
                    incr_del_w_data.append(eval(incr.read()))
                elif 'del' in dir_name:
                    incr_del_data.append(eval(incr.read()))
            
            with open('diplom/' + dir_name + '/classic_result.txt', 'r') as classic:
                if 'add' in dir_name:
                    classic_add_data.append(eval(classic.read()))
                elif 'mod_w' in dir_name:
                    classic_mod_w_data.append(eval(classic.read()))
                elif 'mod' in dir_name:
                    classic_mod_data.append(eval(classic.read()))
                elif 'del_w' in dir_name:
                    classic_del_w_data.append(eval(classic.read()))
                elif 'del' in dir_name:
                    classic_del_data.append(eval(classic.read()))
    

write_data(incr_add_data, 'diplom/incr_add_res.txt')
write_data(incr_mod_data, 'diplom/incr_mod_res.txt')
write_data(incr_mod_w_data, 'diplom/incr_mod_w_res.txt')
write_data(incr_del_data, 'diplom/incr_del_res.txt')
write_data(incr_del_w_data, 'diplom/incr_del_w_res.txt')
write_data(classic_add_data, 'diplom/classic_add_res.txt')
write_data(classic_mod_data, 'diplom/classic_mod_res.txt')
write_data(classic_mod_w_data, 'diplom/classic_mod_w_res.txt')
write_data(classic_del_data, 'diplom/classic_del_res.txt')
write_data(classic_del_w_data, 'diplom/classic_del_w_res.txt')

