
   
    
close all;

graph_path = '/Users/lbrown/Documents/PosfaiLab/3DStardist/TestEval/EmbryoStats/211106_st5/';
graph_name = 'tracking_results_11_15_sox2_cdx2_again_again_again_fixed.mat';

gg = load(strcat( graph_path , graph_name));
gg = gg.G_based_on_nn;

% plot the graph
figure;
H = plot(gg,'layout','layered');
d =degree(gg);
[s,t] = findedge(gg); % all source and targets for graph
index = 1;
% find every node with only one link (it is a 'start' node) - label it
nNodes = size(gg.Nodes);
for iNode = 1:nNodes
    deg = d(iNode);
    %if (deg == 1)
    %    disp(['start node ',gg.Nodes{iNode,1}{1,1} ] );
    %    labelnode(H,iNode,gg.Nodes{iNode,1});
   % end
    iframe = str2double( gg.Nodes{iNode,1}{1,1}(1:3) );
    if  (iframe == 0)
        labelnode(H,iNode,gg.Nodes{iNode,1});
    end
    % if start of graph has a splits (from 4 to 8)
    if (deg == 2) & (iframe == 0)
        labelnode(H,iNode,gg.Nodes{iNode,1});
    end
        
    if (deg > 2)
        labelnode(H,iNode,gg.Nodes{iNode,1});
        bfound = true;
    end
       

end 

