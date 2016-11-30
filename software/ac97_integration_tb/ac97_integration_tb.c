#define AC97_FULL (*((volatile int*)0x80000040) & 0x01)
#define AC97_DATA (*((volatile int*)0x80000044))
#define AC97_VOLUME (*((volatile int*)0x80000048))

// This program sends the PCM samples -50, ..., 50 to your AC97 sample FIFO
int main(void) {
    int i;
    for (i = -50; i <= 50; i++) {
        while(AC97_FULL);
        AC97_DATA = i;
    }

    // Once we are done, the program should just stop sending samples
    jump_here: i = 0;
    goto jump_here;
    return 0;
}
