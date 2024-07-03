function [iou_matrix, M, corresponding_ious_for_matches, cell_labels_I_care_about1, cell_labels_I_care_about2, center_point_for_each_label1, center_point_for_each_label2, match_based_on_nearest_neighbors, volume_for_each_label1, volume_for_each_label2, alpha_shape_for_each_label1, alpha_shape_for_each_label2] = compute_matches_based_on_point_clouds_CPD(movingReg,ptCloud1,...
    combined_image1,combined_image2,find1,find2)
moved_ptCloud2 = movingReg;

cell_labels_I_care_about1 = unique(combined_image1(find1));
cell_labels_I_care_about1(find(cell_labels_I_care_about1 == 0)) = [];
cell_labels_I_care_about2 = unique(combined_image2(find2));
cell_labels_I_care_about2(find(cell_labels_I_care_about2 == 0)) = [];

% initialize matrix for storing ious
iou_matrix = zeros(length(cell_labels_I_care_about1), length(cell_labels_I_care_about2));
center_point_for_each_label1 = zeros(length(cell_labels_I_care_about1), 3);
center_point_for_each_label2 = zeros(length(cell_labels_I_care_about2), 3);
volume_for_each_label1 = zeros(length(cell_labels_I_care_about1), 1);
volume_for_each_label2 = zeros(length(cell_labels_I_care_about2), 1);
alpha_shape_for_each_label1 = cell(length(cell_labels_I_care_about1), 1);
alpha_shape_for_each_label2 = cell(length(cell_labels_I_care_about2), 1);

% loop through labels in both labelled images (two distinct timepoints)
for i = 1:length(cell_labels_I_care_about1)
    for j = 1:length(cell_labels_I_care_about2)
        
        % store label1
        label1 = cell_labels_I_care_about1(i);
        % store label2
        label2 = cell_labels_I_care_about2(j);
        
        % extract labels in point clouds 1 and 2
        labels_pt_Cloud1 = combined_image1(find1);
        labels_pt_Cloud2 = combined_image2(find2);
        
        % find points in point cloud with given labels
        find_label1 = find(labels_pt_Cloud1 == label1);
        find_label2 = find(labels_pt_Cloud2 == label2);
        
        % extract positions from the point clouds with the given labels
        ptCloud1_for_label1 = ptCloud1(find_label1, :);
        ptCloud2_for_label2 = moved_ptCloud2(find_label2, :);
        
        % MAKE ALPHA SHAPES BASED ON THESE
        shp1 = alphaShape(ptCloud1_for_label1);
        shp2 = alphaShape(ptCloud2_for_label2);
        meanx1 = mean(ptCloud1_for_label1(:,1));
        meany1 = mean(ptCloud1_for_label1(:,2));
        meanz1 = mean(ptCloud1_for_label1(:,3));
        meanx2 = mean(ptCloud2_for_label2(:,1));
        meany2 = mean(ptCloud2_for_label2(:,2));
        meanz2 = mean(ptCloud2_for_label2(:,3));
        center_point_for_each_label1(i, :) = [meanx1, meany1, meanz1];
        center_point_for_each_label2(j, :) = [meanx2, meany2, meanz2];
        volume_for_each_label1(i) = volume(shp1);
        volume_for_each_label2(j) = volume(shp2);
        alpha_shape_for_each_label1{i,1} = shp1;
        alpha_shape_for_each_label2{j,1} = shp2;
        
        
        if (volume(shp1) ~= 0 && volume(shp2) ~= 0)
            
            % check which points from point cloud 1 are in shp2
            id1=inShape(shp2,ptCloud1_for_label1(:,1),ptCloud1_for_label1(:,2),ptCloud1_for_label1(:,3));
            % check which points from point cloud 2 are in shp1
            id2=inShape(shp1,ptCloud2_for_label2(:,1),ptCloud2_for_label2(:,2),ptCloud2_for_label2(:,3));
            
            shp3=alphaShape([ptCloud1_for_label1(id1,1); ptCloud2_for_label2(id2,1)], ...
                [ptCloud1_for_label1(id1,2); ptCloud2_for_label2(id2,2)], ...
                [ptCloud1_for_label1(id1,3); ptCloud2_for_label2(id2,3)]);
            
            shp4 = alphaShape([ptCloud1_for_label1(:,1); ptCloud2_for_label2(:,1)], ...
                [ptCloud1_for_label1(:,2); ptCloud2_for_label2(:,2)], ...
                [ptCloud1_for_label1(:,3); ptCloud2_for_label2(:,3)]);
            
            % compute intersection over union
            iou_matrix(i,j) = volume(shp3) / volume(shp4);
            
        else
            
            iou_matrix(i,j) = 0.0;
            
        end
    end
end



% matchpairs (find which matches maximize the sum of ious)
M = matchpairs(iou_matrix,0,'max');
corresponding_ious_for_matches = zeros(size(M,1), 1);
% store iou for every match
for j = 1:size(M,1)
    corresponding_ious_for_matches(j) = iou_matrix(M(j,1),M(j,2));
end

iou_matrix_new = iou_matrix.';
Mnew = matchpairs(iou_matrix_new,0,'max');
Mnewstore = Mnew;
Mnew(:,2) = Mnewstore(:,1);
Mnew(:,1) = Mnewstore(:,2);

intersect_vect = intersect(Mnew, M,'rows');
union_vect = union(Mnew, M,'rows');

Idx = knnsearch(center_point_for_each_label1,center_point_for_each_label2);
Idx_combined_vect = [Idx, (1:size(center_point_for_each_label2, 1))'];
Idx2 = knnsearch(center_point_for_each_label2,center_point_for_each_label1);
Idx2_combined_vect = [(1:size(center_point_for_each_label1, 1))', Idx2];
C = intersect(Idx_combined_vect, Idx2_combined_vect,'rows');
match_based_on_nearest_neighbors = C;


end

