

def parse_int(v, empty_value=None):
    if isinstance(v, int):
        return v
    if not isinstance(v, str):
        raise ValueError("must be string")
    if 0 == len(v):
        if empty_value is None:
            raise ValueError("must not be empty")
        return empty_value
    return int(v, 0)


def parse_bits(v):
    if isinstance(v, int):
        return v
    if not isinstance(v, str):
        raise ValueError("must be string")
    ii = v.split(":")
    if len(ii) == 1:
        return 8 * parse_int(v)
    if len(ii) == 2:
        return parse_int(ii[0], empty_value=0) * 8 + parse_int(ii[1])
    raise ValueError("must be only two parts separated by ':'")


def parse_items(items, parser, allow_not_parsed):
    ret = []
    for item in items:
        try:
            value = parser(item)
        except ValueError:
            if not allow_not_parsed:
                raise
            value = item
        ret.append(value)
    return ret


def make_int_numbering_format(item_count):
    r = 1
    n = 10
    while True:
        if item_count < n:
            break
        r += 1
        n *= 10
    return "%0" + str(r) + "d"

