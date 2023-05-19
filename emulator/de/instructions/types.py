def swap32(value):
    return int.from_bytes(value.to_bytes(4, byteorder='big'), byteorder='little')

def swap128(value):
    return int.from_bytes(value.to_bytes(16, byteorder='big'), byteorder='little')

def swap(value, size):
    return int.from_bytes(value.to_bytes((1<<size), byteorder='big'), byteorder='little')


def frm_msk(msk):
    return ((1 << msk)-1)


def mem_access_size(msk):
    if (msk == 0):
        raise ValueError("Invalid memory mask", msk)
    elif (msk <= 8):
        sz = 0
    elif (msk <= 16):
        sz = 1
    elif (msk <= 32):
        sz = 2
    elif (msk <= 64):
        sz = 3
    elif (msk <= 128):
        sz = 4
    else:
        raise ValueError("Invalid memory mask", msk)

    return sz


# Load from memory helper
def loadmem(context, adr, msk, be=False):
    size = mem_access_size(msk)
    off = context.get_offset_reg()
    value = context.get_memory(adr + off, None, size) & frm_msk(msk)
    if be:
        value = swap(value, size)
    context.inc_power_memory()
    return value


# Store to memory helper
def storemem(context, adr, msk, be=False):
    size = mem_access_size(msk)
    off =  context.get_offset_reg()
    data = context.get_memory(adr + off, None, size) & ~frm_msk(msk)
    a = context.get_accumulator() & frm_msk(msk)
    if be:
        a = swap(a, size)
    value = a | data
    context.set_memory(adr + off, value, size)
    context.inc_power_memory()


def instruction_cmpj(context, jmp, lit, msk):
    a = context.get_accumulator() & frm_msk(msk)
    b = lit
    if a == b:
        context.set_position(jmp)
    else:
        context.next_position()


def instruction_cmpjn(context, jmp, lit, msk):
    a = context.get_accumulator() & frm_msk(msk)
    b = lit
    if a != b:
        context.set_position(jmp)
    else:
        context.next_position()


def instruction_cmpjg(context, jmp, lit, msk):
    a = context.get_accumulator() & frm_msk(msk)
    b = lit
    if a > b:
        context.set_position(jmp)
    else:
        context.next_position()


def instruction_cmpjl(context, jmp, lit, msk):
    a = context.get_accumulator() & frm_msk(msk)
    b = lit
    if a < b:
        context.set_position(jmp)
    else:
        context.next_position()


def instruction_cmpjlge(context, jmpl, jmpge, lit):
    a = context.get_accumulator() #& frm_msk(msk)
    b = lit
    if a < b:
        context.set_position(jmpl)
    else:
        context.set_position(jmpge)


def instruction_load(context, adr, msk):
    context.set_accumulator(loadmem(context, adr, msk))
    context.next_position()


def instruction_loadbe(context, adr, msk):
    context.set_accumulator(loadmem(context, adr, msk, True))
    context.next_position()


def instruction_loadi(context, lit):
    context.set_accumulator(lit)
    context.next_position()


def instruction_store(context, adr, msk):
    storemem(context, adr, msk)
    context.next_position()


def instruction_storebe(context, adr, msk):
    storemem(context, adr, msk, True)
    context.next_position()


def instruction_add(context, adr, msk):
    a = context.get_accumulator()
    b = loadmem(context, adr, msk)
    context.set_accumulator(a + b)
    context.next_position()


def instruction_addi(context, lit):
    a = context.get_accumulator()
    context.set_accumulator(a + lit)
    context.next_position()


def instruction_sub(context, adr, msk):
    a = context.accumulator
    b = loadmem(context, adr, msk)
    context.set_accumulator(a - b)
    context.next_position()


def instruction_subi(context, lit):
    a = context.accumulator
    context.set_accumulator(a - lit)
    context.next_position()


def instruction_j(context, adr):
    context.position = adr


def instruction_rol(context, ofs):
    value = context.get_accumulator()
    value <<= ofs
    value &= context.register_value_max
    context.set_accumulator(value)
    context.next_position()


def instruction_ror(context, ofs):
    value = context.get_accumulator()
    value >>= ofs
    context.set_accumulator(value)
    context.next_position()


def instruction_rcr(context, ofs):
    acc = context.get_accumulator()
    value = acc >> ofs
    value |= (acc & ((1 << ofs) - 1)) << (context.register_width - ofs)
    context.set_accumulator(value)
    context.next_position()


