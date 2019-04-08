function inspect(obj)
%INSPECT Summary of this function goes here
%   Detailed explanation goes here

oldFolder = cd(fullfile(obj.Folder, 'distribution'));
try
    open_system(obj.TopModel);
    for i =1:length(obj.Boards)
        open_system(obj.Boards(i).ModelName);
    end
catch ME
    warning(ME.identifier,'@@@ Error opening system window: %s', ME.message)
end
cd(oldFolder);

