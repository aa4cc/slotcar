function inspect(obj)
%INSPECT Summary of this function goes here
%   Detailed explanation goes here

oldFolder = cd(fullfile(obj.Folder, 'distribution'));
try
    open_system(obj.CtrlModel);
catch ME
    warning(ME.identifier, ...
        '@@@ Error opening system window: \n%s\n', ME.message)
end

for i = 1:length(obj.Boards)
    try
        open_system(obj.Boards(i).ModelName);
    catch ME
    warning(ME.identifier, ...
        '@@@ Error opening system window: \n%s\n', ME.message)
    end
end
cd(oldFolder);

