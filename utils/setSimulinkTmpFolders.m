function setSimulinkTmpFolders()

project = simulinkproject;
projectRoot = project.RootFolder;

myCacheFolder = fullfile(projectRoot, 'tmpwork');
myCodeFolder = fullfile(projectRoot, 'tmpcode');

Simulink.fileGenControl('set',...
    'CacheFolder', myCacheFolder,...
    'CodeGenFolder', myCodeFolder,...
    'createDir', true)
    
disp('## Set temporary folders');

end
