#include "motor.h"

int motor_init() {
    return rc_motor_init();
}

int motor_set(double duty){
    printf("setting duty %f \n", duty);
    fflush(stdout);
    int rv = rc_motor_set(1, duty);
    return rv;
}

int motor_cleanup() {
    return rc_motor_cleanup();
}