start AssemblyTestbench
file copy -force ../../../software/assembly_tests/assembly_tests.mif imem_blk_ram.mif
file copy -force ../../../software/assembly_tests/assembly_tests.mif dmem_blk_ram.mif
file copy -force ../../../software/assembly_tests/assembly_tests.mif bios_mem.mif
add wave AssemblyTestbench/*
add wave AssemblyTestbench/CPU/*
run 10000us

