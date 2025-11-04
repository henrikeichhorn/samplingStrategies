function generate_all_sequences_for_subject_v2(subject, save_path)
% GENERATE_ALL_SEQUENCES_FOR_SUBJECT_V2 Generates all trial sequences with counterbalancing
%
% This function creates all necessary sequence files for the main experiment:
%   - Block 1: Contingency 1 (80 trials, shuffled)
%   - Block 2: Mixed (40 trials Cont 1 + 40 trials Cont 2, each half shuffled separately)
%   - Block 3: Mixed (40 trials Cont 2 + 40 trials Cont 3, each half shuffled separately)
%   - Block 4: Contingency 3 (40 trials, shuffled)
%
% NEW: Implements counterbalancing of scene-face mappings across subjects
%
% Inputs:
%   subject   - Subject number
%   save_path - Path to save all sequence files
%
% Usage:
%   generate_all_sequences_for_subject_v2(1, 'C:/experiment/sequences/')

% Create save directory if it doesn't exist
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

fprintf('\n========================================\n');
fprintf('Generating sequences for Subject %d\n', subject);
fprintf('========================================\n\n');

% Get counterbalanced scene-face mappings for this subject
[cont1_mapping, cont2_mapping, cont3_mapping] = get_counterbalancing_scheme(subject);

%% Generate Block 1 (Contingency 1, 80 trials, fully shuffled)
fprintf('\n--- BLOCK 1 ---\n');
generate_sequence_block_v2(subject, 1, cont1_mapping, save_path, 'full');

%% Generate Block 2 (40 Cont1 + 40 Cont2, each half shuffled)
fprintf('\n--- BLOCK 2 ---\n');
generate_sequence_block2_v2(subject, cont1_mapping, cont2_mapping, save_path);

%% Generate Block 3 (40 Cont2 + 40 Cont3, each half shuffled)
fprintf('\n--- BLOCK 3 ---\n');
generate_sequence_block3_v2(subject, cont2_mapping, cont3_mapping, save_path);

%% Generate Block 4 (Contingency 3, 40 trials, fully shuffled)
fprintf('\n--- BLOCK 4 ---\n');
generate_sequence_block_v2(subject, 4, cont3_mapping, save_path, 'half');

fprintf('\n========================================\n');
fprintf('All sequences generated successfully!\n');
fprintf('Files saved to: %s\n', save_path);
fprintf('========================================\n\n');

%% Display summary
fprintf('Summary:\n');
fprintf('  Block 1: Contingency 1 (80 trials, fully shuffled)\n');
fprintf('  Block 2: Contingency shift at trial 41\n');
fprintf('           - Trials 1-40: Contingency 1 (shuffled)\n');
fprintf('           - Trials 41-80: Contingency 2 (shuffled)\n');
fprintf('  Block 3: Contingency shift at trial 41\n');
fprintf('           - Trials 1-40: Contingency 2 (shuffled)\n');
fprintf('           - Trials 41-80: Contingency 3 (shuffled)\n');
fprintf('  Block 4: Contingency 3 (40 trials, fully shuffled)\n');
fprintf('\nEach block maintains the probabilistic structure:\n');
fprintf('  - 70%% expected face per scene\n');
fprintf('  - 10%% each unexpected face\n');
fprintf('  - Scenes are intermixed within each shuffled section\n');
fprintf('  - Scene-face mappings are counterbalanced across subjects\n\n');

end