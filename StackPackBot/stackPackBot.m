%% which input folder

d1 = spbGetFolderDialog('Folder In', 'Next, navigate to folder of images to pack into stacks.');

if d1.Choice == 0
    return
end

inDirPath = uigetdir;

if inDirPath == 0
    return 
end

%% how many channels

d2 = spbNChannelsDialog;

if d2.NChannels == 0
    return
end

%% tokens

d3 = spbTokensDialog(d2.NChannels);

if isempty(d3.Tokens)
    return
end

%% which output folder

d4 = spbGetFolderDialog('Folder Out', 'Next, navigate to folder where to save stacks.');

if d4.Choice == 0
    return
end

outDirPath = uigetdir;

if outDirPath == 0
    return
end

%% pack

filesChan1 = dir([inDirPath filesep ['*' d3.Tokens{1} '*']]);

h = waitbar(0,sprintf('Packing stack 1 of %d', length(filesChan1)));
for i = 1:length(filesChan1)
    waitbar((i-1)/length(filesChan1),h,sprintf('Packing stack %d of %d', i, length(filesChan1)))
    
    imPathChan1 = filesChan1(i).name;
    
    stackPath0 = strrep(imPathChan1,d3.Tokens{1},'stack');
    [~,stackName] = fileparts(stackPath0);
    stackPath = [stackName '.tif'];
    fullStackPath = [outDirPath filesep stackPath];
    if exist(fullStackPath,'file') == 2
        delete(fullStackPath);
    end
    
    I = imread([inDirPath filesep imPathChan1]);
    imwrite(I, fullStackPath, 'WriteMode', 'append', 'Compression','none');
    
    for j = 2:length(d3.Tokens)
        imPathChanJ = strrep(imPathChan1,d3.Tokens{1},d3.Tokens{j});
        
        I = imread([inDirPath filesep imPathChanJ]);
        imwrite(I, fullStackPath, 'WriteMode', 'append', 'Compression','none');
    end
end
close(h)

%%
clear, clc
disp('Done packing stacks.')