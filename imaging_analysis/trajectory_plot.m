% num_measurements = size(ratio_reg,3)/measurement_length;
%
% mask = ROIs(1).mask;
% VZn = pca_trajectories(VX, VY, mask, measurement_length);
% M=reshape(VZn,size(VZn,1)*size(VZn,2),size(VZn,3)); PCA_V=pca(M);
% volumes =  trajectory_plot(PCA_V, num_measurement ,'D:\test.fig');
%
function [hull_volumes, boundary_volumes, start_end_distances, point_stdevs, average_distances, stdev_distances, sum_of_distances, half_times, max_distances_to_start] = trajectory_plot(V, num_measurements, out_file)

h=figure(); 
set(h, 'Visible', 'off'); set(gcf,'Visible','off','CreateFcn','set(gcf,''Visible'',''on'')')
plot3(V(:,1),V(:,2),V(:,3));
grid on;

l=size(V,1)/num_measurements;

color_names = lines();  
hull_volumes        = zeros(0,num_measurements);
boundary_volumes    = zeros(0,num_measurements);
start_end_distances = zeros(0,num_measurements);
point_stdevs        = zeros(0,num_measurements);
average_distances   = zeros(0,num_measurements);
stdev_distances     = zeros(0,num_measurements);
sum_of_distances    = zeros(0,num_measurements);
half_times          = zeros(0,num_measurements);
max_distances_to_start = zeros(0,num_measurements);

plots = [];

for i=1:num_measurements
    start = (i-1)*l+1;
    stop  = i*l;
    
    hold on;
    p = plot3(V(start:stop,1), V(start:stop,2), V(start:stop,3), '.-', 'Color', color_names(i,:), 'MarkerSize',10, 'DisplayName', strcat('measurement ', num2str(i)));
    plots = cat(1,plots,p);
    
    subset=start:stop;
    [hull, hull_volume] = convhulln(V(start:stop,1:3));
    [the_boundary, boundary_volume]=boundary(V(subset,1:3)); %Matlab help: "Unlike the convex hull, the boundary can shrink towards the interior of the hull to envelop the points."
    hull_volumes(i)     = hull_volume;
    boundary_volumes(i) = boundary_volume;
    
    hold on;
    trisurf(the_boundary,V(subset,1),V(subset,2), V(subset,3), 'FaceColor', color_names(i,:), 'FaceAlpha',0.1, 'EdgeColor', 'none')
    
    %additional features:
    PCA_k=3;
    
    sum_d = 0;
    for j=1:PCA_k
        sum_d = sum_d + (V(start,j) - V(stop,j))^2;
    end
    start_end_distances(i) = sqrt(sum_d); 
    
    point_stdevs(i) = mean(std(V(start:stop,1:PCA_k)));
    
   distances=[];
   distances_to_start = [];
   for r=start:stop-1
        local_d = 0;
        local_d_to_start = 0;
        for j=1:PCA_k
        	local_d = local_d + (V(r,j) - V(r+1,j))^2;
            local_d_to_start = local_d_to_start + (V(1,j) - V(r+1,j))^2;
        end
        local_d   = sqrt(local_d);
        distances = cat(1,distances, local_d);
        local_d_to_start = sqrt(local_d_to_start);
        distances_to_start = cat(1,distances_to_start, local_d_to_start);
   end
   average_distances(i) = mean(distances);
   stdev_distances(i)   = std(distances);
   sum_of_distances(i)  = sum(distances);
   
   half = find(cumsum(distances)>=(sum(distances)/2));
   half_times(i) = half(1);
   
   max_distances_to_start(i) = max(smooth(distances_to_start)); 
end

legend(plots);
savefig(h, out_file);