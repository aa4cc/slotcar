classdef UdpBackend < comms.interface.Backend
    %NNGBACKEND Summary of this class goes here
    %   Detailed explanation goes here
    properties
        SampleTime double = 1
        Port uint16 = 25500
    end
    methods
        function createDistributionModels(obj, conf)
            
        end
    end
    
    methods (Access = protected)

    end
end

