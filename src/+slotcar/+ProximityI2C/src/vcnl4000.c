#include "vcnl4000.h"

uint16_t data = 0;
uint16_t  offset = UINT16_MAX;
rc_filter_t filter;

int i2c_setup(double dt, double tc)
{
       rc_filter_first_order_lowpass(&filter, dt, tc);
       rc_i2c_init(VCNL_BUS, VCNL_DEVICE_ADDR);
       rc_i2c_write_byte(VCNL_BUS, VCNL_CURRENT_ADDR, VCNL_CURRENT_VAL);
}

double i2c_measure()
{
       rc_i2c_write_byte(VCNL_BUS, VCNL_COMMAND_ADDR, VCNL_MEASURE_VAL);
       rc_i2c_read_word(VCNL_BUS, VCNL_RESULT_ADDR, &data);
       if (data < offset) offset = data;
       return rc_filter_march(&filter, data-offset);
}

int i2c_cleanup()
{
       rc_i2c_close(VCNL_BUS);
}