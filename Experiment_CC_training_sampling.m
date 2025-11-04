function [p] = Experiment_CC_training_sampling(subject,path_experiment_material)

%% Experiment CC: Experimental Training

% Participants see a scene cue in one corner of the screen.
% After a 0.5s blank (ISI), a face is presented for 2000 ms or until button press.
% The first task is to indicate whether the presented face was expected or
% unexpected based on learned scene-face contingencies (70/10/10/10%).
% If they answer 'unexpected', a question mark prompts them to 
% identify the face as one of the four learned identities. 
% Visual + Auditory feedback (correct/incorrect/too slow) is provided on every trial.

% Training uses stable contingencies:
% - Scene A → Face 1 (70%), others (10% each)
% - Scene B → Face 2 (70%), others (10% each)
% - Scene C → Face 3 (70%), others (10% each)
% - Scene D → Face 4 (70%), others (10% each)

% There must be a ready-to-be-read-in seqFile for each participant 
% containing:
% 1. scene_ID
% 2. scene_file
% 3. target_ID
% 4. target_file (i.e., filename)
% 5. condition (1 = expected, 2 = unexpected)
% 6. scene_position
% 7. ITI_duration (jittered)
% 8. ISI_duration (0.5)
% 9. block (0 = training)
% 10. contingency_phase (1 = stable)
% 11. is_training (true)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rng('shuffle'); % based on the current time, always creates new seed to use
                % random positions for the question mark for the ID task

debug          = 0;

Screen('Preference', 'SkipSyncTests', 2);

% clear everything
clear mex global functions

% load the GETSECS mex files so call them at least once 
GetSecs;
WaitSecs(0.001);
p                   = [];
n_images_and_trials = 80; % number of trials in seqFile

SetParams;
SetPTB;

%% init some variables so that they are global
t                   = [];
nTrial              = 0;
TimeEndStim         = [];
p_var_event_count   = 0;

%% save again the parameter file
save(p.path.path_param,'p');

%% initialize sound
info = audiodevinfo;
info_cell = struct2cell(info.output);
% select last audio output available for current machine
% (you can manually change this to your desired output devide number!)
audio_device = info_cell{end,end,end};
soundP   = MATLABAudioInit(audio_device,44100,1000,0.5,2,0.1);
p.sound = soundP;

%% start
PresentStimuli;

WaitSecs('UntilTime', TimeEndStim); % wait until last trial of former block 
                                    % is over
ShowInstruction(4,0); % Danke!

%% trim the log file and sav
% shift the time so that the first timestamp is equal to zero
first_timepoint = p.out.log{1};
for log_entries = 1:size(p.out.log,1)
    p.out.log{log_entries,1} = p.out.log{log_entries,1} - first_timepoint;
end

save(p.path.path_param,'p');

% move the file to its final location.
movefile(p.path.subject,p.path.finalsubject);

