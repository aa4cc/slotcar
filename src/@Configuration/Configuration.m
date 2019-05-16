classdef Configuration < handle
    %CONFIGURATION Project root class which holds information on the
    %platform hardware setup and distributed code generation choices.
    
    properties
        % Home folder of the configuration, distribution folder is created
        % here and root model is found here or on path.
        Folder char
        % Name of the root model, from this the distribution files are
        % created.
        RootModel char
        % Name of the created distribution model for Matlab.
        CtrlModel char = 'control'
        % IP address of the computer running Matlab.
        MatlabIpv4 char
        
        % Array of defined BeagleBone devices that are part of the
        % configuration.
        Boards(1,:) BeagleBoard

        % Communication backend used to replace the ports between models.
        CommsBackend comms.interface.Backend = comms.nng.NngBackend
        
        % Unused logical value describing if the control model is run in 
        % external mode inside the Matlab RT kernel (Simulink Desktop RT).
        DesktopExternalRT logical = false
        
        % Logical value describing if the custom compilation procedure
        % should be used to compile on the boards in parallel.
        ParallelCompilation logical = false
        
        % Logical value describing if all scopes from the control model and
        % from external board models should be open. Selectively one can
        % set "open at simulation start" in the scope.
        OpenScopes logical = false
    end
    
    methods
        distribute(obj)
        start(obj)
        stop(obj)  
        inspect(obj)
        [beaglebones, isRunnable] = connect(obj)
        targetHandles = getBoardTargetHandles(obj)
    end
end

