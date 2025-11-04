function [p] = Experiment_CC_main_experiment(subject,part,path_experiment_material)

%% Experiment CC: Main Experiment

% Participants see a scene cue in one corner of the screen.
% Afterwards, a face is presented for 2000 ms or until button press.
% The first task is to indicate whether the presented face was expected or
% unexpected based on learned scene-face contingencies (70/10/10/10%).
% If they answer 'unexpected', a question mark prompts them to 
% identify the face as one of the four learned identities. 
% Auditory as well as visual feedback is provided on every trial.

% Experimental structure:
% - Block 1: 80 trials, stable contingencies
% - Block 2: 80 trials, contingency change at trial 41
%            (trials 1-40: stable, trials 41-80: transition)
% - Block 3: 80 trials, transition contingencies

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
% 9. block
% 10. contingency_phase (1 = stable, 2 = transition)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rng('shuffle'); % based on the current time, always creates new seed to use
                % random positions for the question mark for the ID task

debug          = 0;

% specify if you want to do eyetracking
eytracking     = '0';
USE_EYETRACKER = str2double(eytracking) == 1;

Screen('Preference', 'SkipSyncTests', 2);

% clear everything
clear mex global functions

% load the GETSECS mex files so call them at least once 
GetSecs;
WaitSecs(0.001);
p                   = [];
% Block 4 has 40 trials, all other blocks have 80 trials
if part == 4
    n_images_and_trials = 40;
else
    n_images_and_trials = 80;
end
slack = []; % global variable

