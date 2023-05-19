from emulator.app.component import Component
from .instruction import DEInstructionInfo


class DEInstructions(Component):

    INSTRUCTION_PREFIX = "instruction_"

    def handle_config(self):
        self.opcode_size = self.config.get_bits("opcode_size")

        self.instruction_infos_by_name = {}
        self.instruction_infos_by_opcode = {}

        types_config = self.config["types"]

        import emulator.de.instructions.types as de_instruction_types
        for k, attr in de_instruction_types.__dict__.items():
            if not k.startswith(self.INSTRUCTION_PREFIX):
                continue
            name = k[len(self.INSTRUCTION_PREFIX):]
            if name in self.instruction_infos_by_name:
                raise RuntimeError("instruction name duplication: {name}".format(
                    name=name
                ))
            instruction = DEInstructionInfo(
                self, name, attr, types_config[name]
            )
            if instruction.opcode in self.instruction_infos_by_opcode:
                raise RuntimeError("instruction opcode duplication: {name}".format(
                    name=name
                ))
            self.instruction_infos_by_name[name] = instruction
            self.instruction_infos_by_opcode[instruction.opcode] = instruction

    def value_to_instruction(self, *args, **kw):
        return DEInstructionInfo.from_value(self, *args, **kw)

    def buffer_to_instruction(self, *args, **kw):
        return DEInstructionInfo.from_buffer(self, *args, **kw)
