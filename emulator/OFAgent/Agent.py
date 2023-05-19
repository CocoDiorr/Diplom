from scapy.all import Ether, IP, TCP
from random import randint
from emulator.app.component import Component
from emulator.util.parsing import make_int_numbering_format
from emulator.OFAgent.parser import DECodeParser
from emulator.pipeline.metadata import Metadata
from subprocess import call
from math import ceil
import json


class OFAgent(Component):
    """
    Simple OpenFlow Agent implementation

        * handle's are activated automatically within application initialization
    """

    @classmethod
    def handle_args_register(cls, parser):
        """Add arg for the ASM update prog file path."""
        # parser.add_argument(
        #     "--OF-Agent", "-ofa", dest="agent", type=str,
        #     help="Update file path", required=True
        # )


    # def generate_table(self, no_of_rules):
    #     self.table = dict()

    #     for _ in range(no_of_rules):
    #         mac_addr = "%02x:%02x:%02x:%02x:%02x:%02x" % (
    #             randint(0, 255),
    #             randint(0, 255),
    #             randint(0, 255),
    #             randint(0, 255),
    #             randint(0, 255),
    #             randint(0, 255)
    #         )

    #         self.table[mac_addr] = 'outport:' + str(randint(0, 24))

    #     print(f"\nTABLE of rules = {self.table}\n")

    def handle_initialize(self, params):
        self.upd_flg = False
        self.pipelines = []
        self.upd_ticks = []
        self.upd_flgs = []
        self.total_ticks = 0
        self.upd_active = False
        self.ht = dict()
        self.updates = None
        # self.generate_table(10)


    def handle_config(self):
        """Handle Agent configs."""
        self.config = self.app.config
        self.log_lines = self.config["agent"]["log_lines"]
        self.log_labels = self.config["agent"]["log_labels"]
        self.address_format = self.config["de_code"]["address_format"]
        self.register_size = int(self.config["de"]["register_size"])
        self.log_instructions = self.config["de_code"]["log_instructions"]
        self.value_format = self.config["de_code"]["data_format"]
        self.upd_code = self.app.de_code
        self.register_value_max = (1 << (self.register_size * 8)) - 1
        self.header_size = 0
        for name in self.config["header"]:
            self.header_size += self.config["sizes"][name]
        self.header_size = ceil(self.header_size / 32)

        # print(f"\nHEADER_SZ = {self.header_size}\n")

    def handle_args(self, args):
        """Prepare update for installation."""
        # self.upd_path_cpp = args.agent
        # self.upd_path = self.upd_path_cpp + ".pp"
        # # Call CPP (for ex. GCC) for preprocessing
        # rc = call(["cpp", "-x", "assembler-with-cpp", "-P", "-nostdinc", self.upd_path_cpp, "-o",  self.upd_path])
        # if (rc != 0):
        #     raise RuntimeError("Source preprocessing by CPP failed!")
        # self.logger.info("Parsing code file: {path}".format(
        #     path=self.os_path.abspath(self.upd_path)
        # ))
        # with open(self.upd_path, "r") as f:
        #     self.lines = tuple(f.read().replace('\n', ';').replace('; ', ';').replace(' ;', ';').split(';'))
        # self.line_index_format = make_int_numbering_format(len(self.lines) + 1)

        # parser = DECodeParser(self, self.upd_path, self.lines, self.register_size)
        # self.lines = tuple(parser.lines)
        # self.instructions = parser.instructions
        # self.address_to_line = parser.address_to_line
        # self.line_to_address = parser.line_to_address
        # self.instr_mem_counter = parser.instr_mem_counter

        self.algo = args.algo

        self.ht_path = args.hash_table
        with open(self.ht_path + '/data.json', 'r') as f:
            self.ht = json.load(f)

            if self.algo == 'classic':
                self.updates = self.ht.copy()
            elif self.algo == 'incr':
                self.updates = {'type': None, 'data': []}

        # if self.app.out:
        # print(f'\nHASH_TABLE_AGENT = {self.ht}\n')

        # self.upd_path = args.agent
        with open(self.ht_path + '/upd.json', 'r') as f:
            self.upd = json.load(f)
        
        # if self.app.out:
        # print(f'\nUPDATE_PCK = {self.upd}\n')
        # self.upd_ticks = [0] * len(self.pipelines)

        if self.algo == 'incr':
            self.no_upds = 0
        self.process_upd()



    def format_address(self, address):
        return self.address_format.format(value=address)

    def validate_value(self, value):
        if not isinstance(value, int):
            raise RuntimeError("value must be int")
        if value < 0:
            raise RuntimeError("value must not be negative")
        if value >= self.register_value_max:
            raise RuntimeError("value overflow")

    def value_to_buffer(self, value):
        self.validate_value(value)
        return value.to_bytes(self.register_size, byteorder="little", signed=False)

    def format_value(self, value):
        buffer = self.value_to_buffer(value)
        return self.value_format.format(*buffer)
    
    
    def process_upd(self):
        if self.algo == 'classic':
            if self.upd['type'] == 'add':
                self.updates[self.upd['value']] = self.upd['action']

                if self.app.out:
                    print(f'\nNEW_UPDATE = {self.updates}\n')
            elif self.upd['type'] == 'mod':
                if self.upd['value'] == '***':
                    for k in self.updates.keys():
                        self.updates[k] = self.upd['action']
                else:
                    self.updates[self.upd['value']] = self.upd['action']
            elif self.upd['type'] == 'del':
                if self.upd['value'] == '***':
                    self.updates = dict()
                else:
                    self.updates.pop(self.upd['value'])
            
            self.no_upds = 1
        elif self.algo == 'incr':
            if self.upd['type'] == 'add':
                self.updates['type'] = 'add'
                self.updates['data'] = [{self.upd['value']: self.upd['action']}]

                if self.app.out:
                    print(f'\nNEW_UPDATE = {self.updates}\n')
                # self.updates.append((self.upd['value'], self.upd['action']))
            elif self.upd['type'] == 'mod':
                if self.upd['value'] == '***':
                    self.updates['type'] = 'mod'
                    data = list(self.ht.items())
                    chunks = [data[i: i + 97] for i in range(0, len(data), 97)]
                    self.updates['data'] = [dict(chunk) for chunk in chunks]

                    # for k in self.ht:
                    #     self.updates['data'][k] = self.upd['action']
                else:
                    self.updates['type'] = 'mod'
                    self.updates['data'] = [{self.upd['value']: self.upd['action']}]
            elif self.upd['type'] == 'del':
                if self.upd['value'] == '***':
                    self.updates['type'] = 'del'

                    data = list(self.ht.items())
                    step = 97 // (self.header_size - 1)
                    chunks = [data[i: i + step] for i in range(0, len(data), step)]
                    self.updates['data'] = [dict(chunk) for chunk in chunks]
                else:
                    self.updates['type'] = 'del'
                    self.updates['data'] = [{ self.upd['value']: None}]

            self.no_upds = len(self.updates['data'])

            # if self.app.out:
            # print(f'\nCompiled_upd = {self.updates["data"]}\n')
        



    def upload_upd(self):
        """Upload prepared update in shadow_mem memory part."""
        if not self.upd_active:
            
            for i, pipe in enumerate(self.pipelines):
                # pipe[1].de.shadow_mem_instructions = self.instructions
                # pipe[1].de.shadow_mem_code.address_to_line = self.address_to_line
                # pipe[1].de.shadow_mem_code.lines = self.lines
                if self.algo == 'classic':
                    pipe[1].de.updates = self.updates.copy()
                elif self.algo == 'incr':
                    pipe[1].de.updates = dict()
                    pipe[1].de.updates['type'] = self.updates['type']
                    pipe[1].de.updates['data'] = self.updates['data'][:]
                self.upd_ticks.append(0)

                self.upd_flgs.append(0)

            if self.algo == 'classic':
                self.total_ticks += 6144 * self.header_size * 2
                # if self.upd['type'] == 'del' and self.upd['value'] == '***':
                #     self.total_ticks += len(self.ht) * self.header_size * 2
                # else:
                #     self.total_ticks += len(self.updates) * self.header_size * 2
            elif self.algo == 'incr':
                # self.updates['data'].pop(0)
                # считаем, что для ЦПУ нужен 1 такт, чтобы записать асм правило
                if self.updates["type"] == 'add':
                    # 4 * k * 2 + k, k = self.header_size
                    self.total_ticks += self.header_size * 9 * 2
                elif self.updates["type"] == 'mod':
                    # 4 + 4 * number_of_entries * 2 + 2
                    self.total_ticks += 4 * 2 + 2
                    for sub in self.updates['data']:
                        self.total_ticks += 4 * len(sub) * 2
                    # self.total_ticks += 4 * (1 + len(self.updates['data']))
                elif self.updates["type"] == 'del':
                    # 4 + k * 4 - 4
                    self.total_ticks += 4 * 2
                    for sub in self.updates['data']:
                        self.total_ticks += 4 * (self.header_size - 1) * 2 * len(sub)
                    # self.total_ticks += 4 * self.header_size
                # self.total_ticks += len(self.updates['data']) * 2
            
            if self.app.out:
                print(f"It took {self.total_ticks} ticks to write an update")

    def compile_update_pck(self):
        """Compile one wholesome update out of pieces from the controller."""
        if not self.upd_active:
            # chunks = 0

            # if self.algo == 'classic':
            #     chunks = 1
            # elif self.algo == 'incr':
            #     chunks = self.no_upds
            
            # print(f"\nCUNKS = {chunks}\n")
            # for _ in range(chunks):
            fake_pck = Ether()/IP()/TCP()
            for i, pipe in enumerate(self.pipelines):
                fake_meta = Metadata(self.app, len(fake_pck), 54, i, upd_flg=1)
                pipe[1].in_fifo.add_to_queue(fake_pck, fake_meta)


    def upd_back(self, pipe_num):
        #print(f"Pipeline[{pipe_num}] sent upd_pckg back")
        self.upd_flgs[pipe_num] = True
        if all(self.upd_flgs):
            self.upd_active = False

    def tick(self):
        """Execute one tick and check for packet back."""
        pass
        # if self.upd_flgs:
        #     if not all(self.upd_flgs):
        #         for i in range(len(self.upd_flgs)):
        #             if not self.upd_flgs[i]:
        #                 self.upd_ticks[i] += 1

    def handle_stop(self):
        #for i, ticks in enumerate(self.upd_ticks):
            #print(f"pipeline[{i}] took {ticks - 2} ticks to update")
        self.total_ticks += max(self.upd_ticks) - 2

        if self.app.out:
            print(f"Total ticks for update = {self.total_ticks}")

        with open(self.ht_path + f'/{self.algo}.txt', "a") as f:
            f.write('[' + str(len(self.ht)) + ',' + str(self.total_ticks) + '],\n')
