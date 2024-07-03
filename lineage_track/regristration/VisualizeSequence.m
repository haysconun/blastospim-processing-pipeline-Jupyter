
% for sequence of label images
% using sequence of registration transforms
% put all label images in same reference frame

function [] = VisualizeSequence( config_path )

% Set numThreads to the number of cores in your computer. If your processor
% supports hyperthreading/multithreading then set it to 2 x [number of cores]
numThreads = 4;

%% %%%%% NO CHNAGES BELOW %%%%%%%
addpath(genpath('../YAMLMatlab_0.4.3'));
addpath(genpath('../CPD2/core'));
addpath(genpath('../CPD2/data'));
config_opts = ReadYaml(fullfile(config_path,'config.yaml'));
output_folder = '/mnt/ceph/users/hnunley/mouse_data_folder_Apr24/test/output/';% where to OUTPUT

if config_opts.register_begin_frame == 0
    firstTime = 1;
else
    firstTime = config_opts.register_begin_frame;
end
lastTime =  config_opts.register_end_frame-1;

RegistrationFileName = fullfile(config_opts.output_dir, ...
    strcat(config_opts.register_file_name_prefix,'_transforms.mat'));
transforms = load(RegistrationFileName);

%% save as csv
% figure;
for i=firstTime:lastTime
    s(i) = transforms.store_registration{i,1}.minSigma;
end
% plot(firstTime:lastTime,s(firstTime:lastTime),'LineWidth',4,'Color','b');
% xlabel('Frame');
% ylabel('Registration Sigma ');
time_s_mat = [(firstTime:lastTime)', s(firstTime:lastTime)'];
writematrix(time_s_mat, [output_folder, 'error_matrix.csv']);

%%
%% ANISOTROPY HARD-CODED
% Voxel size before making isotropic
pixel_size_xy_um = 0.208; % um
pixel_size_z_um = 2.0; % um
% Voxel size after making isotropic
xyz_res = 0.8320;
% Volume of isotropic voxel
voxel_vol = xyz_res^3;

% Initialize empty graph and cell array for storing registration
% Which image indices to run over...
which_number_vect = 1:config_opts.register_end_frame;
valid_time_indices = which_number_vect;

for time_index_index = firstTime:lastTime
     
    % store this time index
    time_index = valid_time_indices(time_index_index);
    
    % store next in series
    time_index_plus_1 = valid_time_indices(time_index_index+1);
    
    % store combined image for both.
    combined_image1 = read_embryo_frame(config_opts.data_path, ...
            config_opts.name_of_embryo, ...
            config_opts.suffix_for_embryo, ...
            config_opts.suffix_for_embryo_alternative, ...
            time_index, ...
            numThreads);
    
    combined_image2 = read_embryo_frame(config_opts.data_path, ...
            config_opts.name_of_embryo, ...
            config_opts.suffix_for_embryo, ...
            config_opts.suffix_for_embryo_alternative, ...
            time_index_plus_1, ...
            numThreads);
    
    % STORE MESHGRID
    [X, Y, Z] = meshgrid(1:size(combined_image1, 2), 1:size(combined_image1, 1), 1:size(combined_image1, 3));
    
    % FRACTION OF POINTS (DOWNSAMPLING)
    fraction_of_selected_points =  1/10;  % slow to run at full scale - but make full res points and xform?
    find1 = find(combined_image1(:)~=0); 
    number_of_points = length(find1);
        
    p = randperm(number_of_points,round(number_of_points * fraction_of_selected_points));
    find1 = find1(p);
    
    ptCloud1 = [X(find1), Y(find1), Z(find1)] - [mean(X(find1)), mean(Y(find1)), mean(Z(find1))];
   
    [X, Y, Z] = meshgrid(1:size(combined_image2, 2), 1:size(combined_image2, 1), 1:size(combined_image2, 3));

    find2 = find(combined_image2(:)~=0);
    number_of_points = length(find2);
    
    p = randperm(number_of_points,round(number_of_points * fraction_of_selected_points));
    find2 = find2(p);
    
    ptCloud2 = [X(find2), Y(find2), Z(find2)] - [mean(X(find2)), mean(Y(find2)), mean(Z(find2))];
    ptCloud2 = pointCloud(ptCloud2);
    
    X = ptCloud1;
    
    % perform the transformation iteratively (x1 -> x2 -> ... -> xn)
    if time_index_index == lastTime
        newX = X;
    else
        newX = X;
        Transform = transforms.store_registration{time_index_index,1};
        R = Transform.Rotation;
        t = Transform.Translation;
        [M, D]=size(ptCloud2.Location);
        Transform.Y = ptCloud2.Location*R.' + repmat(t(1,:), [M,1]);
    end
    % for no registration
    %newX = X;
    
    none = [];

    %% save csv t->t+1
    % figure; hold all;
    % title_str = strcat({'Registering: '},string(time_index_index),{' to '},string(time_index_plus_1));
    % title(title_str); 
    % view(45,45);
    % if (time_index_index == lastTime)
    %     cpd_plot_iter(X,X);
    % else
    %     cpd_plot_iter(newX,Transform.Y);
    % end
    % pause;

    % where to OUTPUT
    % disp(size(newX));
    % disp(size(Transform.Y));
    if (time_index_index == lastTime)
        combined_mat = [X,X];
    else
        max_size_val = max([size(newX,1), size(Transform.Y,1)]);
        assert(size(newX,2)==3);
        assert(size(Transform.Y,2)==3);
        combined_mat = zeros(max_size_val, size(newX,2)+size(Transform.Y,2));
        combined_mat(1:size(newX,1),1:size(newX,2)) = newX;
        combined_mat(1:size(Transform.Y,1),(size(newX,2)+1):end) = Transform.Y;
        %combined_mat = [newX,Transform.Y];
    end
    writematrix(combined_mat, [output_folder, 'combined_mat_',num2str(time_index_index,'%05.3d'),'_',num2str(time_index_plus_1,'%05.3d'),'.csv']);
    disp(size(combined_mat));
    disp(time_index_index);

    %%
end
%close all;
end
