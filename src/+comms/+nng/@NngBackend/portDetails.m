function [inportDimensions, ...
          outportDimensions, ...
          inportTypes, ...
          outportTypes] = portDetails(~, conf, top)
% PORTDETAILS Finds the dimensions and types of ports of board
% subsystems.
    % Remove blocks that can be only once
    blocks = Simulink.findBlocksOfType(top,'MATLABSystem');
    params = get_param(blocks, 'ports');
    
    if (~ isempty (params))
        if (iscell(params(1)))
            for i =1:length(params)
                pcell = params(i);
                if (pcell{1}(1) > 0 && pcell{1}(2) == 0 )
                    delete_block(blocks(i)); 
                end
            end
        else
            if (params(1) > 0 && params(2) == 0 )
                delete_block(blocks); 
            end
        end
    end
    
    % Set root model for evaluation
    param = 'compile';%#ok
    cmd = [[conf.RootModel '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);
    
    % Initialize output value cells
    nd = length(conf.Boards);
    
    inportDimensions = cell (nd, 1);
    outportDimensions = cell (nd, 1);
    
    inportTypes = cell (nd, 1);
    outportTypes = cell (nd, 1);
    
    
    for i = 1:nd

        model = strcat (conf.RootModel, '_/', conf.Boards(i).ModelName);
        ph = get_param(model,'PortHandles');
        
        % find inport dimensions
        tmp = get_param(ph.Inport,'CompiledPortDimensions');
        if (~iscell(tmp))
            if (isempty(tmp))
                inportDimensions{i} = [];
            else
                inportDimensions{i} = tmp(2);
            end
        else 
            if (isempty(tmp))
                inportDimensions{i} = [];
            else
                inportDimensions{i} = zeros(1, length(tmp));
                for ii = 1:length(tmp)
                    inportDimensions{i}(ii) = tmp{ii}(2);
                end
            end
        end 
        
        % find inport types
        types = get_param(ph.Inport,'CompiledPortDataType');
        
        if (iscell(types))
            inportTypes{i} = types;
        else
            c = cell(1);
            c{1} = types;
            inportTypes{i} = c;
        end
        
        % find outport dimensions
        tmp = get_param(ph.Outport,'CompiledPortDimensions');
        if (~iscell(tmp))
            outportDimensions{i} = tmp(2);
        else 
            if (isempty(tmp))
                outportDimensions{i} = [];
            else
                outportDimensions{i} = zeros (1, length(tmp));
                for ii = 1:length(tmp)
                    outportDimensions{i}(ii) = tmp{ii}(2);
                end
            end
        end 
        
        % find outport types
        types = get_param(ph.Outport,'CompiledPortDataType');
        if (iscell(types))
            outportTypes{i} = types;
        else
            c = cell(1);
            c{1} = types;
            outportTypes{i} = c;
        end
        
    end
    
    % Close root model evaluation
    param = 'term'; %#ok
    cmd = [[conf.RootModel '_'], ' ([],[],[], ' 'param' ' ); ' ];
    eval (cmd);
end