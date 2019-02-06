function distribute (conf)
    
    tic();
    % fix config
    rootModel = conf.root;
    if isfield(conf, 'commSampleTime') == false
        conf.commSampleTime = 0.1;
    end
    
    if isfield(conf, 'debug') == true
        debug = conf.debug;
    else
        debug = false;
    end

    if isfield(conf, 'parallelCompilation') == false
        conf.parallelCompilation = false;
    end
    
    if isfield(conf, 'port') == false
        conf.port = 25000;
    end
    
    
    numberOfDevices = length(conf.models);
    % Create top level Simulink model
    
    
    if exist (strcat(rootModel, "_"), 'file') ~= 4
        top = new_system (strcat(rootModel, "_"));
    else
        fprintf ("Exists, deleting content.\n");
        set_param(strcat (conf.root, '_'),'SimulationCommand','stop')
        top = load_system (strcat(rootModel, "_"));
        
       
        Simulink.BlockDiagram.deleteContents(top);

    end

    subsys = add_block('built-in/Subsystem', strcat(rootModel,'_/top'));
    root = load_system (rootModel);

    
    if debug
       open_system (top);
    end
    
    % file change
    
    if ~exist('tmp', 'dir')
        mkdir('tmp'); 
        [dir,~,~] = fileparts(mfilename('fullpath'));
        copyfile (fullfile(dir,'compile.*'), 'tmp', 'f')
        
    end
    
    oldFolder = cd ('tmp');
    
    % Copy data to top model
    Simulink.BlockDiagram.copyContentsToSubsystem(root, subsys);
    Simulink.BlockDiagram.expandSubsystem(subsys);

    %Copy configuration of parent model
    rootConfig = getActiveConfigSet (root);
    config = attachConfigSetCopy (top, rootConfig, true);
    setActiveConfigSet ( top, config.name);
    %set_param (top, 'SolverType', 'Variable-step')
   
    
    target_handles = ones (1, numberOfDevices);

    for i = 1:numberOfDevices
        target_handles(i) = getSimulinkBlockHandle(strcat(rootModel, '_/', conf.models(i).name));
    end

    % port dimensions and data type check
    
    [inportDimensions, outportDimensions, inportTypes, outportTypes] = portDimensions (conf, top);
    
    
    % Chck for direct Target to target connection
    directs = directConnections (conf, target_handles);
    


    %Replace subsystem content with comunication blocks
    topComunication (conf, directs, outportDimensions, outportTypes);
    save_system(top);
    
    toc()

    % Create target subsystems

    createDeviceModels (conf, directs, inportDimensions, inportTypes, target_handles, debug)
    
    % Run
    % Open all scopes

    scopes = find_system (top, 'BlockType', 'Scope');
    
    for i = 1:numel (scopes)
        open_system (scopes(i));
    end
    % Run top-level model
    if ~debug
        set_param(strcat (rootModel, '_'), 'StopTime', 'inf')
        set_param(strcat (rootModel, '_'), 'SimulationMode', 'normal')
        set_param(strcat (rootModel, '_'),'SimulationCommand','start')
    end
    cd (oldFolder);
    
end




