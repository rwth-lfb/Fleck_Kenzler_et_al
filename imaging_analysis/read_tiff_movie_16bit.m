function stack = read_tiff_movie_16bit (folder, file_list, scaling_factor)

z=length(file_list);

x =0 ; y = 0; stack = uint16(zeros(y,x,z));

for i=1:length(file_list)      
     im = uint16(imread(fullfile(folder,file_list{i})));
     
     if (scaling_factor~=1) 
       im = imresize(im,scaling_factor,'Method','nearest', 'Dither',false);
     end
     
     if(i==1)
        x=size(im,1); y=size(im,2);   
        stack=uint16(zeros(x,y,z));
     end
     
     stack(: ,: ,i) = im(:,:,1);
end


