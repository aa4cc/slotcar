function stop(obj)
    
% Stop the top model
top = obj.TopModel;
set_param(top, 'SimulationCommand', 'stop')

% Try to stop each board model
for i = 1:numel(obj.Boards)
    board = obj.Boards(i);
    boardModel = board.ModelName;
    ip = board.Ipv4;
    try
        b = beagleboneblue (ip, 'debian', 'temppwd');

        % Stop model execution
        if obj.Boards(i).External
            sys = load_system(boardModel);
            set_param(sys,'SimulationCommand','stop');
        else
            if isModelRunning(b(i), sys)
                stopModel(b, boardModel)
            end
        end
    catch ME
        fprintf(['@@@ Could not stop model running at %s\n',...
                 '@@@ Error message is:\n%s\n'], ip, ME.message);
    end
end
