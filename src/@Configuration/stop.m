function stop(obj)

oldFolder = cd(fullfile(obj.Folder, 'distribution'));
try
    % Stop the control model
    sys = load_system(obj.CtrlModel);
    set_param(sys, 'SimulationCommand', 'stop')
    % Open SSH connections to all boards
    beaglebones = obj.connect;
    
    if isempty(beaglebones)
        return
    end
    
    % Try to stop each board model
    boards = obj.Boards;
    parfor i = 1:numel(boards)
        if isempty(beaglebones{i})
            continue
        end
        b = beaglebones{i}
        board = boards(i);
        model = board.ModelName;
        ip = board.Ipv4;
        try
            % Stop model execution
            if board.External
                sys = load_system(model);
                set_param(sys,'SimulationCommand','stop');
            else
                if isModelRunning(b, model)
                    stopModel(b, model);
                    fprintf('@@@ Stopped model running at %s\n', ip);
                end
            end 
        catch ME
            fprintf(['@@@ Could not stop model running at %s\n',...
                     '@@@ Error message is:\n%s\n'], ip, ME.message);
        end
    end
catch ME
    cd(oldFolder);
    rethrow(ME);
end
cd(oldFolder);
