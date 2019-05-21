#ifndef VCNL4000_H
#define VCNL4000_H

#include <rc/motor.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

int motor_init();

int motor_set(double duty);

int motor_cleanup();
#ifdef __cplusplus
}
#endif

#endif