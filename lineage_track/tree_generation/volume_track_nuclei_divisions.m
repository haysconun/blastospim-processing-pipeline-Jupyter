
function [] = volume_track_nuclei_divisions()
% This is Masha's version of tracking, to run on early mouse embryos.
% This code attempts to construct the full lineage tree, 
% in particular, identify mitotic events.
% Pre-registration is advised but not necessary.

% SETUP starts here.

% Set numThreads to the number of cores in your computer. If your processor
% supports hyperthreading/multithreading then set it to 2 x [number of cores]
numThreads = 4;

[filepath,~,~] = fileparts(mfilename('fullpath'));
[parentFolder, childFolder] = fileparts(filepath);
[parentFolder, ~] = fileparts(parentFolder);
config_path = parentFolder;

%% %%%%% NO CHNAGES BELOW %%%%%%%
% CPD and Library Setup
addpath(genpath('../CPD2/core'));
addpath(genpath('../CPD2/data'));
addpath(genpath('../YAMLMatlab_0.4.3'));
addpath(genpath('../klb_io/'));
addpath(genpath('../common/'));

config_opts = ReadYaml(fullfile(config_path,'config.yaml'));
output_folder = config_opts.output_dir;

% REGISTRATION SETUP
% Do we need to register the whole sample?
to_register = false;
% if registration is available, we can use it
%trans_path = './examples/stack_1/stack_1_transformsMatchGood1_125.mat';
trans_path = fullfile(config_opts.output_dir, ...
    strcat(config_opts.register_file_name_prefix,'_transforms.mat'));
% frames that need to be re-registered
register_again = [];%[10, 13];%[16];
% define threshold for registration (if necessary)
sigma_thres = 30;

% TREE SETUP
% if ground truth tree (for testing) is available, we can use it to clean labels
tree_path = '';
next_graph_file = '';
% should we consider only labels present in ground truth tree above?
clean_data = false;

% DAUGHTER VOLUME THRESHOLD SETUP
vol_thres = 1000;

% PLOTTING SETUP
plot_all = true;
% Set plot sizes 
plot_width = 600;
plot_height = 400;

% IMAGE INDICES
% to consider overall
valid_time_indices = 1:config_opts.track_end_frame+1;
% to use for tracking
inds_to_track = config_opts.track_begin_frame:config_opts.track_end_frame;

%-----END_OF_MAIN_SETUP-----

% DISTANCE SETUP
% I did not find this useful so set it to very liberal values
%minimal distance between mother and daughters
dist_thres = 0;
%maximal distance between mother and daughters' centroid
dist_cent_thres = 100;

% ANISOTROPY INFO: OLD
% Voxel size before making isotropic
%pixel_size_xy_um = 0.208; % um
%pixel_size_z_um = 2.0; % um
% Voxel size after making isotropic
%xyz_res = 0.8320;
% Volume of isotropic voxel
%voxel_vol = xyz_res^3;

% Initialize empty graph and cell array for storing registration
G_based_on_nn = graph;
store_registration = cell((length(valid_time_indices)-1), 1);

