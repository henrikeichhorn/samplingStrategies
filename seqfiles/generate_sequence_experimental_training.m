function generate_sequence_experimental_training(subject, save_path)
% GENERATE_SEQUENCE_EXPERIMENTAL_TRAINING Creates shuffled trial sequences for experimental training
%
% Inputs:
%   subject   - Subject number
%   save_path - Path to save the sequence file
%
% Experimental Training Phase:
%   - 80 trials total (20 per scene)
%   - Uses STABLE contingencies (same as Block 1)
%   - Scene A → Face 1 (70%), Faces 2/3/4 (10% each)
%   - Scene B → Face 2 (70%), Faces 1/3/4 (10% each)
%   - Scene C → Face 3 (70%), Faces 1/2/4 (10% each)
%   - Scene D → Face 4 (70%), Faces 2/3/4 (10% each)
%   - All trials are shuffled together
%   - Face presentation: 2000 ms
%   - Feedback: Visual + Auditory (2000 ms)
%
% This training introduces participants to:
%   1. The scene-face probabilistic associations
%   2. The expected/unexpected task
%   3. The identification task (if unexpected)

% Set random seed based on subject for reproducibility
rng(subject * 1000 + 999); % +999 to differentiate from main experiment blocks

% Define number of trials
trials_per_scene = 20;
n_scenes = 4;
total_trials = trials_per_scene * n_scenes; % 80 trials

% Define contingency structure for STABLE phase
% (Training uses stable contingencies to establish baseline associations)
% Scene → [Face1_count, Face2_count, Face3_count, Face4_count]
contingencies = [
    14, 2, 2, 2;  % Scene A (1) → mostly Face 1
    2, 14, 2, 2;  % Scene B (2) → mostly Face 2
    2, 2, 14, 2;  % Scene C (3) → mostly Face 3
    2, 2, 2, 14;  % Scene D (4) → mostly Face 4
];

% Initialize the sequence structure
seqFile = [];

fprintf('Generating Experimental Training sequence for Subject %d...\n', subject);

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
        trial.block = 0; % 0 indicates training (before main experiment blocks)
        trial.contingency_phase = 1; % stable phase (training uses stable)
        
        % Training-specific flag
        trial.is_training = true;
        
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
                      'ITI_duration', 'ISI_duration', 'block', 'contingency_phase', 'is_training'});

% Save the sequence file
filename = sprintf('Exp_experimental_training_sub%d.mat', subject);
save(fullfile(save_path, filename), 'seqFile');

fprintf('Generated experimental training sequence for Subject %d\n', subject);
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
    for f = 1:4
        count = sum(scene_trials.target_ID == f);
        percentage = (count / height(scene_trials)) * 100;
        expected_marker = '';
        if count == 14
            expected_marker = ' (EXPECTED - 70%)';
        end
        fprintf('    Face %d: %2d trials (%.0f%%)%s\n', f, count, percentage, expected_marker);
    end
end

% Show examples of shuffling
fprintf('\nExample trial order (first 20 trials):\n');
fprintf('Trial: ');
fprintf('%2d ', seqFile.trial_num(1:20));
fprintf('\n');
fprintf('Scene: ');
fprintf('%2d ', seqFile.scene_ID(1:20));
fprintf('\n');
fprintf('Face:  ');
fprintf('%2d ', seqFile.target_ID(1:20));
fprintf('\n');

fprintf('\nNote: Scenes are shuffled throughout training!\n');

end
