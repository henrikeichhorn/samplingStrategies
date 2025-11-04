function generate_sequence_stable(subject, block, save_path)
% GENERATE_SEQUENCE_STABLE Creates shuffled trial sequences for stable contingency phase
%
% Inputs:
%   subject   - Subject number
%   block     - Block number (1, 2, or 3)
%   save_path - Path to save the sequence file
%
% For stable phase:
%   Scene A → Face 1 (70%), Faces 2/3/4 (10% each)
%   Scene B → Face 2 (70%), Faces 1/3/4 (10% each)
%   Scene C → Face 3 (70%), Faces 1/2/4 (10% each)
%   Scene D → Face 4 (70%), Faces 1/2/3 (10% each)
%
% Each block has 80 trials total (20 per scene)
% Trials are fully shuffled while maintaining the probabilistic structure

% Set random seed based on subject and block for reproducibility
rng(subject * 1000 + block);

% Define number of trials
trials_per_scene = 20;
n_scenes = 4;
total_trials = trials_per_scene * n_scenes; % 80 trials

% Define contingency structure for stable phase
% Scene → [Face1_count, Face2_count, Face3_count, Face4_count]
contingencies = [
    14, 2, 2, 2;  % Scene A (1) → mostly Face 1
    2, 14, 2, 2;  % Scene B (2) → mostly Face 2
    2, 2, 14, 2;  % Scene C (3) → mostly Face 3
    2, 2, 2, 14;  % Scene D (4) → mostly Face 4
];

% Initialize the sequence structure
seqFile = [];
trial_counter = 1;

% Generate trials for each scene
for scene_id = 1:n_scenes
    % Generate the face IDs according to the contingency
    face_ids = [];
    for face_id = 1:4
        n_reps = contingencies(scene_id, face_id);
        face_ids = [face_ids; repmat(face_id, n_reps, 1)];
    end
    
    % Shuffle the face IDs for this scene
    face_ids = face_ids(randperm(length(face_ids)));
    
    % Create trials for this scene
    for trial_in_scene = 1:trials_per_scene
        % Scene information
        trial.scene_ID = scene_id;
        trial.scene_file = sprintf('scene_%d.png', scene_id);
        
        % Target face information
        trial.target_ID = face_ids(trial_in_scene);
        trial.target_file = sprintf('face_%d.png', trial.target_ID);
        
        % Determine if this is expected (1) or unexpected (2)
        % Expected = face matches the most probable face for this scene
        expected_face = find(contingencies(scene_id, :) == 14);
        if trial.target_ID == expected_face
            trial.condition = 1; % expected
        else
            trial.condition = 2; % unexpected
        end
        
        % Scene position (random corner: 1=top-left, 2=top-right, 3=bottom-left, 4=bottom-right)
        trial.scene_position = randi(4);
        
        % Jittered ITI (inter-trial interval) between 1.25 and 1.75 seconds
        trial.ITI_duration = 1.25 + rand() * 0.5;
        
        % Fixed ISI (inter-stimulus interval) of 0.5 seconds
        trial.ISI_duration = 0.5;
        
        % Block and phase information
        trial.block = block;
        trial.contingency_phase = 1; % stable phase
        
        % Add to sequence
        seqFile = [seqFile; struct2table(trial)];
    end
end

% CRITICAL: Shuffle all trials together to mix scenes
shuffle_idx = randperm(total_trials);
seqFile = seqFile(shuffle_idx, :);

% Add trial numbers after shuffling
seqFile.trial_num = (1:total_trials)';

% Reorder columns for clarity
seqFile = seqFile(:, {'trial_num', 'scene_ID', 'scene_file', 'target_ID', ...
                      'target_file', 'condition', 'scene_position', ...
                      'ITI_duration', 'ISI_duration', 'block', 'contingency_phase'});

% Save the sequence file
filename = sprintf('Exp_main_experiment_sub%d_block%d_stable.mat', subject, block);
save(fullfile(save_path, filename), 'seqFile');

fprintf('Generated stable phase sequence for Subject %d, Block %d\n', subject, block);
fprintf('Total trials: %d\n', height(seqFile));
fprintf('Scene distribution:\n');
for s = 1:4
    fprintf('  Scene %d: %d trials\n', s, sum(seqFile.scene_ID == s));
end

end
