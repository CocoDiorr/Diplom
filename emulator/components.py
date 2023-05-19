EMULATOR_COMPONENTS = (
    ("agent", "OFAgent.Agent", "OFAgent", 1),
    ("pipeline", "pipeline.pipeline", "Pipeline", 24),
    ("packet_memory", "fifo.packetmem", "PacketMem", 1),
    ("de_instructions", "de.instructions", "DEInstructions", 1),
    ("de_code", "de.code", "DECode", 1)
)

PIPELINE_COMPONENTS = (
    ("in_fifo", "fifo.in", "InFIFO", 1),
    ("de", "de", "DE", 1),
    ("out_fifo", "fifo.out", "OutFIFO", 1),
)
