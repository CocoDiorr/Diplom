from .event_handler import EventHandler


class Component(EventHandler):

    def __init__(self, app, name):
        self.os = app.os
        self.os_path = app.os_path
        self.sys = app.sys
        self.app = app
        self.name = name
        self.json = app.json
        self.logging = app.logging
        self.logger = self.logging.getLogger(name)
        self.static_power = 0
        self.chip_area = 0
        self.config = {}
        
    def fatal_error(self, message):
        self.logger.fatal(message)
        self.app.sys.exit(-1)

    # In mW
    def get_static_power(self):
        return self.static_power

    # In um^2
    def get_chip_area(self):
        return self.chip_area
