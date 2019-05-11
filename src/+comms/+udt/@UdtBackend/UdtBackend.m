classdef UdtBackend < comms.interface.Backend
    %NNGBACKEND Summary of this class goes here
    %   Detailed explanation goes here
    properties
        SampleTime double = 1
        Port uint16 = 25500
    end
    methods
        function createDistributionModels(obj, conf)
            import comms.common.getDirectConnections

            % Check for direct target to target connection
            directs = getDirectConnections(conf);

            % Replace subsystem content with comunication blocks in the 
            % control model
            udtControlComms(obj, conf, directs); 
            
            % Move subsystem content to separate models with matching
            % communication blocks
            udtBoardComms(obj, conf, directs);
        end
    end
    
    methods (Access = protected)
        udtBoardComms(obj, conf, directs)
        udtControlComms(obj, conf, directs)
    end
end

