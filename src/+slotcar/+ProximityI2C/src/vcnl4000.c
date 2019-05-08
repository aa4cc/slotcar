#include "vcnl4000.h"

uint16_t data = 0;
uint16_t  offset = UINT16_MAX;
rc_filter_t filter;

int i2c_setup(int bus, double dt, double tc)
{
       rc_filter_first_order_lowpass(&filter, dt, tc);
       rc_i2c_init(bus, VCNL_DEVICE_ADDR);
       rc_i2c_write_byte(bus, VCNL_CURRENT_ADDR, VCNL_CURRENT_VAL);
       rc_i2c_write_byte(bus, 0x89, 0x00);
}

double i2c_measure(int bus)
{
       rc_i2c_write_byte(bus, VCNL_COMMAND_ADDR, VCNL_MEASURE_VAL);
       rc_i2c_read_word(bus, VCNL_RESULT_ADDR, &data);
       if (data < offset) offset = data;
       return rc_filter_march(&filter, data - offset);
}
int i2c_cleanup(int bus)
{
       rc_i2c_close(bus);
}