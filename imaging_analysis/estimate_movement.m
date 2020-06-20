function [movement_x, movement_y, movement_x_local, movement_y_local] = estimate_movement(VX, VY, ROI)

[m,n,num_time_points]  = size(VX);

idx = find(reshape(ROI.mask,size(ROI.mask,1)*size(ROI.mask,2),1)==1);
VX = reshape(VX,size(VX,1)*size(VX,2),size(VX,3));
VY = reshape(VY,size(VY,1)*size(VY,2),size(VY,3));
movement_x = mean(abs(VX(idx,:)),1)';
movement_y = mean(abs(VY(idx,:)),1)';

%local displacements w.r.t. previous time point:
movement_x_local = movement_x(2:num_time_points) - movement_x(1:num_time_points-1);
movement_y_local = movement_y(2:num_time_points) - movement_y(1:num_time_points-1);
movement_x_local = cat(1,0,movement_x_local);
movement_y_local = cat(1,0,movement_y_local);



