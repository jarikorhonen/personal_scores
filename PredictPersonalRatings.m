%------------------------------------------------------------------------
%
%  Use this function to estimate the personal scores when only a subset
%  of scores for a set of items by a set of users is available. This is
%  a sort of collaborative filtering technique, applied specifically for
%  video quality assessment applications.
%
%  Written by Jari Korhonen, Shenzhen University. The original version of
%  the script was written at Technical University of Denmark in 2017.
%
%  For more details concerning the algorithm, see: 
%
%           J. Korhonen, "Predicting Personal Preferences in Subjective 
%           Video Quality Assessment," Proc. of QoMEX'17, Erfurt, Germany,
%           May 29 - June 2, 2017.
%
%  Input: 
%           score_matrix:  Matrix of scores. Columns represent users,
%                          rows represent different items (video sequences
%                          etc.)
%           mask matrix:   Binary mask for the score matrix. 1 means that 
%                          the score is available, 0 means that it will
%                          be predicted by the algorithm.
%           n_feats:       Number of latent features (four seems to work
%                          ok)
%
%  Output:
%           out:           Predicted matrix of scores, where the missing
%                          scores (mask is zero) have been replaced by
%                          the predicted scores. The available scores are
%                          just copied from score_matrix.
%           
% 
function out = PredictPersonalRatings(score_matrix, mask_matrix, n_feats)
    
    % Initialize variables
    user_params = []; 
    item_params = [];
    [n_items, n_users] = size(score_matrix);
    [n_i, n_u] = size(mask_matrix);
    n_iters = 4;
    
    % Re-scale score matrix to interval -1..1
    min_score = min(min(score_matrix));
    max_score = max(max(score_matrix));
    score_matrix = 2.0.*((score_matrix-min_score)./ ...
                         (max_score-min_score))-1.0;   
    
    % Test if score and mask matrices have the same dimensions
    if n_i ~= n_items || n_u ~= n_users
        out = [];
        fprintf('Matrix dimensions for scores and mask do not match!\n');
        return;
    end
    
    % Convert score matrix into a sequence of scores
    scores = [];
    for i=1:n_items
        for u=1:n_users
            if mask_matrix(i,u) == 1
                scores = [scores; i u score_matrix(i,u)];
            end
        end
    end
    
    % Add the scores one by one, repeat by iterating a few times to
    % get more accurate results (4-5 times seems sufficient) 
    rnseed = 1;
    for j=1:n_iters
        rng(rnseed*j);
        order = randperm(length(scores(:,1)));
        for i=1:length(scores(:,1))           
      
            [user_params,item_params] = AddScore(scores(order(i),1), ...
                                                 scores(order(i),2), ...
                                                 scores(order(i),3), ...
                                                 user_params, ...
                                                 item_params, ...
                                                 n_feats);              
        end
    end
    
    user_params(:,3) = user_params(:,3)./user_params(:,2);
    item_params(:,3) = item_params(:,3)./item_params(:,2);
    
    % Generate predicted matrix
    out = score_matrix;
    for i=1:n_items
        for u=1:n_users
            if mask_matrix(i,u)==0
                i_idx = find(item_params(:,1)==i);
                u_idx = find(user_params(:,1)==u);
                predval = sum(user_params(u_idx,4:3+n_feats).* ...
                              item_params(i_idx,4:3+n_feats));
                predval = max(min(predval,1),-1);
                out(i,u) = predval;
            end 
        end
    end  
    
    % Re-scale back to the original interval
    out = 0.5*(out + 1)*(max_score-min_score)+min_score;
end

%------------------------------------------------------------------------
%  Use this function to add a new score in the pool and to update the
%  user and item features accordingly.
%
function [user_params,item_params] = AddScore(item_id, user_id, score, ... 
                                              user_params, ...
                                              item_params, n_feat)

    % Initialize
    i_param = size(item_params);    
    lim = 1.5;
    alfa = 0;
     
    if i_param(1)==0 || isempty(find(item_params(:,1)==item_id))     
               
        % This item has not been rated yet, add a new item
        vec = lim:(-2*lim/(n_feat-1)):-lim;
        new_item_params = [item_id 1 0 vec];
        item_params = [item_params; new_item_params];
    end    
        
    % Find existing item index
    i_idx = find(item_params(:,1)==item_id);   
    vec = ones(1,n_feat)./n_feat;   
    
    n_users = size(user_params);        
    if n_users(1)==0
        
        % There are no users yet, add the first one
        user_params_new = [user_id 1 0 vec];
        user_params = [user_params; user_params_new];
        
    elseif length(find(user_params(:,1)==user_id))==0
        
        % This user has not rated any items yet, add the new user
        if n_users(1)>1
            u_vec = user_params(1,4:3+n_feat).*user_params(1,2);
            for i=2:n_users(1)
                u_vec = u_vec + user_params(i,4:3+n_feat).* ...
                                user_params(i,2);
            end
            user_params_new = [user_id 1 0 u_vec./sum(user_params(:,2))];
        else
            user_params_new = [user_id 1 0 user_params(1,4:3+n_feat)];
        end
        user_params = [user_params; user_params_new];
    end    
        
        
    % Find existing user
    u_idx = find(user_params(:,1)==user_id);
    
    new_mparams = computeNewItemParams(user_params(u_idx,4:3+n_feat), ...
                                       item_params(i_idx,4:3+n_feat), ...
                                       score);
    new_uparams = computeNewUserParams(item_params(i_idx,4:3+n_feat), ...
                                       score);
 
    if alfa == 0
        item_params(i_idx,4:3+n_feat) = (1/item_params(i_idx,2)).* ...
            new_mparams+((item_params(i_idx,2)-1)/ ...
            item_params(i_idx,2)).*item_params(i_idx,4:3+n_feat);
        user_params(u_idx,4:3+n_feat) = (1/user_params(u_idx,2)).* ...
            new_uparams+((user_params(u_idx,2)-1)/ ...
            user_params(u_idx,2)).*user_params(u_idx,4:3+n_feat);
    else
       item_params(i_idx,4:3+n_feat) = alfa*new_mparams+(1-alfa).* ...
                                       item_params(i_idx,4:3+n_feat);
       user_params(u_idx,4:3+n_feat) = alfa*new_uparams+(1-alfa).* ...
                                       user_params(u_idx,4:3+n_feat);
    end
    
    % Update the number of items and users and their average scores
    % (This is not really used, but it is useful for debugging)
    item_params(i_idx,2) = item_params(i_idx,2)+1;
    user_params(u_idx,2) = user_params(u_idx,2)+1;  
    item_params(i_idx,3) = item_params(i_idx,3)+score;
    user_params(u_idx,3) = user_params(u_idx,3)+score;

