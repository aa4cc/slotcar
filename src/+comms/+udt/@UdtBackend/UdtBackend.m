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
            load_system(conf.TopModel)

            % Check for direct target to target connection
            directs = conf.getDirectConnections;

            % Replace subsystem content with comunication blocks in the top
            % model
            topCommunication(obj, conf, directs); 
            save_system(conf.TopModel);
            
            % Move subsystem content to separate models with matching
            % communication blocks
            createDeviceModels(obj, conf, directs);
        end
    end
    
    methods (Access = protected)

    end
end

