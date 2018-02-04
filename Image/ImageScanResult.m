classdef ImageScanResult < Savable & EventSender & EventListener
    %IMAGESCANRESULT stores the last scan-image
    %   it is savable, so the last image can be saved and opened
    
    % Hopefully, no other figure will need such functionality. Otherwise,
    % this class should be abstracted, and a child class will need to
    % implement it for scan result.
    
    properties(GetAccess = public, SetAccess = private)
        mData = []; % double. Scan results
        mDimNumber  % dimensions number
        mFirstAxis  % vector
        mSecondAxis % vector or point
        mStageName  % string
        mAxesString  % string
        mLabelBot   % string
        mLabelLeft  % string
    end
    
    properties (Access = private) % For plotting over Image
        gAxes
        gLimits = [];           % graphic handle; stores limits drawn onto image (for zoom)
        crosshairs = struct;    % struct of graphic handles, for the elements of the crosshairs\arrow for current position
        cursor                  % datacursor handle. Stores the information about recent mouse actions
    end
    
    properties
        plotStyle               % integer. Index for value in PLOT_STYLE_OPTIONS
        colormapType            % integer. Index for value in COLORMAP_OPTIONS
        colormapLimits = [0 1]; % 2x1 double
        colormapAuto = true;    % logical
        cursorType              % integer. Index for value in CURSOR_OPTIONS
    end
    
    properties(Constant)
        NAME = 'imageScanResult'
        IMAGE_FILE_SUFFIX = 'png'
        
        % Events
        EVENT_IMAGE_UPDATED = 'imageUpdated';

        % Figuer Options
        PLOT_STYLE_OPTIONS = {'Normal', 'Equal', 'Square'};
        COLORMAP_OPTIONS = {'Pink', 'Jet', 'HSV', 'Hot', 'Cool', ...
            'Spring', 'Summer', 'Autumn', 'Winter', ...
            'Gray', 'Bone', 'Copper', 'Lines'};
        CURSOR_OPTIONS = {'Marker', 'Zoom', 'Location'};
    end
    
    methods
        function obj = ImageScanResult
            obj@Savable(ImageScanResult.NAME);
            obj@EventSender(ImageScanResult.NAME);
            obj@EventListener({SaveLoadCatImage.NAME, StageScanner.NAME});
            
            obj.plotStyle = 1;      % Normal
            obj.colormapType = 1;   % Pink
            obj.cursorType = 1;     % Marker
        end
        
        %% Updating Image
        function update(obj, structExtra)
            % Get EVERYTHING from the struct
            obj.mData = structExtra.scan;
            obj.mDimNumber = structExtra.dimNumber;
            obj.mFirstAxis = structExtra.getFirstAxis;
            obj.mSecondAxis = structExtra.getSecondAxis;
            obj.mStageName = structExtra.stageName;
            obj.mAxesString = structExtra.axesString;
            obj.mLabelBot = structExtra.botLabel;
            obj.mLabelLeft = structExtra.leftLabel;
            
            % We need to calculate this:
            obj.colormapLimits = obj.calcColormapLimits(obj.mData);
            
            obj.sendEventImageUpdated();
            obj.imagePostProcessing;
        end
        
        function imagePostProcessing(obj)
            %%%% After plotting is done, we can make some slight changes
            
            % plot style
            styleName = lower(obj.PLOT_STYLE_OPTIONS{obj.plotStyle});
            axis(obj.gAxes, styleName)
            
            % colormap
            colormapName = obj.COLORMAP_OPTIONS{obj.colormapType};
            colormap(obj.gAxes, colormapName)
            
            try
                if obj.colormapAuto
                    obj.colormapLimits = obj.calcColormapLimits(obj.mData);
                end
                caxis(obj.gAxes, obj.colormapLimits);
            catch % there is a problem with the limits we tried to enforce
                caxis(obj.gAxes, 'auto');
            end
            
            % Get current stage position
            try     % This will not happen without an operating stage
                stage = getObjByName(obj.mStageName);
                pos = stage.Pos(obj.mAxesString);
                % Draw
                if isempty(obj.cursor)
                    % If current cursor does not exist (for some reason)
                    warning('This shouldn''t have happenned')
                    fig = ancestor(obj.gAxes,'figure');
                    obj.cursor = datacursormode(fig);
                    set(obj.cursor,'UpdateFcn',@obj.cursorMarkerDisplay);
                end
                obj.drawCrosshairs(axis(obj.gAxes),pos)
            catch
            end
            
        end
        
        %%%% Data Cursor methods %%%%
        function ClearCursorData(obj)
            % Clear the cursor data between passing from one cursor type to
            % another. To avoid collision.
            
            % Stop zoom if active
            % (uses undocumented feature)
            global GETRECT_H1
            if ~isempty(GETRECT_H1) && ishghandle(GETRECT_H1)
                set(GETRECT_H1, 'UserData', 'Completed');
            end
            
            fig = ancestor(obj.gAxes,'figure');
            delete(findall(fig, 'Type', 'hggroup')); % Delete data tip
            datacursormode(fig, 'off'); % Disable cursor mode
            
            % Remove drawn limits, if exists
            if ~isempty(obj.gLimits)
                delete(obj.gLimits);
            end
            
            % Disable button press
            img = imhandles(obj.gAxes);
            set(img, 'ButtonDownFcn', '');
        end
        
        function drawRectangle(obj, pos)
            % Draw rectangle
            if HandleHelper.isType(obj.gLimits, 'rectangle')
                obj.gLimits.Position = pos;
            else
                obj.gLimits = rectangle(obj.gAxes, ...
                    'Position', pos, ...
                    'EdgeColor', 'g', ...
                    'LineWidth', 1, ...
                    'LineStyle', '-.', ...
                    'HitTest', 'Off');
            end
        end
        
        function drawLimitBar(obj,pos)
            % Draw limit bar
            if ~isempty(obj.gLimits)
                delete(obj.gLimits);
            end
            dx = pos(3)/2;
            xPos = pos(1) + dx;         % the center of the bar
            yPos = pos(2) + pos(4)/2;	% position of bar in the middle of selected rectangle
            
            hold(obj.gAxes,'on');
            obj.gLimits = errorbar(obj.gAxes, ...
                xPos,yPos, ...
                dx, 'horizontal', ...
                'Color', 'r', ...
                'LineWidth', 1);
            hold(obj.gAxes,'off');
        end
        
        function updateDataCursor(obj, action)
            % Needs to happen only when everything else finished, whether
            % by scanning or loading
            %
            % action - string. One of obj.CURSOR_OPTIONS

            if isempty(obj.cursor)
                % Nothing to do here
                return
            end
            
            actionIndex = find(strcmp(action,obj.CURSOR_OPTIONS));
            switch actionIndex
                case 1      % Display cursor with specific data tip
                    datacursormode on;
                    obj.setUpdateFcn;
                case 2      % Create a rectangle on the selected area, and update the GUI scanParams's min and max values accordingly
                    obj.UpdataDataByZoom;
                case 3      % Move the stage to selected location
                    datacursormode off;
                    img = imhandles(obj.gAxes);
                    set(img, 'ButtonDownFcn', @obj.setLocationFromCursor);
            end
        end
        
        function setUpdateFcn(obj)      % for ease of use for other objects
            obj.cursor.UpdateFcn = @obj.cursorMarkerDisplay;
        end
        
        function txt = cursorMarkerDisplay(obj, ~, event_obj)
            % Displays the location of the cursor on the plot and the kcps
            % (the color level from the colormap)
            
            % Displays the location of the cursor on the plot and the kcps
            % (the color level from the colormap)
            
            imageScanResult = getObjByName(ImageScanResult.NAME);
            if ~imageScanResult.isDataAvailable
                txt = '';
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            % Get scanning parameters
            dim = imageScanResult.mDimNumber;
            scanAxes = imageScanResult.mAxesString;
            firstAxis = scanAxes(1);	% char (either 'x', 'y' or 'z')
            secondAxis = scanAxes(end); % char (either 'x', 'y' or 'z')
            
            % Customizes text of data tips
            data = getimage(obj.gAxes);
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
        
        function UpdataDataByZoom(obj)
            % Draw the rectangle on the selected area on the plot,
            % and update the GUI with the max and min values
            
            if ~obj.isDataAvailable      % nothing to zoom to
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            % "try" getting user input
            warning('off','all');
            rect = getrect(obj.gAxes);
            warning('on','all');
            if rect(3) == 0; return; end  % Selection has no width. No use in continuing
            
            % Draw, according to the dimensions of the image
            dim = obj.mDimNumber;
            switch dim
                case 1
                    obj.drawLimitBar(rect);
                case 2
                    if rect(4) == 0     % Selection has no height
                        return
                    end
                    obj.drawRectangle(rect);
                otherwise
                    EventStation.anonymousError('Can''t fetch limits in higher dimensions');
            end
            
            try
                stage = getObjByName(obj.mStageName);
                assert(stage.isScannable)
            catch
                EventStation.anonymousError('Can''t set new scan parameters, since there is no relevant stage');
            end
            
            for i = 1:dim
                axisIndex = stage.getAxis(obj.mAxesString(i));
                
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
            hold(obj.gAxes,'on'); % Keep image while creating crosshair/arrow
            
            if all(quadrant == [1 1]) % Inside
                if isfield(obj.crosshairs, 'arrowHandle')
                    delete(obj.crosshairs.arrowHandle);
                end
                if ~isfield(obj.crosshairs, 'xLineHandle') || ~isvalid(obj.crosshairs.xLineHandle)
                    obj.crosshairs.xLineHandle = line(obj.gAxes, ...
                        [0 0], [0 0], 'Color', 'b', 'LineWidth', 0.5, 'HitTest', 'Off');
                end
                if ~isfield(obj.crosshairs, 'yLineHandle') || ~isvalid(obj.crosshairs.yLineHandle)
                    obj.crosshairs.yLineHandle = line(obj.gAxes, ...
                        [0 0], [0 0], 'Color', 'b', 'LineWidth', 0.5, 'HitTest', 'Off');
                end
                
                hold(obj.gAxes,'off'); % Allow picture to change when needed
                
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
                    obj.crosshairs.arrowHandle = quiver(obj.gAxes, 0, 0, 0, 0, 'Color', 'b', ...
                        'LineWidth', 1, 'MaxHeadSize', 10, 'HitTest', 'Off');
                end
                
                hold(obj.gAxes,'off'); % Allow picture to change when needed
                
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
            if isempty(obj.gAxes.Children)
                EventStation.anonymousWarning('Image is empty');
                return
            end
            
            % Get everything we need
            stage = getObjByName(obj.mStageName);
            pos = obj.gAxes.CurrentPoint(1, 1:obj.mDimNumber);

            % Now move to the corresponding location
            stage.move(obj.mAxesString, pos);    % This should update the datacursor, by relevant event
        end
        
        %% Helper methods
        function sendEventImageUpdated(obj)
            obj.sendEvent(struct(obj.EVENT_IMAGE_UPDATED, true));
        end
        
        function tf = isDataAvailable(obj)
            tf = ~isempty(obj.mData);
        end
        
        function checkGraphicAxes(obj)
            if exist('obj.gAxes', 'var') && ~(isgraphics(obj.gAxes) && isvalid(obj.gAxes))
                obj.gAxes = [];
                obj.cursor = [];
            end
        end
        
        function addGraphicAxes(obj, gAxes)
            if ~(isgraphics(gAxes) && isvalid(gAxes))
                obj.sendWarning('Graphic Axes were not created. Plotting is unavailable');
                return
            end
            
            obj.gAxes = gAxes;
            fig = ancestor(obj.gAxes,'figure');
            obj.cursor = datacursormode(fig);
            set(obj.cursor,'UpdateFcn',@obj.cursorMarkerDisplay);
        end
        
        function changeMyStage(obj, stageName)
            try
                % We might not need to do anything, since we are using the
                % same stage.
                if ~strcmp(stageName, obj.mStageName)
                    % Check that required stage is available
                    getObjByName(stageName);
                    
                    % Switch to new stage
                    obj.stopListeningTo(obj.mStageName);
                    obj.mStageName = stageName;
                    obj.startListeningTo(obj.mStageName);
                end
            catch
                obj.sendWarning('New stage is not available. Some things might not work properly.');
            end
        end
        
        %% Saving
        function fullpath = savePlottingImage(obj, folder, filename)
            % Create a new invisible figure, and than save it with a same
            % filename.
            %
            % Input:
            %   folder - string. the path.
            %   filename - string. the file that was saved by the SaveLoad
            %
            % Output:
            % fullpath - the fullpath of the image file that was saved
            
            if isempty(obj.mData) || isempty(obj.mData); return; end
            
            figureInvis = AxesHelper.copyAxes(ViewImageResult.getAxes);
            
            filename = PathHelper.removeDotSuffix(filename);
            filename = [filename '.' ImageScanResult.IMAGE_FILE_SUFFIX];
            fullpath = PathHelper.joinToFullPath(folder, filename);
            
            % Save jpg image
            notes = SaveLoad.getInstance(Savable.CATEGORY_IMAGE).mNotes;
            title(notes); %set the notes as the plot's title
            saveas(figureInvis, fullpath);
            
            % close the figure
            close(figureInvis);
        end
    end
    
    methods (Static)
        function init
            removeObjIfExists(ImageScanResult.NAME); 
            addBaseObject(ImageScanResult);
        end
    end
    
    %% overriding from Savable
    methods(Access = protected)
        function outStruct = saveStateAsStruct(obj, category, type) %#ok<*MANU>
            % Saves the state as struct. if you want to save stuff, make
            % (outStruct = struct;) and put stuff inside. If you dont
            % want to save, make (outStruct = NaN;)
            %
            % category - string. Some objects saves themself only with
            %                    specific category (image/experimetns/etc)
            % type - string.     Whether the objects saves at the beginning
            %                    of the run (parameter) or at its end (result)
            if ~strcmp(category, Savable.CATEGORY_IMAGE) || ~strcmp(type, Savable.TYPE_RESULTS)
                outStruct = NaN;
                return
            end
            
            if isempty(obj.mData)
                outStruct = NaN;
                return
            end
            
            outStruct = struct();
            propNameCell = obj.getAllNonConstProperties();
            for i = 1: length(propNameCell)
                propName = propNameCell{i};
                outStruct.(propName) = obj.(propName);
            end
            
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory)
            % Loads the state from a struct.
            % To support older versoins, always check for a value in the
            % struct before using it. view example in the first line.
            % subCategory - string. could be empty string

            if ~strcmp(category, Savable.CATEGORY_IMAGE); return; end
            if ~any(strcmp(subCategory, {Savable.SUB_CATEGORY_DEFAULT})); return; end
            
            hasChanged = false;     % initialize
            for propNameCell = obj.getAllPropertiesThisClassDefined()
                propName = propNameCell{:};
                if isfield(savedStruct, propName)
                    obj.(propName) = savedStruct.(propName);
                    hasChanged = true;
                end
            end
            if hasChanged
                obj.sendEventImageUpdated();
                obj.imagePostProcessing;
            end
        end
        
        function string = returnReadableString(obj, savedStruct) %#ok<INUSD>
            % Return a readable string to be shown. If this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '');
            string = NaN;
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            % Check if event is "loaded file to SaveLoad" and need to show the image
            if strcmp(event.creator.name, SaveLoadCatImage.NAME) ...
                    && isfield(event.extraInfo, SaveLoad.EVENT_LOAD_SUCCESS_FILE_TO_LOCAL)
                % Need to load the image!
                category = Savable.CATEGORY_IMAGE;
                subcat = Savable.SUB_CATEGORY_DEFAULT;
                saveLoad = event.creator;
                struct = saveLoad.getStructToSavable(obj);
                if ~isempty(struct)
                    obj.loadStateFromStruct(struct, category, subcat);
                end
            end
            
            % Check if event is "SaveLoad wants to save a file" and need to
            % save an image file of the figure
            if strcmp(event.creator.name, SaveLoadCatImage.NAME) ...
                    && isfield(event.extraInfo, SaveLoad.EVENT_SAVE_SUCCESS_LOCAL_TO_FILE) ...
                    && ~isempty(obj.mData)
                
                folder = event.extraInfo.(SaveLoad.EVENT_FOLDER);
                filename = event.extraInfo.(SaveLoad.EVENT_FILENAME);
                obj.savePlottingImage(folder, filename);
            end
            
            % Check if event is "scanner started a new scan", and we might
            % need to change our reference stage
            if strcmp(event.creator.name, StageScanner.NAME) ...
                    && isfield(event.extraInfo, StageScanner.EVENT_SCAN_STARTED)
                obj.changeMyStage(event.creator.mStageName);
            end
                    
            
            % Check if event is "scanner has a new line scanned" and need
            % to updated the image
            if strcmp(event.creator.name, StageScanner.NAME) ...
                    && isfield(event.extraInfo, StageScanner.EVENT_SCAN_UPDATED)
                
                extra = event.extraInfo.(StageScanner.EVENT_SCAN_UPDATED);
                % "extra" now points to an object of class EventExtraScanUpdated
                obj.update(extra);
                drawnow
                return % To avoid drawing crosshairs twice
            end
            
            % Check if event is "Stage moved" (not by scanning,
            % which would have been caught by previous condition),
            % and redraw crosshairs
            if isfield(event.extraInfo, ClassStage.EVENT_POSITION_CHANGED) ...
                    && strcmp(event.creator.name, obj.mStageName)
                
                % If scanner is running, and there is no point in updating
                % crosshairs would really delay it
                scanner = getObjByName(StageScanner.NAME);
                if scanner.mCurrentlyScanning; return; end
                
                try
                    stage = getObjByName(obj.mStageName);
                    physAxes = obj.mAxesString;
                    pos = stage.Pos(physAxes);
                    obj.drawCrosshairs(axis(obj.gAxes),pos);
                catch % Probably, there is nothing to draw on. Moving on
                end
            end
        end
    end
    
    %%
    methods (Static)
       function limits = calcColormapLimits(data)
            % Calculate auto-limits from data.
            maxValue = max(max(data(~isinf(data))));
            minValue = min(min(data(data ~= 0)));
            limits = [minValue maxValue];
        end 
    end
end