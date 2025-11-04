function [cont1_mapping, cont2_mapping, cont3_mapping] = get_counterbalancing_scheme(subject)
% GET_COUNTERBALANCING_SCHEME Returns the scene-face mappings for all 3 contingencies
%
% This function implements counterbalancing across subjects so that all possible
% face-scene pairings are balanced across participants.
%
% Inputs:
%   subject - Subject number
%
% Outputs:
%   cont1_mapping - [4x1] vector where cont1_mapping(scene) = expected_face for Contingency 1
%   cont2_mapping - [4x1] vector for Contingency 2
%   cont3_mapping - [4x1] vector for Contingency 3
%
% Counterbalancing scheme (based on mod(subject, 4)):
%   Group 1 (subject mod 4 = 1): Scene 1→Face 1, Scene 2→Face 2, Scene 3→Face 3, Scene 4→Face 4
%   Group 2 (subject mod 4 = 2): Scene 1→Face 2, Scene 2→Face 3, Scene 3→Face 4, Scene 4→Face 1
%   Group 3 (subject mod 4 = 3): Scene 1→Face 3, Scene 2→Face 4, Scene 3→Face 1, Scene 4→Face 2
%   Group 4 (subject mod 4 = 0): Scene 1→Face 4, Scene 2→Face 1, Scene 3→Face 2, Scene 4→Face 3
%
% For each group, contingencies shift by rotating forward:
%   Contingency 2 = rotate Contingency 1 forward by 1
%   Contingency 3 = rotate Contingency 1 forward by 2

% Determine counterbalancing group
group = mod(subject - 1, 4) + 1; % Maps subject to 1, 2, 3, or 4

% Define Contingency 1 mapping based on group
switch group
    case 1
        % Scene 1→Face 1, Scene 2→Face 2, Scene 3→Face 3, Scene 4→Face 4
        cont1_mapping = [1; 2; 3; 4];
    case 2
        % Scene 1→Face 2, Scene 2→Face 3, Scene 3→Face 4, Scene 4→Face 1
        cont1_mapping = [2; 3; 4; 1];
    case 3
        % Scene 1→Face 3, Scene 2→Face 4, Scene 3→Face 1, Scene 4→Face 2
        cont1_mapping = [3; 4; 1; 2];
    case 4
        % Scene 1→Face 4, Scene 2→Face 1, Scene 3→Face 2, Scene 4→Face 3
        cont1_mapping = [4; 1; 2; 3];
end

% Generate Contingency 2 by rotating forward by 1
cont2_mapping = circshift(cont1_mapping, -1);

% Generate Contingency 3 by rotating forward by 2
cont3_mapping = circshift(cont1_mapping, -2);

% Display the mappings
fprintf('\n=== Counterbalancing for Subject %d (Group %d) ===\n', subject, group);
fprintf('\nContingency 1:\n');
for scene = 1:4
    fprintf('  Scene %d → Face %d (70%%)\n', scene, cont1_mapping(scene));
end

fprintf('\nContingency 2 (SHIFT 1):\n');
for scene = 1:4
    fprintf('  Scene %d → Face %d (70%%)\n', scene, cont2_mapping(scene));
end

fprintf('\nContingency 3 (SHIFT 2):\n');
for scene = 1:4
    fprintf('  Scene %d → Face %d (70%%)\n', scene, cont3_mapping(scene));
end
fprintf('\n');

end