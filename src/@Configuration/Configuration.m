classdef Configuration < handle
    %SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Folder char
        RootModel char
        TopModel char = 'top'
        MatlabIpv4 char
        
        Boards(1,:) Board

        CommsBackend comms.interface.Backend = comms.nng.NngBackend
        
        Debug logical = false
        ParallelCompilation logical = false
    end
    
    methods
        distribute(obj)
        start(obj)
        stop(obj)  
        [beaglebones, ok] = openConnection(obj)
    end
end