end

%------------------------------------------------------------------------
%  Use this function to update the user parameters (weights). See
%  Algorithm (1) in the QoMEX paper for more details.
%
function new_params = computeNewUserParams(params, new_score)

    % Here you match the parameters to their weigths
    n = length(params);
    param_flag = zeros(1, n);
    
    % This implements the method described in the paper (Algorithm 1)
    sum_param_above = 0; 
    num_param_above = 0;
    sum_param_equal = 0;
    num_param_equal = 0;
    sum_param_below = 0; 
    num_param_below = 0;
    
    for i=1:n
        if params(i) > new_score
            sum_param_above = sum_param_above + params(i);
            num_param_above = num_param_above + 1;
            param_flag(i) = 1;
        elseif params(i) < new_score
            sum_param_below = sum_param_below + params(i);
            num_param_below = num_param_below + 1;
            param_flag(i) = -1;
        else 
            sum_param_equal = sum_param_equal + params(i);
            num_param_equal = num_param_equal + 1;
        end
    end
    
    if new_score>1 || new_score<-1
        new_score = 0;
    end
    
    if num_param_equal > 0 && ...
            (num_param_above == 0 || num_param_below == 0)
        [prm,idx] = find(param_flag == 0);
        new_params(idx) = 1/length(idx);
    elseif num_param_equal == 0 && ...
            (num_param_above == 0 || num_param_below == 0)
        new_params(1:n) = 1/n;
    elseif num_param_equal > 0
        [prm,idx] = find(param_flag == 0);
        eqweight = 0.5/length(idx);
        new_params(idx) = eqweight;
        weight_b = (new_score-sum_param_above/num_param_above)/ ...
            (sum_param_below-num_param_below*sum_param_above/ ...
            num_param_above);
        weight_a = (1-weight_b*num_param_below)/num_param_above;
        [prm,idx] = find(param_flag == -1);
        new_params(idx) = 0.5*weight_b;
        [prm,idx] = find(param_flag == 1);
        new_params(idx) = 0.5*weight_a;
    else
        weight_b = (new_score-sum_param_above/num_param_above)/ ...
            (sum_param_below-num_param_below*sum_param_above/ ...
            num_param_above);
        weight_a = (1-weight_b*num_param_below)/num_param_above;
        [prm,idx] = find(param_flag == -1);
        new_params(idx) = weight_b;
        [prm,idx] = find(param_flag == 1);
        new_params(idx) = weight_a;
    end
    
    return;
        
end

%------------------------------------------------------------------------
%  Use this function to update the item parameters. See
%  Algorithm (2) in the QoMEX paper for more details.
%
function new_params = computeNewItemParams(param_weights, params, ...
                                           new_score)

    % Here you match the params to their weights
    n = length(params);

    % This implements the method described in the paper (Algorithm 2)
    tot_diff = (new_score - sum(param_weights.*params));

    if tot_diff==0        
        
        % No need to change parameters
        new_params = params;
        return;
    end    
    
    limit = sign(tot_diff)*5-params;
    max_change = limit.*param_weights;

    if abs(sum(max_change)) <= abs(tot_diff)
        
        % You cannot change the parameters more than the limit
        new_params = params+limit;
        return;
    end
 
    % Compute new item parameters
    new_params = params;
    space = zeros(1,n);
    for i=1:n
        space(i) = (param_weights(i)^1.5);
    end

    for i=1:n
        if param_weights(i)>0
            new_params(i) = params(i)+tot_diff*space(i)/ ...
                            (sum(space)*param_weights(i));
        end
    end

    return;
        
end