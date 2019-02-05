%% Stop all executables
function stop (conf)
    
    if isfield(conf, 'root') == true
        set_param(strcat (conf.root, '_'),'SimulationCommand','stop')
    end



    for i =1:length(conf.models)
        tic ();
        ip = conf.models(i).ip;
        try
            b = beagleboneblue (ip, 'debian', 'temppwd');

            if isfield (conf.models(i), 'external') && ~isempty(conf.models(i).external) && conf.models(i).external
                set_param(sys,'SimulationCommand','stop');
            else
                runs = isModelRunning(b, conf.models(i).name);
                if runs 
                    fprintf ("Stopping model at %s\n", ip);
                    % psmisc must be installed at target to perform this operation
                    stopModel(b, conf.models(i).name)
                end
            end
            toc()
        catch
           fprintf ("Can't stop model at %s\n", ip); 
        end
    end

end
