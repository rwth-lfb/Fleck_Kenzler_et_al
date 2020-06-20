% Martin.Strauch@lfb.rwth-aachen.de
% GUI for the registration (movement correction)
% required: addpath(genpath('.\IAT_v0.9.3')); addpath('.\movement_correction');
%
function movement_correction

%global variables (shared with process_files.m)
%----------------------------------------------

global progress_h;     %handle for progress report
global selected_h;     %handle for file listbox
global savedir_h;      %handle for output directory (text field)
global current_files;  %files selected for inclusion into the listbox
global all_files;      %all files in the listbox
global file_tree; 
global file_container;
global resize_factor;% resize all images by this factor
resize_factor = 0.25;

all_files=[]; current_files=[];
drives  = java.io.File.listRoots;


%GUI elements
%------------

screen_res = get(0,'ScreenSize');
%set limit to window size on larger screens:
if(screen_res(3)> 1366|| screen_res(4) > 768)   
    screen_res(3) = 1366;
    screen_res(4) = 768;   
end  

pos       = [0,0.05*screen_res(4),screen_res(3),screen_res(4)*0.95];
font_size = 11;

%window layout
window = figure('MenuBar','none', 'ToolBar','none', 'NumberTitle','off', 'Name', 'Movement correction for calcium imaging movies (ACTIVE center @ RWTH Aachen University)', 'OuterPosition',pos); 

panel1 = uipanel('Parent',window, 'Position',[0    0 0.25 1]);
panel2 = uipanel('Parent',window, 'Position',[0.25 0 0.1  1]);
panel3 = uipanel('Parent',window, 'Position',[0.35 0 0.35 1]);
panel4 = uipanel('Parent',window, 'Position',[0.7  0 0.3  1]);

%file system
drive_list = [];
for i = 1:length(drives)
  drive_list = cat(1, drive_list, char(drives(i)) );
end

drive_dropbox = uicontrol('style','popupmenu', 'String', drive_list, 'FontSize', font_size, 'Parent', panel1,'units', 'normalized', 'position',[0 0.8 1 0.2], 'CallBack', @drive_selected);

[file_tree, file_container] = uitree('v0', 'Root', drive_list(1,:), 'Parent',panel1, 'SelectionChangeFcn', @select); 
set(file_container, 'Parent', panel1, 'Units','normalized', 'Position',[0 0 1 0.95]);
file_tree.expand(file_tree.getRoot);   
set(file_tree, 'MultipleSelectionEnabled', 1);

%add/remove buttons
button1 = uicontrol('style','pushbutton','String',char(62), 'FontSize', font_size*1.5, 'Parent', panel2,'units', 'normalized', 'position',[0.2 0.5 0.5 0.15], 'CallBack', @button1_pressed);
button2 = uicontrol('style','pushbutton','String',char(60), 'FontSize', font_size*1.5, 'Parent', panel2,'units', 'normalized', 'position',[0.2 0.3 0.5 0.15], 'CallBack', @button2_pressed);

%listbox for selected files
selected_h = uicontrol('style','listbox', 'Parent', panel3, 'FontSize', font_size, 'units', 'normalized', 'position',[0 0 1 1]); 
set(selected_h, 'Max', intmax('uint64'), 'Min', 0);

%choose output directory
button4   = uicontrol('style','pushbutton','String','choose output directory', 'FontSize', font_size, 'Parent', panel4,'units', 'normalized', 'position',[0.05 0.85 0.4 0.1], 'CallBack', @button4_pressed);
savedir_h = uicontrol('style','edit','String', '',  'FontSize', font_size,  'Parent', panel4,'units', 'normalized', 'position',[0.5 0.85 0.45 0.1]);

text1 = uicontrol('style','text','String', 'resize factor (0.1 - 1): ', 'FontSize', font_size,  'Parent', panel4,'units', 'normalized', 'position',[0.02 0.675 0.45 0.1]);
edit1 = uicontrol('style','edit','String', num2str(resize_factor),  'FontSize', font_size,  'Parent', panel4,'units', 'normalized', 'position',[0.5 0.71 0.45 0.1]);
set(edit1, 'CallBack', @edit1_changed);

%start button
button3  = uicontrol('style','pushbutton','String', 'start', 'FontSize',font_size,'Parent', panel4,'units', 'normalized', 'position',[0.05 0.58 0.4 0.1], 'CallBack', @button3_pressed);

%progress report is written here
progress_h = uicontrol('style','edit','String', '', 'HorizontalAlignment','left', 'FontSize', font_size,'Parent', panel4,'units', 'normalized', 'position', [0.05 0 0.9 0.5]);
set(progress_h,'Max',intmax('uint64'));



%drive selection dropbox
function drive_selected(hObject,~) 
    items = get(hObject,'String');
    index = get(hObject,'Value');

    [file_tree, file_container] = uitree('v0', 'Root', items(index,:), 'Parent',panel1, 'SelectionChangeFcn', @select); 
    set(file_container, 'Parent', panel1, 'Units','normalized', 'Position',[0 0 1 0.95]);
    file_tree.expand(file_tree.getRoot);   
    set(file_tree, 'MultipleSelectionEnabled', 1);
end

%add button
function button1_pressed(~,~) 
    if(length(current_files)>0)
        all_files = cat(2,all_files, current_files);
        all_files = unique(all_files);
        set(selected_h,'String', all_files);
    end
end

%remove button
function button2_pressed(~,~)    
    contents = get(selected_h, 'String');
    if length(contents)<1; return; end;
    
    remove = get(selected_h, 'value');
    all_files(:,remove)=[];
    
    value=length(all_files)-1;
    if value<1; value=1; end 

    set(selected_h,'String',all_files,'Value',value);
end


%start button
function button3_pressed(~,~)
    out_folder = get(savedir_h, 'String');
    
    if exist(out_folder,'dir')~=7 
         msgbox('The output directory does not exist.');    
         return; 
    end
    if length(all_files)==0
        msgbox('Please choose at least one folder.');    
        return
    end
    
    temp_folder = ['delete_this', num2str(floor(rand*1e12))];
    [isWritable,m, mid]=mkdir(out_folder, temp_folder);
    if isWritable~=1
        msgbox(strcat({'No write permission for '}, out_folder));
      return
    end
    rmdir(fullfile(out_folder,temp_folder));
    
    process_files(all_files, out_folder, resize_factor);
end


%choose_directory button
function button4_pressed(~,~)
  folder_name = uigetdir();
  
  if folder_name==0
      folder_name='';
  else
    folder_name= strcat(folder_name,'\');
  end
  
  set(savedir_h, 'String',folder_name);
end


%select files from uitree
function select(tree,~)
  nodes = tree.getSelectedNodes;
  
  current_files=[];
  for i = 1:size(nodes,1)
     
     f = arrayfun(@(nd) char(nd.getName), nodes(i).getPath, 'Uniform',false);
   
     file = f(1);
     for j=2:length(f)
        file=strcat(file,'\',f(j));
     end
     
     this_file = char(cellstr(file));
     
     if isdir( this_file ) && length(this_file)>3  %>3: exclude "C:\"
       current_files = cat(2,current_files,file);
     end 
  end
end



%edit field for resize factor
function edit1_changed(~,~)
  input =-1;  
  input = str2num(get(edit1,'String'))
 
  if length(input)==0 
     set(edit1, 'String', num2str(resize_factor));
     return;
  end
  
  if(input>=0.1 && input<=1)
    resize_factor = input;
    set(edit1, 'String', num2str(resize_factor));
  else
    set(edit1, 'String', num2str(resize_factor));
  end
end



end
