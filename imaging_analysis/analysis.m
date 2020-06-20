%Martin.Strauch@lfb.rwth-aachen.de
%
%main file for the data analysis GUI: 
%creates the toolbar from which all other windows are launched.
%
%the other windows are coded by movie_window.m or timeseries_window.m
%handles to the other windows are kept in the global variables 
%fig0, fig1, fig2 (movies) and fig3 (time series)
%
%naming convention:
%fig0: movie window with name 'channel0', fig1: 'channel1', fig2: 'ratio' of both channels, 
%fig3: timeseries window with name 'ROIs'
%
function analysis

%global variables (shared with the movie and/or time series windows)
%-------------------------------------------------------------------

%data:
global ratio_reg;
global channel0_name;
global channel1_name;
global ch0_min; global ch0_max; global ch1_min; global ch1_max; global ratio_min; global ratio_max;

global display_range_lower;
global display_range_upper;

%X and Y shifts from registration:
global VX;
global VY;
global movie_names;
global movie_names_fullpath; 
global movie_box;

%options from the toolbar:
global single_channel;
single_channel=false;
global stimulus_on;
stimulus_on = 10;
global measurement_length;
global offset_ch0;
offset_ch0 = 0;
global offset_ch1;
offset_ch1 = 0;
global stimulus_on_alternative;  %in case there is a movie shorter than "stimulus_on" time points
stimulus_on_alternative = 1;
global compute_deltaF;
compute_deltaF=0;
global subtract_background;
subtract_background=0;
global smooth_parameter; %for smoothing the contraction curves
smooth_parameter=5;
global epsilon;

%ROIs
global ROIs;
global ROI_counter;
ROI_counter=1;
global background_ROI;
global background_ROI_selected;
background_ROI_selected=0;

%elements from gui, windows, etc:
global active_window;
active_window='';
global window_box;
global roi_box;
global ROI_names;
global background_roi_box;
global background_ROI_names;
global checkbox2;
global fig0; global fig1; global fig2; global fig3;
global frame_fig0; global frame_fig1; global frame_fig2;
global screen_res;
screen_res = get(0,'ScreenSize');
global i_am_busy; %possibility to block actions if the program is busy
i_am_busy=0; 
global mouse_is_over_window;
global working_directory;
global movement_data_type;
global xfile;
global yfile;

%precomputed image for online display of deltaF normalisation:
global deltaF_image;

%constants:
epsilon=0.0000001;
pos = [0,screen_res(4)*0.04,screen_res(3)*0.25,screen_res(4)*0.55];
pos0 = [screen_res(3)*0.4,screen_res(4)*0.59,screen_res(3)*0.3,screen_res(4)*0.38];
pos1 = [screen_res(3)*0.5,screen_res(4)*0.59,screen_res(3)*0.3,screen_res(4)*0.38];
pos2 = [screen_res(3)*0.6,screen_res(4)*0.59,screen_res(3)*0.3,screen_res(4)*0.38];
pos3 = [screen_res(3)*0.25,screen_res(4)*0.04,screen_res(3)*0.75,screen_res(4)*0.55];
font_size = 11;


%GUI elements (windows, buttons, ...)
%------------------------------------

%window layout
window = figure('MenuBar','none', 'ToolBar','none', 'NumberTitle','off', 'Name', 'Mouse data GUI. ACTIVE center @ RWTH Aachen', 'OuterPosition',pos); 
set(window, 'DeleteFcn', @on_close); 

%open, save
button1   = uicontrol('style','pushbutton','String','open folder', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.05 0.85 0.4 0.1], 'CallBack', @button1_pressed);
button2   = uicontrol('style','pushbutton','String','save', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.55 0.85 0.2 0.1], 'CallBack', @button2_pressed);
set(button2, 'Enable', 'off');
button2b   = uicontrol('style','pushbutton','String','save as', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.75 0.85 0.2 0.1], 'CallBack', @button2b_pressed);
set(button2b, 'Enable', 'off');

%normal ROIs and background ROI
button3  = uicontrol('style','pushbutton','String','draw ROI', 'ForegroundColor', 'red', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.05 0.7 0.2 0.1], 'CallBack', @button3_pressed);
button4  = uicontrol('style','pushbutton','String','background', 'ForegroundColor', 'blue', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.25 0.7 0.2 0.1], 'CallBack', @button4_pressed);
set(button3, 'Enable', 'off');
set(button4, 'Enable', 'off');

