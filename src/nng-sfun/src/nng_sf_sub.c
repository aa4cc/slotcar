
#define S_FUNCTION_NAME nng_sf_sub
#define S_FUNCTION_LEVEL 2

#define HOST_URL_P 0
#define DATA_WIDTH_P 1
#define SAMPLE_TIME_P 2
#define NUM_PRMS 3

#include <nng/nng.h>
#include <nng/protocol/pubsub0/sub.h>
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
        ssSetErrorStatus(S, "Step size parameter must be a double real scalar.");
        return;
    }

    return;
}
#endif /* MDL_CHECK_PARAMETERS */

static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S, NUM_PRMS); /* Number of expected parameters */
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S))
    {
        /* Return if number of expected != number of actual parameters */
        return;
    }

    ssSetSFcnParamTunable(S, HOST_URL_P, false);
    ssSetSFcnParamTunable(S, DATA_WIDTH_P, false);
    ssSetSFcnParamTunable(S, SAMPLE_TIME_P, false);

    ssSetNumContStates(S, 0);
    ssSetNumDiscStates(S, 0);

    if (!ssSetNumInputPorts(S, 0))
        return;

    if (!ssSetNumOutputPorts(S, 1))
        return;

    double *width = (double *)(mxGetData(ssGetSFcnParam(S, DATA_WIDTH_P)));
    ssSetOutputPortWidth(S, 0, (int)(*width));
    ssSetOutputPortDataType(S, 0, SS_DOUBLE);
    ssSetOutputPortComplexSignal(S, 0, COMPLEX_NO);

    ssSetNumSampleTimes(S, 1);
    ssSetNumPWork(S, 1);

    /* Specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);

    ssSetOptions(S,
                 SS_OPTION_WORKS_WITH_CODE_REUSE |
                     SS_OPTION_EXCEPTION_FREE_CODE |
                     SS_OPTION_USE_TLC_WITH_ACCELERATOR);

    ssSetModelReferenceNormalModeSupport(S, MDL_START_AND_MDL_PROCESS_PARAMS_OK);
}

#define doubleParam(a) ((double *)(mxGetData(ssGetSFcnParam(S, a))))

static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, *doubleParam(SAMPLE_TIME_P));
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S);
}

#define MAXCHARS 80

#define MDL_SETUP_RUNTIME_RESOURCES
#if defined(MDL_SETUP_RUNTIME_RESOURCES)
static void mdlSetupRuntimeResources(SimStruct *S)
{
    nng_socket *sock = malloc(sizeof(nng_socket));
    const mxArray *url_param = ssGetSFcnParam(S, HOST_URL_P);
    size_t len = mxGetNumberOfElements(url_param) + 1;
    char url[MAXCHARS];
    mxGetString(url_param, url, MAXCHARS);
    int rv;

    if ((rv = nng_sub0_open(sock)) < 0)
    {
        ssSetErrorStatus(S, "Unable to open socket.");
        return;
    }

    nng_setopt(*sock, NNG_OPT_SUB_SUBSCRIBE, "", 0);

    if ((rv = nng_dial(*sock, url, NULL, NNG_FLAG_NONBLOCK)) != 0)
    {
        ssSetErrorStatus(S, "Unable to listen on host.");
        return;
    }
    ssSetPWorkValue(S, 0, (void *)sock);
}
#endif // MDL_SETUP_RUNTIME_RESOURCES

#define nngSocket() ((nng_socket *)(ssGetPWorkValue(S, 0)))

static void mdlOutputs(SimStruct *S, int_T tid)
{
    void *uptr = (void *)(ssGetOutputPortRealSignal(S, 0));
    nng_socket *sock = nngSocket();
    size_t usize = sizeof(double) * ssGetOutputPortWidth(S, 0);
    int rv;

    double buffer[50];

    if ((rv = nng_recv(*sock, uptr, &usize, NNG_FLAG_NONBLOCK)) != 0)
    {
        if (rv & (NNG_EAGAIN | NNG_ETIMEDOUT))
            return;
        else
            ssSetErrorStatus(S, "NNG Error receiving message.");
    }
}
#define MDL_CLEANUP_RUNTIME_RESOURCES
#if defined(MDL_CLEANUP_RUNTIME_RESOURCES)
static void mdlCleanupRuntimeResources(SimStruct *S)
{
    nng_close(*nngSocket());
}

#endif // MDL_CLEANUP_RUNTIME_RESOURCES

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
