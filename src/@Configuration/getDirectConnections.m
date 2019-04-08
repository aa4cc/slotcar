function directs = getDirectConnections(obj)
% DIRECTCONNECTIONS Searches which connections connect board subsystems
% directly without crossing blocks in top system.

    % Load the reference model and preallocate the output struct
    load_system(obj.TopModel);
    out = find_system(obj.TopModel, 'BlockType', 'Outport');
    dim = numel(out);
    nd = length(obj.Boards);
    count = 0;
    directs = struct( ... 
        'source', zeros(1,dim), ... % handle of the source block
        'target', zeros(1,dim), ... % handle of the target block
        'sourcePort', zeros(1,dim), ... % port number of the source
        'targetPort', zeros(1,dim), ... % port number of the target
        'sourceIpv4', strings(1,dim), ... % ip of the source board 
        'targetIpv4', strings(1,dim) ); % ip of the target board
    
    % Read block handles for board subsystems  
    targetHandles = ones(1, nd);
    for i = 1:nd
        targetHandles(i) = getSimulinkBlockHandle( ...
            strcat(obj.TopModel, '/', obj.Boards(i).ModelName));
    end
    
    for i = 1:nd
        % Select board's subsystem in top level model
        model = strcat(obj.TopModel, '/', obj.Boards(i).ModelName);
        m = find_system(model);
        
        % Get port connectivity detail, for info see 
        % https://www.mathworks.com/help/simulink/slref/common-block-parameters.html
        port = get_param(m{1}, 'PortConnectivity');

        % Iterate ports of the subsystem
        for j = 1:numel(port)
            if ~isempty(port(j).DstBlock)
                % Find other board handles which are directly connected
                % to the current output port
                [targets, portIdx, targetIdx] = ...
                    intersect(port(j).DstBlock, targetHandles);
                if ~isempty(targets)
                    % Prepare indexes for found direct connections
                    first = count + 1;
                    last = first + numel(targets);
                    k = first : last;

                    % Fill the directs struct entries
                    directs(k).source = targetHandles(i);
                    directs(k).target = targets;
                    directs(k).sourcePort = port(j).Type;
                    directs(k).targetPort = port(j).DstPort(portIdx);
                    directs(k).sourceIpv4 = obj.Boards(i).Ipv4;
                    directs(k).targetIpv4 = obj.Boards(targetIdx).Ipv4;
                    count = last;
                end
            end
        end
    end
    
    % Trim the overallocated directs struct to actual size
    if count > 0
        directs = directs(1:count);
    else
        % create empty struct with same fields as directs and overwrites it
        f = fieldnames(directs)';
        f{2,1} = {};
        directs = struct(f{:});
    end
end