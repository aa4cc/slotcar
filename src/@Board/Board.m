classdef Board < handle
    %BOARD Class representing a Beaglebone Blue development board.
    %   Set of properties used to describe a board for which a separate
    %   model is generated. 
    %
    %   ModelName is the name of the subsystem block in which the board is 
    %   implemented inside the design model. 
    %
    %   Ipv4 is the address which the board uses in a common network. 
    %
    %   Crucial is a boolean value indicating that the experiment should be 
    %   terminated when the board cannot be connected to. 
    %
    %   External determines the mode
    
    properties
        ModelName char
        Ipv4 char
        LoginUser char = 'debian'
        LoginPwd char = 'temppwd'
        Crucial logical = false
        External logical = false

    end
    
    methods
        function [b, ok] = connect(obj)
            try
                b = beagleboneblue(obj.Ipv4, obj.LoginUser, obj.LoginPwd);
                ok = true;
            catch
               fprintf("@@@ Can't connect to %s\n", obj.Ipv4); 
               b = beagleboneblue.empty;
               ok = ~obj.Crucial;
            end
        end
    end
    
end