for time_index_index = inds_to_track
    if ~plot_all
        close all;
    end

    reg_avail = false;
    if (~to_register) && (~ismember(time_index_index, register_again))
        reg_avail = true;
    end

    %-----Start of Hayden's isotropic code-----
    
    % store this time indexes
    time_index = valid_time_indices(time_index_index);
    
    % store next in series
    time_index_plus_1 = valid_time_indices(time_index_index+1);
    
    % store combined image for both.
    combined_image1 = read_embryo_frame(config_opts.data_path, config_opts.name_of_embryo, ...
        config_opts.suffix_for_embryo, ...
        config_opts.suffix_for_embryo_alternative, ...
        time_index, ...
        numThreads);

    combined_image2 = read_embryo_frame(config_opts.data_path, config_opts.name_of_embryo, ...
        config_opts.suffix_for_embryo, ...
        config_opts.suffix_for_embryo_alternative, ...
        time_index_plus_1, ...
        numThreads);
    % Skip if labels are missing
    if size(combined_image1,1) == 1 || size(combined_image2,1) == 1
        continue
    end
    % STORE MESHGRID
    [X, Y, Z] = meshgrid(1:size(combined_image1, 2), 1:size(combined_image1, 1), 1:size(combined_image1, 3));
    
    % FRACTION OF POINTS (DOWNSAMPLING)
    fraction_of_selected_points =  1/10;  % slow to run at full scale - but make full res points and xform?
    find1 = find(combined_image1(:)~=0);  % this is the indices into combined_image1 to get indices into (X,Y,Z) to the full set of point
    number_of_points = length(find1);
    
    % why random points - why not just subsample by 10 ?
    p = randperm(number_of_points,round(number_of_points * fraction_of_selected_points));
    find1 = find1(p);
    
    ptCloud1 = [X(find1), Y(find1), Z(find1)] - [mean(X(find1)), mean(Y(find1)), mean(Z(find1))];
    %
    find2 = find(combined_image2(:)~=0);
    number_of_points = length(find2);
    
    p = randperm(number_of_points,round(number_of_points * fraction_of_selected_points));
    find2 = find2(p);
    
    ptCloud2 = [X(find2), Y(find2), Z(find2)] - [mean(X(find2)), mean(Y(find2)), mean(Z(find2))];
    ptCloud2 = pointCloud(ptCloud2);

    %-----End of Hayden's isotropic code-----

    % Calculate nuclear volumes
    volumes1 = regionprops3(combined_image1, 'Volume').Volume;
    volumes2 = regionprops3(combined_image2, 'Volume').Volume;

    % This is Masha's version of registration;
    % It has not been updated to most current version.

    if ~reg_avail
    
        sigma2 = 100;
        % Set the options
        opt.method='rigid'; % use rigid registration
        opt.viz=0;          % show every iteration
        opt.outliers=0;     % do not assume any noise
    
        opt.normalize=0;    % normalize to unit variance and zero mean before registering (default)
        opt.scale=0;        % estimate global scaling too (default)
        opt.rot=1;          % estimate strictly rotational matrix (default)
        opt.corresp=0;      % do not compute the correspondence vector at the end of registration (default)
    
        opt.max_it=200;     % max number of iterations
        opt.tol=1e-3;       % tolerance

        % Commented this portion out because of 
        % format incompatibility between CPD output and Lisa's output
%         % Try previous Transform
%         if exist('Transform','var') == 1
%             disp('Transform exists');
%             tform = rigid3d(Transform.R, [0,0,0]);%transpose(Transform.t))
%             ptCloud2 = pctransform(ptCloud2,transpose(tform));
%             ptCloud2Loc = ptCloud2.Location;
%             [Transform, ~, sigma2]=cpd_register(ptCloud1,ptCloud2Loc,opt);
%             if sigma2<sigma_thres
%                 disp('save');
%                 opt_ptCloud2 = ptCloud2Loc;
%             end
%         end
%        opt.tol=1e-3;  
        if sigma2>=sigma_thres
            %disp('Trying identity initialization')
            tform = rigid3d(eye(3), [0,0,0]);
    
            ptCloud2 = pctransform(ptCloud2,tform); % this makes ptCloud a pointCloud
            ptCloud2Loc = ptCloud2.Location;
            % registering Y to X
           % [Transform, ~, sigma2]=cpd_register(ptCloud1,ptCloud2,opt);
            [Transform, ~, sigma2]=cpd_register(ptCloud1,ptCloud2Loc,opt);
            if sigma2<sigma_thres
                %disp('save');
                opt_ptCloud2 = ptCloud2Loc;
            end
        end
        
        sigma2_vect = zeros(100, 1);
        theta_vect = zeros(100, 3);
        opt.tol=1e-3;  
        which_rot = 1;
        opt_sigma = 100;
        while (sigma2 > sigma_thres) && (which_rot < 100)    
        
%             theta1 =rand*360;
%             rot1 = [ cosd(theta1) -sind(theta1) 0; ...
%             sind(theta1) cosd(theta1) 0; ...
%             0 0 1];
%             theta2 =rand*360;
%             rot2 = [ 1 0 0; ...
%             0 cosd(theta2) -sind(theta2); ...
%             0 sind(theta2) cosd(theta2)];
%             theta3 =rand*360;
%             rot3 = [ cosd(theta3) 0 sind(theta3); ...
%             0 1 0; ...
%             -sind(theta3) 0 cosd(theta3)];
%             tform = rigid3d(rot1*rot3*rot2,[0,0,0]);
            tform = rigid3d(orth(randn(3)), [0,0,0]);
            ptCloud2 = pctransform(ptCloud2,tform);
            ptCloud2Loc = ptCloud2.Location;
