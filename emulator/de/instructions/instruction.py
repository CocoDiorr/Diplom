import inspect
from .argument import DEInstructionArgumentInfo
import emulator.util.parsing

# Debug testing of every int -> buffer operation (and vice versa)
TEST_INSTRUCTION_SERIALIZATION = False


class DEInstructionInfo:

    def __init__(self, de_instructions, name, func, config):
        self.de_instructions = de_instructions
        self.de_code = de_instructions.app.de_code
        self.register_size_bits = int(self.de_code.app.config["de"]["register_size"]) * 8 # ugly
        self.name = name
        self.func = func
        self.opcode = config.get_int("opcode")
        args = list(inspect.signature(func).parameters.items())
        if not len(args) or args[0][0] != "context":
            raise RuntimeError("instruction '{name}' bad first argument:".format(
                name=name
            ))
        offset = de_instructions.opcode_size
        self.arguments = []
        config_arguments = config["arguments"]
        for arg_name, arg_info in args[1:]:
            if arg_info.kind != arg_info.POSITIONAL_OR_KEYWORD:
                raise RuntimeError("instruction '{name}' argument '{arg}' bad kind".format(
                    name=name,
                    arg=arg_name
                ))
            argument = DEInstructionArgumentInfo(
                self, arg_name, offset, config_arguments.get_bits(arg_name))
            offset += argument.size
            if offset > self.register_size_bits:
                raise RuntimeError("instruction '{name}' register size overflow".format(
                    name=name
                ))
            self.arguments.append(argument)
        self.argument_count = len(self.arguments)

    def validate_argument(self, index, value):
        info = self.arguments[index]
        if not isinstance(value, int):
            raise ValueError("argument must be int")
        if value < 0:
            raise ValueError("argument must not be negative")
        if value > info.value_max:
            raise ValueError("argument overflow")

    def to_value(self, arguments, debug_test=TEST_INSTRUCTION_SERIALIZATION):
        if len(arguments) != self.argument_count:
            raise ValueError("argument count mismatch")
        offset = self.register_size_bits - self.de_instructions.opcode_size
        value = self.opcode << offset
        for i in range(len(self.arguments)):
            arg_info = self.arguments[i]
            arg_value = arguments[i]
            offset -= arg_info.size
            # print(format(value, "016x"), offset)
            assert offset >= 0
            arg_info.validate_value(arg_value)
            value |= (arg_value << offset)
        if debug_test:
            instruction_, arguments_ = self.de_instructions.value_to_instruction(value, debug_test=False)
            if self is not instruction_ or arguments != arguments_:
                raise RuntimeError("instruction serialization debug_test failed")
            value_ = instruction_.to_value(arguments_, debug_test=False)
            if value != value_:
                raise RuntimeError("instruction serialization debug_test failed")
        return value

    @classmethod
    def from_value(cls, de_instructions, value, debug_test=TEST_INSTRUCTION_SERIALIZATION):
        full_config = de_instructions.app.config
        register_size_bits = int(full_config["de"]["register_size"]) * 8
        offset = register_size_bits - de_instructions.opcode_size
        opcode = value >> offset
        try:
            instruction = de_instructions.instruction_infos_by_opcode[opcode]
        except KeyError:
            raise ValueError("bad instruction opcode: {opcode}".format(
                opcode=opcode
            ))
        arguments = []
        for arg_info in instruction.arguments:
            offset -= arg_info.size
            assert offset >= 0
            arg_value = (value >> offset) & arg_info.value_max
            arguments.append(arg_value)
        if debug_test:
            value_ = instruction.to_value(arguments, debug_test=False)
            if value != value_:
                raise RuntimeError("instruction serialization debug_test failed")
            instruction_, arguments_ = de_instructions.value_to_instruction(value_, debug_test=False)
            if instruction is not instruction_ or arguments != arguments_:
                raise RuntimeError("instruction serialization debug_test failed")
        return instruction, arguments

    def to_buffer(self, *args, **kw):
        value = self.to_value(*args, **kw)
        return emulator.util.parsing.value_to_buffer(value)

    @classmethod
    def from_buffer(cls, de_instructions, buffer, *args, **kw):
        value = de_instructions.app.de_code.buffer_to_value(buffer)
        return cls.from_value(de_instructions, value, *args, **kw)
