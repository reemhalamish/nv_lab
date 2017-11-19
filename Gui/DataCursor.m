classdef DataCursor < handle
    %DATACURSOR class for wrapping data cursor with options specified for
    %it
    
    properties
        vAxes
        cursor
        
        drawn = [];
        crosshairs = struct;
    end
    
    methods
        function obj = DataCursor(imageView)
            obj.vAxes = imageView.vAxes;
            fig = ancestor(obj.vAxes,'figure');
            obj.cursor = datacursormode(fig);
            set(obj.cursor,'UpdateFcn',@obj.cursorMarkerDisplay);
        end
        
        function ClearCursorData(obj)
            % Clear the cursor data between passing from one cursor type to
            % another. To avoid collision.
            
            % Stop zoom if active
            % (uses undocumented feature)
            global GETRECT_H1
            if ~isempty(GETRECT_H1) && ishghandle(GETRECT_H1)
                set(GETRECT_H1, 'UserData', 'Completed');
            end
            
            fig = ancestor(obj.vAxes,'figure');
            delete(findall(fig, 'Type', 'hggroup')); % Delete data tip
            datacursormode(fig, 'off'); % Disable cursor mode
            
            % Remove drawn limits, if exists
            if ~isempty(obj.drawn)
                delete(obj.drawn);
            end
            
            % Disable button press
            img = imhandles(obj.vAxes);
            set(img, 'ButtonDownFcn', '');
        end
        
        function setUpdateFcn(obj)      % for ease of use for other objects
            obj.cursor.UpdateFcn = @obj.cursorMarkerDisplay;
        end
        
        function txt = cursorMarkerDisplay(obj, ~, event_obj)
            % Displays the location of the cursor on the plot and the kcps
            % (the color level from the colormap)
            
            % Displays the location of the cursor on the plot and the kcps
            % (the color level from the colormap)
            
            stageScanner = getObjByName(StageScanner.NAME);
            if isempty(stageScanner.mScan)
                txt = '';
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            % Get scanning parameters
            dim = stageScanner.getScanDimensions;
            sp = stageScanner.mStageScanParams;
            firstAxis = sp.getFirstScanAxisLetter;
            secondAxis = sp.getSecondScanAxisLetter;
            
            % Customizes text of data tips
            data = getimage(obj.vAxes);
            pos = event_obj.Position;
            
            if dim == 1
                txt = sprintf('%s = %.3f\nkcps = %.1f', firstAxis, pos(1), pos(2));
            else
                dataIndex = get(event_obj, 'DataIndex');
                level = data(dataIndex);
                txt = {sprintf('(%s,%s) = (%.3f, %.3f)\nkcps = %.1f', ...
                    firstAxis, secondAxis,...
                    pos(1), pos(2), level)};
            end
        end
        
        function drawRectangle(obj, pos)
            % Draw rectangle
            if HandleHelper.isType(obj.drawn,'rectangle')
                obj.drawn.Position = pos;
            else
                obj.drawn = rectangle(obj.vAxes, ...
                    'Position', pos, ...
                    'EdgeColor', 'g', ...
                    'LineWidth', 1, ...
                    'LineStyle', '-.', ...
                    'HitTest', 'Off');
            end
        end
        
        function drawLimitBar(obj,pos)
            % Draw limit bar
            if ~isempty(obj.drawn)
                delete(obj.drawn);
            end
            dx = pos(3)/2;
            xPos = pos(1) + dx;         % the center of the bar
            yPos = pos(2) + pos(4)/2;	% position of bar in the middle of selected rectangle
            
            hold(obj.vAxes,'on');
            obj.drawn = errorbar(obj.vAxes, ...
                xPos,yPos, ...
                dx, 'horizontal', ...
                'Color', 'r', ...
                'LineWidth', 1);
            hold(obj.vAxes,'off');
        end
        
        function UpdataDataByZoom(obj)
            % Draw the rectangle on the select area on the plot and update
            % the GUI with the max and min values
            
            stageScanner = getObjByName(StageScanner.NAME);
            if isempty(stageScanner.mScan)      % nothing to zoom to
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            % "try" getting user input
            warning('off','all');
            rect = getrect(obj.vAxes);
            warning('on','all');
            if rect(3) == 0; return; end  % selection has no width. No use in continuing
            
            % Get scanning parameters
            dim = stageScanner.getScanDimensions;
            sp = stageScanner.mStageScanParams;
            
            switch dim
                case 1
                    obj.drawLimitBar(rect);
                    scanAxes = sp.getFirstScanAxisIndex;
                case 2
                    if rect(4) == 0     % selection has no height
                        return
                    end
                    obj.drawRectangle(rect);
                    scanAxes = [sp.getFirstScanAxisIndex sp.getSecondScanAxisIndex];
                otherwise
                    EventStation.anonymousError('Cannot fetch limits in higher dimensions');
            end
            
            stage = getObjByName(stageScanner.mStageName);
            
            for i = 1:dim
                axisIndex = scanAxes(i);
                
                stage.scanParams.from(axisIndex) = rect(i);            % rect(1)==horizontal position, rect(2)==vertical position
                stage.scanParams.to(axisIndex) = rect(i)+rect(i+2);    % rect(3)==width;	rect(4)==height
            end
            stage.sendEventScanParamsChanged;
        end
        
        function drawCrosshairs(obj, limits, pos)
            % Draws an arrow or a cross on the plot on a selected position
            %       limits: limits of the view in the axes,
            %               [x_min x_max y_min y_max]
            %       pos:    current stage position, [x] or [x y]
            %
            %       Note: this function assumes the input arguments have
            %       been validated.
            
            % Get properties of axes
            xLimits = limits(1:2);
            yLimits = limits(3:4);
            dim = length(pos);
            
            % If 1D, arbitrarily set the position in the middle
            if dim == 1
                pos(2) = (yLimits(2) + yLimits(1))/2;
            end
            
            %%%% Deciding on which area the position is located %%%%
            % Trinary encoding of the position yields:
            %-----------------------%
            %  2,0  |  2,1  |  2,2  |
            %-----------------------|
            %  1,0  |  1,1  |  1,2  |
            %-----------------------|
            %  0,0  |  0,1  |  0,2  |
            %-----------------------%
            % trinary receives:
            %       x, scalar
            %       I, vector representing interval
            % returns:
            %   0, if x < I,
            %   1, if x in I (including edges)
            %   2, if x > I
            quadrant = [trinary(pos(1),xLimits) , trinary(pos(2),yLimits)];
            
            % Delete previous and recreate correct handles
            hold(obj.vAxes,'on'); % Keep image while creating crosshair/arrow
            
            if all(quadrant == [1 1]) % Inside
                if isfield(obj.crosshairs, 'arrowHandle')
                    delete(obj.crosshairs.arrowHandle);
                end
                if ~isfield(obj.crosshairs, 'xLineHandle') || ~isvalid(obj.crosshairs.xLineHandle)
                    obj.crosshairs.xLineHandle = line(obj.vAxes, [0 0], [0 0], 'Color', 'b', 'HitTest', 'Off');
                end
                if ~isfield(obj.crosshairs, 'yLineHandle') || ~isvalid(obj.crosshairs.yLineHandle)
                    obj.crosshairs.yLineHandle = line(obj.vAxes, [0 0], [0 0], 'Color', 'b', 'HitTest', 'Off');
                end
                
                hold(obj.vAxes,'off'); % Allow picture to change when needed
                
                set(obj.crosshairs.xLineHandle, 'XData', xLimits);
                set(obj.crosshairs.xLineHandle, 'YData', [pos(2) pos(2)]);
                set(obj.crosshairs.yLineHandle, 'XData', [pos(1) pos(1)]);
                set(obj.crosshairs.yLineHandle, 'YData', yLimits);
                
            else % Outside
                if isfield(obj.crosshairs, 'xLineHandle')
                    delete(obj.crosshairs.xLineHandle);
                end
                if isfield(obj.crosshairs,'yLineHandle')
                    delete(obj.crosshairs.yLineHandle);
                end
                if ~isfield(obj.crosshairs, 'arrowHandle') || ~ishandle(obj.crosshairs.arrowHandle)
                    obj.crosshairs.arrowHandle = quiver(obj.vAxes, 0, 0, 0, 0, 'Color', 'b', 'LineWidth', 1, 'MaxHeadSize', 10, 'HitTest', 'Off');
                end
                
                hold(obj.vAxes,'off'); % Allow picture to change when needed
                
                % Draw arrow according to position
                row = quadrant(1);
                switch row
                    case 0 % left column
                        set(obj.crosshairs.arrowHandle, 'XData', xLimits(1)+(xLimits(2)-xLimits(1))/10);
                        set(obj.crosshairs.arrowHandle, 'UData', (xLimits(1)-xLimits(2))/10);
                    case 1 % middle column
                        set(obj.crosshairs.arrowHandle, 'XData', pos(1));
                        set(obj.crosshairs.arrowHandle, 'UData', 0);
                    case 2 % right column
                        set(obj.crosshairs.arrowHandle, 'XData', xLimits(2)+(xLimits(1)-xLimits(2))/10);
                        set(obj.crosshairs.arrowHandle, 'UData', (xLimits(2)-xLimits(1))/10);
                end
                
                column = quadrant(2);
                switch column
                    case 0 % in bottom row
                        set(obj.crosshairs.arrowHandle, 'YData', yLimits(1)+(yLimits(2)-yLimits(1))/10);
                        set(obj.crosshairs.arrowHandle, 'VData', (yLimits(1)-yLimits(2))/10);
                    case 1 % middle row
                        set(obj.crosshairs.arrowHandle, 'YData', pos(2));
                        set(obj.crosshairs.arrowHandle, 'VData', 0);
                    case 2 % top row
                        set(obj.crosshairs.arrowHandle, 'YData', yLimits(2)+(yLimits(1)-yLimits(2))/10);
                        set(obj.crosshairs.arrowHandle, 'VData', (yLimits(2)-yLimits(1))/10);
                end
            end
            
            
            % If 1D, don't draw horizontal line
            if dim == 1 && isfield(obj.crosshairs,'xLineHandle') && ishandle(obj.crosshairs.xLineHandle)
                delete(obj.crosshairs.xLineHandle);
            end
            
        end
        
        function setLocationFromCursor(obj, ~, ~)
            if isempty(obj.vAxes.Children)
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            stageScanner = getObjByName(StageScanner.NAME);
            stage = getObjByName(stageScanner.mStageName);
            sp = stageScanner.mStageScanParams;
            
            axesString = sp.getScanAxes;
            dim = stageScanner.getScanDimensions;
            assert(length(axesString) == dim)
            
            pos = obj.vAxes.CurrentPoint(1, 1:dim);
            
            % Now move to the corresponding location
            stage.move(axesString, pos);
            obj.drawCrosshairs(axis(obj.vAxes),pos);
        end
    end
end
