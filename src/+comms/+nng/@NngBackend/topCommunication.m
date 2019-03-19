function topCommunication(obj, conf, directs)
% TOPCOMMUNICATION Replaces subsystems with  blocks of the communication
% library for the top level scheme running in Matlab.

    port = obj.Port;
    Ts = obj.SampleTime;
    nd = length(conf.Boards);

    for i = 1:nd
        
        ip = conf.Boards(i).Ipv4;
        model = strcat(conf.TopModel, '/', conf.Boards(i).ModelName);
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
        for j = 2: numel(toRemove)
            delete_block (toRemove{j})
        end

        % Replace inports of subsystem with send blocks
        for inportNum = 0:numel(in)-1
            isDirect = ~isempty(directs) && ...
                       any(([directs.target] == modelHandle) & ...
                           ([directs.targetPort] == inportNum));
%             isDirect = false;
%             for directNum = 1:numel(directs)
%                 if (directs(directNum).target == modelHandle) ...
%                 && (directs(directNum).targetPort == inportNum)
%                     isDirect = true;
%                 end
%             end

            if isDirect == false
                % Add block and set parameters
                bh = add_block('libnng/NNG Sender', ...
                               strcat(model, '/Send', string(inportNum)));
                set_param(bh, 'hosturl', ...
                          string(sprintf ('''tcp://:%u''',port)));
                set_param(bh, 'sampletime', num2str(Ts));
                
                % Connect block to outport
                tmp = extractAfter(in{inportNum}, strcat(model,'/'));
                %tmp = extractAfter(tmp, '/');
                add_line(model, ...
                         strcat(tmp, '/1'), ...
                         strcat('Send', string(inportNum), '/1'));
                     
                % Increment the port value for the next connection
                port = port + 1;
            end
        end

        % Replace outports of subsystem with receive blocks
        for outportNum = 1: numel(out)
            isOnly = ~isempty(directs) && ...
                     any(( [directs.source] == modelHandle ) & ...
                         ( [directs.sourcePort] == outportNum ) & ...
                         ( directs.onlyDirect ));
%             isOnly = 0; 
%             for directNum = 1: size(directs, 1)
%                 if (directs (directNum, 1) == modelHandle) && (directs (directNum, 3) == outportNum)
%                     isOnly = directs(directNum, 5);
%                 end
%             end

            if isOnly == 0
                % Add block and set parameters
                bh = add_block ('libnng/NNG Receiver', ...
                                strcat(model, '/Receive', string(outportNum)));
                set_param (bh, 'hosturl', ...
                           string(sprintf ('''tcp://%s:%u''', ip, port)));
                set_param (bh, 'sampletime', num2str(Ts));
                
                % Connect block to inport
                tmp = extractAfter (out{outportNum}, strcat(model,'/'));
                %tmp = extractAfter (tmp, '/');
                add_line (model, ...
                          strcat('Receive', string(outportNum), '/1' ), ...
                          strcat(tmp, '/1'));
                
                % Increment the port value for the next connection
                port = port + 1;
            end
        end
    end
end
