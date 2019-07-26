/* See LICENSE of license details. */

#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>

#include "platform.h"
#include "stub.h"
#include "weak_under_alias.h"

#define SC_SIM_OUTPORT (0xd0580000)
#define SIM_OUTPORT ( *((volatile unsigned *)(0xd0580000)) )


int __wrap_puts(const char *s)
{
  while (*s != '\0') {
    volatile char *out_ptr = (volatile char*)SC_SIM_OUTPORT;
    *out_ptr = *s;

    if (*s == '\n') {
      *out_ptr = '\r';   
    }

    ++s;
  }

  return 0;
}
weak_under_alias(puts);
