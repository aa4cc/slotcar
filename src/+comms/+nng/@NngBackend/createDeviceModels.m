function createDeviceModels(obj, conf, directs, target_handles)
% CREATEDEVICEMODELS Creates a model for each specified subsystem to be
% loaded on a board.

    port = obj.Port;
    portDirect = obj.Port + 200;
    Ts = obj.SampleTime;

    for i =1:length(conf.Boards)
        tic ();
        boardModel = conf.Boards(i).ModelName;
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
        for ii = 1:numel(in)
            isDirect = false;
            portOffset = 0;
            for iii = 1: size(directs, 1)
                if (directs (iii, 2) == modelHandle) ...
                && (directs (iii, 4) == ii)
                    isDirect = true;
                    if iii > portOffset
                        portOffset = iii;
                    end
                end
            end
            if isDirect == true
                set_param (in{ii}, 'portnum', ...
                    string(portDirect + portOffset));
            else
                set_param (in{ii}, 'portnum', ...
                    string(port));
                port = port + 1;
            end
            %set_param (in{ii}, 'signalDatatype', inportTypes{i}{ii});
            %set_param (in{ii}, 'dims', num2str(inportDimensions{i}(ii)));
            set_param (in{ii}, 'sampletime', string(obj.CommSampleTime));
        end

        % Set params of replaced outports
        for ii = 1:numel (out)
            count = 0;
            ips = [];
            isDirect = false;
            isOnly = 0;
            portOffset = [];
            for iii = 1: size(directs, 1)
                if (directs (iii, 1) == modelHandle) ...
                && (directs (iii, 3) == ii)
                    isDirect = true;
                    isOnly = directs(iii, 5);
                    for iiii = 1:length(target_handles)
                        if target_handles(iiii) == directs (iii, 2)
                            portOffset(end + 1) = iii; %#ok
                        end
                    end
                    count = count + 1;
                    name = get_param (directs (iii, 2), 'Name');

                    for iiii = 1: length(conf.Boards)
                        if (conf.Boards(iiii).ModelName == name)
                            ips(end  + 1) = iiii; %#ok

                        end
                    end

                end
            end

            if isDirect == true
                for j = 1:count
                    pc = get_param (out{ii}, 'PortConnectivity');
                    name = get_param (pc.SrcBlock, 'Name');
                    bh = add_block('comms_lib/Publishing', ...
                        strcat(boardModel, ...
                               '/SendDirect_', ...
                               string(ii), ...
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
                        strcat(name, '/1'), ...
                        strcat('SendDirect_', string(ii), '_', string(j), ...
                        '/1'));
                end
            end

            if isOnly == 0
                set_param (out{ii}, 'hosturl', ...
                    string(sprintf ('''tcp://:%u''',port)));
                set_param(out{ii}, 'sampletime', ...
                        num2str(Ts));
                port = port + 1;
            else
               delete_block (out{ii}); 
            end
        end
        save_system(sys);
    end
end