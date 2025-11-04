%% Cutting 400x400-face images smaller for Meadows
% get images from 100-300 (x-axis), 45-355 (y-axis)

% get all images inside the folder
%%%% snippet from (c) Selim Onat: NormalizeMeanStd_WithoutSmoothing %%%%

function cropping_images(folder)
save_path = [folder 'Cropped\'];
if exist(save_path) == 0
    mkdir(save_path);
else
    delete([save_path '*'])
end

f = dir([folder '*.png']);
tstim = length(f);
sprintf('%d files found\n',tstim)

%read all the images and crop each one of them and save it
for i = 1:tstim
    sprintf('File %d...\n',i);
    [im map alpha] = imread([Folder f(i).name]);
    
    imwrite(im, [ save_path regexprep(f(i).name,'png$','bmp')],'bmp');
    imwrite(im, [save_path f(i).name], 'png');
    
end
end