%             theta_vect(which_rot, 1) = theta1;
%             theta_vect(which_rot, 2) = theta2;
%             theta_vect(which_rot, 3) = theta3;
     
            % registering Y to X
            [Transform, ~, sigma2]=cpd_register(ptCloud1,ptCloud2Loc,opt);
            %disp(sigma2);
            %disp(opt_sigma);
            %disp(sigma_thres);
            if ((sigma2<opt_sigma) || (sigma2<sigma_thres))
                %disp('save');
                opt_sigma= sigma2;
                opt_transform = Transform;
                opt_ptCloud2 = ptCloud2Loc;
            end
            which_rot = which_rot + 1;
            %close all;
        end
        opt.tol=1e-5;       % change tolerance for more accuracy
        [Transform, ~, sigma2]=cpd_register(ptCloud1,opt_ptCloud2,opt);
    else
        transforms = load(trans_path);
        Transform = transforms.store_registration{time_index_index, 1};
        R = Transform.Rotation;
        t = Transform.Translation;
        [M, D]=size(ptCloud2.Location);
        Transform.Y=ptCloud2.Location*R.' + repmat(t(1,:), [M,1]); 
    end
    %sigma2_vect(which_rot) = sigma2;
    store_registration{time_index_index, 1} = Transform;
    % f = figure; f.Position = [50 50 plot_width plot_height]; hold all; 
    % title('After registering Y to X.'); cpd_plot_iter(ptCloud1, Transform.Y);
    % End of registration
    
    % Begin tracking
    [iou_matrix, M, corresponding_ious_for_matches, ...
            cell_labels_I_care_about1, cell_labels_I_care_about2, ...
            center_point_for_each_label1, center_point_for_each_label2, ...
            match_based_on_nearest_neighbors, ~, ~, ...
            alpha_shape_for_each_label1, alpha_shape_for_each_label2] = compute_matches_based_on_point_clouds_CPD(Transform.Y,ptCloud1,...
            combined_image1,combined_image2,find1,find2);
    if clean_data
        m = load(tree_path);
        times = split(m.G_based_on_nn.Nodes.Name, '_');
        tree_inds_from = str2num(cell2mat(times(sum(cell2mat(times(:,1)) == num2str(time_index_plus_1,'%05.3d'),2)==3,2)));
        tree_inds_to = str2num(cell2mat(times(sum(cell2mat(times(:,1)) == num2str(time_index,'%05.3d'),2)==3,2)));

        cell_labels_I_care_about1 = cell_labels_I_care_about1(tree_inds_to,:);
        cell_labels_I_care_about2 = cell_labels_I_care_about2(tree_inds_from,:);
        center_point_for_each_label1 = center_point_for_each_label1(tree_inds_to,:);
        center_point_for_each_label2 = center_point_for_each_label2(tree_inds_from,:);
        alpha_shape_for_each_label1 = alpha_shape_for_each_label1(tree_inds_to,:);
        alpha_shape_for_each_label2 = alpha_shape_for_each_label2(tree_inds_from,:);
        iou_matrix = iou_matrix(tree_inds_to, tree_inds_from);
    end
    %disp('Cell_labels_I_care_about1');
    %disp(cell_labels_I_care_about1);
    %disp('Cell_labels_I_care_about2');
    %disp(cell_labels_I_care_about2);

    store_iou_table{time_index_index, 1} = iou_matrix;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % make the graph..
        
    [nn_three nd]=kNearestNeighbors(center_point_for_each_label1, center_point_for_each_label2,min(3,size(center_point_for_each_label2, 1)));
    %find bad matches
    nn_orig = nn_three;
    %disp(nn_orig);
    bad_matches = [];
    to_bad_matches = [];
    dup=find_duplicates(nn_three(:,1));
    for i=1:size(nn_orig,1)
        to = nn_orig(i,1);
        from = i;
        to_volume = volumes1(cell_labels_I_care_about1(to));
        from_volume = volumes2(cell_labels_I_care_about2(from));
        % this used to include IOU comparisons but I have not found them
        % useful
        flag = true;
        for lvd=1:size(dup,1)
            if to == dup(lvd).val;
                flag = false;
            end
        end
        %if not a daughter candidate and volume disbalance is present
        if (from_volume<=2/3*to_volume) & (from_volume < vol_thres) & flag
