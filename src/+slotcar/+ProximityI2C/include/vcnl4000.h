#ifndef VCNL4000_H
#define VCNL4000_H

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <rc/i2c.h>
#include <rc/math/filter.h>

#define VCNL_DEVICE_ADDR 0x13
#define VCNL_COMMAND_ADDR 0x80
#define VCNL_MEASURE_VAL 0x08
#define VCNL_RESULT_ADDR 0x87
#define VCNL_CURRENT_ADDR 0x83
#define VCNL_CURRENT_VAL 20
#define VCNL_FREQUENCY_ADDR 0x89
#define VCNL_FREQUENCY_VAL 0
#define VCNL_TIMING_ADDR 0x8A
#define VCNL_TIMING_VAL 129
#define VCNL_BUS 1

#ifdef __cplusplus
extern "C" {
#endif
int i2c_setup();
double i2c_measure();
int i2c_cleanup(); 
#ifdef __cplusplus
}
#endif

#endif