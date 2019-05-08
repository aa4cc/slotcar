#ifndef VCNL4000_H
#define VCNL4000_H

#include <stdio.h>
#include <stdlib.h>
#include <rc/i2c.h>
#include <rc/math/filter.h>

#define VCNL_DEVICE_ADDR 0x13
#define VCNL_COMMAND_ADDR 0x80
#define VCNL_MEASURE_VAL 0x08
#define VCNL_RESULT_ADDR 0x87
#define VCNL_CURRENT_ADDR 0x83
#define VCNL_CURRENT_VAL 20

#ifdef __cplusplus
extern "C" {
#endif
int i2c_setup(int bus, double dt, double tc);
double i2c_measure(int bus);
int i2c_cleanup(int bus); 
#ifdef __cplusplus
}
#endif

#endif