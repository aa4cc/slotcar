function distribute(obj)
        
    
    %% Prepare distribution directory
    p = simulinkproject;
    if ~exist('distribution', 'dir')
        mkdir('distribution'); 
        copyfile (fullfile(p.RootFolder,'lib','compile.*'), 'distribution', 'f')
    end
    
    oldFolder = cd ('distribution');
    
    %% Create top level Simulink model
    tic();   
    numberOfDevices = length(obj.Models);
    
    if exist (strcat(obj.Root, "_"), 'file') ~= 4
        top = new_system (strcat(obj.Root, "_"));
    else
        fprintf ("Exists, deleting content.\n");
        set_param(strcat (obj.Root, '_'),'SimulationCommand','stop')
        top = load_system (strcat(obj.Root, "_"));
         
        Simulink.BlockDiagram.deleteContents(top);
    end

    subsys = add_block('built-in/Subsystem', strcat(obj.Root,'_/top'));
    root = load_system (obj.Root);

    if obj.Debug
       open_system (top);
    end
    
    %% Copy data to top model
    Simulink.BlockDiagram.copyContentsToSubsystem(root, subsys);
    Simulink.BlockDiagram.expandSubsystem(subsys);

    %% Copy configuration of parent model
    rootConfig = getActiveConfigSet (root);
    config = attachConfigSetCopy (top, rootConfig, true);
    setActiveConfigSet ( top, config.name);
    
    target_handles = ones (1, numberOfDevices);

    for i = 1:numberOfDevices
        target_handles(i) = getSimulinkBlockHandle(strcat(obj.Root, '_/', obj.Models(i).Name));
    end

    % Check port dimensions and data type
    
    [inportDimensions, outportDimensions, inportTypes, outportTypes] = portDimensions (obj, top);
    
    % Check for direct Target to target connection
    directs = directConnections (obj, target_handles);
    


    % Replace subsystem content with comunication blocks
    topComunication (obj, directs, outportDimensions, outportTypes);
    save_system(top);
    
    toc()

    % Create target subsystems

    createDeviceModels (obj, directs, inportDimensions, inportTypes, target_handles, obj.Debug)
    
    % Run
    % Open all scopes

    scopes = find_system (top, 'BlockType', 'Scope');
    
    for i = 1:numel (scopes)
        open_system (scopes(i));
    end
    % Run top-level model
    if ~obj.Debug
        set_param(strcat (obj.Root, '_'), 'StopTime', 'inf')
        set_param(strcat (obj.Root, '_'), 'SimulationMode', 'normal')
        set_param(strcat (obj.Root, '_'),'SimulationCommand','start')
    end
    cd (oldFolder);
    
end




