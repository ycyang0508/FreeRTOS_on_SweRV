#include "defines.h"
#include "encoding.h"
#include "sifive/bits.h"


#define meivt    0xBC8
#define meipt    0xBC9
#define meicpct  0xBCB
#define meicidpl 0xBCB
#define meicurpl 0xBCC
#define meihap   0xFC8


.macro enable_ext_interrup gate_id
disable_machine_ext_int   // Disable interrupts (MIE[meip]=0) 
set_threshold 1   // Program global threshold 
init_gateway \gate_id, 1, 1  // Configure gateway id=\gate_id to edge-triggered/low 
clear_gateway \gate_id   // Clear gateway id=\gate_id
set_priority \gate_id, 7   // Set id=5 threshold at 7 
enable_interrupt \gate_id   // Enable id=\gate_id
enable_machine_ext_int   // Enable interrupts (MIE[meip]=1)
.endm

.macro disable_machine_ext_int     
	// Clear MIE[miep]
disable_machine_ext_int_\@:
    li a0, (1<<11)     
    csrrc zero, mie, a0 
.endm 


.macro enable_machine_ext_int
enable_machine_ext_int_\@:
    // Set MIE[miep]
    li a0, (1<<11)
    csrrs zero, mie, a0 
.endm 

.macro init_priorityorder priord
init_priorityorder_\@:
    li tp, (RV_PIC_BASE_ADDR + RV_PIC_MPICCFG_OFFSET)
    li t0, \priord 
    sw t0, 0(tp) 
.endm 

.macro init_nstthresholds threshold 
init_nstthresholds_\@: 
    li t0, \threshold 
    csrrw zero, meicidpl, t0
    csrrw zero, meicurpl, t0
.endm 

.macro set_threshold threshold 
set_threshold_\@: 
    li tp, (RV_PIC_BASE_ADDR + RV_PIC_MEIPT_OFFSET) 
    li t0, \threshold 
    sw t0, 0(tp) 
.endm 

.macro enable_interrupt id 
enable_interrupt_\@: 
    li tp, (RV_PIC_BASE_ADDR + RV_PIC_MEIE_OFFSET + (\id <<2)) 
    li t0, 1 
    sw t0, 0(tp) 
.endm

.macro set_priority id, priority 
set_priority_\@: 
    li tp, (RV_PIC_BASE_ADDR + RV_PIC_MEIPL_OFFSET + (\id <<2)) 
    li t0, \priority 
    sw t0, 0(tp) 
.endm 

.macro init_gateway id, polarity, type 
init_gateway_\@: 
    li tp, (RV_PIC_BASE_ADDR + RV_PIC_MEIGWCTRL_OFFSET + (\id <<2)) 
    li t0, ((\type<<1) | \polarity) 
    sw t0, 0(tp) 
.endm 


.macro clear_gateway id 
clear_gateway_\@: 
    li tp, (RV_PIC_BASE_ADDR + RV_PIC_MEIGWCLR_OFFSET + (\id <<2)) 
    sw zero, 0(tp) 
.endm 

.macro set_priority_threshold threshold
set_priority_threshold_\@:

    li t0, \threshold
    csrrw zero,meipt,t0

.endm

.macro set_base_addr addr
set_base_addr_\@:

1:  auipc   t0, %pcrel_hi(freertos_risc_v_trap_handler)       
    addi    t0, t0, %pcrel_lo(1b)       
    slli    t0, t0, 3
    csrrw   zero, meivt, t0

.endm


.macro initIntGateWay
initIntGateWay_\@:
    //step1 
    init_priorityorder 0

    //step3
    set_base_addr machine_trap_entry

    //step 5
    set_priority_threshold 0

    //step 6
    init_nstthresholds 0
.endm

.macro initIntGatewayCh id
initIntGatewayCh_\@:
    //step 2
    init_gateway \id, 0,0
    clear_gateway \id 
    
    //step 4
    set_priority \id, 15

    //step 7
    enable_interrupt \id

.endm


.macro saveReg
saveReg_\@:
  addi sp, sp, -32*REGBYTES

  STORE x1, 1*REGBYTES(sp)
  STORE x2, 2*REGBYTES(sp)
  STORE x3, 3*REGBYTES(sp)
  STORE x4, 4*REGBYTES(sp)
  STORE x5, 5*REGBYTES(sp)
  STORE x6, 6*REGBYTES(sp)
  STORE x7, 7*REGBYTES(sp)
  STORE x8, 8*REGBYTES(sp)
  STORE x9, 9*REGBYTES(sp)
  STORE x10, 10*REGBYTES(sp)
  STORE x11, 11*REGBYTES(sp)
  STORE x12, 12*REGBYTES(sp)
  STORE x13, 13*REGBYTES(sp)
  STORE x14, 14*REGBYTES(sp)
  STORE x15, 15*REGBYTES(sp)
  STORE x16, 16*REGBYTES(sp)
  STORE x17, 17*REGBYTES(sp)
  STORE x18, 18*REGBYTES(sp)
  STORE x19, 19*REGBYTES(sp)
  STORE x20, 20*REGBYTES(sp)
  STORE x21, 21*REGBYTES(sp)
  STORE x22, 22*REGBYTES(sp)
  STORE x23, 23*REGBYTES(sp)
  STORE x24, 24*REGBYTES(sp)
  STORE x25, 25*REGBYTES(sp)
  STORE x26, 26*REGBYTES(sp)
  STORE x27, 27*REGBYTES(sp)
  STORE x28, 28*REGBYTES(sp)
  STORE x29, 29*REGBYTES(sp)
  STORE x30, 30*REGBYTES(sp)
  STORE x31, 31*REGBYTES(sp)

.endm

.macro restoreReg
restoreReg_\@:
  LOAD x1, 1*REGBYTES(sp)
  LOAD x2, 2*REGBYTES(sp)
  LOAD x3, 3*REGBYTES(sp)
  LOAD x4, 4*REGBYTES(sp)
  LOAD x5, 5*REGBYTES(sp)
  LOAD x6, 6*REGBYTES(sp)
  LOAD x7, 7*REGBYTES(sp)
  LOAD x8, 8*REGBYTES(sp)
  LOAD x9, 9*REGBYTES(sp)
  LOAD x10, 10*REGBYTES(sp)
  LOAD x11, 11*REGBYTES(sp)
  LOAD x12, 12*REGBYTES(sp)
  LOAD x13, 13*REGBYTES(sp)
  LOAD x14, 14*REGBYTES(sp)
  LOAD x15, 15*REGBYTES(sp)
  LOAD x16, 16*REGBYTES(sp)
  LOAD x17, 17*REGBYTES(sp)
  LOAD x18, 18*REGBYTES(sp)
  LOAD x19, 19*REGBYTES(sp)
  LOAD x20, 20*REGBYTES(sp)
  LOAD x21, 21*REGBYTES(sp)
  LOAD x22, 22*REGBYTES(sp)
  LOAD x23, 23*REGBYTES(sp)
  LOAD x24, 24*REGBYTES(sp)
  LOAD x25, 25*REGBYTES(sp)
  LOAD x26, 26*REGBYTES(sp)
  LOAD x27, 27*REGBYTES(sp)
  LOAD x28, 28*REGBYTES(sp)
  LOAD x29, 29*REGBYTES(sp)
  LOAD x30, 30*REGBYTES(sp)
  LOAD x31, 31*REGBYTES(sp)

  addi sp, sp, 32*REGBYTES

    
.endm


.macro initPIC
initPIC_:\@:

    disable_machine_ext_int

    initIntGateWay
    initIntGatewayCh 1

    enable_machine_ext_int
    
.endm

