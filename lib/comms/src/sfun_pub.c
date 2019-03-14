
#define S_FUNCTION_NAME sfun_pub
#define S_FUNCTION_LEVEL 2

#define HOST_URL_P 0
#define DATA_WIDTH_P 1
#define SAMPLE_TIME_P 2
#define NUM_PRMS 3

#include <nng/nng.h>
#include <nng/protocol/pair0/pair.h>
#include "simstruc.h"

static bool isPositiveRealDoubleParam(const mxArray *p)
{
    bool isValid = (mxIsDouble(p) &&
                    mxGetNumberOfElements(p) == 1 &&
                    !mxIsComplex(p));

    if (isValid)
    {
        double *v = (double *)(mxGetData(p));
        if (*v < 0)
            isValid = false;
    }
    return isValid;
}

/*====================*
 * S-function methods *
 *====================*/

#define MDL_CHECK_PARAMETERS
#if defined(MDL_CHECK_PARAMETERS) && defined(MATLAB_MEX_FILE)
/* Function: mdlCheckParameters =============================================
 * Abstract:
 *    Validate our parameters to verify they are okay.
 */
static void mdlCheckParameters(SimStruct *S)
{
    if (!mxIsChar(ssGetSFcnParam(S, HOST_URL_P)))
    {
        ssSetErrorStatus(S, "Host URL parameter must be a char array.");
        return;
    }

    bool isValid = isPositiveRealDoubleParam(ssGetSFcnParam(S, DATA_WIDTH_P));
    if (!isValid)
    {
        ssSetErrorStatus(S, "Data width parameter must be a positive scalar.");
        return;
    }

    isValid = isPositiveRealDoubleParam(ssGetSFcnParam(S, SAMPLE_TIME_P));
    if (!isValid)
    {
        ssSetErrorStatus(S, "Step size parameter must be a positive double real scalar.");
        return;
    }

    return;
}
#endif /* MDL_CHECK_PARAMETERS */

/* Function: mdlInitializeSizes ===============================================
 * Abstract:
 *    The sizes information is used by Simulink to determine the S-function
 *    block's characteristics (number of inputs, outputs, states, etc.).
 */
static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S, NUM_PRMS);
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S))
    {
        return;
    }

    ssSetSFcnParamTunable(S, HOST_URL_P, false);
    ssSetSFcnParamTunable(S, DATA_WIDTH_P, false);
    ssSetSFcnParamTunable(S, SAMPLE_TIME_P, false);

    ssSetNumContStates(S, 0);
    ssSetNumDiscStates(S, 0);

    if (!ssSetNumInputPorts(S, 1))
        return;
    double *width = (double *)(mxGetData(ssGetSFcnParam(S, DATA_WIDTH_P)));
    ssSetInputPortWidth(S, 0, (int)(*width));
    ssSetInputPortDataType(S, 0, SS_DOUBLE);
    ssSetInputPortComplexSignal(S, 0, COMPLEX_NO);
    ssSetInputPortRequiredContiguous(S, 0, true);
    ssSetInputPortDirectFeedThrough(S, 0, 1);

    if (!ssSetNumOutputPorts(S, 0))
        return;

    ssSetNumSampleTimes(S, 1);
    ssSetNumPWork(S, 1);

    /* Specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);

    ssSetOptions(S, SS_OPTION_EXCEPTION_FREE_CODE);

    ssSetModelReferenceNormalModeSupport(S, MDL_START_AND_MDL_PROCESS_PARAMS_OK);
}

/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    This function is used to specify the sample time(s) for your
 *    S-function. You must register the same number of sample times as
 *    specified in ssSetNumSampleTimes.
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    double *stepSizeP = (double *)(mxGetData(ssGetSFcnParam(S, SAMPLE_TIME_P)));
    ssSetSampleTime(S, 0, *stepSizeP);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S);
}

#define MDL_SETUP_RUNTIME_RESOURCES /* Change to #undef to remove function */
#if defined(MDL_SETUP_RUNTIME_RESOURCES)
/* Function: mdlStart =======================================================
   * Abstract:
   *    This function is called once at start of model execution. If you
   *    have states that should be initialized once, this is the place
   *    to do it.
   */
static void mdlSetupRuntimeResources(SimStruct *S)
{
    nng_socket *sock = malloc(sizeof(nng_socket));
    const mxArray *url_param = ssGetSFcnParam(S, HOST_URL_P);
    size_t len = mxGetNumberOfElements(url_param) + 1;
    char url[len];
    int rv;

    if ((rv = nng_pair0_open(sock)) < 0)
    {
        ssSetErrorStatus(S, "Unable to open socket.");
        return;
    }

    mxGetString(url_param, url, len);

    if ((rv = nng_listen(*sock, url, NULL, 0)) < 0)
    {
        ssSetErrorStatus(S, "Unable to listen on host.");
        return;
    }
    ssSetPWorkValue(S, 0, (void *)sock);
}
#endif /*  MDL_START */

/* Function: mdlOutputs =======================================================
 * Abstract:
 *    In this function, you compute the outputs of your S-function
 *    block.
 */
static void mdlOutputs(SimStruct *S, int_T tid)
{
    double *u_ptr = (double *)(ssGetInputPortSignal(S, 0));
    nng_socket *sock = (nng_socket *)(ssGetPWorkValue(S, 0));
    size_t sizep = sizeof(double) * ssGetInputPortWidth(S, 0);
    int rv;

    if ((rv = nng_send(*sock, u_ptr, sizep, NNG_FLAG_NONBLOCK)) != 0)
    {
        if (rv & (NNG_EAGAIN | NNG_ETIMEDOUT))
            return;
        else
            ssSetErrorStatus(S, "NNG Error sending message.");
    }
}

#define MDL_CLEANUP_RUNTIME_RESOURCES
static void mdlCleanupRuntimeResources(SimStruct *S)
{
    nng_socket *sock = (nng_socket *)(ssGetPWorkValue(S, 0));
    nng_close(*sock);
    free(sock);
}

/* Function: mdlTerminate =====================================================
 * Abstract:
 *    In this function, you should perform any actions that are necessary
 *    at the termination of a simulation.  For example, if memory was
 *    allocated in mdlStart, this is the place to free it.
 */
static void mdlTerminate(SimStruct *S)
{
}

/*=============================*
 * Required S-function trailer *
 *=============================*/

#ifdef MATLAB_MEX_FILE /* Is this file being compiled as a MEX-file? */
#include "simulink.c"  /* MEX-file interface mechanism */
#else
#include "cg_sfun.h" /* Code generation registration function */
#endif
