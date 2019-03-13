%% Stop all executables
function stop(obj)
    
    if isfield(obj, 'root') == true
        set_param(strcat (obj.Root, '_'),'SimulationCommand','stop')
    end



    for i =1:length(obj.Boards)
        tic ();
        board = obj.Boards(i);
        ip = board.Ipv4;
        try
            b = beagleboneblue (ip, 'debian', 'temppwd');

            if isfield (board, 'External') ...
                    && ~isempty(board.External) ...
                    && board.External
                set_param(sys,'SimulationCommand','stop');
            else
                runs = isModelRunning(b, board.ModelName);
                if runs 
                    fprintf ("Stopping model at %s\n", ip);
                    % psmisc must be installed at target to perform this operation
                    stopModel(b, board.ModelName)
                end
            end
            toc()
        catch
           fprintf ("Can't stop model at %s\n", ip); 
        end
    end

end
