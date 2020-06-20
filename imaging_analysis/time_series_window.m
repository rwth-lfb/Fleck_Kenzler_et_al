% time series window object  launched from the toolbar in analysis.m 
%
% name: string (e.g. 'ROIs')
% pos : [xpos, ypos, width, height] (as used for all uicontrol elements)
%
function window = time_series_window (name, pos)


%global variables (shared with the main window (toolbar, analysis.m) 
%and/or the movie windows)
%-------------------------------------------------------------------

global active_window;
global window_box;
global ROIs;
global background_ROI;
global roi_box;
global ROI_names;
global background_roi_box;
global background_ROI_names;
global ROI_counter;
global i_am_busy;
global checkbox2;
global fig0; global fig1; global fig2;
global frame_fig0; global frame_fig1; global frame_fig2;
global stimulus_on;
global measurement_length;
global ratio_reg; 
global channel0_name; global channel1_name;
global deltaF_image;
global subtract_background;
global compute_deltaF;
global smooth_parameter;
global epsilon;


font_size = 11;
frames    = size(ratio_reg,3);
height    = size(ratio_reg,1);
width     = size(ratio_reg,2);


%GUI elements:
%-------------

%window layout
window = figure('MenuBar','none', 'ToolBar','none', 'NumberTitle','off', 'Name', name, 'OuterPosition',pos, 'CloseRequestFcn', @window_close); 
set(window,'WindowButtonDownFcn',@mouse_event);

%listbox for ROIs
roi_box = uicontrol('style','listbox','String','', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0 0.1 0.2 0.9], 'CallBack', @roi_box_changed);
set(roi_box,'Min',0, 'Max',999999999);
set(roi_box,'Value',[]);
  
if(length(ROI_names)==0)
  set(roi_box,'Enable','off');
else
   set(roi_box,'String', ROI_names);
   set(roi_box,'Enable', 'on');
end

%context menu for deleting ROI entries:
roi_box_menu=uicontextmenu;
Menu1=uimenu(roi_box_menu,'Label','delete', 'CallBack',@delete_data_roi);
set(roi_box,'UIContextMenu', roi_box_menu);
 
