from emulator.util.parsing import parse_int, parse_bits


NO_DEFAULT_VALUE = object()


class ConfigWrapper:

    def __init__(self, name, config):
        self.__name = name
        self.__items = dict(
            (
                k,
                v
                if not isinstance(v, dict)
                else self.__make_child(k, v)
            )
            for k, v in config.items()
        )

    def __make_child(self, name, items):
        return ConfigWrapper(
            "{name}/{subname}".format(
                name=self.__name,
                subname=name
            ),
            items
        )

    def __getitem__(self, item):
        try:
            return self.__items[item]
        except KeyError:
            raise KeyError("{name}/{item} not found".format(
                name=self.__name,
                item=item
            ))

    def make_child(self, item):
        try:
            r = self.__items[item]
        except KeyError:
            r = self.__make_child(item, {})
            self.__items[item] = r
        else:
            if not isinstance(r, ConfigWrapper):
                raise RuntimeError("{name}/{item} must be container".format(
                    name=self.__name,
                    item=item
                ))
        return r

    def get(self, *args, **kw):
        return self.__items.get(*args, **kw)

    def get_value(self, name, default=NO_DEFAULT_VALUE, converter=None):
        try:
            v = self[name]
        except KeyError:
            if default is NO_DEFAULT_VALUE:
                raise
            return default
        if converter is not None:
            try:
                v = converter(v)
            except ValueError as ex:
                raise ValueError("config parameter {name} parsing error: {error}".format(
                    name=name,
                    error=str(ex.args)
                ))
        return v

    def get_int(self, *args, **kw):
        return self.get_value(*args, converter=parse_int, **kw)

    def get_bits(self, *args, **kw):
        return self.get_value(*args, converter=parse_bits, **kw)
        
    def get_float(self, cfg):
        return float(self.get(cfg))

    def get_bytes(self, *args, block_size=1, **kw):
        def converter(v):
            v = parse_bits(v)
            if v % (block_size * 8):
                raise ValueError("must not have bits component")
            return v // 8
        return self.get_value(*args, converter=converter, **kw)