def instruction_rcl(context, ofs):
    acc = context.get_accumulator()
    value = (acc << ofs) & context.register_value_max
    value |= acc >> (context.register_width - ofs)
    context.set_accumulator(value)
    context.next_position()


def instruction_or(context, adr, msk):
    a = context.get_accumulator()
    b = loadmem(context, adr, msk)
    context.set_accumulator(a | b)
    context.next_position()


def instruction_orbe(context, adr, msk):
    a = context.get_accumulator()
    b = loadmem(context, adr, msk, True)
    context.set_accumulator(a | b)
    context.next_position()


def instruction_ori(context, lit):
    a = context.get_accumulator()
    context.set_accumulator(a | lit)
    context.next_position()


def instruction_xor(context, adr, msk):
    a = context.get_accumulator()
    b = loadmem(context, adr, msk)
    context.set_accumulator(a ^ b)
    context.next_position()


def instruction_xorbe(context, adr, msk):
    a = context.get_accumulator()
    b = loadmem(context, adr, msk, True)
    context.set_accumulator(a ^ b)
    context.next_position()


def instruction_xori(context, lit):
    a = context.get_accumulator()
    context.set_accumulator(a ^ lit)
    context.next_position()


def instruction_and(context, adr, msk):
    a = context.get_accumulator()
    b = loadmem(context, adr, msk)
    context.set_accumulator(a & b)
    context.next_position()


def instruction_andbe(context, adr, msk):
    a = context.get_accumulator()
    b = loadmem(context, adr, msk, True)
    context.set_accumulator(a & b)
    context.next_position()


def instruction_andi(context, lit):
    a = context.get_accumulator()
    context.set_accumulator(a & lit)
    context.next_position()


def instruction_modi(context, lit):
    ticks = 10
    a = context.get_accumulator() & frm_msk(64)
    context.set_accumulator(a % lit)
    context.inc_power_alu(ticks)
    context.spend_ticks(ticks)
    context.next_position()


def instruction_loadoff(context):
    context.set_offset_reg(context.get_accumulator() & frm_msk(context.offset_reg_size*8))
    context.next_position()


def instruction_loadoffi(context, lit):
    context.set_offset_reg(lit & frm_msk(context.offset_reg_size*8))
    context.next_position()


def instruction_cpoff(context):
    context.set_accumulator(context.offset_reg)
    context.next_position()


def instruction_nop(context):
    context.next_position()


def instruction_setsz(context, lit):
    offset, context.offset_reg = context.offset_reg, 0
    context.set_accumulator(context.de.metadata.header_start - lit + context.de.metadata.header_size)
    storemem(context, context.de.metadata_address + context.de.metadata.metadata_header_start_off,
             context.de.metadata.metadata_header_start_size * 8)
    context.set_accumulator(lit)
    storemem(context, context.de.metadata_address + context.de.metadata.metadata_header_size_off,
             context.de.metadata.metadata_header_size_size * 8)
    context.set_accumulator(context.de.metadata.packet_size - context.de.metadata.header_size + lit)
    storemem(context, context.de.metadata_address + context.de.metadata.metadata_packet_size_off,
             context.de.metadata.metadata_packet_size_size * 8)
    context.offset_reg = offset
    context.next_position()


def instruction_setmask(context, lit):
    offset, context.offset_reg = context.offset_reg, 0
    context.set_accumulator(loadmem(context, context.de.metadata_address + context.de.metadata.metadata_port_map_off,
                                    context.de.metadata.metadata_port_map_size * 8) | lit)
    storemem(context, context.de.metadata_address + context.de.metadata.metadata_port_map_off,
             context.de.metadata.metadata_port_map_size * 8)
    context.offset_reg = offset
    context.next_position()


def instruction_setxmask(context, lit):
    offset, context.offset_reg = context.offset_reg, 0
    context.set_accumulator(lit)
    storemem(context, context.de.metadata_address + context.de.metadata.metadata_port_map_off,
             context.de.metadata.metadata_port_map_size * 8)
    context.offset_reg = offset
    context.next_position()


def instruction_loadmeta(context, adr, msk):
    offset, context.offset_reg = context.offset_reg, 0
    context.set_accumulator(loadmem(context, context.de.metadata_address + context.de.metadata.metadata_user_meta_off +
                                    adr, msk))
    context.offset_reg = offset
    context.next_position()


def instruction_storemeta(context, adr, msk):
    offset, context.offset_reg = context.offset_reg, 0
    storemem(context, context.de.metadata_address + context.de.metadata.metadata_user_meta_off + adr, msk)
    context.offset_reg = offset
    context.next_position()