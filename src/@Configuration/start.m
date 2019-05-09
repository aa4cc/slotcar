function start(obj)

oldFolder = cd(fullfile(obj.Folder, 'distribution'));
try
    % Open SSH connections to all boards
    [beaglebones, ok] = obj.connect;
    if ~ok
        fprintf('@@@ Returning without starting any model.\n')
        return;
    end

    % Start each board model
    parfor i = 1:numel(obj.Boards)
        if isempty(beaglebones{i})
            continue
        end
        boardModel = obj.Boards(i).ModelName; %#ok
        sys = load_system(boardModel);
        try 
        % Open the board system and run in external mode
        if obj.Boards(i).External
            set_param(sys, 'SimulationCommand', 'start');
            open_system(sys);
        % Run the model compiled on the board silently
        else
            if ~isModelRunning(b(i), sys)
                runModel(b, boardModel)
                fprintf('@@@ Running model %s', boardModel);
            else
                fprintf('@@@ Model %s already running', boardModel);
            end
        end
        catch ME
                fprintf(['@@@ Could not stop model running at %s\n',...
                 '@@@ Error message is:\n%s\n'], ip, ME.message);
        end
    end

    % Open and start the control simulink model
    ctrl = obj.CtrlModel;
    fprintf('@@@ Running model %s', ctrl);
    sys = load_model(ctrl);
    open_model(sys);
    set_param(sys, 'SimulationCommand', 'start');

    % UNUSED: set "open at simulation start" in the scope instead
    % % Open all scopes in this model
    % scopes = find_system(ctrl, 'BlockType', 'Scope');
    % for i = 1:numel(scopes)
    %     open_system(scopes{i});
    % end
catch ME
   cd(oldFolder);
   rethrow(ME);
end
cd(oldFolder);


