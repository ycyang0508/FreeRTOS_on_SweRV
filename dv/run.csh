rm *.elf *.hex
pushd .
cd ./FreeRTOS/Demo/RISC-V-SweRV
make clean;make
popd 
cp ./FreeRTOS/Demo/RISC-V-SweRV/build/FreeRTOS-simple.elf .
riscv64-unknown-elf-objdump -t -S -D -h FreeRTOS-simple.elf > FreeRTOS-simple.dump

#whisper test.elf -i --consoleio 0xd0580000 -f logfile --abinames
riscv64-unknown-elf-objcopy -O verilog --set-start=0x0 FreeRTOS-simple.elf program.hex

xrun -sv -f stim.f
