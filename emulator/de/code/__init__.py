import json
from emulator.app.component import Component
from emulator.util.parsing import make_int_numbering_format
from .parser import DECodeParser
from subprocess import call


class DECode(Component):

    @classmethod
    def handle_args_register(cls, parser):
        parser.add_argument(
            "--de-code", "-p", dest="de_code", type=str,
            help="DE code input file", required=True
        )


    def handle_args(self, args):
        self.log_lines = self.config["log_lines"]
        self.log_labels = self.config["log_labels"]
        self.log_instructions = self.config["log_instructions"]
        self.value_format = self.config["data_format"]
        self.address_format = self.config["address_format"]
        self.argument_format = self.config["argument_format"]
        
        self.register_size = int(self.app.config["de"]["register_size"])
        self.register_size_bits = self.register_size * 8
        self.memory_size = int(self.app.config["de"]["memory_size"])
        self.shadow_memory_size = int(self.app.config["de"]["memory_size"])
        self.register_value_max = (1 << (self.register_size*8))-1
        self.instruction_size = int(self.app.config["de"]["instruction_size"])

        self.path_cpp = args.de_code
        self.path = self.path_cpp + ".pp"
        # Call CPP (for ex. GCC) for preprocessing
        rc = call(["cpp", "-x", "assembler-with-cpp", "-P", "-nostdinc", self.path_cpp, "-o",  self.path])
        if (rc != 0):
            raise RuntimeError("Source preprocessing by CPP failed!")
        
        if self.app.out:
            self.logger.info("Parsing code file: {path}".format(
                path=self.os_path.abspath(self.path)
            ))
        with open(self.path, "r") as f:
            self.lines = tuple(f.read().replace('\n', ';').replace('; ', ';').replace(' ;', ';').split(';'))
        self.line_index_format = make_int_numbering_format(len(self.lines) + 1)

        parser = DECodeParser(self, self.path, self.lines, self.instruction_size)
        self.lines = tuple(parser.lines)
        self.instructions = parser.instructions
        self.address_to_line = parser.address_to_line
        self.line_to_address = parser.line_to_address
        self.instr_mem_counter = parser.instr_mem_counter

        
    def print_code(self):
        if self.app.out:
            self.logger.debug("\nShadow Memory Microcode:")
            print("*********")
            for line in self.lines:
                print(line)
            print("*********")
 #   	for line_index, line_address, command in self.__commands:
#		if self.de_code.log_instructions:
#		        self.logger.debug("  {address}: {value}: {line}".format(
#		            address=self.de_code.format_address(line_address),
#		            value=self.de_code.format_value(value),
#		            line=self.lines[line_index]
 #		        ))
        
    def validate_value(self, value):
        if not isinstance(value, int):
            raise RuntimeError("value must be int")
        if value < 0:
            raise RuntimeError("value must not be negative")
        if value >= self.register_value_max: 
            raise RuntimeError("value overflow")
    
    def validate_buffer(self, buffer):
        if not isinstance(buffer, (bytearray, bytes)):
            raise RuntimeError("buffer must be bytearray or bytes")
        if len(buffer) != self.register_size:     
            raise RuntimeError("buffer length must be equal to register size")
    
    def value_to_buffer(self, value):
        self.validate_value(value)
        return value.to_bytes(self.register_size, byteorder="little", signed=False)
    
    def buffer_to_value(self, buffer):
        # self.validate_buffer(buffer)
        return int.from_bytes(buffer, byteorder="little", signed=False)
    
    def validate_address(self, address):
        if not isinstance(address, int):
            raise RuntimeError("address must be int")
        if address < 0:
            raise RuntimeError("address must not be negative")
        if address % self.register_size:
            raise RuntimeError("address not aligned by register size")
        if address >= self.memory_size:
            raise RuntimeError("address overflow")
            
    def format_value(self, value):
        buffer = self.value_to_buffer(value)
        return self.value_format.format(*buffer)

    def format_address(self, address):
        # self.validate_address(address)
        return self.address_format.format(value=address)

    def format_buffer(self, buffer):
        return self.format_value(self.buffer_to_value(buffer))

    def format_argument(self, value):
        return self.argument_format.format(value=value)
