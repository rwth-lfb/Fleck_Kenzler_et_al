function mask = read_imageJ_ROI(filename, x_size, y_size)

 [sROI] = ReadImageJROI(filename);
 mask   = NaN(1);
  
 if(strcmp(sROI.strType, 'Polygon') || strcmp(sROI.strType, 'Freehand') || strcmp(sROI.strType, 'Traced'))
    
    sROI.mnCoordinates =  sROI.mnCoordinates+1;
    mask = poly2mask(sROI.mnCoordinates(:,1), sROI.mnCoordinates(:,2), x_size, y_size);
 end