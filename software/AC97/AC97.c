#include "ascii.h"
#include "uart.h"
#include "string.h"
#include "types.h"

#define AC97_FULL (*((volatile uint32_t*)0x80000040))
#define AC97_data (*((volatile uint32_t*)0x80000044))

#define BUFFER_LEN 128

typedef void (*entry_t)(void);

void set_period(int tone_period)
{
  int32_t counter = 0;
  int32_t ac_value = tone_period;
  int8_t buffer[BUFFER_LEN];

  for ( ; ; ) {
    
    if(counter >= 54) {
      counter = 0;
      ac_value = 0 - ac_value;
    }

    while(AC97_FULL);
    AC97_data = ac_value;
    counter++;

}

int main(void)
{
      
  set_period(250000);
  return 0;
}

