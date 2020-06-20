function movie_reg = apply_transformation(movie, transformation_X, transformation_Y)

movie_reg = [];
frames    = size(movie,3);

for i = 1:frames
    [reg, SUPPORT] = iat_pixel_warping(movie(:,:,i),transformation_X(:,:,i),transformation_Y(:,:,i));   
    movie_reg = cat(3, movie_reg, reg);
end