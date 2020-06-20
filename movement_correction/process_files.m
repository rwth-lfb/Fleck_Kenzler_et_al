function process_files(folders, output_directory, resize)

global progress_h; %handle to progress report field
iat_setup;

for i=1:length(folders)
  
  try
    %progress report
    text = get(progress_h, 'String');  
    new_text = {' '};
    new_text = cat(1, new_text, datestr(now));
    new_text = cat(1, new_text, strcat({'processing folder '}, num2str(i),{' out of '}, num2str(length(folders)),':') );
    new_text = cat(1, new_text, folders(i));
    new_text = cat(1, new_text, {' '});
    set(progress_h, 'String', cat(1, new_text, text));
    drawnow;
    
    subdirectories = get_subdirectories(folders{i});
    %if there are no subdirectories, process the files in folders{i}:
    if(length(subdirectories)==0) subdirectories = {folders{i}}; end
    
    reg_stack_ch00 = cell(length(subdirectories),1); 
    reg_stack_ch01 = cell(length(subdirectories),1);
    stack_ch00     = cell(length(subdirectories),1);
    stack_ch01     = cell(length(subdirectories),1);
    stack_ch02     = cell(length(subdirectories),1);
    VXshift        = cell(length(subdirectories),1);
    VYshift        = cell(length(subdirectories),1);
    name0          = cell(length(subdirectories),1);
    name1          = cell(length(subdirectories),1);
    name0_reg      = cell(length(subdirectories),1);
    name1_reg      = cell(length(subdirectories),1);
    name_VX        = cell(length(subdirectories),1);
    name_VY        = cell(length(subdirectories),1);
    name_metainf   = cell(length(subdirectories),1);
    single_channel = false;
  
    for f = 1:length(subdirectories)
 
      current_folder = subdirectories{f};
      
      %read tiff stacks for channel ch00 and ch01
      [tiffs_ch00, tiffs_ch01, tiffs_ch02, single_channel] = get_channels( current_folder );
      current_stack_ch00       = read_tiff_movie( current_folder, tiffs_ch00, resize);
      current_stack_ch01       = read_tiff_movie( current_folder, tiffs_ch01, resize);
      current_stack_ch02       = read_tiff_movie( current_folder, tiffs_ch02, resize);
      
      %register movies and save to tiff stacks:
      s = regexp(current_folder, '\', 'split');
      folder_name = s(length(s));
    
      namestring = char(strcat(folder_name,'_reg\'));
     
      new_folder = strcat(output_directory, namestring);
      
      if(length(subdirectories)>1) 
          new_folder = char(strcat(output_directory, s(length(s)-1), '_reg\',s(length(s)), '\'));
      end
      mkdir(char(new_folder));
        
      name0{f}     = char(strcat(new_folder, folder_name, '_stack_ch00.tif'));
      name1{f}     = char(strcat(new_folder, folder_name, '_stack_ch01.tif'));
      name2{f}     = char(strcat(new_folder, folder_name, '_stack_ch02.tif'));
      name0_reg{f} = char(strcat(new_folder, folder_name, '_stack_ch00_reg.tif'));
      name1_reg{f} = char(strcat(new_folder, folder_name, '_stack_ch01_reg.tif'));
      name_VX{f}   = char(strcat(new_folder, folder_name, '_VX.mat'));
      name_VY{f}   = char(strcat(new_folder, folder_name, '_VY.mat'));
      name0{f}     = char(strcat(new_folder, folder_name, '_stack_ch00.tif'));
      name_metainf{f} = char(strcat(new_folder, folder_name, '_metainf.mat'));
  
      current_reg_stack_ch00=[]; current_reg_stack_ch01=[]; current_VX=[]; current_VY=[];
      
      if(~single_channel)    
             [current_reg_stack_ch00, current_reg_stack_ch01, current_VX, current_VY] = register(current_stack_ch00, current_stack_ch01);
      else
             [current_reg_stack_ch00, current_VX, current_VY] = register_single_channel(current_stack_ch00);
      end
      
      reg_stack_ch00{f} = current_reg_stack_ch00;
      reg_stack_ch01{f} = current_reg_stack_ch01;
      stack_ch00{f}     = current_stack_ch00;
      stack_ch01{f}     = current_stack_ch01;
      stack_ch02{f}     = current_stack_ch02;
      VXshift{f}        = current_VX;
      VYshift{f}        = current_VY;
    end
    
    % if there is more than one stack, register all stacks to the first
    if (size(stack_ch00,1)>1) 
        
       means_ch00 = cell(length(subdirectories),1);
       means_ch01 = cell(length(subdirectories),1);
       
       for s=1:size(stack_ch00,1) 
          means_ch00{s} = mean(reg_stack_ch00{s},3);
          means_ch00{s} = histeq(min_max_normalise(means_ch00{s}));
          if(~single_channel)
            means_ch01{s} = histeq(min_max_normalise(means_ch01{s}));
            means_ch01{s} = mean(reg_stack_ch01{s},3);
          end
       end
       
       for s=2:size(stack_ch00,1)
         [current_VX, current_VY, ENERGY] = iat_SIFTflow(means_ch00{1}, means_ch00{s}); 
            
         [reg_stack_ch00{s}, SUPPORT] = iat_pixel_warping(reg_stack_ch00{s},current_VX,current_VY);
         
         if(~single_channel)
            [reg_stack_ch01{s}, SUPPRORT] = iat_pixel_warping(reg_stack_ch01{s},current_VX,current_VY);
         end
            
         for t=1:size(VXshift{s},3)
           VXshift{s}(:,:,t) = VXshift{s}(:,:,t) + current_VY;
           VYshift{s}(:,:,t) = VYshift{s}(:,:,t) + current_VX;
         end
       end
      
    end
        
    %write movies
    for s=1:size(stack_ch00,1) 
    
      write_tiff_stack(stack_ch00{s}, name0{s});
      write_tiff_stack(reg_stack_ch00{s}, name0_reg{s});
      if(~single_channel)
        write_tiff_stack(stack_ch01{s}, name1{s});
        write_tiff_stack(reg_stack_ch01{s}, name1_reg{s});
      end
      
      VX = VXshift{s}; VY = VYshift{s};
      save(name_VX{s}, 'VX', '-v7.3');
      save(name_VY{s}, 'VY', '-v7.3');
      
      save(name_metainf{s}, 'single_channel');
    end
    
  catch exception   
    text = get(progress_h, 'String');
    new_text = {' '};
    new_text = cat(1, new_text, datestr(now));
    new_text = cat(1, new_text, {'A problem has occurred with '}, folders{i});
    new_text = cat(1, new_text, getReport(exception, 'basic'));
    set(progress_h, 'String', cat(1,new_text, text));
    drawnow;
  end
  
end

text = get(progress_h, 'String');
new_text = {' '};
new_text = cat(1, new_text, datestr(now));
new_text = cat(1, new_text, 'done'); 
text = cat(1,new_text, text);
set(progress_h, 'String', text);