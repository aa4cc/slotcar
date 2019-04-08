function createDeviceModels(obj, conf, directs)
% CREATEDEVICEMODELS Creates a model for each specified subsystem to be
% loaded on a board.

    port = obj.Port;
    Ts = obj.SampleTime;
    
    for boardNum =1:length(conf.Boards)
        tic ();
        boardModel = conf.Boards(boardNum).ModelName;
        boardIpv4 = conf.Boards(boardNum).Ipv4;
        modelToReplace = strcat(conf.RootModel, '/', boardModel);
        modelHandle = getSimulinkBlockHandle(modelToReplace);
        
        % Open subsystem as new model
        if exist (boardModel, 'file') ~= 4
            sys = new_system(boardModel);
        else
            sys = load_system(boardModel);
            Simulink.BlockDiagram.deleteContents(sys);            
        end

        % Copy contents from the subsystem in the root model
        Simulink.SubSystem.copyContentsToBlockDiagram(modelToReplace, sys);

        %Copy configuration of root model
        rootConfig = getActiveConfigSet(conf.RootModel);
        config = attachConfigSetCopy(sys, rootConfig, true);
        setActiveConfigSet(sys, config.name);

        %Replace I/O ports with communication library blocks
        in = replace_block(sys, 'Inport', 'libnng/NNG Receiver', ...
                           'noprompt');
        out = replace_block(sys, 'Outport', 'libnng/NNG Sender', ...
                           'noprompt');
                       
        % Set params of replaced inports
        for portNum = 1:numel(in)
            bh = in{portNum};
            % check if the connection goes to another board
            I = find(([directs.target] == modelHandle) & ...
                     ([directs.targetPort] == portNum), 1);
            % Connection goes to Matlab
            if isempty(I)
                set_param(bh, 'hosturl', ...
                          string(sprintf('''tcp://%s:%u''', ...
                                         conf.MatlabIpv4, port)));                
            % Connection goes to a board
            else
                set_param(bh, 'hosturl', ...
                          string(sprintf ('''tcp://%s:%u''', ...
                                          directs(I).sourceIpv4, port)));
            end
            port = port + 1;
            set_param(in{portNum}, 'sampletime', num2str(Ts));
        end
        
        % Set params of replaced outports
        for portNum = 1:numel(out)
            set_param (out{portNum}, 'hosturl', ...
                string(sprintf ('''tcp://%s:%u''',boardIpv4, port)));
            set_param(out{portNum}, 'sampletime', num2str(Ts));
            port = port + 1;
        end

        
        save_system(sys);
        fprintf('@@@ Generated distribution model for %s\n', boardModel);
        toc();
    end
end