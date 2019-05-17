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
    boards = obj.Boards;
    openScopes = obj.OpenScopes;
    parfor i = 1:numel(boards)
        if isempty(beaglebones{i})
            continue
        end
        b = beaglebones{i};
        board = boards(i);
        model = board.ModelName;
        ip = board.Ipv4;
        sys = load_system(model);
        try 
        % Open the board system and run in external mode
        if board.External
            open_system(sys);
            if openScopes
                scopes = find_system(ctrl, 'BlockType', 'Scope');
                for j = 1:numel(scopes)
                    open_system(scopes{j});
                end
            end
            % set_param(sys, 'SimulationCommand', 'start');
            if ~isModelRunning(b, model)
                runModel(b, model)
            end
            set_param(sys, 'SimulationCommand', 'connect');
        % Run the model compiled on the board silently
        else
            if ~isModelRunning(b, model)
                runModel(b, model)
                fprintf('@@@ Running model %s\n', model);
            else
                fprintf('@@@ Model %s already running\n', model);
            end
        end
        catch ME
                warning(['@@@ Could not start model %s at %s\n',...
                 '@@@ Error message is:\n%s\n'], model, ip, ME.message);
        end
    end

    % Open and start the control simulink model
    sys = load_system(obj.CtrlModel);
    open_system(sys);
    set_param(sys, 'SimulationCommand', 'start');
    
    if openScopes
        scopes = find_system(ctrl, 'BlockType', 'Scope');
        for i = 1:numel(scopes)
            open_system(scopes{i});
        end
    end
catch ME
   cd(oldFolder);
   rethrow(ME);
end
cd(oldFolder);


