#include "vcnl4000.h"

uint16_t data = 0;
uint16_t offset = 0;

int i2c_setup()
{
       FILE* offsetFile = fopen("offset.txt", "r");
       if (offsetFile == NULL) {
           offset = 0;
       }
       else {
           fscanf(offsetFile, "%" PRIu16, &offset);
       }
       
       rc_i2c_init(VCNL_BUS, VCNL_DEVICE_ADDR);
       rc_i2c_write_byte(VCNL_BUS, VCNL_CURRENT_ADDR, VCNL_CURRENT_VAL);
       rc_i2c_write_byte(VCNL_BUS, VCNL_FREQUENCY_ADDR, VCNL_FREQUENCY_VAL);
       rc_i2c_write_byte(VCNL_BUS, VCNL_TIMING_ADDR, VCNL_TIMING_VAL);
}

double i2c_measure()
{
       rc_i2c_write_byte(VCNL_BUS, VCNL_COMMAND_ADDR, VCNL_MEASURE_VAL);
       rc_i2c_read_word(VCNL_BUS, VCNL_RESULT_ADDR, &data);
       return data - offset;
}

int i2c_cleanup()
{
       rc_i2c_close(VCNL_BUS);
}