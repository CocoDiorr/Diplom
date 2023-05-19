

class DEInstructionArgumentInfo:

    def __init__(self, instruction, name, offset, size):
        self.instruction = instruction
        self.name = name
        # self.offset = offset
        self.size = size
        self.value_max = (1 << size) - 1

    def validate_value(self, value):
        if not isinstance(value, int):
            raise ValueError("argument must be int")
        if value < 0:
            raise ValueError("argument must not be negative")
        if value > self.value_max:
            raise ValueError("argument overflow", value, "of", self.value_max)
