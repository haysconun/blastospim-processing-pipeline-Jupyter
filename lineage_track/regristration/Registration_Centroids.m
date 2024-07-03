
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This should take ~10 seconds per frame when only using centroids.
%
% This may increase to 30-60 seconds per frame when also doing a final registration 
% using the full point clouds.
%
% This is runnable with 8GB.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% [registration] struct for each pair of frames containing
%       -frame_pair - [n,n+1] pair of frames
%       -centroids1 and centroid2 - centroids from each frame
%       -centroids1_ids and centroid2_ids - ids for each centroid
%       -ptCloud1 and ptCloud2 - full or downsampled point cloud for each frame
%       -ptCloud1_ids and ptCloud2_ids - ids for each point in point clouds
%       -volumes1 and volumes2 - volumes of each segmented region
%       -sigma2 - sigma2 value from CPD registration
%       -Transform - transformation struct
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = Registration_Centroids(config_path)
% Set numThreads to the number of cores in your computer. If your processor
% supports hyperthreading/multithreading then set it to 2 x [number of cores]
numThreads = 4;

%%  %%%%% NO CHNAGES BELOW %%%%%%%

% Imports
addpath(genpath('../CPD2/core'));
addpath(genpath('../CPD2/data'));
addpath(genpath('../YAMLMatlab_0.4.3'));
addpath(genpath('../klb_io'));
addpath(genpath('../common'));

config_opts = ReadYaml(fullfile(config_path,'config.yaml'));

% Name of output file
registration_filename = fullfile(config_opts.output_dir, ...
    strcat(config_opts.register_file_name_prefix,'_transforms.mat'));

% Which pairs of frames to run over. Remember that the first frame is 0.
% If you would like to re-register for certain frame pairs then set [frame_pairs] accordingly.
first_frame = config_opts.register_begin_frame;
final_frame = config_opts.register_end_frame;
frame_pairs = [(first_frame:final_frame-1).', (first_frame+1:final_frame).'];

% Voxel size before making isotropic
pixel_size_xy_um = 0.208; % um
pixel_size_z_um = 2.0; % um
% Voxel size after making isotropic
xyz_res = 0.8320;
% Volume of isotropic voxel
voxel_vol = xyz_res^3;

% Threshold to accept registration
sigma2_threshold = 5;

% Set this to true to exclude the false positives found using the Preprocess_seg_errors script
use_preprocess_false_positives = false;

% Name of preprocessing output
preprocess_filename = '';
if use_preprocess_false_positives
    load(preprocess_filename);
end

% Option to downsample point clouds in the saved output. Will reduce storage space
downsample_fraction = 1/10;

% numTrials controls how many random initializations to do 
numTrials = 1e3;

% Do final registration with full point clouds
final_full_register = false;

tic;
registration = [];

