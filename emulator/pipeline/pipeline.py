import os
import os.path
import sys
import logging
import argparse
import json
from importlib import import_module
from emulator.app.event_handler import EventHandler
from emulator.components import PIPELINE_COMPONENTS
from emulator.app.config import ConfigWrapper
from emulator.app.component import Component


class Pipeline(Component):
    
    @classmethod
    def handle_args_register(cls, parser):
        for component_name, module_name, class_name, count in PIPELINE_COMPONENTS:
            module_ = import_module("emulator." + module_name)
            class_ = getattr(module_, class_name)
            class_.handle_args_register(parser)

    def handle_initialize(self, params):
        self.pipeline_num = params["instance_num"]

    def de_by_num(self, num):
        # return self.__components_by_name["de_" + format(num, "02d")]
        return self.__components_by_name["de"]
        
    def handle_config(self):
        self.__components = []
        self.__components_by_name = {}
        self.config = self.app.config
        self.ether_ports_cnt = int(self.config["ether_ports_cnt"])
        self.de_per_pipeline = int(self.config["pipeline"]["de_per_pipeline"])
        if (self.de_per_pipeline != 1):
            raise ValueError("Only one DE per pipeline is supported for now!")
        
        # Zero statistics
        self.total_de_ticks = 0
        self.total_de_power = 0
        self.max_de_power = 0
        self.memory_utilization = 0
        self.packets_processed = 0
        self.run_ticks = 0
        self.run_power = 0
        self.running = True
        
        comps = []
        for component_name, module_name, class_name, count in PIPELINE_COMPONENTS:
            module_ = import_module("emulator." + module_name)
            class_ = getattr(module_, class_name)
            comps.append((component_name, class_, count))
        
        comp_init_params = dict()
        comp_init_params["pipeline_num"] = self.pipeline_num
        comp_init_params["pipeline"] = self
        #self.__components_by_name["agent"] = self.app.__components_by_name["agent"]
        #self.__components_by_name["agent"] = None
        #self.app.__components_by_name["agent"] = 0
        for component_name, class_, count in comps:
             for i in range(count):
                component_inst_name = component_name 
                # if (component_name=="de") or (count != 1):   # ugly!..
                if (count != 1): 
                    component_inst_name += "_" + format(i, "02d")
                _component = class_(self.app, component_inst_name)
                comp_init_params["instance_num"] = i
                _component.handle_initialize(comp_init_params)
                self.__components.append(_component)
                self.__components_by_name[component_inst_name] = _component
            
        # self.__components_event("initialize", init_params)
        
        for name, comp in self.__components_by_name.items():
            comp.config = self.config.make_child(name)
            comp.handle_config()
            #comp.agent = self.__components_by_name["agent"]
            #comp.agent = None
            
        # walk the pipeline to set previous element references
        self.de_by_num(0).prev_pipeline_element = self.__components_by_name["in_fifo"]
        for i in range(1, self.de_per_pipeline):
            self.de_by_num(i).prev_pipeline_element = self.de_by_num(i-1)
        self.__components_by_name["out_fifo"].prev_pipeline_element = self.de_by_num(self.de_per_pipeline-1)
            
    def handle_args(self, args):
        self.__components_event("args", args)
            
    def handle_start(self):
        self.__components_event("start")
            
    def handle_stop(self):
        self.__components_event("stop")

    def __getattr__(self, name):
        try:
            return self.__components_by_name[name]
        except KeyError:
            raise AttributeError("attribute not found: " + name)
            
    def __components_event(self, name, *args, **kw):
        name = "handle_" + name
        for c in self.__components:
            getattr(c, name)(*args, **kw)

    def step(self):
        if self.running:
            self.running = False
            self.run_ticks += 1
            for c in self.__components:
                self.running |= c.tick()
                    
            if not self.running:
                for c in self.__components:
                    power,tick = c.get_statistics()
                    self.run_power += power
                self.packets_processed = self.__components_by_name["in_fifo"].packets_processed() #- self.packets_processed
                self.app.commit_statistics(self.packets_processed, self.run_power, self.run_ticks, self.memory_utilization)
        return self.running
        
    def commit_prog_statistics(self, memory_utilization):
        self.memory_utilization += memory_utilization
        
    def get_static_power(self):
        power = 0
        power_phy = 0
        for c in self.__components:
            if "fifo" in c.name:
                power_phy += c.get_static_power()
            else:
                power += c.get_static_power()
        return power_phy,power
        
    def get_chip_area(self):
        area = 0
        for c in self.__components:
            area += c.get_chip_area()
        return area
