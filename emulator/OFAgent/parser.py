import sys

from emulator.util.parsing import parse_int, parse_items
import os
from emulator.de.code.tree import Tree


class DECodeParser:

    def __init__(self, de_code, path, lines, instr_size):
        self.de_code = de_code
        self.app = de_code.app
        self.path = path
        self.instr_size = instr_size
        self.logger = de_code.logger

        self.de_instructions = self.app.de_instructions
        self.instruction_infos_by_name = self.de_instructions.instruction_infos_by_name
        self.address_to_line = {}
        self.line_to_address = {}
        self.label_to_address = {}
        self.instructions = []
        self.instr_mem_counter = 0
        self.next_address = 0
        self.__disable_line_address = True
        self.__main_found = False
        self.__commands = []
        self.__line_index = None
        self.lines = []
        for line_index, line in enumerate(list(lines)):
            self.__line_index = line_index
            if self.__parse_line(line):
                self.instr_mem_counter += self.instr_size
        self.__print_info()
        self.__make_microcode()
        self.__print_asm_file()

    def __parse_line(self, line):

        values = self.__get_line_values(line)
        if not values:
            return False

        if self.__parse_label(values):
            self.lines.append(line)
            return False

        if self.__parse_tree(values):
            return False

        line_address = self.__get_line_address(values)
        if len(values) == 0:
            command = 0
            self.logger.warning("address {line_address} skipped (line {line_index]), it will be noop".format(
                line_address=self.de_code.format_address(line_address),
                line_index=self.__format_line_index()
            ))
        else:
            instruction_name = values.pop(0)

            if isinstance(instruction_name, int):
                if len(values) > 1:
                    self.__error("data must not have more words after it")
                command = instruction_name
            else:
                try:
                    instruction = self.instruction_infos_by_name[instruction_name]
                except KeyError:
                    self.__error("unknown instruction \""+instruction_name+"\"")
                if len(values) != len(instruction.arguments):
                    self.__error("bad instruction argument count")
                command = (instruction, values)

        self.__commands.append((self.__line_index, line_address, command))
        self.lines.append(line)
        return True

    def __get_line_values(self, line):
        part = line.partition(" ") # get instruction name
        words = []
        if part[0]:
            words = [part[0]]
            if part[2]:
                words += part[2].replace(" ", "").split("//")[0].split(",")

        if self.de_code.log_lines and words:
            self.logger.debug("  line {line_index}: {words}".format(
                line_index=self.__format_line_index(),
                words=" ".join(words)
            ))
        return parse_items(words, parser=parse_int, allow_not_parsed=True)

    def __format_line_index(self, v=None):
        if v is None:
            v = self.__line_index
        return self.de_code.line_index_format % (v + 1)

    def __parse_label(self, values):
        if len(values) != 1:
            return False
        item = values[0]
        if not isinstance(item, str):
            return False
        if not item.endswith(":"):
            return False
        if item.startswith("0x"):
            return False
        if item in self.label_to_address:
            self.__error("label name duplication")
        self.label_to_address[item[:-1]] = self.next_address
        return True

    def __parse_tree(self, values):
        directive_name = values[0]
        if directive_name == 'tree_in':
            tree_type = 'in'
        elif directive_name == 'tree_lpm':
            tree_type = 'lpm'
        else:
            return False

        if len(values) != 2:
            self.__error("bad directive argument count")
        file_name = values[1]
        if not isinstance(file_name, str):
            self.__error("bad directive argument")
        if not file_name.endswith('"'):
            self.__error("bad directive argument")
        if not file_name.startswith('"'):
            self.__error("bad directive argument")
        file_name = file_name[1:-1]
        if not file_name:
            self.__error("bad directive argument")

        file_path = os.path.split(self.path)[0] + '/' + file_name
        with open(file_path, "r") as f:
            lines = tuple(f.read().splitlines())

        tree_elements = list()
        for i, line in enumerate(lines):
            line = line.split()
            if tree_type == 'in' and len(line) != 2 or tree_type == 'lpm' and len(line) != 3:
                self.__error("bad tree file in line #" + str(i + 1))
            line[0] = int(line[0], 16)
            if tree_type == 'lpm':
                line[1] = int(line[1])
            tree_elements.append(tuple(line))

        values_num = len(tree_elements)
        if tree_type == 'in':
            tree = Tree(sorted(tree_elements, key=lambda x: x[0]), True)
            size = 48
        else:
            trees = []
            tree_elements = sorted(tree_elements, key=lambda x: (x[1], x[0]))
            while tree_elements:
                key = tree_elements[-1][1]
                matches = [x for x in tree_elements if (lambda x: x[1] == key)(x)]
                tree = Tree(matches, True)
                trees.append(tree)
                tree_elements = tree_elements[:-len(matches)]
            size = 64

        tree_lines = []
        shift = 0
        if tree_type == 'in':
            for node in tree:
                if node.label:
                    tree_lines.append(node.label + ':')
                if not node.left or not node.right:
                    tree_lines.append('cmpj ' + node.value[1] + ', ' + hex(node.value[0])
                                      + ', ' + str(size))
                    tree_lines.append('j ' + tree.label + '_miss')
                else:
                    tree_lines.append('cmpjl ' + node.left.label + ', '
                                      + hex(node.value[0]) + ', ' + str(size))
            tree_lines.append(tree.label + '_miss:')
        else:
            for tree in trees:
                count_zeros = size - tree.value[1]
                if (shift < count_zeros):
                    tree_lines.append('ror ' + str(count_zeros - shift))
                    shift = count_zeros
                for node in tree:
                    if node.label:
                        tree_lines.append(node.label + ':')
                    if not node.left or not node.right:
                        tree_lines.append('cmpj ' + node.value[2] + ', '
                                          + hex(node.value[0] >> count_zeros) + ', '
                                          + str(tree.value[1]))
                        tree_lines.append('j ' + tree.label + '_miss')
                    else:
                        tree_lines.append('cmpjl ' + node.left.label + ', '
                                          + hex(node.value[0] >> count_zeros) + ', '
                                          + str(tree.value[1]))
                tree_lines.append(tree.label + '_miss:')

        for line in tree_lines:
            self.__parse_line(line)
        self.instr_mem_counter += int(2.5 * self.instr_size) * values_num
        return True

    def __get_line_address(self, values):
        if self.__disable_line_address:
            line_address = self.next_address
        else:
            line_address_str = values.pop(0)
            if not line_address_str.startswith("0x"):
                self.__error("line address must start with '0x'")
            if not line_address_str.endswith(":"):
                self.__error("line address must end with ':'")

            try:
                line_address = int(line_address_str[:-1], 0)
            except ValueError:
                self.__error("line address parsing failed")
            if line_address % self.register_size:
                self.__error("line address not multiple of register size")
        self.next_address += self.de_code.register_size
        self.line_to_address[self.__line_index] = line_address
        self.address_to_line[line_address] = self.__line_index
        return line_address

    def __error(self, message, with_line=True):
        text = "{path}{line_info}: {message}".format(
            path=self.de_code.os_path.abspath(self.path),
            line_info=(
                ", line {line_index}".format(
                    line_index=self.__format_line_index()
                ) if with_line else ""
            ),
            message=message
        )
        self.de_code.logger.error(text)
        self.de_code.sys.exit(-1)

    def __print_info(self):
        if self.de_code.log_labels and self.label_to_address:
            self.logger.debug("Labels:")
            for label, address in self.label_to_address.items():
                self.logger.debug("  {address}: {label}".format(
                    address=self.de_code.format_address(address),
                    label=label
                ))

    def __make_microcode(self):
        self.logger.debug("Microcode:")

        for line_index, line_address, command in self.__commands:
            if isinstance(command, int):
                value = command
            else:
                instruction, arguments = command
                for i in range(len(arguments)):
                    argument = arguments[i]
                    try:
                        arg_value = self.label_to_address[argument]
                    except KeyError:
                        try:
                            arg_value = parse_int(eval(str(argument)))
                        except NameError:
                            self.__error("Undefined label \"{label}\"".format(label=str(argument)))
                        except ValueError:
                            self.__error("failed to parse argument #{i} '{argument}'".format(
                                i=i,
                                argument=argument
                            ))
                    arguments[i] = arg_value
                value = instruction.to_value(arguments)
            if self.de_code.log_instructions:
               self.logger.debug("  {address}: {value}: {line}".format(
                   address=self.de_code.format_address(line_address),
                   value=self.de_code.format_value(value),
                   line=self.lines[line_index]
               ))
            buffer = self.de_code.value_to_buffer(value)
            self.instructions.append(buffer)

    def __print_asm_file(self):
        print(f"self.path = {self.path}")
        with open(self.path, "w") as f:
            for line in self.lines:
                f.write(line + "\n")
