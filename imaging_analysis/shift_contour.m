function [area_vals, poly_nods2] = shift_contour( VX, VY, poly_nods )

poly_nods2 = [];
[ysize,xsize,zsize] = size(VX);

for frame=1:size(VX,3)
    tmp=[];  
    for i=1:size(poly_nods,1)
       x = VX( round(poly_nods(i,2)),round(poly_nods(i,1)), frame );
       y = VY( round(poly_nods(i,2)),round(poly_nods(i,1)), frame );
       
       %check for image borders:
       if (poly_nods(i,2)+y) > ysize
         y = ysize-poly_nods(i,2); 
       end
       if (poly_nods(i,2)+y) < 1
         y = -poly_nods(i,2)+1;
       end
       if (poly_nods(i,1)+x) > xsize
         x = xsize-poly_nods(i,1);  
       end
       if (poly_nods(i,1)+x) < 1
         x = -poly_nods(i,1)+1;
       end
      
       tmp = [tmp; x,y];
    end
    poly_nods2 = cat(3,poly_nods2, tmp);
end

area_vals = [];
for frame=1:size(VX,3)
    area = poly2mask( poly_nods(:,1)+poly_nods2(:,1,frame), poly_nods(:,2)+poly_nods2(:,2,frame), size(VX,1), size(VX,2));
    area_vals(frame) = sum(sum(area));
end

end

