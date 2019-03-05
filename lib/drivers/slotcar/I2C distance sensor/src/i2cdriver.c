#include "i2cdriver.h"



int file;

int i2c_setup(uint8_t current) {
    open_file();
    set_current(current);
}

int open_file() {

    int adapter_nr = 1; /* The number of adapter */
    int addr = 0x13; /* The I2C address of our proximity sensor */
    char filename[20];

    snprintf(filename, 19, "/dev/i2c-%d", adapter_nr);
    file = open(filename, O_RDWR);
    if (file < 0) {
        /* ERROR HANDLING; you can check errno to see what went wrong */
        exit(1);
    }

    if (ioctl(file, I2C_SLAVE, addr) < 0) {
        /* ERROR HANDLING; you can check errno to see what went wrong */
        exit(2);
    }
}

int set_current(uint8_t current) {
    __u8 reg = 0x83; /* Device register to access */
    __u16 res;
    
    /* Using SMBus commands */
    /* Command to set the current of IR LED */ 
    res = i2c_smbus_write_byte_data(file, reg, current);       
}

int i2c_measure() {
    __u8 reg_measure = 0x80;
    __u8 reg_result = 0x87; /* Device register to access */
    
    __u16 measure_data_value = 0x18;
    __u16 res;
      
         /* Using SMBus commands */
         /* Command to do the measurement of distance */ 
         res = i2c_smbus_write_byte_data(file, reg_measure, measure_data_value);
                
         /* Command to read the result*/
         res = i2c_smbus_read_word_data(file, reg_result);
         
         /*Changing lower and upper bits to compensate endianness*/
         res = (res << 8) | (res >> 8);
         
         if (res < 0) {
                /* ERROR HANDLING: i2c transaction failed */
         } else {
               
         }

       return res;    

     
}