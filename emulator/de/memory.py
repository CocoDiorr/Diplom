

class DEMemory:					

    def __init__(self, de, de_code):
        self.__de = de
        self.de_code = de_code
        self.de_shadow_code = de_code
        self.__buffer = bytearray(de.memory_size)

    def get_buffer(self, address):
        # self.__de.validate_address(address)
        return self.__buffer[
            address:
            address + self.__de.register_size
        ]

    def set_buffer(self, address, buffer):
        # self.__de.validate_address(address)
        self.de_code.validate_buffer(buffer)
        self.__buffer[
            address:
            address + self.__de.register_size
        ] = buffer

    def get_value(self, address, offset=None):
        buffer = self.get_buffer(address)
        value = self.de_code.buffer_to_value(buffer)
        # value = self.__de.apply_offset(value, offset)
        return value

    def set_value(self, address, value, offset=None):
        # value = self.__de.apply_offset(value, offset)
        buffer = self.de_code.value_to_buffer(value)
        self.set_buffer(address, buffer)