function [inportDimensions, outportDimensions, inportTypes, outportTypes] = portDimensions (obj, top)

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
    cmd = [[obj.Root '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);
    
    numberOfDevices = length(obj.Models);
    
    inportDimensions = cell (numberOfDevices, 1);
    outportDimensions = cell (numberOfDevices, 1);
    
    inportTypes = cell (numberOfDevices, 1);
    outportTypes = cell (numberOfDevices, 1);
    
    
    for i = 1:numberOfDevices

        model = strcat (obj.Root, '_/', obj.Models(i).Name);

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
    cmd = [[obj.Root '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);

end

function directs = directConnections (obj, target_handles)

    % searches which connection goes straight from one target to another
    directs = [];
    
    for i =1:length(obj.Models)
        model = strcat (obj.Root, '_/', obj.Models(i).Name);
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

function topComunication (obj, directs, outportDimensions, outportTypes)


    port = obj.Port;
    Ts = obj.CommSampleTime;
    numberOfDevices = length(obj.Models);

    for i =1:numberOfDevices
        
        ip = obj.Models(i).Ipv4;
        model = strcat (obj.Root, '_/', obj.Models(i).Name);
        my_handle = getSimulinkBlockHandle (model);

        % delete lines
        lines = find_system(model,'FindAll','on','type','line');
        
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
                bh = add_block ('comms_lib/Publishing', strcat(model, '/Send', string(ii)));
                set_param (bh, 'hosturl', string(sprintf ('''tcp://:%u''',port)));
                set_param (bh, 'stepsize', num2str(Ts));
                tmp = extractAfter (in{ii}, model);
                tmp = extractAfter (tmp, '/');
                add_line (model, strcat(tmp, '/1'), strcat('Send', string(ii), '/1'));
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
                bh = add_block ('comms_lib/Subscribing', strcat(model, '/Receive', string(ii)));
%                 set_param (bh, 'signalDatatype', outportTypes{i}{ii});
%                 set_param (bh, 'dims', num2str(outportDimensions{i}(ii)));
                %set_param (bh, 'hosturl', strcat ("'","tcp://",ip,":",port,"'"));
                set_param (bh, 'hosturl', string(sprintf ('''tcp://%s:%u''',ip,port)));
                set_param (bh, 'sampletime', num2str(Ts));
                tmp = extractAfter (out{ii}, model);
                tmp = extractAfter (tmp, '/');
                add_line (model, strcat('Receive', string(ii), '/1' ), strcat(tmp, '/1'));
                port = port + 1;
            end
        end
    end
end

function createDeviceModels (obj, directs, inportDimensions, inportTypes, target_handles, debug)

    port = obj.Port;
    portDirect = obj.Port + 200;
    numberOfDevices = length(obj.Models);

    
    for i =1:numberOfDevices
        tic ();
        model = strcat (obj.Root, '/', obj.Models(i).Name);
        my_handle = getSimulinkBlockHandle (strcat (obj.Root, '_/', obj.Models(i).Name));
        % Copy subsystem to new model

        
        if exist (obj.Models(i).Name, 'file') ~= 4
            sys = new_system (obj.Models(i).Name);
        else
            fprintf ("Exists, deleting content.\n");
            sys = load_system (obj.Models(i).Name);
            Simulink.BlockDiagram.deleteContents(sys);            
        end

        
        
        %open_system (sys);
        Simulink.SubSystem.copyContentsToBlockDiagram (model, sys);

        %Copy configuration of parent model
        rootConfig = getActiveConfigSet (obj.Root);
        config = attachConfigSetCopy (sys, rootConfig, true);
        setActiveConfigSet ( sys, config.name);

        %Replace I/O ports with UDP send/receive blocks


        in = replace_block (sys, 'Inport', 'comms_lib/Subscribing', 'noprompt');
        out = replace_block (sys, 'Outport', 'comms_lib/Publishing', 'noprompt');
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
                %set_param (in{ii}, 'portnum', string(portDirect + portOffset));
            else
                %set_param (in{ii}, 'portnum', string(port));
                port = port + 1;
            end

            %set_param (in{ii}, 'signalDatatype', inportTypes{i}{ii});
            %set_param (in{ii}, 'dims', num2str(inportDimensions{i}(ii)));
            set_param (in{ii}, 'sampletime', string(obj.CommSampleTime));

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

                    for iiii = 1: length(obj.Models)
                        if (obj.Models (iiii).name == name)
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
                    bh = add_block ('comms_lib/Publishing', strcat(obj.Models(i).Name, '/SendDirect_', string(ii), '_', string(j)));
                    set_param (bh, 'hosturl', string(sprintf ('''tcp://%s:%u''',obj.Models(ips(j)).Ipv4,portDirect + portOffset(j))));
                    %set_param (bh, 'portnum', string(portDirect + portOffset(j)));
               
                    add_line (sys, strcat(name, '/1'), strcat('SendDirect_', string(ii), '_', string(j), '/1'));
                end
            end

            if isOnly == 0
                set_param (out{ii}, 'hosturl', string(sprintf ('''tcp://:%u''',port)));
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
        
        ip = obj.Models(i).Ipv4;

        if ~debug
            try
                b = beagleboneblue (ip, 'debian', 'temppwd');
            catch
               fprintf("Can't connect to %s\n", ip); 
               continue;
            end
            
                if isfield (obj.Models(i), 'external') && ~isempty(obj.Models(i).External) && obj.Models(i).External
                    % run in external mode
                    set_param(sys, 'SimulationMode', 'external');
                    set_param(sys,'SimulationCommand','start');
                    open_system (sys);
                else
                    % normal build
                    if obj.ParallelCompilation
                        % paralel compilation
                        set_param(sys, 'GenCodeOnly', 'on');
                        fprintf ('Building %s\n',  char(obj.Models(i).Name));
                        txt = evalc ('slbuild (sys)');

                        fprintf ('Code generation completed.\n%s\n', txt);

                        % checks for changes, runs model if there are not
                        if contains(txt, 'is up to date because no structural, parameter or code replacement library changes were found.')
                            fprintf ('Model %s has no new code, just starting old application.\n',  char(obj.Models(i).Name));
                            runModel(b, obj.Models(i).Name)
                        else

                            fprintf ('Model %s has new code, processing changes.\n',  char(obj.Models(i).Name));

                            bi = load ([char(obj.Models(i).Name), '_ert_rtw/buildInfo.mat']);
                            packNGo(bi.buildInfo,{'packType', 'flat'});

                            if getenv('OS') == 'Windows_NT'
                                system ( ['compile.bat ', char(obj.Models(i).Name), ' ', ip, ' &']);
                            else
                                system ( ['compile.bash ', char(obj.Models(i).Name), ' ', ip, ' &']);                
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

