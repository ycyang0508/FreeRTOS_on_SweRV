`ifndef TESTBENCHTOP
`define TESTBENCHTOP tbTop
`endif


logic waveOpened = 0;
task automatic dumpWave();

    if (waveOpened  == 'd0)
    begin
        $display("dumpWave");
        $shm_open("wave.shm",0,64'd100000000000,1,64'd100000000000);
        $shm_probe(`TESTBENCHTOP,"ASM");
        waveOpened = 1;
    end

endtask

task automatic closeWave();

    if (waveOpened)
    begin
        $display("closeWave");
        $shm_close;
        waveOpened = 0;
    end

endtask

