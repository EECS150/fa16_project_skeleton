start ac97_integration_testbench
file copy -force ../../../software/ac97_integration_tb/ac97_integration_tb.mif imem_blk_ram.mif
file copy -force ../../../software/ac97_integration_tb/ac97_integration_tb.mif dmem_blk_ram.mif
file copy -force ../../../software/ac97_integration_tb/ac97_integration_tb.mif bios_mem.mif
add wave ac97_integration_testbench/*
add wave ac97_integration_testbench/ac97_fifo/*
add wave ac97_integration_testbench/ac97_fifo/buff/*
add wave ac97_integration_testbench/audio_controller/*
add wave ac97_integration_testbench/codec/*
add wave ac97_integration_testbench/codec/CodecReady
add wave ac97_integration_testbench/codec/BitCount
add wave ac97_integration_testbench/codec/Slot1
add wave ac97_integration_testbench/codec/Slot2
add wave ac97_integration_testbench/codec/Slot3
add wave ac97_integration_testbench/codec/Slot4
add wave ac97_integration_testbench/codec/OutShift
add wave ac97_integration_testbench/codec/ControlRegs/*
run 6ms
