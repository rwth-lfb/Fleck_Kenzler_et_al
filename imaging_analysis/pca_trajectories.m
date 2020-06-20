% VZn contains the concatenated matrices VZ (absolute X + absolute Y movement for each pixel/time point) 
% for the different measurements/concentration levels (sequence: beginning to end of experiment)
%
function VZn = pca_trajectories(VX, VY, mask, measurement_length)

[height,width,frames] = size(VX);

VZ = zeros(size(VX));

%movement "signal": absolute X and Y movement:
for i=1:frames
    VZ(:,:,i) = abs(VX(:,:,i)) + abs(VY(:,:,i));
end

%iterate over all measurements:
num_measurements = frames/measurement_length

VZn = [];

for m=1:num_measurements
    start = (m-1)*measurement_length+1;
    stop  = m*measurement_length;
    
    this_VZ = VZ(:,:,start:stop);
    
    disp( std(std(std(this_VZ(:,:,1:20)))) );
    
    [height,width,this_frames] = size(this_VZ);
    
    %summed movement --> change in movement
    this_VZ_backup = this_VZ;
    for i=2:this_frames
        this_VZ(:,:,i) = abs(this_VZ_backup(:,:,i) - this_VZ_backup(:,:,(i-1)));  
    end
    
    this_VZ = this_VZ(:,:,2:this_frames);
    [height,width,this_frames] = size(this_VZ);
     
    %centering: normalise s.t. first frames are zero:
    for i=1:height
        for j=1:width
         this_VZ(i,j,:) = subtract_mean(this_VZ(i,j,:), measurement_length-1, 1, 20);   
        end
    end
    
    %apply ROI mask (only regard movement of the ROI)
    h = fspecial('Gaussian', 5, 2);
    for i=1:this_frames 
        this_VZ(:,:,i) = this_VZ(:,:,i).*mask; 
        %this_VZ(:,:,i) = imfilter(this_VZ(:,:,i),h); %optional Gauss filter
    end 
    
    VZn = cat(3,VZn,this_VZ);
end

