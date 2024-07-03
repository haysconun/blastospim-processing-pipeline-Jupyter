

%Change path here to point to CPD2 folder
addpath(genpath('./CPD2/core'));
addpath(genpath('./CPD2/data'));

% Name of registration output file
registration_filename = 'test.mat';
load(registration_filename);

% Which pairs of frames to run over. Remember that the first frame is 0.
% If you would like to re-match certain frame pairs then set [frame_pairs] accordingly.
first_frame = 0;
final_frame = 126;
frame_pairs = [(first_frame:final_frame-1).', (first_frame+1:final_frame).'];

% also, check the alignment of this one with the time frame after
for ii = 1:size(frame_pairs, 1)
     
    % get pair of frames
    frame_pair = frame_pairs(ii,:);

    % Get index of registration struct
    registration_frame_pairs = cell2mat({registration.frame_pair}.');
    reg_ind = find(ismember(registration_frame_pairs, frame_pair, 'rows'));
    if isempty(reg_ind)
        error('Registration output not found for frame pair (%d, %d)', frame_pair(1), frame_pair(2));
    end

    % Get transform between frames  
    Transform = registration(reg_ind).Transform;

    % Get centroids
    centroids1 = registration(reg_ind).centroids1;
    centroids2 = registration(reg_ind).centroids2;

    % Get point clouds
    ptCloud1 = registration(reg_ind).ptCloud1;
    ptCloud2 = registration(reg_ind).ptCloud2;

    % Get centroid labels
    uVal1 = registration(reg_ind).centroids1_ids;
    uVal2 = registration(reg_ind).centroids2_ids;

    % Transform ptCloud2 and centroids2
    ptCloud2_transform = cpd_transform(ptCloud2, Transform);
    centroids2_transform  = cpd_transform(centroids2, Transform);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    % show point clouds registered (red is earlier time point)
    figure(1);
    clf;
    title('After registering Y to X.'); 
    scatter3(ptCloud1(:,1), ptCloud1(:,2), ptCloud1(:,3), '.r');
    hold on;
    scatter3(ptCloud2_transform(:,1), ptCloud2_transform(:,2), ptCloud2_transform(:,3), '.b');
    axis equal vis3d;
    title(sprintf('Pair (%d, %d)', frame_pair(1), frame_pair(2)));
    pause;
    %close all;
end

