%% Convert RGB scenes to gray scale (fMRI experiment AND localizer scenes)
% for ANY number of files in a folder! (19.10.2021) (taken from Selim Onat)
% IMPORTANT: Images need the same dimensions! (e.g., 400x400)

%%% NOT USED !!! %%%

% converts any number of images 1) into greyscale and then 2) normalizes
% them with the SHINE toolbox
% (c) Annika Garlichs
% principle of taking any file number taken from (c) Selim Onat (code:
% NormalizeMeanStd)

clear

% path with RGB images
% path = 'C:\Users\Annika Garlichs\Documents\UKEbox_backup\scenes\Exp2_7_final\fMRI_experiment\SUN_only_supermarketotherdatabase\normalized_with_localizer_scenes\400x400\';
path = 'C:\Users\Annika Garlichs\Documents\UKEbox_backup\scenes\Exp2_7_final\fMRI_experiment\SUN_only_supermarketotherdatabase\normalized_with_localizer_scenes\531x531\';

% path to save grey-scale images
save_path_gray = [path 'gray\'];
save_path_norm = [path 'gray\Normalized\'];

if exist(save_path_gray) == 0
   mkdir(save_path_gray);
else
   delete([save_path_gray '*'])
end

if exist(save_path_norm) == 0
   mkdir(save_path_norm);
else
   delete([save_path_norm '*'])
end

f = dir([path '*.png']);
tstim = length(f);
sprintf('%d files found\n',tstim)

% read all the images & convert them to grayscale
for i = 1:tstim
    sprintf('File %d...\n',i);
    images{i} = imread([path f(i).name]);
    % conversion to grayscale
    images_gray{i} = rgb2gray(images{i}); % this format (images_gray) is needed for functions like sfMatch
    
    % save grayscale image
    file_name = [f(i).name];
    imwrite(images_gray{i}, [save_path_gray f(i).name]);
end

% lumMatch
    
%% different normalizations and saving of the normalized images
images_gray_lumMatch = lumMatch(images_gray); % lumMatch
images_gray_histMatch = histMatch(images_gray); % histMatch
images_gray_sfMatch = sfMatch(images_gray); % sfMatch
images_gray_specMatch = specMatch(images_gray); %specMatch

% save images
for i = 1:tstim
    imwrite(images_gray_lumMatch{1,i}, [save_path_norm 'lumMatch_' f(i).name]);
    imwrite(images_gray_histMatch{1,i}, [save_path_norm 'histMatch_' f(i).name]);
    imwrite(images_gray_histMatch{1,i}, [save_path_norm 'sfMatch_' f(i).name]);
    imwrite(images_gray_histMatch{1,i}, [save_path_norm 'specMatch_' f(i).name]);
end

%% check whether luminance is really the same for all histMatch images
for i = 1:tstim
    lum_mean = mean2(images_gray_histMatch{1,i});
    sprintf('Luminance for picture %i is %2d', i, lum_mean)
end

%% RDM and MDS for histMatch normalized images
% pixel_vector = horzcat(supermarket_grey_histMatch(:), bar_grey_histMatch(:), office_grey_histMatch(:), ...
%                        library_grey_histMatch(:), gymnasium_grey_histMatch(:), ...
%                        restaurant_grey_histMatch(:), swimming_pool_grey_histMatch(:), ...
%                        theater_grey_histMatch(:), reception_grey_histMatch(:));
% 
% pixel_vector_pdist = pdist(pixel_vector', 'correlation'); % For the RDM, the distance between each row of act_vector with each other row
% 
% %% Create unranked RDM
% pixel_RDM = squareform(pixel_vector_pdist);
% 
% %% make a classical and non-classical MDS analysis
% [pixel_cmds] = cmdscale(double(pixel_RDM), 2);
% [pixel_cmds_3d] = cmdscale(double(pixel_RDM), 3);
% %[pixel_mds]  = mdscale(double(pixel_RDM), 2);
% 
% %% plot RDM and MDS
% label_names = {'sup'; 'bar'; 'off'; 'lib'; 'gym'; 'res'; 'swi'; 'the'; 'rec'};
% 
% figure;
% subplot(1,3,1);
% colormap(jet); % 0 = blue; 1 = red
% imagesc(pixel_RDM);
% colorbar;
% title('RDM unranked grey histMatch');
% yticks(1:9); % adjust according to RDM size
% xticks(1:9);
% xticklabels(label_names);
% yticklabels(label_names);
% 
% % 2D MDS
% subplot(1,3,2);
% plot(pixel_cmds(:,1),pixel_cmds(:,2),'o')
% hold on
% text(pixel_cmds(:,1)+0.001,pixel_cmds(:,2)+0.001,label_names,'fontsize',10)
% title_pixel_cmds_2d = ['classical MDS (2D) grey histMatch'];
% title(title_pixel_cmds_2d);
% axis square
% xlabel 'Dimension 1'
% ylabel 'Dimension 2'
% 
% % 3D MDS 
% subplot(1,3,3);
% plot3(pixel_cmds_3d(:,1),pixel_cmds_3d(:,2),pixel_cmds_3d(:,3),'o')
% hold on
% text(pixel_cmds_3d(:,1)+0.005,pixel_cmds_3d(:,2)+0.005,pixel_cmds_3d(:,3)+0.005,label_names,'fontsize',10)
% title_pixel_cmds_3d = ['classical MDS (3D) grey histMatch'];
% title(title_pixel_cmds_3d);
% axis square
% axis equal
% xlabel 'Dimension 1'
% ylabel 'Dimension 2'
% zlabel 'Dimension 3'
% 
% % save RDM
% save([save_path_gray 'Pixel_RDM_grey_histMatch.mat'],'pixel_RDM')
% 
% % save figure with RDM and 2D and 3D MDS
% saveas(gcf, [save_path_gray 'Pixel_MDS_2D_3D_grey_histMatch.fig']);
% saveas(gcf, [save_path_gray 'Pixel_MDS_2D_3D_grey_histMatch.png']);
% 
% %% mean luminance
% supermarket_lum_mean = mean2(supermarket_grey_histMatch);
% bar_lum_mean = mean2(bar_grey_histMatch);
% office_lum_mean = mean2(office_grey_histMatch);
% library_lum_mean = mean2(library_grey_histMatch);
% gymnasium_lum_mean = mean2(gymnasium_grey_histMatch);
% restaurant_lum_mean = mean2(restaurant_grey_histMatch);
% swimming_pool_lum_mean = mean2(swimming_pool_grey_histMatch);
% theater_lum_mean = mean2(theater_grey_histMatch);
% reception_lum_mean = mean2(reception_grey_histMatch);
% 
% sprintf('The mean luminance of supermarket is %d.', supermarket_lum_mean)
% sprintf('The mean luminance of bar is %d.', bar_lum_mean)
% sprintf('The mean luminance of office is %d.', office_lum_mean)
% sprintf('The mean luminance of library is %d.', library_lum_mean)
% sprintf('The mean luminance of gymnasium is %d.', gymnasium_lum_mean)
% sprintf('The mean luminance of restaurant is %d.', restaurant_lum_mean)
% sprintf('The mean luminance of swimming pool is %d.', swimming_pool_lum_mean)
% sprintf('The mean luminance of theater is %d.', theater_lum_mean)
% sprintf('The mean luminance of reception is %d.', reception_lum_mean)