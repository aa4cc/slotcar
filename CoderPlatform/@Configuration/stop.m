%% Stop all executables
function stop(obj)
    
    if isfield(obj, 'root') == true
        set_param(strcat (obj.Root, '_'),'SimulationCommand','stop')
    end



    for i =1:length(obj.Models)
        tic ();
        ip = obj.Models(i).Ipv4;
        try
            b = beagleboneblue (ip, 'debian', 'temppwd');

            if isfield (obj.Models(i), 'external') && ~isempty(obj.Models(i).external) && obj.Models(i).external
                set_param(sys,'SimulationCommand','stop');
            else
                runs = isModelRunning(b, obj.Models(i).name);
                if runs 
                    fprintf ("Stopping model at %s\n", ip);
                    % psmisc must be installed at target to perform this operation
                    stopModel(b, obj.Models(i).name)
                end
            end
            toc()
        catch
           fprintf ("Can't stop model at %s\n", ip); 
        end
    end

end
