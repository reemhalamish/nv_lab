classdef ViewImageResultPanelCursor < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for the cursor
    %   Detailed explanation goes here
    
    properties
        radioMarker
        radioZoom
        radioLocation
        
        drawn = [];
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
            obj.drawn = errorbar(resultImageView.vAxes, ...
                xPos,yPos, ...
                dx, 'horizontal', ...
                'Color', 'r', ...
                'LineWidth', 1);
        end
        
        function UpdataDataByZoom(obj)
            % Draw the rectangle on the select area on the plot and update
            % the GUI with the max and min values
            resultImageView = getObjByName(ViewImageResultImage.NAME);
            img = getimage(resultImageView.vAxes);
            if isempty(img)
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            try
                rect = getrect(resultImageView.vAxes);
            catch       % user chose to interrupt rectangle drawing
                return;
            end
            
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
        
        function SetLocationFromCursor(obj, ~, ~)
            if isempty(obj.lastScanedData) || ~isfield(obj.lastScanedData, 'dimentions')
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            if get(handles.bCursorLocation, 'Value')
                pos = get(handles.axes1, 'CurrentPoint');
                pos = pos(1, 1:obj.lastScanedData.dimentions);
                
                % Now move to the correspondig location
                obj.stage.Move(obj.lastScanedData.axisStr, pos);
                obj.UpdatePositionInGUI(obj.lastScanedData.axisStr, pos);
                obj.DrawCrosshairs;
            end
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
                otherwise
                    EventStation.anonymousError('This should not have happenned')
            end
        end
        
        %%%% Callbacks %%%%
        function callbackRadioSelection(obj, ~, event) % todo
            selection = event.NewValue;
            uiresume;
            obj.ClearCursorData;
            obj.update(selection);
        end
        
        function radioMarkerCallback(obj)
            % display cursor with specific data tip
            datacursormode on;
            resultImage = getObjByName(ViewImageResultImage.NAME);
            fig = ancestor(resultImage.component,'figure');
            cursor = datacursormode(fig);
            set(cursor,'UpdateFcn', @ViewImageResultPanelCursor.CursorMarkerDisplay);
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
            set(img, 'ButtonDownFcn', @obj.SetLocationFromCursor);
        end
    end
        
    methods (Static)
        function txt = cursorMarkerDisplay(~, event)
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
            pos = event.Position;
            
            if dim == 1
                txt = sprintf('%s = %.3f\nkcps = %.1f', firstAxis, pos(1), pos(2));
            else
                dataIndex = get(event, 'DataIndex');
                txt = sprintf('(%s,%s) = (%.3f, %.3f)\nkcps = %.1f', ...
                    firstAxis, secondAxis,...
                    pos(1), pos(2), img(dataIndex));
            end
        end
    end
end

