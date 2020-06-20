function [reg_ch1, transformations_X, transformations_Y] = register_single_channel(stack1)

global progress_h; %handle to progress report field

frames = size(stack1,3);

reg_ch1 = [];
reg_ch2 = [];
transformations_X = [];
transformations_Y = [];

%store in cells for the parfor loop
reg_ch1_cell = cell(frames);
transformations_X_cell = cell(frames);
transformations_Y_cell = cell(frames);

window_size=1; %3

%reference image
ref = stack1(:,:,1);
for i=1:window_size
  ref = ref+stack1(:,:,i);
end
ref = ref./double(window_size);
ref = histeq(min_max_normalise(ref));

for i = 1 : (window_size-1)
  reg_ch1 = cat(3, reg_ch1, stack1(:,:,i));
  reg_ch2 = cat(3, reg_ch2, stack2(:,:,i));
end

text = get(progress_h, 'String');
text = cat(1,text,{' '});
set(progress_h, 'String', text);
drawnow

%parfor i = window_size:frames    
for i = window_size:frames
    
    %report progress
    fprintf('frame no. %i\n',i);
    text = get(progress_h, 'String');
    text{5}= strcat( num2str( round(i/frames*100) ),'%');
    set(progress_h, 'String', text);
    drawnow
    
    %image to be registered against the reference:
    sliding_average = stack1(:,:,i);
    for j=1:(window_size-1)
      sliding_average = sliding_average + stack1(:,:,i-j); 
    end
    sliding_average = sliding_average./double(window_size);
    this_image      = histeq(min_max_normalise(sliding_average ));
        
    PAR.nIterations = 5;
    %determine transformation:
    [VX, VY, ENERGY] = iat_SIFTflow(ref, this_image, PAR); 
  
    %apply transformation to both stacks/channels
    [reg_res_ch1, SUPPRORT] = iat_pixel_warping(stack1(:,:,i),VX,VY);
    reg_ch1 = cat(3, reg_ch1, reg_res_ch1);
    %reg_ch1_cell{i} = reg_res_ch1;
   
    transformations_X = cat(3, transformations_X, VX);
    transformations_Y = cat(3, transformations_Y, VY);
    %transformations_X_cell{i} = VX; 
    %transformations_Y_cell{i} = VY;
    
end

%assemble the results from the parfor loop:
% for i = window_size:frames  
%   transformations_X = cat(3, transformations_X, transformations_X_cell{i});
%   transformations_Y = cat(3, transformations_Y, transformations_Y_cell{i});
%   reg_ch1 = cat(3, reg_ch1, reg_ch1_cell{i});
%   reg_ch2 = cat(3, reg_ch2, reg_ch2_cell{i});
% end