adjusted_registration = cell(size(frame_pairs, 1), 1);
for ii = 1:size(frame_pairs, 1)
    
    % get pair of frames
    frame_pair = frame_pairs(ii,:);

    fprintf('Beginning Registration Pair (%d, %d)...', frame_pair(1), frame_pair(2));
    
    % read in segmented images and rescale 
    seg1 = read_embryo_frame(config_opts.data_path, config_opts.name_of_embryo, ...
        config_opts.suffix_for_embryo, ...
        config_opts.suffix_for_embryo_alternative, ...
        frame_pair(1), ...
        numThreads);

    seg2 = read_embryo_frame(config_opts.data_path, config_opts.name_of_embryo, ...
        config_opts.suffix_for_embryo, ...
        config_opts.suffix_for_embryo_alternative, ...
        frame_pair(2), ...
        numThreads);

    % Exclude regions in segmented image whose mean intensities are within 2 stds of the background
    if use_preprocess_false_positives
        stored_frame_ids = [preprocess.frame_id].';

        ind_frame1 = find(stored_frame_ids == frame_pair(1));
        ind_frame2 = find(stored_frame_ids == frame_pair(2));

        temp = preprocess(ind_frame1).false_positive_ids_guess;
        for jj = 1:length(temp)
            seg1(seg1 == temp(jj)) = 0;
        end

        temp = preprocess(ind_frame2).false_positive_ids_guess;
        for jj = 1:length(temp)
            seg2(seg2 == temp(jj)) = 0;
        end
    end
   
    % Find non-zero indices of image
    [Y, XZ, Val1] = find(seg1);
    [X, Z] = ind2sub([size(seg1, 2), size(seg1, 3)], XZ);
    
    ptCloud1 = [X, Y, Z];
    ptCloud1 = ptCloud1 - mean(ptCloud1, 1);
    
    %Compute centroids
    uVal1 = unique(Val1);
    centroids1 = zeros(length(uVal1), 3);
    for jj = 1:length(uVal1)
        centroids1(jj,:) = mean(ptCloud1(Val1 == uVal1(jj),:), 1);
    end
    
    [Y, XZ, Val2] = find(seg2);
    [X, Z] = ind2sub([size(seg2, 2), size(seg2, 3)], XZ);
    
    ptCloud2 = [X, Y, Z];
    ptCloud2 = ptCloud2 - mean(ptCloud2, 1);
    
    %Compute centroids
    uVal2 = unique(Val2);
    centroids2 = zeros(length(uVal2), 3);
    for jj = 1:length(uVal2)
        centroids2(jj,:) = mean(ptCloud2(Val2 == uVal2(jj),:), 1);
    end

    % Compute some stats about the volumes of each cell to make an estimate of the cell radius
    stats1 = regionprops3(seg1, 'Volume');
    volumes1 = stats1.Volume(stats1.Volume > 0);
    stats2 = regionprops3(seg2, 'Volume');
    volumes2 = stats2.Volume(stats2.Volume > 0);

    % optionally downsample point clouds
    if downsample_fraction < 1
        p1 = randperm(size(ptCloud1, 1), round(size(ptCloud1, 1) * downsample_fraction));
        p2 = randperm(size(ptCloud2, 1), round(size(ptCloud2, 1) * downsample_fraction));
        
        find1 = find(seg1);
        find2 = find(seg2);

        find1 = find1(p1);
        find2 = find2(p2);

        Val1 = Val1(p1);
        Val2 = Val2(p2);

        ptCloud1 = ptCloud1(p1,:);
        ptCloud2 = ptCloud2(p2,:);
    end

    % Initialize variables for CPD
    step = 1;
    sigma2 = Inf;
    sigma2_best = Inf;
    Transform_best = [];

    Transform_init.R = eye(3);
    Transform_init.s = 1;
    Transform_init.method = 'rigid';
    Transform_init.t = zeros(3, 1);

    % Set the options
    opt.method='rigid'; % use rigid registration
    opt.viz=0;          % show every iteration
    opt.outliers=0;     % do not assume any noise

    opt.normalize=0;    % normalize to unit variance and zero mean before registering (default)
    opt.scale=0;        % estimate global scaling too (default)
    opt.rot=1;          % estimate strictly rotational matrix (default)
    opt.corresp=0;      % do not compute the correspondence vector at the end of registration (default)

    opt.max_it=200;     % max number of iterations
    opt.tol=1e-5;       % tolerance
    opt.fgt = 0;        % make faster (for some reason this doesn't produce good results, so set this to 0).
    while ((sigma2 > sigma2_threshold) && (step <= numTrials))    

        if step == 1
            Transform_init.R = eye(3);
        else
            Transform_init.R = orth(randn(3));
        end

        % Initialize centroids2
        centroids2_init = cpd_transform(centroids2, Transform_init);

        % registering Y to X
        [Transform, ~, sigma2] = cpd_register(centroids1, centroids2_init, opt);

        % Update transformation using initialization
        Transform.R = Transform.R * Transform_init.R;

        if sigma2 < sigma2_best
            sigma2_best = sigma2;
            Transform_best = Transform;
        end

        step = step + 1;
    end

    if final_full_register
        % Do a final registration using the full (or downsampled) point clouds
        % This registration will be initialized using the best of the centroid trials
        Transform_init = Transform_best;
        ptCloud2_init = cpd_transform(ptCloud2, Transform_init);
    
        % registering Y to X
        [Transform, ~, sigma2_best] = cpd_register(ptCloud1, ptCloud2_init, opt);
    
        % Update transformation using initialization
        Transform_best.R = Transform.R * Transform_init.R;
        Transform_best.t = Transform.t + Transform_init.t;
    end

    temp = Transform_best;
    temp.Rotation = Transform_best.R;
    temp.Translation = Transform_best.t.';
    temp.Centroids1 = centroids1;
    temp.Centroids2 = centroids2;
    temp.NumberTrials = step;
    temp.minSigma = sigma2_best;
    adjusted_registration{ii,1} = temp;

    % Update registration struct
    if ~isempty(registration)
        stored_frame_pairs = cell2mat({registration.frame_pair}.');
        ind = find(ismember(stored_frame_pairs, frame_pair, 'rows'));

        if isempty(ind)
            ind = size(registration, 1) + 1;
        end

        registration(ind,1) = struct('frame_pair', frame_pair, ...
                                     'centroids1', centroids1, 'centroids2', centroids2, ...
                                     'centroids1_ids', uVal1, 'centroids2_ids', uVal2, ...
                                     'ptCloud1', ptCloud1, 'ptCloud2', ptCloud2, ...
                                     'ptCloud1_ids', Val1, 'ptCloud2_ids', Val2, ...
                                     'volumes1', volumes1, 'volumes2', volumes2, ...
                                     'sigma2', sigma2_best, 'Transform', Transform_best);
    else
        registration = struct('frame_pair', frame_pair, ...
                               'centroids1', centroids1, 'centroids2', centroids2, ...
                               'centroids1_ids', uVal1, 'centroids2_ids', uVal2, ...
                               'ptCloud1', ptCloud1, 'ptCloud2', ptCloud2, ...
                               'ptCloud1_ids', Val1, 'ptCloud2_ids', Val2, ...
                               'volumes1', volumes1, 'volumes2', volumes2, ...
                               'sigma2', sigma2_best, 'Transform', Transform_best);
    end 
    

    fprintf(' Best Sigma2: %f, Done!\n', sigma2_best);
end
toc;

%Sort rows of registration output
stored_frame_pairs = cell2mat({registration.frame_pair}.');
[~, ind] = sortrows(stored_frame_pairs);
registration = registration(ind,:);
nframes = final_frame;
store_registration = cell(nframes,1);

% order of T/R (2,1,3)
% AND remove 0 so starts at 1 before conversion 
loop_begin_frame = first_frame;
if first_frame == 0
   loop_begin_frame = 1;
end

for i=loop_begin_frame:final_frame - 1
    R = adjusted_registration{i-first_frame+1,1}.Rotation;
    T = adjusted_registration{i-first_frame+1,1}.Translation;
%     Q = [[0,1,0];[1,0,0];[0,0,1]];
%     newR = Q*R*Q;
%     newT = [T(2),T(1),T(3)];
    store_registration{i,1}.Rotation = R;
    store_registration{i,1}.Translation = T;
    store_registration{i,1}.minSigma = adjusted_registration{i-first_frame+1,1}.minSigma;
    store_registration{i,1}.Centroids1 = adjusted_registration{i-first_frame+1,1}.Centroids1;
    store_registration{i,1}.Centroids2 = adjusted_registration{i-first_frame+1,1}.Centroids2;
end

% save as mat file
save(registration_filename, 'store_registration');

% output json 
jH = jsonencode(store_registration);
n = length(registration_filename);
json_registration_fileName = strcat(registration_filename(1:n-3),'json');
fid = fopen(json_registration_fileName,'w');
fprintf(fid, jH);
fclose(fid);
end
