function udtControlComms(obj, conf, directs, outportDims)
% TOPCOMMUNICATION Replaces subsystems with  blocks of the communication
% library for the top level scheme running in Matlab.

    port = obj.Port;
    Ts = obj.SampleTime;
    nd = length(conf.Boards);
    % open the control model, done visibly because arrangement requires it
    open_system(conf.CtrlModel);
    load_system('libudt')
    
    for boardNum = 1:nd
        % Work with board subsystem model
        ip = conf.Boards(boardNum).Ipv4;
        model = strcat(conf.CtrlModel, '/', conf.Boards(boardNum).ModelName);
        modelHandle = getSimulinkBlockHandle(model);
        
        % Delete lines inside the board subsystem in top level model
        lines = find_system(model,'FindAll','on','type','line');   
        for j = lines
            delete_line(j)
        end
        
        % Find all ports of the subsystem
        allblocks = find_system(model);
        in = find_system(model,'BlockType','Inport');
        out = find_system(model,'BlockType','Outport');

        % Remove all blocks except ports
        toRemove = setdiff(allblocks,in);
        toRemove = setdiff(toRemove,out);
        for j = 2:numel(toRemove)
            delete_block (toRemove{j})
        end

        % Replace inports of subsystem with send blocks
        for inportNum = 1:numel(in)
            isDirect = ~isempty(directs) && ...
                       any(([directs.target] == modelHandle) & ...
                           ([directs.targetPort] == inportNum));

            if ~isDirect
                % Add block and set parameters
                bh = add_block('libudt/UDT Sender', ...
                               strcat(model, '/Send', string(inportNum)));
                set_param(bh, 'hostaddress', ...
                    string(sprintf ('''%s''', conf.MatlabIpv4)));
                set_param(bh, 'hostport', ...
                          string(sprintf ('''%u''', port)));
                set_param(bh, 'sampletime', num2str(Ts));
                
                % Connect block to outport
                tmp = extractAfter(in{inportNum}, strcat(model,'/'));
                %tmp = extractAfter(tmp, '/');
                add_line(model, ...
                         strcat(tmp, '/1'), ...
                         strcat('Send', string(inportNum), '/1'));
            end
            % Increment the port value for the next connection
            port = port + 1;
        end

        % Replace outports of subsystem with receive blocks
        for outportNum = 1:numel(out)
            isDirect = ~isempty(directs) && ...
                        any(([directs.target] == modelHandle) & ...
                            ([directs.targetPort] == outportNum));
            if ~isDirect
                % Add block and set parameters
                bh = add_block ('libudt/UDT Receiver', ...
                                strcat(model, '/Receive', string(outportNum)));
                set_param(bh, 'hostaddress', ...
                    string(sprintf ('''%s''', ip)));
                set_param(bh, 'hostport', ...
                          string(sprintf ('''%u''', port)));
                set_param (bh, 'sampletime', num2str(Ts));
                set_param(bh, 'datawidth', ...
                    num2str(outportDims{boardNum}(outportNum)));
                % Connect block to inport
                tmp = extractAfter (out{outportNum}, strcat(model,'/'));
                %tmp = extractAfter (tmp, '/');
                add_line (model, ...
                          strcat('Receive', string(outportNum), '/1' ), ...
                          strcat(tmp, '/1'));
                
            end
            % Increment the port value for the next connection
            port = port + 1;
        end
        % Finally automatically arrange the blocks inside the subsystem
        open_system(model);
        Simulink.BlockDiagram.arrangeSystem(model);
    end
    % close and save the control model
    close_system(conf.CtrlModel, true);
    close_system('libudt')
end
