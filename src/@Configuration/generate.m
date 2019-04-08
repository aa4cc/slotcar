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
    % Open top model, top is the distribution model for Matlab PC.
    if exist(obj.TopModel, 'file') ~= 4
        top = new_system(obj.TopModel);
    else
        top = load_system(obj.TopModel);
        set_param(obj.TopModel, 'SimulationCommand','stop');
        Simulink.BlockDiagram.deleteContents(top);
    end
    subsys = add_block('built-in/Subsystem', ...
                        strcat(obj.TopModel,'/top'));

    % Copy root data to top model
    Simulink.BlockDiagram.copyContentsToSubsystem(root, subsys);
    Simulink.BlockDiagram.expandSubsystem(subsys);

    % Copy configuration set to top model
    rootConfig = getActiveConfigSet(root);
    config = attachConfigSetCopy(top, rootConfig, true);
    setActiveConfigSet(top, config.name);
    
    % Save top model
    save_system(top)
catch ME
    toc();
    cd(oldFolder)
    rethrow(ME)
end

disp("@@@ Copied root model.")
toc();

% Create top and board models with communication blocks
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