% close everything down
cleanup;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PresentStimuli
        TimeEndStim       = GetSecs; % this is NOW
        % This is the main loop.
        for nTrial  = 1:p.presentation.tTrial          
            if nTrial == 1
               ShowInstruction(1,1); % reminder faces
               ShowInstruction(2,1); % instruction
               ShowInstruction(3,0); % training starts
               TimeEndStim       = GetSecs;  
            end
            
            % Get the variables that the Trial function needs. 
            scene_id              = p.presentation.scene_id{nTrial};
            scene_file            = p.presentation.scene_file{nTrial};
            target_id             = p.presentation.target_id{nTrial};
            target_file           = p.presentation.target_file{nTrial};
            condition             = p.presentation.condition{nTrial};
            scene_pos             = p.presentation.scene_pos{nTrial};
            block_id              = p.presentation.block_id{nTrial};
            contingency_phase     = p.presentation.contingency_phase{nTrial};
            ITI                   = p.duration.ITI{nTrial};
            ISI                   = p.duration.ISI{nTrial};

            % Start to monitor keypresses.
            KbQueueCreate(p.ptb.device);
            KbQueueStart(p.ptb.device);
            
            trial_OnsetTime       = TimeEndStim;
            
            % Start with the trial
            fprintf('Trial %d of %d; scene_id: %d; target_id: %d\n', nTrial, p.presentation.tTrial, scene_id, target_id);
            [TimeEndStim] = Trial(nTrial, trial_OnsetTime, scene_id, scene_file, target_id, target_file, condition, scene_pos, ITI, ISI, block_id, contingency_phase);
        end
    end
    
    function [TimeEndStim] = Trial(nTrial, trial_OnsetTime, scene_id, scene_file, target_id, target_file, condition, scene_pos, ITI, ISI, block_id, contingency_phase)
           %% get all the times for current trial
           TimeITIOnset        = trial_OnsetTime; % 1. ITI
           TimeSceneOnset      = trial_OnsetTime + ITI; % 2. scene cue
           TimeISIOnset        = trial_OnsetTime + ITI + p.duration.scene; % 3. ISI (blank)
           TimeStimOnset       = trial_OnsetTime + ITI + p.duration.scene + ISI; % 4. face
           TimeFeedbackOnset   = trial_OnsetTime + ITI + p.duration.scene + ISI + p.duration.target; % 5. feedback onset

           %% 1. Fixation Onset = InterTrialInterval
           TimeITIOn = Screen('Flip', p.ptb.w, TimeITIOnset, 0);
           Logfile(TimeITIOn, 1, nTrial, 0, 0, 0, 0, condition, 0, 0, 0, 0, block_id, contingency_phase);
           
           %% 2. Scene Cue
           % show scene image
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_scenes(nTrial), [], p.ptb.bottomrect{scene_pos});
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeSceneOn = Screen('Flip', p.ptb.w, TimeSceneOnset, 0);
           Logfile(TimeSceneOn, 2, nTrial, scene_id, scene_file, 0, 0, condition, 0, 0, 0, scene_pos, block_id, contingency_phase);

           %% 3. ISI (Blank Screen)
           Screen('FillRect', p.ptb.w, p.stim.bg);
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeISIOn = Screen('Flip', p.ptb.w, TimeISIOnset, 0);
           Logfile(TimeISIOn, 3, nTrial, 0, 0, 0, 0, condition, 0, 0, 0, 0, block_id, contingency_phase); 
           
           %% 4. Face Stimulus           
           % draw face image
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(nTrial), [], p.ptb.imrect);
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeStimOn = Screen('Flip', p.ptb.w, TimeStimOnset, 0);
           Logfile(TimeStimOn, 4, nTrial, 0, 0, target_id, target_file, condition, 0, 0, 0, 0, block_id, contingency_phase);
  
           %% 5. Response
           % start collecting response while image is presented on the screen
           response = nan;
           RT = nan;
           while GetSecs() < TimeFeedbackOnset - 0.05
                [current_response, current_RT] = getResponse;
                if isnan(response) && ~isnan(current_response) && (current_RT > TimeStimOn)
                   response = current_response;
                   RT = current_RT - TimeStimOn;
                   Logfile(current_RT, 5, nTrial, scene_id, 0, target_id, 0, condition, response, 0, RT, 0, block_id, contingency_phase);
                   TimeResponseEnd = GetSecs; 
                   break % exit while-loop
                end               
           end    
           
           %% Evaluate response and provide feedback
           if ~isnan(response)
               % Determine correctness
               if condition == 1 && response == 5  % expected and answered expected
                   correct = 1;  % correct
               elseif condition == 2 && response == 6  % unexpected and answered unexpected
                   correct = 1;  % correct
               elseif condition == 1 && response == 6  % expected but answered unexpected
                   correct = 0;  % incorrect
               elseif condition == 2 && response == 5  % unexpected but answered expected
                   correct = 0;  % incorrect
               else
                   correct = -1;  % other
               end

               % Visual feedback (checkmark or X)
               if correct == 1
                   % Draw green checkmark
                   Screen('FillRect', p.ptb.w, p.stim.bg);
                   Screen('TextSize', p.ptb.w, 100);
                   DrawFormattedText(p.ptb.w, '✓', 'center', 'center', [0 255 0]);
               else
                   % Draw red X
                   Screen('FillRect', p.ptb.w, p.stim.bg);
                   Screen('TextSize', p.ptb.w, 100);
                   DrawFormattedText(p.ptb.w, 'X', 'center', 'center', [255 0 0]);
               end

               TimeFeedbackOn = Screen('Flip', p.ptb.w, TimeResponseEnd, 0);
               Logfile(TimeFeedbackOn, 7, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase);

               % Auditory feedback
               if correct == 1
                   audio_idx = 1;  % correct.wav
               elseif correct == 0
                   audio_idx = 2;  % incorrect.wav
               else % correct == -1 or other
                   audio_idx = 3;  % tooslow.wav (or use 2 for incorrect)
               end
                sound = audioread(p.stim.audio{audio_idx});
               player = audioplayer(sound*0.3, p.sound.sf, 16, p.sound.deviceId);

               TimeAuditoryFeedbackOn = GetSecs;
               playblocking(player);
               Logfile(TimeAuditoryFeedbackOn, 8, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase);
               clear sound

               TimeEndStim = TimeFeedbackOn + p.duration.feedback;
           end
           
           %% if they answered too slow: feedback and end of trial
           if isnan(response)
              % grey background for auditory feedback
              Screen('FillRect',p.ptb.w,p.stim.bg);
              TimeFeedbackOn = Screen('Flip',p.ptb.w, TimeFeedbackOnset, 0);
              Logfile(TimeFeedbackOn, 7, nTrial, scene_id, 0, target_id, 0, condition, response, 0, 0, 0, block_id, contingency_phase);
               
              correct = 3;
              
              % 6. Feedback  
              % auditory
              % pre-load sound
              sound = audioread(p.stim.audio{correct});
              player = audioplayer(sound*0.3, p.sound.sf, 16, p.sound.deviceId);
              
              TimeAuditoryFeedbackOn = GetSecs;
              playblocking(player);
              Logfile(TimeAuditoryFeedbackOn, 8, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase); % log the sound onset
              clear sound
               
              TimeEndStim = TimeFeedbackOn + p.duration.feedback; 
                
                       
           %% if they answered mismatch: ID task
           elseif ~isnan(response) && isequal(response,6) % 6 = unexpected
               % grey background for ID response
               Screen('FillRect',p.ptb.w,p.stim.bg);
               randomIndex = randi(4, 1); % draw random number between 1 and 4 where the question mark should appear
               Screen('DrawTexture', p.ptb.w, p.ptb.stim_questionmark(1), [], p.ptb.bottomrect{randomIndex}); % draw question mark at random location of the four corners
               TimeIDResponseOn = Screen('Flip',p.ptb.w, TimeResponseEnd, 0);
               Logfile(TimeIDResponseOn, 9, nTrial, 0, 0, 0, 0, condition, 0, 0, 0, randomIndex, block_id, contingency_phase); % log the question mark position that is drawn randomly (in the position of the priorIndex)
               TimeIDFeedbackOnset = TimeIDResponseOn + p.duration.responseID; % 1.5 seconds response window
               
               % 10. Response ID task
               response = nan;
               RT = nan;
               while GetSecs() < TimeIDFeedbackOnset - 0.05
                 [current_response, current_RT] = getResponseID;
                 if isnan(response) && ~isnan(current_response) && (current_RT > TimeIDResponseOn)
                    response = current_response;
                    RT = current_RT - TimeIDResponseOn;
                    Logfile(current_RT, 10, nTrial, scene_id, 0, target_id, 0, condition, response, 0, RT, 0, block_id, contingency_phase);
                 end      
               end
                  
               % 11. Feedback Screen
               % grey background for auditory feedback
               Screen('FillRect',p.ptb.w,p.stim.bg);
               TimeIDFeedbackOn = Screen('Flip',p.ptb.w, TimeIDFeedbackOnset, 0);
               Logfile(TimeIDFeedbackOn, 11, nTrial, scene_id, 0, target_id, 0, condition, response, 0, 0, 0, block_id, contingency_phase);
                        
               % evaluate response: only feedback for too slow!
               if isnan(response)
                  correct = 3;

                  % 12. Feedback  
                  % auditory
                  % pre-load sound
                  sound = audioread(p.stim.audio{correct});
                  player = audioplayer(sound*0.3, p.sound.sf, 16, p.sound.deviceId);

                  TimeAuditoryFeedbackOn = GetSecs;
                  playblocking(player);
                  Logfile(TimeAuditoryFeedbackOn, 12, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase);
                  clear sound
                  
               end

               TimeEndStim = TimeResponseEnd + p.duration.responseID + p.duration.feedback; 
           
           end
           save(p.path.path_param,'p'); % save it
    end   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [response, RT] = getResponse
        % simply record whether button press was "expected" or "unexpected"
        % if a different key was pressed, treat it as NaN
        % collect keyboard events since KbQueueStart was invoked
        [keyIsDown, firstPress] = KbQueueCheck(p.ptb.device);
        if keyIsDown == 1
            pressedCode = find(firstPress);
            if pressedCode == 65 % left/a
               % subject: 1, 2, 3, 4; 9, 10, 11, 12; ...
               if ((rem(subject,8) > 0) && (rem(subject,8) < 5)) 
                  response = 5; % expected
               % subject: 5, 6, 7, 8; 13, 14, 15, 16; ...
               else
                  response = 6; % unexpected
               end
               RT = firstPress(pressedCode);
            elseif pressedCode == 68 % right/d
               if ((rem(subject,8) > 0) && (rem(subject,8) < 5))
                  response = 6; % unexpected
               else
                  response = 5; % expected
               end
               RT = firstPress(pressedCode);
            else % treat other button presses as NaN
               response = NaN;
               RT = NaN;
            end
        elseif keyIsDown == 0
            response = NaN;
            RT = NaN;
        end
        WaitSecs(0.001);
    end
    %       
    function [response, RT] = getResponseID
        % simply record whether button press was "expected" or "unexpected"
        % if a different key was pressed, treat it as NaN
        % collect keyboard events since KbQueueStart was invoked
        [keyIsDown, firstPress] = KbQueueCheck(p.ptb.device);
        if keyIsDown == 1
            pressedCode = find(firstPress);
            if pressedCode == 68 % right/d
               % odd number
               if rem(subject,2) ~= 0
                  response = 6; % unexpected
               % even number
               else
                  response = 5; % expected
               end
               RT = firstPress(pressedCode);
            elseif pressedCode == 74 % Ari/j
               response = 1;
               RT = firstPress(pressedCode);
            elseif pressedCode == 75 % Bob/k
               response = 2;
               RT = firstPress(pressedCode);
            elseif pressedCode == 76 % Cid/l
               response = 3;
               RT = firstPress(pressedCode);
            elseif pressedCode == 192 % Dan/ö (Code = `)
               response = 4;
               RT = firstPress(pressedCode);
            else % treat other button presses as NaN
               response = NaN;
               RT = NaN;
            end
        elseif keyIsDown == 0
            response = NaN;
            RT = NaN;
        end
        WaitSecs(0.001);
    end
    %
    function SetParams
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % relative path to stim and experiments
        % Path business.
        p.path.baselocation = path_experiment_material;
        
        p.path.experiment         = [p.path.baselocation 'experimental_training\']; 
                
        if exist(p.path.experiment, 'dir') == 0  % checks if folder exists
           fprintf('Baselocation:\n %s doesn''t exist', p.path.experiment);
           keyboard  % stops execution of file and gives contol of user's keyboard
        end
        %
        p.path.stimfile               = [p.path.experiment 'stimulusfiles' filesep];
        p.path.scenes                 = [p.path.experiment 'scenes' filesep];
        p.path.audio                  = [p.path.experiment 'audio' filesep];
        p.path.instruction            = [p.path.experiment 'instructions' filesep];
        %
        p.subID                       = sprintf('sub%d',subject);
        p.path.edf                    = sprintf('st%02d.edf',subject);
        p.path.stim                   = [p.path.experiment 'stimuli' filesep];
        
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data' filesep 'tmp' filesep p.subID '_' timestamp filesep];
        p.path.finalsubject           = [p.path.experiment 'data' filesep p.subID '_' timestamp filesep ];
        p.path.path_param             = [p.path.subject 'dataOut' filesep 'data.mat'];
        % create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'dataOut']);  
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % get information about stimulus presentation
        S = load([p.path.experiment 'stimulusfiles\Exp_experimental_training_sub' num2str(subject) '.mat']); % loads in seqFile
        p.stim.info                    = S.seqFile;
        % Convert table to struct array if it's a table (for compatibility)
        if istable(p.stim.info)
            p.stim.info = table2struct(p.stim.info);
        end

        % get stim file names
        [p.stim.files]                 = FileMatrix([p.path.stim]);  % they are already in the correct order for the subject's trials
        [p.stim.scenes]                = FileMatrix_scenes([p.path.scenes]);
        [p.stim.questionmark]          = FileMatrix_questionmark([p.path.stim]); % question mark for ID task
        [p.stim.audio]                 = FileMatrix_audio([p.path.audio]); % get stim file names of sounds
        [p.stim.instruction]           = FileMatrix_instruction([p.path.instruction]);
        
        p.stim.nImage                = size(p.stim.files,1); % number of different files
        p.stim.nScenes               = size(p.stim.scenes,1); % number of different priors
        p.stim.nQuestionMark         = 1; % number of question marks
        p.stim.nSound                = size(p.stim.audio,1); % number of different files (including the UCS symbol)
        p.stim.nInstruction          = size(p.stim.instruction,1); % number of instruction files
        disp([mat2str(p.stim.nImage) ' images found in the destination.'])
        disp([mat2str(p.stim.nScenes) ' scenes found in the destination.'])
        disp([mat2str(p.stim.nSound) ' sounds found in the destination.']);
        disp([mat2str(p.stim.nInstruction) ' instructions found in the destination.'])
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        p.stim.bg                  = [150 150 150]; % background color
        p.stim.white               = [255 255 255];
        p.stim.red                 = [246 0 0];
        % get the actual stim size (assumes all the same)
        info                       = imfinfo(p.stim.files{1,:});
        p.stim.width               = info.Width;
        p.stim.height              = info.Height;
        % get the size of the prior
        info_scene                    = imfinfo(p.stim.scenes{1,:}); % 220x114: Ari too slow
        p.stim.width_scene            = info_scene.Width;
        p.stim.height_scene           = info_scene.Height;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % font size
        p.text.fontname            = 'Arial';
        p.text.fontsize            = 46;
        p.text.fixsize             = 80;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % all settings for laptop computer.
        try
            p.keys.left            = KbName('a'); 
            p.keys.right           = KbName('d');
            p.keys.Ari             = KbName('j'); 
            p.keys.Bob             = KbName('k');
            p.keys.Cid             = KbName('l');
            p.keys.Dan             = KbName('`'); % ö
            p.keys.space           = KbName('space');          
        catch
            fprintf('You need to change the key names because\n the assigned keys were not found.\n You can do that by calling the KbName function and\n pressing the key you want, it will output the correct keyname.\n And then replace in the code above.');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % duration of different events
        p.duration.scene              = 0.75;
        p.duration.target             = 2.0;  % Changed from 4.5s to 2.0s
        p.duration.feedback           = 2.0;  % Changed from 0.75s to 2.0s (visual + auditory)
        p.duration.responseID         = 1.5;
        p.duration.ITI                = struct('ITI_duration', {p.stim.info(:).ITI_duration})';
        p.duration.ITI                = struct2cell(p.duration.ITI);
        p.duration.ISI                = struct('ISI_duration', {p.stim.info(:).ISI_duration})';
        p.duration.ISI                = struct2cell(p.duration.ISI);  
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % stimulus presentation
        p.presentation.scene_id            = struct('scene_ID', {p.stim.info(:).scene_ID})';
        p.presentation.scene_id            = struct2cell(p.presentation.scene_id); 
        p.presentation.scene_file          = struct('scene_file', {p.stim.info(:).scene_file})';
        p.presentation.scene_file          = struct2cell(p.presentation.scene_file); 
        p.presentation.target_id           = struct('target_ID', {p.stim.info(:).target_ID})';
        p.presentation.target_id           = struct2cell(p.presentation.target_id); 
        p.presentation.target_file         = struct('target_file', {p.stim.info(:).target_file})';
        p.presentation.target_file         = struct2cell(p.presentation.target_file); 
        p.presentation.condition           = struct('condition', {p.stim.info(:).condition})';
        p.presentation.condition           = struct2cell(p.presentation.condition); 
        p.presentation.scene_pos           = struct('scene_position', {p.stim.info(:).scene_position})';
        p.presentation.scene_pos           = struct2cell(p.presentation.scene_pos); 
        p.presentation.block_id            = struct('block', {p.stim.info(:).block})';
        p.presentation.block_id            = struct2cell(p.presentation.block_id); 
        p.presentation.contingency_phase   = struct('contingency_phase', {p.stim.info(:).contingency_phase})';
        p.presentation.contingency_phase   = struct2cell(p.presentation.contingency_phase); 
        p.presentation.tTrial              = length(p.presentation.target_id);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;
        p.out.log                          = cell(15*n_images_and_trials,14);
        % Save the stuff for safety
        save(p.path.path_param,'p');
        %
        function [pathtofile] = FileMatrix(path)
        % Takes a path with file extension associated to regexp (e.g.
        % C:\blabl\bla\*.bmp) returns the file matrix
            for n = 1:n_images_and_trials
                filename = p.stim.info(n).target_file;
                pathtofile{n,1} = [path filename]; % get filename and save paths to files in correct order
            end
        end
        %
        function [pathtofile] = FileMatrix_scenes(path)
            for n = 1:n_images_and_trials
                filename = p.stim.info(n).scene_file;
                pathtofile(n,:) = {[path filename]}; % save all priors for all trials in correct order
            end
        end
        %
        function [pathtofile] = FileMatrix_questionmark(path)
                filename1 = 'question_mark.png';
                pathtofile(1,:) = {[path filename1]}; % path to image  % put into cell so it works with createstimsprotes
        end
        %
        function [pathtofile] = FileMatrix_audio(path)
               filename1 = 'correct.wav';
               filename2 = 'incorrect.wav';
               filename3 = 'tooslow.wav';
               pathtofile(1,:) = {[path filename1]}; % path to sound  % put into cell so it works with createstimsprotes
               pathtofile(2,:) = {[path filename2]}; 
               pathtofile(3,:) = {[path filename3]}; 
        end
        %
        function [pathtofile] = FileMatrix_instruction(path)
            % 4 versions: name-face associations
            if mod(subject,4) == 1
                filename1 = 'instruction_ver1.png';
            elseif mod(subject,4) == 2
                filename1 = 'instruction_ver2.png';
            elseif mod(subject,4) == 3 
                filename1 = 'instruction_ver3.png';
            elseif mod(subject,4) == 0
                filename1 = 'instruction_ver4.png';
            end
            
            % 2 versions: task (left/right arrow for expected/unexpected)
            % subject: 1, 2, 3, 4; 9, 10, 11, 12; ...
            if ((rem(subject,8) > 0) && (rem(subject,8) < 5))
               filename2 = 'task_ver1.png'; 
            % subject: 5, 6, 7, 8; 13, 14, 15, 16; ...
            else
               filename2 = 'task_ver2.png'; 
            end
            
            % for everyone the same
            filename3 = 'training_start.png';
            filename4 = 'training_end.png';
            pathtofile(1,:) = {[path filename1]}; % path to image  % put into cell so it works with createstimsprotes
            pathtofile(2,:) = {[path filename2]}; 
            pathtofile(3,:) = {[path filename3]}; 
            pathtofile(4,:) = {[path filename4]}; 
        end
        %
    end

    function ShowInstruction(nInstruct, waitforkeypress)
        % If waitforkeypress is 1, then subject has to press a button to
        % make the instruction text dissappear. Otherwise, you have to take
        % care of it later.
        
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_instruction(nInstruct));
        Screen('DrawingFinished', p.ptb.w, 0);
        t = Screen('Flip', p.ptb.w);
        Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        
        % let subject read it and ask confirmation to proceed.
        if waitforkeypress
            if nInstruct == 1 || nInstruct == 2 % instruction pages, wait for SPACE keypress
                RestrictKeysForKbCheck(32); % 32 = space; % KbName('space')
                KbStrokeWait;
                RestrictKeysForKbCheck([]); % enable all keys again
            elseif nInstruct == 3 % "Test starts."
                WaitSecs(2.5+rand(1));
            elseif nInstruct == 4 % Danke!
                WaitSecs(5); % 5 seconds break
            end
            Screen('FillRect',p.ptb.w,p.stim.bg);
            t = Screen('Flip',p.ptb.w);
            Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        else
            if nInstruct == 1 || nInstruct == 2 % instruction pages, wait for SPACE keypress
                RestrictKeysForKbCheck(32); % 32 = space; % KbName('space')
                KbStrokeWait;
                RestrictKeysForKbCheck([]); % enable all keys again
            elseif nInstruct == 3 % "Test starts."
                WaitSecs(2.5+rand(1));
            elseif nInstruct == 4 % Danke!
                WaitSecs(5); % 5 seconds break
            end 
            Screen('FillRect',p.ptb.w,p.stim.bg);
            t = Screen('Flip',p.ptb.w);
            Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        end
    end
    %
    function SetPTB
        % Sets the parameters related to the PTB toolbox.
        % Including fontsizes, font names.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Find the number of the screen to be opened
        screens            =  Screen('Screens');
        p.ptb.screenNumber =  max(screens); % the maximum is the second monitor
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Use the debug feature of PTB
        if debug == 1
            PsychDebugWindowConfiguration % transparent Screen
        else
            commandwindow;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2); % enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w); % make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        % image and prior rect/location
        p.ptb.imrect                = CenterRectOnPoint([0, 0, p.stim.width, p.stim.height], p.ptb.midpoint(1), p.ptb.midpoint(2));
        % 4 different prior locations: read-out as numbers 1-4 from stimulusfiles
        p.ptb.bottomrect{1}         = CenterRectOnPoint([0, 0, p.stim.width_scene, p.stim.height_scene], p.ptb.midpoint(1)-550, p.ptb.midpoint(2)-400); % upper-left corner
        p.ptb.bottomrect{2}         = CenterRectOnPoint([0, 0, p.stim.width_scene, p.stim.height_scene], p.ptb.midpoint(1)+550, p.ptb.midpoint(2)-400); % upper-right corner
        p.ptb.bottomrect{3}         = CenterRectOnPoint([0, 0, p.stim.width_scene, p.stim.height_scene], p.ptb.midpoint(1)-550, p.ptb.midpoint(2)+400); % lower-left corner
        p.ptb.bottomrect{4}         = CenterRectOnPoint([0, 0, p.stim.width_scene, p.stim.height_scene], p.ptb.midpoint(1)+550, p.ptb.midpoint(2)+400); % lower-right corner

        % fixation cross settings
        p.ptb.fc_size               = 10; % size of the arms of the fixation cross
        p.ptb.fc_width              = 4; % line width of fixation cross
        p.ptb.xCoords               = [-p.ptb.fc_size p.ptb.fc_size 0 0];
        p.ptb.yCoords               = [0 0 -p.ptb.fc_size p.ptb.fc_size];
        p.ptb.allCoords             = [p.ptb.xCoords; p.ptb.yCoords];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Prepare the keypress queue listening.
        p.ptb.device                         = -1;
        p.ptb.keysOfInterest                 = zeros(1,600);
        p.ptb.keysOfInterest(p.keys.space)   = 1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % load the pictures to the memory.
        p.ptb.stim_sprites      = CreateStimSprites(p.stim.files); % face images
        p.ptb.stim_scenes       = CreateStimSprites_scenes(p.stim.scenes); % scene images
        p.ptb.stim_questionmark = CreateStimSprites_questionmark(p.stim.questionmark);
        p.ptb.stim_instruction  = CreateStimSprites_instruction(p.stim.instruction);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Priority(MaxPriority(p.ptb.w));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [out] = CreateStimSprites(files)
            % loads all the stims to video memory
            for nStim = 1:p.stim.nImage
                filename       = files{nStim,:};  % get out of cell
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
        %
        function [out] = CreateStimSprites_questionmark(files)
            % loads all the stims to video memory
            for nStim = 1:p.stim.nQuestionMark
                filename       = files{nStim,:};  % get out of cell
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
        %
        function [out] = CreateStimSprites_instruction(files)
            % loads all the stims to video memory
            for nStim = 1:p.stim.nInstruction
                filename       = files{nStim,:};  % get out of cell
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
        %
        function [out] = CreateStimSprites_scenes(files)
            % loads all scene images to video memory
            for nStim = 1:p.stim.nScenes
                filename       = files{nStim,:};  % get out of cell
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
        %
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function cleanup
        % Close window:
        sca;
        %
        commandwindow;
        ListenChar(0);
        KbQueueRelease(p.ptb.device);
    end

    function Logfile(ptb_time, event_type, event_info1, event_info2, event_info3, event_info4, event_info5, event_info6, event_info7, event_info8, event_info9, event_info10, event_info11, event_info12)
        %% LogFile has to include:
        % 1. Time
        % 2. Event type
        % 3. nTrial 
        % 4. scene_ID
        % 5. scene_filename
        % 6. target_ID
        % 7. target_filename
        % 8. condition
        % 9. response
        % 10. correct (1 = correct, 0 = wrong, 3 = too slow)
        % 11. RT
        % 12. fb_pos
        % 13. block_id 
        % 14. contingency_phase
        p_var_event_count                = p_var_event_count + 1;
        ptb_time = {ptb_time};
        event_type = {event_type};
        event_info1 = {event_info1};
        event_info2 = {event_info2};
        event_info3 = {event_info3};
        event_info4 = {event_info4};
        event_info5 = {event_info5};
        event_info6 = {event_info6};
        event_info7 = {event_info7};
        event_info8 = {event_info8};
        event_info9 = {event_info9};
        event_info10 = {event_info10};
        event_info11 = {event_info11};
        event_info12 = {event_info12};
        p.out.log(p_var_event_count,:)     = [ptb_time event_type event_info1 event_info2 event_info3 event_info4 event_info5 event_info6 event_info7 event_info8 event_info9 event_info10 event_info11 event_info12];
    end
end