text1 = uicontrol('style','text','String', 'stimulus on: ', 'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.05 0.6 0.2 0.05]);
edit1 = uicontrol('style','edit','String', num2str(stimulus_on),  'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.25 0.61 0.2 0.04]);
set(edit1, 'CallBack', @edit1_changed);
set(edit1, 'Enable', 'off');

text4 = uicontrol('style','text','String', 'period: ', 'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.05 0.55 0.2 0.05]);
edit2 = uicontrol('style','edit','String', num2str(measurement_length),  'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.25 0.56 0.2 0.04]);
set(edit2, 'CallBack', @edit2_changed);
set(edit2, 'Enable', 'off');

%check boxes:
checkbox1  = uicontrol('style','checkbox','String','compute delta(F)/F', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.55 0.61 0.9 0.05], 'CallBack', @box1_changed);
checkbox2  = uicontrol('style','checkbox','String','subtract background', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.55 0.56 0.9 0.05], 'CallBack', @box2_changed);
set(checkbox1, 'Enable','off');
set(checkbox2, 'Enable','off');

%ratio movie display range:
text6 = uicontrol('style','text','String', 'display range: ', 'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.05 0.48 0.2 0.05]);
text5 = uicontrol('style','text','String', 'lower: ', 'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.05 0.43 0.2 0.05]);
edit3 = uicontrol('style','edit','String', num2str(display_range_lower),  'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.25 0.44 0.2 0.04]);
set(edit3, 'CallBack', @edit3_changed);
set(edit3, 'Enable', 'off');
text6 = uicontrol('style','text','String', 'upper: ', 'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.05 0.38 0.2 0.05]);
edit4 = uicontrol('style','edit','String', num2str(display_range_upper),  'FontSize', font_size,  'Parent', window,'units', 'normalized', 'position',[0.25 0.39 0.2 0.04]);
set(edit4, 'CallBack', @edit4_changed);
set(edit4, 'Enable', 'off');

%load precomputed ratio movie:
button5   = uicontrol('style','pushbutton','String','load ratio', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.55 0.7 0.2 0.1], 'CallBack', @button5_pressed);
set(button5, 'Enable', 'off');

%load ROIs button:
button6   = uicontrol('style','pushbutton','String','load ROIs', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.75 0.7 0.2 0.1], 'CallBack', @button6_pressed);
set(button6, 'Enable', 'off');

%PCA trajectories button:
button7  = uicontrol('style','pushbutton','String','PCA trajectories', 'ForegroundColor', 'black', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.55 0.39 0.4 0.1], 'CallBack', @button7_pressed);
set(button7, 'Enable', 'off');


%list of windows
win_list   = {'channel0'};
win_list   = cat(1,win_list,'channel1');
win_list   = cat(1,win_list,'ratio');
win_list   = cat(1,win_list,'ROIs');
window_box = uicontrol('style','listbox','String',win_list, 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.05 0.20 0.9 0.15], 'CallBack', @window_box_changed);
set(window_box,'Min',1, 'Max',1);
set(window_box,'Value',1);
set(window_box,'Enable','off');

%list of movies
movie_box = uicontrol('style','listbox','String',{''}, 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0.05 0.02 0.9 0.15], 'CallBack', @movie_box_changed);
set(movie_box,'Min',1, 'Max',1);
set(movie_box,'Value',1);
set(movie_box,'Enable','off');



%Functions behind the toolbar buttons:
%-------------------------------------

%open button
function button1_pressed(~,~)
    persistent folder_name;  %remember folder from last time
    
    if(exist('path.mat')) load path; end;
    if(i_am_busy==1) return; end;

    folder_name = uigetdir(folder_name);
    if (folder_name==0) return; end
   
    try   
        hourglass_on;  
        submovies = get_subdirectories(folder_name);
        ROIs=[]; ROI_counter = 1; ROI_names=''; background_ROI_names='';
        background_ROI=[]; background_ROI_selected=0;
   
        if(length(submovies)==0) 
            read_data(folder_name); 
            read_ROIs(folder_name);
     
            movie_names_fullpath = {folder_name};
            [pathstr,name,ext]   = fileparts(folder_name);
            movie_names          = {name};
        else
            read_data(submovies{1});
            read_ROIs(submovies{1});
        
            movie_names_fullpath = submovies;
        
            for i=1:length(submovies)
                [pathstr,name,ext] = fileparts(submovies{i});
                submovies{i}       = name;
            end  
            movie_names = submovies;
        end
  
        %currently, the GUI starts up with default values, i.e. no background
        %subtraction etc. --> recompute the ROI timeseries from scratch: 
        recompute_ROIs();
    
        %close old figures and clear all variables
        this_fig = findobj('type','figure','name','channel0');
        if(length(this_fig)>0) close(this_fig); end  
        this_fig = findobj('type','figure','name','channel1');
        if(length(this_fig)>0) close(this_fig); end  
        this_fig = findobj('type','figure','name','ratio');
        if(length(this_fig)>0) close(this_fig); end  
        this_fig = findobj('type','figure','name','ROIs');
        if(length(this_fig)>0) close(this_fig); end  
  
        fig3 = time_series_window('ROIs', pos3); 
        fig0 = movie_window('channel0', pos0, 1);
        fig1 = movie_window('channel1', pos1, 1); 
        fig2 = movie_window('ratio', pos2, 1);
    
        set(roi_box,'String', ROI_names);
        set(background_roi_box,'String', background_ROI_names);
        set(movie_box, 'String', movie_names);
        set(movie_box,'Value',1);
        set(movie_box,'Enable','on');
    catch exception
        disp(exception)
        hourglass_off; 
        return;
    end
    
    measurement_length = size(ratio_reg,3);
    set(edit2, 'String', num2str(measurement_length));
    set(edit1, 'Enable', 'on');
    set(edit2, 'Enable', 'on');
    set(checkbox1, 'Enable', 'on');
    set(window_box,'Value',1);
    set(window_box,'Enable','on');
    set(edit3, 'Enable', 'on');
    set(edit3, 'String', num2str(display_range_lower));
    set(edit4, 'Enable', 'on');
    set(edit4, 'String', num2str(display_range_upper));
    set(button2, 'Enable', 'on');
    set(button2b, 'Enable', 'on');
    set(button3, 'Enable', 'on');
    set(button4, 'Enable', 'on');
    set(button5, 'Enable', 'on');
    set(button6, 'Enable', 'on');
    set(button7, 'Enable', 'on');
  
    active_window='channel0';
    figure(fig0);
  
    working_directory = folder_name;
  
    try
        save 'path.mat' folder_name;
    catch exception
        hourglass_off; 
    end;
 
    hourglass_off;
end


%save as button
function button2b_pressed(~,~)
    saveas_folder_name='';   
    if(i_am_busy==1) return; end;

    saveas_folder_name = uigetdir(saveas_folder_name,'select directory for saving');
    if (saveas_folder_name==0) return; end

    hourglass_on(); 
    try    
        disp(working_directory)
        disp(saveas_folder_name)
        copyfile(working_directory, saveas_folder_name);
    catch exception
        disp(exception)    
        msgbox('Data could not be saved 1.');
        hourglass_off();
        return;
    end
  
    try
        backup_working_directory = working_directory;
        backup_movie_names_fullpath = movie_names_fullpath;
  
        working_directory = saveas_folder_name;
        movie_names_fullpath{1} = saveas_folder_name;
    catch exception
        disp(exception)    
        msgbox('Data could not be saved 2.');
        hourglass_off();
    
        working_directory = backup_working_directory;
        movie_names_fullpath = backup_movie_names_fullpath;
        return;
    end
   
    save_button();
    msgbox('Changes have been saved.')
    hourglass_off();
end




%save button
function button2_pressed(~,~)
    if(i_am_busy==1) return; end;
    hourglass_on(); 
    save_button(); 
    msgbox('Changes have been saved.')
    hourglass_off();
end


function save_button()    
    try
        %remove ROIs deleted by the user
        remove_list=[];
        for i=1:length(ROIs)
            if(length(ROIs(i).xy)==0) remove_list=cat(1,remove_list,i); end 
        end
        ROIs(remove_list)=[];
        
        if(length(movie_names_fullpath)==1)
            save_data(movie_names_fullpath{1});
            %save_pca();
        else  
            %read one movie after another, compute ROI signals and then save  
            for i=1:length(movie_names_fullpath)   
                read_data(movie_names_fullpath{i}); 
                recompute_ROIs();
                hourglass_on();
                save_data(movie_names_fullpath{i});
            end
            %PCA for the concatenated movies:
            %save_pca();
    
            %finally, back to the movie that was on display before:
            the_chosen_one = get(movie_box,'Value');
            read_data(movie_names_fullpath{the_chosen_one});  
            recompute_ROIs();
            hourglass_on();
            replace_movies(); 
        end
    catch exception
        disp(exception)    
        msgbox('Data could not be saved.');
        hourglass_off();
        return;
    end
end



%PCA: compute and save PCA trajectories
function button7_pressed(~,~)
    if(i_am_busy==1) return; end;
  
    try
        hourglass_on();
        tic
        save_pca();
        toc
        msgbox('PCA trajectories have been saved to disk.')
        hourglass_off();
    catch exception
        disp(exception)    
        msgbox('PCA trajectories could not be saved.');
        hourglass_off();
        return;
    end
end


%saves PCA results
function save_pca()
    [part1,part2,part3] = fileparts(movie_names_fullpath{1});
    filename_fig = char(fullfile(part1, 'PCA_trajectories'));
    filename_xls = char(fullfile(part1, 'PCA_parameters.xlsx'));
    
    if(length(movie_names_fullpath)==1)
        filename_fig = char(fullfile(strcat(part1,'\',part2), 'PCA_trajectories'));
        filename_xls = char(fullfile(strcat(part1,'\',part2), 'PCA_parameters.xlsx'));
    end
    
    if(exist(filename_xls))  delete(filename_xls); end  
    delete(fullfile(strcat(part1,'\',part2),'*.fig'));
    
    scaling=1;
    %memory/computing time issues: scale down movies that are larger than 500 (average side length)
    if(size(VX,1)>500) 
        side_length = (size(VX,1)+size(VX,2))/2;
        scaling = round(1/(side_length/500),2)
    end
    %
    
    PCA_VX = []; PCA_VY = [];
    if(length(movie_names_fullpath)==1) 
        %PCA_VX = VX; PCA_VY = VY; 
        PCA_VX = resize_all(VX, scaling); PCA_VY = resize_all(VY, scaling);
    else
        for i=1:length(movie_names_fullpath)  
            read_data(movie_names_fullpath{i});
            %PCA_VX = cat(3,PCA_VX,VX); PCA_VY = cat(3,PCA_VY,VY);
            PCA_VX = cat(3,PCA_VX,resize_all(VX, scaling)); PCA_VY = cat(3, PCA_VY, resize_all(VY, scaling));
        end
    end
    
    Excel = actxserver ('Excel.Application');
    if ~exist(filename_xls,'file')
        ExcelWorkbook = Excel.workbooks.Add;
        ExcelWorkbook.SaveAs(filename_xls);
        ExcelWorkbook.Close(false);
    end
    invoke(Excel.Workbooks,'Open',filename_xls);
     
    for i=1:length(ROIs)    
        num_measurements = size(PCA_VX,3)/measurement_length;
        mask = imresize(ROIs(i).mask,scaling);
        
        VZn = pca_trajectories(PCA_VX, PCA_VY, mask, measurement_length);
        M=reshape(VZn,size(VZn,1)*size(VZn,2),size(VZn,3)); 
        
        %[coeff,score,latent,tsquared,explained,mu] = pca(M); PCA_V = coeff;
        [U S PCA_V] = svd(M-mean(M),'econ');
        sigma = zeros(0,size(S,1));
        for a=1:size(S,1)
          sigma(a)=S(a,a);
        end
        explained = cumsum(sigma.^2 / sum(sigma.^2))';
        
        [hull_volumes, boundary_volumes, start_end_distances, point_stdevs, average_distances, stdev_distances, sum_of_distances, half_times, max_distances_to_start] = trajectory_plot(PCA_V, num_measurements , strcat(filename_fig,'_',ROIs(i).name,'.fig'));
        
        sheet_name = 'hull volume';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, hull_volumes', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls,  [1:length(hull_volumes)]', sheet_name, strcat(char(64+1), '2'));
        
        sheet_name = 'boundary volume';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, boundary_volumes', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls, [1:length(boundary_volumes)]', sheet_name, strcat(char(64+1), '2'));
        
        sheet_name = 'start to end distance';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, start_end_distances', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls,  [1:length(start_end_distances)]', sheet_name, strcat(char(64+1), '2'));
          
        sheet_name = 'average point distance';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, average_distances', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls,  [1:length(average_distances)]', sheet_name, strcat(char(64+1), '2'));
        
        sheet_name = 'std. dev. of point distances';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, stdev_distances', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls,  [1:length(stdev_distances)]', sheet_name, strcat(char(64+1), '2'));
        
        sheet_name = 'path length';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, sum_of_distances', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls,  [1:length(sum_of_distances)]', sheet_name, strcat(char(64+1), '2'));
        
        sheet_name = 'distance half time';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, half_times', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls,  [1:length(half_times)]', sheet_name, strcat(char(64+1), '2'));
        
        sheet_name = 'max. distance to start';
        xlswrite1(filename_xls, {ROIs(i).name}, sheet_name, strcat(char(64+i+1), '1'));
        xlswrite1(filename_xls, max_distances_to_start', sheet_name, strcat(char(64+i+1), '2'));
        xlswrite1(filename_xls, {'measurement'}, sheet_name, strcat(char(64+1), '1'));
        xlswrite1(filename_xls,  [1:length(max_distances_to_start)]', sheet_name, strcat(char(64+1), '2'));
 
    end
    
    sheet_name = 'PCA variance explained';
    xlswrite1(filename_xls, {'percent of variance'}, sheet_name, 'B1');
    xlswrite1(filename_xls, round(explained,2), sheet_name, 'B2');
    xlswrite1(filename_xls, {'PC'}, sheet_name, 'A1');
    xlswrite1(filename_xls,  [1:length(explained)]', sheet_name, 'A2');
    
    invoke(Excel.ActiveWorkbook,'Save');
    Excel.Quit
    Excel.delete
    clear Excel  
end    
    


%saves ROI signals and contraction curves (into .xls) and movies (into tiff-stacks)
function save_data(directory) 
    all_tiffs = dir([strcat(directory,'\'),'*.tif']);
    [fp1, fp2, fp3] = fileparts(all_tiffs(1).folder);
    name = fp2;
  
    filename       = char(fullfile(directory, strcat(name,'_ROIs.mat'))); 
    filename_xls   = char(fullfile(directory, strcat(name,'_ROIs.xls'))); 
    filename_xls2  = char(fullfile(directory, strcat(name,'_parameters.xlsx')));
    %in case of several movies in subdirectories, save into main directory:
    if(length(movie_names_fullpath)>1)
        [part1,part2,part3] = fileparts(movie_names_fullpath{1});
        filename_xls2 = char(fullfile(strcat(part1,'\'), strcat(name,'_parameters.xlsx')));
    end 
  
    filename_tif   = char(fullfile(directory, strcat(name,'_ROIs.tif')));  
    filename_fig   = char(fullfile(directory, strcat(name,'_contraction_trajectories'))); 
    directory_name = char(fullfile(directory, strcat(name,'ROIs\')));
    if(exist(filename_xls2))  delete(filename_xls2); end
    if(exist(filename_xls))   delete(filename_xls); end
    if(exist(filename_tif))   delete(filename_tif); end
    if(exist(filename))       delete(filename); end
    delete(fullfile(directory,'*.eps'));
  
    if(length(ROIs)>0 || length(background_ROI)>0) 
        try
            save('-v7.3', filename, 'ROIs', 'ROI_names', 'ROI_counter', 'background_ROI', 'background_ROI_names', 'stimulus_on','deltaF_image');
        catch exception
            disp(exception)
        end
        for i=1:length(background_ROI)
            sheet_name = background_ROI(i).name;
            xlswrite(filename_xls, {'calcium signal'}, sheet_name, 'A1');
            timeseries = background_ROI(i).timeseries_ratio_reg;
            xlswrite(filename_xls, timeseries, sheet_name, 'A2');
        end
    
        Excel = actxserver ('Excel.Application');
        if ~exist(filename_xls2,'file')
            ExcelWorkbook = Excel.workbooks.Add;
            ExcelWorkbook.SaveAs(filename_xls2);
            ExcelWorkbook.Close(false);
        end
        invoke(Excel.Workbooks,'Open',filename_xls2);
     
        %Time series (calcium signal and movement)
        for i=1:length(ROIs)
            timeseries         = ROIs(i).timeseries_ratio_reg;     
            timeseries_deltaff = delta_FF2(timeseries,measurement_length,1,stimulus_on); 
      
            M_x = ROIs(i).movement_x;
            M_y = ROIs(i).movement_y;
            %norm to beginning of sub-movie:
            M_x = subtract_mean(M_x,measurement_length,1,stimulus_on);
            M_y = subtract_mean(M_y,measurement_length,1,stimulus_on);
             
            M_x_unsmoothed = M_x; M_y_unsmoothed = M_y;
            vector_norm            = sqrt((M_x.^2 + M_y.^2));
            vector_norm_unsmoothed = vector_norm;
        
            M_x_local = ROIs(i).movement_x_local;
            M_y_local = ROIs(i).movement_y_local;
            M_x_local_unsmoothed = M_x_local;
            M_y_local_unsmoothed = M_y_local;
       
            num_time_points = size(ratio_reg,3);
            for j=1:measurement_length:num_time_points
                M_x_local(j:j+measurement_length-1) = smooth(M_x_local(j:j+measurement_length-1),10);
                M_y_local(j:j+measurement_length-1) = smooth(M_y_local(j:j+measurement_length-1),10);
                M_x(j:j+measurement_length-1) = smooth(M_x(j:j+measurement_length-1),10);
                M_y(j:j+measurement_length-1) = smooth(M_y(j:j+measurement_length-1),10);
                vector_norm(j:j+measurement_length-1) = smooth(vector_norm(j:j+measurement_length-1),10);
            end
       
            sheet_name = 'vector norm';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, vector_norm_unsmoothed, sheet_name, strcat(char(64+i),'2'));
    
            sheet_name = 'x movement';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_x_unsmoothed, sheet_name, strcat(char(64+i),'2'));
       
            sheet_name = 'y movement';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_y_unsmoothed, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'x movement (change)';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name , strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_x_local_unsmoothed, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'y movement (change)';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_y_local_unsmoothed, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'x movement (change), smoothed';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_x_local, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'y movement (change), smoothed';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name , strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_y_local, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'x movement, smoothed';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_x, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'y movement, smoothed';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, M_y, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'vector norm, smoothed';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, vector_norm, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'calcium signal';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, timeseries, sheet_name, strcat(char(64+i),'2'));

            sheet_name = 'calcium signal (delta F)';
            xlswrite1(filename_xls2, {ROIs(i).name}, sheet_name, strcat(char(64+i),'1'));
            xlswrite1(filename_xls2, timeseries_deltaff, sheet_name, strcat(char(64+i),'2'));

            %quiver plots:
            temp_h = figure(); set(temp_h, 'Visible', 'off');
            l=length(M_x);
            quiver(M_x(5:(l-5))', M_y(5:(l-5))', 1);
            pbaspect([12 2 2]);
            set(temp_h,'PaperOrientation','landscape');
            set(temp_h,'PaperUnits','normalized');
            set(temp_h,'PaperPosition', [0 0 1 1]);
            print(temp_h,'-depsc', char(fullfile(directory, strcat(name, '_', ROIs(i).name,'_vectors.eps'))), '-r1200', '-painters');    
            close(temp_h);
       
            temp_h = figure(); set(temp_h, 'Visible', 'off');
            l=length(M_y);
            quiver(M_x_local(5:(l-5))', M_y_local(5:(l-5))', 1);
            pbaspect([12 2 2]);
            set(temp_h,'PaperOrientation','landscape');
            set(temp_h,'PaperUnits','normalized');
            set(temp_h,'PaperPosition', [0 0 1 1]);
            print(temp_h,'-depsc', fullfile(directory, char(strcat(name, '_', ROIs(i).name,'_vectors_change.eps'))), '-r1200', '-painters');   
            close(temp_h);
        end
    
        invoke(Excel.ActiveWorkbook,'Save');
        Excel.Quit
        Excel.delete
        clear Excel
     
        %ROI positions   
        ROI_image = draw_ROI('channel0', 1, ROIs(1).xy, 2^16-1); 
        imwrite(ROI_image, filename_tif, 'Compression','none');
        for i=2:length(ROIs)  
            ROI_image = draw_ROI('channel0', 1, ROIs(i).xy, 2^16-1); 
            imwrite( ROI_image, filename_tif, 'WriteMode', 'append', 'Compression','none');
        end
    end %endif

    try
        %if the VX/VY .mat files are still of the old (floating point) type,
        %overwrite them with the integer variant to save memory/speed up loading times:
        if(~strcmp(movement_data_type, 'int16'))
            save('-v7.3', xfile.Properties.Source, 'VX');
            save('-v7.3', yfile.Properties.Source, 'VY');
        end
    catch exception
        disp(exception);
    end
end



%load ImageJ ROIs button:
function button6_pressed(~,~)
    if(i_am_busy==1) return; end;
  
    roi_folder = uigetdir(working_directory);
    if (roi_folder==0) return; end
  
    roi_files = dir([strcat(roi_folder,'\'),'*.roi']);
  
    hourglass_on();
    for i=1:length(roi_files)
        load_imageJ_ROIs(strcat(roi_folder,'\',roi_files(i).name));
    end
    hourglass_off();
   
    try
        %default: activate all ROIs   
        roi_box.Value=1:length(roi_box.String);
        update_windows(); 
    catch exception
         disp(exception)
    end
end


% currently loads only polygon ROIs (other geometrical objects do not have the mnCoordinates field)
%
function load_imageJ_ROIs(filename)
    [sROI] = ReadImageJROI(filename);
  
    if(strcmp(sROI.strType, 'Polygon') || strcmp(sROI.strType, 'Freehand'))
        %check if the ROIs are from the wrong movie (size doesn't match).
        if(max(sROI.mnCoordinates(:,2))>size(VX,1)) return; end;
        if(max(sROI.mnCoordinates(:,1))>size(VX,2)) return; end;
 
        sROI.mnCoordinates =  sROI.mnCoordinates+1;
        mask = poly2mask(sROI.mnCoordinates(:,1), sROI.mnCoordinates(:,2), size(VX,1), size(VX,2));
    
        ROIs(ROI_counter).xy      = sROI.mnCoordinates;
        ROIs(ROI_counter).mask    = mask;
        ROIs(ROI_counter).channel = active_window;
 
        extract_ROI(mask);
    end
end



%ROI button
function button3_pressed(~,~)        
    if(i_am_busy==1) return; end;
 
    %escape key terminates any running imfreehand()
    robot = java.awt.Robot;
    robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
    robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE);   
     
    if(strcmp(active_window,'ROIs') || strcmp(active_window,'')) return; end
 
    try   
        fig=figure( findobj('type','figure','name', active_window) );
 
        set(window_box,'Enable', 'off');
        set(button4,'Enable', 'off');
        h = imfreehand();
        set(window_box,'Enable', 'on');
        set(button4,'Enable', 'on');
  
        setColor(h,'red');
        setClosed(h,true);

        handles=imhandles(fig);
      
        ROIs(ROI_counter).xy      = getPosition(h);
        ROIs(ROI_counter).mask    = createMask(h, handles(length(handles)));
        ROIs(ROI_counter).channel = active_window;
        delete(h);
        drawnow;
  
        %cut off ROIs at the image borders:
        [xsize,ysize,zsize]=size(VX);
 
        for i=1:size(ROIs(ROI_counter).xy,1)   
            if ROIs(ROI_counter).xy(i,1) > ysize 
                ROIs(ROI_counter).xy(i,1) = ysize;
            end
            if ROIs(ROI_counter).xy(i,1) < 1 
                ROIs(ROI_counter).xy(i,1) = 1;
            end
            if ROIs(ROI_counter).xy(i,2) > xsize 
                 ROIs(ROI_counter).xy(i,2) = xsize;
            end
            if ROIs(ROI_counter).xy(i,2) < 1 
                ROIs(ROI_counter).xy(i,2) = 1;
            end
        end
 
        extract_ROI(ROIs(ROI_counter).mask);
 
    catch exception
        disp(exception)
    end
 
    try
        %default: activate all ROIs   
        roi_box.Value=1:length(roi_box.String);
        update_windows();
    catch exception
        disp(exception)
    end
end


function extract_ROI(mask)
    hourglass_on(); 
    ROIs(ROI_counter).timeseries_ratio_reg = make_timeseries(mask, ratio_reg); 
    [movement_x, movement_y, movement_x_local, movement_y_local] = estimate_movement(VX, VY, ROIs(ROI_counter));
   
    ROIs(ROI_counter).movement_x = movement_x;
    ROIs(ROI_counter).movement_y = movement_y;
    ROIs(ROI_counter).movement_x_local = movement_x_local;
    ROIs(ROI_counter).movement_y_local = movement_y_local;
    hourglass_off();
  
    if(ROI_counter==1) 
        ROI_names = {'data_ROI_1'}; 
        ROIs(ROI_counter).name='data_ROI_1';
    else
        new_name=strcat('data_ROI_',num2str(ROI_counter));
        if(strcmp(ROI_names{1},'')) 
            ROI_names{1} = new_name; 
        else
            ROI_names = cat(1, ROI_names, new_name);
        end
     
        ROIs(ROI_counter).name=new_name;
    end
 
    set(roi_box, 'String', ROI_names);
    set(roi_box, 'Enable', 'on');
    ROI_counter = ROI_counter+1;
end



%Background ROI button
function button4_pressed(~,~)
    if(i_am_busy==1) return; end;
 
    %escape key terminates any running imfreehand()
    robot = java.awt.Robot;
    robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
    robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE);   
 
    movies_to_front();
    if(strcmp(active_window,'ROIs') || strcmp(active_window,'')) return; end
 
    try
        fig= figure( findobj('type','figure','name', active_window) );
  
        set(window_box,'Enable', 'off');
        set(button3,'Enable', 'off');
        background_ROI_handle = imfreehand;
        set(window_box,'Enable', 'on');
        set(button3,'Enable', 'on');
   
        setColor(background_ROI_handle,'blue');
  
        handles=imhandles(fig);
        background_ROI(1).xy      = getPosition(background_ROI_handle);
        background_ROI(1).mask    = createMask(background_ROI_handle, handles(length(handles)));
        background_ROI(1).channel = active_window;
        background_ROI_selected   = 1;
        background_ROI.name       = 'background_ROI';
  
        delete(background_ROI_handle);
        drawnow;
 
        %cut off ROIs at the image borders:
        [xsize,ysize,zsize]=size(VX);
 
        for i=1:size(background_ROI(1).xy,1)   
            if background_ROI(1).xy(i,1) > ysize 
                background_ROI(1).xy(i,1) = ysize;
            end
            if background_ROI(1).xy(i,1) < 1 
                background_ROI(1).xy(i,1) = 1;
            end
            if background_ROI(1).xy(i,2) > xsize 
                background_ROI(1).xy(i,2) = xsize;
            end
            if background_ROI(1).xy(i,2) < 1 
                background_ROI(1).xy(i,2) = 1;
            end
        end

        hourglass_on();
        background_ROI(1).timeseries_ratio_reg = make_timeseries(background_ROI(1).mask, ratio_reg);  
        hourglass_off();
  
    catch exception
        disp(exception)
    end
 
    background_ROI_names = {'background_ROI'};
    set(background_roi_box, 'String', background_ROI_names);
    set(background_roi_box, 'Enable', 'on');
    set(checkbox2, 'Enable','on');
 
    try  
        background_roi_box.Value=length(background_roi_box.String);
        update_windows();
    catch exception
    end
end


%load precomputed ratio movie (overwrites ratio_reg)
function button5_pressed(~,~)
    ratio_movie_folder = uigetdir(working_directory);
    if (ratio_movie_folder==0) return; end
  
    try
        hourglass_on();
        ratio = read_ratio_movie(ratio_movie_folder);
    
        %stop if loaded ratio movie has a different number of time points
        if size(ratio,3)~=size(ratio_reg,3)
            hourglass_off(); return;
        end
    
        w=size(ratio,1); h=size(ratio,2);
        target_w=size(ratio_reg,1); target_h=size(ratio_reg,2);
        if w~=target_w || h~=size(target_h,2)
            w_resize = target_w/w;
            h_resize = target_h/h;
       
            if (w_resize-h_resize~=0)
                hourglass_off(); return;
            else
                ratio_resized = []; 
                for i = 1:size(ratio,3)
                    ratio_resized = cat(3, ratio_resized, imresize(ratio(:,:,i), w_resize));
                end
            end
            ratio = ratio_resized;
        end
    
    catch exception
        hourglass_off();
    end 
    
    try  
        ratio_reg = apply_transformation(ratio, VX, VY);
      
        %recompute min/max
        frames = size(ratio_reg,3);
        ratio_minima = zeros(frames,1); ratio_maxima = zeros(frames,1);
        for i = 1:frames
            ratio_maxima(i) = max(max(ratio_reg(:,:,i))); 
            ratio_minima(i) = min(min(ratio_reg(:,:,i)));
        end
 
        ratio_max = max(ratio_maxima);
        ratio_min = min(ratio_minima);
 
        display_range_lower = ratio_min;
        display_range_upper = ratio_max;
        set(edit3, 'String', num2str(display_range_lower));
        set(edit4, 'String', num2str(display_range_upper));
        update_windows();
    
        compute_deltaF = 0;
        set(checkbox1, 'Value', compute_deltaF);

        recompute_ROIs();
        replace_movies(); 
        %default: activate all ROIs   
        roi_box.Value=1:length(roi_box.String);
        update_windows();
    
    catch exception
        hourglass_off();
        disp('registration failed');
    end
    hourglass_off();
end



%Functions behind check boxes, edit fields:
%-------------------------------------------


function reset_checkboxes()
    compute_deltaF = 0;
    subtract_background = 0;  
    set(checkbox1, 'Value',0);
    set(checkbox2, 'Value',0);
end


function apply_offsets()
    offset_ch0   = round(get(slider1, 'Value'));
    offset_ch1   = round(get(slider2, 'Value'));
    
    ratio_reg = single(zeros(size(ratio_reg)));
 
    for i = 1:size(ratio_reg,3)
        im_channel0 = single(imread(channel0_name, i));
        im_channel1 = single(imread(channel1_name, i));
      
        ch0_below = find(im_channel0<offset_ch0);
        ch1_below = find(im_channel1<offset_ch1);
      
        if length(ch0_below)>0 im_channel0(ch0_below) = 0; end
        if length(ch1_below)>0 im_channel1(ch1_below) = 0; end
      
        if(single_channel)
            ratio_reg(:,:,i)  = uint16(im_channel0);
        else
            ratio_reg(:,:,i)  = imdivide(im_channel0, im_channel1+epsilon);
        end
    end
    
    deltaF_image = mean(ratio_reg(:,:,1:stimulus_on),3);
end



%compute deltaF check box
function box1_changed(~,~)
    compute_deltaF = get(checkbox1, 'Value');

    %update time series window
    if(length(findobj('type','figure','name','ROIs'))>0)  
        callbackA = get(fig3, 'WindowButtonDownFc');
        callbackA(fig3,[]);
    end
  
    %precompute the mean image:
    deltaF_image = mean(ratio_reg(:,:,1:stimulus_on),3);

    %update movie window:
    selected = findobj('type','figure','name','ratio');
    if(length(selected>0))
        figure(fig2);
        map = CubeHelix(4096,0.5,-1.5,1.2,1.0);
        %map = colormap(gray(256));

        im = ratio_reg(:,:,frame_fig2);
   
        if(compute_deltaF==1)
            im = imdivide(im - deltaF_image, deltaF_image);
        end
        imshow(im, 'Colormap', map, 'DisplayRange', [display_range_lower display_range_upper]);
   
        try
            callbackA = get(fig2, 'WindowButtonDownFc');
            callbackA(fig2,[]);
        catch exception
            disp(exception)
        end
    end
end


%subtract background check box
function box2_changed(~,~)
    hourglass_on();  
    
    if get(checkbox2,'Value')==1
        subtract_background = 1;  
        for i = 1:size(ratio_reg,1)
            for j=1:size(ratio_reg,2) 
                ratio_reg(i,j,:) = squeeze( single(ratio_reg(i,j,:)) ) - single(background_ROI(1).timeseries_ratio_reg);    
            end
        end
    else
        subtract_background=0; 
        apply_offsets();
    end
     
    deltaF_image = mean(ratio_reg(:,:,1:stimulus_on),3);
    recompute_ROIs();
    hourglass_off();
   
    replace_movies(); 
    roi_box.Value=1:length(roi_box.String);
    background_roi_box.Value=length(background_roi_box.String);
    update_windows();
end


%edit field for stimulus onset
function edit1_changed(~,~)
    input =-1;  
    input = str2num(get(edit1,'String'));
 
    if length(input)==0 
        set(edit1, 'String', num2str(stimulus_on));
        return;
    end
  
    if(input>0 && input<=size(ratio_reg,3))
        stimulus_on = round(input); 
        set(edit1, 'String', num2str(stimulus_on));
    else
        set(edit1, 'String', num2str(stimulus_on));
    end
end


function edit2_changed(~,~)
    input =-1;  
    input = str2num(get(edit2,'String'));
 
    if length(input)==0 
        set(edit2, 'String', num2str(measurement_length));
        return;
    end
  
    if(input>0 && input<=size(ratio_reg,3) && mod(size(ratio_reg,3),input)==0 )
        measurement_length = round(input); 
        set(edit2, 'String', num2str(measurement_length));
    else
        set(edit2, 'String', num2str(measurement_length));
    end
  
    box1_changed();
end


%display range lower and upper:
function edit3_changed(~,~)
    input =-1;  
    input = str2num(get(edit3,'String'));
 
    if (length(input)==0 || input>=display_range_upper)
        set(edit3, 'String', num2str(display_range_lower));
        return;
    end
  
    display_range_lower = input;
    set(edit3, 'String', num2str(display_range_lower)); 
end


function edit4_changed(~,~)
    input =-1;  
    input = str2num(get(edit4,'String'));
 
    if (length(input)==0 || input<=display_range_lower)
         set(edit4, 'String', num2str(display_range_upper));
        return;
    end
  
    display_range_upper = input;
    set(edit4, 'String', num2str(display_range_upper));
end



%Internal functions (used by the (button) callback functions above)
%------------------------------------------------------------------


%movie list: switch between submovies
function movie_box_changed(~,~)
    if(i_am_busy==1) return; end;
  
    try  
        the_chosen_one = get(movie_box,'Value');
        read_data(movie_names_fullpath{the_chosen_one});  
        replace_movies();
    catch exception
    end
 
    recompute_ROIs();
end



%reload all movie windows
function replace_movies()
    %close old figures
    this_fig = findobj('type','figure','name','channel0');
    if(length(this_fig)>0) close(this_fig); end  
    this_fig = findobj('type','figure','name','channel1');
    if(length(this_fig)>0) close(this_fig); end  
    this_fig = findobj('type','figure','name','ratio');
    if(length(this_fig)>0) close(this_fig); end  
    this_fig = findobj('type','figure','name','ROIs');
    if(length(this_fig)>0) close(this_fig); end  
  
    fig3 = time_series_window('ROIs', pos3);
    fig0 = movie_window('channel0', pos0, 1);
    if(~single_channel)
        fig1 = movie_window('channel1', pos1, 1);
        fig2 = movie_window('ratio', pos2, 1);
    end
end  


% recompute ROIs for the current movie (if the movie in ratio_reg has changed)
%
function recompute_ROIs()
    try 
        hourglass_on();
        for i=1:length(ROIs) 
            ROIs(i).timeseries_ratio_reg = make_timeseries(ROIs(i).mask, ratio_reg);  
            [movement_x, movement_y, movement_x_local, movement_y_local] = estimate_movement(VX, VY, ROIs(i));  
            ROIs(i).movement_x = movement_x;
            ROIs(i).movement_y = movement_y;
            ROIs(i).movement_x_local = movement_x_local;
            ROIs(i).movement_y_local = movement_y_local;  
        end
 
        for i=1:length(background_ROI)
            background_ROI(i).timeseries_ratio_reg = make_timeseries(background_ROI(i).mask, ratio_reg);  f
        end
  
        hourglass_off();
     catch exception
        disp(exception)
     end
end


function recompute_only_foreground_ROIs()
    hourglass_on();
 
    for i=1:length(ROIs) 
         ROIs(i).timeseries_ratio_reg = make_timeseries(ROIs(i).mask, ratio_reg); 
    end
 
    hourglass_off();  
end



%window list: (re)open a window or give focus to a window
function window_box_changed(~,~)
    if(i_am_busy==1) return; end;

    open_windows = get(window_box,'Value');
    if length(find(open_windows==1)==1) 
        this_fig = findobj('type','figure','name','channel0');
 
        if length(this_fig)==0
            fig0 = movie_window('channel0', pos0, 1);
            this_fig = findobj('type','figure','name','channel0');
        end
    
        figure(this_fig);
        active_window='channel0';
    end

    if length(find(open_windows==2)==1) 
        this_fig = findobj('type','figure','name','channel1');
        if length(this_fig)==0
            fig1 = movie_window('channel1', pos1, 1);
            this_fig = findobj('type','figure','name','channel1');
        end
    
        figure(this_fig);
        active_window='channel1';
    end

    if length(find(open_windows==3)==1) 
        this_fig = findobj('type','figure','name','ratio');
        if length(this_fig)==0
            fig2 = movie_window('ratio', pos2, 1);
            this_fig = findobj('type','figure','name','ratio');
        end
    
        figure(this_fig);
        active_window='ratio';
    end

    if length(find(open_windows==4)==1) 
        this_fig = findobj('type','figure','name','ROIs');
        if length(this_fig)==0
            fig3 = time_series_window('ROIs', pos3);
            this_fig = findobj('type','figure','name','ROIs');
        end
    
        figure(this_fig);
        active_window='ROIs';
    end
end    
    


%plot ROI borders onto movie frame
function ROI_image = draw_ROI(movie_name, frame, ROI_object, color)
    if(strcmp(movie_name,'channel0'))
        im = uint16(imread(channel0_name, frame));
    end
    if(strcmp(movie_name,'channel1'))
        im = uint16(imread(channel1_name, frame));
    end
    if(strcmp(movie_name,'ratio'))
        im = ratio_reg(:,:,frame);
    end
 
    ROI_image = im;
  
    for i=1:size(ROI_object,1)
        x = floor(ROI_object(i,2));
        y = floor(ROI_object(i,1));
        ROI_image(x, y) = color;
    end 
end



%time series (for each time point: mean of all pixels within the ROI mask)
%
function timeseries = make_timeseries(ROI_mask, movie)
    idx = find(reshape(ROI_mask,size(ROI_mask,1)*size(ROI_mask,2),1)==1);
    movie = reshape(movie,size(movie,1)*size(movie,2),size(movie,3));
    timeseries = mean(movie(idx,:))';
end


%give focus to the indicated window (if open) 
%or to any movie window (if open)
function movies_to_front()
    if strcmp(active_window,'') return; end; 
  
    chosen = get(window_box, 'Value');
    names = {'channel0', 'channel1', 'ratio'};
  
    if(chosen==4)   
        for i=1:3      
            this_fig = findobj('type','figure','name',names{i});
            if(length(this_fig)>0) 
                figure(this_fig);
                active_window=names{i};
                set(window_box, 'Value',i);
            end
        end
    else
        this_fig = findobj('type','figure','name',names{chosen});
        figure(this_fig);
        active_window=names{chosen};
    end  
end


%on closing the main toolbar window: close&clear everything
function on_close(~,~)
    close all;
    clearvars -global;
end


%turn mouse cursor to hourglass and block gui objects. sets i_am_busy=1
function hourglass_on()
    set(window_box, 'Enable', 'off'); 
    i_am_busy=1;
    figHandles = findobj('Type','figure');
    set(figHandles, 'Pointer', 'watch');
    drawnow;
end

%mouse cursor back to normal: sets i_am_busy=0
function hourglass_off()
    figHandles = findobj('Type','figure');
    set(figHandles, 'Pointer', 'arrow');
    drawnow;
    i_am_busy=0;
    set(window_box, 'Enable', 'on'); 
end


function update_windows()
    this_fig = findobj('type','figure','name','channel0');
    if(length(this_fig)>0)  zoom(fig0,'off'); end
    this_fig = findobj('type','figure','name','channel1');
    if(length(this_fig)>0)  zoom(fig1,'off'); end
    this_fig = findobj('type','figure','name','ratio');
    if(length(this_fig)>0)  zoom(fig2,'off'); end

    try
        selected   = findobj('type','figure','name','ratio');
        if(length(selected>0))
            figure(fig2);
            map = CubeHelix(4096,0.5,-1.5,1.2,1.0);
            %map = colormap(gray(256));
    
            im = ratio_reg(:,:,frame_fig2);
            if(compute_deltaF==1)
                im = imdivide(im - deltaF_image, deltaF_image);
            end
            imshow(im, 'Colormap', map, 'DisplayRange', [display_range_lower display_range_upper]);
    
            callbackA = get(fig2, 'WindowButtonDownFc');
            callbackA(fig2,[]);
        end
    
        selected  = findobj('type','figure','name','ROIs');
        if(length(selected>0))
            figure(fig3);
            callbackA = get(fig3, 'WindowButtonDownFc');
            callbackA(fig3,[]);
        end
   
        selected   = findobj('type','figure','name','channel1');
        if(length(selected>0))
            figure(fig1);
            im = uint16(imread(channel1_name, frame_fig1)); imshow(min_max_normalise(im));
            callbackA = get(fig1, 'WindowButtonDownFc');
            callbackA(fig1,[]);
        end
    
        selected   = findobj('type','figure','name','channel0');
        if(length(selected>0))
            figure(fig0)
            im = uint16(imread(channel0_name, frame_fig0)); imshow(min_max_normalise(im));
            callbackA = get(fig0, 'WindowButtonDownFc');
            callbackA(fig0,[]);
        end
        
    catch exception
    end

    %bring the active (movie) window to the front
    value      = get(window_box,'Value');
    stringlist = get(window_box,'String');
    selected   = findobj('type','figure','name',stringlist{value});

    if(length(selected)>0) figure(selected); end

    this_fig = findobj('type','figure','name','ratio');
    if(length(this_fig)>0)  zoom(fig2,'on'); end
    this_fig = findobj('type','figure','name','channel1');
    if(length(this_fig)>0)  zoom(fig1,'on'); end
    this_fig = findobj('type','figure','name','channel0');
    if(length(this_fig)>0)  zoom(fig0,'on'); end
end



%reads data from a folder (as written by the movement correction program)
function read_data(folder)
    %read mat-files: VX,VY from registration, meta information file:
    all_mats = dir([strcat(folder,'\'),'*.mat']);
    xfile_pos      =-1; yfile_pos=-1; ROIs_pos =-1; metainf_pos = -1;
    for i=1:length(all_mats)
        if (length(regexpi(all_mats(i).name,'VX'))>0)     xfile_pos=i; end
        if (length(regexpi(all_mats(i).name,'VY'))>0)     yfile_pos=i; end  
        if (length(regexpi(all_mats(i).name,'ROIs'))>0)   ROIs_pos=i; end 
        if (length(regexpi(all_mats(i).name,'metainf'))>0)  metainf_pos=i; end 
    end
 
    xfile = matfile( fullfile(folder, all_mats(xfile_pos).name) );
    yfile = matfile( fullfile(folder, all_mats(yfile_pos).name) );
    movement_data_type = string(class(xfile.VX(1,1,:))); 
    VX  = int16(xfile.VX);
    VY  = int16(yfile.VY); 
 
    single_channel=false;
    if(metainf_pos~=-1) 
        metainf_file   = matfile( fullfile(folder, all_mats(metainf_pos).name) );
        single_channel = metainf_file.single_channel;
    end
    
    %read TIFF stacks
    all_tiffs = dir([strcat(folder,'\'),'*.tif']);
      
    channel0_pos=-1; channel1_pos=-1; channel0_original_pos=-1; channel1_original_pos=-1;
 
    for i=1:length(all_tiffs)    
        if (length(regexpi(all_tiffs(i).name,'ch00_reg')>0)) channel0_pos=i; end  
        if (length(regexpi(all_tiffs(i).name,'ch00.tif')>0)) channel0_original_pos=i; end  
        if (length(regexpi(all_tiffs(i).name,'ch01_reg')>0)) channel1_pos=i; end 
        if (length(regexpi(all_tiffs(i).name,'ch01.tif')>0)) channel1_original_pos=i; end 
    end
 
    channel0_name = fullfile(folder, all_tiffs(channel0_pos).name);
    if(~single_channel)
        channel1_name = fullfile(folder, all_tiffs(channel1_pos).name);
    else
        channel1_name = fullfile(folder, all_tiffs(channel0_pos).name);
    end
 
    info   = imfinfo(channel0_name);
    frames = length(info);
    width  = info.Width;
    height = info.Height;
    ratio_reg  = single(zeros(height, width, frames));

    Link_channel0 = Tiff(channel0_name,'r');
    if(~single_channel)
        Link_channel1 = Tiff(channel1_name,'r');
    else
        Link_channel1 = Tiff(channel0_name,'r');
    end
 
    for i = 1:frames 
        Link_channel0.setDirectory(i);
        im_channel0 = single(Link_channel0.read());
        Link_channel1.setDirectory(i);
        im_channel1 = single(Link_channel1.read());
   
        if(single_channel)
            ratio_reg(:,:,i) = uint16(im_channel0);
        else
            ratio_reg(:,:,i) = imdivide(im_channel0, im_channel1+epsilon);
        end
    end
 
    Link_channel0.close();
    Link_channel1.close();
 
    %guess good values for the color scale (true max values are often extreme outliers):
    mean_image = mean(ratio_reg,3);
    ratio_max = round(median(mean_image(:))*2,2);
    ratio_min = round(min(mean_image(:)),2);
 
    display_range_lower = ratio_min;
    display_range_upper = ratio_max;
  
    %if the movie is shorter than "stimulus_on" time points, temporarily use
    %stimulus_on_alternative (=1):
    stimulus_on = str2num(get(edit1,'String'));
    if(size(ratio_reg,3) <=stimulus_on || size(ratio_reg,3) <=10) stimulus_on=stimulus_on_alternative; end
  
    deltaF_image = mean(ratio_reg(:,:,1:stimulus_on),3);
end


%if available, read ROIs (and settings) from a previous run:
function read_ROIs(folder)
    all_mats = dir([strcat(folder,'\'),'*.mat']);
    ROIs_pos =-1;
 
    for i=1:length(all_mats) 
        if length(regexpi(all_mats(i).name,'ROIs'))>0 
            ROIs_pos=i;
        end 
    end
 
    if(ROIs_pos>-1)    
        ROIs_file            = matfile( fullfile(folder, all_mats(ROIs_pos).name) );
        ROIs                 = ROIs_file.ROIs;
        ROI_names            = ROIs_file.ROI_names;
        ROI_counter          = ROIs_file.ROI_counter;
        background_ROI       = ROIs_file.background_ROI;
        background_ROI_names = ROIs_file.background_ROI_names;
        stimulus_on          = ROIs_file.stimulus_on;
        set(edit1,'Value', stimulus_on);
        set(edit1,'String',num2str(stimulus_on));
        deltaF_image         = ROIs_file.deltaF_image;
      
        if(length(ROIs)>0) 
            set(roi_box, 'String', ROI_names);
            set(roi_box, 'Enable', 'on');
        end
        if(length(background_ROI)>0)
            set(background_roi_box, 'String', background_ROI_names);
            set(background_roi_box, 'Enable', 'on');
            set(checkbox2, 'Enable','on');
        end
    end
end


end

