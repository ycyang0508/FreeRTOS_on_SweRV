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


ssize_t __wrap_write(int fd, const void* ptr, size_t len)
{
  const uint8_t * current = (const uint8_t *)ptr;

  if (isatty(fd)) {
    volatile char *out_ptr = (volatile char*)SC_SIM_OUTPORT;
    for (size_t jj = 0; jj < len; jj++) {

     *out_ptr = current[jj];

      if (current[jj] == '\n') {
        *out_ptr  = '\r';
      }
    }
    return len;
  }

  return _stub(EBADF);
}
weak_under_alias(write);