function [inportDimensions, outportDimensions, inportTypes, outportTypes] = portDimensions (conf, top)

    % remove blocks that can be only once
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
    
    % get dimensions
    
    param = 'compile';%#ok
    cmd = [[conf.root '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);
    
    numberOfDevices = length(conf.models);
    
    inportDimensions = cell (numberOfDevices, 1);
    outportDimensions = cell (numberOfDevices, 1);
    
    inportTypes = cell (numberOfDevices, 1);
    outportTypes = cell (numberOfDevices, 1);
    
    
    for i = 1:numberOfDevices

        model = strcat (conf.root, '_/', conf.models(i).name);

        % mabe use ph = get_param(model,'PortHandles');
        % ph.Inport, ph.Outport
        ph = get_param(model,'PortHandles');
        %in = find_system(model,'BlockType','Inport');
        
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
                inportDimensions{i} = zeros (1, length(tmp));
                for ii = 1:length(tmp)
                    inportDimensions{i}(ii) = tmp{ii}(2);
                end
            end
        end 
        
        types = get_param(ph.Inport,'CompiledPortDataType');
        
        if (iscell(types))
            inportTypes{i} = types;
        else
            c = cell(1);
            c{1} = types;
            inportTypes{i} = c;
        end
        
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
        
        types = get_param(ph.Outport,'CompiledPortDataType');
        
        if (iscell(types))
            outportTypes{i} = types;
        else
            c = cell(1);
            c{1} = types;
            outportTypes{i} = c;
        end
        
    end
    
    param = 'term'; %#ok
    cmd = [[conf.root '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);

end

function directs = directConnections (conf, target_handles)

    % searches which connection goes straight from one target to another
    directs = [];
    numberOfDevices = length(conf.models);
    
    for i =1:numberOfDevices
        model = strcat (conf.root, '_/', conf.models(i).name);
        my_handle = getSimulinkBlockHandle (model);
        m = find_system (model);
        pc = get_param (m{1}, 'PortConnectivity');

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

function topComunication (conf, directs, outportDimensions, outportTypes)


    port = conf.port;
    numberOfDevices = length(conf.models);

    for i =1:numberOfDevices

        model = strcat (conf.root, '_/', conf.models(i).name);
        my_handle = getSimulinkBlockHandle (model);

        % delete lines
        lines = find_system(model,'FindAll','on','type','line');
        ip = conf.models(i).ip;

        for ii = lines
            delete_line (ii)
        end
        
        allblocks = find_system(model);
        in = find_system(model,'BlockType','Inport');
        out = find_system(model,'BlockType','Outport');


        toRemove = setdiff(allblocks,in);
        toRemove = setdiff(toRemove,out);

        for ii = 2: numel(toRemove)
            delete_block (toRemove{ii})
        end

        % send blocks
        for ii = 1: numel(in)
            isDirect = false;
            for iii = 1: size(directs, 1)
                if (directs (iii, 2) == my_handle) && (directs (iii, 4) == ii)
                    isDirect = true;
                end
            end

            if isDirect == false
                bh = add_block ('beaglebonebluelib/UDP Send', strcat(model, '/Send_', string(ii)));
                set_param (bh, 'remotePort', string(port));
                set_param (bh, 'remoteUrl', strcat ("'", ip, "'"));
                tmp = extractAfter (in{ii}, model);
                tmp = extractAfter (tmp, '/');
                add_line (model, strcat(tmp, '/1'), strcat('Send_', string(ii), '/1'));
                port = port + 1;
            end
        end

        % receive blocks
        for ii = 1: numel(out)

            isOnly = 0;
            for iii = 1: size(directs, 1)
                if (directs (iii, 1) == my_handle) && (directs (iii, 3) == ii)
                    isOnly = directs (iii, 5);
                end
            end

            if isOnly == 0
                bh = add_block ('beaglebonebluelib/UDP Receive', strcat(model, '/Receive', string(ii)));
                set_param (bh, 'localPort', string(port));
                set_param (bh, 'signalDatatype', outportTypes{i}{ii});
                set_param (bh, 'dims', num2str(outportDimensions{i}(ii)));
                set_param (bh, 'sampleTime', string(conf.commSampleTime));
                
                %commSampleTime
                tmp = extractAfter (out{ii}, model);
                tmp = extractAfter (tmp, '/');
                add_line (model, strcat('Receive', string(ii), '/1' ), strcat(tmp, '/1'));
                port = port + 1;
            end
        end
    end
end

function createDeviceModels (conf, directs, inportDimensions, inportTypes, target_handles, debug)

    port = conf.port;
    portDirect = conf.port + 200;
    numberOfDevices = length(conf.models);

    
    for i =1:numberOfDevices
        tic ();
        model = strcat (conf.root, '/', conf.models(i).name);
        my_handle = getSimulinkBlockHandle (strcat (conf.root, '_/', conf.models(i).name));
        % Copy subsystem to new model

        
        if exist (conf.models(i).name, 'file') ~= 4
            sys = new_system (conf.models(i).name);
        else
            fprintf ("Exists, deleting content.\n");
            sys = load_system (conf.models(i).name);
            Simulink.BlockDiagram.deleteContents(sys);            
        end

        
        
        %open_system (sys);
        Simulink.SubSystem.copyContentsToBlockDiagram (model, sys);

        %Copy configuration of parent model
        rootConfig = getActiveConfigSet (conf.root);
        config = attachConfigSetCopy (sys, rootConfig, true);
        setActiveConfigSet ( sys, config.name);

        %Replace I/O ports with UDP send/receive blocks


        in = replace_block (sys, 'Inport', 'beaglebonebluelib/UDP Receive', 'noprompt');
        out = replace_block (sys, 'Outport', 'beaglebonebluelib/UDP Send', 'noprompt');
        % inputs
        for ii = 1:numel (in)

            isDirect = false;
            portOffset = 0;
            for iii = 1: size(directs, 1)
                if (directs (iii, 2) == my_handle) && (directs (iii, 4) == ii)
                    isDirect = true;
                    if iii > portOffset
                        portOffset = iii;
                    end
                end
            end
            if isDirect == true
                set_param (in{ii}, 'localPort', string(portDirect + portOffset));
            else
                set_param (in{ii}, 'localPort', string(port));
                port = port + 1;
            end

            set_param (in{ii}, 'signalDatatype', inportTypes{i}{ii});
            set_param (in{ii}, 'dims', num2str(inportDimensions{i}(ii)));
            set_param (in{ii}, 'sampleTime', string(conf.commSampleTime));

        end

        % outputs
        for ii = 1:numel (out)

            count = 0;
            ips = [];
            isDirect = false;
            isOnly = 0;
            portOffset = [];
            for iii = 1: size(directs, 1)
                if (directs (iii, 1) == my_handle) && (directs (iii, 3) == ii)
                    isDirect = true;
                    isOnly = directs(iii, 5);
                    for iiii = 1:length(target_handles)

                        if target_handles(iiii) == directs (iii, 2)
                            portOffset(end + 1) = iii; %#ok
                        end
                    end
                    count = count + 1;
                    name = get_param (directs (iii, 2), 'Name');

                    for iiii = 1: length(conf.models)
                        if (conf.models (iiii).name == name)
                            ips(end  + 1) = iiii; %#ok

                        end
                    end

                end
            end

            if isDirect == true
                % direct send
                
                for j = 1:count
                    pc = get_param (out{ii}, 'PortConnectivity');
                    name = get_param (pc.SrcBlock, 'Name');
                    bh = add_block ('beaglebonebluelib/UDP Send', strcat(conf.models(i).name, '/SendDirect_', string(ii), '_', string(j)));
                    set_param (bh, 'remotePort', string(portDirect + portOffset(j)));
                    set_param (bh, 'remoteUrl', strcat ("'", conf.models(ips(j)).ip, "'"));
                    
                    add_line (sys, strcat(name, '/1'), strcat('SendDirect_', string(ii), '_', string(j), '/1'));
                end
            end

            if isOnly == 0
                set_param (out{ii}, 'remoteUrl', "'255.255.255.255'");
                set_param (out{ii}, 'remotePort', string(port));

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
        
        ip = conf.models(i).ip;

        if ~debug
            try
                b = beagleboneblue (ip, 'debian', 'temppwd');
            catch
               fprintf("Can't connect to %s\n", ip); 
               continue;
            end
            
                if isfield (conf.models(i), 'external') && ~isempty(conf.models(i).external) && conf.models(i).external
                    % run in external mode
                    set_param(sys, 'SimulationMode', 'external');
                    set_param(sys,'SimulationCommand','start');
                    open_system (sys);
                else
                    % normal build
                    if conf.parallelCompilation
                        % paralel compilation
                        set_param(sys, 'GenCodeOnly', 'on');
                        fprintf ('Building %s\n',  char(conf.models(i).name));
                        txt = evalc ('slbuild (sys)');

                        fprintf ('Code generation completed.\n%s\n', txt);

                        % checks for changes, runs model if there are not
                        if contains(txt, 'is up to date because no structural, parameter or code replacement library changes were found.')
                            fprintf ('Model %s has no new code, just starting old application.\n',  char(conf.models(i).name));
                            runModel(b, conf.models(i).name)
                        else

                            fprintf ('Model %s has new code, processing changes.\n',  char(conf.models(i).name));

                            bi = load ([char(conf.models(i).name), '_ert_rtw/buildInfo.mat']);
                            packNGo(bi.buildInfo,{'packType', 'flat'});

                            if getenv('OS') == 'Windows_NT'
                                system ( ['compile.bat ', char(conf.models(i).name), ' ', ip, ' &']);
                            else
                                system ( ['compile.bash ', char(conf.models(i).name), ' ', ip, ' &']);                
                            end
                        end

                    else
                        % normal compilation
                        set_param(sys, 'GenCodeOnly', 'off');
                        slbuild (sys);
                        %runs = true;
                        runs = isModelRunning(b, sys);
                        if runs
                            fprintf("Running at %s\n", ip);
                        end
                    end
                end
            
        end
        save_system(sys);
        
        toc ();
    end



end

