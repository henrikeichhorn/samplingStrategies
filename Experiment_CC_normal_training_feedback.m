function total_score = Experiment_2_normal_training_feedback(subject,path_experiment_material)

%% Experiment 2: Normal Training (Feedback)

% Evaluation of last part of 'Experiment_1_normal_training.m' in which 
% participants only got auditory feedback.

% Have they learned the 4 IDs?

subjects = subject;

p.path.experiment         = path_experiment_material;

% path with data/logfiles
path = [p.path.experiment 'normal_training\data\'];

%% read in data file
listing = dir(path);

for i_sub = 1:size(subjects,2)
    sub = sprintf('sub%d', subjects(i_sub));
    index = find(contains({listing.name}, sub)==1);
    folder = listing(index).name;
    data_path = [path folder '\dataOut\data.mat'];
    data = load(data_path);
    data_cell = data.p.out.log;
    data_cell_cleaned = data_cell(~all(cellfun(@isempty,data_cell(:,:)),2),:);

    % clear matrix of columns containing string (5 = target_filename)
    data_complete = data_cell_cleaned(:, [1:4 6:10]);
    data_saved{:,:,i_sub} = data_complete;
    clear data_cell data_complete
end

%% Cleaned Logfiles:
% - column 1: time point
% - column 2: event ID (1  = ITI, 2 = stimulus, 3 = response, 4.1 = visual
% feedback, 4.2 = auditory feedback, -9 = instructions)
% - column 3: trial nr
% - column 4: target ID (1 = Ari, 2 = Bob, 3 = Cid, 4 = Dan)
% - column 5: response (1 to 4 or NaN)
% - column 6: correct (e.g., for Ari: 11 (correct), 19 (incorrect), 
%                                     -91 (too slow))
% - column 7: RT (s)
% - column 8: feedback location (1 to 4)
% - column 9: block (1 to 3)

blocks = 3;

for n_sub = 1:size(data_saved,3)
    sub_mat = cell2mat(data_saved{:,:,n_sub}); 

    for n_part = 1:blocks
        A_count_correct = 0;
        B_count_correct = 0;
        C_count_correct = 0;
        D_count_correct = 0;

        A_count_incorrect = 0;
        B_count_incorrect = 0;
        C_count_incorrect = 0;
        D_count_incorrect = 0;

        A_count_NaN = 0;
        B_count_NaN = 0;
        C_count_NaN = 0;
        D_count_NaN = 0;

        % pre-allocate NaNs for RTs per block (8 trials per ID per block)
        A_matrix{n_sub,n_part} = NaN(12,1);
        B_matrix{n_sub,n_part} = NaN(12,1);
        C_matrix{n_sub,n_part} = NaN(12,1);
        D_matrix{n_sub,n_part} = NaN(12,1);

        for n_rows = 1:size(sub_mat,1)
            if isequal(sub_mat(n_rows,9), n_part)
               if (isequal(sub_mat(n_rows,2),3)) || ...
                  ((isnan(sub_mat(n_rows,5))) && ...
                  (isequal(sub_mat(n_rows,2),4.2)))
                  % Ari
                  if isequal(sub_mat(n_rows,4),1)
                     % correct response
                     if isequal(sub_mat(n_rows,4),sub_mat(n_rows,5))
                        A_count_correct = A_count_correct + 1;
                        % save RT
                        A_matrix{n_sub,n_part}(A_count_correct) = sub_mat(n_rows,7);
                     % too slow
                     elseif isnan(sub_mat(n_rows,5))
                        A_count_NaN = A_count_NaN + 1;
                     % wrong response
                     else 
                        A_count_incorrect = A_count_incorrect + 1;
                     end
                  % Bob
                  elseif isequal(sub_mat(n_rows,4),2)
                     if isequal(sub_mat(n_rows,4),sub_mat(n_rows,5))
                        B_count_correct = B_count_correct + 1;
                        B_matrix{n_sub,n_part}(B_count_correct) = sub_mat(n_rows,7);
                     elseif isnan(sub_mat(n_rows,5))
                        B_count_NaN = B_count_NaN + 1;
                     else % wrong response
                        B_count_incorrect = B_count_incorrect + 1;
                     end
                  % Cid
                  elseif isequal(sub_mat(n_rows,4),3)
                     if isequal(sub_mat(n_rows,4),sub_mat(n_rows,5))
                        C_count_correct = C_count_correct + 1;
                        C_matrix{n_sub,n_part}(C_count_correct) = sub_mat(n_rows,7);
                     elseif isnan(sub_mat(n_rows,5))
                        C_count_NaN = C_count_NaN + 1;
                     else % wrong response
                        C_count_incorrect = C_count_incorrect + 1;
                     end
                  % Dan
                  elseif isequal(sub_mat(n_rows,4),4)
                     if isequal(sub_mat(n_rows,4),sub_mat(n_rows,5))
                        D_count_correct = D_count_correct + 1;
                        D_matrix{n_sub,n_part}(D_count_correct) = sub_mat(n_rows,7);
                     elseif isnan(sub_mat(n_rows,5))
                        D_count_NaN = D_count_NaN + 1;
                     else
                        D_count_incorrect = D_count_incorrect + 1;
                     end
                  end
               end
            end 
        end

        % responses
        A_count_total(n_sub,n_part) = A_count_correct + ...
                                      A_count_incorrect + ...
                                      A_count_NaN;
        B_count_total(n_sub,n_part) = B_count_correct + ...
                                      B_count_incorrect + ...
                                      B_count_NaN;
        C_count_total(n_sub,n_part) = C_count_correct + ...
                                      C_count_incorrect + ...
                                      C_count_NaN;
        D_count_total(n_sub,n_part) = D_count_correct + ...
                                      D_count_incorrect + ...
                                      D_count_NaN;

        % save each participant's values in a matrix
        A_answers(1:4,n_sub,n_part) = [A_count_correct; ...
                                       A_count_incorrect; ...
                                       A_count_NaN; ...
                                       A_count_total(n_sub)];
        B_answers(1:4,n_sub,n_part) = [B_count_correct; ...
                                       B_count_incorrect; ...
                                       B_count_NaN; ...
                                       B_count_total(n_sub)];
        C_answers(1:4,n_sub,n_part) = [C_count_correct; ...
                                       C_count_incorrect; ...
                                       C_count_NaN; ...
                                       C_count_total(n_sub)];
        D_answers(1:4,n_sub,n_part) = [D_count_correct; ...
                                       D_count_incorrect; ...
                                       D_count_NaN; ...
                                       D_count_total(n_sub)];

        %% calculate a score for each block and print it: did participant 
        %% get 75% right?
        A_answers_part = A_answers(1:3,n_sub,n_part)';
        B_answers_part = B_answers(1:3,n_sub,n_part)';
        C_answers_part = C_answers(1:3,n_sub,n_part)';
        D_answers_part = D_answers(1:3,n_sub,n_part)';

        A_score(1,n_sub,n_part) = A_answers_part(1)/...
                                  (A_count_total(n_sub,n_part)/100);
        B_score(1,n_sub,n_part) = B_answers_part(1)/...
                                  (B_count_total(n_sub,n_part)/100);
        C_score(1,n_sub,n_part) = C_answers_part(1)/...
                                  (C_count_total(n_sub,n_part)/100);
        D_score(1,n_sub,n_part) = D_answers_part(1)/...
                                  (D_count_total(n_sub,n_part)/100);

        total_score(1,n_sub,n_part) = mean([A_score(1,n_sub,n_part) ...
                                            B_score(1,n_sub,n_part) ...
                                            C_score(1,n_sub,n_part) ...
                                            D_score(1,n_sub,n_part)]);

        sprintf('Participant %s answered %s percent of the trials in part %s correctly.', ...
             num2str(subjects(n_sub)), num2str(total_score(1,n_sub,n_part)), num2str(n_part))


    end % block

end % subject