%list box for background ROI
background_roi_box = uicontrol('style','listbox','String','', 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position',[0 0 0.2 0.1], 'CallBack', @roi_box_changed);
set(background_roi_box,'Min',0, 'Max',999999999);
set(background_roi_box,'Value',[]);

if(length(background_ROI_names)==0)
   set(background_roi_box,'Enable','off');
else
   set(background_roi_box,'String', background_ROI_names);
   set(background_roi_box,'Enable', 'on');
end

%context menu for deleting:
background_roi_box_menu=uicontextmenu;
Menu2=uimenu(background_roi_box_menu,'Label','delete', 'CallBack',@delete_background_roi);
set(background_roi_box,'UIContextMenu', background_roi_box_menu);

%switch between time series and contraction view
popup1 = uicontrol('style','popup','String',{'calcium signal', 'movement (since previous image)', 'movement (since first image)'}, 'FontSize', font_size, 'Parent', window,'units', 'normalized', 'position', [0.7 0.9 0.275 0.1], 'CallBack', @switch_timeseries_contraction);
set(popup1, 'Value',1);

%plotting area
ax = axes('units', 'normalized', 'position', [0.25 0.1 0.725 0.85], 'Xlim', [1 frames], 'Ylim', [-2 2]);
xlabel('time points');
ylab='fluorescence';
if(compute_deltaF==1) ylab='fluorescence: delta(F)/F'; end 
if(subtract_background==1) ylab='fluorescence: background ROI subtracted'; end 
if(compute_deltaF==1 && subtract_background==1) ylab='fluorescence: background ROI subtracted; delta(F)/F'; end 
ylabel(ax, ylab);

ax_x_movement = axes('units', 'normalized', 'position', [0.25 0.1 0.725 0.15], 'Xlim', [1 frames], 'Ylim', [-2 2]);   
ax_y_movement = axes('units', 'normalized', 'position', [0.25 0.4 0.725 0.15], 'Xlim', [1 frames], 'Ylim', [-2 2]);   
ax_quiver     = axes('units', 'normalized', 'position', [0.25 0.7 0.725 0.15], 'Xlim', [1 frames], 'Ylim', [-2 2]);   
set(ax_x_movement, 'Visible', 'off');
set(ax_y_movement, 'Visible', 'off');
set(ax_quiver, 'Visible', 'off');



%internal functions:
%------------------


%switch between time series view and contraction view
function switch_timeseries_contraction(hObject,~)
    if(i_am_busy==1) return; end;

    if length(get(roi_box,'String'))==0 return; end
    
    %check which view has been selected:
    view = get(popup1, 'Value');

    if(view==1) 
        plot_time_series()
    else
        plot_movement();
    end
end


% check which ROIs are currently selected in the listbox, 
% and update movie and time series windows, if necessary
%
function roi_box_changed(~,~)
    update_windows();

    %check which view has been selected:
    view = get(popup1, 'Value');

    if(view==1) 
        plot_time_series()
    else
        plot_movement();
        %plot_contraction()
    end

    this_fig = findobj('type','figure','name','channel0');
    if(length(this_fig)>0)  zoom(fig0,'on'); end
    this_fig = findobj('type','figure','name','channel1');
    if(length(this_fig)>0)  zoom(fig1,'on'); end
    this_fig = findobj('type','figure','name','ratio');
    if(length(this_fig)>0)  zoom(fig2,'on'); end    
end



function update_windows()
    if(i_am_busy==1) return; end;

    this_fig = findobj('type','figure','name','channel0');
    if(length(this_fig)>0)  zoom(fig0,'off'); end
    this_fig = findobj('type','figure','name','channel1');
    if(length(this_fig)>0)  zoom(fig1,'off'); end
    this_fig = findobj('type','figure','name','ratio');
    if(length(this_fig)>0)  zoom(fig2,'off'); end
    
    try

    %redraw ROIs in all open movie windows
    selected   = findobj('type','figure','name','ratio');
    if(length(selected>0))
        figure(fig2);
        map=colormap(gray(256));
        %map=CubeHelix(4096,0.5,-1.5,1.2,1.0);
   
        if(compute_deltaF==1)
            imshow( imdivide(abs(ratio_reg(:,:,frame_fig2) - deltaF_image), abs(deltaF_image+epsilon)), 'Colormap', map);
        else
            imshow(ratio_reg(:,:,frame_fig2), 'Colormap', map);
        end
   
        callbackA = get(fig2, 'WindowButtonDownFc');
        callbackA(fig2,[]);
    end
    
    selected   = findobj('type','figure','name','channel0');
    if(length(selected>0))
        figure(fig0)
        im = uint16(imread(channel0_name, frame_fig0)); imshow(min_max_normalise(im));
        callbackA = get(fig0, 'WindowButtonDownFc');
        callbackA(fig0,[]);
    end

    selected   = findobj('type','figure','name','channel1');
    if(length(selected>0))
        figure(fig1);
        im = uint16(imread(channel1_name, frame_fig1)); imshow(min_max_normalise(im));
        callbackA = get(fig1, 'WindowButtonDownFc');
        callbackA(fig1,[]);
    end

    catch exception
        disp(exception)
    end

    %bring the active (movie) window to the front
    value      = get(window_box,'Value');
    stringlist = get(window_box,'String');
    selected   = findobj('type','figure','name',stringlist{value});
    
    if(length(selected)>0) figure(selected); end
end


% if the signal view was selected (uicontrol element popup1),
% plot the ROI's time series (calcium signal)
%
function plot_time_series()
    if length(get(background_roi_box, 'String'))>0
        set(background_roi_box, 'Enable', 'on');   
    end
    
    %close all other axes and enable time series axis
    cla(ax); hold(ax,'off');
    cla(ax_x_movement); hold(ax_x_movement,'off');
    cla(ax_y_movement); hold(ax_y_movement,'off');
    cla(ax_quiver); hold(ax_quiver,'off');
    set(ax_x_movement, 'Visible', 'off');
    set(ax_y_movement, 'Visible', 'off');
    set(ax_quiver, 'Visible', 'off');
    set(ax,'Visible', 'on');

    %plot time series of the selected ROIs
    selected   = get(roi_box, 'Value');
    roistrings = get(roi_box, 'String');

    for i=1:length(selected)
        current_roi = roistrings(selected(i));
        index = find( cellfun(@(x)strcmp(x,current_roi),{ROIs.name}) );
        timeseries = ROIs(index).timeseries_ratio_reg;
  
        if(compute_deltaF==1) 
            timeseries_deltaFF = delta_FF2(timeseries,measurement_length,1,stimulus_on);
            plot(ax, timeseries_deltaFF , 'color', 'red'); 
        else
            plot(ax, timeseries, 'color', 'red'); 
        end
        drawnow;
        hold(ax,'on')
    end

    if(~isempty(background_ROI))
        %plot time series of background ROI
        selected   = get(background_roi_box, 'Value');
        roistrings = get(background_roi_box, 'String');
    
        for i=1:length(selected)
            current_roi = roistrings(selected(i));
            index = find( cellfun(@(x)strcmp(x,current_roi),{background_ROI.name}) );
   
            timeseries = background_ROI(index).timeseries_ratio_reg;
            if(compute_deltaF==1) 
                timeseries_deltaFF = abs(timeseries - mean(timeseries(1:stimulus_on))) / abs(mean(timeseries(1:stimulus_on)));
                plot(ax, timeseries_deltaFF, 'color', 'blue'); 
            else
                plot(ax, timeseries, 'color', 'blue');
            end
            drawnow;
            hold(ax,'on')
        end
    end %endif

    xlabel(ax, 'time points');
    ylab='fluorescence';
    if(compute_deltaF==1) ylab='fluorescence: delta(F)/F'; end 
    if(subtract_background==1) ylab='fluorescence: background ROI subtracted'; end 
    if(compute_deltaF==1 && subtract_background==1) ylab='fluorescence: background ROI subtracted; delta(F)/F'; end 

    ylabel(ax, ylab);
    drawnow;
end


function plot_movement()
    set(background_roi_box, 'Enable', 'off');   
    cla(ax);   
    hold(ax,'off');
    set(ax,'Visible', 'off');
    set(ax_x_movement, 'Visible', 'on');
    set(ax_y_movement, 'Visible', 'on');
    set(ax_quiver, 'Visible', 'on');
 
    selected   = get(roi_box, 'Value');
    %can only show one ROI in this view:
    if(length(selected>1))
        set(roi_box, 'Value', selected(length(selected)));
        update_windows();
    end
 
    selected   = get(roi_box, 'Value');
    roistrings = get(roi_box, 'String');
    view = get(popup1, 'Value');
 
    current_roi = roistrings(selected(1));
    index = find( cellfun(@(x)strcmp(x,current_roi),{ROIs.name}) ); 
    num_time_points = length((ROIs(index).movement_x_local)); 
    plot(ax_x_movement, [1 num_time_points],[0 0],'k-') 
    plot(ax_y_movement, [1 num_time_points],[0 0],'k-') 
    hold(ax_x_movement, 'on');
    hold(ax_y_movement, 'on');
 
    for i=1:length(selected)
        current_roi = roistrings(selected(i));
        index = find( cellfun(@(x)strcmp(x,current_roi),{ROIs.name}) );
  
        filter_size = 10;
        movement_x = []; movement_y = [];
        if(view==2)
            movement_x = ROIs(index).movement_x_local;
            movement_y = ROIs(index).movement_y_local; 
      
            for j=1:measurement_length:num_time_points
                movement_x(j:(j+measurement_length-1)) = smooth(movement_x(j:(j+measurement_length-1)),filter_size);
                movement_y(j:(j+measurement_length-1)) = smooth(movement_y(j:(j+measurement_length-1)),filter_size);
            end
        end
        if(view==3)
            movement_x = ROIs(index).movement_x;
            movement_y = ROIs(index).movement_y; 
       
            %norm to beginning of sub-movie:
            movement_x = abs(subtract_mean(movement_x,measurement_length,1,stimulus_on));
            movement_y = abs(subtract_mean(movement_y,measurement_length,1,stimulus_on));
        
            for j=1:measurement_length:num_time_points 
                movement_x(j:(j+measurement_length-1)) = smooth(movement_x(j:(j+measurement_length-1)),filter_size);
                movement_y(j:(j+measurement_length-1)) = smooth(movement_y(j:(j+measurement_length-1)),filter_size);
            end
        end
   
        plot(ax_x_movement, movement_x, 'r');
        plot(ax_y_movement, movement_y, 'r');
        quiver(ax_quiver, movement_x(5:num_time_points-5)', movement_y(5:num_time_points-5)',1);
 
        xlim(ax_quiver,[0,num_time_points]);
        xlim(ax_x_movement,[0,num_time_points]);
        xlim(ax_y_movement,[0,num_time_points]);
    end
 
    intervals = [];
    for i=1:measurement_length:num_time_points
        intervals = cat(2,intervals,[(i+4):(i+measurement_length-4)]); 
    end

    max1=max(movement_x(intervals));
    max2=max(movement_y(intervals));
    min1=min(movement_x(intervals));
    min2=min(movement_y(intervals));
    upper_limit = max(max1,max2);
    lower_limit = min(min1,min2);  

    ylim(ax_x_movement, [lower_limit upper_limit]);
    ylim(ax_y_movement, [lower_limit upper_limit]);
    xlabel(ax_x_movement, 'time points')
    ylabel(ax_x_movement, 'x movement')
    xlabel(ax_y_movement, 'time points')
    ylabel(ax_y_movement, 'y movement')
    ylabel(ax_quiver, 'displacement vectors')
    drawnow;

    hold(ax_x_movement, 'off');
    hold(ax_y_movement, 'off');
end



%delete a ROI (name from the listbox; and delete ROIs(i) )
function delete_data_roi(~,~)
    if(i_am_busy==1) return; end;
  
    selected = get(roi_box, 'Value'); 
    names    = get(roi_box, 'String');
 
    try
        for i=1:length(selected)
            %find ROI to be deleted by its name
            searchstring = names{selected(i)};
            index = find( cellfun(@(x)strcmp(x,searchstring),{ROIs.name}) );
   
            %remove ROI
            ROIs(index)=[];
        end
  
        %remove ROI name from listbox
        names(selected)=[];

        if(length(names)>0)
            set(roi_box,'String', names);
            ROI_names=names;
        else
            set(roi_box,'String', '');
            ROI_names={''};
            set(popup1, 'Value',1);
        end
  
        set(roi_box,'Value',[]);
    catch exception
        disp(exception)
    end
  
    roi_box_changed();
end



%delete background ROI (name from the listbox; and delete background_ROI(1) )
function delete_background_roi(~,~)
    if(i_am_busy==1) return; end;
  
    selected = get(background_roi_box, 'Value'); 
    names    = get(background_roi_box, 'String');
    
    try
        for i=1:length(selected)
            %find ROI to be deleted by its name
            searchstring = names{selected(i)};
            index = find( cellfun(@(x)strcmp(x,searchstring),{background_ROI.name}) );
   
            %remove ROI
            background_ROI(index)=[];
        end
  
        %remove ROI name from listbox
        names(selected)=[];

        if(length(names)>0)
            set(background_roi_box,'String', names);
            background_ROI_names=names;
        else
            set(background_roi_box,'String', '');
            background_ROI_names={''};
            set(checkbox2, 'Enable','off');
        end
  
        set(background_roi_box,'Value',[]);
  catch exception
  end
  
  roi_box_changed();
end


%mouse listener
function mouse_event(hObject,~) 
    switch_timeseries_contraction(hObject);
end


%if the window is closed, give focus to another window (if any is open)
function window_close(~,~)
    this_fig = findobj('type','figure','name',name);
    delete(this_fig);

    check_fig = findobj('type','figure','name','channel0'); 
    if length(check_fig==1)
        figure(check_fig);
        active_window='channel0';
        set(window_box, 'Value', 1);
        return;
    end   
    check_fig = findobj('type','figure','name','channel1'); 
    if length(check_fig==1)
        figure(check_fig);
        active_window='channel1';
        set(window_box, 'Value', 2);
        return;
    end 
    check_fig = findobj('type','figure','name','ratio'); 
    if length(check_fig==1)
        figure(check_fig);
        active_window='ratio';
        set(window_box, 'Value', 3);
        return;
    end 

    active_window='';
end


end
