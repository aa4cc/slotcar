function directs = directConnections(obj, conf, targetHandles)
% DIRECTCONNECTIONS Searches which connections connect board subsystems
% directly.

    directs = struct('source',[],'target',[],'sourcePort',[],'targetPort',[], 'onlyDirect',[]);
    
    for i = 1:length(conf.Boards)
        % Select board's subsystem in top level model
        model = strcat(conf.TopModel, '/', conf.Boards(i).ModelName);
        modelHandle = getSimulinkBlockHandle(model);
        m = find_system(model);
        port = get_param(m{1}, 'PortConnectivity');

        % Iterate ports of the subsystem
        for j = 1:numel(port)
            if ~isempty(port(j).DstBlock)
                % Select other board handles which are directly connected
                % to the output and save them in directs struct
                [C,IA] = intersect(port(j).DstBlock, targetHandles);
                onlyDirect = numel(C) == numel(port(j).DstBlock);
                for k = 1:numel(C)
                    directs(end + 1).source = modelHandle;
                    directs(end).target = C(k);
                    directs(end).sourcePort = port(j).Type;
                    directs(end).targetPort = port(j).DstPort(IA(k));
                    directs(end).onlyDirect = onlyDirect;
                    directCount = directCount + 1;
                end
            end
        end
    end
end