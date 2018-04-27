%------------------------------------------------------------------------
%
%  This script shows an example how to predict personal opinion scores 
%  using PredictPersonalRatings.m
%
%  Written by Jari Korhonen, Shenzhen University. The original version
%  of the script was written at Technical University of Denmark in 2017.
%
%  To use the script, you need scores from MOS_example.csv.
%
function out = PredictPersonalRatings_Example()

    clear;
    
    % Get the matrix of scores (columns are users, rows are items)
    score_matrix = csvread('MOS_example.csv');
    [n_items, n_users] = size(score_matrix);
    
    % Generate mask matrix by assigning zeros and ones randomly.
    % Zero means that the score is not available. Make sure that there
    % is at least one score by every user, and each item is scored at
    % least once.
    %
    rng(99);  
    mask_matrix = zeros(n_items,n_users);
    for i=1:n_items
        for u=1:n_users
            mask_matrix(i,u)=floor(rand(1)+0.5);
        end
    end
    
    % Predict the scores in masked positions
    n_feats = 4;
    pred_matrix = PredictPersonalRatings(score_matrix, ...
                                         mask_matrix, ... 
                                         n_feats); 
                                     
    % Now we can estimate the accuracy of the prediction. Baseline
    % means that we just compute the MOS for each item from the
    % available scores.
    %
    real_scores = [];
    pred_scores = [];
    baseline = [];
    for i=1:n_items
        bl = sum(score_matrix(i,:).*mask_matrix(i,:))./ ...
             sum(mask_matrix(i,:));
        for u=1:n_users
            if mask_matrix(i,u)==0
                real_scores = [real_scores score_matrix(i,u)];
                pred_scores = [pred_scores pred_matrix(i,u)];
                baseline = [baseline bl];
            end
        end
    end
    
    % We can compare the results in terms of PCC and RMSE
    fprintf('Baseline: PCC %0.2f, RMSE %0.3f\n', ...
            corr(real_scores', baseline'), ...
            sqrt(mean((real_scores-baseline).^2)));
    fprintf('Proposed: PCC %0.2f, RMSE %0.3f\n', ...
            corr(real_scores', pred_scores'), ...
            sqrt(mean((real_scores-pred_scores).^2)));
        
    out = 0;
end
    

