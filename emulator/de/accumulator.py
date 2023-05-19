
class DEAccumulator:

    def __init__(self, de):
        self.__register_size = de.register_size
        self.__value_max = (1 << self.__register_size) - 1
        self.__value = 0

    def get_value(self):
        return self.__value

    def set_value(self, value):
        if not isinstance(value, int):
            raise RuntimeError("value must be int")
        if value < 0:
            raise RuntimeError("value must not be negative")
        if value > self.__value_max:
            raise RuntimeError("value overflow")
        self.__value = value

    value = property(get_value, set_value)
