classdef ViewImageResultPanelPlot < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for plotting the image
    
    properties
        popupStyle
    end
    
    properties (Constant = true)
        PLOT_STYLE_OPTIONS = {'Normal', 'Equal', 'Square'};
    end
    
    methods
        function obj = ViewImageResultPanelPlot(parent, controller)
            obj@GuiComponent(parent, controller);
            panel = uix.Panel('Parent', parent.component, ...
                'Title','Plot Options', ...
                'Padding', 5);
            vboxMain = uix.VBox('Parent', panel, ...
                'Spacing', 5, 'Padding', 0);
            obj.component = vboxMain;
            
            hboxSecondLine = uix.HBox('Parent', vboxMain, ...
                'Spacing', 5);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxSecondLine, ...
                'String', 'Plot Style:');  % label
            obj.popupStyle = uicontrol(obj.PROP_POPUP{:}, ...
                'Parent', hboxSecondLine, ...
                'String', obj.PLOT_STYLE_OPTIONS, ...
                'Callback', @(h,e)obj.update);
            uicontrol(obj.PROP_BUTTON{:}, ...
                'Parent', vboxMain, ...
                'String', 'Open in Figure', ...
                'Callback', @obj.btnOpenInFigureCallback);
            
            vboxMain.Heights = [25 -1];
            obj.height = 120;
            obj.width = 160;
        end

        function update(obj)
            resultImage = getObjByName(ViewImageResultImage.NAME);
            styleName = lower(obj.PLOT_STYLE_OPTIONS{obj.popupStyle.Value});
            axis(resultImage.vAxes,styleName)
        end
        
        %%%% Callbacks %%%%        
        function btnOpenInFigureCallback(obj,~,~)
            resultImage = getObjByName(ViewImageResultImage.NAME);
            hFigure = figure;
            axes = resultImage.vAxes;
            copyobj([axes,colorbar(axes)],hFigure);
        end
        
    end
    
end

