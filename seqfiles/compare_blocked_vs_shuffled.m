% COMPARE_BLOCKED_VS_SHUFFLED
% Visual comparison of old blocked design vs new shuffled design

clear all; close all; clc;

%% Simulate OLD approach (all trials of same scene together)
fprintf('==============================================\n');
fprintf('COMPARISON: BLOCKED vs SHUFFLED\n');
fprintf('==============================================\n\n');

% Old approach: 20 trials per scene, all together
old_sequence = [repmat(1, 20, 1); repmat(2, 20, 1); repmat(3, 20, 1); repmat(4, 20, 1)];

fprintf('OLD APPROACH (Blocked by scene):\n');
fprintf('First 40 trials: %s\n', num2str(old_sequence(1:40)'));
fprintf('Last 40 trials:  %s\n', num2str(old_sequence(41:80)'));
fprintf('\nProblem: All Scene 1 trials, then all Scene 2 trials, etc.\n');
fprintf('This makes the scene-face associations too predictable!\n\n');

%% Generate NEW approach (properly shuffled)
fprintf('NEW APPROACH (Properly shuffled):\n');
subject = 42;
save_path = './comparison_test/';

% Generate for test
generate_all_sequences_for_subject(subject, save_path);

% Load Block 1
filename = sprintf('%sExp_main_experiment_sub%d_block1_stable.mat', save_path, subject);
load(filename);
new_sequence = seqFile.scene_ID;

fprintf('First 40 trials: %s\n', num2str(new_sequence(1:40)'));
fprintf('Last 40 trials:  %s\n', num2str(new_sequence(41:80)'));
fprintf('\nBenefit: Scenes are intermixed throughout the block!\n');
fprintf('This maintains unpredictability while keeping 70/10/10/10 structure.\n\n');

%% Create visualization
figure('Position', [100, 100, 1400, 600]);

% OLD APPROACH
subplot(2, 2, 1);
plot(1:80, old_sequence, 'rs-', 'MarkerSize', 8, 'LineWidth', 1.5);
ylim([0.5, 4.5]);
xlabel('Trial Number', 'FontSize', 12);
ylabel('Scene ID', 'FontSize', 12);
title('OLD: Blocked Design', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
set(gca, 'YTick', 1:4);

% Add shaded regions to show blocking
hold on;
fill([0, 20, 20, 0], [0.5, 0.5, 4.5, 4.5], 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
fill([20, 40, 40, 20], [0.5, 0.5, 4.5, 4.5], 'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
fill([40, 60, 60, 40], [0.5, 0.5, 4.5, 4.5], 'b', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
fill([60, 80, 80, 60], [0.5, 0.5, 4.5, 4.5], 'm', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
text(10, 4.3, 'Block 1', 'HorizontalAlignment', 'center', 'FontSize', 10);
text(30, 4.3, 'Block 2', 'HorizontalAlignment', 'center', 'FontSize', 10);
text(50, 4.3, 'Block 3', 'HorizontalAlignment', 'center', 'FontSize', 10);
text(70, 4.3, 'Block 4', 'HorizontalAlignment', 'center', 'FontSize', 10);

% NEW APPROACH
subplot(2, 2, 2);
plot(1:80, new_sequence, 'bo-', 'MarkerSize', 8, 'LineWidth', 1.5);
ylim([0.5, 4.5]);
xlabel('Trial Number', 'FontSize', 12);
ylabel('Scene ID', 'FontSize', 12);
title('NEW: Shuffled Design', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
set(gca, 'YTick', 1:4);

% Scene count comparison for OLD
subplot(2, 2, 3);
scene_counts_old = [sum(old_sequence(1:20)==1), sum(old_sequence(1:20)==2), sum(old_sequence(1:20)==3), sum(old_sequence(1:20)==4);
                    sum(old_sequence(21:40)==1), sum(old_sequence(21:40)==2), sum(old_sequence(21:40)==3), sum(old_sequence(21:40)==4);
                    sum(old_sequence(41:60)==1), sum(old_sequence(41:60)==2), sum(old_sequence(41:60)==3), sum(old_sequence(41:60)==4);
                    sum(old_sequence(61:80)==1), sum(old_sequence(61:80)==2), sum(old_sequence(61:80)==3), sum(old_sequence(61:80)==4)];
bar(scene_counts_old, 'grouped');
xlabel('Trial Bins (20 trials each)', 'FontSize', 12);
ylabel('Number of Trials', 'FontSize', 12);
title('OLD: Scene Distribution', 'FontSize', 14, 'FontWeight', 'bold');
legend('Scene 1', 'Scene 2', 'Scene 3', 'Scene 4', 'Location', 'best');
set(gca, 'XTickLabel', {'1-20', '21-40', '41-60', '61-80'});
grid on;

% Scene count comparison for NEW
subplot(2, 2, 4);
scene_counts_new = [sum(new_sequence(1:20)==1), sum(new_sequence(1:20)==2), sum(new_sequence(1:20)==3), sum(new_sequence(1:20)==4);
                    sum(new_sequence(21:40)==1), sum(new_sequence(21:40)==2), sum(new_sequence(21:40)==3), sum(new_sequence(21:40)==4);
                    sum(new_sequence(41:60)==1), sum(new_sequence(41:60)==2), sum(new_sequence(41:60)==3), sum(new_sequence(41:60)==4);
                    sum(new_sequence(61:80)==1), sum(new_sequence(61:80)==2), sum(new_sequence(61:80)==3), sum(new_sequence(61:80)==4)];
bar(scene_counts_new, 'grouped');
xlabel('Trial Bins (20 trials each)', 'FontSize', 12);
ylabel('Number of Trials', 'FontSize', 12);
title('NEW: Scene Distribution', 'FontSize', 14, 'FontWeight', 'bold');
legend('Scene 1', 'Scene 2', 'Scene 3', 'Scene 4', 'Location', 'best');
set(gca, 'XTickLabel', {'1-20', '21-40', '41-60', '61-80'});
grid on;

sgtitle('Comparison: Blocked vs Shuffled Trial Organization', 'FontSize', 16, 'FontWeight', 'bold');

%% Summary statistics
fprintf('==============================================\n');
fprintf('SUMMARY STATISTICS\n');
fprintf('==============================================\n\n');

fprintf('OLD APPROACH:\n');
fprintf('  Predictability: HIGH (participant knows which scene is next)\n');
fprintf('  Scene changes per block: 3 (only at block boundaries)\n');
fprintf('  Average consecutive same-scene trials: 20\n\n');

% Calculate scene changes for new approach
scene_changes = sum(diff(new_sequence) ~= 0);
fprintf('NEW APPROACH:\n');
fprintf('  Predictability: LOW (scenes intermixed)\n');
fprintf('  Scene changes per block: %d\n', scene_changes);

% Calculate average run length
runs = [];
current_run = 1;
for i = 2:length(new_sequence)
    if new_sequence(i) == new_sequence(i-1)
        current_run = current_run + 1;
    else
        runs = [runs; current_run];
        current_run = 1;
    end
end
runs = [runs; current_run];
fprintf('  Average consecutive same-scene trials: %.1f\n', mean(runs));
fprintf('  Maximum consecutive same-scene trials: %d\n\n', max(runs));

fprintf('==============================================\n\n');

fprintf('The new shuffled design maintains the same probabilistic structure\n');
fprintf('(70/10/10/10) but makes the experiment less predictable and more\n');
fprintf('engaging for participants!\n\n');
