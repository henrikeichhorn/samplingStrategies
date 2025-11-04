# Button-Face Mapping Reference for Instruction Screens

## Overview

The button-face mapping is determined by: `mod(subject - 1, 4) + 1`

This creates 4 groups with different button layouts.

## Complete Mapping Table

| Subject # | Group | J Button | K Button | L Button | Ö Button |
|-----------|-------|----------|----------|----------|----------|
| 1, 5, 9, 13, 17, 21, 25, 29, 33, 37... | 1 | **Face 1** | **Face 2** | **Face 3** | **Face 4** |
| 2, 6, 10, 14, 18, 22, 26, 30, 34, 38... | 2 | **Face 2** | **Face 3** | **Face 4** | **Face 1** |
| 3, 7, 11, 15, 19, 23, 27, 31, 35, 39... | 3 | **Face 3** | **Face 4** | **Face 1** | **Face 2** |
| 4, 8, 12, 16, 20, 24, 28, 32, 36, 40... | 4 | **Face 4** | **Face 1** | **Face 2** | **Face 3** |

## Determining Group for Any Subject

```matlab
group = mod(subject - 1, 4) + 1
```

Examples:
- Subject 1: mod(0, 4) + 1 = **1**
- Subject 2: mod(1, 4) + 1 = **2**
- Subject 3: mod(2, 4) + 1 = **3**
- Subject 4: mod(3, 4) + 1 = **4**
- Subject 5: mod(4, 4) + 1 = **1** (cycles back)

## Four Instruction Screen Versions Needed

### Version 1 (for subjects 1, 5, 9, 13, 17, 21...)
```
Press J for Face 1
Press K for Face 2
Press L for Face 3
Press Ö for Face 4
```

### Version 2 (for subjects 2, 6, 10, 14, 18, 22...)
```
Press J for Face 2
Press K for Face 3
Press L for Face 4
Press Ö for Face 1
```

### Version 3 (for subjects 3, 7, 11, 15, 19, 23...)
```
Press J for Face 3
Press K for Face 4
Press L for Face 1
Press Ö for Face 2
```

### Version 4 (for subjects 4, 8, 12, 16, 20, 24...)
```
Press J for Face 4
Press K for Face 1
Press L for Face 2
Press Ö for Face 3
```

## Visual Layout Suggestion

For each version, create an instruction image showing:

```
┌─────────────────────────────────────────┐
│                                         │
│    When you see an UNEXPECTED face,    │
│    identify it by pressing:             │
│                                         │
│    [Image Face 1]    →    J             │
│                                         │
│    [Image Face 2]    →    K             │
│                                         │
│    [Image Face 3]    →    L             │
│                                         │
│    [Image Face 4]    →    Ö             │
│                                         │
└─────────────────────────────────────────┘
```

Just rotate which face appears in each position based on the group!

## File Naming Convention

I suggest creating instruction files like:

```
instruction_buttons_group1.png
instruction_buttons_group2.png
instruction_buttons_group3.png
instruction_buttons_group4.png
```

Or to match your existing naming:

```
instruction_ver1.png  (already exists - shows face-name associations)
task_block1_ver1.png  (already exists - shows expected/unexpected task)
buttons_ver1.png      (NEW - shows button-face mapping for group 1)
buttons_ver2.png      (NEW - shows button-face mapping for group 2)
buttons_ver3.png      (NEW - shows button-face mapping for group 3)
buttons_ver4.png      (NEW - shows button-face mapping for group 4)
```

## How Your Code Should Load These

In the `FileMatrix_instruction` function (around line 716), you already have logic for loading different instruction versions based on subject. Add similar logic for the button mapping screens:

```matlab
% Determine button mapping group (1-4)
button_group = mod(subject - 1, 4) + 1;

% Load the appropriate button instruction
if button_group == 1
    filename_buttons = 'buttons_ver1.png';
elseif button_group == 2
    filename_buttons = 'buttons_ver2.png';
elseif button_group == 3
    filename_buttons = 'buttons_ver3.png';
elseif button_group == 4
    filename_buttons = 'buttons_ver4.png';
end
```

## Quick Reference for First 20 Subjects

