
function [] = PrecomputeRegistrationTransforms(  )

config_path = 'C:/Users/ab50/Documents/git/lineage_track/test';
% Set numThreads to the number of cores in your computer. If your processor
% supports hyperthreading/multithreading then set it to 2 x [number of cores]
numThreads = 4;

%% %%%%% NO CHNAGES BELOW %%%%%%%
addpath(genpath('../CPD2/core'));
addpath(genpath('../CPD2/data'));
addpath(genpath('../YAMLMatlab_0.4.3'));
addpath(genpath('../klb_io'));
addpath(genpath('../common'));

config_opts = ReadYaml(fullfile(config_path,'config.yaml'));

%% Loading User Inputs
verbosemode = 0;  % show the plots of registration

firstTime = config_opts.register_begin_frame;
lastTime =  config_opts.register_end_frame;

maxItr = 8;
nRerun = 0;
poolsize = 8;

time_str = strcat(string(firstTime),'_',string(lastTime));
RegistrationFileName = fullfile(config_opts.output_dir, ...
    strcat(config_opts.register_file_name_prefix,'_transforms.mat'));
RegistrationFileNameJSON = fullfile(config_opts.output_dir, ...
    strcat(config_opts.register_file_name_prefix,'_transforms.json'));

 
G_based_on_nn = graph;
% Voxel size before making isotropic
pixel_size_xy_um = 0.208; % um
pixel_size_z_um = 2.0; % um
% Voxel size after making isotropic
xyz_res = 0.8320;
% Volume of isotropic voxel
voxel_vol = xyz_res^3;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% SCRIPT BEGINS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Which image indices to run over...
valid_time_indices = 1:lastTime + 1; %what is the valid time range.
% Initialize empty graph and cell array for storing registration
store_registration = cell((length(valid_time_indices)-1), 1);

% Set the options for CPD - these are always the same.
opt.method='rigid'; % use rigid registration
opt.viz=0;          % show every iteration
opt.outliers=0;     % do not assume any noise

opt.normalize=0;    % normalize to unit variance and zero mean before registering (default)
opt.scale=0;        % estimate global scaling too (default)
opt.rot=1;          % estimate strictly rotational matrix (default)
opt.corresp=0;      % do not compute the correspondence vector at the end of registration (default)

opt.max_it=200;     % max number of iterations
opt.tol=1e-5;       % tolerance
opt.ftg = 1; % make faster

