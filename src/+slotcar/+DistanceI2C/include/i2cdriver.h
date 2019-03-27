#ifndef I2CDRIVER_H
#define I2CDRIVER_H

#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"

#include "rtwtypes.h"


#include <stdio.h>
#include <stdlib.h>
#include <errno.h>



#include <linux/i2c-dev.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>


#ifdef __cplusplus
extern "C" {
#endif

int i2c_setup(uint8_t current);
int open_file();
int set_current(uint8_t current);
int i2c_measure();
    
    
    
    
    
    
    
#ifdef __cplusplus
}
#endif

#endif