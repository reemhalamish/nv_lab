classdef GuiComponent < handle
    %GUICOMPONENT parent class for all the GUI components
    %   connects to the controller
    
    properties(GetAccess = public, SetAccess = protected)
        component  % this inner variable stores the component
        parent   % parent of the component
    end
    properties
        width = -1;
        height = -1;
    end
    
    properties(Constant = true)
        %% properties for design
        PROP_TEXT_NO_BG =           {'Style', 'text',       'FontSize', 8,                          'ForegroundColor', 'black',                             'HorizontalAlignment', 'left'};
        PROP_TEXT_NORMAL =          {'Style', 'text',       'FontSize', 8,                          'ForegroundColor', 'black', 'BackgroundColor', 'white', 'HorizontalAlignment', 'left'};
        PROP_TEXT_BIG =             {'Style', 'edit',       'FontSize', 10, 'FontWeight', 'bold',   'ForegroundColor', 'black', 'BackgroundColor', 'white', 'HorizontalAlignment', 'center', 'Enable', 'off'};
        PROP_LABEL =                {'Style', 'edit',       'FontSize', 10, 'FontWeight', 'bold',   'ForegroundColor', 'white', 'BackgroundColor', 'black', 'HorizontalAlignment', 'center', 'Enable', 'inactive'};
        PROP_EDIT =                 {'Style', 'edit',       'FontSize', 10, 'FontWeight', 'bold',   'ForegroundColor', 'black', 'BackgroundColor', 'white', 'HorizontalAlignment', 'center'};
        PROP_EDIT_SMALL =           {'Style', 'edit',       'FontSize', 8,  'FontWeight', 'normal', 'ForegroundColor', 'Black', 'BackgroundColor', 'white', 'HorizontalAlignment', 'left'};
        PROP_BUTTON =               {'Style', 'pushbutton', 'FontSize', 10, 'FontWeight', 'bold'};
        PROP_BUTTON_SMALL =         {'Style', 'pushbutton', 'FontSize', 8,  'FontWeight', 'bold'};
        PROP_BUTTON_BIG_GREEN =     {'Style', 'pushbutton', 'FontSize', 14, 'FontWeight', 'bold',   'ForegroundColor', 'white', 'BackgroundColor', 'green'};
        PROP_BUTTON_BIG_RED =       {'Style', 'pushbutton', 'FontSize', 14, 'FontWeight', 'bold',   'ForegroundColor', 'white', 'BackgroundColor', 'red'};
        PROP_BUTTON_BIG_BLUE =      {'Style', 'pushbutton', 'FontSize', 14, 'FontWeight', 'bold',   'ForegroundColor', 'white', 'BackgroundColor', 'blue'};
        PROP_CHECKBOX =             {'Style', 'checkbox',   'FontSize', 10};
        PROP_POPUP =                {'Style', 'popup',      'FontSize', 10,                                                     'BackgroundColor', 'white'};
        PROP_RADIO =                {'Style', 'radiobutton','FontSize', 10};
        PROP_SLIDER =               {'Style', 'slider'};
        COLOR_ENABLE_OFF_BG = [0.9 0.9 0.9];
        COLOR_ENABLE_OFF_FG = [0.3 0.3 0.3];
        
        
    end
    
    methods
        %% Constructor %%
        function obj = GuiComponent(parent, controller)
            obj = obj@handle();
            if nargin == 0
                % default constructor
                return
            end
            
            if nargin < 2
                EventStation.anonymousError('Can''t construct object without parent and the main controller arguments!')
            end
            obj.parent = parent;
            controller.addView(obj);
            
        end % GuiComponent constructor function
        
        
        function initHeightWidth(obj)
            obj.width = obj.getWidth(obj.component);
            obj.height = obj.getHeight(obj.component);
        end        
        
        function onCloseGui(obj)
            obj.delete();
        end
        
        function recolor(obj,vectorEdt,isBeingGrayed)
            % Supports coloring of vector of editboxes
           if isBeingGrayed
               set(vectorEdt, 'BackgroundColor', obj.COLOR_ENABLE_OFF_BG, ...
                   'ForegroundColor', obj.COLOR_ENABLE_OFF_FG);
           else
               set(vectorEdt, 'BackgroundColor', 'white', ...
                   'ForegroundColor', 'black');
           end
        end
        
        
    end
    
    methods(Static)
        function out = getWidth(uicontrol)
            position = get(uicontrol, 'Position');  % "Position" returns an array --> [left bottom width height]
            out = position(3);
        end
            
        function out = getHeight(uicontrol)
            position = get(uicontrol, 'Position');  % "Position" returns an array --> [left bottom width height]
            out = position(4);
        end
    end
end