%             disp('Adding both because badly matched one-to-one:');
%             disp('From');
%             disp(cell_labels_I_care_about2(i));
%             disp('To');
%             disp(cell_labels_I_care_about1(to));
%             disp('From_volume');
%             disp(from_volume);
%             disp('To_volume');
%             disp(to_volume);

            bad_matches = [bad_matches,i];
            to_bad_matches = [to_bad_matches,to];
        end
    end
    %disp(bad_matches);
    %disp(to_bad_matches);
    %disp('Going through duplicates now')
    dup=find_duplicates(nn_three(:,1));
    for lvd=1:size(dup,1)
        from = dup(lvd).ind;
        to = dup(lvd).val;
        to_volume = volumes1(cell_labels_I_care_about1(to));
        
        %[k,to_volume] = convhull(alpha_shape_for_each_label1{to,:}.Points);
        %disp('To')
        %disp(cell_labels_I_care_about1(to));

        %disp('To_volume')
        %disp(to_volume);
        daughter_flag = true;
        fv = volumes2(cell_labels_I_care_about2(from));
        num_large = sum(fv>vol_thres);
        if (num_large == 0) | (num_large >1)
            %disp('Daughter candidates or more than two large descendants; adding all:')
            %disp('From');
            %disp(cell_labels_I_care_about2(from));
            to_bad_matches = [to_bad_matches,to];
            for j=1:length(from)
                bad_matches = [bad_matches,from(j)];
            end
        else
            %disp('Exactly one large descendant; adding all the rest:')
            %disp('From');
            %disp(cell_labels_I_care_about2(from));
            cells_to_add = from(find(fv<=vol_thres));
            for j=1:length(cells_to_add)
                bad_matches = [bad_matches,cells_to_add(j)];
            end
        end
    end
    %disp('Adding nuclei with no matches:')
    for i=1:size(cell_labels_I_care_about1,1)
        if ~ismember(i, nn_orig(:,1))
            %disp(cell_labels_I_care_about1(i));
            to_bad_matches = [to_bad_matches,i];
        end
    end

    bad_matches = unique(bad_matches);
    to_bad_matches = unique(to_bad_matches);
    %disp('Descendants to be reanalyzed:');
    %disp(bad_matches);
    %disp('Parents to be reanalyzed:');
    %disp(to_bad_matches);
    center1 = center_point_for_each_label1(to_bad_matches,:);
    center2 = center_point_for_each_label2(bad_matches,:);
    %disp('Remapping...');
    if (size(center1,1)>0)
        [nn_three nd]=kNearestNeighbors(center1, center2,min(3,size(center1,1)));%length(center2)));
    
        %disp(nn_three);
        
        alpha1 = alpha_shape_for_each_label1(to_bad_matches,:);
        alpha2 = alpha_shape_for_each_label2(bad_matches,:);
        if length(nn_three(:,1))~=length(unique(nn_three(:,1))) % Reject duplicate nearest neighbors
            dup=find_duplicates(nn_three(:,1));
            %disp(dup);
            for lvd=1:size(dup,1)
                %flag indicates divisions
                flag = 0;
                from = dup(lvd).ind;
                to = dup(lvd).val;
                %disp('To');
                %disp(to);
                to_cell = center1(to,:);
                %disp(alpha1(to,:));
                %disp('To_volume');
                to_volume = volumes1(cell_labels_I_care_about1(to_bad_matches(to)));
                %disp(to_volume);
                %disp('From');
                %disp(from);
                daughter_flag = true;
                for i=1:length(from)
                    %disp(i);
    
                    %disp(to);
                    fv = volumes2(cell_labels_I_care_about2(bad_matches(from(i))));
            
                    %disp(fv);
                    if fv>2/3*to_volume
                        daughter_flag = false;
                        %disp('One of the daughters is too large');
                    end
                end
                if (dup(lvd).length==2) & daughter_flag
                    %check if 2 matches are likely to be daughters
                    from_cell_1 = center2(from(1),:);
                    from_cell_2 = center2(from(2),:);
                    dist_1 = vecnorm(from_cell_1-to_cell);
                    dist_2 = vecnorm(from_cell_2-to_cell);
                    center = (from_cell_1+from_cell_2)/2;
                    dist_cent = vecnorm(center-to_cell);
                    if ((dist_1>dist_thres)&(dist_2>dist_thres)&(dist_cent<dist_cent_thres))
                        flag = 1;
                        %disp('found a pair');
                        %disp(dist_1);
                        %disp(dist_2);
                        %disp(to_cell);
                        %disp(from_cell_2);
                        %disp(center);
    
                    end
                end
                %if not daughters resolve conflicts using second nearest
                %neighbors
                if (flag == 0) & (size(nn_three,2)>1)
                    %disp('Flag is zero, resolving conflicts');
                    %disp(from);
                    %disp(nn_three(from,2));
                    [ic,ia,ib]=intersect(nn_three(from,2),setdiff(1:size(nn_three,1),nn_three(:,1)));
                    %disp(ic);s
                    %disp(ia);
                    %disp(ib);
                    if ~isempty(ia)
                        nn_three(from(ia),1)=nn_three(from(ia),2);
                        nd(from(ia),1)=nd(from(ia),2);
                        loi=from(setdiff(1:size(from,1),ia)); % treat triple and more entries
                        if length(loi)>1
                            [mv,mi]=min(nd(loi,1));
                            loi1=setdiff(1:length(loi),mi);
                            nn_three(loi(loi1),1)=NaN;
                        end
                    else
                        [mv mi]=min(sum(nd(from,1),2));
                        loi=setdiff(from,from(mi));
                        nn_three(loi,1)=NaN;
                    end
                else
                    if (flag == 0) & (size(nn_three,2)>0)
                        [mv mi]=min(sum(nd(from,1),2));
                        loi=setdiff(from,from(mi));
                        nn_three(loi,1)=NaN;
                    end
                end
            end
        end
    else
        nn_three = NaN*zeros(length(bad_matches),1);
    end
    nn=nn_orig(:,1);
    %disp(nn);
    good_inds = nn_three(~isnan(nn_three(:,1)),1);
    nn(bad_matches(~isnan(nn_three(:,1))),1) = to_bad_matches(good_inds);
    nn(bad_matches(isnan(nn_three(:,1))),1) = NaN;
    %nn = nn_three(:,1);
    %nd=nd(:,1);
    %disp('Final matching:')
    %disp(nn(:,1));
    color_vec = [];
    color_map_setting = [1 0 0; 0 0 1];
    sample_graph = graph;
    missing_nodes  = cell2table(cell(0, 3), 'VariableNames', {'xpos' 'ypos' 'zpos'}); 
    for iind = 1:size(cell_labels_I_care_about1, 1)
        this_label = cell_labels_I_care_about1(iind);
        
        % store node props table... so that node can be added with volume
        node_id = {[num2str(time_index,'%05.3d'),'_', ...
            num2str(this_label,'%05.3d')]};
        NodePropsTable = table(node_id, ...
            center_point_for_each_label1(iind, 1), ...
            center_point_for_each_label1(iind, 2), ...
            center_point_for_each_label1(iind, 3), ...
            'VariableNames',{'Name' 'xpos' 'ypos' 'zpos'});
        
        sample_graph = addnode(sample_graph, NodePropsTable);
        % Adding nodes to the main graph to show the single ones
        if numnodes(G_based_on_nn) > 0 && findnode(G_based_on_nn, node_id) == 0
            G_based_on_nn = addnode(G_based_on_nn, NodePropsTable);
        elseif numnodes(G_based_on_nn) == 0
            G_based_on_nn = addnode(G_based_on_nn, NodePropsTable);
        end
        if ismember(iind,nn)
            color_vec = [color_vec; 1];
        else
            color_vec = [color_vec; 1];
            missing_nodes = [missing_nodes; {center_point_for_each_label1(iind, 1), ...
            center_point_for_each_label1(iind, 2), ...
            center_point_for_each_label1(iind, 3)}];
        end
    end

    for iind = 1:size(cell_labels_I_care_about2, 1)
        this_label = cell_labels_I_care_about2(iind);
        
        % store node props table... so that node can be added with volume
        node_id = {[num2str(time_index_plus_1,'%05.3d'),'_', ...
            num2str(this_label,'%05.3d')]};
        NodePropsTable = table(node_id, ...
            center_point_for_each_label2(iind, 1), ...
            center_point_for_each_label2(iind, 2), ...
            center_point_for_each_label2(iind, 3), ...
            'VariableNames',{'Name' 'xpos' 'ypos' 'zpos'});
        
        sample_graph = addnode(sample_graph, NodePropsTable);
        % Adding nodes to the main graph to show the single ones
        if numnodes(G_based_on_nn) > 0 && findnode(G_based_on_nn, node_id) == 0
            G_based_on_nn = addnode(G_based_on_nn, NodePropsTable);
        elseif numnodes(G_based_on_nn) == 0
            G_based_on_nn = addnode(G_based_on_nn, NodePropsTable);
        end
        if (~isnan(nn(iind)))
            color_vec = [color_vec; 2];
        else
            color_vec = [color_vec; 2];
            missing_nodes = [missing_nodes; {center_point_for_each_label2(iind, 1), ...
            center_point_for_each_label2(iind, 2), ...
            center_point_for_each_label2(iind, 3)}];
        end
    end
    for point_index = 1:length(nn)
        
        if (~isnan(nn(point_index)))
            % make directed edges (in time) between matches + 
            % store iou for the match as a graph weight
            sample_graph = addedge(sample_graph, [num2str(time_index,'%05.3d'),'_', ...
                num2str(cell_labels_I_care_about1(nn(point_index)),'%05.3d')],...
                [num2str(time_index_plus_1,'%05.3d'),'_', ...
                num2str(cell_labels_I_care_about2(point_index),'%05.3d')]);
        end
        if (~isnan(nn(point_index)))
            
            % make directed edges (in time) between matches + 
            % store iou for the match as a graph weight
            G_based_on_nn = addedge(G_based_on_nn, [num2str(time_index,'%05.3d'),'_', ...
                num2str(cell_labels_I_care_about1(nn(point_index)),'%05.3d')],...
                [num2str(time_index_plus_1,'%05.3d'),'_', ...
                num2str(cell_labels_I_care_about2(point_index),'%05.3d')]);
            %dist = vecnorm(center_point_for_each_label1(nn(point_index)) - 
            % center_point_for_each_label2(point_index));
            %disp(dist);
            %if (dist>5)
            %    disp('Large distance detected')
            %    %search for another neighbor
            %end 
        end
        
    end
    % % visualization for checking if everything is correct
    % hold all; plot(sample_graph, 'XData', sample_graph.Nodes.xpos, ...
    %     'YData', sample_graph.Nodes.ypos, 'ZData', sample_graph.Nodes.zpos, ...
    %     'NodeCData', color_vec, 'NodeFontSize', config_opts.marker_font_size, ...
    %     'EdgeColor', 'k', 'LineWidth', 2.0, 'MarkerSize', config_opts.marker_size, ...
    %     'Interpreter','none');
    % colormap(color_map_setting);
    % f2 = figure; f2.Position = [600 50 plot_width plot_height];
    % h2 = plot(sample_graph, 'XData', sample_graph.Nodes.xpos, 'YData', ...
    %     sample_graph.Nodes.ypos, 'ZData', sample_graph.Nodes.zpos, ...
    %     'NodeCData', color_vec, 'NodeFontSize', config_opts.marker_font_size, ...
    %     'EdgeColor', 'k', 'LineWidth', 2.0,'NodeLabel', sample_graph.Nodes.Name, ...
    %     'MarkerSize', config_opts.marker_size, 'Interpreter','none');
    sample_graph.Nodes.colorvec = color_vec;
    writetable(sample_graph.Nodes, [output_folder, '/node_info_',num2str(time_index,'%05.3d'),'_',num2str(time_index_plus_1,'%05.3d'),'.csv']);
    
    % % missing_nodes -- check whether they are in sample_graph
    % hold all;
    % colormap(color_map_setting);
    % sc_plot = scatter3(missing_nodes,'xpos','ypos','zpos', 'filled', ...
    %     'Marker','^', 'MarkerFaceColor','#EDB120');
    % sc_plot.SizeData = 150;
    % disp(time_index);

    % % DISPLAY CURRENT TIME INDEX (just to make sure that calculation is not stalled).
    % f3 = figure; f3.Position = [300 450 plot_width plot_height];
    % plot(G_based_on_nn, 'Layout', 'layered','Interpreter','none');    
       
    %% Save the new graph file 
    if isfile(next_graph_file)
        delete(next_graph_file);
    end
    next_graph_file = fullfile(config_opts.output_dir, ...
        strcat(config_opts.track_file_name_prefix,'_',string(config_opts.track_begin_frame),'_', ...
        string(time_index_plus_1),'_graph.mat'));
    save(next_graph_file, 'G_based_on_nn');
    disp('time index');
    disp(time_index);
end

% Save vector of transformations...
%save('transform_labels_pCloud.mat', 'store_registration');
%save('matches.mat','store_matches');
%save('iou_table.mat','store_iou_table');
%save(strcat(output_path, 'graph.mat'),'G_based_on_nn');


end

