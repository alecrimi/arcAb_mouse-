%Parameters
n_substacks = 225;%500;
fname  = 'old_left_scaled.tif';%'left_c.tif';
info = imfinfo(fname);

num_images =  numel(info);

%numFramesStr = regexp(info.ImageDescription, 'images=(\d*)', 'tokens');
%num_images =  str2double(numFramesStr{1}{1});
fname_atlas = 'revert\result.tif';%'result_atlas.tif ';
info2 = imfinfo(fname_atlas);
grouped_region = xlsread('regions_columns.xls');
[ sub, roi] = size(grouped_region);
grouped_region(isnan(grouped_region))=0;
res = zeros(floor(num_images/n_substacks),roi);
   
%load  partially 
temp = imread(fname);
[r,c] = size(temp);
%c = c -4 ;
A = zeros(r,c,n_substacks,'uint16');
reg_atlas = zeros(r,c,n_substacks,'uint16');

count = 1;
for k = 1     :    num_images
        A(:,:,count ) = (imread(fname, k)); %imadjust
        k
        count = count +1;
end

count = 1;
for k = 1     :    num_images
        reg_atlas(:,:,count ) = (imread(fname_atlas, k)); %imadjust
        k
        count = count +1;
end

% For each substack
% Use low-level File I/O to read the file
%fp = fopen(fname , 'rb'); 
%fp2 = fopen(fname_atlas , 'rb'); 
% The StripOffsets field provides the offset to the first strip. Based on
% the INFO for this file, each image consists of 1 strip.
%fseek(fp, info.StripOffsets, 'bof');
%fseek(fp2, info2.StripOffsets, 'bof');
%count = 1;
se = offsetstrel('ball',4,4);

%for k = 1:  n_substacks:  num_images - n_substacks
%k
%{
    for jj = 1 : n_substacks
        tmp = fread(fp, [info.Width info.Height], 'uint16', 0, 'ieee-be')'; 
        %tmp = imread(fname, k + jj -1 );
        A(:,:,jj) = tmp(1:r,1:c);%imread(fname, k);
        reg_atlas(:,:,jj) = fread(fp2, [info2.Width info2.Height], 'uint16', 0, 'ieee-be')'; % imread(fname_atlas, k);
    end
    %}
    %reg_atlas = reg_atlas - 32768; %Adjust from imagej values
    T = adaptthresh(A);       
    bw=imbinarize(A,max(max(max(T))));
   % saveastiff(uint8(bw), [ 'seg2.tif']);
    
    %Create mask according to region
    for ll = 1  :     roi
        ll
        mask = zeros(r,c,n_substacks,'uint16');
        this_roi = grouped_region(:,ll);
        this_roi(this_roi==0) = [];
        %{
        for zz = 1 : n_substacks
        for rr = 1 : r
            for cc = 1 : c
                
                if ( any(reg_atlas(rr,cc,zz) == this_roi )) 
                    mask(rr,cc,zz) = 1;
                end
            end
        end
        end
        %}
        for zz = 1 : length(this_roi)
            %zz
            indices = find( reg_atlas == this_roi(zz) ) ;
            [rr,cc,z] = ind2sub(size(reg_atlas),indices) ;
            
            for pp = 1 : length(rr)
                   mask(rr(pp),cc(pp),z(pp)) = 1;
            end
            
        end
    
    %    for tt = 1 : n_substacks
    %        mask(:,:,tt) = imerode( mask(:,:,tt),se);
    %    end
        
        layer = mask.* uint16(bw);%A ;
        %Segment according to global threshold automatically
       
        res(1,ll) = max(max(max(bwlabeln(layer))));
    end
  %      count = count + 1 ;
%end
%fclose(fp); 
%fclose(fp2); 

save