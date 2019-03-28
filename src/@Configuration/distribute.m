function distribute(obj)
% DISTRIBUTE Generate distribute folder a load onto boards.
%   Separates the root model into models for computer and boards and then
%   loads and runs each model. 

    oldFolder = cd(obj.Folder); % work in folder specified by configuration

    % ######## Create distribution folder with neccessary files ###########

    if ~exist('distribution', 'dir')
        mkdir('distribution');
%         copyFiles = fullfile(p.RootFolder, 'src', 'compile', 'compile.*');
%         copyfile(copyFiles, 'distribution', 'f');
    end

    % ############### Copy root model to top model and cd #################

    tic();   

    try
        % Open top and root models, top is the distribution model for
        % Matlab PC and root is the design model.
        if exist(obj.TopModel, 'file') ~= 4
            top = new_system(obj.TopModel);
        else
            set_param(obj.TopModel, 'SimulationCommand','stop')
            top = load_system(obj.TopModel);
            Simulink.BlockDiagram.deleteContents(top);
        end
        subsys = add_block('built-in/Subsystem', ...
                            strcat(obj.TopModel,'/top'));
        root = load_system(obj.RootModel);

        % Copy data to top model
        Simulink.BlockDiagram.copyContentsToSubsystem(root, subsys);
        Simulink.BlockDiagram.expandSubsystem(subsys);

        % Copy configuration of parent model
        rootConfig = getActiveConfigSet(root);
        config = attachConfigSetCopy(top, rootConfig, true);
        setActiveConfigSet(top, config.name);
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

    disp("@@@ Copied root model.")
    toc()

    % ####### Create top and board models with communication blocks #######
    tic()
    try
        obj.CommsBackend.createDistributionModels(obj);
    catch ME
        % close board models
        cd(oldFolder);
        rethrow(ME);
    end
    disp("@@@ Created distribution models.")
    toc()
    
    % ############## Load and run the board and top models ################
    open_system(top);
    % For debugging only open generated models
    if obj.Debug
        for i =1:length(obj.Boards)
            sys = load_system(obj.Boards(i).ModelName);
            open_system(sys);
        end
    else
        try
            % Open all scopes in top level scheme
            scopes = find_system(top, 'BlockType', 'Scope');
            for i = 1:numel (scopes)
                open_system(scopes(i));
            end
            % Run board models
            runDeviceModels(obj)
            % Run top-level model
            set_param(obj.TopModel, 'StopTime', 'inf')
            set_param(obj.TopModel, 'SimulationMode', 'normal')
            set_param(obj.TopModel, 'SimulationCommand','start')
        catch ME
            cd(oldFolder);
            rethrow(ME);
        end
    end
    cd(oldFolder);
end


function runDeviceModels(obj)
% RUNDEVICEMODELS Sends a model for each specified subsystem to a board and 
% runs it.

    for i =1:length(obj.Boards)
        tic ();
        boardModel = obj.Boards(i).ModelName;
        
        % Open subsystem
        sys = load_system(boardModel);

        % Compile and run created model
        % Test connection to the board
        ip = obj.Boards(i).Ipv4;
        try
            b = beagleboneblue(ip, 'debian', 'temppwd');
        catch
           fprintf("Can't connect to %s\n", ip); 
           continue;
        end

        % Open the board model and run in external model
        if obj.Boards(i).External
            set_param(sys, 'SimulationMode', 'external');
            set_param(sys, 'SimulationCommand', 'start');
            open_system(sys);
        else
            % Compile model on board and execute it there
            % Parallel compilation does this without waiting for
            % compilation results
            if obj.ParallelCompilation
                set_param(sys, 'GenCodeOnly', 'on');
                fprintf('Building %s\n',  char(boardModel));
                txt = evalc('slbuild(sys)');

                fprintf ('@@@ Code generation completed.\n%s\n', txt);

                % Check for changes, run model if there are none
                if contains(txt, 'is up to date because no structural, parameter or code replacement library changes were found.')
                    fprintf('@@@ Model %s has no new code, starting old application.\n',  ...
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
                slbuild(sys);
                runs = isModelRunning(b, sys);
                if runs
                    fprintf("@@@ Model running at %s\n", ip);
                end
            end
        end
        fprintf("@@@ Built and started model %s at %s\n", boardModel, ip);
        toc ();
    end
end
