#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include <getopt.h>
#include <rc/mpu.h>
#include <rc/time.h>




#ifdef __cplusplus
extern "C" {
#endif

int imu_setup();

int is_gyro_calibrated();
int is_accel_calibrated();

float return_gyro_x();             
float return_gyro_y();
float return_gyro_z();
float return_accel_x();
float return_accel_y();
float return_accel_x();


int i2c_measure(); 
      
#ifdef __cplusplus
}
#endif
 