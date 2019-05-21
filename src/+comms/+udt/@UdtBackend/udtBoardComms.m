function udtBoardComms(obj, conf, directs, inportDims)
% CREATEDEVICEMODELS Creates a model for each specified subsystem to be
% loaded on a board.

    port = obj.Port;
    Ts = obj.SampleTime;
    load_system('libudt')
    
    for boardNum =1:length(conf.Boards)
        tic ();
        boardModel = conf.Boards(boardNum).ModelName;
        boardIpv4 = conf.Boards(boardNum).Ipv4;
        modelToReplace = strcat(conf.RootModel, '/', boardModel);
        modelHandle = getSimulinkBlockHandle(modelToReplace);
        
        % Open subsystem as new model
        sys = load_system(boardModel);
        %open_system(boardModel);

        %Copy configuration of root model
%         rootConfig = getActiveConfigSet(conf.RootModel);
%         config = attachConfigSetCopy(sys, rootConfig, true);
%         setActiveConfigSet(sys, config.name);

        %Replace I/O ports with communication library blocks
        in = replace_block(sys, 'Inport', 'libudt/UDT Receiver', ...
                           'noprompt');
        out = replace_block(sys, 'Outport', 'libudt/UDT Sender', ...
                           'noprompt');
                       
        % Set params of replaced inports
        for portNum = 1:numel(in)
            bh = in{portNum};
            % check if the connection goes to another board
            I = find(([directs.target] == modelHandle) & ...
                     ([directs.targetPort] == portNum), 1);
            % Connection goes to Matlab
            if isempty(I)
                set_param(bh, 'hostaddress', ...
                          string(sprintf('''%s''', conf.MatlabIpv4))); 
                set_param(bh, 'hostport', ...
                          string(sprintf('''%u''', port))); 
            % Connection goes to a board
            else
                set_param(bh, 'hostaddress', ...
                          string(sprintf('''%s''', directs(I).sourceIpv4))); 
                set_param(bh, 'hostport', ...
                          string(sprintf('''%u''', port))); 
            end
            port = port + 1;
            set_param(in{portNum}, 'sampletime', num2str(Ts));
            set_param(bh, 'datawidth', ...
                num2str(inportDims{boardNum}(portNum)));
        end
        
        % Set params of replaced outports
        for portNum = 1:numel(out)
            bh = out{portNum};
            set_param(bh, 'hostaddress', ...
                      string(sprintf('''%s''', boardIpv4))); 
            set_param(bh, 'hostport', ...
                      string(sprintf('''%u''', port))); 
            set_param(bh, 'sampletime', num2str(Ts));
            port = port + 1;
        end
        %Simulink.BlockDiagram.arrangeSystem(sys);
        close_system(sys, true);
        fprintf('@@@ Generated distribution model for %s\n', boardModel);
        toc();
    end
    close_system('libudt')
end