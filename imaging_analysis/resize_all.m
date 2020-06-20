function R = resize_all(M, scaling)

R = [];

for i = 1:size(M,3)
    R = cat(3, R, imresize(M(:,:,i),scaling));
end
