from emulator.app.component import Component

class PacketMem(Component):

    def handle_config(self):
        self.pipeline_config = self.app.config.get("pipeline")
        self.memory_size = self.config.get_bytes("size")
        self.memory_width = self.config.get_bytes("width")
        self.packets = []
        self.memory_usage = 0
        self.max_memory_usage = 0
        self.mem_kb_static_power = self.config.get_float("mem_kb_static_power")
        self.static_power = (self.mem_kb_static_power * self.memory_size / 1024)
        self.mem_port_dynamic_power = self.config.get_float("mem_port_dynamic_power")
        self.chip_area = (self.config.get_float("mem_kb_chip_area") * self.memory_size / 1024)
        
        self.dynamic_power = 0
        
        for i in range(int(self.app.config.get("ether_ports_cnt"))):
            self.packets.append([])
            
            
    def handle_stop(self):
        # sanity check
        if (self.memory_usage != 0):
            self.fatal_error("Packet body memory not empty on finish!")


    # Put packet body to memory
    def put_packet(self, port, body, full_len):
        # calc memory space & power
        self.memory_usage += len(body)
        self.dynamic_power += (full_len / self.memory_width) * self.mem_port_dynamic_power
        # check for overflow
        if (self.memory_usage >= self.memory_size):
            self.fatal_error("Packet body memory overflow!")
        # remember maximum for statistics
        if (self.memory_usage > self.max_memory_usage):
            self.max_memory_usage = self.memory_usage
        # put packet body to storage
        self.packets[port].append(body)
    
    
    # Take packet body out of memory    
    def get_packet(self, port):
        if not self.packets[port]:
            self.fatal_error("Reading from empty packet body memory!")
        body = self.packets[port][0]
        del(self.packets[port][0])
        # calc memory space & power
        self.memory_usage -= len(body)
        self.dynamic_power += (len(body) / self.memory_width) * self.mem_port_dynamic_power
        return body
        
            
    def get_dynamic_power(self):
        return self.dynamic_power
