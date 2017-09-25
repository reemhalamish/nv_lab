classdef ViewImageResultPanelPlot < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for plotting the image
    
    properties
        popupStyle
        btnOpenInFigure
    end
    
    methods
        function obj = ViewImageResultPanelPlot(parent, controller)
            obj@GuiComponent(parent, controller);
            panel = uix.Panel('Parent', parent.component,'Title','Plot Options', 'Padding', 5);
            vboxMain = uix.VBox('Parent', panel, 'Spacing', 5, 'Padding', 0);
            obj.component = vboxMain;
            
            hboxSecondLine = uix.HBox('Parent', vboxMain, 'Spacing', 5);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxSecondLine, 'String', 'Plot Style:');  % label
            obj.popupStyle = uicontrol(obj.PROP_POPUP{:}, 'Parent', hboxSecondLine, 'String', {'normal', 'equal', 'square'});
            obj.btnOpenInFigure = uicontrol(obj.PROP_BUTTON{:}, 'Parent', vboxMain, 'string', 'Open in Figure');
            
            vboxMain.Heights = [25 -1];
            obj.height = 120;
            obj.width = 160;
        end
    end
    
end

