%%% imscramble_one_image

%%% adjust %%%
% I will use ONE noise level:
clear
noise = [0.4]; % 40 noise because of 100ms; for 120ms, we would try 50% noise

% subject = [1:2]; % if participants get different images (noise)

%%%
% Path business.
[~, hostname]             = system('hostname');
p.hostname                = deblank(hostname); % deletes blank character at the end of string
if strcmp(p.hostname,'stimpc1') %triostim1 % change
   p.path.baselocation       = 'D:\garlichs\'; % change
   message = 'You should not be using this script! Stimuli for all participants have already been created on the laptop.';
   error(message) % stop this script
elseif strcmp(p.hostname,'isn842afd3b7267') % Annika's HP
   p.path.baselocation       = 'C:\Users\Annika Garlichs\Documents\UKEbox_backup\';
   % path with normalized 400x400 images that have been corrected for weird white spots AND normalized again with Selim's code!
   image_path                = [p.path.baselocation 'faces\male\Exp2.7\4faces_final_raw\all_renamed\1_2_3_4\552x552\Transparent\Normalized\'];
   % all participants get the same images for the calibration
   save_path                 = [p.path.baselocation 'faces\male\Exp2.7\4faces_final_raw\all_renamed\1_2_3_4\552x552\Transparent\Normalized\scrambled\'];
end

% read in 100% images (identical for everyone)
Ari = imread([image_path '1.png']);
Bob = imread([image_path '2.png']);
Cid = imread([image_path '3.png']);
Dan = imread([image_path '4.png']);

for i_noise = 1:size(noise,1)
    % prepare for filenaming according to noise level
    noise_level = sprintf('%s0', num2str(noise(i_noise))); % 0.4; add a 0 afterwards
    noise_level = noise_level(3:4); % 40

    % define new filename for each scrambled image
    filename_Ari = sprintf('1_noise%s.png', noise_level);
    filename_Bob = sprintf('2_noise%s.png', noise_level);
    filename_Cid = sprintf('3_noise%s.png', noise_level);
    filename_Dan = sprintf('4_noise%s.png', noise_level);
    Ari_scrambled = imscramble(Ari, noise(i_noise),'range'); % add noise
    Bob_scrambled = imscramble(Bob, noise(i_noise),'range'); % add noise
    Cid_scrambled = imscramble(Cid, noise(i_noise),'range'); % add noise
    Dan_scrambled = imscramble(Dan, noise(i_noise),'range'); % add noise
    
    % save scrambled image
    imwrite(Ari_scrambled, [save_path filename_Ari]); 
    imwrite(Bob_scrambled, [save_path filename_Bob]); 
    imwrite(Cid_scrambled, [save_path filename_Cid]); 
    imwrite(Dan_scrambled, [save_path filename_Dan]); 
    
    % clear for safety
    clear filename_Ari filename_Bob filename_Cid filename_Dan
    clear Ari_scrambled Bob_scrambled Cid_scrambled Dan_scrambled
end % end of 100% images
