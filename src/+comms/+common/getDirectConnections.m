function directs = getDirectConnections(obj)
% DIRECTCONNECTIONS Searches which connections connect board subsystems
% directly without crossing blocks in top system.

    % Load the reference model and preallocate the output struct
    load_system(obj.CtrlModel);
    out = find_system(obj.CtrlModel, 'BlockType', 'Outport');
    dim = numel(out);
    nd = length(obj.Boards);
    count = 1;
    directs = struct( ... 
        'source', zeros(1,dim), ... % handle of the source block
        'target', zeros(1,dim), ... % handle of the target block
        'sourcePort', zeros(1,dim), ... % port number of the source
        'targetPort', zeros(1,dim), ... % port number of the target
        'sourceIpv4', strings(1,dim), ... % ip of the source board 
        'targetIpv4', strings(1,dim) ); % ip of the target board
    
    % Read block handles for board subsystems  
    targetHandles = obj.getBoardTargetHandles();
    
    for i = 1:nd
        % Select board's subsystem in top level model
        model = strcat(obj.CtrlModel, '/', obj.Boards(i).ModelName);
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
                    first = count;
                    last = count + numel(targets) - 1;
                    k = first : last;

                    % Fill the directs struct entries
                    directs.source(k) = targetHandles(i);
                    directs.target(k) = targets;
                    directs.sourcePort(k) = port(j).Type;
                    directs.targetPort(k) = port(j).DstPort(portIdx);
                    directs.sourceIpv4(k) = obj.Boards(i).Ipv4;
                    directs.targetIpv4(k) = obj.Boards(targetIdx).Ipv4;
                    count = last;
                end
            end
        end
    end
    
    % Trim the overallocated directs struct to actual size
    if count > 0
        directs.source = directs.source(1:count);
        directs.target = directs.target(1:count);
        directs.sourcePort = directs.sourcePort(1:count);
        directs.targetPort = directs.targetPort(1:count);
        directs.sourceIpv4 = directs.sourceIpv4(1:count);
        directs.targetIpv4 = directs.targetIpv4(1:count);

    else
        % create empty struct with same fields as directs and overwrite it
        f = fieldnames(directs)';
        f{2,1} = {};
        directs = struct(f{:});
    end
end