classdef NngBackend < comms.interface.Backend
    %NNGBACKEND Summary of this class goes here
    %   Detailed explanation goes here
    properties
        SampleTime double = 1
        Port uint16 = 25500
    end
    methods
        function createDistributionModels(obj, conf)
            import comms.common.getDirectConnections
            import comms.common.portDetails

            % Check for direct target to target connection
            directs = getDirectConnections(conf);
            
            % Check the port width of board subsystems when compiled
            [inportDims, outportDims] = portDetails(conf, conf.CtrlModel);
            
            % Replace subsystem content with comunication blocks in the 
            % control model
            nngControlComms(obj, conf, directs, outportDims); 
            
            % Move subsystem content to separate models with matching
            % communication blocks
            nngBoardComms(obj, conf, directs, inportDims);
        end
    end
    
    methods (Access = protected)
        nngBoardComms(obj, conf, directs, inportDims)
        nngControlComms(obj, conf, directs, outportDims)
    end
end