%% Note: last time point will look at this time point and the next one
time_index_index = firstTime;
while time_index_index <= lastTime
    
    sigma2tests = zeros(maxItr,1)*nan;  % these are the 100 tests for one pair of images
    transforms = cell(maxItr,1);
    tic
    time_index = valid_time_indices(time_index_index);
    disp(time_index)

    % store next in series
    time_index_plus_1 = valid_time_indices(time_index_index+1);

    if (nRerun == 0)  % only read the first time
        % store combined image for both.
        combined_image1 = read_embryo_frame(config_opts.data_path, ...
            config_opts.name_of_embryo, ...
            config_opts.suffix_for_embryo, ...
            config_opts.suffix_for_embryo_alternative, ...
            time_index, ...
            numThreads);
        nNuclei = size(unique(combined_image1),1) - 1;
   
        combined_image2 = read_embryo_frame(config_opts.data_path, ...
            config_opts.name_of_embryo, ...
            config_opts.suffix_for_embryo, ...
            config_opts.suffix_for_embryo_alternative, ...
            time_index_plus_1, ...
            numThreads);
    end

    % STORE MESHGRID
    [X, Y, Z] = meshgrid(1:size(combined_image1, 2), 1:size(combined_image1, 1), 1:size(combined_image1, 3));

    % FRACTION OF POINTS (DOWNSAMPLING)
    %% add so if fails, then change resolution & number of iterations
    if (nNuclei <= 20)  %% 50 for Jan22, 25 for Masha stack7
        fraction_of_selected_points =  1/10;  % slow to run at full scale - but make full res points and xform? (1/40 for frame 150 Jan22 seq)
        % how many random orientations do you want - minimum.
        maxItr = 8;
    else
        fraction_of_selected_points = 1/40;
        % how many random orientations do you want - minimum.
        maxItr = 100;
    end

    find1 = find(combined_image1(:)~=0);  % this is the indices into combined_image1 to get indices into (X,Y,Z) to the full set of point
    number_of_points = length(find1);
    
    rng(1)
    p = randperm(number_of_points,round(number_of_points * fraction_of_selected_points));
    find1 = find1(p);
    meanX1 = mean(X(find1));
    meanY1 = mean(Y(find1));
    meanZ1 = mean(Z(find1));
    ptCloud1 = [X(find1), Y(find1), Z(find1)] - [meanX1, meanY1, meanZ1];
    
    find2 = find(combined_image2(:)~=0);
    number_of_points = length(find2);
    
    p = randperm(number_of_points,round(number_of_points * fraction_of_selected_points));
    find2 = find2(p);   
    
    % why random points - why not just subsample by 10 ?
    [X, Y, Z] = meshgrid(1:size(combined_image2, 2), 1:size(combined_image2, 1), 1:size(combined_image2, 3));
    
    meanX2 = mean(X(find2));
    meanY2 = mean(Y(find2));
    meanZ2 = mean(Z(find2));
    ptCloud2 = [X(find2), Y(find2), Z(find2)] - [meanX2, meanY2, meanZ2];
    ptCloud2 = pointCloud(ptCloud2);

    tform = rigid3d(eye(3), [0,0,0]);
    
    % get 100 random numbers
    for i=1:100
        store_rand(i) = rand;
    end
  

    % Example 3. 3D Rigid CPD point-set registration. Full options intialization.
    %  3D face point-set.
    bStoredReg = false;
    if bStoredReg % get from file
        Transform = xforms.store_registration{time_index_index,1};
    else

        which_rot = 1;
        min_sigma2 = 100;
        counter = 0;

        while ((min_sigma2 > 10) && (counter < maxItr))
            fprintf('.')
            thetaHoldler = {};
            parfor whichrot = 1:gcp().NumWorkers
                newRotation = RandomRotationMatrix(counter+whichrot);
                ptCloud2Loc = ptCloud2.Location*newRotation;
                % registering Y to X
                [Transform,~, sigma2]=cpd_register(ptCloud1,ptCloud2Loc,opt);
                transforms{counter+whichrot, 1} = Transform;
                sigma2tests(counter+whichrot) = sigma2;
                init_transforms{counter+whichrot, 1} = newRotation;
            end

            counter = counter + gcp().NumWorkers;%which_rot;
            if counter > 99
                disp('did not find transformation with sigma2 < 10');
            end
            % get the best one we found this loop, 
            [tmp_min_sigma2, min_ind] = nanmin(sigma2tests);
            min_sigma2 = tmp_min_sigma2;
            Transform = transforms{min_ind,1};
            disp('min sigma');
            disp(min_sigma2);
            
            X = ptCloud1;
            [M, D] = size(X);            
            % combined transform
            Rinit =  init_transforms{min_ind, 1};
            final_translation = -repmat(Transform.t',[M,1])*Transform.R*Rinit';
            final_rotation = Transform.R*Rinit';
            newX = X*final_rotation + final_translation;
            if verbosemode
                figure; hold all; title('LB New X.'); cpd_plot_iter(newX, ptCloud2.Location);
            end
            s.Rotation = final_rotation;
            s.Translation = final_translation;
            s.Centroids1 = [meanX1,meanY1,meanZ1];
            s.Centroids2 = [meanX2,meanY2,meanZ2];
            s.NumberTrials = counter;
            s.minSigma = min_sigma2;
            store_registration{time_index_index, 1} = s;
        end
    end
    
    %% compute the matches 
    [iou_matrix, M, corresponding_ious_for_matches, ...
            cell_labels_I_care_about1, cell_labels_I_care_about2, ...
            center_point_for_each_label1, center_point_for_each_label2, ...
            match_based_on_nearest_neighbors, ~, ~, ...
            alpha_shape_for_each_label1, alpha_shape_for_each_label2] = compute_matches_based_on_point_clouds_CPD(Transform.Y,ptCloud1,...
            combined_image1,combined_image2,find1,find2);
     store_matches{time_index_index, 1} = M;
     store_iou_table{time_index_index, 1} = iou_matrix;
     
    %% make the graph..
        
    [nn nd]=kNearestNeighbors(center_point_for_each_label1, center_point_for_each_label2,min(3,length(center_point_for_each_label2)));
    if length(nn(:,1))~=length(unique(nn(:,1))) % Reject duplicate nearest neighbors
        dup=find_duplicates(nn(:,1));
        for lvd=1:size(dup,1)
            [ic,ia,ib]=intersect(nn(dup(lvd).ind,2),setdiff(1:size(nn,1),nn(:,1)));
            if ~isempty(ia)
                nn(dup(lvd).ind(ia),1)=nn(dup(lvd).ind(ia),2);
                nd(dup(lvd).ind(ia),1)=nd(dup(lvd).ind(ia),2);
                loi=dup(lvd).ind(setdiff(1:size(dup(lvd).ind,1),ia)); % treat triple and more entries
                if length(loi)>1
                    [mv,mi]=min(nd(loi,1));
                    loi1=setdiff(1:length(loi),mi);
                    nn(loi(loi1),1)=NaN;
                end
            else
                [mv mi]=min(sum(nd(dup(lvd).ind,1),2));
                loi=setdiff(dup(lvd).ind,dup(lvd).ind(mi));
                nn(loi,1)=NaN;
            end
        end
    end
    
    nn=nn(:,1);
    nd=nd(:,1);
    
    sample_graph = graph;
    for iind = 1:length(cell_labels_I_care_about1)
        this_label = cell_labels_I_care_about1(iind);
        
        % store node props table... so that node can be added with volume
        NodePropsTable = table({[num2str(time_index,'%05.3d'),'_', num2str(this_label,'%05.3d')]}, center_point_for_each_label1(iind, 1), center_point_for_each_label1(iind, 2), center_point_for_each_label1(iind, 3), ...
            'VariableNames',{'Name' 'xpos' 'ypos' 'zpos'});
        
        sample_graph = addnode(sample_graph, NodePropsTable);
    end
    
        for iind = 1:length(cell_labels_I_care_about2)
        this_label = cell_labels_I_care_about2(iind);
        
        % store node props table... so that node can be added with volume
        NodePropsTable = table({[num2str(time_index_plus_1,'%05.3d'),'_', num2str(this_label,'%05.3d')]}, center_point_for_each_label2(iind, 1), center_point_for_each_label2(iind, 2), center_point_for_each_label2(iind, 3), ...
            'VariableNames',{'Name' 'xpos' 'ypos' 'zpos'});
        
        sample_graph = addnode(sample_graph, NodePropsTable);
    end
    
    for point_index = 1:length(nn)
        
        if (~isnan(nn(point_index)))
            % make directed edges (in time) between matches + store iou for the match as a graph weight
            sample_graph = addedge(sample_graph, [num2str(time_index,'%05.3d'),'_', num2str(cell_labels_I_care_about1(nn(point_index)),'%05.3d')],...
                [num2str(time_index_plus_1,'%05.3d'),'_', num2str(cell_labels_I_care_about2(point_index),'%05.3d')]);
        end
        if (~isnan(nn(point_index)))
            
            % make directed edges (in time) between matches + store iou for the match as a graph weight
            G_based_on_nn = addedge(G_based_on_nn, [num2str(time_index,'%05.3d'),'_', num2str(cell_labels_I_care_about1(nn(point_index)),'%05.3d')],...
                [num2str(time_index_plus_1,'%05.3d'),'_', num2str(cell_labels_I_care_about2(point_index),'%05.3d')]);
            
        end
        
    end
    % visualization for checking if everything is correct - 3d plot of
    % edges and nodes
    if verbosemode
        hold all; plot(sample_graph, 'XData', sample_graph.Nodes.xpos, 'YData', sample_graph.Nodes.ypos, 'ZData', sample_graph.Nodes.zpos, 'EdgeColor', 'k', 'LineWidth', 2.0);
        figure; h1 = plot(sample_graph, 'XData', sample_graph.Nodes.xpos, 'YData', sample_graph.Nodes.ypos, 'ZData', sample_graph.Nodes.zpos, 'EdgeColor', 'k', 'LineWidth', 2.0,'NodeLabel',sample_graph.Nodes.Name);
    end
    %disp(time_index);
   
    % loop through all matches
    % LB: M is nMatches x 2 (label at time t, label at time t+1)  

    for i = 1:length(M)
        find_non_zero_please = find(iou_matrix(M(i,1),:));
        if (length(find_non_zero_please) > 1)  % more than one iou match
            if verbosemode
                figure; hold all; cpd_plot_iter(ptCloud1, Transform.Y);
                hold all; plot(alpha_shape_for_each_label1{M(i,1),1},'FaceColor','red','FaceAlpha',0.5);
                for j = 1:length(find_non_zero_please)
                    if (find_non_zero_please(j) == M(i,2)) % this is the best match?
                        hold all; plot(alpha_shape_for_each_label2{M(i,2),1},'FaceColor','green','FaceAlpha',0.5);
                    else
                        hold all; plot(alpha_shape_for_each_label2{find_non_zero_please(j),1},'FaceColor','black','FaceAlpha',0.5);
                    end
                end                
            end
            
            title([num2str(corresponding_ious_for_matches(i)),';',num2str(i)]);
        end
    end
    
    
    %% compute size of each nucleus
    % if reg failed - remove two smallest
    if min_sigma2 > 10
        %% find nuclei with no match
        for iImage = 1:2
            iNoInd = 1;
            NoM = [];
            if iImage == 1
                nlabels = size( unique(combined_image1), 1) - 1;
            else
                 nlabels = size( unique(combined_image2), 1) - 1;
            end
            for itest = 1: nlabels
                bFound = false;
                for imatch= 1:length(M)
                    if (M(imatch,iImage) == itest)
                        bFound = true;
                    end
                end
                if ~bFound
                    NoM(iNoInd) = itest;
                    iNoInd = iNoInd + 1;
                end
            end
            %disp(length(NoM));
            %disp(NoM);
            % remove these nuclei from image
            for ind =1:length(NoM)
                iLabel = NoM(ind);
                if iImage == 1
                    nucleus_pts = find(combined_image1(:)==iLabel); 
                    combined_image1(nucleus_pts) = 0;
                else
                    nucleus_pts = find(combined_image2(:)==iLabel); 
                    combined_image2(nucleus_pts) = 0;
                end
            end
        end   
     
        bRemoveSmall = false;
        if bRemoveSmall
            % get nuclei labels
            nlabels = size( unique(combined_image2), 1) - 1;
            vol = [];
            for ilabel = 1:nlabels
                 nucleus_pts = find(combined_image2(:)==ilabel);  % this is the indices into combined_image1 to get indices into (X,Y,Z) to the full set of point
                vol(ilabel) = length(nucleus_pts);
            end
            if verbosemode
                figure;
                plot(1:nlabels,vol,'LineWidth',5);
                xlabel('Nucleus Label ID');
                ylabel('Nucleus Volume');
            end
            % order by size
            [sort_vol,sort_idx] = sort(vol);
             % remove two smallest (if smaller than 1000 ?? depends on time)
            smallest_id = sort_idx(1);
            nucleus_pts = find(combined_image2(:)==smallest_id); 
            combined_image2(nucleus_pts) = 0;
            second_smallest_id = sort_idx(2);
            nucleus_pts = find(combined_image2(:)==second_smallest_id); 
            combined_image2(nucleus_pts) = 0;
        end % end of if bSmall
        if nRerun < 1
            nRerun = nRerun + 1;
            disp('rerunning');
        else
            nRerun = 0;
            time_index_index = time_index_index + 1;
        end
    else
        nRerun = 0;
        time_index_index = time_index_index + 1;
    end
    %pause;
    close all;
    disp(' ')
    toc
end

% Save vector of transformations...
save(RegistrationFileName, 'store_registration');
% output for python reading
jH = jsonencode(store_registration);
fid = fopen(RegistrationFileNameJSON,'w');
fprintf(fid, jH);
fclose(fid);

% add time range in file name
%save(strcat(config_opts.output_dir,'matches',time_str,'.mat'),'store_matches');
%save(strcat(config_opts.output_dir,'iou_table',time_str,'.mat'),'store_iou_table');
%save(strcat(config_opts.output_dir,'graph',time_str,'.mat'),'G_based_on_nn');

