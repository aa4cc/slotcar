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
    % Open control model, that is the distribution model for Matlab PC.
    if exist(obj.CtrlModel, 'file') ~= 4
        model = new_system(obj.CtrlModel);
    else
        model = load_system(obj.CtrlModel);
        set_param(obj.CtrlModel, 'SimulationCommand','stop');
        Simulink.BlockDiagram.deleteContents(model);
    end
    subsys = add_block('built-in/Subsystem', ...
                        strcat(obj.CtrlModel,'/subsystem'));

    % Copy root data to control model
    Simulink.BlockDiagram.copyContentsToSubsystem(root, subsys);
    Simulink.BlockDiagram.expandSubsystem(subsys);

    % Copy configuration set to control model
    rootConfig = getActiveConfigSet(root);
    config = attachConfigSetCopy(model, rootConfig, true);
    setActiveConfigSet(model, config.name);
    
    % Save control model
    save_system(model)
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

