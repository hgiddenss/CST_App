CST = actxserver('CSTStudio.application');
mws = CST.Active3D;

direc = mws.invoke('GetMacroPathFromIndex',0);
macroDir = fullfile(direc,'CST_App Macros');
if ~isfolder(fullfile(direc,'CST_App Macros'))
    mkdir(macroDir)
    fprintf('New Macro Directory Created: \n%s\n',macroDir)
end

existingMacroInfo = dir(macroDir);
existingMacroInfo(1:2) = [];
macroFilePath = fileparts(mfilename('fullpath'));
allMacros = dir(macroFilePath);
allMacros(1:2) = [];
existingMacroFilenames = cell(numel(existingMacroInfo),1);
for i = 1:numel(existingMacroInfo)
    existingMacroFilenames{i} = existingMacroInfo(i).name;
end
for i = 1:numel(allMacros)
    if ~any(strcmp(allMacros(i).name,existingMacroFilenames))
        [~,~,extension] = fileparts(allMacros(i).name);
        if strcmpi(extension,'.mcr')
            macroFileToCopy = fullfile(macroFilePath,allMacros(i).name);
            copyfile(macroFileToCopy,macroDir); %Install macro in the path
            fprintf('New Macro Installed: \n%s\n',allMacros(i).name)
        end
    end
end