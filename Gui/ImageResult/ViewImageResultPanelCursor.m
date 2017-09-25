classdef ViewImageResultPanelCursor < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for the cursor
    %   Detailed explanation goes here
    
    properties
        radioMarker
        radioZoom
        radioLocation
    end
    
    methods
        function obj = ViewImageResultPanelCursor(parent, controller)
            obj@GuiComponent(parent, controller);
%             panel = uix.Panel('Parent', parent.component,'Title','Colormap', 'Padding', 5);
            bgMain = uibuttongroup(...
                'parent', parent.component, ...
                'Title', 'Cursor', ...
                'SelectionChangedFcn',@(bg,event) obj.callbackRadioSelection(event) ...
            );
            obj.component = bgMain;
            
            rbHeight = 15; % "rb" stands for "radio button"
            rbWidth = 70;
            paddingFromLeft = 10;
            
            obj.radioMarker = uicontrol('parent', bgMain, obj.PROP_RADIO{:}, 'String', 'Marker', 'Position',    [paddingFromLeft 60 rbWidth rbHeight]);
            obj.radioZoom = uicontrol('parent', bgMain, obj.PROP_RADIO{:}, 'String', 'Zoom', 'Position',        [paddingFromLeft 35 rbWidth rbHeight]);
            obj.radioLocation = uicontrol('parent', bgMain, obj.PROP_RADIO{:}, 'String', 'Location', 'Position',[paddingFromLeft 10 rbWidth rbHeight]);

            obj.height = 100;
            obj.width = 90;
        end
        
        function callbackRadioSelection(obj, event)
            nowPressed = event.NewValue;
            % todo if nowPressed == obj.radioZoom ... else ...
        end
    end
    
end

