function subdirectories = get_subdirectories(directory)

subfolders       = dir(directory);
indices          = [subfolders(:).isdir];
subdirectories   = {subfolders(indices).name};
 
remove_list=[];

for f=1:length(subdirectories)
   if(strcmp(subdirectories(f), '.')) remove_list=cat(1,remove_list,f); end
   if(strcmp(subdirectories(f), '..')) remove_list=cat(1,remove_list,f); end
   
   subdirectories(f) = strcat(directory, '\', subdirectories(f));
end

subdirectories(remove_list)=[];


    