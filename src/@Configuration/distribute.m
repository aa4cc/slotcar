function distribute(obj)
% DISTRIBUTE Generate distribute folder a load onto boards.
%   Separates the root model into models for computer and boards and then
%   loads and runs each model. 

    p = simulinkproject; % project handle
    nd = length(obj.Boards); % number of boards
    topModel = strcat(obj.RootModel,"_"); % name of the top execution model
    oldFolder = cd(obj.Folder); % work in folder specified by configuration

    % ######## Create distribution folder with neccessary files ###########

    if ~exist('distribution', 'dir')
        mkdir('distribution');
%         copyFiles = fullfile(p.RootFolder, 'src', 'compile', 'compile.*');
%         copyfile(copyFiles, 'distribution', 'f');
    end

    % ############## Prepare top level distribution model #################

    tic();   

    try
        % Open top, root and subsys models
        if exist(topModel, 'file') ~= 4
            top = new_system (strcat(obj.RootModel, "_"));
        else
            set_param(topModel, 'SimulationCommand','stop')
            top = load_system(topModel);
            Simulink.BlockDiagram.deleteContents(top);
        end
        subsys = add_block('built-in/Subsystem', ...
                            strcat(topModel,'/top'));
        root = load_system(obj.RootModel);

        % Copy data to top model
        Simulink.BlockDiagram.copyContentsToSubsystem(root, subsys);
        Simulink.BlockDiagram.expandSubsystem(subsys);

        % Copy configuration of parent model
        rootConfig = getActiveConfigSet(root);
        config = attachConfigSetCopy(top, rootConfig, true);
        setActiveConfigSet(top, config.name);

        % Prepare handles for board blocks
        targetHandles = ones(1, nd);
        for i = 1:nd
            targetHandles(i) = getSimulinkBlockHandle( ...
                strcat(topModel, '/', obj.Boards(i).ModelName));
        end

        % Check port dimensions and data type
        %[inDims, outDims, inTypes, outTypes] = portDetails(obj, top);

        % Check for direct target to target connection
        directs = directConnections(obj, targetHandles);

        % Replace subsystem content with comunication blocks
        topCommunication(obj, directs);

        % Open model window if debugging
        if obj.Debug
            open_system (top);
        end 
    catch ME
        rethrow(ME);
    end

    % Save to distribution folder
    try
        cd('distribution');
        save_system(top);
    catch ME
       cd(oldFolder);
       rethrow(ME);
    end

    disp("@@@ Generated top level model.")
    toc()

    % #################### Create board models ############################
    tic()
    try
        createDeviceModels(obj, ...
            directs, ...
            targetHandles, ...
            obj.Debug)
    catch ME
        % close board models
        cd(oldFolder);
        rethrow(ME);
    end
    % ##################### Run the top model #############################
    if ~obj.Debug
        try
            % Open all scopes
            scopes = find_system(top, 'BlockType', 'Scope');
            for i = 1:numel (scopes)
                open_system (scopes(i));
            end

            % Run top-level model
            set_param(topModel, 'StopTime', 'inf')
            set_param(topModel, 'SimulationMode', 'normal')
            set_param(topModel, 'SimulationCommand','start')
        catch ME
            cd(oldFolder);
            rethrow(ME);
        end
    end
    cd (oldFolder);
end




function [inportDimensions, ...
          outportDimensions, ...
          inportTypes, ...
          outportTypes] = portDetails(obj, top)
