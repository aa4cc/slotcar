classdef Configuration
    %SETTINGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Root
        Models(1,:) Model
        Debug = false
        ParallelCompilation = false
        CommSampleTime = 0.1
        Port = 25500
    end
    
    methods
        function obj = Configuration(root)
            obj.Root = root;
        end
        distribute(obj)
        start(obj)
        stop(obj)
        add(obj)
        
    end
end

