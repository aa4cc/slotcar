
#define S_FUNCTION_NAME udt_sf_sub
#define S_FUNCTION_LEVEL 2

#define HOST_IP_P 0
#define HOST_PORT_P 1
#define DATA_WIDTH_P 2
#define SAMPLE_TIME_P 3
#define NUM_PRMS 4

#ifndef WIN32
#include <arpa/inet.h>
#include <netdb.h>
#else
#include <WinSock2.h>
#include <ws2tcpip.h>
#include <wspiapi.h>
#endif
#include <udt.h>
#include "simstruc.h"

static bool isPositiveRealDoubleParam(const mxArray *p)
{
    bool isValid =
        (mxIsDouble(p) && mxGetNumberOfElements(p) == 1 && !mxIsComplex(p));

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
    if (!mxIsChar(ssGetSFcnParam(S, HOST_IP_P)))
    {
        ssSetErrorStatus(S, "Host URL parameter must be a char array.");
        return;
    }

    if (!mxIsChar(ssGetSFcnParam(S, HOST_PORT_P)))
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
        ssSetErrorStatus(
            S, "Step size parameter must be a positive double real scalar.");
        return;
    }

    return;
}
#endif /* MDL_CHECK_PARAMETERS */

static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S, NUM_PRMS); /* Number of expected parameters */
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S))
        return;

    ssSetSFcnParamTunable(S, HOST_IP_P, false);
    ssSetSFcnParamTunable(S, HOST_PORT_P, false);
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
    ssSetNumPWork(S, 2);

    /* Specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);

    ssSetOptions(S, SS_OPTION_WORKS_WITH_CODE_REUSE |
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
    char address[MAXCHARS], port[MAXCHARS];
    UDTSOCKET *sock;
    const mxArray *address_p, *port_p;
    struct addrinfo hints, *peer;

    UDT::startup();

    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_flags = AI_PASSIVE;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_DGRAM;

    // read function parameters
    address_p = ssGetSFcnParam(S, HOST_IP_P);
    port_p = ssGetSFcnParam(S, HOST_PORT_P);
    mxGetString(address_p, address, MAXCHARS);
    mxGetString(port_p, port, MAXCHARS);

    if (0 != getaddrinfo(address, port, &hints, &peer))
    {
        ssSetErrorStatus(S, "Incorrect server/peer address.\n");
        return;
    }

    sock = new UDTSOCKET(
        UDT::socket(hints.ai_family, hints.ai_socktype, hints.ai_protocol));

    // socket options
    bool block = false, reuse = false;
    if (UDT::ERROR ==
            UDT::setsockopt(*sock, 0, UDT_RCVSYN, &block, sizeof(bool)) ||
        UDT::ERROR ==
            UDT::setsockopt(*sock, 0, UDT_SNDSYN, &block, sizeof(bool)) ||
        UDT::ERROR ==
            UDT::setsockopt(*sock, 0, UDT_REUSEADDR, &reuse, sizeof(bool)))
    {
        ssSetErrorStatus(S, "Unable to set socket options.\n");
        UDT::close(*sock);
        return;
    }

    // try connect to the server, implict bind
    UDT::connect(*sock, peer->ai_addr, peer->ai_addrlen);

    ssSetPWorkValue(S, 0, (void *)sock);
    ssSetPWorkValue(S, 1, (void *)peer);
}
#endif // MDL_SETUP_RUNTIME_RESOURCES

#define udtSocket ((UDTSOCKET *)(ssGetPWorkValue(S, 0)))
#define udtPeer ((addrinfo *)(ssGetPWorkValue(S, 1)))

static void mdlOutputs(SimStruct *S, int_T tid)
{
    void *uptr = (void *)(ssGetOutputPortRealSignal(S, 0));
    size_t usize = sizeof(double) * ssGetOutputPortWidth(S, 0);
    while (UDT::ERROR != UDT::recvmsg(*udtSocket, (char *)uptr, usize));
    if (CUDTException::EASYNCRCV != UDT::getlasterror_code())
    {
        UDT::connect(*udtSocket, udtPeer->ai_addr, udtPeer->ai_addrlen);
    }
}
#define MDL_CLEANUP_RUNTIME_RESOURCES
#if defined(MDL_CLEANUP_RUNTIME_RESOURCES)
static void mdlCleanupRuntimeResources(SimStruct *S)
{
    freeaddrinfo(udtPeer);

        UDT::cleanup();
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