% PORTDETAILS Finds the dimensions and types of ports of board
% subsystems.
    % Remove blocks that can be only once
    blocks = Simulink.findBlocksOfType(top,'MATLABSystem');
    params = get_param(blocks, 'ports');
    
    if (~ isempty (params))
        if (iscell(params(1)))
            for i =1:length(params)
                pcell = params(i);
                if (pcell{1}(1) > 0 && pcell{1}(2) == 0 )
                    delete_block(blocks(i)); 
                end
            end
        else
            if (params(1) > 0 && params(2) == 0 )
                delete_block(blocks); 
            end
        end
    end
    
    % Set root model for evaluation
    param = 'compile';%#ok
    cmd = [[obj.RootModel '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);
    
    % Initialize output value cells
    nd = length(obj.Boards);
    
    inportDimensions = cell (nd, 1);
    outportDimensions = cell (nd, 1);
    
    inportTypes = cell (nd, 1);
    outportTypes = cell (nd, 1);
    
    
    for i = 1:nd

        model = strcat (obj.RootModel, '_/', obj.Boards(i).ModelName);
        ph = get_param(model,'PortHandles');
        
        % find inport dimensions
        tmp = get_param(ph.Inport,'CompiledPortDimensions');
        if (~iscell(tmp))
            if (isempty(tmp))
                inportDimensions{i} = [];
            else
                inportDimensions{i} = tmp(2);
            end
        else 
            if (isempty(tmp))
                inportDimensions{i} = [];
            else
                inportDimensions{i} = zeros(1, length(tmp));
                for ii = 1:length(tmp)
                    inportDimensions{i}(ii) = tmp{ii}(2);
                end
            end
        end 
        
        % find inport types
        types = get_param(ph.Inport,'CompiledPortDataType');
        
        if (iscell(types))
            inportTypes{i} = types;
        else
            c = cell(1);
            c{1} = types;
            inportTypes{i} = c;
        end
        
        % find outport dimensions
        tmp = get_param(ph.Outport,'CompiledPortDimensions');
        if (~iscell(tmp))
            outportDimensions{i} = tmp(2);
        else 
            if (isempty(tmp))
                outportDimensions{i} = [];
            else
                outportDimensions{i} = zeros (1, length(tmp));
                for ii = 1:length(tmp)
                    outportDimensions{i}(ii) = tmp{ii}(2);
                end
            end
        end 
        
        % find outport types
        types = get_param(ph.Outport,'CompiledPortDataType');
        if (iscell(types))
            outportTypes{i} = types;
        else
            c = cell(1);
            c{1} = types;
            outportTypes{i} = c;
        end
        
    end
    
    % Close root model evaluation
    param = 'term'; %#ok
    cmd = [[obj.RootModel '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);
end

function directs = directConnections(obj, target_handles)
% DIRECTCONNECTIONS Searches which connections connect board subsystems
% directly.
% TODO: understand this better and document it

    directs = [];
    
    for i = 1:length(obj.Boards)
        model = strcat(obj.RootModel, '_/', obj.Boards(i).ModelName);
        my_handle = getSimulinkBlockHandle(model);
        m = find_system(model);
        pc = get_param(m{1}, 'PortConnectivity');

        for ii = 1:numel(pc)
            onlyToTarget = 0;
            j = 1;
            for dst = pc(ii).DstBlock
                for th = target_handles
                    if dst == th
                        directs(end + 1, :) = [my_handle, dst, str2double(pc(ii).Type),pc(ii).DstPort(j) + 1 , 0]; %#ok
                        onlyToTarget = onlyToTarget + 1;
                    end
                end
                j = j + 1;
            end
            if onlyToTarget > 0
                if onlyToTarget == length (pc(ii).DstBlock)
                    directs (size (directs, 1) - onlyToTarget + 1:size (directs, 1), 5) = 1;
                end
            end
        end
    end
end

function topCommunication (obj, directs)
% TOPCOMMUNICATION Replaces subsystems with  blocks of the communication
% library for the top level scheme running in Matlab.

    port = obj.Port;
    Ts = obj.CommSampleTime;
    nd = length(obj.Boards);

    for i =1:nd
        
        ip = obj.Boards(i).Ipv4;
        model = strcat (obj.RootModel, '_/', obj.Boards(i).ModelName);
        modelHandle = getSimulinkBlockHandle(model);

        % Delete lines inside the board subsystem in top level model
        lines = find_system(model,'FindAll','on','type','line');
        
        for ii = lines
            delete_line (ii)
        end
        
        % Select all ports of the subsystem
        allblocks = find_system(model);
        in = find_system(model,'BlockType','Inport');
        out = find_system(model,'BlockType','Outport');

        % Remove all other blocks
        toRemove = setdiff(allblocks,in);
        toRemove = setdiff(toRemove,out);
        for ii = 2: numel(toRemove)
            delete_block (toRemove{ii})
        end

        % Replace inports of subsystem with send blocks
        for ii = 1: numel(in)
            isDirect = false;
            for iii = 1: size(directs, 1)
                if (directs (iii, 2) == modelHandle) && (directs (iii, 4) == ii)
                    isDirect = true;
                end
            end

            if isDirect == false
                % Add block and set parameters
                bh = add_block('comms_lib/Publishing', ...
                               strcat(model, '/Send', string(ii)));
                set_param(bh, 'hosturl', ...
                          string(sprintf ('''tcp://:%u''',port)));
                set_param(bh, 'sampletime', num2str(Ts));
                
                % Connect block to outport
                tmp = extractAfter(in{ii}, model);
                tmp = extractAfter(tmp, '/');
                add_line(model, ...
                         strcat(tmp, '/1'), ...
                         strcat('Send', string(ii), '/1'));
                     
                % Increment the port value for the next connection
                port = port + 1;
            end
        end

        % Replace outports of subsystem with receive blocks
        for ii = 1: numel(out)

            isOnly = 0; 
            for iii = 1: size(directs, 1)
                if (directs (iii, 1) == modelHandle) && (directs (iii, 3) == ii)
                    isOnly = directs(iii, 5);
                end
            end

            if isOnly == 0
                % Add block and set parameters
                bh = add_block ('comms_lib/Subscribing', ...
                                strcat(model, '/Receive', string(ii)));
                set_param (bh, 'hosturl', ...
                           string(sprintf ('''tcp://%s:%u''', ip, port)));
                set_param (bh, 'sampletime', num2str(Ts));
                
                % Connect block to inport
                tmp = extractAfter (out{ii}, model);
                tmp = extractAfter (tmp, '/');
                add_line (model, ...
                          strcat('Receive', string(ii), '/1' ), ...
                          strcat(tmp, '/1'));
                
                % Increment the port value for the next connection
                port = port + 1;
            end
        end
    end
end

function createDeviceModels (obj, directs, target_handles, debug)
% CREATEDEVICEMODELS Creates a model for each specified subsystem to be
% loaded on a board.

    port = obj.Port;
    portDirect = obj.Port + 200;
    Ts = obj.CommSampleTime;

    for i =1:length(obj.Boards)
        tic ();
        boardModel = obj.Boards(i).ModelName;
        modelToReplace = strcat(obj.RootModel, '/', boardModel);
        modelHandle = getSimulinkBlockHandle(modelToReplace);
        
        % Open subsystem as new model
        if exist (boardModel, 'file') ~= 4
            sys = new_system(boardModel);
        else
            sys = load_system(boardModel);
            Simulink.BlockDiagram.deleteContents(sys);            
        end

        % Copy contents from the subsystem in the root model
        Simulink.SubSystem.copyContentsToBlockDiagram (modelToReplace, sys);

        %Copy configuration of root model
        rootConfig = getActiveConfigSet (obj.RootModel);
        config = attachConfigSetCopy (sys, rootConfig, true);
        setActiveConfigSet ( sys, config.name);

        %Replace I/O ports with communication library blocks
        in = replace_block(sys, 'Inport', 'comms_lib/Subscribing', ...
                           'noprompt');
        out = replace_block(sys, 'Outport', 'comms_lib/Publishing', ...
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

                    for iiii = 1: length(obj.Boards)
                        if (obj.Boards(iiii).ModelName == name)
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
                                       obj.Boards(ips(j)).Ipv4, ...
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

        % Compile and run created model
        if debug
            open_system (sys);
        end
        save_system(sys);
        
        ip = obj.Boards(i).Ipv4;

        if ~debug
            try
                b = beagleboneblue (ip, 'debian', 'temppwd');
            catch
               fprintf("Can't connect to %s\n", ip); 
               continue;
            end
            
                if obj.Boards(i).External
                    % run in external mode
                    set_param(sys, 'SimulationMode', 'external');
                    set_param(sys, 'SimulationCommand', 'start');
                    open_system (sys);
                else
                    if obj.ParallelCompilation
                        set_param(sys, 'GenCodeOnly', 'on');
                        fprintf ('Building %s\n',  char(boardModel));
                        txt = evalc ('slbuild (sys)');

                        fprintf ('Code generation completed.\n%s\n', txt);

                        % Check for changes, run model if there are none
                        if contains(txt, 'is up to date because no structural, parameter or code replacement library changes were found.')
                            fprintf('@@@ Model %s has no new code, just starting old application.\n',  ...
                                    char(boardModel));
                            runModel(b, boardModel)
                        else
                            fprintf('@@@ Model %s has new code, processing changes.\n', ...
                                    char(boardModel));

                            bi = load([char(boardModel), '_ert_rtw/buildInfo.mat']);
                            packNGo(bi.buildInfo,{'packType', 'flat'});

                            if ispc
                                system( ['compile.bat ', char(boardModel), ' ', ip, ' &'] );
                            else
                                system( ['compile.bash ', char(boardModel), ' ', ip, ' &'] );                
                            end
                        end

                    else % normal compilation
                        set_param(sys, 'GenCodeOnly', 'off');
                        slbuild (sys);
                        runs = isModelRunning(b, sys);
                        if runs
                            fprintf("@@@ Model running at %s\n", ip);
                        end
                    end
                end
        end
        save_system(sys);
        
        fprintf("@@@ Built and started model %s at %s\n", boardModel, ip);
        toc ();
    end
end

