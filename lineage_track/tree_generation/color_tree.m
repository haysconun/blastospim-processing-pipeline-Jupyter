%% Script to color the tree based on the intensity of images

config_path = 'C:/Users/ab50/Documents/git/lineage_track/test';

%% %%%%% NO CHNAGES BELOW %%%%%%%
version = 3.1;
addpath(genpath('../YAMLMatlab_0.4.3'));

config_opts = ReadYaml(fullfile(config_path,'config.yaml'));

graph_file = fullfile(config_opts.output_dir, config_opts.view_file_name);
load(graph_file) % Graph file from tracking
tf_table = csvread(config_opts.intensity_file,1,0); % Intensities file 
leaf_node = config_opts.leaf_node; % The leaf node timestamp ID

begin_labels = config_opts.begin_labels; % Begin label of intensity line plot
end_labels = config_opts.end_labels; % End label of intensity line plot

% Set the colormap and other options
color_map_setting = eval(config_opts.color_map); 
%color_map_setting = jet(50); 
%color_map_setting = pink(5); 

% Set plot sizes 
plot_width = 1500;
plot_height = 400;
marker_size = 5; % The node marker size 

% Enable or disable smoothing 
enable_smooth = 1; % Set to 0 to disable smoothing

% Specify paired nodel labels that are to be shown in black color
blackout_begin_labels = config_opts.blackout_begin_labels; % Begin label of blackout start
blackout_end_labels = config_opts.blackout_end_labels; % End label of blackout ends matched to the begin labels

version = 3.1;
% Extract the intensities
[r, c] = size(tf_table);
tf_lookup = containers.Map('KeyType','char','ValueType','double');
for i=1:r
    key_val = strcat(num2str(tf_table(i,1),'%03d'), '_', num2str(tf_table(i,2),'%03d'));
    intensity_value = tf_table(i,3);
    tf_lookup(key_val) = intensity_value;
end
mean_intensity = mean(tf_table(:,3));

%% Color the nodes
blackout_node_keys = get_blackout_nodes(G_based_on_nn, ...
    blackout_begin_labels, ...
    blackout_end_labels);
%% Start coloring 
color_vec = [];
number_of_nodes = size(G_based_on_nn.Nodes);
for i=1:number_of_nodes(1)
    node_key = char(G_based_on_nn.Nodes{i,1});
    if ~any(strcmp(blackout_node_keys, node_key))
        if enable_smooth == 1
            node_intensity = get_smoothed_intensity(G_based_on_nn, tf_lookup, ...
                                            mean_intensity, node_key);
        else
            node_intensity = get_intensity(G_based_on_nn, tf_lookup, ...
                                    mean_intensity, node_key);
        end
    else
        node_intensity = 0;
    end
    color_vec = [color_vec; node_intensity];
end

% Label the leafs
label_vec = {};
for i=1:number_of_nodes(1)
    node_key = char(G_based_on_nn.Nodes{i,1});
    if startsWith(node_key, leaf_node)
        label_vec{end+1} = node_key;
    else
        label_vec{end+1} = '';
    end
end
label_vec = label_vec';

% Plot the tree
f = figure; 
f.Position = [50 50 plot_width plot_height]; 
H = plot(G_based_on_nn,'layout','layered', ...
    'NodeCData', color_vec, ...
    'NodeFontAngle', 'italic', ...
    'MarkerSize', marker_size, ...
    'NodeLabel', label_vec, ...
    'LineWidth', 2.0, ...
    'EdgeColor','k','Interpreter','none');
colormap(color_map_setting);

% Check if path plot is needed
for i=1:length(begin_labels)
    start_key = char(begin_labels{1,i});
    end_key = char(end_labels{1,i});
    plot_path = shortestpath(G_based_on_nn, start_key, end_key);
    intensity_plot_vec = [];
    % Extract the intensitied for the path plot 
    for i=1:length(plot_path)
        node_key = char(plot_path{1,i});
        if isKey(tf_lookup,node_key)
            intensity_plot_vec = [intensity_plot_vec; tf_lookup(node_key)];
        end
    end
    figure; LP = plot(intensity_plot_vec);
end

function intensity_val = get_smoothed_intensity(G_based_on_nn, ...
    tf_lookup, ...
    mean_intensity, ...
    node_key)
    % Smooth intensities by averaging immediate neighbours
    intensity_val = 0;
    intensity_count = 0;
    neigh = neighbors(G_based_on_nn, node_key);
    if length(neigh)>1
        neigh_key_1 = char(neigh(1,1));
        neigh_key_2 = char(neigh(2,1));
        if isKey(tf_lookup,node_key)
            intensity_val = tf_lookup(node_key);
            intensity_count = intensity_count + 1;
        end
        if isKey(tf_lookup,neigh_key_1)
            intensity_val = intensity_val + tf_lookup(neigh_key_1);
            intensity_count = intensity_count + 1;
        end
        if isKey(tf_lookup,neigh_key_2)
            intensity_val = intensity_val + tf_lookup(neigh_key_2);
            intensity_count = intensity_count + 1;
        end
        if intensity_count > 0
            intensity_val = intensity_val / intensity_count;
        else
            intensity_val = mean_intensity;
        end
    else
        neigh_key_1 = char(neigh(1,1));
        if isKey(tf_lookup,node_key)
            intensity_val = tf_lookup(node_key);
            intensity_count = intensity_count + 1;
        end
        if isKey(tf_lookup,neigh_key_1)
            intensity_val = intensity_val + tf_lookup(neigh_key_1);
            intensity_count = intensity_count + 1;
        end
        if intensity_count > 0
            intensity_val = intensity_val / intensity_count;
        else
            intensity_val = mean_intensity;
        end
    end
end

function intensity_val = get_intensity(G_based_on_nn, ...
    tf_lookup, ...
    mean_intensity, ...
    node_key)
    % Check node has intensity assigned
    intensity_val = mean_intensity; % Assign default value
    if isKey(tf_lookup,node_key)
        intensity_val = tf_lookup(node_key);
    else
        % Check if previous node has intensity
        neigh = neighbors(G_based_on_nn, node_key);
        neigh_key_1 = char(neigh(1,1));
        if isKey(tf_lookup,neigh_key_1)
            intensity_val = tf_lookup(neigh_key_1);
        elseif length(neigh)>1
            neigh_key_2 = char(neigh(2,1));
            if isKey(tf_lookup,neigh_key_2)
                intensity_val = tf_lookup(neigh_key_2);
            end
        end
    end
end

function blackout_node_keys = get_blackout_nodes(G_based_on_nn, ...
    blackout_begin_label, ...
    blackout_end_label)
    blackout_node_keys = {};
    for i=1:length(blackout_begin_label)
        start_key = char(blackout_begin_label{1,i});
        end_key = char(blackout_end_label{1,i});
        plot_path = shortestpath(G_based_on_nn, start_key, end_key);
        blackout_node_keys = {blackout_node_keys{:}, plot_path{:}};
    end

end