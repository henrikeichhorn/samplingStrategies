%%%%%%%% *~.~*~.~*~.~*~.~*~.~* ExperimentCC *~.~*~.~*~.~*~.~*~.~* %%%%%%%%%

%% Master Script
% Run all scripts of ExperimentCC sequentially for one subject.

%%   ENTER HERE YOUR PATHS TO THE EXPERIMENT SCRIPTS FOR EXPERIMENTCC    %%
%%                 AND TO THE MATERIALS FOR EXPERIMENTCC                 %%
path_experiments_code = 'C:\Users\eichhhwg\Documents\Promotion\PredictiveSaccades\ExpCC\code\ExperimentCC\experiments\';
path_experiment_material = 'C:\Users\eichhhwg\Documents\Promotion\PredictiveSaccades\ExpCC\material\ExperimentCC\';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%  *~.~*~.~*~.~*~.~*~.~*~.~*~. SCRIPT START .~*~.~*~.~*~.~*~.~*~.~*~.~*   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add folder with experiment scripts to MATLAB path
addpath(path_experiments_code)
% add folder with materials to MATLAB path (with subfolders)
addpath(genpath(path_experiment_material))

% Initiate retry variable on the first run
if exist("retry") == false
    retry = 0;
end

% On first try, ask for subject number and run the long (i.e., regular) 
% training version.
if retry == 0
    subject = input('Enter subject number  ');
    
    % Run Experiment_CC_normal_training()
    user_input = input('Start training? (y/n)  ', "s");
    
    if user_input == 'y' 
        run Experiment_CC_normal_training(subject,path_experiment_material);
    elseif user_input == 'debug' %type debug to skip
    else disp('Script terminated by user')
        return
    end
    
    
    % Evaluate training performance
    user_input = input('Evaluate training performance? (y/n)  ', "s");
    
    if user_input == 'y'
        feedback_score = Experiment_CC_normal_training_feedback(subject,path_experiment_material);
        if feedback_score(:,:,3) < 75
         disp('Bad training performance. Move data file and start again (see instruction sheet).')
         retry = retry +1
         return
        end
    elseif user_input == 'debug' 
    else disp('Script terminated by user')
        return
    end

% On retries, run the shortened version of the training.   
elseif retry > 0

    user_input = input('Retry training? (y/n)  ', "s");
    
    if user_input == 'y' 
        run Experiment_CC_normal_training_short(subject,path_experiment_material);
    elseif user_input == 'debug'
    else disp('Script terminated by user')
        return
    end

    user_input = input('Evaluate training performance? (y/n)  ', "s");
    
    if user_input == 'y'
        feedback_score = Experiment_CC_normal_training_feedback(subject,path_experiment_material);
        if feedback_score(:,:,3) < 75
         disp('Bad training performance. Move data file and start again (see instruction sheet).')
         retry = retry +1
         return
        else 
            disp('Looks good, time to move on.')

        end
    end

end


% Start first block
user_input = input('Start first block? (y/n)  ', "s");

if user_input == 'y'
    run Experiment_CC_main_experiment(subject, 1, path_experiment_material);
elseif user_input == 'debug'
else disp('Script terminated by user')
    return
end


% Start second block
user_input = input('Start second block? (y/n)  ', "s");

if user_input == 'y'
    run Experiment_CC_main_experiment(subject, 2, path_experiment_material);
elseif user_input == 'debug'
else disp('Script terminated by user')
    return
end


% Start third block
user_input = input('Start third block? (y/n)  ', "s");

if user_input == 'y'
    run Experiment_CC_main_experiment(subject, 3, path_experiment_material);
elseif user_input == 'debug'
else disp('Script terminated by user')
    return
end


% Start fourth block (NEW!)
user_input = input('Start fourth block? (y/n)  ', "s");

if user_input == 'y'
    run Experiment_CC_main_experiment(subject, 4, path_experiment_material);
elseif user_input == 'debug'
else disp('Script terminated by user')
    return
end


disp('Done')