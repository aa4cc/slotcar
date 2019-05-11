
#define S_FUNCTION_NAME udt_pub
#define S_FUNCTION_LEVEL 2

#define HOST_IP_P 0
#define HOST_PORT_P 1
#define SAMPLE_TIME_P 2
#define NUM_PRMS 3

#ifndef WIN32
#include <arpa/inet.h>
#include <netdb.h>
#else
#include <WinSock2.h>
#include <ws2tcpip.h>
#include <wspiapi.h>
#endif
#include <udt.h>
#include <forward_list>
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

    bool isValid = isPositiveRealDoubleParam(ssGetSFcnParam(S, SAMPLE_TIME_P));
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

    ssSetSFcnParamTunable(S, HOST_IP_P, false);
    ssSetSFcnParamTunable(S, HOST_PORT_P, false);
    ssSetSFcnParamTunable(S, SAMPLE_TIME_P, false);

    ssSetNumContStates(S, 0);
    ssSetNumDiscStates(S, 0);

    if (!ssSetNumInputPorts(S, 1))
        return;
    ssSetInputPortWidth(S, 0, DYNAMICALLY_TYPED);
    ssSetInputPortDataType(S, 0, SS_DOUBLE);
    ssSetInputPortComplexSignal(S, 0, COMPLEX_NO);
    ssSetInputPortRequiredContiguous(S, 0, true);
    ssSetInputPortDirectFeedThrough(S, 0, 1);

    if (!ssSetNumOutputPorts(S, 0))
        return;

    ssSetNumSampleTimes(S, 1);
    ssSetNumPWork(S, 2);

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
#define BACKLOG_SIZE 32

#define MDL_SETUP_RUNTIME_RESOURCES
#if defined(MDL_SETUP_RUNTIME_RESOURCES)
static void mdlSetupRuntimeResources(SimStruct *S)
{
    char address[MAXCHARS], port[MAXCHARS];
    UDTSOCKET *sock;
    const mxArray *address_p, *port_p;
    struct addrinfo hints, *self;

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

    if (0 != getaddrinfo(NULL, port, &hints, &self) || self == NULL)
    {
        ssSetErrorStatus(S, "Incorrect or busy port.\n");
        UDT::close(*sock);
        return;
    }

    sock = new UDTSOCKET(UDT::socket(self->ai_family, self->ai_socktype, self->ai_protocol));

    // socket options
    bool block = false, reuse = false;
    if (UDT::ERROR == UDT::setsockopt(*sock, 0, UDT_SNDSYN, &block, sizeof(bool)) ||
        UDT::ERROR == UDT::setsockopt(*sock, 0, UDT_RCVSYN, &block, sizeof(bool)) ||
        UDT::ERROR == UDT::setsockopt(*sock, 0, UDT_REUSEADDR, &reuse, sizeof(bool)))
    {
        ssSetErrorStatus(S, "Unable to set socket options.\n");
        UDT::close(*sock);
        return;
    }
    if (UDT::ERROR == UDT::bind(*sock, self->ai_addr, self->ai_addrlen))
    {
        ssSetErrorStatus(S, UDT::getlasterror().getErrorMessage());
        return;
    }

    freeaddrinfo(self);

    UDT::listen(*sock, BACKLOG_SIZE);

    ssSetPWorkValue(S, 0, (void *)sock);
    ssSetPWorkValue(S, 1, (void *)new std::forward_list<UDTSOCKET>());
}
#endif // MDL_SETUP_RUNTIME_RESOURCES

#define udtSocket ((UDTSOCKET *)(ssGetPWorkValue(S, 0)))
#define udtClients ((std::forward_list<UDTSOCKET> *)(ssGetPWorkValue(S, 1)))

static void mdlOutputs(SimStruct *S, int_T tid)
{
    const real_T *uptr = ssGetInputPortRealSignal(S, 0);
    size_t usize = sizeof(real_T) * ssGetInputPortWidth(S, 0);
    auto clients = udtClients;
    UDTSOCKET sock = *udtSocket, accepting;

    while (UDT::INVALID_SOCK != (accepting = UDT::accept(sock, (sockaddr *)NULL, NULL)))
    {
        clients->push_front(accepting);
    }

    for (auto it = clients->begin(); it != clients->end();)
    {
        if (UDT::ERROR == UDT::sendmsg(*it, (char *)uptr, usize))
        {
            clients->remove(*(it++));
        }
        else
        {
            ++it;
        }
    }
}

#define MDL_CLEANUP_RUNTIME_RESOURCES
#if defined(MDL_CLEANUP_RUNTIME_RESOURCES)
static void mdlCleanupRuntimeResources(SimStruct *S)
{
    delete (udtClients);
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
