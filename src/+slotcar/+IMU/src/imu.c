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

double return_gyro_x(){
      return data.gyro[0];
}                       
double return_gyro_y(){
      return data.gyro[1];
}       
double return_gyro_z(){
      return data.gyro[2];
}          

double return_accel_x(){
      return data.accel[0];
}
double return_accel_y(){
      return data.accel[1];
}
double return_accel_z(){
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