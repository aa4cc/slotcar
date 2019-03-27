classdef Backend < handle
    properties (SetAccess = immutable)
        SendBlock char
        RecvBlock char
    end
    
    methods (Abstract)
        createDistributionModels(conf)
    end
end

