function write_tiff_stack(stack, filename)

frames = size(stack,3);

imwrite( uint16(stack(:,:,1)), filename, 'Compression','none');

for i=2:frames    
    imwrite( uint16(stack(:,:,i)), filename, 'WriteMode', 'append', 'Compression','none');   
end


