function ratio = read_ratio_movie(folder)

all_tiffs = dir([strcat(folder,'\'),'*.tif']);

file_list = {all_tiffs.name};

ratio = read_tiff_movie_16bit(folder, file_list, 1);
