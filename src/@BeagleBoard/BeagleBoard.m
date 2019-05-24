classdef BeagleBoard < handle
    %BEAGLEBOARD Class representing a Beaglebone Blue development board.
    %   Set of properties used to describe a board for which a separate
    %   model is generated. 
    
    properties
        % Name of the subsystem inside the root model and the name of the 
        % distribution model after creation
        ModelName char
        % IP address assigned to the board, best made static
        Ipv4 char
        % Username of the linux user in the beaglebone
        LoginUser char = 'debian'
        % Password of the linux user in the beaglebone
        LoginPwd char = 'temppwd'
        % Logical value describing if the experiment can continue without
        % the board present
        Crucial logical = true
        % Logical value describing if the model of the board is run in
        % external mode or not
        External logical = false

    end
    
    properties(Access = private)
        b beagleboneblue = beagleboneblue.empty
    end
    
    methods
        function connected = isConnected(obj)
            if isempty(obj.b)
                connected = false;
            else
                try
                    obj.b.system('echo connection test');
                    connected = true;
                catch
                    connected = false;
                end
            end 
        end
        
        function [b, ok] = reconnect(obj)
            if obj.isConnected
                b = obj.b;
                ok = true;
            else
                [b, ok] = obj.connect;
            end
        end
        
        function [b, ok] = connect(obj)
            try
                b = beagleboneblue(obj.Ipv4, obj.LoginUser, obj.LoginPwd);
                ok = true;
            catch ME
               b = beagleboneblue.empty;
               ok = ~obj.Crucial;
               fprintf('@@@ %s\n', ME.message);
            end
            obj.b = b;
        end
            
        function openShell(obj)
            if ~obj.isConnected
                board = obj.connect;
                if ~isempty(board)
                    board.openShell;
                end
            else
                obj.b.openShell;
            end
        end
    end
    
end

