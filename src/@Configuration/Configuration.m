classdef Configuration < handle
    %SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Folder char
        RootModel char
        CtrlModel char = 'control'
        MatlabIpv4 char
        
        Boards(1,:) BeagleBoard

        CommsBackend comms.interface.Backend = comms.nng.NngBackend
        
        DesktopExternalRT logical = false
        ParallelCompilation logical = false
    end
    
    methods
        gui(obj)
        distribute(obj)
        start(obj)
        stop(obj)  
        inspect(obj)
        [beaglebones, isRunnable] = connect(obj)
        targetHandles = getBoardTargetHandles(obj)
    end
end

