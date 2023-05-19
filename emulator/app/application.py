import os
import os.path
import sys
import logging
import argparse
import json
from importlib import import_module
from .event_handler import EventHandler
from emulator.components import EMULATOR_COMPONENTS
from .config import ConfigWrapper


class Application(EventHandler):

    NAME = "Emulator"

    def __init__(self, args):
        self.os = os
        self.os_path = os.path
        self.sys = sys
        self.json = json
        self.logging = logging
        self.logger = logging.getLogger(self.NAME)
        self.__components = []
        self.__components_by_name = {}
        parser = argparse.ArgumentParser(
            prog=args[0], description=self.NAME)
        parser.add_argument(
            "--config", "-c", dest="config", type=str,
            help="Config file path", required=True, default=None
        )
        parser.add_argument(
            "--log-level", "-l", dest="log_level", type=str,
            help="Log level: DEBUG, INFO, WARNING, ERROR, FATAL, CRITICAL", required=False, default="INFO"
        )
        parser.add_argument(
            "--update-alg", "-ua", dest="algo", type=str,
            help="which algo to use for update", required=True
        )
        parser.add_argument(
            "--output_log", "-out", dest="out", action="store_true",
            default=False, help="output data in console", required=False
        )
        # parser.add_argument(
        #     "--data_file", "-df", dest="data", type=str,
        #     help="Output file for exp data storage", required=False
        # )
        
        # Zero statistics
        self.total_de_ticks = 0
        self.total_de_power = 0
        self.total_de_pj = 0
        self.de_memory_utilization = 0
        self.stat_commits = 0
        self.packets_processed = 0
        self.max_ticks_per_packet = 0
        
        # Load components topology from components.py & call handle_args_register class methods
        comps = []
        for component_name, module_name, class_name, count in EMULATOR_COMPONENTS:			
            module_ = import_module("emulator." + module_name)
            class_ = getattr(module_, class_name)
            class_.handle_args_register(parser)
            comps.append((component_name, class_, count))
        arguments = parser.parse_args(args[1:])
        self.out = arguments.out
        with open(arguments.config, "r") as f:
            self.config = ConfigWrapper(
                self.os_path.basename(arguments.config),
                json.load(f)
            )
        logging.basicConfig(
            format=self.config["log_format"],
            level=getattr(logging, arguments.log_level),
            stream=sys.stdout
        )
        
        # Load & check some config vals
        self.frequency = int(self.config["frequency"])
        self.ether_ports_cnt = int(self.config["ether_ports_cnt"])
        self.de_per_pipeline = int(self.config["pipeline"]["de_per_pipeline"])
        if (self.ether_ports_cnt < 2) or (self.ether_ports_cnt > 64):
                raise RuntimeError("Number of ports should be between 2 and 64!")
        
        # Create components objects & call initialize handlers
        comp_init_params = dict()
        for component_name, class_,count in comps: 					
            # check that we have 1 pipeline per ether port
            if (component_name == "pipeline") and (count != self.ether_ports_cnt):
                self.logger.warning("Number of pipelines is not equal to number of ports, assuming them both to be " +  str(self.ether_ports_cnt))
                count = self.ether_ports_cnt
                
            for i in range(count):
                component_inst_name = component_name 
                if count != 1:
                    component_inst_name += "_" + format(i, "02d")
                _component = class_(self, component_inst_name)
                comp_init_params["instance_num"] = i
                _component.handle_initialize(comp_init_params)
                self.__components.append(_component)
                self.__components_by_name[component_inst_name] = _component
                #if count != 1:
                #	self.__components_by_name["agent"].pipelines.append(_component)
        
        # Call config & args event handlers
        for name, comp in self.__components_by_name.items():
            comp.config = self.config.make_child(name)  # not needed???
            comp.handle_config()

        self.__components_event("args", arguments)
        for name, comp in self.__components_by_name.items():
            if name.startswith("pipeline"):
                self.__components_by_name["agent"].pipelines.append((name, comp))

        if self.out:
            print("number of pipes = ", len(self.__components_by_name["agent"].pipelines))

    def __getattr__(self, name):
        try:
            return self.__components_by_name[name]
        except KeyError:
            raise AttributeError("attribute not found: " + name)
            
    def pipeline_by_num(self, num):
        return self.__components_by_name["pipeline_" + format(num, "02d")]
        
    def commit_statistics(self, packets_processed, de_power, de_ticks, memory_utilization):
        if (packets_processed != 0):
            de_ticks_per_packet = de_ticks / packets_processed
        else:
            de_ticks_per_packet = 0
        self.packets_processed += packets_processed
        self.stat_commits += 1
        self.de_memory_utilization += memory_utilization
        self.total_de_pj += de_power
        if (de_ticks != 0):
            self.total_de_power += de_power / de_ticks
        if de_ticks > self.total_de_ticks:
            self.total_de_ticks = de_ticks
        if de_ticks_per_packet > self.max_ticks_per_packet:
            self.max_ticks_per_packet = de_ticks_per_packet
            
    def print_statistics(self):
        if self.max_ticks_per_packet != 0:
            # ticks_per_packet = self.total_de_ticks // self.packets_processed
            throughput = int(10**6 * self.frequency / self.max_ticks_per_packet)
        else:
            # ticks_per_packet = 1
            throughput = 0
        ticks_per_packet = int(self.max_ticks_per_packet)
        self.de_memory_utilization /= self.stat_commits * int(self.config["de"]["memory_size"])
        if self.total_de_ticks != 0:
            packet_mem_dynamic_power = self.packet_memory.get_dynamic_power()*self.frequency / self.total_de_ticks
        else:
            packet_mem_dynamic_power = 0
        self.total_de_power *= self.frequency
        
        phy_power,static_power = self.get_static_power()
        
        if self.out:
            print("********************************************************************************")
            print("Performance:")
            print("Total packets processed: {packets}".format(packets=self.packets_processed))
            print("Average pipeline ticks spent on packet: {ticks}".format(ticks=ticks_per_packet))
            print("DE memory utilization: {perc}%".format(perc=round(self.de_memory_utilization*100)))
            print("Throughput at {freq} MHz: {throughput} packets/s".format(freq=self.frequency, throughput=throughput))
            print("********************************************************************************")
            print("Energy consumption:")
            print("Total static power: {power} mW".format(power=static_power))
            print("Total PHY power: {power} mW".format(power=phy_power))
            print("Total dynamic power consumed in all pipelines: {power} pJ".format(power=int(self.total_de_pj*1000)))
            print("Total dynamic power consumed in packet body memory: {power} pJ".format(power=int(self.packet_memory.get_dynamic_power()*1000)))
            print("Average total power: {power} mW".format(power=int(phy_power + static_power + self.total_de_power + packet_mem_dynamic_power)))
            print("********************************************************************************")
            print("Chip area:")
            print("Packet body memory: {area} mm^2".format(area=int(self.packet_memory.get_chip_area() / 10**6)))
            print("Total: {area} mm^2".format(area=self.get_chip_area()))
            print("********************************************************************************")
    
    # in mW    
    def get_static_power(self):
        power = 0
        power_phy = 0
        for c in self.__components:
            if "pipeline" in c.name:
                c_power_phy,c_power = c.get_static_power()
                power += c_power
                power_phy += c_power_phy
            else:
                power += c.get_static_power()
        return int(power_phy),int(power)
        
    
    # in mm^2    
    def get_chip_area(self):
        area = 0
        for c in self.__components:
            area += c.get_chip_area()
        return int(area / 10**6)


    def run(self):
        self.logger.info("Begin")
        self.__components_event("start")
        # try:
        running = True
        
        self.__components_by_name["agent"].upload_upd()
        self.__components_by_name["agent"].compile_update_pck()
        while(running):
            running = False
            self.__components_by_name["agent"].tick()
            for i in range(self.ether_ports_cnt):
                running |= self.pipeline_by_num(i).step()
        # finally:
        self.__components_event("stop")
        self.logger.info("End")
        self.print_statistics()
        return 0

    def __components_event(self, name, *args, **kw):
        name = "handle_" + name
        getattr(self, name)(*args, **kw)
        for c in self.__components:
            getattr(c, name)(*args, **kw)
            
