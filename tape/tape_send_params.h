
// Marcel Timm, RhinoDevel, 2018nov16

#ifndef MT_TAPE_SEND_PARAMS
#define MT_TAPE_SEND_PARAMS

#include <stdint.h>

struct tape_send_params
{
    uint32_t gpio_pin_nr_read;
    uint32_t gpio_pin_nr_sense;
    uint32_t gpio_pin_nr_motor;

    struct tape_input* data;
};

#endif //MT_TAPE_SEND_PARAMS
