function start(obj)

oldFolder = cd(fullfile(obj.Folder, 'distribution'));
% Open SSH connections to all boards
[beaglebones, ok] = obj.connect;
if ~ok
    fprintf('@@@ Returning without starting any model.')
    return;
end

% Start each board model
for i = 1:numel(obj.Boards)
    if isempty(beaglebones{i})
        continue
    end
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
            fprintf('@@@ Running model %s', boardModel);
        else
            fprintf('@@@ Model %s already running', boardModel);
        end
    end
end

% Open and start the top simulink model
top = obj.TopModel;
fprintf('@@@ Running model %s', top);
sys = load_model(top);
open_model(sys);
set_param(top, 'SimulationMode', 'normal');
set_param(top, 'SimulationCommand', 'start');
% Open all scopes in this model
scopes = find_system(top, 'BlockType', 'Scope');
for i = 1:numel(scopes)
    open_system(scopes{i});
end

cd(oldFolder);


