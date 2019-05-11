function generate(obj)
%GENERATE Create distribution folder and distribution models.
%   Separates the root model into models for computer and boards. 
%   Interfaces between these models are replaced by wireless communication
%   blocks according to specified communication backend.

tic();
oldFolder = cd(obj.Folder); % work in folder specified by configuration

% Create distribution folder for generated models
if ~exist('distribution', 'dir')
    mkdir('distribution');
end

% Load design model and then work in distribution directory
root = load_system(obj.RootModel);
cd('distribution');

try 
    % Read the config set from root model
    rootConfig = getActiveConfigSet(obj.RootModel);
    
    % copy the board subsystems to new models
    for i = 1:length(obj.Boards)
        % pick the name of the new model and close the existing model
        boardModel = obj.Boards(i).ModelName;
        close_system(boardModel, false);
        
        % copy the subsystem content to a new model
        newModel = new_system;
        modelToCopy = strcat(obj.RootModel, '/', boardModel);
        Simulink.SubSystem.copyContentsToBlockDiagram(modelToCopy, newModel);
        config = attachConfigSetCopy(newModel, rootConfig, true);
        setActiveConfigSet(newModel, config.name);
        
        % save the new model
        save_system(newModel, boardModel);
        close_system(newModel);
    end
    
    % Save root model copy as control model
    close_system(obj.CtrlModel, false);
    save_system(root, obj.CtrlModel)
catch ME
    toc();
    cd(oldFolder);
    rethrow(ME);
end

disp("@@@ Copied root model.")
toc();

% Create control and board models with communication blocks
tic();
try
    obj.CommsBackend.createDistributionModels(obj);
catch ME
    toc();
    cd(oldFolder);
    rethrow(ME);
end
disp("@@@ Separated distribution models.")
toc();
cd(oldFolder);

