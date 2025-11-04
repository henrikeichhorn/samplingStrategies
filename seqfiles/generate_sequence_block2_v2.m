function generate_sequence_block2_v2(subject, cont1_mapping, cont2_mapping, save_path)
% GENERATE_SEQUENCE_BLOCK2_V2 Creates Block 2 with contingency shift at trial 41
%
% Inputs:
%   subject         - Subject number
%   cont1_mapping   - [4x1] vector for Contingency 1: mapping(scene) = expected_face
%   cont2_mapping   - [4x1] vector for Contingency 2: mapping(scene) = expected_face
%   save_path       - Path to save the sequence file
%
% Block 2 structure:
%   - Trials 1-40: Contingency 1 (shuffled)
%   - Trials 41-80: Contingency 2 (shuffled)
%   - Each half maintains 7/1/1/1 distribution per scene (70/10/10/10%)

% Set random seed based on subject for reproducibility
rng(subject * 1000 + 2);

block_num = 2;
trials_per_half = 40;
trials_per_scene_per_half = 10;
expected_per_scene = 7;
unexpected_per_scene = 1;
n_scenes = 4;

%% PART 1: First 40 trials (Contingency 1) %%
fprintf('Generating Block 2, Part 1 (Contingency 1, trials 1-40)...\n');

% Build contingency matrix for Contingency 1
contingencies_cont1 = zeros(4, 4);
for scene_id = 1:4
    expected_face = cont1_mapping(scene_id);
    for face_id = 1:4
        if face_id == expected_face
            contingencies_cont1(scene_id, face_id) = expected_per_scene;
        else
            contingencies_cont1(scene_id, face_id) = unexpected_per_scene;
        end
    end
end

seqFile_part1 = [];

% Generate trials for each scene (Contingency 1)
for scene_id = 1:n_scenes
    face_ids = [];
    for face_id = 1:4
        n_reps = contingencies_cont1(scene_id, face_id);
        face_ids = [face_ids; repmat(face_id, n_reps, 1)];
    end
    
    % Shuffle the face IDs for this scene
    face_ids = face_ids(randperm(length(face_ids)));
    
    % Create trials
    for trial_in_scene = 1:trials_per_scene_per_half
        trial.scene_ID = scene_id;
        trial.scene_file = sprintf('scene_%d.png', scene_id);
        trial.target_ID = face_ids(trial_in_scene);
        trial.target_file = sprintf('face_%d.png', trial.target_ID);
        
        % Determine expected/unexpected based on Contingency 1
        expected_face = cont1_mapping(scene_id);
        if trial.target_ID == expected_face
            trial.condition = 1; % expected
        else
            trial.condition = 2; % unexpected
        end
        
        trial.scene_position = randi(4);
        trial.ITI_duration = 1.25 + rand() * 0.5;
        trial.ISI_duration = 0.5;
        trial.block = block_num;
        trial.contingency_phase = 1;
        
        seqFile_part1 = [seqFile_part1; struct2table(trial)];
    end
end

% Shuffle Part 1 separately
shuffle_idx_part1 = randperm(trials_per_half);
seqFile_part1 = seqFile_part1(shuffle_idx_part1, :);

%% PART 2: Last 40 trials (Contingency 2) %%
fprintf('Generating Block 2, Part 2 (Contingency 2, trials 41-80)...\n');

% Build contingency matrix for Contingency 2
contingencies_cont2 = zeros(4, 4);
for scene_id = 1:4
    expected_face = cont2_mapping(scene_id);
    for face_id = 1:4
        if face_id == expected_face
            contingencies_cont2(scene_id, face_id) = expected_per_scene;
        else
            contingencies_cont2(scene_id, face_id) = unexpected_per_scene;
        end
    end
end

seqFile_part2 = [];

% Generate trials for each scene (Contingency 2)
for scene_id = 1:n_scenes
    face_ids = [];
    for face_id = 1:4
        n_reps = contingencies_cont2(scene_id, face_id);
        face_ids = [face_ids; repmat(face_id, n_reps, 1)];
    end
    
    % Shuffle the face IDs for this scene
    face_ids = face_ids(randperm(length(face_ids)));
    
    % Create trials
    for trial_in_scene = 1:trials_per_scene_per_half
        trial.scene_ID = scene_id;
        trial.scene_file = sprintf('scene_%d.png', scene_id);
        trial.target_ID = face_ids(trial_in_scene);
        trial.target_file = sprintf('face_%d.png', trial.target_ID);
        
        % Determine expected/unexpected based on Contingency 2
        expected_face = cont2_mapping(scene_id);
        if trial.target_ID == expected_face
            trial.condition = 1; % expected
        else
            trial.condition = 2; % unexpected
        end
        
        trial.scene_position = randi(4);
        trial.ITI_duration = 1.25 + rand() * 0.5;
        trial.ISI_duration = 0.5;
        trial.block = block_num;
        trial.contingency_phase = 2;
        
        seqFile_part2 = [seqFile_part2; struct2table(trial)];
    end
end

% Shuffle Part 2 separately
shuffle_idx_part2 = randperm(trials_per_half);
seqFile_part2 = seqFile_part2(shuffle_idx_part2, :);

%% COMBINE BOTH PARTS %%
seqFile = [seqFile_part1; seqFile_part2];

% Add trial numbers (1-80)
seqFile.trial_num = (1:height(seqFile))';

% Reorder columns
seqFile = seqFile(:, {'trial_num', 'scene_ID', 'scene_file', 'target_ID', ...
                      'target_file', 'condition', 'scene_position', ...
                      'ITI_duration', 'ISI_duration', 'block', 'contingency_phase'});

% Save the sequence file
filename = sprintf('Exp_main_experiment_sub%d_block2.mat', subject);
save(fullfile(save_path, filename), 'seqFile');

fprintf('\nBlock 2 sequence generated for Subject %d\n', subject);
fprintf('Total trials: %d\n', height(seqFile));

% Verification
fprintf('\n=== VERIFICATION ===\n');
fprintf('Part 1 (Contingency 1, trials 1-40):\n');
for s = 1:4
    scene_trials = seqFile(seqFile.scene_ID == s & seqFile.trial_num <= 40, :);
    expected_face = cont1_mapping(s);
    fprintf('  Scene %d → Face %d: %d trials (expected)\n', s, expected_face, sum(scene_trials.target_ID == expected_face));
end

fprintf('\nPart 2 (Contingency 2, trials 41-80):\n');
for s = 1:4
    scene_trials = seqFile(seqFile.scene_ID == s & seqFile.trial_num > 40, :);
    expected_face = cont2_mapping(s);
    fprintf('  Scene %d → Face %d: %d trials (expected)\n', s, expected_face, sum(scene_trials.target_ID == expected_face));
end

end