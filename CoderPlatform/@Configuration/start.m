%% Run no compile
function start(obj)
    
    for i =1:length(obj.Models)
        tic ()
        ip = obj.Models(i).Ipv4;
        try
        b = beagleboneblue (ip, 'debian', 'temppwd');

        
        if isfield (obj.Models(i), 'external') && ~isempty(obj.Models(i).external)&& obj.Models(i).external
                set_param(sys, 'SimulationMode', 'external');
                set_param(sys,'SimulationCommand', 'start');
                open_system (sys)
        else
            fprintf ("Starting model at %s\n", ip);
            runModel(b, obj.Models(i).name)
        end
        toc()
        
        catch
           fprintf ("Cant start model at %s\n", ip); 
        end
    end

    
    if isfield(obj, 'root') == true
        set_param(strcat (obj.Root, '_'),'SimulationCommand','start');
    
        scopes = find_system (strcat (obj.Root, '_'), 'BlockType', 'Scope');
        for i = 1:numel (scopes)
            open_system (scopes{i});
        end
    end

end