%% get flip rate for defining stimulus durations in "SetParams"
% Find the number of the screen to be opened
screens            =  Screen('Screens');
screenNumber       =  max(screens); % the maximum is the second monitor
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
Screen('Preference', 'DefaultFontSize', 46);
Screen('Preference', 'DefaultFontName', 'Arial');
Screen('Preference', 'TextAntiAliasing',2); % enable textantialiasing high quality
Screen('Preference', 'VisualDebuglevel', 0);
Screen('Preference', 'SuppressAllWarnings', 1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open a graphics window using PTB
w                     = Screen('OpenWindow', screenNumber, [150 150 150]);
Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
Screen('Flip',w); % make the bg
slack                 = Screen('GetFlipInterval',w);
sca % close 

%% set experiment parameters and PTB parameters
SetParams;
SetPTB;

%% init some variables so that they are global
t                   = [];
nTrial              = 0;
TimeEndStim         = [];
p_var_event_count   = 0;

if debug
   el      = [];
end

%% calibrate if we are at the scanner computer.
if str2double(eytracking) == 1
   InitEyeLink;
   WaitSecs(2);
   CalibrateEL;
end

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
% start eyetracking
if str2double(eytracking) == 1
    Eyelink('Initialize');
    edf_name = sprintf('s%02d%d.edf',subject,part);
    Eyelink('OpenFile', edf_name);
    Eyelink('Startrecording');
end

%% start
PresentStimuli;

WaitSecs('UntilTime', TimeEndStim); % wait until last trial of former block 
                                    % is over
ShowInstruction(8,0); % Danke!

% get the eyelink file back to this computer
if str2double(eytracking) == 1
   StopEyelink(p.path.edf);
end

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
               if isequal(part,1)
                  ShowInstruction(1,1); % reminder faces
                  ShowInstruction(2,1); % instruction block 1
               elseif isequal(part,2)
                  ShowInstruction(1,1); % reminder faces
                  ShowInstruction(3,1); % instruction block 2
               elseif isequal(part,3)
                  ShowInstruction(1,1); % reminder faces
                  ShowInstruction(4,1); % instruction block 3
               elseif isequal(part,4)
                  ShowInstruction(1,1); % reminder faces
                  ShowInstruction(5,1); % instruction block 4
               end
               ShowInstruction(7,0); % test starts
               TimeEndStim       = GetSecs;
           % REMOVED: Mid-block pause
           % elseif nTrial == 41 && part ~= 4 % Pause-Screen (not in Block 4 which only has 40 trials)
           %   WaitSecs('UntilTime', TimeEndStim);
           %   ShowInstruction(6,0); % pause, continues after 10 sec
           %   ShowInstruction(7,0); % test starts
           %   TimeEndStim       = GetSecs;      
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
            fprintf('Trial %d of %d; scene_id: %d; target_id: %d\n', nTrial, p.presentation.tTrial, scene_id, target_id, contingency_phase);
            [TimeEndStim] = Trial(nTrial, trial_OnsetTime, scene_id, scene_file, target_id, target_file, condition, scene_pos, ITI, ISI, block_id, contingency_phase);
        end
    end
    
    function [TimeEndStim] = Trial(nTrial, trial_OnsetTime, scene_id, scene_file, target_id, target_file, condition, scene_pos, ITI, ISI, block_id, contingency_phase)
           %% get all the times for current trial
           TimeEyeLinkStart    = trial_OnsetTime;
           TimeITIOnset        = trial_OnsetTime + p.duration.EyeLinkStart - p.ptb.slack; % 1. ITI 
           TimeSceneOnset      = trial_OnsetTime + p.duration.EyeLinkStart + ITI - p.ptb.slack; % 2. scene cue
           TimeISIOnset        = trial_OnsetTime + p.duration.EyeLinkStart + ITI + p.duration.scene - p.ptb.slack; % 3. ISI (blank)
           TimeStimOnset       = trial_OnsetTime + p.duration.EyeLinkStart + ITI + p.duration.scene + ISI - p.ptb.slack; % 4. face
           TimeFeedbackOnset   = trial_OnsetTime + p.duration.EyeLinkStart + ITI + p.duration.scene + ISI + p.duration.target - p.ptb.slack; % 5. feedback if they answered too slow     
            
           %% 0. RESTART EYELINK FOR EACH TRIAL
           % grey background
           Screen('FillRect', p.ptb.w , p.stim.bg);
           TimeEyeLinkOn = Screen('Flip', p.ptb.w, TimeEyeLinkStart, 0);
           Logfile(TimeEyeLinkOn, 0.1, nTrial, 0, 0, 0, 0, 0, 0, 0, 0, 0, block_id, contingency_phase);
            
           if str2double(eytracking) == 1
               % write TRIALID message to EDF file: marks the start of a trial for DataViewer 
               trial_id = double(nTrial); % otherwise messages to eyelink are not sent.
               Eyelink('Message', 'TRIALID %d', trial_id);
               % Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
               Eyelink('Message', '!V CLEAR %d %d %d', el.backgroundcolour(1), el.backgroundcolour(2), el.backgroundcolour(3));
               % Supply the trial number as a line of text on Fost PC screen
               Eyelink('Command', 'record_status_message "TRIAL %d/%d"', trial_id, n_images_and_trials);
               % put tracker in idle/offline mode before drawing Host PC graphics and before recording
               Eyelink('SetOfflineMode'); 
               % Clear Host PC display from any previous drawing?
               Eyelink('Command', 'clear_screen 0');
               % START RECORDING
               Eyelink('SetOfflineMode'); % put tracker in idle/offline mode before recording
               Eyelink('StartRecording'); % Start tracker recording
               WaitSecs(0.1); % allow some time to record a few samples before presenting first stimulus                   
           end 
               
           %% 1. Blank Screen = InterTrialInterval
           TimeITIOn = Screen('Flip', p.ptb.w, TimeITIOnset, 0);
           if str2double(eytracking) == 1
               % send eyelink a marker asap
               Eyelink('Message', '1 ITI Onset');
           end
           Logfile(TimeITIOn, 1, nTrial, 0, 0, 0, 0, condition, 0, 0, 0, 0, block_id, contingency_phase);
           
           %% 2. Scene Cue
           % show scene image
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_scenes(nTrial), [], p.ptb.bottomrect{scene_pos});
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeSceneOn = Screen('Flip', p.ptb.w, TimeSceneOnset, 0);
           if str2double(eytracking) == 1
                Eyelink('Message', '2 Scene Onset');
           end
           Logfile(TimeSceneOn, 2, nTrial, scene_id, scene_file, 0, 0, condition, 0, 0, 0, scene_pos, block_id, contingency_phase);

           %% 3. ISI (Blank Screen)
           Screen('FillRect', p.ptb.w, p.stim.bg);
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeISIOn = Screen('Flip', p.ptb.w, TimeISIOnset, 0);
           if str2double(eytracking) == 1
                Eyelink('Message', '3 ISI Onset');
           end
           Logfile(TimeISIOn, 3, nTrial, 0, 0, 0, 0, condition, 0, 0, 0, 0, block_id, contingency_phase);
           
           %% 4. Stimulus Image                  
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(nTrial), [], p.ptb.imrect);
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeStimOn = Screen('Flip', p.ptb.w, TimeStimOnset, 0);
           if str2double(eytracking) == 1
               Eyelink('Message', '4 Stimulus Onset');
           end
           Logfile(TimeStimOn, 4, nTrial, 0, 0, target_id, target_file, condition, 0, 0, 0, 0, block_id, contingency_phase);
  
           %% 5. Response
           % start collecting response while image is presented on the 
           % screen
           response = nan;
           RT = nan;
           while GetSecs() < TimeFeedbackOnset - 0.05
                 [current_response, current_RT] = getResponse;
                 if isnan(response) && ~isnan(current_response) && (current_RT > TimeStimOn)
                    response = current_response;
                    if str2double(eytracking) == 1
                        Eyelink('Message', '4 Response Onset');
                    end
                    RT = current_RT - TimeStimOn;
                    Logfile(current_RT, 4, nTrial, scene_id, 0, target_id, 0, condition, response, 0, RT, 0, block_id, contingency_phase);
                    TimeResponseEnd = GetSecs;
                    break % exit while-loop
                 end               
           end       
           
           %% 5. Evaluate response and provide feedback (if response given)
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
               Screen('FillRect', p.ptb.w, p.stim.bg);
               
               if correct == 1
                   % Draw green checkmark
                   % Get screen center
                   [xCenter, yCenter] = RectCenter(Screen('Rect', p.ptb.w));
                   
                   % Checkmark parameters
                   checkSize = 80;
                   lineWidth = 12;
                   greenColor = [0 255 0];
                   
                   % Draw checkmark as two lines
                   % First line: bottom-left to middle
                   fromX1 = xCenter - checkSize/2;
                   fromY1 = yCenter;
                   toX1 = xCenter - checkSize/6;
                   toY1 = yCenter + checkSize/2;
                   Screen('DrawLine', p.ptb.w, greenColor, fromX1, fromY1, toX1, toY1, lineWidth);
                   
                   % Second line: middle to top-right
                   fromX2 = toX1;
                   fromY2 = toY1;
                   toX2 = xCenter + checkSize/2;
                   toY2 = yCenter - checkSize/2;
                   Screen('DrawLine', p.ptb.w, greenColor, fromX2, fromY2, toX2, toY2, lineWidth);
                   
               else
                   % Draw red X
                   % Get screen center
                   [xCenter, yCenter] = RectCenter(Screen('Rect', p.ptb.w));
                   
                   % X parameters
                   xSize = 80;
                   lineWidth = 12;
                   redColor = [255 0 0];
                   
                   % Draw X as two diagonal lines
                   % First diagonal: top-left to bottom-right
                   Screen('DrawLine', p.ptb.w, redColor, ...
                          xCenter - xSize/2, yCenter - xSize/2, ...
                          xCenter + xSize/2, yCenter + xSize/2, lineWidth);
                   
                   % Second diagonal: top-right to bottom-left
                   Screen('DrawLine', p.ptb.w, redColor, ...
                          xCenter + xSize/2, yCenter - xSize/2, ...
                          xCenter - xSize/2, yCenter + xSize/2, lineWidth);
               end

               TimeFeedbackOn = Screen('Flip', p.ptb.w, TimeResponseEnd, 0);
               Logfile(TimeFeedbackOn, 5, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase);

               % Auditory feedback
               % Map correct value to audio file index
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
               Logfile(TimeAuditoryFeedbackOn, 6, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase);
               clear sound

               TimeEndStim = TimeFeedbackOn + p.duration.feedback;
           end
           
           %% if they answered too slowly: feedback and end of trial
           if isnan(response)
               % grey background for auditory feedback
               Screen('FillRect',p.ptb.w,p.stim.bg);
               TimeFeedbackOn = Screen('Flip',p.ptb.w, TimeFeedbackOnset, 0);
               if str2double(eytracking) == 1
                     Eyelink('Message', '5 Feedback Screen Onset');
               end
               Logfile(TimeFeedbackOn, 7, nTrial, scene_id, 0, target_id, 0, condition, response, 0, 0, 0, block_id, contingency_phase);

               correct = 3; % for too slow feedback
               id_task = 0; % for logging in eyelink that no id_task took place in this trial

               % 6. Feedback  
               % auditory
               % pre-load sound
               sound = audioread(p.stim.audio{correct});
               player = audioplayer(sound*0.3, p.sound.sf, 16, p.sound.deviceId);

               TimeAuditoryFeedbackOn = GetSecs;
               if str2double(eytracking) == 1
                     Eyelink('Message', '6 Auditory Feedback Onset');
               end
               playblocking(player);
               Logfile(TimeAuditoryFeedbackOn, 8, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase); 
               clear sound

               TimeEyeLinkStop = TimeFeedbackOn + p.duration.feedback - p.ptb.slack; % time for turning off the eyetracker
               TimeEndStim     = TimeEyeLinkStop + p.duration.EyeLinkStop; % ending time of trial
                
                       
           %% if they answered mismatch: ID task
           elseif ~isnan(response) && isequal(response,6) % 6 = unexpected
               % grey background for ID response
               Screen('FillRect',p.ptb.w,p.stim.bg);
               randomIndex = randi(4, 1); % draw random number between 1 and 4 where the question mark should appear
               Screen('DrawTexture', p.ptb.w, p.ptb.stim_questionmark(1), [], p.ptb.bottomrect{randomIndex}); % draw question mark at random location of the four corners
               TimeIDResponseOn = Screen('Flip',p.ptb.w, TimeResponseEnd, 0);
               if str2double(eytracking) == 1
                    Eyelink('Message', '9 Question Mark Onset');
               end
               Logfile(TimeIDResponseOn, 9, nTrial, 0, 0, 0, 0, condition, 0, 0, 0, randomIndex, block_id, contingency_phase);
               TimeIDFeedbackOnset = TimeIDResponseOn + p.duration.responseID; % 1.5 seconds response window

               % 10. Response ID task
               id_task = 1; % for logging in eyelink that id_task took place in this trial

               response = nan; % otherwise, it would think there is already an ID response
               RT = nan;
               while GetSecs() < TimeIDFeedbackOnset - 0.05
                 [current_response, current_RT] = getResponseID;
                 if isnan(response) && ~isnan(current_response) && (current_RT > TimeIDResponseOn)
                    response = current_response;
                    if str2double(eytracking) == 1
                        Eyelink('Message', '10 ID Response Onset');
                    end
                    RT = current_RT - TimeIDResponseOn;
                    Logfile(current_RT, 10, nTrial, scene_id, 0, target_id, 0, condition, response, 0, RT, 0, block_id, contingency_phase);
                 end      
               end

               % 11. Feedback Screen
               % grey background for auditory feedback
               Screen('FillRect',p.ptb.w,p.stim.bg);
               TimeIDFeedbackOn = Screen('Flip',p.ptb.w, TimeIDFeedbackOnset, 0);
               if str2double(eytracking) == 1
                    Eyelink('Message', '11 Feedback Screen Onset');
               end
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
                  if str2double(eytracking) == 1
                        Eyelink('Message', '12 Auditory Feedback Onset');
                  end
                  playblocking(player);
                  Logfile(TimeAuditoryFeedbackOn, 12, nTrial, scene_id, 0, target_id, 0, condition, response, correct, 0, 0, block_id, contingency_phase);
                  clear sound

               end
               
               TimeEyeLinkStop = TimeResponseEnd + p.duration.responseID + p.duration.feedback - p.ptb.slack; % time for turning off the eyetracker
               TimeEndStim     = TimeEyeLinkStop + p.duration.EyeLinkStop; % ending time of trial
           
           end   
           
           %% STOP EYELINK of the trial
           % create grey background for stopping of eyelink
           Screen('FillRect', p.ptb.w , p.stim.bg);
           % Write message to EDF file to mark time when blank screen is presented
           if str2double(eytracking) == 1
                TimeEyeLinkOff = Screen('Flip', p.ptb.w, TimeEyeLinkStop, 0);
                Eyelink('Message', 'BLANK_SCREEN');
                % Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
                Eyelink('Message', '!V CLEAR %d %d %d', el.backgroundcolour(1), el.backgroundcolour(2), el.backgroundcolour(3));
                Logfile(TimeEyeLinkOff, 0.2, nTrial, 0, 0, 0, 0, 0, 0, 0, 0, 0, block_id, contingency_phase);
           end
           
           
           if str2double(eytracking) == 1
               % stop recording eye movements at the end of each trial
               WaitSecs(0.1); % add 100 ms of data to catch final events before stopping
               Eyelink('StopRecording'); % Stop tracker recording

               %% CREATE VARIABLES FOR DATAVIWER; END TRIAL
               % Write !V TRIAL_VAR messages to EDF file: creates trial
               % variables in DataViewer
               Eyelink('Message', '!V TRIAL_VAR iteration %d', trial_id);
               Eyelink('Message', '!V TRIAL_VAR condition %d', condition);
               WaitSecs(0.001); % allow some time between messages. Some messages can be lost if too many are written at the same time.
               Eyelink('Message', '!V TRIAL_VAR prior_id %d', scene_id);
               Eyelink('Message', '!V TRIAL_VAR prior_file %s', scene_file);
               WaitSecs(0.001);
               Eyelink('Message', '!V TRIAL_VAR target_id %d', target_id);
               Eyelink('Message', '!V TRIAL_VAR target_file %s', target_file);
               WaitSecs(0.001);
               Eyelink('Message', '!V TRIAL_VAR id_task %d', id_task);
               % Write TRIAL_RESULT message to EDF file: marks the end of a
               % trial for DataViwer
               Eyelink('Message', 'TRIAL_RESULT 0');
               WaitSecs(0.01); % allow some time before ending the trial
           end
           
           save(p.path.path_param,'p'); % save it so that we don't lose data in case of natural catastrophies              
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
        % Records button press for face identification task
        % Button-face mapping is counterbalanced across subjects
        % Counterbalancing scheme: mod(subject, 4) determines button order
        
        % collect keyboard events since KbQueueStart was invoked
        [keyIsDown, firstPress] = KbQueueCheck(p.ptb.device);
        if keyIsDown == 1
            pressedCode = find(firstPress);
            
            % Determine button-face mapping based on subject
            % This creates 4 different button layouts (independent of scene-face mapping)
            button_group = mod(subject - 1, 4) + 1;
            
            % Define the 4 counterbalancing layouts
            % Each row: [Face for J, Face for K, Face for L, Face for Ö]
            button_mappings = [
                1, 2, 3, 4;  % Group 1: J=Face1, K=Face2, L=Face3, Ö=Face4
                2, 3, 4, 1;  % Group 2: J=Face2, K=Face3, L=Face4, Ö=Face1
                3, 4, 1, 2;  % Group 3: J=Face3, K=Face4, L=Face1, Ö=Face2
                4, 1, 2, 3;  % Group 4: J=Face4, K=Face1, L=Face2, Ö=Face3
            ];
            
            current_mapping = button_mappings(button_group, :);
            
            if pressedCode == 68 % right/d (for expected/unexpected response - not used in ID task)
               % odd number
               if rem(subject,2) ~= 0
                  response = 6; % 
               % even number
               else
                  response = 5; % expected
               end
               RT = firstPress(pressedCode);
            elseif pressedCode == 74 % j button
               response = current_mapping(1); % Face assignment depends on group
               RT = firstPress(pressedCode);
            elseif pressedCode == 75 % k button
               response = current_mapping(2);
               RT = firstPress(pressedCode);
            elseif pressedCode == 76 % l button
               response = current_mapping(3);
               RT = firstPress(pressedCode);
            elseif pressedCode == 192 % ö button (Code = `)
               response = current_mapping(4);
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
        
        p.path.experiment   = [p.path.baselocation 'main_experiment\'];
        
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
        p.path.edf                    = sprintf('s%02d%d.edf',subject,part);
        p.part                        = sprintf('part%d',part);  % part1
        p.path.stim                   = [p.path.experiment 'stimuli' filesep];
        
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data' filesep 'tmp' filesep p.subID '_' p.part '_' timestamp filesep];
        p.path.finalsubject           = [p.path.experiment 'data' filesep p.subID '_' p.part '_' timestamp filesep ];
        p.path.path_param             = [p.path.subject 'dataOut' filesep 'data.mat'];
        % create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'dataOut']);  
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % get information about stimulus presentation
        % Load appropriate sequence file based on block
        if part == 1
            filename = sprintf('Exp_main_experiment_sub%d_block1.mat', subject);
        elseif part == 2
            % Block 2 is special (contains both stable and transition phases)
            filename = sprintf('Exp_main_experiment_sub%d_block2.mat', subject);
        elseif part == 3
            filename = sprintf('Exp_main_experiment_sub%d_block3.mat', subject);
        else % part == 4
            filename = sprintf('Exp_main_experiment_sub%d_block4.mat', subject);
        end
        S = load([p.path.experiment 'stimulusfiles\' filename]);
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
        p.stim.nScenes               = size(p.stim.scenes,1); % number of different scenes
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
        % get the size of the scene cue
        info_scene                    = imfinfo(p.stim.scenes{1,:}); 
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
        p.duration.scene              = 45 * slack; % 0.75 sec; duration of scene cue
        p.duration.target             = 120 * slack; % 2.0 sec; duration of face (changed from 4.5s)
        p.duration.feedback           = 45 * slack; % 0.75; duration of feedback 'too slow!'
        p.duration.responseID         = 135 * slack; % 2.25; duration response window ID task
        p.duration.ITI                = struct('ITI_duration', {p.stim.info(:).ITI_duration})'; %
        p.duration.ITI                = struct2cell(p.duration.ITI);
        p.duration.ISI                = struct('ISI_duration', {p.stim.info(:).ISI_duration})'; % 0.5 sec
        p.duration.ISI                = struct2cell(p.duration.ISI);
        p.duration.EyeLinkStart       = 15 * slack; % 0.25; duration of eyelink starting between trials
        p.duration.EyeLinkStop        = 30 * slack; % 0.5; duration of eyelink stopping between trials
        
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
                pathtofile(n,:) = {[path filename]}; % save all scenes for all trials in correct order
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
               filename2 = 'task_block1_ver1.png'; 
               filename3 = 'task_block2_ver1.png';
               filename4 = 'task_block3_ver1.png'; 
               filename5 = 'task_block4_ver1.png';
            % subject: 5, 6, 7, 8; 13, 14, 15, 16; ...
            else
               filename2 = 'task_block1_ver2.png'; 
               filename3 = 'task_block2_ver2.png';
               filename4 = 'task_block3_ver2.png'; 
               filename5 = 'task_block4_ver2.png';
            end
            
            % for everyone the same
            filename6 = 'pause.png';
            filename7 = 'test_start.png';
            filename8 = 'test_end.png';
            filename9 = 'calibration.png';
            pathtofile(1,:) = {[path filename1]}; % path to image  % put into cell so it works with createstimsprotes
            pathtofile(2,:) = {[path filename2]}; 
            pathtofile(3,:) = {[path filename3]}; 
            pathtofile(4,:) = {[path filename4]}; 
            pathtofile(5,:) = {[path filename5]}; 
            pathtofile(6,:) = {[path filename6]}; 
            pathtofile(7,:) = {[path filename7]}; 
            pathtofile(8,:) = {[path filename8]}; 
            pathtofile(9,:) = {[path filename9]}; 
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
        
        if str2double(eytracking) == 1
            Eyelink('Message', '6 Instruction Onset');
        end
        
        Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        
        % let subject read it and ask confirmation to proceed.
        if waitforkeypress
            if nInstruct == 1 || nInstruct == 2 || nInstruct == 3 || nInstruct == 4 || ...
               nInstruct == 5 || nInstruct == 9 % instruction pages, wait for SPACE keypress
                RestrictKeysForKbCheck(32); % 32 = space; % KbName('space')
                KbStrokeWait;
                RestrictKeysForKbCheck([]); % enable all keys again
            elseif nInstruct == 6 % break
                WaitSecs(10); % 10 seconds break
            elseif nInstruct == 7 % "Test starts."
                WaitSecs(2.5+rand(1));
            elseif nInstruct == 8 % Danke!
                WaitSecs(5); % 5 seconds break
            end
            Screen('FillRect',p.ptb.w,p.stim.bg);
            t = Screen('Flip',p.ptb.w);
            Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        else
           if nInstruct == 1 || nInstruct == 2 || nInstruct == 3 || nInstruct == 4 || ...
               nInstruct == 5 || nInstruct == 9 % instruction pages, wait for SPACE keypress
                RestrictKeysForKbCheck(32); % 32 = space; % KbName('space')
                KbStrokeWait;
                RestrictKeysForKbCheck([]); % enable all keys again
            elseif nInstruct == 6 % break
                WaitSecs(10); % 10 seconds break
            elseif nInstruct == 7 % "Test starts."
                WaitSecs(2.5+rand(1));
            elseif nInstruct == 8 % Danke!
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

%%%%%%%%%%%%%%%%%% eyetracker functions %%%%%%%%%%%%%%%%%%%%%

    function CalibrateEL
        fprintf('=================\n=================\nEntering Eyelink Calibration\n')
        p_var_ExpPhase  = 0;
        ShowInstruction(9,1); % calibration starts. are you ready?
        EyelinkDoTrackerSetup(el);
        % Returns 'messageString' text associated with result of last calibration
        [~, messageString] = Eyelink('CalMessage');
        Eyelink('Message','%s',messageString);%
        WaitSecs(0.05);
        fprintf('=================\n=================\nNow we are done with the calibration\n')
    end
    function InitEyeLink
        % will init the eyelink connection
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if EyelinkInit(0)%use 0 to init normaly
            fprintf('=================\nEyelink initialized correctly...\n')
        else
            fprintf('=================\nThere is problem in Eyelink initialization\n')
            keyboard;
        end
        WaitSecs(0.5);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [~, vs]                         = Eyelink('GetTrackerVersion');
        fprintf('=================\nRunning experiment on a ''%s'' tracker.\n', vs );
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        el                              = EyelinkInitDefaults(p.ptb.w);
        % update the defaults of the eyelink tracker
        el.backgroundcolour             = p.stim.bg;
        el.msgfontcolour                = WhiteIndex(el.window);
        el.imgtitlecolour               = WhiteIndex(el.window);
        el.targetbeep                   = 0;
        el.calibrationtargetcolour      = WhiteIndex(el.window);
        el.calibrationtargetsize        = 1.5;
        el.calibrationtargetwidth       = 0.5;
        el.displayCalResults            = 1;
        el.eyeimgsize                   = 50;
        el.waitformodereadytime         = 25; % ms
        el.msgfont                      = 'Times New Roman';
        el.cal_target_beep              = [0 0 0]; % shut all sounds off
        el.drift_correction_target_beep = [0 0 0];
        el.calibration_failed_beep      = [0 0 0];
        el.calibration_success_beep     = [0 0 0];
        el.drift_correction_failed_beep = [0 0 0];
        el.drift_correction_success_beep= [0 0 0];
        EyelinkUpdateDefaults(el);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % open EDF file and write information on it.
        res = Eyelink('Openfile', p.path.edf);
        %
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearCloud Experiment''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        % set calibration type.
        Eyelink('command','auto_calibration_messages = YES');
        Eyelink('command', 'calibration_type = HV13');
        Eyelink('command', 'select_parser_configuration = 1');
        % what do we want to record
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'use_ellipse_fitter = no');
        % set sample rate in camera setup screen
        Eyelink('command', 'sample_rate = %d',1000);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end

    function StopEyelink(filename)
        try
            fprintf('Trying to stop the Eyelink system with StopEyelink\n');
            Eyelink('StopRecording');
            WaitSecs(0.5);
            Eyelink('Closefile');
            disp('receiving the EDF file...');
            Eyelink('ReceiveFile',filename,[p.path.subject '\eye\'],1);
            disp('...finished!')
            % Shutdown Eyelink:
            Eyelink('Shutdown');
        catch
            disp('StopEyeLink routine didn''t really run well');
        end
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
        % 10. correct (1 = correct, 0 = wrong, -1 = too slow)
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