#include "imu.h"


rc_mpu_data_t data; //struct to hold new data
FILE *f;

int imu_setup() {
        rc_mpu_config_t conf = rc_mpu_default_config();
        conf.i2c_bus = 2;
        
        if(rc_mpu_initialize(&data, conf)){
            fprintf(stderr,"rc_mpu_initialize_failed\n");
            return -1;
        }
        f = fopen("file.txt", "w");
}
/*
int is_gyro_calibrated(){
  return rc_is_gyro_calibrated();
}

int is_accel_calibrated(){
  return rc_is_accel_calibrated();
}
      */


float return_gyro_x(){
      return data.gyro[0];
}                       
float return_gyro_y(){
      return data.gyro[1];
}       
float return_gyro_z(){
      return data.gyro[2];
}          

float return_accel_x(){
      return data.accel[0];
}
float return_accel_y(){
      /*fprintf(f, "y: %d   ", data.accel[1]);*/
      return data.accel[1];
}
double return_accel_z(){
      /*fprintf(f, "z: %d\n", data.accel[2]*MS2_TO_G);*/
	    return data.accel[2];
}


int imu_measure() {      
                           
        if(rc_mpu_read_accel(&data)<0){
            printf("read accel data failed\n");
            return -1;
        }
        if(rc_mpu_read_gyro(&data)<0){
            printf("read gyro data failed\n");
            return -2;
        }         

       return 0; 

}

int imu_terminate(){
    rc_mpu_power_off();
    return 0;
} 