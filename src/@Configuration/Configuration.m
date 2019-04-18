classdef Configuration < handle
    %SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Folder char
        RootModel char
        TopModel char = 'top'
        MatlabIpv4 char
        
        Boards(1,:) BeagleBoard

        CommsBackend comms.interface.Backend = comms.nng.NngBackend
        
        ParallelCompilation logical = false
    end
    
    methods
        distribute(obj)
        start(obj)
        stop(obj)  
        inspect(obj)
        [beaglebones, isRunnable] = openConnection(obj)
        directs = getDirectConnections(obj)
        targetHandles = getBoardTargetHandles(obj)
    end
end

