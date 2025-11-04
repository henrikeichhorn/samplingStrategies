function generate_sequence_block_v2(subject, block_num, contingency_mapping, save_path, block_size)
% GENERATE_SEQUENCE_BLOCK_V2 Creates shuffled trial sequences for a single contingency block
%
% Inputs:
%   subject              - Subject number
%   block_num            - Block number (1, 2, 3, or 4)
%   contingency_mapping  - [4x1] vector where mapping(scene) = expected_face
%   save_path            - Path to save the sequence file
%   block_size           - 'full' (80 trials) or 'half' (40 trials)
%
% This function generates trials with proper counterbalancing

% Set random seed based on subject and block for reproducibility
rng(subject * 1000 + block_num);

% Determine number of trials based on block size
if strcmp(block_size, 'full')
    trials_per_scene = 20;
    expected_per_scene = 14;
    unexpected_per_scene = 2; % per unexpected face
elseif strcmp(block_size, 'half')
    trials_per_scene = 10;
    expected_per_scene = 7;
    unexpected_per_scene = 1; % per unexpected face
else
    error('block_size must be either "full" or "half"');
end

n_scenes = 4;
total_trials = trials_per_scene * n_scenes;

% Build contingency matrix based on mapping
% contingencies(scene, face) = number of trials
contingencies = zeros(4, 4);
for scene_id = 1:4
    expected_face = contingency_mapping(scene_id);
    
    % Set counts for each face
    for face_id = 1:4
        if face_id == expected_face
            contingencies(scene_id, face_id) = expected_per_scene;
        else
            contingencies(scene_id, face_id) = unexpected_per_scene;
        end
    end
end

% Initialize the sequence structure
seqFile = [];

fprintf('Generating Block %d (%s, %d trials)...\n', block_num, block_size, total_trials);

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
        expected_face = contingency_mapping(scene_id);
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
        trial.block = block_num;
        
        % Determine contingency phase based on block
        if block_num == 1
            trial.contingency_phase = 1;
        elseif block_num == 2 || block_num == 3
            % Will be overwritten for block 2 and 3 in their specific functions
            trial.contingency_phase = 0; % placeholder
        elseif block_num == 4
            trial.contingency_phase = 3;
        end
        
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
filename = sprintf('Exp_main_experiment_sub%d_block%d.mat', subject, block_num);
save(fullfile(save_path, filename), 'seqFile');

fprintf('Generated Block %d sequence for Subject %d\n', block_num, subject);
fprintf('Total trials: %d\n', height(seqFile));
fprintf('Scene distribution:\n');
for s = 1:4
    fprintf('  Scene %d: %d trials\n', s, sum(seqFile.scene_ID == s));
end

% Show face distribution per scene
fprintf('\nFace distribution per scene:\n');
for s = 1:4
    fprintf('  Scene %d:\n', s);
    scene_trials = seqFile(seqFile.scene_ID == s, :);
    expected_face = contingency_mapping(s);
    for f = 1:4
        count = sum(scene_trials.target_ID == f);
        percentage = (count / height(scene_trials)) * 100;
        expected_marker = '';
        if f == expected_face
            expected_marker = ' (EXPECTED - 70%)';
        end
        fprintf('    Face %d: %2d trials (%.0f%%)%s\n', f, count, percentage, expected_marker);
    end
end

end