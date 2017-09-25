classdef ViewImageResultPanelColormap < GuiComponent
    %VIEWSTAGESCANPANELPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        popupTypes
        cbxAuto
        edtMin
        edtMax
    end
    
    methods
        function obj = ViewImageResultPanelColormap(parent, controller)
            obj@GuiComponent(parent, controller);
            panel = uix.Panel('Parent', parent.component,'Title','Colormap', 'Padding', 5);
            vboxMain = uix.VBox('Parent', panel, 'Spacing', 5, 'Padding', 0);
            obj.component = vboxMain;
            
            colormap1stRow = uix.HBox('Parent', vboxMain, 'Spacing', 5);
            obj.popupTypes = uicontrol(obj.PROP_POPUP{:}, 'Parent', colormap1stRow, 'String', {'Jet', 'HSV', 'Hot', 'Cool', 'Spring', 'Summer', 'Autumn', 'Winter', 'Gray', 'Bone', 'Copper', 'Pink', 'Lines'});
            uix.Empty('Parent', colormap1stRow);
            obj.cbxAuto = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', colormap1stRow, 'string', 'Auto');
            set(colormap1stRow, 'Widths', [-1 15 50]);
            
            colormap2ndRow = uix.HBox('Parent', vboxMain, 'Spacing', 5);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', colormap2ndRow, 'String', 'Min');  % Label
            obj.edtMin = uicontrol(obj.PROP_EDIT{:}, 'Parent', colormap2ndRow, 'String', '0');
            uicontrol(obj.PROP_LABEL{:}, 'Parent', colormap2ndRow, 'String', 'Max');  % Label
            obj.edtMax = uicontrol(obj.PROP_EDIT{:}, 'Parent', colormap2ndRow, 'String', '1');
            set(colormap2ndRow, 'Widths', -1 * ones(1,4));
            
            set(vboxMain, 'Heights', [25 -1]);
            obj.height = 100;
            obj.width = 160;
        end
    end
    
end

