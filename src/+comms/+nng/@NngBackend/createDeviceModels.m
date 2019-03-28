function createDeviceModels(obj, conf, directs, target_handles)
% CREATEDEVICEMODELS Creates a model for each specified subsystem to be
% loaded on a board.

    port = obj.Port;
    portDirect = obj.Port + 200;
    Ts = obj.SampleTime;

    for boardNum =1:length(conf.Boards)
        tic ();
        boardModel = conf.Boards(boardNum).ModelName;
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
            isDirect = false;
            portOffset = 0;
            for directNum = 1:numel(directs)
                if ~isempty(directs) && ...
                        (directs(directNum).target == modelHandle) && ...
                        (directs(directNum).targetPort == portNum)
                    isDirect = true;
                    if directNum > portOffset
                        portOffset = directNum;
                    end
                end
            end
            if isDirect == true
                set_param (in{portNum}, 'portnum', ...
                    string(portDirect + portOffset));
            else
                set_param (in{portNum}, 'portnum', ...
                    string(port));
                port = port + 1;
            end
            %set_param (in{ii}, 'signalDatatype', inportTypes{i}{ii});
            %set_param (in{ii}, 'dims', num2str(inportDimensions{i}(ii)));
            set_param (in{portNum}, 'sampletime', string(obj.CommSampleTime));
        end

        % Set params of replaced outports
        for portNum = 1:numel (out)
            count = 0;
            ips = [];
            isDirect = false;
            isOnly = 0;
            portOffset = [];
            for directNum = 1:numel(directs.source)
                if ~isempty(directs) && ...
                        (directs.source(directNum) == modelHandle) && ...
                        (directs.sourcePort(directNum) == portNum)

                    isDirect = true;
                    isOnly = directs(directNum).onlyDirect;
                    for handleNum = 1:length(target_handles)
                        if target_handles(handleNum) == directs(directNum).target
                            portOffset(end + 1) = directNum; %#ok
                        end
                    end
                    count = count + 1;
                    targetName = get_param(directs(directNum).target, 'Name');

                    for targetNum = 1:length(conf.Boards)
                        if (conf.Boards(targetNum).ModelName == targetName)
                            ips(end + 1) = targetNum; %#ok

                        end
                    end

                end
            end

            if isDirect == true
                for j = 1:count
                    pc = get_param (out{portNum}, 'PortConnectivity');
                    targetName = get_param (pc.SrcBlock, 'Name');
                    bh = add_block('comms_lib/Publishing', ...
                        strcat(boardModel, ...
                               '/SendDirect_', ...
                               string(portNum), ...
                               '_', ...
                               string(j)));
                    set_param(bh, 'hosturl', ...
                        string(sprintf('''tcp://%s:%u''', ...
                                       conf.Boards(ips(j)).Ipv4, ...
                                       portDirect + portOffset(j))));
                    set_param(bh, 'portnum', ...
                        string(portDirect + portOffset(j)));
                    set_param(bh, 'sampletime', ...
                        num2str(Ts));
                    add_line(sys, ...
                        strcat(targetName, '/1'), ...
                        strcat('SendDirect_', string(portNum), '_', string(j), ...
                        '/1'));
                end
            end

            if isOnly == 0
                set_param (out{portNum}, 'hosturl', ...
                    string(sprintf ('''tcp://:%u''',port)));
                set_param(out{portNum}, 'sampletime', ...
                        num2str(Ts));
                port = port + 1;
            else
               delete_block (out{portNum}); 
            end
        end
        save_system(sys);
    end
end