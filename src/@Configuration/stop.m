function stop(obj)

oldFolder = cd(fullfile(obj.Folder, 'distribution'));
try
    % Try to stop each board model
    parfor i = 1:numel(obj.Boards)
        board = obj.Boards(i); %#ok
        model = board.ModelName;
        ip = board.Ipv4;
        sys = load_system(model);
        try
            b = beagleboneblue (ip, 'debian', 'temppwd');

            % Stop model execution
            if obj.Boards(i).External
                set_param(sys,'SimulationCommand','stop');
            else
                if isModelRunning(b(i), sys)
                    stopModel(b, model)
                end
            end
        catch ME
            fprintf(['@@@ Could not stop model running at %s\n',...
                     '@@@ Error message is:\n%s\n'], ip, ME.message);
        end
    end
    
    % Stop the control model
    ctrl = obj.CtrlModel;
    sys = load_system(ctrl);
    set_param(sys, 'SimulationCommand', 'stop')
catch ME
    cd(oldFolder);
    rethrow(ME);
end
cd(oldFolder);
