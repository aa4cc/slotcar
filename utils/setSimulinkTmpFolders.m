function setSimulinkTmpFolders()

project = simulinkproject;
projectRoot = project.RootFolder;

myCacheFolder = fullfile(projectRoot, 'work', 'cache');
myCodeFolder = fullfile(projectRoot, 'work', 'codegen');

Simulink.fileGenControl('set',...
    'CacheFolder', myCacheFolder,...
    'CodeGenFolder', myCodeFolder,...
    'createDir', true)
    
disp('## Set temporary folders');

end
