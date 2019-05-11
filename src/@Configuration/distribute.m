function distribute(obj)
% DISTRIBUTE Send generated models to development boards and compile or
% open models for inspection.
%   Load device models to specified board where the external mode is not
%   specified. When debugging is specified only open generated models 
%   for inspection.

    oldFolder = cd(fullfile(obj.Folder, 'distribution'));
    try
        uploadDeviceModels(obj);
        uploadControlModel(obj);
    catch ME
        cd(oldFolder);
        rethrow(ME);
    end
    cd(oldFolder);
end

function uploadDeviceModels(obj)
% UPLOADDEVICEMODELS Sends a model for each specified subsystem to a board 
% and compiles it.

    % Open SSH connections to all boards
    [beaglebones, ok] = obj.connect;
    if ~ok
        fprintf('@@@ Returning without starting any model.\n')
        return;
    end

    % Load each board model
    for i = 1:numel(obj.Boards)
        % skip uncrucial unconnected boards
        if isempty(beaglebones{i})
            continue;
        end
        
        tic();
        boardModel = obj.Boards(i).ModelName;
        
        % Open subsystem
        sys = load_system(boardModel);

        % Pick connection to the board
        ip = obj.Boards(i).Ipv4;
        b = beaglebones{i};

        % Distribute and compile models on boards
        if obj.Boards(i).External
            % set external mode and build the model
            set_param(sys, 'SimulationMode', 'external');
            rtwbuild(sys, 'generateCodeOnly', false);
            fprintf("@@@ Loaded and connected external mode model %s\n",...
                boardModel);
        else
            % Compile model on board in normal mode
            % Parallel compilation does this without waiting for
            % compilation results
            set_param(sys, 'SimulationMode', 'normal');
            if obj.ParallelCompilation
                %set_param(sys, 'GenCodeOnly', 'on');
                fprintf('Building %s\n',  char(boardModel));
                txt = evalc('rtwbuild(sys,''generateCodeOnly'', true)');

                fprintf (['@@@ Parallel code generation for board %u' ...
                          'completed.\n%s\n'], txt);

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
                rtwbuild(sys, 'generateCodeOnly', false);
            end
            fprintf("@@@ Built model %s at %s\n", boardModel, ip);
        end
        toc ();
    end
end

function uploadControlModel(obj)
% UPLOADCONTROLMODEL sets and conditionally builds the control model to be 
% run on pc

model = obj.CtrlModel;
sys = load_system(model);
set_param(sys,'SimulationMode','normal')
if obj.DesktopExternalRT
    warning('@@@ Desktop external mode not yet supported.\n')
    %rtwbuild(sys, 'generateCodeOnly', false);
end
end
