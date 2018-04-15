classdef ViewImageResultPanelPlot < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for plotting the image
    
    properties
        popupStyle
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
                'String', 'Plot Style:');
            obj.popupStyle = uicontrol(obj.PROP_POPUP{:}, ...
                'Parent', hboxSecondLine, ...
                'String', ImageScanResult.PLOT_STYLE_OPTIONS, ...
                'Callback', @obj.popupStyleCallback);
            uicontrol(obj.PROP_BUTTON{:}, ...
                'Parent', vboxMain, ...
                'String', 'Open in Figure', ...
                'Callback', @obj.btnOpenInFigureCallback);
            
            vboxMain.Heights = [25 -1];
            obj.height = 120;
            obj.width = 160;
            
            obj.update;
        end

        function update(obj)
            % Get data from ImageScanResult, and apply on views
            imageScanResult = getObjByName(ImageScanResult.NAME);
            obj.popupStyle.Value = imageScanResult.plotStyle;
        end
    end
       
    methods (Access = private)
        %%%% Callbacks %%%%        
        function btnOpenInFigureCallback(obj, ~, ~) %#ok<INUSD>
            imageScanResult = getObjByName(ImageScanResult.NAME);
            isVisible = true;
            imageScanResult.copyToFigure(isVisible);
        end
        
        function popupStyleCallback(obj, ~, ~)
            imageScanResult = getObjByName(ImageScanResult.NAME);
            imageScanResult.plotStyle = obj.popupStyle.Value;
            imageScanResult.imagePostProcessing;    % Update added layer (including plot style)
        end
    end
    
end

