classdef Configuration < handle
    %SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Folder
        RootModel
        MatlabIpv4
        Models(1,:) Model
        Debug = false
        ParallelCompilation = false
        CommSampleTime = 0.1
        Port = 25500
    end
    
    methods
        distribute(obj)
        start(obj)
        stop(obj)
        add(obj,val)
        
    end
end

