from scapy.all import rdpcap
from emulator.app.component import Component
from emulator.pipeline.metadata import Metadata
from os import path

class InFIFO(Component):				

    @classmethod
    def handle_args_register(cls, parser):
        parser.add_argument(
            "--in-fifo", "-i", dest="in_fifo", type=str,
            help="Packets input PCAP directory", required=True
        )

    def handle_initialize(self, params):
        self.pipeline_num = params["pipeline_num"]
        self.prev_pipeline_element = None

    def handle_start(self):
        self.in_packets = []
        for p in self.packets:
            self.in_packets.append((p, None))
        self.cur_packet = 0

    def handle_args(self, args):
        if not path.isdir(args.in_fifo):
            self.fatal_error("Input PCAP directory does not exist:" + args.in_fifo)
        self.__path = args.in_fifo + "/port" + format(self.pipeline_num, "02d") + "_in.pcap"

    def handle_config(self):
        self.pipeline_config = self.app.config.get("pipeline")
        self.metadata_config = self.pipeline_config.get("metadata")
        self.packet_header_size = int(self.pipeline_config.get("packet_header_size"))
        self.chip_area = self.pipeline_config.get_float("fifo_chip_area")
        self.static_power = self.app.config.get_float("ether_port_power")

    def handle_stop(self):
        if self.cur_packet < len(self.in_packets):
            self.fatal_error("Input fifo is not empty on stop!")

    def get_header_out(self):
        if self.cur_packet >= len(self.in_packets):
            return None,None
        packet = self.in_packets[self.cur_packet][0]
        metadata_in = self.in_packets[self.cur_packet][1]
        self.cur_packet += 1
        # Strip packet header
        data = packet.original
        packet_size = len(data)
        body = data[self.packet_header_size:]
        self.app.packet_memory.put_packet(self.pipeline_num, body, packet_size)
        header_in = data[:self.packet_header_size]
        # Form metadata
        if metadata_in == None:
            metadata = Metadata(self.app, packet_size, self.packet_header_size, self.pipeline_num)
        else:
            metadata = metadata_in
            #metadata = Metadata(self.app, packet_size, self.packet_header_size, self.pipeline_num)
            #metadata.set_reprocess()
        return header_in,metadata

    # Clock event
    def tick(self):
        return False

    def get_statistics(self):
        return 0,0

    def packets_processed(self):
        return self.cur_packet

    def add_to_queue(self, packet, metadata=None):
    	if metadata:
    		#print("fake pckt")
    		self.in_packets.insert(0, (packet, metadata))
    	else:
        	self.in_packets.append((packet, metadata))

    @property
    def packets(self):
        if path.isfile(self.__path):
            return rdpcap(self.__path)
        else:
            self.logger.warning("Input PCAP " + self.__path + " not found, assuming no packets on this port.")
            return []
