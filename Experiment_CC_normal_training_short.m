function [p] = Experiment_2_normal_training_short(subject,path_experiment_material)

%% Experiment 2: Normal Training (Repetition of Last Part)

% Participants see clear faces for various durations. Their task is to
% identify the face (A, B, C, or D).
% Part 1: face (3000 ms) - visual + auditory feedback
% Part 2: face (2000 ms) - visual + auditory feedback
% Part 3: face (2000 ms) - auditory feedback
% Always complete feedback: correct, wrong, too slow + always correct name

% There must be a ready-to-be-read-in seqFile for each participant containing:
% 1. target_ID
% 2. target_file (i.e., filename)
% 3. fb_position
% 4. ITI_duration (jittered)
% 5. block (task 1: block 1; task 2: block 2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

debug          = 0; %1

Screen('Preference', 'SkipSyncTests', 2);

% clear everything
clear mex global functions

%%%%%%load the GETSECS mex files so call them at least once 
GetSecs;
WaitSecs(0.001);
p                   = [];
n_images_and_trials = 128; % !!! always set according to rows in your 
                           % seqFile (which equals the number of trials per 
                           % part!) !!!

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

WaitSecs('UntilTime', TimeEndStim); % wait until last trial of former part 
                                    % is over

ShowInstruction(6,0); % Thank you!

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
        % This is the main loop 
        TimeEndStim       = GetSecs; % this is NOW
        for nTrial  = 81:p.presentation.tTrial          
            if nTrial == 1
               ShowInstruction(1,1); % overview faces
               ShowInstruction(2,1); % instruction for part 1
               ShowInstruction(5,0); % training starts
               TimeEndStim       = GetSecs;
            elseif nTrial == 33
               WaitSecs('UntilTime', TimeEndStim); % wait until last trial of former part is over
               ShowInstruction(3,1); % instruction for part 2
               ShowInstruction(5,0); % training starts
               TimeEndStim       = GetSecs;
            elseif nTrial == 81
               WaitSecs('UntilTime', TimeEndStim);
               ShowInstruction(4,1); % instruction for part 3
               ShowInstruction(5,0); % training starts
               TimeEndStim       = GetSecs;   
            end
            
            % Get the variables that Trial function needs. 
            target_id             = p.presentation.target_id{nTrial};
            target_file           = p.presentation.target_file{nTrial}; 
            fb_pos                = p.presentation.fb_pos{nTrial};
            block_id              = p.presentation.block_id{nTrial};
            ITI                   = p.duration.ITI{nTrial};
            
            % Start to monitor keypresses
            KbQueueCreate(p.ptb.device);
            KbQueueStart(p.ptb.device);
            
            % (better if it's down here; otherwise the first trial is too fast)
            trial_OnsetTime       = TimeEndStim; % trials start with fixation cross (ITI)
            
            % Start with the trial, here is time-wise sensitive must be optimal
            fprintf('Trial %d of %d; target_id: %d\n', nTrial, p.presentation.tTrial, target_id);
            [TimeEndStim] = Trial(nTrial, trial_OnsetTime, target_id, target_file, fb_pos, ITI, block_id); % target_name
        end
    end
    
    function [TimeEndStim] = Trial(nTrial, trial_OnsetTime, target_id, target_file, fb_pos, ITI, block_id)
       %% get all the times for current trial
       if block_id == 1 % feedback: visual + auditory + face with red circle
          TimeITIOnset        = trial_OnsetTime; % 1. ITI
          TimeStimOnset       = trial_OnsetTime + ITI; % 2. face
          TimeFeedbackOnset   = trial_OnsetTime + ITI + p.duration.target1; % 3. end of response window
          TimeEndStim         = trial_OnsetTime + ITI + p.duration.target1 + p.duration.feedback1;
           
          %% 1. InterTrialInterval (empty screen)
           TimeITIOn = Screen('Flip', p.ptb.w, TimeITIOnset, 0);
           % log ITI onset (1) + block ID
           Logfile(TimeITIOn, 1, nTrial, 0, 0, 0, 0, 0, 0, block_id);

           %% 2. Stimulus Image           
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(nTrial), [], p.ptb.imrect); % draw face image
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeStimOn = Screen('Flip', p.ptb.w, TimeStimOnset, 0);
           Logfile(TimeStimOn, 2, nTrial, target_id, target_file, 0, 0, 0, 0, block_id);

           %% 3. Response
           % start collecting response while image is presented on the screen
           % and continue to collect response during following fixation cross
           response = nan;
           RT = nan;
           % look for responses from onset of response image until next
           % trial begins
           while GetSecs() < TimeFeedbackOnset - 0.05
                 [current_response, current_RT] = getResponse;
               if isnan(response) && ~isnan(current_response) && (current_RT > TimeStimOn)
                  response = current_response;
                  RT = current_RT - TimeStimOn;
                  Logfile(current_RT, 3, nTrial, target_id, 0, response, 0, RT, 0, block_id);
               end               
           end       

           % evaluate response
           if ~isnan(response)  % if there was a response
              correct = evaluateResponse(target_id, response);
           else
              response = NaN; % no response or too slow
              correct = evaluateResponse(target_id, response);
           end        

           %% 4. Feedback  
           [FeedbackImage, FeedbackSound] = loadFeedback(correct);
           % pre-load sound
           sound = audioread(p.stim.audio{FeedbackSound});
           player = audioplayer(sound*0.3, p.sound.sf, 16, p.sound.deviceId);

           % visual
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_fb_red_circles(target_id), [], p.ptb.imrect); % draw face image with red circle
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_feedback(FeedbackImage), [], p.ptb.bottomrect{fb_pos}); % e.g., Ari correct; ORDER important: draw AFTER image
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeFeedbackOn = Screen('Flip', p.ptb.w, TimeFeedbackOnset,0);
           Logfile(TimeFeedbackOn, 4.1, nTrial, target_id, 0, response, correct, 0, fb_pos, block_id); % log feedback onset
           
           % auditory
           TimeAudioFeedbackOn    = GetSecs;
           playblocking(player);
           Logfile(TimeAudioFeedbackOn, 4.2, nTrial, target_id, 0, response, correct, 0, fb_pos, block_id); % log the sound onset
           clear sound 
           
      %% second block
      elseif block_id == 2 % visual + auditory feedback (but no red circles)
           TimeITIOnset        = trial_OnsetTime; 
           TimeStimOnset       = trial_OnsetTime + ITI; 
           TimeFeedbackOnset   = trial_OnsetTime + ITI + p.duration.target2; 
           TimeEndStim         = trial_OnsetTime + ITI + p.duration.target2 + p.duration.feedback2;

           %% 1. InterTrialInterval (empty screen)
           TimeITIOn = Screen('Flip', p.ptb.w, TimeITIOnset, 0);
           Logfile(TimeITIOn, 1, nTrial, 0, 0, 0, 0, 0, 0, block_id);

           %% 2. Stimulus Image           
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(nTrial), [], p.ptb.imrect);
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeStimOn = Screen('Flip', p.ptb.w, TimeStimOnset, 0);
           Logfile(TimeStimOn, 2, nTrial, target_id, target_file, 0, 0, 0, 0, block_id);

           %% 3. Response
           % start collecting response while image is presented on the screen
           % and continue to collect response during following fixation cross
           response = nan;
           RT = nan;
           % look for responses from onset of response image until next
           % trial begins
           while GetSecs() < TimeFeedbackOnset - 0.05
                 [current_response, current_RT] = getResponse;
               if isnan(response) && ~isnan(current_response) && (current_RT > TimeStimOn)
                  response = current_response;
                  RT = current_RT - TimeStimOn;
                  Logfile(current_RT, 3, nTrial, target_id, 0, response, 0, RT, 0, block_id);
               end               
           end       

           % evaluate response
           if ~isnan(response)  % if there was a response
              correct = evaluateResponse(target_id, response);
           else
              response = NaN; % no response or too slow
              correct = evaluateResponse(target_id, response);
           end        

           %% 4. Feedback  
           [FeedbackImage, FeedbackSound] = loadFeedback(correct);
           % pre-load sound
           sound = audioread(p.stim.audio{FeedbackSound});
           player = audioplayer(sound*0.3, p.sound.sf, 16, p.sound.deviceId);

           % visual
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_fb_red_circles(target_id), [], p.ptb.imrect);
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_feedback(FeedbackImage), [], p.ptb.bottomrect{fb_pos});
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeFeedbackOn = Screen('Flip', p.ptb.w, TimeFeedbackOnset,0);
           Logfile(TimeFeedbackOn, 4.1, nTrial, target_id, 0, response, correct, 0, fb_pos, block_id); 
           
           % auditory
           TimeAudioFeedbackOn    = GetSecs;
           playblocking(player);
           Logfile(TimeAudioFeedbackOn, 4.2, nTrial, target_id, 0, response, correct, 0, fb_pos, block_id);
           clear sound
           
       %% third block
       % only auditory feedback
       elseif block_id == 3
           TimeITIOnset        = trial_OnsetTime;
           TimeStimOnset       = trial_OnsetTime + ITI;
           TimeFeedbackOnset   = trial_OnsetTime + ITI + p.duration.target3;
           TimeEndStim         = trial_OnsetTime + ITI + p.duration.target3 + p.duration.feedback3;   
           
           %% 1. InterTrialInterval (empty screen)
           TimeITIOn = Screen('Flip', p.ptb.w, TimeITIOnset, 0);
           Logfile(TimeITIOn, 1, nTrial, 0, 0, 0, 0, 0, 0, block_id);

           %% 2. Stimulus Image           
           Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(nTrial), [], p.ptb.imrect); 
           Screen('DrawingFinished', p.ptb.w, 0);
           TimeStimOn = Screen('Flip', p.ptb.w, TimeStimOnset, 0);
           Logfile(TimeStimOn, 2, nTrial, target_id, target_file, 0, 0, 0, 0, block_id); 

           %% 3. Response
           % start collecting response while image is presented on the screen
           % and continue to collect response during following fixation cross
           response = nan;
           RT = nan;
           % look for responses from onset of response image until next
           % trial begins
           while GetSecs() < TimeFeedbackOnset - 0.05
                 [current_response, current_RT] = getResponse;
               if isnan(response) && ~isnan(current_response) && (current_RT > TimeStimOn)
                  response = current_response;
                  RT = current_RT - TimeStimOn;
                  Logfile(current_RT, 3, nTrial, target_id, 0, response, 0, RT, 0, block_id);
               end               
           end       
     
           % evaluate response
           if ~isnan(response)  % if there was a response
              correct = evaluateResponse(target_id, response);
           else
              response = NaN; % no response or too slow
              correct = evaluateResponse(target_id, response); 
           end        

           %% 4. Feedback  
           [~, FeedbackSound] = loadFeedback(correct);
           % pre-load sound
           sound = audioread(p.stim.audio{FeedbackSound});
           player = audioplayer(sound*0.3, p.sound.sf, 16, p.sound.deviceId);
           
           % always create a gray background
           Screen('FillRect', p.ptb.w , p.stim.bg ); 
           TimeFeedbackOn = Screen('Flip', p.ptb.w, TimeFeedbackOnset, 0);
           Logfile(TimeFeedbackOn, 4.1, nTrial, target_id, 0, response, 0, 0, fb_pos, block_id); 
           
           % auditory feedback
           TimeAudioFeedbackOn    = GetSecs;
           playblocking(player); % play sound
           Logfile(TimeAudioFeedbackOn, 4.2, nTrial, target_id, 0, response, correct, 0, 0, block_id);
           clear sound
       end

       save(p.path.path_param,'p'); % save it so that we don't lose data in case of natural catastrophies              
    end   
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [response, RT] = getResponse
        % simply record whether button press was 1,2,3,4
        [keyIsDown, firstPress] = KbQueueCheck(p.ptb.device); % collect keyboard events since KbQueueStart was invoked
        if keyIsDown == 1
            pressedCode = find(firstPress);
            if pressedCode == 74 % Ari/j
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
            else
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
    function [correct] = evaluateResponse(target_id, response)
        % code whether response was equal to the presented_id (target)
        if target_id == 1
           if response == 1  % 1 = Ari
              correct = 11;
           elseif response == 2 || response == 3 || response == 4
              correct = 19; % wrong answer
           elseif isnan(response)
              correct = -91;
           end
        elseif target_id == 2 
           if response == 2  % 2 = Bob
              correct = 22;
           elseif response == 1 || response == 3 || response == 4 % wrong
              correct = 29;
           elseif isnan(response)
              correct = -92;
           end
        elseif target_id == 3 
           if response == 3 % Cid is correct
              correct = 33; 
           elseif response == 1 || response == 2 || response == 4  % wrong
              correct = 39;
           elseif isnan(response)
              correct = -93;
           end
        elseif target_id == 4 
           if response == 4
              correct = 44; % Dan is correct
           elseif response == 1 || response == 2 || response == 3 % wrong
              correct = 49;
           elseif isnan(response)
              correct = -94;
           end
        end
    end
    %             
    function [FeedbackImage, FeedbackSound] = loadFeedback(correct)
        if correct == 11 % correct + name
           FeedbackImage = 1;
           FeedbackSound = 1; % correct
        elseif correct == 22
           FeedbackImage = 2;
           FeedbackSound = 1; % correct
        elseif correct == 33
           FeedbackImage = 3;
           FeedbackSound = 1; % correct
        elseif correct == 44
           FeedbackImage = 4;   
           FeedbackSound = 1; % correct
        elseif correct == 19
           FeedbackImage = 5; % Ari would have been correct 
           FeedbackSound = 2; % incorrect
        elseif correct == 29
           FeedbackImage = 6;
           FeedbackSound = 2; % incorrect
        elseif correct == 39 
           FeedbackImage = 7;
           FeedbackSound = 2; % incorrect
        elseif correct == 49
           FeedbackImage = 8;
           FeedbackSound = 2; % incorrect
        elseif correct == -91 % too slow + name
           FeedbackImage = 9;
           FeedbackSound = 3; % too slow
        elseif correct == -92 % too slow + name
           FeedbackImage = 10;
           FeedbackSound = 3; % too slow
        elseif correct == -93 % too slow + name
           FeedbackImage = 11;
           FeedbackSound = 3; % too slow
        elseif correct == -94 % too slow + name
           FeedbackImage = 12;
           FeedbackSound = 3; % too slow
        else 
           FeedbackImage = 18; % just to avoid errors; non-existent image
           FeedbackSound = 4; % just to avoid errors; non-existent sound
        end
    end
    %
    function SetParams
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % relative path to stim and experiments
        % Path business.
        p.path.baselocation = path_experiment_material;
        
        p.path.experiment         = [p.path.baselocation 'normal_training\']; 
        
        if exist(p.path.experiment, 'dir') == 0  % checks if folder exists
           fprintf('Baselocation:\n %s doesn''t exist', p.path.experiment);
           keyboard  % stops execution of file and gives contol of user's keyboard
        end
        %
        p.path.feedback               = [p.path.experiment 'feedback' filesep];
        p.path.audio                  = [p.path.experiment 'audio' filesep];
        p.path.stimfile               = [p.path.experiment 'stimulusfiles' filesep];
        p.path.instruction            = [p.path.experiment 'instructions' filesep];
        p.path.fb_red_circles         = [p.path.experiment 'feedback_red_circles' filesep];
        %
        p.subID                       = sprintf('sub%d',subject);  % sub1
        p.path.edf                    = sprintf('t%02d.edf',subject);
        p.path.stim                   = [p.path.experiment 'stimuli' filesep];
        %
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data' filesep 'tmp' filesep p.subID '_' timestamp filesep];
        p.path.finalsubject           = [p.path.experiment 'data' filesep p.subID '_' timestamp filesep ];
        p.path.path_param             = [p.path.subject 'dataOut' filesep 'data.mat'];
        %create folder hierarchy
        mkdir(p.path.subject); % e.g., 'C:\Users\Annika Garlichs\Documents\UKEbox_backup\01_ProjectNames\Pilot_EyeLink\data\tmp\sub1_timestamp\';
        mkdir([p.path.subject 'dataOut']);  
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % get information about stimulus presentation
        S = load([p.path.experiment 'stimulusfiles\Exp_2_normal_training_sub' num2str(subject) '.mat']); % loads in seqFile
        p.stim.info                  = S.seqFile;

        % get stim file names
        [p.stim.files]                  = FileMatrix([p.path.stim]);  % they are already in the correct order for the subject's trials
        [p.stim.feedback]               = FileMatrix_feedback([p.path.feedback]);
        [p.stim.audio]                  = FileMatrix_audio([p.path.audio]); % get stim file names of sounds
        [p.stim.instruction]            = FileMatrix_instruction([p.path.instruction]);
        [p.stim.fb_red_circles]         = FileMatrix_fb_red_circles([p.path.fb_red_circles]);
        p.stim.nImage                   = size(p.stim.files,1); % number of different files
        p.stim.nFeedback                = size(p.stim.feedback,1); % number of feedback files
        p.stim.nSound                   = size(p.stim.audio,1); % number of different files (including the UCS symbol)
        p.stim.nInstruction             = size(p.stim.instruction,1); % number of instruction files
        p.stim.nFeedback_red_circles    = size(p.stim.fb_red_circles,1); % images with red circles
        disp([mat2str(p.stim.nImage) ' images found in the destination.'])
        disp([mat2str(p.stim.nFeedback) ' feedbacks found in the destination.'])
        disp([mat2str(p.stim.nSound) ' found in the destination.']);
        disp([mat2str(p.stim.nInstruction) ' instructions found in the destination.'])
        disp([mat2str(p.stim.nFeedback_red_circles) ' feedbacks with red circles found in the destination.'])
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        p.stim.bg                  = [150 150 150]; % background color
        p.stim.white               = [255 255 255];
        %get the actual stim size (assumes all the same)
        info                       = imfinfo(p.stim.files{1,:});
        p.stim.width               = info.Width;
        p.stim.height              = info.Height;
        % get the size of the feedback
        info_fb                    = imfinfo(p.stim.feedback{9,:}); % 200x100: Ari too slow
        p.stim.width_fb            = info_fb.Width;
        p.stim.height_fb           = info_fb.Height;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % font size
        p.text.fontname            = 'Arial';
        p.text.fontsize            = 46; %40;
        p.text.fixsize             = 80;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % all settings for laptop computer.
        try
            p.keys.Ari             = KbName('j'); 
            p.keys.Bob             = KbName('k');
            p.keys.Cid             = KbName('l');
            p.keys.Dan             = KbName('`');
            p.keys.space         = KbName('space');
        catch
            fprintf('You need to change the key names because\n the assigned keys were not found.\n You can do that by calling the KbName function and\n pressing the key you want, it will output the correct keyname.\n And then replace on the code above.');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        % duration of different events
        p.duration.target1            = 4.5; % duration of target in seconds (part 1)
        p.duration.target2            = 3.5; % second block
        p.duration.target3            = 3.5; % third block
        p.duration.feedback1          = 3; % with red circles
        p.duration.feedback2          = 2; % 'Zu langsam!', 'Richtig!', 'Falsch!'
        p.duration.feedback3          = 0.75; % 'Zu langsam!', 'Richtig!', 'Falsch!'
        p.duration.ITI                = struct('ITI_duration', {p.stim.info(:).ITI_duration})'; %
        p.duration.ITI                = struct2cell(p.duration.ITI);               
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % stimulus presentation
        p.presentation.target_id           = struct('target_ID', {p.stim.info(:).target_ID})';
        p.presentation.target_id           = struct2cell(p.presentation.target_id); 
        p.presentation.target_file         = struct('target_file', {p.stim.info(:).target_file})';
        p.presentation.target_file         = struct2cell(p.presentation.target_file); 
        p.presentation.fb_pos              = struct('fb_pos', {p.stim.info(:).fb_position})';
        p.presentation.fb_pos              = struct2cell(p.presentation.fb_pos); 
        p.presentation.block_id            = struct('block', {p.stim.info(:).block})';
        p.presentation.block_id            = struct2cell(p.presentation.block_id); 
        p.presentation.tTrial              = length(p.presentation.target_id);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;
        p.out.log                          = cell(10*n_images_and_trials,10);
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
        function [pathtofile] = FileMatrix_feedback(path)
                filename1 = 'correct_Ari.png';
                filename2 = 'correct_Bob.png';
                filename3 = 'correct_Cid.png';
                filename4 = 'correct_Dan.png';
                filename5 = 'wrong_Ari.png';
                filename6 = 'wrong_Bob.png';
                filename7 = 'wrong_Cid.png';
                filename8 = 'wrong_Dan.png';
                filename9 = 'tooslow_Ari.png';
                filename10 = 'tooslow_Bob.png';
                filename11 = 'tooslow_Cid.png';
                filename12 = 'tooslow_Dan.png';
                pathtofile(1,:) = {[path filename1]}; % path to image  % put into cell so it works with createstimsprotes
                pathtofile(2,:) = {[path filename2]}; 
                pathtofile(3,:) = {[path filename3]}; 
                pathtofile(4,:) = {[path filename4]};
                pathtofile(5,:) = {[path filename5]};
                pathtofile(6,:) = {[path filename6]};
                pathtofile(7,:) = {[path filename7]};
                pathtofile(8,:) = {[path filename8]};
                pathtofile(9,:) = {[path filename9]};
                pathtofile(10,:) = {[path filename10]};
                pathtofile(11,:) = {[path filename11]};
                pathtofile(12,:) = {[path filename12]};
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
             if mod(subject,4) == 1
                filename1 = 'training_overview_ver1.png';
                filename2 = 'training_part1_ver1.png';
                filename3 = 'training_part2_ver1.png';
                filename4 = 'training_part3_ver1.png';
             elseif mod(subject,4) == 2
                filename1 = 'training_overview_ver2.png';
                filename2 = 'training_part1_ver2.png';
                filename3 = 'training_part2_ver2.png';
                filename4 = 'training_part3_ver2.png';
             elseif mod(subject,4) == 3
                filename1 = 'training_overview_ver3.png';
                filename2 = 'training_part1_ver3.png';
                filename3 = 'training_part2_ver3.png';
                filename4 = 'training_part3_ver3.png';
             elseif mod(subject,4) == 0
                filename1 = 'training_overview_ver4.png';
                filename2 = 'training_part1_ver4.png';
                filename3 = 'training_part2_ver4.png';
                filename4 = 'training_part3_ver4.png';
             end
             filename5 = 'training_start.png';
             filename6 = 'training_end.png';
             filename7 = 'calibration.png';
             pathtofile(1,:) = {[path filename1]}; % path to image  % put into cell so it works with createstimsprotes
             pathtofile(2,:) = {[path filename2]}; 
             pathtofile(3,:) = {[path filename3]}; 
             pathtofile(4,:) = {[path filename4]}; 
             pathtofile(5,:) = {[path filename5]}; 
             pathtofile(6,:) = {[path filename6]}; 
             pathtofile(7,:) = {[path filename7]}; 
        end
        %
        function [pathtofile] = FileMatrix_fb_red_circles(path)
            if mod(subject,4) == 1
                filename1 = '1_red.png';
                filename2 = '2_red.png';
                filename3 = '3_red.png';
                filename4 = '4_red.png';
             elseif mod(subject,4) == 2
                filename1 = '2_red.png';
                filename2 = '3_red.png';
                filename3 = '4_red.png';
                filename4 = '1_red.png';
             elseif mod(subject,4) == 3
                filename1 = '3_red.png';
                filename2 = '4_red.png';
                filename3 = '1_red.png';
                filename4 = '2_red.png';
             elseif mod(subject,4) == 0
                filename1 = '4_red.png';
                filename2 = '1_red.png';
                filename3 = '2_red.png';
                filename4 = '3_red.png';
            end
            pathtofile(1,:) = {[path filename1]}; % path to image  % put into cell so it works with createstimsprotes
            pathtofile(2,:) = {[path filename2]}; 
            pathtofile(3,:) = {[path filename3]}; 
            pathtofile(4,:) = {[path filename4]}; 
        end
    end

    function ShowInstruction(nInstruct, waitforkeypress)
        % If waitforkeypress is 1, then subject has to press a button to
        % make the instruction text dissappear. Otherwise, you have to take
        % care of it later.
        
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_instruction(nInstruct));
        Screen('DrawingFinished', p.ptb.w, 0);
        t = Screen('Flip', p.ptb.w);
        Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0);
        
        % let subject read it and ask confirmation to proceed.
        if waitforkeypress
            if nInstruct == 1 || nInstruct == 2 || nInstruct == 3 || nInstruct == 4 || nInstruct == 7 % instruction pages, wait for SPACE keypress; pause page
                RestrictKeysForKbCheck(32); % 32 = space; % KbName('space')
                KbStrokeWait;
                RestrictKeysForKbCheck([]); % enable all keys again
            elseif nInstruct == 5 % "Training starts." and "Test starts."
                WaitSecs(2.5+rand(1));
            elseif nInstruct == 6 % Danke!
                WaitSecs(10); % 10 Sekunden break
            end
            Screen('FillRect',p.ptb.w,p.stim.bg);
            t = Screen('Flip',p.ptb.w);
            Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0);
        else
            if nInstruct == 1 || nInstruct == 2 || nInstruct == 3 || nInstruct == 4 || nInstruct == 7 % instruction pages, wait for SPACE keypress; pause page
                RestrictKeysForKbCheck(32); % 32 = space; % KbName('space')
                KbStrokeWait;
                RestrictKeysForKbCheck([]); % enable all keys again
            elseif nInstruct == 5 % "Training starts." and "Test starts."
                WaitSecs(2.5+rand(1));
            elseif nInstruct == 6 % Danke!
                WaitSecs(10); % 10 seconds break
            end
            Screen('FillRect',p.ptb.w,p.stim.bg);
            t = Screen('Flip',p.ptb.w);
            Logfile(t,-9,nInstruct, 0, 0, 0, 0, 0, 0, 0);
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
            %ListenChar(2); % disable pressed keys to be spitted around
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        % image and feedback rect/location
        p.ptb.imrect                = CenterRectOnPoint([0, 0, p.stim.width, p.stim.height], p.ptb.midpoint(1), p.ptb.midpoint(2));
        % 4 different feedback locations: read-out as numbers 1-4 from stimulusfiles
        p.ptb.bottomrect{1}         = CenterRectOnPoint([0, 0, p.stim.width_fb, p.stim.height_fb], p.ptb.midpoint(1)-550, p.ptb.midpoint(2)-400); % upper-left corner
        p.ptb.bottomrect{2}         = CenterRectOnPoint([0, 0, p.stim.width_fb, p.stim.height_fb], p.ptb.midpoint(1)+550, p.ptb.midpoint(2)-400); % upper-right corner
        p.ptb.bottomrect{3}         = CenterRectOnPoint([0, 0, p.stim.width_fb, p.stim.height_fb], p.ptb.midpoint(1)-550, p.ptb.midpoint(2)+400); % lower-left corner
        p.ptb.bottomrect{4}         = CenterRectOnPoint([0, 0, p.stim.width_fb, p.stim.height_fb], p.ptb.midpoint(1)+550, p.ptb.midpoint(2)+400); % lower-right corner
        
        % fixation cross settings according to this: https://peterscarfe.com/fixationcrossdemo.html
        p.ptb.fc_size               = 10; % size of the arms of the fixation cross
        p.ptb.fc_width              = 4; % line width of fixation cross
        p.ptb.xCoords               = [-p.ptb.fc_size p.ptb.fc_size 0 0];
        p.ptb.yCoords               = [0 0 -p.ptb.fc_size p.ptb.fc_size];
        p.ptb.allCoords             = [p.ptb.xCoords; p.ptb.yCoords];
        % fix                         = [p.ptb.midpoint];
        % p.ptb.centralFixCross       = [fix(1)-p.ptb.fc_width,fix(2)-p.ptb.fc_size,fix(1)+p.ptb.fc_width,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-p.ptb.fc_width,fix(1)+p.ptb.fc_size,fix(2)+p.ptb.fc_width];
        % if you want to change the size of your pictures:
        % p.ptb.spriteRect            = [p.ptb.imrect p.ptb.imrect 1100 1100]; % The bounding box for our animated sprite; 400x400 pixels are the face images
        % p.ptb.spriteRect_small      = [p.ptb.midpoint(1)-1000/2 p.ptb.midpoint(2)-1000/2 1000 1000]; % how large it should be
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Prepare the keypress queue listening.
        p.ptb.device                         = -1;
        p.ptb.keysOfInterest                 = zeros(1,600);  % 256
        p.ptb.keysOfInterest(p.keys.space)   = 1;
        %KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest); % default device.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % load the pictures to the memory.
        p.ptb.stim_sprites           = CreateStimSprites(p.stim.files); % face images
        p.ptb.stim_feedback          = CreateStimSprites_feedback(p.stim.feedback); % 1 = correct, 2 = incorrect, 3 = too slow
        p.ptb.stim_instruction       = CreateStimSprites_instruction(p.stim.instruction);
        p.ptb.stim_fb_red_circles    = CreateStimSprites_fb_red_circles(p.stim.fb_red_circles);
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
        function [out] = CreateStimSprites_feedback(files)
            % loads all the stims to video memory
            for nStim = 1:p.stim.nFeedback
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
        function [out] = CreateStimSprites_fb_red_circles(files)
            % loads all the stims to video memory
            for nStim = 1:p.stim.nFeedback_red_circles
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

    function Logfile(ptb_time, event_type, event_info1, event_info2, event_info3, event_info4, event_info5, event_info6, event_info7, event_info8)
        %% LogFile has to include:
        % 1. Time
        % 2. Event type
        % 3. nTrial 
        % 4. target_ID
        % 5. target_file
        % 6. response
        % 7. correct (1 = correct, 0 = wrong, -1 = too slow)
        % 8. RT
        % 9. fb_loc
        % 10. block_id   
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
        p.out.log(p_var_event_count,:)     = [ptb_time event_type event_info1 event_info2 event_info3 event_info4 event_info5 event_info6 event_info7 event_info8];
    end
end