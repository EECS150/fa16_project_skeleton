#include "ascii.h"
#include "uart.h"
#include "string.h"
#include "types.h"

#define AC97_FULL (*((volatile uint32_t*)0x80000040) & 0x01)
#define AC97_DATA (*((volatile uint32_t*)0x80000044))
#define AC97_VOLUME (*((volatile uint32_t*)0x80000048))
#define GPIO_FIFO_EMPTY (*((volatile uint32_t*)0x80000020) & 0x01)
#define GPIO_FIFO_DATA (*((volatile uint32_t*)0x80000024))
#define DIP_SWITCHES (*((volatile uint32_t*)0x80000028) & 0xFF)
#define LED_CONTROL (*((volatile uint32_t*)0x80000030))
#define TONE_GEN_OUTPUT_ENABLE (*((volatile uint32_t*)0x80000034))
#define TONE_GEN_TONE_INPUT (*((volatile uint32_t*)0x80000038))

// Low and high sample values of the square wave
#define HIGH_AMPLITUDE 0x20000
#define LOW_AMPLITUDE -0x20000

#define BUFFER_LEN 128

typedef void (*entry_t)(void);

int main(void) {
    TONE_GEN_OUTPUT_ENABLE = 1;
    int8_t buffer[BUFFER_LEN];
    uint32_t tone_period = 54 + 54;
    uint32_t counter = 0;

    for ( ; ; ) {
        // Set the volume of the AC97 headphone codec with the DIP switch setting
        AC97_VOLUME = DIP_SWITCHES & 0xF;

        // Adjust the tone_period if a rotary wheel spin or push is detected
        if (!GPIO_FIFO_EMPTY) {
            uint32_t button_state = GPIO_FIFO_DATA;
            if ((button_state & 0x1) && (button_state & 0x2)) { // Rotary wheel left spin
                counter = 0;
                tone_period += 2;
            }
            if (!(button_state & 0x1) && (button_state & 0x2)) { // Rotary wheel right spin
                counter = 0;
                tone_period -= 2;
            }
            if (button_state & 0x4) { // Rotary wheel push
                counter = 0;
                tone_period = 54 + 54;
            }
        }

        if (counter < (tone_period >> 1)) {
            while(AC97_FULL);
            AC97_DATA = HIGH_AMPLITUDE;
        }
        else if (counter >= (tone_period >> 1)) {
            while(AC97_FULL);
            AC97_DATA = LOW_AMPLITUDE;
        }
        counter++;
        if (counter >= tone_period) {
            counter = 0;
        }
        LED_CONTROL = tone_period;
    }

    return 0;
}