| Subject | Group | J | K | L | Ö | Subject | Group | J | K | L | Ö |
|---------|-------|---|---|---|---|---------|-------|---|---|---|---|
| 1 | 1 | F1 | F2 | F3 | F4 | 11 | 3 | F3 | F4 | F1 | F2 |
| 2 | 2 | F2 | F3 | F4 | F1 | 12 | 4 | F4 | F1 | F2 | F3 |
| 3 | 3 | F3 | F4 | F1 | F2 | 13 | 1 | F1 | F2 | F3 | F4 |
| 4 | 4 | F4 | F1 | F2 | F3 | 14 | 2 | F2 | F3 | F4 | F1 |
| 5 | 1 | F1 | F2 | F3 | F4 | 15 | 3 | F3 | F4 | F1 | F2 |
| 6 | 2 | F2 | F3 | F4 | F1 | 16 | 4 | F4 | F1 | F2 | F3 |
| 7 | 3 | F3 | F4 | F1 | F2 | 17 | 1 | F1 | F2 | F3 | F4 |
| 8 | 4 | F4 | F1 | F2 | F3 | 18 | 2 | F2 | F3 | F4 | F1 |
| 9 | 1 | F1 | F2 | F3 | F4 | 19 | 3 | F3 | F4 | F1 | F2 |
| 10 | 2 | F2 | F3 | F4 | F1 | 20 | 4 | F4 | F1 | F2 | F3 |

## Pattern Recognition

Notice the pattern:
- **Group 1**: Sequential (1,2,3,4)
- **Group 2**: Shift left by 1 (2,3,4,1)
- **Group 3**: Shift left by 2 (3,4,1,2)
- **Group 4**: Shift left by 3 (4,1,2,3)

This is the same rotation pattern used for scene-face counterbalancing!

## Creating the Instruction Screens

### Step-by-Step Process:

1. **Start with your face images** (face_1.png, face_2.png, face_3.png, face_4.png)

2. **Create a template layout** showing 4 faces with 4 buttons

3. **Create 4 versions** by rearranging which face appears in each position:

   **Version 1:** Face 1 with J, Face 2 with K, Face 3 with L, Face 4 with Ö
   
   **Version 2:** Face 2 with J, Face 3 with K, Face 4 with L, Face 1 with Ö
   
   **Version 3:** Face 3 with J, Face 4 with K, Face 1 with L, Face 2 with Ö
   
   **Version 4:** Face 4 with J, Face 1 with K, Face 2 with L, Face 3 with Ö

4. **Add text instructions** like:
   - "Wenn Sie ein unerwartetes Gesicht sehen, identifizieren Sie es:"
   - (or whatever instructions you prefer)

## Testing Your Screens

After creating the screens, test that they're being loaded correctly:

```matlab
for subject = 1:8
    button_group = mod(subject - 1, 4) + 1;
    fprintf('Subject %d → Group %d → buttons_ver%d.png\n', ...
            subject, button_group, button_group);
end
```

Should output:
```
Subject 1 → Group 1 → buttons_ver1.png
Subject 2 → Group 2 → buttons_ver2.png
Subject 3 → Group 3 → buttons_ver3.png
Subject 4 → Group 4 → buttons_ver4.png
Subject 5 → Group 1 → buttons_ver1.png
Subject 6 → Group 2 → buttons_ver2.png
Subject 7 → Group 3 → buttons_ver3.png
Subject 8 → Group 4 → buttons_ver4.png
```

## Important Notes

1. **Face Names**: If your faces have names (Ari, Bob, Cid, Dan), make sure the button instructions use the same names consistently

2. **Face Images**: The face IDs (1,2,3,4) in the button mapping refer to the **same faces** used in the experiment, not different faces for each subject

3. **Keyboard Layout**: The physical keyboard layout is:
   ```
   J K L Ö
   ```
   (four adjacent keys - easy for participants to remember)

4. **Consistency**: Make sure participants see the button mapping during:
   - Initial training (if they need to identify faces)
   - Before each block where ID task is required
   - As a reminder screen if needed

## MATLAB Helper Function

Here's a quick function to tell you which button maps to which face for any subject:

```matlab
function show_button_mapping(subject)
    button_group = mod(subject - 1, 4) + 1;
    mappings = [1,2,3,4; 2,3,4,1; 3,4,1,2; 4,1,2,3];
    mapping = mappings(button_group, :);
    
    fprintf('\nSubject %d (Group %d):\n', subject, button_group);
    fprintf('  J button → Face %d\n', mapping(1));
    fprintf('  K button → Face %d\n', mapping(2));
    fprintf('  L button → Face %d\n', mapping(3));
    fprintf('  Ö button → Face %d\n', mapping(4));
end
```

Usage:
```matlab
show_button_mapping(1)
show_button_mapping(15)
show_button_mapping(23)
```

---

This should give you everything you need to create the instruction screens! Let me know if you need any clarification about specific subjects or want help with the actual screen design.
