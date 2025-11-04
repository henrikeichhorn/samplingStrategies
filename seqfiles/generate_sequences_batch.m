function generate_sequences_batch(subject_list, save_path)
% GENERATE_SEQUENCES_BATCH Generates sequences for multiple subjects
%
% This is a convenience function that loops through multiple subjects
% and generates all sequences for each one.
%
% Inputs:
%   subject_list - Vector of subject numbers (e.g., 1:30 or [1 3 5 7])
%   save_path    - Path to save all sequence files
%
% Usage:
%   % Generate for subjects 1-5
%   generate_sequences_batch(1:5, 'C:/experiment/sequences/')
%
%   % Generate for specific subjects
%   generate_sequences_batch([1 3 5 7 9], 'C:/experiment/sequences/')
%
%   % Generate for all 30 subjects
%   generate_sequences_batch(1:30, 'C:/experiment/sequences/')

% Check inputs
if ~isnumeric(subject_list) || isempty(subject_list)
    error('subject_list must be a numeric vector of subject numbers');
end

if ~exist(save_path, 'dir')
    mkdir(save_path);
    fprintf('Created directory: %s\n', save_path);
end

% Get total number of subjects
n_subjects = length(subject_list);

fprintf('\n╔════════════════════════════════════════════════╗\n');
fprintf('║   BATCH SEQUENCE GENERATION                    ║\n');
fprintf('╚════════════════════════════════════════════════╝\n\n');
fprintf('Generating sequences for %d subject(s)\n', n_subjects);
fprintf('Subject list: %s\n', mat2str(subject_list));
fprintf('Save path: %s\n\n', save_path);

% Track timing
batch_start_time = tic;

% Loop through subjects
for i = 1:n_subjects
    subject = subject_list(i);
    
    fprintf('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    fprintf('  Processing Subject %d (%d/%d)\n', subject, i, n_subjects);
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    try
        % Generate all sequences for this subject
        subject_start_time = tic;
        generate_all_sequences_for_subject(subject, save_path);
        subject_elapsed = toc(subject_start_time);
        
        fprintf('\n✓ Subject %d complete (%.1f seconds)\n', subject, subject_elapsed);
        
    catch ME
        fprintf('\n✗ ERROR generating sequences for Subject %d:\n', subject);
        fprintf('  %s\n', ME.message);
        fprintf('  Continuing with next subject...\n');
    end
end

% Report completion
batch_elapsed = toc(batch_start_time);

fprintf('\n\n╔════════════════════════════════════════════════╗\n');
fprintf('║   BATCH GENERATION COMPLETE                    ║\n');
fprintf('╚════════════════════════════════════════════════╝\n\n');
fprintf('Total subjects processed: %d\n', n_subjects);
fprintf('Total time: %.1f seconds (%.1f seconds per subject)\n', ...
    batch_elapsed, batch_elapsed/n_subjects);
fprintf('Files saved to: %s\n\n', save_path);

% List generated files
fprintf('Generated files per subject:\n');
fprintf('  • Exp_experimental_training_sub[N].mat\n');
fprintf('  • Exp_main_experiment_sub[N]_block1_stable.mat\n');
fprintf('  • Exp_main_experiment_sub[N]_block2.mat\n');
fprintf('  • Exp_main_experiment_sub[N]_block3_transition.mat\n\n');

% Verify files
fprintf('Verifying file generation...\n');
missing_files = false;
for subject = subject_list
    files_to_check = {
        sprintf('Exp_experimental_training_sub%d.mat', subject);
        sprintf('Exp_main_experiment_sub%d_block1_stable.mat', subject);
        sprintf('Exp_main_experiment_sub%d_block2.mat', subject);
        sprintf('Exp_main_experiment_sub%d_block3_transition.mat', subject);
    };
    
    for f = 1:length(files_to_check)
        if ~exist(fullfile(save_path, files_to_check{f}), 'file')
            fprintf('  ✗ Missing: %s\n', files_to_check{f});
            missing_files = true;
        end
    end
end

if ~missing_files
    fprintf('  ✓ All files generated successfully!\n\n');
else
    fprintf('\n  ⚠ Some files are missing. Check error messages above.\n\n');
end

fprintf('Ready for experiment!\n\n');

end
