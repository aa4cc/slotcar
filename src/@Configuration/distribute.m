function distribute(obj)
% DISTRIBUTE Send generated models to development boards and compile or
% open models for inspection.
%   Load device models to specified board where the external mode is not
%   specified. When debugging is specified only open generated models 
%   for inspection.

    oldFolder = cd(fullfile(obj.Folder, 'distribution'));
    try
        loadDeviceModels(obj);
    catch ME
        cd(oldFolder);
        rethrow(ME);
    end
    fprintf('@@@ Successfully generated distribution models\n'); 
end

function loadDeviceModels(obj)
% LOADDEVICEMODELS Sends a model for each specified subsystem not in 
% external mode to a board and compiles it.

    % Open SSH connections to all boards
    [beaglebones, ok] = obj.connect;
    if ~ok
        fprintf('@@@ Returning without starting any model.')
        return;
    end

    % Load each board model
    for i = 1:numel(obj.Boards)
        if isempty(beaglebones{i})
            continue;
        end
        tic();
        boardModel = obj.Boards(i).ModelName;
        
        % Open subsystem
        sys = load_system(boardModel);

        % Test connection to the board
        ip = obj.Boards(i).Ipv4;
        b = beaglebones{i};

        % Distribute and compile models on boards not run in external mode
        if ~obj.Boards(i).External
            % Compile model on board and execute it there
            % Parallel compilation does this without waiting for
            % compilation results
            if obj.ParallelCompilation
                set_param(sys, 'GenCodeOnly', 'on');
                fprintf('Building %s\n',  char(boardModel));
                txt = evalc('slbuild(sys)');

                fprintf ('@@@ Code generation completed.\n%s\n', txt);

                % Check for changes
                if ~contains(txt, ['is up to date because no structural, ',...
                        'parameter or code replacement library changes ',...
                        'were found.'])
                    fprintf(['@@@ Model %s has new code, ',...
                             'processing changes.\n'], ...
                            char(boardModel));

                    bi = load([char(boardModel), '_ert_rtw/buildInfo.mat']);
                    packNGo(bi.buildInfo,{'packType', 'flat'});

                    if ispc
                        system( ['compile.bat ', ...
                                 char(boardModel), ' ', ip, ' &'] );
                    else
                        system( ['compile.bash ', ...
                                 char(boardModel), ' ', ip, ' &'] );                
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
            fprintf("@@@ Built model %s at %s\n", boardModel, ip);
        else
            fprintf("@@@ Skipping external mode model %s\n", boardModel);
        end
        toc ();
    end
end
