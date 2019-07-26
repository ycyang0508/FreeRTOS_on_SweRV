// See LICENSE for license details.

#ifndef _SWERV_EH1_PLATFORM_H
#define _SWERV_EH1_PLATFORM_H

// Some things missing from the official encoding.h

// Helper functions
#define _REG32(p, i) (*(volatile uint32_t *) ((p) + (i)))
#define _REG32P(p, i) ((volatile uint32_t *) ((p) + (i)))

// Misc

#include <stdint.h>

unsigned long get_cpu_freq(void);
unsigned long get_timer_freq(void);
uint64_t get_timer_value(void);

#endif /* _SWERV_EH1_PLATFORM_H */
