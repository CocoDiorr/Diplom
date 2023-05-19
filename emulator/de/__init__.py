import logging
import json
from emulator.app.component import Component
import emulator.util.parsing
from emulator.de.memory import DEMemory
from emulator.pipeline.metadata import Metadata
from .context import DEExecutorContext
from random import randint

DE_NAME_FORMAT = "de_{pl:02d}_{de:02d}"

class DE(Component):

	@classmethod
	def handle_args_register(cls, parser):
		parser.add_argument(
			"--de-log", dest="de_logfile", type=str,
			help="DE log file name format, {pl} is replaced by pipeline number and {de} by de number in pipeline.", 
			default="./" + DE_NAME_FORMAT + ".log"
		)
		parser.add_argument(
			"--de-log-console", action='append', dest="de_logcons_list", 
			help="DE numbers to log to console in format: de_XX_YY, where XX is pipeline number and YY - de number. Could be used multiple times.", 
			default=[]
		)
		parser.add_argument(
            "--hash-table", "-ht", dest="hash_table", type=str,
            help="JSON for hash_table immitation", required=True
        )
		
	def handle_config(self):
		# Parse config
		# general config
		self.de_code = self.app.de_code
		self.shadow_mem_code = None
		self.pipeline_config = self.app.config.get("pipeline")
		self.metadata_config = self.pipeline_config.get("metadata")
		self.ether_ports_cnt = int(self.app.config.get("ether_ports_cnt"))
		self.upd_flg = False
		
		# sizes & addresses
		self.packet_header_size = self.pipeline_config.get_bytes("packet_header_size")
		self.memory_size = self.config.get_int("memory_size")
		self.shadow_memory_size = self.config.get_int("memory_size")
		self.register_size = self.config.get_bytes("register_size")
		self.offset_reg_size = self.config.get_bytes("offset_reg_size")
		self.instruction_size = self.config.get_bytes("instruction_size")
		self.instructions_address = self.config.get_bytes("instructions_address", 0)
		self.metadata_size = self.pipeline_config.get_bytes("metadata_size")
		self.metadata_address = self.memory_size - self.metadata_size
		self.packet_header_address = self.config.get_bytes(
			"packet_header_address", self.metadata_address - self.packet_header_size)
		self.register_size_bits = self.register_size * 8
		self.register_value_max = (1 << self.register_size_bits) - 1
		self.log_packet_headers_in = self.config["log_packet_headers_in"]
		self.log_packet_headers_out = self.config["log_packet_headers_out"]
		self.log_execution = self.config["log_execution"]
		self.log_metadata = self.config["log_metadata"]
		
		# power (static in mW, dynamic - nJ) & area (in um^2)
		self.reg_byte_static_power = self.config.get_float("reg_byte_static_power")
		self.mem_kb_static_power = self.config.get_float("mem_kb_static_power")
		self.static_power = self.config.get_float("alu_static_power") + (self.reg_byte_static_power * self.register_size) + (self.mem_kb_static_power * self.memory_size / 1024)
		self.alu_dynamic_power = self.config.get_float("alu_dynamic_power")
		self.mem_port_dynamic_power = self.config.get_float("mem_port_dynamic_power")
		self.chip_area = self.config.get_float("alu_chip_area") + (self.config.get_float("mem_kb_chip_area") * self.memory_size / 1024)
		
	
	def handle_args(self, args):
		# config logging
		self.logger = logging.getLogger(self.de_name)
		self.logger.propagate = False
		for l in args.de_logcons_list:
			if self.de_name == l:
				console = logging.StreamHandler()
				self.logger.addHandler(console)
				# self.logger.propagate = True
		logname = args.de_logfile.format(pl=self.pipeline_num, de=self.de_num)
		fh = logging.FileHandler(logname, mode='w')
		self.logger.addHandler(fh)

		self.ht_path = args.hash_table
		with open(self.ht_path + '/data.json', 'r') as f:
			self.ht = json.load(f)

		# print(f'\nHASH_TABLE = {self.ht}\n')
		
	def handle_initialize(self, params):
		self.pipeline_num = params["pipeline_num"]
		self.de_num = params["instance_num"]
		self.pipeline = params["pipeline"]
		self.de_name = DE_NAME_FORMAT.format(pl=self.pipeline_num, de=self.de_num)
		
		
	def handle_start(self):
		self.instructions = self.de_code.instructions				
		self.shadow_mem_instructions = None
		self.instr_mem_counter = self.de_code.instr_mem_counter
		self.de_instructions = self.app.de_instructions				
		self.memory = DEMemory(self, self.de_code)					
		self.register_size = self.register_size					
		self.header_out = None
		self.metadata_out = None
		self.metadata = None
		self.total_dynamic_power = 0
		self.total_ticks = 0
		self.updates = None
		#self.shadow_mem_code.print_code()
		
		# Copy instructions
		for i, buffer in enumerate(self.instructions):
			self.memory.set_buffer(
				self.instructions_address + i * self.register_size,
				buffer
			)
		
		# Calculate memory utilization
		# self.memory_utilization = self.memory_size / ((self.instructions * self.register_size) + self.metadata_size)
		memory_utilization = self.instr_mem_counter + self.metadata_size
		self.pipeline.commit_prog_statistics(memory_utilization)
		
		# Create executor context
		self.processing_header = False
		self.context = DEExecutorContext(self)
	
	
	# Perform single clock tick			   
	def tick(self):						
		if self.processing_header:
			if self.metadata.reserved1:
				# print(f"\nDE UPD = {self.updates}\n")
				# print("Entered update condition")
				# self.instructions = self.shadow_mem_instructions
				# self.de_code.address_to_line = self.shadow_mem_code.address_to_line
				# self.de_code.lines = self.shadow_mem_code.lines
				if self.app.agent.algo == 'classic':
					self.ht = self.updates
					self.app.agent.upd_ticks[self.pipeline_num] += (100 + randint(0,100))
				elif self.app.agent.algo == 'incr':
					for chunk in self.updates['data']:
						if self.updates['type'] == 'del':
							for key in chunk:
								self.ht.pop(key)
						else:
							self.ht.update(chunk)
						self.app.agent.upd_ticks[self.pipeline_num] += (100 + randint(0,100))
						# self.updates['data'].pop(0)
				self.metadata_out = self.load_metadata()
				self.packet_header_address = self.metadata_out.header_start
				self.header_out = self.load_packet_header(self.metadata_out.header_size)
				self.processing_header = False
				# self.app.agent.upd_ticks[self.pipeline_num] += (100 + randint(0,100))

				if self.app.out:
					print(f"\n{self.pipeline_num} pipeline = {self.app.agent.upd_ticks[self.pipeline_num]} ticks\n")
			# header processing
			if not self.metadata.reserved1 or not self.context.tick():
				# processing ended - put header to output
				if (self.header_out != None):
					raise RuntimeError("Packet header stalled on the output of DE", self.de_num, "in pipeline", self.pipeline_num)
				self.metadata_out = self.load_metadata()
				self.packet_header_address = self.metadata_out.header_start
				self.header_out = self.load_packet_header(self.metadata_out.header_size)
				# print statistics
				portmask_fmt = "{portmask:0"+str(self.ether_ports_cnt)+"b}"
				portmask_text = "Output portmask: " + portmask_fmt.format(portmask=self.metadata_out.port_map)[-self.ether_ports_cnt:]
				if self.metadata_out.get_control_port():
					portmask_text += " CTRL"
				if self.metadata_out.get_reprocess():
					portmask_text += " REPROC"
				dynamic_power = self.context.dynamic_power
				self.total_dynamic_power += dynamic_power
				self.total_ticks += self.context.ticks
				if self.app.out:
					self.logger.info("################################################################################################")
					self.logger.info(portmask_text)
					self.logger.info("Ticks spent in pipeline on packet: {ticks}".format(ticks=self.context.ticks))
					self.logger.info("Power spent in pipeline on packet: {power} pJ".format(power=int(dynamic_power*1000)))
					self.logger.info("################################################################################################")
				# self.pipeline.commit_packet_statistics(power, self.context.ticks)
				# recreate execution context
				self.processing_header = False
				self.context = DEExecutorContext(self)
			return True
		else:
			# try to get new header
			return self.fetch_packet_header()
	
	
	# Get packet header from previous element of pipeline
	def fetch_packet_header(self):
		result = False
		header_in, self.metadata = self.prev_pipeline_element.get_header_out()
		if (header_in != None):
			result = True
			# Set header parameters from metadata
			self.packet_header_address = self.metadata.header_start
			self.packet_header_start = self.metadata.header_start
			# Store header & metadata in mem
			self.store_packet_header(header_in)
			self.store_metadata(self.metadata)
			self.processing_header = True  
			
		return result
				
	
	# Give processed packet header to the next element in pipeline
	def get_header_out(self):
		header_out = self.header_out
		metadata_out = self.metadata_out
		self.header_out = None
		self.metadata_out = None
		return header_out,metadata_out

	 
	def get_statistics(self):
		power = self.total_dynamic_power
		ticks = self.total_ticks
		self.total_dynamic_power = 0
		self.total_ticks = 0
		return power,ticks

	def store_bytes_to_mem(self, data, addr, log=False):
		for offset in range(0, len(data), self.register_size):
			buffer = data[offset: offset + self.register_size]
			tail = len(buffer) % self.register_size
			if tail:
				buffer += bytes(self.register_size - tail)
			address = addr + offset
			if log:
				self.logger.info("	{address}: {value}".format(
					address=self.de_code.format_address(address),
					value=self.de_code.format_buffer(buffer),
				))
			self.memory.set_buffer(address, buffer)
			self.context.inc_power_memory()

	def load_bytes_from_mem(self, addr, size, log=False):
		buffers = []
		for offset in range(0, size, self.register_size):
			address = addr + offset
			buffer = self.memory.get_buffer(address)
			self.context.inc_power_memory()
			tail = len(buffer) % self.register_size
			if log:
				self.logger.info("	{address}: {value}".format(
					address=self.de_code.format_address(address),
					value=self.de_code.format_buffer(buffer),
				))
			if tail:
				buffer = buffer[:self.register_size - tail]
			buffers.append(buffer)
		return b"".join(buffers)

	def store_packet_header(self, packet_header):
		if self.log_packet_headers_in:
			self.logger.info("Packet header in:")
		self.store_bytes_to_mem(packet_header, self.packet_header_address, self.log_packet_headers_in)

	def store_metadata(self, metadata):
		if self.log_metadata:
			self.logger.info("Metadata in:")
		self.store_bytes_to_mem(metadata.get_bytes(), self.metadata_address, self.log_metadata)

	def load_packet_header(self, size):
		if self.log_packet_headers_out:
			self.logger.info("Packet header out:")
		return self.load_bytes_from_mem(self.packet_header_address, size, self.log_packet_headers_out)

	def load_metadata(self):
		if self.log_metadata:
			self.logger.info("Metadata out:")
		return Metadata.from_bytes(self.app, self.load_bytes_from_mem(self.metadata_address, self.metadata_size, self.log_metadata))
		
