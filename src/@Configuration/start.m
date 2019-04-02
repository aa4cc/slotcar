function start(obj)

% Open SSH connections to all boards
[beaglebones, ok] = openConnection(obj);
if ~ok
    fprintf('@@@ Returning without starting any model')
    return;
end

% Start each board model
for i = 1:numel(obj.Boards)
    if ~isempty(beaglebones{i})
        boardModel = obj.Boards(i).ModelName;
        sys = load_system(boardModel);

        % Open the board system and run in external mode
        if obj.Boards(i).External
            set_param(sys, 'SimulationMode', 'external');
            set_param(sys, 'SimulationCommand', 'start');
            open_system(sys);
        % Run the model compiled on the board silently
        else
            if ~isModelRunning(b(i), sys)
                runModel(b, boardModel)
            end
        end
    end
end

% Open and start the top simulink model
top = obj.TopModel;
set_param(top, 'SimulationMode', 'normal');
set_param(top, 'SimulationCommand', 'start');
% Open all scopes in this model
scopes = find_system(top, 'BlockType', 'Scope');
for i = 1:numel(scopes)
    open_system(scopes{i});
end


