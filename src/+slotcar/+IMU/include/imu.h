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
int imu_terminate();
int imu_measure();

double return_gyro_x();             
double return_gyro_y();
double return_gyro_z();
double return_accel_x();
double return_accel_y();
double return_accel_z();
      
#ifdef __cplusplus
}
#endif
 