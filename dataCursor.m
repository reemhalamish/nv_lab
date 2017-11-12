classdef DataCursor < handle
    %DATACURSOR class for wrapping data cursor with options specified for
    %it
    
    properties
        fig
        cursor
    end
    
    methods
        function obj = DataCursor(fig)
        obj@handle;
        obj.fig = fig;        % todo: check if really needed
        obj.cursor = datacursormode(figure, ...
            'UpdateFcn', @obj.update);
        end
        
        %%%% Callback %%%%
        function update(obj)
            % triggered when new data tip is created
            
        end
    end
    
    methods (Static = true)
        function txt = cursorMarkerDisplay(~, event_obj)
            % Displays the location of the cursor on the plot and the kcps
            % (the color level from the colormap)
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            img = getimage(resultImageView.vAxes);
            
            if isempty(img)
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            % Get scanning parameters
            stageScanner = getObjByName(StageScanner.NAME);
            dim = stageScanner.getScanDimensions;
            sp = stageScanner.mStageScanParams;
            firstAxis = sp.getFirstScanAxisLetter;
            secondAxis = sp.getSecondScanAxisLetter;
            
            % Customizes text of data tips
            pos = event_obj.Position;
            
            if dim == 1
                txt = sprintf('%s = %.3f\nkcps = %.1f', firstAxis, pos(1), pos(2));
            else
                dataIndex = get(event_obj, 'DataIndex');
                level = img.CData(dataIndex);
                txt = {sprintf('(%s,%s) = (%.3f, %.3f)\nkcps = %.1f', ...
                    firstAxis, secondAxis,...
                    pos(1), pos(2), level)};
            end
        end
    end
end

