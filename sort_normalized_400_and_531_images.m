%% script for splitting up normalized 400x400 and 531x531 into two separate folders and also
% rename them by removing their size from the filename
% e.g., '12_34_66_400' -> 400x400-folder and '12_34_66'

%%%% doesn't work!!! I did sorting and renaming manually %%%% (11.11.2021)

% path with normalized images
path = 'C:\Users\Annika Garlichs\Documents\UKEbox_backup\faces\male\Exp2.7\4faces_final_raw\all_renamed\normalization_400_AND_531\ALL_transparent\corrected_white_spots\Normalized\split_up\400x400\';

cd(path)

% (c) Selim Onat
list = dir([path '*.png']); 
tstim = length(list);
sprintf('%d files found\n',tstim)

for i_stim = 1:tstim
    old_name = list(i_stim).name; % '12_80_20_400.png' (without path)
    if list(i_stim).name(2) == '_' % 1 2 3 4 images
       new_name = [list(i_stim).name(1) '.png'];
    elseif list(i_stim).name(3) == '_' % 12 ...
       new_name = [list(i_stim).name(1:8) '.png'];
    end

    % rename file
    movefile old_name new_name
end
