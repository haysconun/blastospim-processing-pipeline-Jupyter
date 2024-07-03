%% Script to color the tree based on the intensity of images

config_path = 'C:/Users/ab50/Documents/git/lineage_track/test';

%% %%%%% NO CHNAGES BELOW %%%%%%%
version = 3.1;
addpath(genpath('../YAMLMatlab_0.4.3'));

config_opts = ReadYaml(fullfile(config_path,'config.yaml'));

graph_file = fullfile(config_opts.output_dir, config_opts.view_file_name);
load(graph_file) % Graph file from tracking

% Set plot sizes 
plot_width = 1500;
plot_height = 400;
marker_size = 5; % The node marker size 

% Set the colormap and other options
color_map_setting = eval(config_opts.color_map); 

% Label the leafs
label_vec = {};
number_of_nodes = size(G_based_on_nn.Nodes);
for i=1:number_of_nodes(1)
    node_key = char(G_based_on_nn.Nodes{i,1});
    if startsWith(node_key, config_opts.leaf_node)
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
    'NodeCData', linspace(1,1,number_of_nodes(1)), ...
    'NodeFontAngle', 'italic', ...
    'MarkerSize', marker_size, ...
    'NodeLabel', label_vec, ...
    'LineWidth', 2.0, ...
    'EdgeColor','k','Interpreter','none');
colormap(color_map_setting);

