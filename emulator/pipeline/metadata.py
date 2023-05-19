from time import time

class Metadata:
    
    def __init__(self, app, packet_size, header_size, inbound_port, user_meta=0, port_map=0, upd_flg=0):
        self.app = app
        self.pipeline_config = self.app.config.get("pipeline")
        self.metadata_config = self.pipeline_config.get("metadata")
        self.de_config = self.app.config.get("de")
        self.ether_ports_cnt = int(self.app.config.get("ether_ports_cnt"))
        
        # metadata config
        self.metadata_size  = self.pipeline_config.get_bytes("metadata_size")
        self.metadata_packet_size_size  = self.metadata_config.get_bytes("packet_size")
        self.metadata_header_size_size  = self.metadata_config.get_bytes("header_size")
        self.metadata_header_start_size = self.metadata_config.get_bytes("header_start")
        self.metadata_inbound_port_size = self.metadata_config.get_bytes("inbound_port")
        self.metadata_timestamp_size    = self.metadata_config.get_bytes("timestamp")
        self.metadata_port_map_size     = self.metadata_config.get_bytes("port_map")
        self.metadata_reserved1_size    = self.metadata_config.get_bytes("reserved1")
        self.metadata_user_meta_size    = self.metadata_config.get_bytes("user_meta")
        self.metadata_reserved2_size    = self.metadata_config.get_bytes("reserved2")

        self.metadata_packet_size_off   = 0
        self.metadata_header_size_off   = self.metadata_packet_size_off + self.metadata_packet_size_size
        self.metadata_header_start_off  = self.metadata_header_size_off + self.metadata_header_size_size
        self.metadata_timestamp_off     = self.metadata_header_start_off + self.metadata_header_start_size
        self.metadata_port_map_off      = self.metadata_timestamp_off + self.metadata_timestamp_size
        self.metadata_inbound_port_off  = self.metadata_port_map_off +  self.metadata_port_map_size
        self.metadata_reserved1_off     = self.metadata_inbound_port_off +  self.metadata_inbound_port_size
        self.metadata_user_meta_off     = self.metadata_reserved1_off + self.metadata_reserved1_size
        self.metadata_reserved2_off     = self.metadata_user_meta_off + self.metadata_user_meta_size
        
        self.packet_size = packet_size
        self.header_size = header_size
        self.body_packet_size = packet_size - header_size
        self.header_start = self.calc_header_start()
        self.inbound_port = inbound_port
        self.timestamp = int(time() * 10**6) & 0xFF
        self.port_map = port_map
        self.reserved1 = upd_flg					
        self.user_meta = user_meta
        self.reserved2 = 0
        
        self.control_port_mask = (1<<(self.pipeline_config.get_int("port_mask_ctrl_bit")))
        self.reprocess_mask = (1<<(self.pipeline_config.get_int("port_mask_reprocess_bit")))
   
    def calc_header_start(self):
       return int(self.de_config.get("memory_size")) - self.metadata_size - self.header_size
            
    # Prints metadata field for debug    
    def print_metadata(self):
        #!! todo
        print("Metadata outbound ports: ", self.get_outbound_ports())
        
    def bytes_format(self, v, s):
        return v.to_bytes(s, byteorder="little", signed=False)
        
    def from_bytes_format(self, b, off, size):
        return int.from_bytes(b[off:off+size], byteorder="little", signed=False)
    
    def get_bytes(self):
        return self.bytes_format(self.packet_size, self.metadata_packet_size_size) + \
            self.bytes_format(self.header_size, self.metadata_header_size_size) + \
            self.bytes_format(self.header_start, self.metadata_header_start_size) + \
            self.bytes_format(self.timestamp, self.metadata_timestamp_size) + \
            self.bytes_format(self.port_map, self.metadata_port_map_size) + \
            self.bytes_format(self.inbound_port, self.metadata_inbound_port_size) + \
            self.bytes_format(self.reserved1, self.metadata_reserved1_size) + \
            self.bytes_format(self.user_meta, self.metadata_user_meta_size) + \
            self.bytes_format(self.reserved2, self.metadata_reserved2_size)

    @classmethod
    def from_bytes(cls, app, b):
        metadata = cls(app, 0, 0, 0, 0)
        metadata.packet_size = metadata.from_bytes_format(b, metadata.metadata_packet_size_off, metadata.metadata_packet_size_size)
        metadata.header_size = metadata.from_bytes_format(b, metadata.metadata_header_size_off, metadata.metadata_header_size_size)
        metadata.inbound_port = metadata.from_bytes_format(b, metadata.metadata_inbound_port_off, metadata.metadata_inbound_port_size)
        metadata.port_map = metadata.from_bytes_format(b, metadata.metadata_port_map_off, metadata.metadata_port_map_size)
        metadata.header_start = metadata.from_bytes_format(b, metadata.metadata_header_start_off, metadata.metadata_header_start_size)
        metadata.user_meta = metadata.from_bytes_format(b, metadata.metadata_user_meta_off, metadata.metadata_user_meta_size)
        metadata.reserved1 = metadata.from_bytes_format(b, metadata.metadata_reserved1_off, metadata.metadata_reserved1_size)
        return metadata
        
            
    def get_outbound_ports(self):
        ports = []
        for i in range(self.ether_ports_cnt):
            if ((1<<i) & self.port_map) != 0:
                ports.append(i)
        return ports
    
    # Returns true if packet should be sent to control port    
    def get_control_port(self):
        return (self.port_map & self.control_port_mask) != 0
        
    # Returns true if packet should be reprocessed
    def get_reprocess(self):
        return (self.port_map & self.reprocess_mask) != 0
        
    def set_reprocess(self):
        self.port_map |= self.reprocess_mask
        
    def update_port(self):
    	#print(f"update port = {self.reserved1}")
    	return self.reserved1 == 1
