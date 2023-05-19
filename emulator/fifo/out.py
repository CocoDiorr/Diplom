from scapy.all import wrpcap
from scapy.all import Packet
from emulator.app.component import Component
from emulator.pipeline.metadata import Metadata
import os


class OutFIFO(Component):			

    @classmethod
    def handle_args_register(cls, parser):
        parser.add_argument(
            "--out-fifo", "-o", dest="out_fifo", type=str,
            help="Packets output PCAP directory", required=True
        )

    def handle_initialize(self, params):
        self.pipeline_num = params["pipeline_num"]
        self.pipeline = params["pipeline"]
        self.in_fifo = self.pipeline.in_fifo
        #self.OFAgent = self.pipeline.OFAgent
        self.__packets = []

    def handle_config(self):
        self.pipeline_config = self.app.config.get("pipeline")
        self.ether_ports_cnt = self.app.config.get_int("ether_ports_cnt")
        self.ctrl_port = self.app.config.get_int("ctrl_port")
        self.chip_area = self.pipeline_config.get_float("fifo_chip_area")
        self.static_power = self.app.config.get_float("ether_port_power")

    def handle_args(self, args):
        filename_format = args.out_fifo + "/port{num:02d}_out.pcap"
        if not os.path.isdir(args.out_fifo):
            self.fatal_error("Output PCAP directory does not exist:" + args.out_fifo)
        # remove old PCAPs
        if (self.pipeline_num == 0):
            try:
                os.remove(filename_format.format(num=self.ctrl_port))
            except:
                pass
        try:
            os.remove(filename_format.format(num=self.pipeline_num))
        except:
            pass
        # put all ports PCAP paths to list
        self.path = []
        for i in range(self.ctrl_port+1):
            self.path.append(filename_format.format(num=i))


    # On each tick check if new packet is ready
    def tick(self):
        header_out,metadata = self.prev_pipeline_element.get_header_out()
        if header_out != None:
            body = self.app.packet_memory.get_packet(self.pipeline_num)
            if len(body) == 0:
                header_out = header_out[:metadata.packet_size]
            packet = Packet() / header_out / body
            packet.time = 0
            packet.original = header_out + body
            if metadata.update_port():
                self.app.agent.upd_back(self.pipeline_num)
            else:
                for i in metadata.get_outbound_ports():
                    wrpcap(self.path[i], packet, append=True)
                if metadata.get_reprocess():
                    self.in_fifo.add_to_queue(packet, metadata)
                if metadata.get_control_port():
                    wrpcap(self.path[self.ctrl_port], packet, append=True)
            return True
        return False

    def get_statistics(self):
        return 0,0
