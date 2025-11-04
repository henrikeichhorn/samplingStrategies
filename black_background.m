function black_background(folder)

save_path = [folder 'Black\'];
if exist(save_path) == 0
    mkdir(save_path);
else
    delete([save_path '*'])
end

f = dir([folder '*.png']);
tstim = length(f);
sprintf('%d files found\n',tstim)

% read all the images and crop each one of them and save it
for i = 1:tstim
    sprintf('File %d...\n',i);
    [im, ~, alpha] = imread([folder f(i).name]);
%%% end of Selim Onat's code
    
% where alpha is 0 (transparent because of normalized images), set the
% pixel values in all 3 RGB-channels to 255 so that the background is
% black like in the experiment
for i_row = 1:size(alpha,1) % rows of alpha
    for j_col = 1:size(alpha,2) % columns of alpha
        if isequal(alpha(i_row, j_col),0) % background (grey)
           for i_dim = 1:size(im,3) % dimensions of images
               im(i_row,j_col,i_dim) = 0; % set to black
           end
        end
    end
end

% crop image
% im_cropped = im(y_start:y_end, x_start:x_end, :);
    
%imwrite(im_cropped, [save_path regexprep(f(i).name,'png$','bmp')],'bmp'); % Selim's code
imwrite(im, [save_path f(i).name], 'png'); % Selim's code

clear im alpha
end
end