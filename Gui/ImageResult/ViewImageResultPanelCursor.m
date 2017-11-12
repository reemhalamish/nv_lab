classdef ViewImageResultPanelCursor < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for the cursor
    %   Detailed explanation goes here
    
    properties
        radioMarker
        radioZoom
        radioLocation
        
        drawn = [];
        crosshairs = struct;
    end
    
    methods
        function obj = ViewImageResultPanelCursor(parent, controller)
            obj@GuiComponent(parent, controller);
            %             panel = uix.Panel('Parent', parent.component,'Title','Colormap', 'Padding', 5);
            bgMain = uibuttongroup(...
                'parent', parent.component, ...
                'Title', 'Cursor', ...
                'SelectionChangedFcn',@obj.callbackRadioSelection);
            obj.component = bgMain;
            
            rbHeight = 15; % "rb" stands for "radio button"
            rbWidth = 70;
            paddingFromLeft = 10;
            
            obj.radioMarker = uicontrol(obj.PROP_RADIO{:}, 'Parent', bgMain, ...
                'String', 'Marker', ...
                'Position', [paddingFromLeft 60 rbWidth rbHeight]);
            obj.radioZoom = uicontrol(obj.PROP_RADIO{:}, 'Parent', bgMain, ...
                'String', 'Zoom', ...
                'Position', [paddingFromLeft 35 rbWidth rbHeight]);
            obj.radioLocation = uicontrol(obj.PROP_RADIO{:}, 'Parent', bgMain, ...
                'String', 'Move to', ...
                'Position', [paddingFromLeft 10 rbWidth rbHeight]);
            
            obj.height = 100;
            obj.width = 90;
        end
        
        function ClearCursorData(obj)
            % Clear the cursor data between passing from one cursor type to
            % another. To avoid collision.
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            fig = ancestor(resultImageView.component,'figure');
%             cursor = datacursormode(fig);       % finds all available data cursors
%             delete(cursor);                     % Delete data tip: todo -
%                                                           is this needed?
            % Stop zoom if active
            global GETRECT_H1
            if ~isempty(GETRECT_H1) && ishghandle(GETRECT_H1)
                set(GETRECT_H1, 'UserData', 'Completed');
            end

            datacursormode(fig,'off'); % Disables cursor mode
            
            % Remove drawn limits, if exists
            if ~isempty(obj.drawn)
                delete(obj.drawn);
            end
            
            % Disable button press
            img = imhandles(resultImageView.component);
            set(img, 'ButtonDownFcn', '');
        end
        
        function DrawRectangle(obj, pos)
            % Draw rectangle
            if HandleHelper.isType(obj.drawn,'rectangle')
                obj.drawn.Position = pos;
            else
                resultImageView = getObjByName(ViewImageResultImage.NAME);
                obj.drawn = rectangle(resultImageView.vAxes, ...
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
            
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            ax = resultImageView.vAxes;
            hold(ax,'on');
            obj.drawn = errorbar(ax, ...
                xPos,yPos, ...
                dx, 'horizontal', ...
                'Color', 'r', ...
                'LineWidth', 1);
            hold(ax,'off');
        end
        
        function UpdataDataByZoom(obj)
            % Draw the rectangle on the select area on the plot and update
            % the GUI with the max and min values
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            data = resultImageView.vAxes.Children;
            if isempty(data)
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            % "try" getting user input
            rect = getrect(resultImageView.vAxes);
            if rect(3) == 0; return; end  % selection has no width. No use in continuing
            
            % Get scanning parameters
            stageScanner = getObjByName(StageScanner.NAME);
            dim = stageScanner.getScanDimensions;
            sp = stageScanner.mStageScanParams;
            
            switch dim
                case 1
                    obj.drawLimitBar(rect);
                    changedAxes = sp.getFirstScanAxisIndex;
                case 2
                    if rect(4) == 0     % selection has no height
                        return
                    end
                    obj.DrawRectangle(rect);
                    changedAxes = [sp.getFirstScanAxisIndex sp.getSecondScanAxisIndex];
                otherwise
                    EventStation.anonymousError('Cannot fetch limits in higher dimensions');
            end

            stage = getObjByName(stageScanner.mStageName);

            for i = 1:dim
                axisIndex = changedAxes(i);
                
                minimum = rect(i);              % rect(1)==horizontal position, rect(2)==vertical position
                maximum = rect(i)+rect(i+2);    % rect(3)==width;	rect(4)==height
                stage.scanParams.updateByLimit(axisIndex, minimum, maximum);
            end
        end
        
        function DrawCrosshairs(obj, limits, pos)
            % Draws an arrow or a cross on the plot on a selected position
            %       Note: this function assumes it has validated
            %       axis limits and stage position

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
            %  6  |  7  |  8
            %----------------
            %  3  |  4  |  5
            %----------------
            %  0  |  1  |  2
            % trinary receives:
            %       x, scalar
            %       I, vector representing interval
            % returns:
            %   0, if x < I,
            %   1, if x in I (including edges)
            %   2, if x > I
            quadrant = 1*trinary(pos(1),xLimits) + 3*trinary(pos(2),yLimits);

            
            % Delete previous and recreate correct handles
            hold on % Keep image while creating crosshair/arrow
            
            if quadrant == 4 % Inside
                if isfield(obj.crosshairs, 'arrowHandle')
                    delete(obj.crosshairs.arrowHandle);
                end
                if ~isfield(obj.crosshairs, 'xLineHandle') || ~isvalid(obj.crosshairs.xLineHandle)
                    obj.crosshairs.xLineHandle = line([0 0], [0 0], 'Color', 'b', 'HitTest', 'Off');
                end
                if ~isfield(obj.crosshairs, 'yLineHandle') || ~isvalid(obj.crosshairs.yLineHandle)
                    obj.crosshairs.yLineHandle = line([0 0], [0 0], 'Color', 'b', 'HitTest', 'Off');
                end
                
                hold off % Allow picture to change when needed
                
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
                    obj.crosshairs.arrowHandle = quiver(0, 0, 0, 0, 0, 'Color', 'b', 'LineWidth', 1, 'MaxHeadSize', 10, 'HitTest', 'Off');
                end
                
                hold off % Allow picture to change when needed
                
                % Draw arrow according to position
                row = mod(quadrant,3);
                switch row
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
                
                column = floor(quadrant/3);
                switch column
                    case 0 % left column
                        set(obj.crosshairs.arrowHandle, 'XData', xLimits(1)+(xLimits(2)-xLimits(1))/10);
                        set(obj.crosshairs.arrowHandle, 'UData', (xLimits(1)-xLimits(2))/10);
                    case 1 % middle column
                        set(obj.crosshairs.arrowHandle, 'XData', pos(1));
                        set(obj.crosshairs.arrowHandle, 'VData', 0);
                    case 2 % right column
                        set(obj.crosshairs.arrowHandle, 'XData', xLimits(2)+(xLimits(1)-xLimits(2))/10);
                        set(obj.crosshairs.arrowHandle, 'UData', (xLimits(2)-xLimits(1))/10);
                end
            end
            
            
            % If 1D, don't draw horizontal line
            if dim == 1 && isfield(obj.crosshairs,'xLineHandle') && ishandle(obj.crosshairs.xLineHandle)
                delete(obj.crosshairs.xLineHandle);
            end
            
        end
        
        function setLocationFromCursor(obj, ~, ~)
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            gAxes = resultImageView.vAxes;
            if isempty(gAxes.Children)
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            stageScanner = getObjByName(StageScanner.NAME);
            stage = getObjByName(stageScanner.mStageName);
            sp = stageScanner.mStageScanParams;
            
            axesString = sp.getScanAxes;
            dim = stageScanner.getScanDimensions;
            assert(length(axesString) == dim)
            
            pos = gAxes.CurrentPoint(1, 1:dim);

            % Now move to the corresponding location
            stage.move(axesString, pos);
            obj.DrawCrosshairs(axis(gAxes),pos);
        end

        function update(obj,selectedRadioButton)
            % executes when image updates
            if ~exist('selectedRadioButton','var')
                selectedRadioButton = obj.component.SelectedObject;
            end
            switch selectedRadioButton
                case obj.radioMarker
                    obj.radioMarkerCallback;
                case obj.radioZoom
                    obj.radioZoomCallback;
                case obj.radioLocation
                    obj.radioLocationCallback;
                otherwise
                    EventStation.anonymousError('This should not have happenned')
            end
        end
        
        function txt = cursorMarkerDisplay(obj, ~ , event)
            % Displays the location of the cursor on the plot and the kcps
            % (the color level from the colormap)
            
            % Get scanning parameters
            stageScanner = getObjByName(StageScanner.NAME);
            dim = stageScanner.getScanDimensions;
            sp = stageScanner.mStageScanParams;
            firstAxis = sp.getFirstScanAxisLetter;
            secondAxis = sp.getSecondScanAxisLetter;
            
            % Customizes text of data tips
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            pos = event.Position;
            
            data = resultImageView.vAxes.Children;
            if isempty(data) || ~isvalid(data)
                txt = '';
                EventStation.anonymousWarning('Image is empty');
            elseif dim == 1
                txt = sprintf('%s = %.3f\nkcps = %.1f', firstAxis, pos(1), pos(2));
            else
                img = getimage(resultImageView.vAxes);
                dataIndex = get(event, 'DataIndex');
                txt = sprintf('(%s,%s) = (%.3f, %.3f)\nkcps = %.1f', ...
                    firstAxis, secondAxis,...
                    pos(1), pos(2), img(dataIndex));
            end
        end
        
        %%%% Callbacks %%%%
        function callbackRadioSelection(obj, ~, event) % todo
            selection = event.NewValue;
            obj.ClearCursorData;
            obj.update(selection);
        end
        
        function radioMarkerCallback(obj)
            % display cursor with specific data tip
            datacursormode on;
            resultImage = getObjByName(ViewImageResultImage.NAME);
            fig = ancestor(resultImage.component,'figure');
            cursor = datacursormode(fig);
            set(cursor,'UpdateFcn', @obj.cursorMarkerDisplay);
        end
        function radioZoomCallback(obj)
            % Creates a rectangle on the selected area, and updates the
            % GUI's min and max values accordingly
            obj.UpdataDataByZoom;
            obj.radioMarker.Value = 1;
            obj.radioMarkerCallback;
        end
        function radioLocationCallback(obj)
            % Draws horizontal and vertical line on the selected
            % location, and moves the stage to this location.
            obj.ClearCursorData;
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            img = imhandles(resultImageView.component);
            set(img, 'ButtonDownFcn', @obj.setLocationFromCursor);
        end
    end
end

