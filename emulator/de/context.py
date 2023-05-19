
class DEExecutorContext:

    def __init__(self, de):
        self.de = de
        self.de_code = de.de_code
        self.app = de.app
        self.log_execution = self.de.log_execution
        self.logger = de.logger
        self.memory = de.memory
        self.register_size = self.de.register_size
        self.offset_reg_size = self.de.offset_reg_size
        self.register_width = (self.register_size  * 8) # in bits
        self.register_value_max = self.de.register_value_max
        self.accumulator = 0
        self.offset_reg = 0
        self.position = self.de.instructions_address
        self.position_stop = self.position + len(de.instructions) * self.register_size
        self.buffer_to_instruction = self.de.de_instructions.buffer_to_instruction
        self.ticks = 0
        self.dynamic_power = 0  # in nJ

    def tick(self): 								
        if self.position >= self.position_stop:
            return False
        buffer = self.memory.get_buffer(self.position)
        instruction, arguments = self.buffer_to_instruction(buffer)
        if self.log_execution:
            line_index = self.de_code.address_to_line[self.position]
            self.logger.debug("  {address}: {value}: {line}".format(
                address=self.de_code.format_address(self.position),
                value=self.de_code.format_buffer(buffer),
                line=self.de_code.lines[line_index]
                # line_index=self.de_code.line_index_format % line_index,
            ))
            for arg_index, arg in enumerate(arguments):
                arg_info = instruction.arguments[arg_index]
                self.logger.debug("    {name}: {value}".format(
                    name=arg_info.name,
                    value=self.de_code.format_argument(self.position)
                ))
        instruction.func(self, *arguments)
        
        # increase counters
        # self.dynamic_power += self.de.alu_dynamic_power + self.de.mem_port_dynamic_power
        self.spend_ticks()
        self.inc_power_memory()
        self.inc_power_alu()
        
        return True
        
    def spend_ticks(self, ticks=1):
        self.ticks += ticks
        # !!dirty hack!!
        if (ticks != 1):
            self.de.pipeline.run_ticks += ticks
        
    def inc_power_memory(self):
        self.dynamic_power += self.de.mem_port_dynamic_power
        
    def inc_power_alu(self, times=1):
       self.dynamic_power += self.de.alu_dynamic_power * times
    
    def next_position(self):
        self.set_position(self.get_position() + self.register_size)

    def get_position(self):
        if self.de.log_execution:
            self.logger.debug("    get pos: {value}".format(
                value=self.de_code.format_address(self.position)
            ))
        return self.position

    def set_position(self, address):
        self.de_code.validate_address(address)
        if self.de.log_execution:
            self.logger.debug("    set pos: {value}".format(
                value=self.de_code.format_address(address)
            ))
            self.logger.debug("        was: {value}".format(
                value=self.de_code.format_address(self.position)
            ))
        if address > self.position_stop:
            raise RuntimeError("position overflow")
        self.position = address

    def get_accumulator(self):
        if self.de.log_execution:
            self.logger.debug("    get acc: {value}".format(
                value=self.de_code.format_value(self.accumulator)
            ))
        return self.accumulator

    def set_accumulator(self, value):
        self.de_code.validate_value(value)
        if self.de.log_execution:
            self.logger.debug("    set acc: {value}".format(
                value=self.de_code.format_value(value)
            ))
            self.logger.debug("        was: {value}".format(
                value=self.de_code.format_value(self.accumulator)
            ))
        self.accumulator = value

    def get_offset_reg(self):
        if self.de.log_execution:
            self.logger.debug("    get off: {value}".format(
                value=self.de_code.format_value(self.offset_reg)
            ))
        return self.offset_reg

    def set_offset_reg(self, value):
        self.de_code.validate_value(value)
        if self.de.log_execution:
            self.logger.debug("    set off: {value}".format(
                value=self.de_code.format_value(value)
            ))
            self.logger.debug("        was: {value}".format(
                value=self.de_code.format_value(self.offset_reg)
            ))
        self.offset_reg = value

    def __format_address_and_offset(self, address, offset):
        s = self.de_code.format_address(address)
        return s

    def get_memory(self, address, offset=None, size=4):
        if (size > 0) and (address & (1 << (size))-1 != 0):
            self.fatal_error("Unaligned memory access! Address {addr:08X} with access size of {size} bytes.".format(addr=address, size=1<<size))
        value = self.memory.get_value(address, offset)
        if self.de.log_execution:
            address_str = self.__format_address_and_offset(address, offset)
            self.logger.debug("    get mem: {value} at {address_and_offset}".format(
                address_and_offset=address_str,
                value=self.de_code.format_value(value)
            ))
        return value

    def set_memory(self, address, value, size=4):
        if (size > 0) and (address & (1 << (size-1))-1 != 0):
            self.fatal_error("Unaligned memory access! Address {addr:08X} with access size of {size}.".format(addr=address, size=size))
        self.memory.set_value(address, value, None)
        if self.de.log_execution:
            address_str = self.__format_address_and_offset(address, None)
            self.logger.debug("    set mem: {value} at {address_and_offset}".format(
                address_and_offset=address_str,
                value=self.de_code.format_value(value)
            ))
        return value

    def set_value(self, value, address, offset=None):
        if self.de.log_execution:
            address_str = self.__format_address_and_offset(address, offset)
            self.logger.debug("    set mem: {value} at {address_and_offset}".format(
                address_and_offset=address_str,
                value=self.de_code.format_value(value)
            ))
            old_value = self.memory.get_value(address)
            self.logger.debug("        was: {value}".format(
                address_and_offset=" " * len(address_str),
                value=self.de_code.format_value(
                    self.memory.get_value(address, offset))
            ))
        self.memory.set_value(value, address, offset)

    def fatal_error(self, message):
        self.logger.fatal(message)
        self.app.sys.exit(-1)
