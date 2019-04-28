
#define S_FUNCTION_NAME nng_sf_pub
#define S_FUNCTION_LEVEL 2

#define HOST_URL_P 0
#define DATA_WIDTH_P 1
#define SAMPLE_TIME_P 2
#define NUM_PRMS 3

#include <nng/nng.h>
#include <nng/protocol/pubsub0/pub.h>
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
    char url[MAXCHARS];
    int rv;

    if ((rv = nng_pub0_open(sock)) < 0)
    {
        ssSetErrorStatus(S, "Unable to open socket.");
        return;
    }

    mxGetString(url_param, url, MAXCHARS);

    if ((rv = nng_listen(*sock, url, NULL, 0)) < 0)
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
    double *uptr = (double *)(ssGetInputPortSignal(S, 0));
    size_t usize = sizeof(double) * ssGetInputPortWidth(S, 0);
    int rv;

    if ((rv = nng_send(*nngSocket(), uptr, usize, NNG_FLAG_NONBLOCK)) != 0)
    {
        if (rv & (NNG_EAGAIN | NNG_ETIMEDOUT))
            return;
        else
            ssSetErrorStatus(S, "NNG Error sending message.");
    }
}

#define MDL_CLEANUP_RUNTIME_RESOURCES
#if defined(MDL_CLEANUP_RUNTIME_RESOURCES)
static void mdlCleanupRuntimeResources(SimStruct *S)
{
    nng_close(*nngSocket());
}
#endif // MDL_CLEANUP_RUNTIME_RESOURCES

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
