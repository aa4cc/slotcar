classdef NngBackend < comms.interface.Backend
    %NNGBACKEND Summary of this class goes here
    %   Detailed explanation goes here
    properties
        SampleTime double = 1
        Port uint16 = 25500
    end
    methods
        function createDistributionModels(obj, conf)
            
            load_system(conf.TopModel)
            % Prepare handles for board blocks
            nd = length(conf.Boards);
            targetHandles = ones(1, nd);
            for i = 1:nd
                targetHandles(i) = getSimulinkBlockHandle( ...
                    strcat(conf.TopModel, '/', conf.Boards(i).ModelName));
            end

            % Check port dimensions and data type
            %[inDims, outDims, inTypes, outTypes] = portDetails(obj, top);

            % Check for direct target to target connection
            directs = directConnections(obj, conf, targetHandles);

            % Replace subsystem content with comunication blocks in the top
            % model
            topCommunication(obj, conf, directs); 

            % Move subsystem content to separate models with matching
            % communication blocks
            createDeviceModels(obj, conf, directs, targetHandles)
        end
    end
    
    methods (Access = protected)
        createDeviceModels(obj, conf, directs, target_handles)
        topCommunication(obj, conf, directs)
        directs = directConnections(obj, conf, targetHandles)
        [inportDimensions, ...
          outportDimensions, ...
          inportTypes, ...
          outportTypes] = portDetails(obj, conf, top)
    end
end

