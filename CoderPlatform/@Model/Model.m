classdef Model
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name
        Ipv4
        External = false
    end
    
    methods
        function obj = Model(name,Ipv4)
            obj.Name = name;
            obj.Ipv4 = Ipv4;
        end
    end
end

