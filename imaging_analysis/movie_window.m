% movie window object launched from the toolbar in analysis.m 
%
% name         : string, e.g. 'channel0', 'channel1', or 'ratio' 
% pos          : [xpos, ypos, width, height] (as used for all uicontrol elements)
% current_frame: frame number (of the frame shown initially)
%
function window = movie_window(name, pos, current_frame)

%global variables (shared with the main window (toolbar, analysis.m) 
%and/or the time series window)
%-------------------------------------------------------------------

global active_window;
global window_box;
global ROIs;
global roi_box;
global background_roi_box;
global background_ROI;
global ROI_names;
global frame_fig0; global frame_fig1; global frame_fig2;
global deltaF_image;
global compute_deltaF;
global mouse_is_over_window;
global channel0_name;
global channel1_name;
global ratio_reg;
global display_range_lower; global display_range_upper;

font_size = 11;
[height,width,frames] = size(ratio_reg);

%GUI elements
%------------

%window layout
window = figure('MenuBar','none', 'ToolBar','none', 'NumberTitle','off', 'Name', name, 'Position',pos, 'CloseRequestFcn', @window_close); 
set(window,'WindowButtonDownFcn',@mouse_event);
set(window, 'WindowButtonMotionFcn', @mouse_over);

%axes for drawing
axes_h = axes('Parent',window, 'units', 'normalized', 'position',[0 0.1 1 0.9]);

%slider: frame number
slider     = uicontrol('style','slider', 'Min',1,'Max',frames,'Value',current_frame, 'Parent', window, 'SliderStep', [1 1]./frames, 'units', 'normalized', 'position',[0.0 0 1 0.05], 'CallBack', @slider_changed);
frame_nr   = uicontrol('Style','text', 'Parent', window, 'units', 'normalized', 'position',[0.0 0.05 1 0.05], 'String',num2str(current_frame), 'FontSize', font_size);

%upon creating the window, draw frame at position <current_frame>:
map=colormap(gray(256));
if(strcmp(name,'ratio')) map = CubeHelix(4096,0.5,-1.5,1.2,1.0); end

slider_pos=current_frame; 
show_image(slider_pos);
set_frame(current_frame);    
plot_ROIs();

%calls to "zoom": here, in roi_box_changed() (this file) and in update_window (analysis.m)
zoom(window,'on');

%callback from the slider (when the frame number is changed)
function slider_changed(hObj, eventdata)    
   slider_pos = round(get(hObj, 'Value')); 
   show_image(slider_pos);
   set_frame(slider_pos);
   set(frame_nr, 'String',num2str(slider_pos));  
   plot_ROIs();
end



%internal functions:
%-------------------

%plot all ROIs that are currently selected in the ROI window (fig3)
function plot_ROIs()        
    try  
        active_ROIs = get(roi_box, 'Value');
  
        if(length(ROIs)>0)
            for i = 1:length(active_ROIs)
            hold on;
      
            %find name of selected ROI and then retrieve xy coordinates + plot
            searchstring = ROI_names{active_ROIs(i)};
            index = find( cellfun(@(x)strcmp(x,searchstring),{ROIs.name}) );
            plot(ROIs(index).xy(:,1), ROIs(index).xy(:,2), 'color', 'red', 'Parent', axes_h); 
            plot(ROIs(index).xy([1,size(ROIs(index).xy,1)],1), ROIs(index).xy([1,size(ROIs(index).xy,1)],2), 'color', 'red', 'Parent', axes_h); 
            end
        end
  
        bgROI = get(background_roi_box, 'Value');
        if(length(bgROI)>0 && length(background_ROI)>0)
            hold on;
            plot(background_ROI.xy(:,1), background_ROI.xy(:,2), 'color', 'blue', 'Parent', axes_h); 
        end
    catch exception
    end
end


%communicate the current movie frame to the GUI's main window (toolbar)
function set_frame(nr)    
    if strcmp(name,'channel0') frame_fig0=nr; end
    if strcmp(name,'channel1') frame_fig1=nr; end
    if strcmp(name,'ratio') frame_fig2=nr; end    
end


%show the image indicated by the slider
function show_image(slider_pos) 
    im = [];   
    if(strcmp(name,'channel0'))
        im = uint16(imread(channel0_name, slider_pos));
    end
    if(strcmp(name,'channel1'))
        im = uint16(imread(channel1_name, slider_pos));
    end
    if(strcmp(name,'ratio'))
        im = ratio_reg(:,:,slider_pos);
    end
 
    if(strcmp('ratio',name) && compute_deltaF==1)
        im = imdivide(im - deltaF_image, deltaF_image);
        imshow(im, 'Parent', axes_h, 'Colormap', map, 'DisplayRange', [display_range_lower display_range_upper]);
    else
         if strcmp('ratio',name)
            imshow(im, 'Parent', axes_h, 'Colormap', map, 'DisplayRange', [display_range_lower display_range_upper]);
         else
            imshow(min_max_normalise(im), 'Parent', axes_h, 'Colormap', map);
         end 
    end 
end


%mouse listeners:
function mouse_event(~,~)  
    try  
        figure(window);
        plot_ROIs();
    catch exception
    end
end


function mouse_over(~,~)
    mouse_is_over_window=name;
end



%if the window is closed, give focus to another window (if any is open)
%
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