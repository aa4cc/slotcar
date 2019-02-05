%% Run no compile
function start (conf)
    
    


    for i =1:length(conf.models)
        tic ()
        ip = conf.models(i).ip;
        try
        b = beagleboneblue (ip, 'debian', 'temppwd');

        
        if isfield (conf.models(i), 'external') && ~isempty(conf.models(i).external)&& conf.models(i).external
                set_param(sys, 'SimulationMode', 'external');
                set_param(sys,'SimulationCommand','start');
                open_system (sys)
        else
            fprintf ("Starting model at %s\n", ip);
            runModel(b, conf.models(i).name)
        end
        toc()
        
        catch
           fprintf ("Cant start model at %s\n", ip); 
        end
    end

    
    if isfield(conf, 'root') == true
        set_param(strcat (conf.root, '_'),'SimulationCommand','start');
    
        scopes = find_system (strcat (conf.root, '_'), 'BlockType', 'Scope');
        for i = 1:numel (scopes)
            open_system (scopes{i});
        end
    end

end


