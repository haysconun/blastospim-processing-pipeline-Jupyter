function combined_image = read_embryo_frame(data_path, name_of_embryo, ...
                suffix_for_embryo, ...
                suffix_for_embryo_alt, ...
                time_index, ...
                numThreads)
%% Reads a TIF or KLB image and does some sampling to handle isotropy
%% Inputs: 
%%  name_of_embryo: The prefix name of the file name upto the 5 digit time_index
%%  suffix_for_embryo: The suffix of the file name after the time index 
%%  suffix_for_embryo_alternative: The suffix of the file name after the time index if the file has been hand corrected
%%  time_index: The time index
%%  numThreads: Number of threads to use for reading KLB file
    emb_name = fullfile(data_path, strcat(name_of_embryo,num2str(time_index,'%05.5d'),suffix_for_embryo_alt));
    if ~isfile(emb_name)
        emb_name = fullfile(data_path, strcat(name_of_embryo,num2str(time_index,'%05.5d'),suffix_for_embryo));
        if ~isfile(emb_name)
            disp('file does not exist, passing to next iteration');
            combined_image = zeros();
            return;
        end
    end
    if endsWith(suffix_for_embryo, 'klb')
        try
            combined_image = readKLBstack(emb_name, numThreads);
            combined_image = permute(combined_image, [2 1 3]);
        catch ME
            error('KLB could not be read. Try using TIF images. quitting...');
        end
    elseif endsWith(suffix_for_embryo, 'tif')||endsWith(suffix_for_embryo, 'tiff')
        A = imread(emb_name,1);
        tiff_info = imfinfo(emb_name);
        % combine all tiff stacks into 1 3D image.
        combined_image = zeros(size(A,1), size(A,2), size(tiff_info, 1));
        for j = 1:size(tiff_info, 1)
            A = imread(emb_name,j);
            combined_image(:,:,j) = A(:,:,1);
        end
    else
        error('Filename should end with tif, tiff or klb');
    end
  
    resXY = 0.208;
    resZ = 2.0;
    reduceRatio = 1/4;
    combined_image = isotropicSample_nearest(double(combined_image), resXY, resZ, reduceRatio);
end