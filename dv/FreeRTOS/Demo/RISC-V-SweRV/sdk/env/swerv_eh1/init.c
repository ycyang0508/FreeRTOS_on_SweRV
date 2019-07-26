#include <stdint.h>
#include <stdio.h>
#include <unistd.h>

#include "platform.h"
#include "encoding.h"

extern int main(int argc, char** argv);
extern void trap_entry();
extern void freertos_risc_v_trap_handler();
extern void doInitPIC(void);

static unsigned long mtime_lo(void)
{
  return 0;
}

#ifdef __riscv32

static uint32_t mtime_hi(void)
{
  return 0;
}

uint64_t get_timer_value()
{
  while (1) {
    uint32_t hi = mtime_hi();
    uint32_t lo = mtime_lo();
    if (hi == mtime_hi())
      return ((uint64_t)hi << 32) | lo;
  }
}

#else /* __riscv32 */

uint64_t get_timer_value()
{
  return mtime_lo();
}

#endif

unsigned long get_timer_freq()
{
  return 10000;
}

static unsigned long __attribute__((noinline)) measure_cpu_freq(size_t n)
{
    return 10000000;
}

unsigned long get_cpu_freq()
{
  static uint32_t cpu_freq;

  if (!cpu_freq) {
    // warm up I$
    measure_cpu_freq(1);
    // measure for real
    cpu_freq = measure_cpu_freq(10);
  }

  return cpu_freq;
}

static void uart_init(size_t baud_rate)
{
}



# define MSTATUS_SD             MSTATUS32_SD
# define SSTATUS_SD             SSTATUS32_SD
#define MCAUSE32_INT         0x80000000
#define MCAUSE32_CAUSE       0x7FFFFFFF


# define MSTATUS_SD             MSTATUS32_SD
# define SSTATUS_SD             SSTATUS32_SD
# define RISCV_PGLEVEL_BITS     10
# define MCAUSE_INT             MCAUSE32_INT
# define MCAUSE_CAUSE           MCAUSE32_CAUSE



#ifdef USE_PIC
extern void handle_m_ext_interrupt();
#endif

#ifdef USE_M_TIME
extern void handle_m_time_interrupt(void);
#endif

uintptr_t handle_trap(uintptr_t mcause, uintptr_t epc)
{
  if (0){
#ifdef USE_PIC
    // External Machine-Level interrupt from PLIC
  } else if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE) == IRQ_M_EXT)) {
    handle_m_ext_interrupt();
#endif
#ifdef USE_M_TIME
    // External Machine-Level interrupt from PLIC
  } else if ((mcause & MCAUSE_INT) && ((mcause & MCAUSE_CAUSE) == IRQ_M_TIMER)){
    handle_m_time_interrupt();
#endif
  }
  else {
    write(1, "trap\n", 5);
    _exit(1 + mcause);
  }
  return epc;
}

void enable_timer()
{
    volatile uint8_t *pTimer = (uint8_t *)0xD0590000;
    *pTimer = 0x1;
    //printf("enable_timer\n");
}

void disable_timer()
{
    volatile uint8_t *pTimer = (uint8_t *)0xD0590000;
    *pTimer = 0xFF;
    //printf("disable_timer\n");
}

void reset_timer()
{
    volatile uint8_t *pTimer = (uint8_t *)0xD0590000;
    *pTimer = 0x2;
}   


void init_timer_interrupt()
{
    printf("init timer_interrupt\n");
    // enable machine mode interrupt
    //write_csr(mstatus,8);

    // enable timber interrupt
    //write_csr(mie,128);
    enable_timer();
}
extern  int  _heap_end;
extern  int __stack_size;
extern  int  __freertos_irq_stack_top;

void _init()
{
  
  #ifndef NO_INIT
  uart_init(115200);

  doInitPIC();

  printf("core freq at %d Hz\n", (int)get_cpu_freq());
  //printf("heap end %x stack size %x stack begin %x\n", _heap_end,__stack_size,__freertos_irq_stack_top);
  printf("heap size %d\n",xPortGetFreeHeapSize());

  //write_csr(mtvec, &trap_entry);
  write_csr(mtvec, &freertos_risc_v_trap_handler);

  #endif
  
}

void _fini()
{
}
