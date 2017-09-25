classdef ClassImage < BaseObject
    
    % Private parameters
    properties (Access = protected)
        stage
        lastScanedData
        startScanBoolean
        drawSquare
    end
    
    properties(Constant = true)
        NAME = 'classImage';
    end
    
    % Constructor
    methods (Access = protected) % Private Functions
        function obj = ClassImage()
            % Private default constructor.
            obj@BaseObject(ClassImage.NAME);
            addBaseObject(obj);
        end
    end
    
    % Creates singletone
    methods (Static, Access = public)
        function init()
            ClassImage.GetInstance();
        end
        
        function obj = GetInstance()
            % Returns a singelton instance of this class.
            % the object can also be retreived directly via
            % getObjByName(ClassImage.NAME)
            try
                obj = getObjByName(ClassImage.NAME);
            catch  % still wasn't created
                obj = ClassImage();
            end
        end
    end
    
    methods (Access = public)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%     Start GUI     %%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function Start(obj, handles)
            % Initialize the GUI with default parameters
            obj.InitializeParameters(handles);
        end
        
        function InitializeParameters(obj, handles)
%             setupNumber = GetDataFile('SetupNumber');
%             % Set default data for file saving and loading
%             obj.saveFileData.saveAsPath = sprintf('%s\\Google Drive\\NV Lab\\CFA confocal\\NVConfocalCodeNew\\Data\\Images\\', getenv('USERPROFILE'));
%             obj.saveFileData.loadPath = sprintf('%s\\Google Drive\\NV Lab\\CFA confocal\\NVConfocalCodeNew\\Data\\Images\\AutoSave\\Setup %s\\', getenv('USERPROFILE'), setupNumber);
%             obj.saveFileData.autoSavePath = sprintf('%s\\Google Drive\\NV Lab\\CFA confocal\\NVConfocalCodeNew\\Data\\Images\\AutoSave\\Setup %s\\', getenv('USERPROFILE'), setupNumber);
%             obj.saveFileData.format = 'yyyymmdd_HHMMSS';
%             obj.saveFileData.file = datestr(now,obj.saveFileData.format);
%             obj.saveFileData.saveAsFile = obj.saveFileData.file;
%           
%             % Set initial values
%             set(handles.LaserPower, 'Min', 0);
%             set(handles.LaserPower, 'Max', 1);
%             set(handles.bAutoSaveImg, 'Value', 1);
%             set(handles.bCursorMarker,'Value', 0);
%             set(handles.bZoom,'Value', 0);
%             set(handles.bCursorLocation,'Value', 0);
%             set(handles.CAxisAuto, 'Value', 1); % set to auto color map
%             set(handles.bFastScan, 'Value', 1);
%             set(handles.Colormap, 'Value', 12); % set default color to pink
%             caxis(handles.axes1, 'auto');
%             
%             [tiltEnabled, thetaXZ, thetaYZ] = obj.stage.GetTiltStatus();
%             set(handles.bEnableAngle, 'Value', tiltEnabled);
%             set(handles.ThetaX, 'String', thetaXZ);
%             set(handles.ThetaX, 'UserData', thetaXZ);
%             set(handles.ThetaY, 'String', thetaYZ);
%             set(handles.ThetaY, 'UserData', thetaYZ);
%             
%             % Create a struct with default values, update the GUI and return it
%             
%             % Get the soft limits
%             [lowEndOfRange, highEndOfRange] = obj.stage.ReturnLimits('xyz'); % Soft Limits
%             curPos = obj.stage.Pos('xyz');
%             
%             % Set the Scan Parameters according to the current position of
%             % the stage
%             scanParameters = struct(...
%                 'minVx', round(curPos(1)-1),...
%                 'maxVx', round(curPos(1)+1),...
%                 'NVx',   50,...
%                 'bFixVx',0,...
%                 'FixVx', curPos(1),...
%                 ...
%                 'minVy', round(curPos(2)-1),...
%                 'maxVy', round(curPos(2)+1),...
%                 'NVy',   50,...
%                 'bFixVy',0,...
%                 'FixVy', curPos(2),...
%                 ...
%                 'minVz', round(curPos(3)-5),...
%                 'maxVz', round(curPos(3)+5),...
%                 'NVz',   100,...
%                 'bFixVz',1,...
%                 'FixVz', curPos(3),...
%                 ...
%                 'FixDT', 15e-3,...
%                 ...
%                 ...% Set the axis limits on the GUI according to the Soft Limits of the stage
%                 'Xllimit', lowEndOfRange(1), 'Xulimit',  highEndOfRange(1), ...
%                 'Yllimit', lowEndOfRange(2), 'Yulimit',  highEndOfRange(2), ...
%                 'Zllimit', lowEndOfRange(3), 'Zulimit',  highEndOfRange(3));
%             
%             % Update the GUI with the new parameters
%             obj.UpdateGUIForms(scanParameters, handles);
        end
        
        function UpdateGUIForms(obj, parametersStruct, handles)
            % Updates the GUI with the values from parametersStruct.
            % Set the 'String' and 'UserData' values.
            stepSize = 0.1;
            caxisMin = 0;
            caxisMax = 1;
            todo = 'why is this here and not in parameterStruct?';
            
            set(handles.Xllimit,    'String', num2str(parametersStruct.Xllimit, '%.0f'));
            set(handles.Xulimit,    'String', num2str(parametersStruct.Xulimit, '%.0f'));
            set(handles.Yllimit,    'String', num2str(parametersStruct.Yllimit, '%.0f'));
            set(handles.Yulimit,    'String', num2str(parametersStruct.Yulimit, '%.0f'));
            set(handles.Zllimit,    'String', num2str(parametersStruct.Zllimit, '%.0f'));
            set(handles.Zulimit,    'String', num2str(parametersStruct.Zulimit, '%.0f'));
            set(handles.StepSize,   'String', num2str(stepSize, '%.3f'));
            set(handles.CAxisMin,   'String', caxisMin);
            set(handles.CAxisMax,   'String', caxisMax);
            set(handles.LimitAround,   'String', 0);
            
            % Update all the 'UserData' values of the same fields
            set(handles.Xllimit, 'UserData', num2str(parametersStruct.Xllimit, '%.0f'));
            set(handles.Xulimit, 'UserData', num2str(parametersStruct.Xulimit, '%.0f'));
            set(handles.Yllimit, 'UserData', num2str(parametersStruct.Yllimit, '%.0f'));
            set(handles.Yulimit, 'UserData', num2str(parametersStruct.Yulimit, '%.0f'));
            set(handles.Zllimit, 'UserData', num2str(parametersStruct.Zllimit, '%.0f'));
            set(handles.Zulimit, 'UserData', num2str(parametersStruct.Zulimit, '%.0f'));
            set(handles.StepSize, 'UserData', num2str(stepSize, '%.3f'));
            set(handles.CAxisMin, 'UserData', caxisMin);
            set(handles.CAxisMax, 'UserData', caxisMax);
            set(handles.LimitAround,   'UserData', 0);
            
%             obj.UpdateGUIScanParameters(parametersStruct, handles);
%             obj.UpdatetLaserGUI(handles);
            drawnow;
        end
        
        function UpdateGUIScanParameters(obj, parametersStruct, handles) %#ok<INUSL>
            if isempty(parametersStruct) || ~isfield(parametersStruct, 'minVx')
                fprintf('Image is empty?\n');
                return
            end
            todo = 'Get the rounding consistent, here and in GUI file';
            set(handles.FromX,  'String', num2str(parametersStruct.minVx, '%.3f'));
            set(handles.ToX,  'String', num2str(parametersStruct.maxVx, '%.3f'));
            set(handles.NX,    'String', num2str(parametersStruct.NVx, '%d'));
            set(handles.bFixX, 'Value', parametersStruct.bFixVx);
            set(handles.FixX,  'String', num2str(parametersStruct.FixVx, '%.3f'));
            
            set(handles.FromY,  'String', num2str(parametersStruct.minVy, '%.3f'));
            set(handles.ToY,  'String', num2str(parametersStruct.maxVy, '%.3f'));
            set(handles.NY,    'String', num2str(parametersStruct.NVy, '%d'));
            set(handles.bFixY, 'Value', parametersStruct.bFixVy);
            set(handles.FixY,  'String', num2str(parametersStruct.FixVy, '%.3f'));
            
            set(handles.FromZ,  'String', num2str(parametersStruct.minVz, '%.3f'));
            set(handles.ToZ,  'String', num2str(parametersStruct.maxVz, '%.3f'));
            set(handles.NZ,    'String', num2str(parametersStruct.NVz, '%d'));
            set(handles.bFixZ, 'Value', parametersStruct.bFixVz);
            set(handles.FixZ,  'String', num2str(parametersStruct.FixVz, '%.3f'));
            
            set(handles.FixDT,  'String', num2str(parametersStruct.FixDT, '%.3f'));
            
            set(handles.FromX,  'UserData', num2str(parametersStruct.minVx, '%.3f'));
            set(handles.ToX,  'UserData', num2str(parametersStruct.maxVx, '%.3f'));
            set(handles.NX,    'UserData', num2str(parametersStruct.NVx, '%d'));
            set(handles.FixX,  'UserData', num2str(parametersStruct.FixVx, '%.3f'));
            
            set(handles.FromY,  'UserData', num2str(parametersStruct.minVy, '%.3f'));
            set(handles.ToY,  'UserData', num2str(parametersStruct.maxVy, '%.3f'));
            set(handles.NY,    'UserData', num2str(parametersStruct.NVy, '%d'));
            set(handles.FixY,  'UserData', num2str(parametersStruct.FixVy, '%.3f'));
            
            set(handles.FromZ,  'UserData', num2str(parametersStruct.minVz, '%.3f'));
            set(handles.ToZ,	'UserData', num2str(parametersStruct.maxVz, '%.3f'));
            set(handles.NZ,    'UserData', num2str(parametersStruct.NVz, '%d'));
            set(handles.FixZ,  'UserData', num2str(parametersStruct.FixVz, '%.3f'));
            
            set(handles.FixDT,   'UserData', num2str(parametersStruct.FixDT, '%.3f'));
        end
        
        function PlotAndSave(obj, handles, currentAxisHandle, isAutoSaveMode)
            % Plots the last scanned data (after scan, save or load) and
            % sends it to save if needed.
            % currentAxisHandle - (axis handle) of the needed figure.
            % Sometimes it's the gui and for saving it's a saparate figure.
            % isAutoSaveMode - (boolean) Save to autoSave path if needed - set to true.
            %                   if this function was called by one of the
            %                   saving or load buttons then there is no
            %                   need to save in the autoSave path - set to false.
            
            %Set the current axes
            if isempty(obj.lastScanedData) || ~isfield(obj.lastScanedData, 'dimentions')
                fprintf('Image is empty?\n');
                return
            end
            axes(currentAxisHandle);
            switch obj.lastScanedData.dimentions
                % 1D
                case 1
                    % plot the data on the given axis
                    plot(currentAxisHandle, obj.lastScanedData.curAxis, obj.lastScanedData.data);
                    xlabel([obj.lastScanedData.axisStr ' (\mum)']);
                    ylabel('kcps');
                    
                    % 2D
                case 2
                    % plot the 2D data
                    imagesc(obj.lastScanedData.data, 'XData', obj.lastScanedData.xData, ...
                        'YData', obj.lastScanedData.yData, 'Parent', currentAxisHandle);
                    try
                        eval(obj.lastScanedData.axisMode);
                        axis manual
                    catch
                        % Did not exist when image was saved
                        axis xy tight normal
                        axis manual
                    end
                    
                    xlabel([obj.lastScanedData.axisStr(1) ' (\mum)']);
                    ylabel([obj.lastScanedData.axisStr(2) ' (\mum)']);
                    
                    
                    %                     Not sure why it was needed, works perfectly fine
                    %                     without it, and it avoids the annoying glitch at the
                    %                     end (because the sizes were not proper defined)
                    %                     Yoav 02/03/17
                    
                    
                    %                     % Set axis limits - Important in case of scaning from
                    %                     % higher number to lower (backwards)
                    %                     try
                    %                         % old file version
                    %                         XvecData = [obj.lastScanedData.spX.spxMin obj.lastScanedData.spX.spxMax];
                    %                         YvecData = [obj.lastScanedData.spY.spyMin obj.lastScanedData.spY.spyMax];
                    %                         ZvecData = [obj.lastScanedData.spZ.spzMin obj.lastScanedData.spZ.spzMax];
                    %                     catch
                    %                         XvecData = [obj.lastScanedData.minVx obj.lastScanedData.maxVx];
                    %                         YvecData = [obj.lastScanedData.minVy obj.lastScanedData.maxVy];
                    %                         ZvecData = [obj.lastScanedData.minVz obj.lastScanedData.maxVz];
                    %                     end
                    %
                    %                     if strcmp(obj.lastScanedData.axisStr, 'xy')
                    %                         axis(currentAxisHandle,...
                    %                             [min(XvecData) max(XvecData) min(YvecData) max(YvecData)]);
                    %
                    %                     elseif strcmp(obj.lastScanedData.axisStr, 'yz')
                    %                         axis(currentAxisHandle, ...
                    %                             [min(YvecData) max(YvecData) min(ZvecData) max(ZvecData)]);
                    %
                    %                     elseif strcmp(obj.lastScanedData.axisStr, 'xz')
                    %                         axis(currentAxisHandle,...
                    %                             [min(XvecData) max(XvecData) min(ZvecData) max(ZvecData)]);
                    %                     end
                    
                    % Update the colormap according to the GUI parameters
                    obj.Colormap(handles, currentAxisHandle);
                    c = colorbar('peer', currentAxisHandle, 'location', 'EastOutside');
                    xlabel(c, 'kcps')
                    drawnow;
            end
            
            % Save image if in AutoSave mode & not in continous scan
            if get(handles.bAutoSaveImg,'Value') && isAutoSaveMode && ~get(handles.bScanCont, 'Value')
                obj.ImageSave('AutoSave', handles)
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%     Image Scan     %%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function ImageScan(obj, what, handles)
            switch what
                case 'Scan'
                    obj.CallMakeScan(handles);
                case 'StopScan'
                    obj.StopScan(handles);
                case 'SetRange'
                    obj.UpdateGUIScanParameters(obj.lastScanedData, handles);
                    return;
                otherwise
            end
        end
        
        function scanParameters = GetScanValues(obj, handles) %#ok<INUSL>
            % creates a struct from the Scan Parameters data on the GUI
            scanParameters = struct(...
                'minVx', str2double(get(handles.FromX,'String')),...
                'maxVx', str2double(get(handles.ToX,'String')),...
                'NVx',   str2double(get(handles.NX,'String')),...
                'bFixVx',get(handles.bFixX,'Value'),...
                'FixVx', str2double(get(handles.FixX,'String')),...
                ...
                'minVy', str2double(get(handles.FromY,'String')),...
                'maxVy', str2double(get(handles.ToY,'String')),...
                'NVy',   str2double(get(handles.NY,'String')),...
                'bFixVy',get(handles.bFixY,'Value'),...
                'FixVy', str2double(get(handles.FixY,'String')),...
                ...
                'minVz', str2double(get(handles.FromZ,'String')),...
                'maxVz', str2double(get(handles.ToZ,'String')),...
                'NVz',   str2double(get(handles.NZ,'String')),...
                'bFixVz',get(handles.bFixZ,'Value'),...
                'FixVz', str2double(get(handles.FixZ,'String')),...
                ...
                'FixDT', str2double(get(handles.FixDT,'String')));
        end
%         % is being checked in the stage itself. not needed.
%         function scanOk = CheckScanRange(obj, x0, minX, maxX, y0, minY, maxY, z0, minZ, maxZ)
%             scanOk = 1;
%             if (~obj.stage.PointIsInRange('x', maxX)); [negLimit, posLimit] = obj.stage.ReturnLimits('x'); fprintf('Max x is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             if (~obj.stage.PointIsInRange('x', minX)); [negLimit, posLimit] = obj.stage.ReturnLimits('x'); fprintf('Min x is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             if (~obj.stage.PointIsInRange('y', maxY)); [negLimit, posLimit] = obj.stage.ReturnLimits('y'); fprintf('Max y is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             if (~obj.stage.PointIsInRange('y', minY)); [negLimit, posLimit] = obj.stage.ReturnLimits('y'); fprintf('Min y is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             if (~obj.stage.PointIsInRange('z', maxZ)); [negLimit, posLimit] = obj.stage.ReturnLimits('z'); fprintf('Max z is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             if (~obj.stage.PointIsInRange('z', minZ)); [negLimit, posLimit] = obj.stage.ReturnLimits('z'); fprintf('Min z is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             
%             % Check fixed values
%             if (~obj.stage.PointIsInRange('x', x0)); [negLimit, posLimit] = obj.stage.ReturnLimits('x'); fprintf('Fixed x is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             if (~obj.stage.PointIsInRange('y', y0)); [negLimit, posLimit] = obj.stage.ReturnLimits('y'); fprintf('Fixed y is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%             if (~obj.stage.PointIsInRange('z', z0)); [negLimit, posLimit] = obj.stage.ReturnLimits('z'); fprintf('Fixed z is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); scanOk = 0; end
%         end
%         
        function CallMakeScan(obj, handles)
            % Reset parameters before a new scan
            
            % Reset the Notes before scanning
            set(handles.SaveNotes, 'String', '');
            
            % Reset the start scan boolean
            obj.startScanBoolean = true;
            
            % Update GUI's scan values and save to lastScanedData
            scanParameters = obj.GetScanValues(handles);
            obj.SaveScanParameters(scanParameters, handles);
            
            % Save the handle state at the moment that 'scan' was pressed.
            % any changes in the GUI during the scan will be ignored.
            fastScan = get(handles.bFastScan, 'Value');
            obj.stage.FastScan(fastScan);
            
            % Stop continuous tracking
            set(handles.bTrackCont, 'Value', 0);
            
            % Start Scan
            disp('Initiating scan...');
            obj.SPCMGateEnable(1);
            timerVal = tic;
            kcps = obj.MakeScan(scanParameters, fastScan, handles);
            drawnow;
            while get(handles.bScanCont, 'Value') && obj.startScanBoolean
                scanParameters = obj.GetScanValues(handles);
                kcps = obj.MakeScan(scanParameters, fastScan, handles, kcps);
                drawnow;
            end
            toc(timerVal)
            % update the stage position in the end of scan
            obj.PiezoQueries(handles);
            obj.SPCMGateEnable(0);
        end
        
        function kcps = MakeScan(obj, parametersStruct, fastScan, handles, varargin)
            % varargin can be the kcps if it is continous scan.
            % If kcps is given, some things are ignored to speed things up.
            skip = exist('kcps', 'var');
            
            minX = parametersStruct.minVx;
            minY = parametersStruct.minVy;
            minZ = parametersStruct.minVz;
            maxX = parametersStruct.maxVx;
            maxY = parametersStruct.maxVy;
            maxZ = parametersStruct.maxVz;
            
            nX = parametersStruct.NVx;
            nY = parametersStruct.NVy;
            nZ = parametersStruct.NVz;
            x = minX:(maxX-minX)/(nX-1):maxX;
            y = minY:(maxY-minY)/(nY-1):maxY;
            z = minZ:(maxZ-minZ)/(nZ-1):maxZ;
            
            x0 = parametersStruct.FixVx;
            y0 = parametersStruct.FixVy;
            z0 = parametersStruct.FixVz;
            
            bX = ~parametersStruct.bFixVx;
            bY = ~parametersStruct.bFixVy;
            bZ = ~parametersStruct.bFixVz;
            
            % Check if range is within piezo range - needed????
            todo = 'In any case this should be moved to CallMakeScan';
            if ~skip && ~CheckScanRange(obj, x0, minX, maxX, y0, minY, maxY, z0, minZ, maxZ)
                return
            end
            
            % Pixel time
            tPixel = parametersStruct.FixDT;
            
            % Scanning parameters
            
            % A flat section at the start of ramp.
            % Not needed genrally, a stage can overwrite if needed
            nFlat = 0;
            
            % Let the waveform over run the start and end.
            % Not needed genrally, a stage can overwrite if needed
            nOverRun = 0;
            
            % Check number of dimensions
            nDimensions = bX + bY + bZ;
            switch nDimensions
                case 0
                    disp('Nothing to scan dude!');
                    return;
                case 1 % One dimensional scanning
                    if bX
                        %%%%%%%%%%%%%%%%%%%% ONE DIMENSIONAL SCAN X %%%%%%%%%%%%%%%%%%%%
                        kcps = obj.OneDimensionalScan('X', x, y0, z0, nX, nFlat, nOverRun, tPixel, fastScan, handles);
                        
                        % Plot
                        obj.SaveScanParameters(kcps, x, y, 1, x, 'x', handles);
                        obj.PlotAndSave(handles, handles.axes1, true);
                    elseif bY
                        %%%%%%%%%%%%%%%%%%%% ONE DIMENSIONAL SCAN Y %%%%%%%%%%%%%%%%%%%%
                        kcps = obj.OneDimensionalScan('Y', x0, y, z0, nY, nFlat, nOverRun, tPixel, fastScan, handles);
                        
                        % Plot
                        obj.SaveScanParameters(kcps, x, y, 1, y, 'y', handles);
                        obj.PlotAndSave(handles, handles.axes1, true);
                    elseif bZ
                        %%%%%%%%%%%%%%%%%%%% ONE DIMENSIONAL SCAN Z %%%%%%%%%%%%%%%%%%%%
                        kcps = obj.OneDimensionalScan('Z', x0, y0, z, nZ, nFlat, nOverRun, tPixel, fastScan, handles);
                        
                        % Plot
                        obj.SaveScanParameters(kcps, x, y, 1, z, 'z', handles);
                        obj.PlotAndSave(handles, handles.axes1, true);
                    end
                case 2 % Two dimensional scanning
                    if (bX && bY) %XY scan
                        %%%%%%%%%%%%%%%%%%%% TWO DIMENSIONAL SCAN XY %%%%%%%%%%%%%%%%%%%%
                        kcps = obj.TwoDimensionalScan('XY', x, y, z0, nX, nY, nFlat, nOverRun, tPixel, fastScan, handles, varargin{:});
                        
                        % Plot
                        obj.SaveScanParameters(kcps, x, y, 2, 0, 'xy', handles);
                        obj.PlotAndSave(handles, handles.axes1, true);
                    elseif (bX && bZ) % XZ scan
                        %%%%%%%%%%%%%%%%%%%% TWO DIMENSIONAL SCAN XZ %%%%%%%%%%%%%%%%%%%%
                        kcps = obj.TwoDimensionalScan('XZ', x, y0, z, nX, nZ, nFlat, nOverRun, tPixel, fastScan, handles, varargin{:});
                        
                        % Plot
                        obj.SaveScanParameters(kcps, x, z, 2, 0, 'xz', handles);
                        obj.PlotAndSave(handles, handles.axes1, true);
                    elseif (bY && bZ) % YZ scan
                        %%%%%%%%%%%%%%%%%%%% TWO DIMENSIONAL SCAN YZ %%%%%%%%%%%%%%%%%%%%
                        kcps = obj.TwoDimensionalScan('YZ', x0, y, z, nY, nZ, nFlat, nOverRun, tPixel, fastScan, handles, varargin{:});
                        
                        % Plot
                        obj.SaveScanParameters(kcps, y, z, 2, 0, 'yz', handles);
                        obj.PlotAndSave(handles, handles.axes1, true);
                    end
                case 3
                    warning('3D scan not implemented!');
                otherwise
                    warning('%d dimensional scan request. String thoery not yet implemented!\n', nDimensions);
            end
        end
        
        function kcps = OneDimensionalScan(obj, axis, x, y, z, nPixels, nFlat, nOverRun, tPixel, fastScan, handles)
            % Starts a one dimensional scan with the given parameters and return
            % the kcps.
            % Axis should be 'X', 'Y' or 'Z'.
            
            maxScanSize = obj.stage.ReturnMaxScanSize(1);
            kcps = zeros(1, nPixels);
            
            % Check if scan is too large and divide into 2 smaller parts.
            if (nPixels > maxScanSize)
                fprintf('Max number of points to scan is %d, %d were given for %s axis, spliting into 2 scans.\n', maxScanSize, nPixels, lower(axis));
                
                % Divide the vector that is being scanned into 2 parts.
                eval(sprintf('%s1 = %s(1:floor(end/2)); %s2 = %s(floor(end/2)+1:end);', lower(axis), lower(axis), lower(axis), lower(axis)));
                
                % Launch the first smaller scans.
                switch lower(axis)
                    case 'x'
                        kcps1 = obj.OneDimensionalScan(axis, x1, y, z, length(x1), nFlat, nOverRun, tPixel, fastScan, handles);
                    case 'y'
                        kcps1 = obj.OneDimensionalScan(axis, x, y1, z, length(y1), nFlat, nOverRun, tPixel, fastScan, handles);
                    case 'z'
                        kcps1 = obj.OneDimensionalScan(axis, x, y, z1, length(z1), nFlat, nOverRun, tPixel, fastScan, handles);
                end
                
                % Draw
                eval(sprintf('plot(handles.axes1, %s1, kcps1);', lower(axis)));
                eval(sprintf('xlabel(''%s (\\mum)'');', lower(axis)));
                ylabel('kcps');
                ylim([0 max(kcps1)+1]);
                eval(sprintf('xlim([min(%s) max(%s)]);', lower(axis), lower(axis)));
                drawnow;
                
                % Launch the second smaller scans.
                switch lower(axis)
                    case 'x'
                        kcps2 = obj.OneDimensionalScan(axis, x2, y, z, length(x2), nFlat, nOverRun, tPixel, fastScan, handles);
                    case 'y'
                        kcps2 = obj.OneDimensionalScan(axis, x, y2, z, length(y2), nFlat, nOverRun, tPixel, fastScan, handles);
                    case 'z'
                        kcps2 = obj.OneDimensionalScan(axis, x, y, z2, length(z2), nFlat, nOverRun, tPixel, fastScan, handles);
                end
                
                % Combine & return the 2 parts.
                kcps = [kcps1 kcps2];
                return
            end
            
            if ~obj.startScanBoolean
                return
            end
            
            % Prepare Scan
            eval(sprintf('obj.stage.PrepareScan%s(x, y, z, nFlat, nOverRun, tPixel);', upper(axis)));
            
            % Pre-Processing
            nPoints = nPixels + 2*(nFlat + nOverRun);
            timeout = 10*nPoints*tPixel;
            if fastScan
                nCounts = nPixels+1; % Number of points read should be one longer than nPixels
            else
                nCounts = nPixels; % Number of points read should be nPixels
            end
            
            trial=1;
            while trial<4 && trial>0
                try
                    % Define two counters, Ctr0 counts the SPCM pulses and Ctr1
                    % counts the duration of the pixel (stage movement)
                    if fastScan
                        hCounterSPCM = obj.CreateDAQEdgeCountingMeas('dev1/Ctr0', nCounts, 'SPCMStage');
                        hCounterTime = obj.CreateDAQEdgeCountingMeas('dev1/Ctr1', nCounts, 'TimeStage');
                    else
                        hCounterSPCM = obj.CreateDAQPulseWidthMeas('dev1/Ctr0', nCounts, 'SPCMStage');
                        hCounterTime = obj.CreateDAQPulseWidthMeas('dev1/Ctr1', nCounts, 'TimeStage');
                    end
                    status = DAQmxStartTask(hCounterSPCM);
                    DAQmxErr(status)
                    status = DAQmxStartTask(hCounterTime);
                    DAQmxErr(status)
                    
                    % Scan
                    eval(sprintf('obj.stage.Scan%s(x, y, z, nFlat, nOverRun, tPixel);', upper(axis)));
                    
                    % Read counter
                    [countsSPCM, ~] = obj.ReadDAQCounter(hCounterSPCM, nCounts, timeout);
                    [countsTime, ~] = obj.ReadDAQCounter(hCounterTime, nCounts, timeout);
                    if fastScan
                        countsSPCM = diff(countsSPCM);
                        countsTime = diff(countsTime);
                    end
                    nReadSPCM = length(countsSPCM);
                    nReadTime = length(countsTime);
                    DAQmxStopTask(hCounterTime);
                    DAQmxClearTask(hCounterTime);
                    DAQmxStopTask(hCounterSPCM);
                    DAQmxClearTask(hCounterSPCM);
                    
                    if ~nnz(countsTime)
                        error('No time signal detected')
                    end
                    trial=0; % This marks that the line succeeded
                catch err
%                     rethrow(err) % Uncomment to debug
                    warning(err.message);
                    
                    if ~obj.startScanBoolean
                        obj.stage.AbortScan();
                        return
                    end
                    
                    fprintf('Scan failed at trial %d, attempting to rescan.\n', trial);
                    trial=trial+1;
                end
            end
            obj.stage.AbortScan();
            
            if (nReadSPCM ~= nReadTime)
                error(sprintf('SPCM counter has %d pixels while time counter has %d counter, scan failed', nReadSPCM, nReadTime)); %#ok<SPERR>
            end
            
            % Process data
            kiloCounts = double(countsSPCM)/1000;
            time = double(countsTime)*1e-8; % For seconds
            kcps = kiloCounts./time;
            if nnz(isnan(kcps))
                if nnz(time)==0
                    error('NaN detected in kcps, time is zeros (no data read from the DAQ)')
                else
                    error('NaN detected in kcps')
                end
            end
        end
        
        function kcps = TwoDimensionalScan(obj, axes, x, y, z, nMacroPixels, nNormalPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps, scanIndices)
            % Starts a two dimensional scan with the given parameters and return
            % the kcps.
            % Axes should be 'XY', 'XZ', 'YX', 'YZ', 'ZX' or 'ZY'.
            % kcps is optional and is useful for continous scans.
            
            % Flip is used to to keep the image orientation constant regardless of
            % XY or YX scan.
            
            todo = 'macro pixel is line pixel - num of pixels every line' % Maybe rename nPixelsPerLine
            todo = 'normal pixel is total lines - num of lines' % Maybe rename nLinesPerScan
            
            switch axes
                case {'XY', 'XZ', 'YZ'}
                    flipped = 0;
                otherwise
                    flipped = 1;
            end
            
            if ~exist('kcps', 'var')
                if flipped
                    kcps = zeros(nMacroPixels, nNormalPixels);
                else
                    kcps = zeros(nNormalPixels, nMacroPixels);
                end
            end
            if ~exist('scanIndices', 'var') % From where to where should we scan & enter data into the kcps matrix
                scanIndices(1) = 1;
                scanIndices(2) = nMacroPixels;
            end
            
            maxScanSize = obj.stage.ReturnMaxScanSize(2);
            todo = 'amount of dimensions! notice the argument'
            
            % Check if scan is too large.
            if (nMacroPixels > maxScanSize)
                if (nNormalPixels <= maxScanSize)
                    fprintf('Max number of points is %d, %d were given for %s axis and %d for %s axis, ', maxScanSize, nMacroPixels, lower(axes(1)), nNormalPixels, lower(axes(2)));
                    if ~strcmpi(axes(2), 'z') % Yonantan 21.7.16 - do not flip for z axis, causes hysteris
                        fprintf('flipping axes.\n');
                        kcps = obj.TwoDimensionalScan(fliplr(axes), x, y, z, nNormalPixels, nMacroPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps);
                        return
                    else
                        fprintf('not flipping axes as second axis is z, this should be put as an option!\n');
                    end
                end
                fprintf('Max number of points is %d, %d were given for %s axis and %d for %s axis, splitting into 2 scans.\n', maxScanSize, nMacroPixels, lower(axes(1)), nNormalPixels, lower(axes(2)));
                
                % Divide the vector into 2 parts.              
                eval(sprintf('half = floor(length(%s(scanIndices(1):scanIndices(2)))/2);', lower(axes(1))))
                scanIndicesFirst = [scanIndices(1), scanIndices(1) - 1 + half];
                nPixelsFirst = scanIndicesFirst(2)-scanIndicesFirst(1)+1;
                scanIndicesSecond = [scanIndices(1) + half, scanIndices(2)];
                nPixelSecond = scanIndicesSecond(2)-scanIndicesSecond(1)+1;
                
                % Launch 2 smaller scans.
                switch lower(axes(1))
                    case 'x'
                        kcps = obj.TwoDimensionalScan(axes, x, y, z, nPixelsFirst, nNormalPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps, scanIndicesFirst);
                        kcps = obj.TwoDimensionalScan(axes, x, y, z, nPixelSecond, nNormalPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps, scanIndicesSecond);
                    case 'y'
                        kcps = obj.TwoDimensionalScan(axes, x, y, z, nPixelsFirst, nNormalPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps, scanIndicesFirst);
                        kcps = obj.TwoDimensionalScan(axes, x, y, z, nPixelSecond, nNormalPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps, scanIndicesSecond);
                    case 'z'
                        kcps = obj.TwoDimensionalScan(axes, x, y, z, nPixelsFirst, nNormalPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps, scanIndicesFirst);
                        kcps = obj.TwoDimensionalScan(axes, x, y, z, nPixelSecond, nNormalPixels, nFlat, nOverRun, tPixel, fastScan, handles, kcps, scanIndicesSecond);
                end
                return
            end
            
            % Pre-Processing
            nMacroPoints = nMacroPixels + nFlat + 2*nOverRun;
            timeout = 10*nMacroPoints*tPixel;
            
            if fastScan
                nCounts = nMacroPixels+1; % Number of points read should be one longer than nMacroPixels
            else
                nCounts = nMacroPixels; % Number of points read should be nMacroPixels
            end
            
            if ~obj.startScanBoolean
                return
            end
            
            % Prepare scan
            switch lower(axes(1))
                case 'x'
                    eval(sprintf('obj.stage.PrepareScan%s(x(scanIndices(1):scanIndices(2)), y, z, nFlat, nOverRun, tPixel);', upper(axes)));
                case 'y'
                    eval(sprintf('obj.stage.PrepareScan%s(x, y(scanIndices(1):scanIndices(2)), z, nFlat, nOverRun, tPixel);', upper(axes)));
                case 'z'
                    eval(sprintf('obj.stage.PrepareScan%s(x, y, z(scanIndices(1):scanIndices(2)), nFlat, nOverRun, tPixel);', upper(axes)));
            end
            
            
            if flipped
                % After this part, axes is being used only for plotting, and we
                % want the plot to be the same, so flipping axes back.
                axes = fliplr(axes);
            end
            
            for i=1:nNormalPixels
                if ~obj.startScanBoolean
                    break;
                end
                
                trial=1;
                while trial<6 && trial>0
                    try
                        afterLastLine = 0;
                        % Define two counters, Ctr0 counts the SPCM pulses and Ctr1
                        % counts the duration of the pixel (stage movement)
                        if fastScan
                            hCounterSPCM = obj.CreateDAQEdgeCountingMeas('dev1/Ctr0', nCounts, 'SPCMStage');
                            hCounterTime = obj.CreateDAQEdgeCountingMeas('dev1/Ctr1', nCounts, 'TimeStage');
                        else
                            hCounterSPCM = obj.CreateDAQPulseWidthMeas('dev1/Ctr0', nCounts, 'SPCMStage');
                            hCounterTime = obj.CreateDAQPulseWidthMeas('dev1/Ctr1', nCounts, 'TimeStage');
                        end
                        
                        % Start counter
                        status = DAQmxStartTask(hCounterSPCM);
                        DAQmxErr(status);
                        status = DAQmxStartTask(hCounterTime);
                        DAQmxErr(status);
                        
                        afterLastLine = 1;
                        % Scan line
                        forwards = obj.stage.ScanNextLine();
                        todo = 'forwards: 1 is left-to-right (inc.), 0 is otherwise'
                        
                        % Read counter
                        [countsSPCM, ~] = obj.ReadDAQCounter(hCounterSPCM, nCounts, timeout);
                        [countsTime, ~] = obj.ReadDAQCounter(hCounterTime, nCounts, timeout);
                        if fastScan
                            countsSPCM = diff(countsSPCM);
                            countsTime = diff(countsTime);
                        end
                        nReadSPCM = length(countsSPCM);
                        nReadTime = length(countsTime);
                        
                        if (nReadSPCM ~= nReadTime)
                            error('Error scanning line %d.\nSPCM counter has %d pixels while time counter has %d pixels. Skipping line...\n', i, nReadSPCM, nReadTime);
                        elseif (nReadSPCM ~= nMacroPixels)
                            error('Error scanning line %d.\nCounters have %d pixels instead of %d. Skipping line...\n', i, nReadSPCM, nMacroPixels);
                        end
                        
                        % Stop counter
                        status = DAQmxStopTask(hCounterSPCM);
                        DAQmxErr(status);
                        status = DAQmxStopTask(hCounterTime);
                        DAQmxErr(status);
                        
                        % Process data
                        kiloCounts = double(countsSPCM)/1000;
                        time = double(countsTime)*1e-8; % For seconds
                        if flipped
                            if forwards
                                kcps(scanIndices(1):scanIndices(2),i) = kiloCounts./time;
                            else % Backwards
                                kcps(scanIndices(1):scanIndices(2),i) = fliplr(kiloCounts./time);
                            end
                        else
                            if forwards
                                kcps(i,scanIndices(1):scanIndices(2)) = kiloCounts./time;
                            else % Backwards
                                kcps(i,scanIndices(1):scanIndices(2)) = fliplr(kiloCounts./time);
                            end
                        end
                        trial=0; % This marks that the line succeeded
                    catch err
%                       rethrow(err);  % Uncomment to debug
                        warning(err.message);
                        
                        if ~obj.startScanBoolean
                            obj.stage.AbortScan();
                            return;
                        end
                        
                        fprintf('Line %d failed at trial %d, attempting to rescan line.\n', i, trial);
                        trial=trial+1;
                        if afterLastLine
                            try
                                obj.stage.PrepareRescanLine(); % Prepare to rescan the line
                            catch err2
                                obj.stage.AbortScan();
                                rethrow(err2)
                            end
                        end
                    end
                end
                
                % Plot & Update
                eval(sprintf('imagesc(kcps, ''XData'', %s, ''YData'', %s, ''Parent'', handles.axes1);', lower(axes(1)), lower(axes(2))));
                
                list = get(handles.AxisDisplay, 'String');
                val = get(handles.AxisDisplay, 'Value');
                eval(sprintf('axis xy tight %s;', list{val}));
                axis manual
                
                obj.Colormap(handles, handles.axes1)
                eval(sprintf('xlabel(''%s (\\mum)'');', lower(axes(1))));
                eval(sprintf('ylabel(''%s (\\mum)'');', lower(axes(2))));
                c = colorbar('peer', handles.axes1, 'location', 'EastOutside');
                xlabel(c, 'kcps')
                drawnow;
            end
            obj.stage.AbortScan();
            
            % Clear counter
            DAQmxStopTask(hCounterSPCM);
            DAQmxStopTask(hCounterTime);
            DAQmxClearTask(hCounterSPCM);
            DAQmxClearTask(hCounterTime);
        end
        
        function StopScan(obj, handles) %#ok<INUSD>
            % Stops the scan and the stage movment
            obj.startScanBoolean = false;
            %             %24.1.17 the boolean is being checked inside the 
            %             scan function, and they should do the abortscan.
            %
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%     Stage       %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function SPCMGateEnable(obj, bGate, handles) %#ok<INUSL,INUSD>
            device = 'dev1';
            port = 1;
            line = 4;
            
            DAQmx_Val_ChanForAllLines = daq.ni.NIDAQmx.DAQmx_Val_ChanForAllLines;
            DAQmx_Val_GroupByChannel = daq.ni.NIDAQmx.DAQmx_Val_GroupByChannel;
            
            [ status, ~, task ] = DAQmxCreateTask([]);
            DAQmxErr(status);
            
            status = DAQmxCreateDOChan(task, sprintf('/%s/port%d/line%d', device, port, line), '', DAQmx_Val_ChanForAllLines);
            DAQmxErr(status);
            
            status = DAQmxWriteDigitalU32(task, 1, 1, 10, DAQmx_Val_GroupByChannel, bGate*2^line, 1);
            DAQmxErr(status);
            
            DAQmxStopTask(task);
            DAQmxClearTask(task);
        end
        
        function task = CreateDAQEdgeCountingMeas(obj, device, nCounts, source) %#ok<INUSL>
            % Creates an edge counting measurement task, if source is set to 'SPCMStage'
            % it will give the number of the SPCM counts, if it's set to 'TimeStage'
            % it'll give the time in a 100MHz timebase (10^8 seconds).
            
            DAQmx_Val_Rising = daq.ni.NIDAQmx.DAQmx_Val_Rising;
            DAQmx_Val_Falling = daq.ni.NIDAQmx.DAQmx_Val_Falling;
            DAQmx_Val_ContSamps = daq.ni.NIDAQmx.DAQmx_Val_ContSamps;
            DAQmx_Val_CountUp = daq.ni.NIDAQmx.DAQmx_Val_CountUp;
            
            [ status, ~, task ] = DAQmxCreateTask([]);
            DAQmxErr(status);
            
            status = DAQmxCreateCICountEdgesChan(task, device, '', DAQmx_Val_Rising, 0, DAQmx_Val_CountUp);
            DAQmxErr(status);
            
            status = DAQmxCfgSampClkTiming(task, '/dev1/PFI1', 1000000.0, DAQmx_Val_Falling, DAQmx_Val_ContSamps, nCounts);
            DAQmxErr(status);
            
            switch source
                case 'SPCMStage' % Counts the number of SPCM pulses in an external pulse given by the stage
                    status = DAQmxCfgSampClkTiming(task, '/dev1/PFI1', 1000000.0, DAQmx_Val_Falling, DAQmx_Val_ContSamps, nCounts);
                    DAQmxErr(status);
                    DAQmxSet(task, 'CI.CountEdgesTerm', device, '/dev1/PFI5');
                case 'TimeStage' % Counts the number of 100MHz pulses in an external pulse given by the stage in order to know its duration
                    % 100MHz clock is the default, but we set it to make sure
                    % (protection against future changes)
                    status = DAQmxCfgSampClkTiming(task, '/dev1/PFI1', 1000000.0, DAQmx_Val_Falling, DAQmx_Val_ContSamps, nCounts);
                    DAQmxErr(status);
                    DAQmxSet(task, 'CI.CountEdgesTerm', device, '/dev1/100MHzTimebase');
                case 'SPCMFixedTime' % Counts the number of SPCM pulses in 10ms periods, nPixels define how many periods.
                    status = DAQmxCfgSampClkTiming(task, '/dev1/100kHzTimebase', 100000.0, DAQmx_Val_Falling, DAQmx_Val_ContSamps, nCounts);
                    DAQmxErr(status);
                    DAQmxSet(task, 'CI.CountEdgesTerm', device, '/dev1/PFI5');
                otherwise
                    error('Unknown source: %s', source);
            end
        end
        
        function task = CreateDAQPulseWidthMeas(obj, device, nCounts, source) %#ok<INUSL>
            % Creates a pulse width measurement task, if source is set to 'SPCM' it will
            % give the number of the SPCM counts, if it's set to 'time' it'll give
            % the time in a 100MHz timebase (10^8 seconds).
            
            DAQmx_Val_Rising = daq.ni.NIDAQmx.DAQmx_Val_Rising; % Rising
            DAQmx_Val_FiniteSamps = daq.ni.NIDAQmx.DAQmx_Val_FiniteSamps; % Finite Samples
            DAQmx_Val_Seconds = daq.ni.NIDAQmx.DAQmx_Val_Seconds; % Seconds
            
            [ status, ~, task ] = DAQmxCreateTask([]);
            DAQmxErr(status);
            
            status = DAQmxCreateCIPulseWidthChan(task, device, '', 0.000000100, 18.38860750, DAQmx_Val_Seconds, DAQmx_Val_Rising, '');
            DAQmxErr(status);
            
            % nPixels has to be the number of samples to read (this is important)
            status = DAQmxCfgImplicitTiming(task, DAQmx_Val_FiniteSamps , nCounts);
            DAQmxErr(status);
            
            switch source
                case 'SPCMStage'
                    DAQmxSet(task, 'CI.PulseWidthTerm', device, '/dev1/PFI1');
                    DAQmxSet(task, 'CI.CtrTimebaseSrc', device, '/dev1/PFI5');
                case 'TimeStage' % Counts the number of 100MHz pulses in an external pulse given by the stage in order to know its duration
                    % 100MHz clock is the default, but we set it to make sure
                    % (protection against future changes)
                    DAQmxSet(task, 'CI.CtrTimebaseSrc', device, '/dev1/100MHzTimebase');
                    DAQmxSet(task, 'CI.PulseWidthTerm', device, '/dev1/PFI1');
                case 'SPCMFixedTime' % Counts the number of SPCM pulses in 10ms periods, nPixels define how many periods.
                    DAQmxSet(task, 'CI.PulseWidthTerm', device, '/dev1/100kHzTimebase');
                    DAQmxSet(task, 'CI.CountEdgesTerm', device, '/dev1/PFI5');
                otherwise
                    error('Unknown source: %s', source);
            end
            DAQmxSet(task, 'CI.DupCountPrevent', device, 1);
        end
        
        function Close(obj)
            % Closes the GUI, disconnects the stages
            obj.stage.CloseConnection();
        end
        
        function ResetPiezo(obj, handles) %#ok<INUSD>
            % Resets the connection with the stage
            fprintf('Resetting Piezo Stage, Please Wait...\n');
            obj.stage.CloseConnection();
            obj.stage.Reconnect();
            todo = 'force reference?';
            fprintf('Piezo Stage Ready!\n');
        end
        
        function ResetDAQ(obj, handles) %#ok<INUSD>
            DAQmxResetDevice('dev1');
            fprintf('DAQ Card Ready!\n');
            todo = 'Fix laser output!'
        end
        
        function CloseImage(obj, handles) %#ok<INUSD>
            % Close the GUI and all the objects and classes it used
            obj.stage.CloseConnection();
            clear obj.stage;
            clear ClassStage;
        end
        
        function ChangeLoopMode(obj, mode, handles) %#ok<INUSD>
            % Changes between open and closed loop
            obj.stage.ChangeLoopMode(mode);
        end
        
        function PiezoSingleStep(obj, what, handles)
            % moves the stage one step
            stepSize = str2double(get(handles.StepSize, 'String'));
            regexpResult = regexp(what, '(x|y|z)|(Inc|Dec)', 'Match');
            axis = regexpResult{1};
            direction = regexpResult{2};
            switch direction
                case 'Inc'
                    step = stepSize;
                case 'Dec'
                    step = -stepSize;
                otherwise
            end
            obj.stage.RelativeMove(axis, step);
            % Update the GUI according to the new location of the stage
            obj.PiezoQueries(handles);
        end
        
        function PiezoQueries(obj, handles)
            % Ask the stage for it current location and updates the GUI
            % accordingly
            pos = obj.stage.Pos('xyz');
            obj.UpdatePositionInGUI('xyz', pos, handles);
            try
                obj.DrawCrosshairs(handles);
            catch
            end
        end
        
        function [readArray, nRead] = ReadDAQCounter(obj, task, nCounts, timeout) %#ok<INUSL>
            numSampsPerChan = nCounts;
            readArray = zeros(1, nCounts);
            arraySizeInSamps = nCounts;
            sampsPerChanRead = int32(0);
            
            [status, readArray, nRead] = DAQmxReadCounterU32(task, numSampsPerChan, timeout, readArray, arraySizeInSamps, sampsPerChanRead);
            DAQmxErr(status);
        end
        
        function UpdatePositionInGUI(obj, axisStr, pos, handles) %#ok<INUSL,INUSD>
            % Update the GUI "Fixed Position" according to the given
            % position.
            % 'axisStr' Should be a string with the axes with the same
            % length as the 'pos' vector.
            % 'pos' - vector the size of the scan dimentions or current
            % location (xyz)
            
            for i = 1:length(axisStr)
                posStr = sprintf('%.2f', pos(i)); %#ok<NASGU>
                
                % update the gui with the new position - on each
                % axis(x,y,z)
                eval(sprintf('set(handles.Fix%s,''String'', posStr)', upper(axisStr(i))));
                eval(sprintf('set(handles.Fix%s,''UserData'', posStr)', upper(axisStr(i))));
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%              ImageSave             %%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function ImageSave(obj, what, handles)
            if isempty(obj.lastScanedData) || ~isfield(obj.lastScanedData, 'axisStr')
                fprintf('Image is empty?\n');
                return
            end
            switch what
                case 'AutoSave'
                    filename = [datestr(now, obj.saveFileData.format) '_' obj.lastScanedData.axisStr];
                    obj.SavePlot(handles, obj.saveFileData.autoSavePath, filename, 0);
                case 'Save'
                    % Updated time just before saving
                    filename = [datestr(now, obj.saveFileData.format) '_' obj.lastScanedData.axisStr];
                    obj.SavePlot(handles, obj.saveFileData.saveAsPath, filename, 0);
                case 'SaveAs'
                    obj.SaveAs(handles);
            end
        end
        
        function SaveAs(obj, handles)
            % Pop up a window - where to save the files (mat and jpg)
            % and saves the new path for the next saving
            filename = [datestr(now,obj.saveFileData.format) '_' obj.lastScanedData.axisStr]; % Updated time just before saving
            defaultFileName = [obj.saveFileData.saveAsPath filename];
            [file, path, ~] = uiputfile({'*.jpg'; '*.mat'}, 'Save File As', defaultFileName);
            
            % In case user presses "Save"
            if (file)
                % update the new path
                obj.saveFileData.saveAsPath = path;
                display(['Attention! The path was changed to: ' path]);
                
                % Erase the file name ending
                file = file(1:end-4);
                
                % plot and save the data
                obj.SavePlot(handles, obj.saveFileData.saveAsPath, file, 0);
            end
            
            % Nothing is saved incase 'Cancel' is pressed
        end
        
        function SavePlot(obj, handles, path, file, isUpdateNotes)
            % Plots the current axes on a new figure, saves it as a .jpg
            % and .mat files with all the last scaned data
            
            % create a new figure to save, and plot on it
            figure_handle = figure('Visible', 'off');
            cb = colorbar(handles.axes1);
            copyobj([handles.axes1 cb], figure_handle);
            todo = 'Copy these three lines to the save area. Think about lastScannedData name, also update image proprties';
            
            % update notes just before saving
            if ~isUpdateNotes
                obj.PlotAndSave(handles, handles.axes1, false);
                obj.lastScanedData.Notes = get(handles.SaveNotes, 'String');
                % Update colormap and caxis just before saving
                obj.lastScanedData.Colormap = get(handles.Colormap, 'Value');
                obj.lastScanedData.caxisMin = str2num(get(handles.CAxisMin, 'String')); %#ok<ST2NM>
                obj.lastScanedData.caxisMax = str2num(get(handles.CAxisMax, 'String')); %#ok<ST2NM>
            end
            
            % Update the data before saving and save .mat file
            filePath = [path file];
            lastScanedData = obj.lastScanedData; %#ok<PROPLC,NASGU>
            save([filePath '.mat'], 'lastScanedData');
            
            % Save jpg image
            title(obj.lastScanedData.Notes); %set the notes as the plot's title
            saveas(figure_handle, [filePath '.jpg']);
            
            % close the figure
            close(figure_handle);
            % Print the saved image path only when saveas or save is
            % pressed - not when autosaved
            if get(handles.SaveAs, 'Value') || get(handles.Save, 'Value')
                disp(['Saved as: ' filePath ' -> .mat and .jpg']);
            end
            obj.saveFileData.loadPath = path;
            set(handles.strLoadedFile, 'String', [file '.mat']);
        end
        
        function UpdateNotes(obj, handles)
            % Updates only the notes on the loaded file.
            
            % In case changes were made on the GUI - dont save them.
            % load the original scaned data (without updating the gui)
            % and update only the notes
            currentLoadedFile = get(handles.strLoadedFile, 'String');
            loadedData = load([obj.saveFileData.loadPath currentLoadedFile]);
            % In case of older saved files or change of the name of the lastScanedData
            % this code will load any struct name that was saved.
            structName = fieldnames(loadedData);
            eval(['obj.lastScanedData = loadedData.' structName{1} ';']);
            
            % update last scanned data
            obj.lastScanedData.Notes = get(handles.LoadedNotes, 'String');
            
            % save the new data on the same name
            currentLoadedFile = currentLoadedFile(1:end-4); todo = 'make it using regexp, to make it roboust'
            obj.SavePlot(handles, obj.saveFileData.loadPath, currentLoadedFile, 1);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%              ImageLoad              %%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function ImageLoad(obj, what, handles)
            switch what
                case 'Load'
                    obj.LoadWindow(handles);
                case 'LoadNext'
                    obj.LoadNextOrPrev('Next', handles);
                case 'LoadPrevious'
                    obj.LoadNextOrPrev('Previous', handles);
                case 'Delete'
                    obj.DeleteImg(handles);
                otherwise
            end
        end
        
        function LoadWindow(obj, handles)
            % Open a window to choose a file to load. Plots it's data
            % on the GUI and display it's scan parameters.
            
            % load a struct from mat file
            [file, path, ~] = uigetfile('*.mat', 'Load Image', obj.saveFileData.loadPath);
            
            if ~isequal(file,0) && ~isequal(path,0)
                obj.LoadAndUpdateGUI(path, file, handles);
            end
        end
        
        function OldtoNewVersionConverter(obj, handles) %#ok<INUSD>
            % checks whether the loaded lastScanedData struct is of an old file form.
            % If it does - convert it to the new form
            
            % Is the struct of the old form?
            if isfield(obj.lastScanedData, 'spX')
                axis = ['x','y','z'];
                for i = 1: length(axis)
                    % Convert to the new form
                    eval(sprintf('obj.lastScanedData = setfield(obj.lastScanedData, ''minV%s'', obj.lastScanedData.sp%s.sp%sMin);', axis(i), upper(axis(i)), axis(i)));
                    eval(sprintf('obj.lastScanedData = setfield(obj.lastScanedData, ''maxV%s'', obj.lastScanedData.sp%s.sp%sMax);', axis(i), upper(axis(i)), axis(i)));
                    eval(sprintf('obj.lastScanedData = setfield(obj.lastScanedData, ''NV%s'', obj.lastScanedData.sp%s.sp%sNum);', axis(i), upper(axis(i)), axis(i)));
                    eval(sprintf('obj.lastScanedData = setfield(obj.lastScanedData, ''bFixV%s'', obj.lastScanedData.sp%s.sp%sFix);', axis(i), upper(axis(i)), axis(i)));
                    eval(sprintf('obj.lastScanedData = setfield(obj.lastScanedData, ''FixV%s'', obj.lastScanedData.sp%s.sp%sPos);', axis(i), upper(axis(i)), axis(i)));
                    
                    % delete the old forms
                    eval(sprintf('obj.lastScanedData = rmfield(obj.lastScanedData,''sp%s'');', upper(axis(i))));
                end
                
                % same for the time
                obj.lastScanedData = setfield(obj.lastScanedData, 'FixDT', obj.lastScanedData.spT.sptPos);
                obj.lastScanedData = rmfield(obj.lastScanedData,'spT');
            end
        end
        
        function OK = LoadAndUpdateGUI(obj, path, file, handles)
            % path - (string) the path of the file tha was chosen to load.
            % file - (string) the name of the file that was chosen to load.
            % a helper function for 'LoadWindow' function.
            % load the chosen data and updates the GUI.
            OK = 0;
            obj.saveFileData.loadPath = path;
            loadedData = load([path file]);
            % In case of older saved files or change of the name of the lastScanedData
            % this code will load any struct name that was saved.
            structName = fieldnames(loadedData);
            
            eval(['obj.lastScanedData = loadedData.' structName{1} ';']);
            obj.OldtoNewVersionConverter(handles);
            
            % Update file name
            set(handles.strLoadedFile, 'String', file);
            %%%%%%%% Added so that this program will not try to read wrong
            %%%%%%%% types . Can solve by creating a saving class
            %%%
            if sum(isfield(eval(['loadedData.' structName{1}]),{'xData','data'}) ==0)
                return;
            end
            %%%
            % Update Notes
            try
                set(handles.LoadedNotes,'String', obj.lastScanedData.Notes);
            catch
                % For old saved version
                set(handles.LoadedNotes,'String', obj.lastScanedData.notes);
            end
            
            % Update info
            switch obj.lastScanedData.dimentions
                case 1
                    axisStr = lower(obj.lastScanedData.axisStr);
                    fixedAxisStr = setdiff('xyz', axisStr);
                    info = sprintf('%s scan\n%s From: %.3f To: %.3f #Points: %d\n%s Position: %.3f\n%s Position: %.3f\nLaser Power: %s%', ...
                        upper(axisStr), ...
                        upper(axisStr), eval(sprintf('obj.lastScanedData.minV%s', axisStr)), eval(sprintf('obj.lastScanedData.maxV%s', axisStr)), eval(sprintf('obj.lastScanedData.NV%s', axisStr)), ...
                        upper(fixedAxisStr(1)), eval(sprintf('obj.lastScanedData.FixV%s', fixedAxisStr(1))), ...
                        upper(fixedAxisStr(2)), eval(sprintf('obj.lastScanedData.FixV%s', fixedAxisStr(2))), ...
                        obj.lastScanedData.laserPower);
                case 2
                    axisStr = lower(obj.lastScanedData.axisStr);
                    fixedAxisStr = setdiff('xyz', axisStr);
                    info = sprintf('%s scan\n%s From: %.3f To: %.3f #Points: %d\n%s From: %.3f To: %.3f #Points: %d\n%s Position: %.3f\nLaser Power: %s%', ...
                        upper(axisStr), ...
                        upper(axisStr(1)), eval(sprintf('obj.lastScanedData.minV%s', axisStr(1))), eval(sprintf('obj.lastScanedData.maxV%s', axisStr(1))), eval(sprintf('obj.lastScanedData.NV%s', axisStr(1))), ...
                        upper(axisStr(2)), eval(sprintf('obj.lastScanedData.minV%s', axisStr(2))), eval(sprintf('obj.lastScanedData.maxV%s', axisStr(2))), eval(sprintf('obj.lastScanedData.NV%s', axisStr(2))), ...
                        upper(fixedAxisStr), eval(sprintf('obj.lastScanedData.FixV%s', fixedAxisStr)), ...
                        obj.lastScanedData.laserPower);
            end
            
            set(handles.strLoadedFileInfo, 'String', info);
            
            % Reset the coursor: marker zoom and location
            set(handles.bCursorMarker, 'Value', 0);
            set(handles.bZoom, 'Value', 0);
            set(handles.bCursorLocation, 'Value', 0);
            
            % Check which axis mode was saved - default Normal
            try
                mode = textscan(obj.lastScanedData.axisMode, '%s', 'Delimiter', ' ');
                strAxisMode = mode{1}{4};
                switch strAxisMode
                    case 'normal'
                        strAxisMode = 1;
                    case 'equal'
                        strAxisMode = 2;
                    case 'square'
                        strAxisMode = 3;
                    otherwise
                        strAxisMode = 1;
                end
            catch
                % the default is normal
                strAxisMode = 1;
            end
            
            % Update the axis mode on the gui
            set(handles.AxisDisplay, 'Value', strAxisMode);
            try
                % newFile version
                % Update the loaded colormap name to the gui
                set(handles.Colormap, 'Value', obj.lastScanedData.Colormap);
                set(handles.CAxisMin, 'String', num2str(obj.lastScanedData.caxisMin));
                set(handles.CAxisMax, 'String', num2str(obj.lastScanedData.caxisMax));
            catch
                % In the old file version the colors didnt save
            end
            % plot the graph
            obj.PlotAndSave(handles, handles.axes1, false);
            OK = 1;
        end
        
        function DeleteImg(obj, handles)
            % Deletes the current loaded file
            
            filename = get(handles.strLoadedFile, 'String');
            choice = questdlg(['Do you want to delete ' filename '?'], 'Delete file?',...
                'Yes', 'No', 'No');
            % Handle response
            switch choice
                case 'Yes'
                    [~, name, ext] = fileparts(filename);
                    [prevFile, nextFile] = obj.FindPrevNextImgByDate(obj.saveFileData.loadPath, [name ext]);
                    delete([obj.saveFileData.loadPath name '.mat']);
                    delete([obj.saveFileData.loadPath name '.jpg']);
                    % If the deleted file is the last one on the list -
                    % then take the previous file. else take the nextFile
                    if isempty(nextFile) || strcmp([name ext], nextFile)
                        obj.LoadAndUpdateGUI(obj.saveFileData.loadPath, prevFile, handles);
                    else
                        obj.LoadAndUpdateGUI(obj.saveFileData.loadPath, nextFile, handles);
                    end
            end
        end
        
        function LoadNextOrPrev(obj, what, handles)
            % Loades the next .mat file or the previous (according to the
            % selection).
            % The files are ordered by last modification date! (not
            % creation date).
            file = get(handles.strLoadedFile, 'String');
            [prevFile, nextFile] = obj.FindPrevNextImgByDate(obj.saveFileData.loadPath, file);
            switch what
                case 'Next'
                    if strcmp(nextFile, file) % first / last file
                        disp('Last file reached');
                        return
                    else
                        file = nextFile;
                    end
                case 'Previous'
                    if strcmp(prevFile, file) % first / last file
                        disp('First file reached');
                        return
                    else
                        file = prevFile;
                    end
                otherwise
                    error('Unknown ''what'' command %s',what)
            end
            OK = obj.LoadAndUpdateGUI(obj.saveFileData.loadPath, file, handles);
            if ~OK % in case the file loaded is not a an image
                LoadNextOrPrev(obj, what, handles)
            else
                display(['Image: ' file]);
            end
        end
        
        function [prevFile, nextFile] = FindPrevNextImgByDate(obj, path, file) %#ok<INUSL>
            % Returns the names of the previous or the next file according
            % to the loaded .mat file (the input path and file name).
            % param path (String) - path of the current loaded file.
            %       file (String) - current loaded file name with the file format.
            % [prevFile, nextFile] (strings) of the previous and next file,
            % without the file format.
            
            % create a list of all .mat files sorted by creation date
            filesInFolder = dir([path '*.mat']);
            sortedBydate = [filesInFolder(:).datenum].';
            [~,I] = sort(sortedBydate);
            namesOfSortedFiles = {filesInFolder(I).name};
            
            % find the location of the opened file in the list
            [truefalse, inx] = ismember(file, namesOfSortedFiles);
            
            % set next and previous file names - and consider the start and end of
            % files list
            if truefalse
                if inx == length(namesOfSortedFiles)
                    nextFile = file;
                else
                    nextFile = namesOfSortedFiles{inx+1};
                end
                
                if inx == 1
                    prevFile = file;
                else
                    prevFile = namesOfSortedFiles{inx-1};
                end
                
            else
                error('There is no such file %s', file);
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%     ImageSetCursor     %%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function FixLocations(obj, handles)
            % Moves the stage to the position set on the 'Fix' position area
            % on the GUI
            
            x = str2double(get(handles.FixX,'String'));
            y = str2double(get(handles.FixY,'String'));
            z = str2double(get(handles.FixZ,'String'));
            % Is needed???????
            if (~obj.stage.PointIsInRange('x', x)); [negLimit, posLimit] = obj.stage.ReturnLimits('x'); fprintf('Fixed x is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); return; end
            if (~obj.stage.PointIsInRange('y', y)); [negLimit, posLimit] = obj.stage.ReturnLimits('y'); fprintf('Fixed y is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); return; end
            if (~obj.stage.PointIsInRange('z', z)); [negLimit, posLimit] = obj.stage.ReturnLimits('z'); fprintf('Fixed z is out of bounds, limit is between %.4f and %.4f.\n', negLimit, posLimit); return; end
            obj.stage.Move(['x' 'y' 'z'], [x y z]);
            % Update the gui with the new location of the stage
            obj.PiezoQueries(handles);
        end
        
        function SetLocationFromCursor(obj, ~, ~, handles)
            if isempty(obj.lastScanedData) || ~isfield(obj.lastScanedData, 'dimentions')
                fprintf('Image is empty?\n');
                return
            end
            
            if get(handles.bCursorLocation, 'Value')
                pos = get(handles.axes1, 'CurrentPoint');
                pos = pos(1, 1:obj.lastScanedData.dimentions);
                
                % Now move to the correspondig location
                obj.stage.Move(obj.lastScanedData.axisStr, pos);
                obj.UpdatePositionInGUI(obj.lastScanedData.axisStr, pos, handles);
                obj.DrawCrosshairs(handles);
            end
        end
        
        function SetCursor(obj, handles)
            % Manage the cursor according to what was chosen: Marker, Zoom
            % or Location
            
            % Set which are the current axes
            axes(handles.axes1);
            if (get(handles.bCursorMarker, 'Value') == 1)
                % display cursor with specific data tip
                obj.ClearCursorData(handles);
                datacursormode on;
                cursorObj = datacursormode(gcf);
                set(cursorObj,'UpdateFcn', @obj.CursorMarkerDisplay);
                
            elseif (get(handles.bZoom, 'Value') == 1)
                % Creates a rectangle on the selected area, and updates the
                % GUI's min and max values accordingly
                obj.ClearCursorData(handles);
                set(handles.bCursorMarker, 'Enable', 'Off');
                set(handles.bCursorLocation, 'Enable', 'Off');
                obj.UpdataDataByZoom(handles);
                set(handles.bCursorMarker, 'Enable', 'On');
                set(handles.bCursorLocation, 'Enable', 'On');
                set(handles.bZoom, 'Value',0);
                obj.ClearCursorData(handles);
                
            elseif (get(handles.bCursorLocation, 'Value') == 1)
                % Draws horizontal and vertical line on the selected
                % location, and moves the stage to this location.
                obj.ClearCursorData(handles);
                imageHandle = imhandles(handles.axes1);
                if isempty(imhandles(handles.axes1))
                    imageHandle = gca;
                end
                set(imageHandle, 'ButtonDownFcn', {@obj.SetLocationFromCursor, handles});
                
            else
                % Stop zoom if active
                global GETRECT_H1 %#ok<TLEV>
                if ~isempty(GETRECT_H1) && ishghandle(GETRECT_H1)
                    set(GETRECT_H1, 'UserData', 'Completed');
                end
                obj.ClearCursorData(handles);
                set(gcf, 'Pointer', 'arrow');
            end
        end
        
        function ClearCursorData(obj, handles) %#ok<INUSL>
            % Clear the cursor data between passing from one cursor type to
            % another. To avoid collision.
            delete(findall(gcf,'Type','hggroup')); % Delete data tip
            datacursormode off; % Disables cursor mode
            
            % Disable button press
            imageHandle = imhandles(handles.axes1);
            set(imageHandle, 'ButtonDownFcn', '');
            
        end
        
        function txt = CursorMarkerDisplay(obj, ~, event_obj)
            % Displays the location of the cursor on the plot and the kcps
            % (the color level from the colormap)
            if isempty(obj.lastScanedData) || ~isfield(obj.lastScanedData, 'dimentions')
                fprintf('Image is empty?\n');
                return
            end
            
            % Customizes text of data tips
            pos = get(event_obj, 'Position');
            
            if obj.lastScanedData.dimentions == 1
                txt = sprintf('%s = %.3f\nkcps = %.1f', obj.lastScanedData.axisStr, pos(1), pos(2));
            else
                axesHandle = get(event_obj, 'Target');
                dataIndex = get(event_obj, 'DataIndex');
                data = get(axesHandle, 'CData');
                txt = sprintf('(%s,%s) = (%.3f, %.3f)\nkcps = %.1f', ...
                    obj.lastScanedData.axisStr(1), obj.lastScanedData.axisStr(2),...
                    pos(1), pos(2), data(dataIndex));
            end
        end
        
        function UpdataDataByZoom(obj, handles)
            % Draw the rectangle on the select area on the plot and update
            % the GUI with the max and min values
            if isempty(obj.lastScanedData) || ~isfield(obj.lastScanedData, 'dimentions')
                fprintf('Image is empty?\n');
                return
            end
            
            rect = getrect(handles.axes1);
            if (rect(3) == 0) || (rect(4) == 0) % Width or Height are 0
                return
            end
            
            for i = 1:obj.lastScanedData.dimentions
                minimum = rect(i); %#ok<NASGU>
                maximum = rect(i)+rect(i+2); %#ok<NASGU>
                
                % update the gui's Scan Parameters with the selected coordinates
                eval(sprintf('set(handles.From%s,''String'', num2str(minimum, %s));', upper(obj.lastScanedData.axisStr(i)), '''%.3f'''));
                eval(sprintf('set(handles.To%s,''String'', num2str(maximum, %s));', upper(obj.lastScanedData.axisStr(i)), '''%.3f'''));
                eval(sprintf('set(handles.From%s,''UserData'', num2str(minimum, %s));', upper(obj.lastScanedData.axisStr(i)), '''%.3f'''));
                eval(sprintf('set(handles.To%s,''UserData'', num2str(maximum, %s));', upper(obj.lastScanedData.axisStr(i)), '''%.3f'''));
                
            end
            obj.DrawRectangle(rect, handles)
        end
        
        function DrawRectangle(obj, pos, handles) %#ok<INUSD>
            % Draw rectangle
            if isfield(obj.drawSquare, 'rectangleHandle') && ishandle(obj.drawSquare.rectangleHandle)
                set(obj.drawSquare.rectangleHandle, 'Position', pos);
            else
                obj.drawSquare.rectangleHandle = rectangle('Position', pos, 'EdgeColor', 'g', 'LineWidth', 1, 'LineStyle', '-.', 'HitTest', 'Off');
            end
        end
        
        function DrawCrosshairs(obj, handles)
            % Draw the cross on the plot on the selected position
            if ~isstruct(obj.lastScanedData)
                return
            end
            
            dimension = length(obj.lastScanedData.axisStr);
            
            pos = zeros(1,2);
            for i=1:length(obj.lastScanedData.axisStr)
                pos(i) = str2double(eval(sprintf('get(handles.Fix%s,''String'');', upper(obj.lastScanedData.axisStr(i)))));
            end
            
            % Get the current limits of the axes1
            xLimits = get(handles.axes1,'XLim');
            yLimits = get(handles.axes1,'YLim');
            
            % If 1D, arbitrary set the position in the middle
            if dimension == 1
                pos(2) = (yLimits(2) + yLimits(1))/2;
            end
            
            % Binary encode the location relative to the axes, the image is
            % at the 0 square:
            %  6  |  4  |  12
            %----------------
            %  2  |  0  |  8
            %----------------
            %  3  |  1  |  9
            % Decides on which area the position is located
            quadrat =  1*(pos(2) < yLimits(1)) + 2*(pos(1) < xLimits(1)) + 4*(yLimits(2) < pos(2)) + 8*(xLimits(2) < pos(1));
            
            % Delete previous and recreate correct handles
            hold on % Keep image while creating crosshair/arrow
            if quadrat == 0 % Inside
                if isfield(obj.drawSquare, 'arrowHandle') && ishandle(obj.drawSquare.arrowHandle)
                    delete(obj.drawSquare.arrowHandle);
                end
                if ~isfield(obj.drawSquare, 'xLineHandle') || ~ishandle(obj.drawSquare.xLineHandle)
                    obj.drawSquare.xLineHandle = line([0 0], [0 0], 'Color', 'b', 'HitTest', 'Off');
                end
                if ~isfield(obj.drawSquare, 'yLineHandle') || ~ishandle(obj.drawSquare.yLineHandle)
                    obj.drawSquare.yLineHandle = line([0 0], [0 0], 'Color', 'b', 'HitTest', 'Off');
                end
            else % Outside
                if isfield(obj.drawSquare, 'xLineHandle') && ishandle(obj.drawSquare.xLineHandle)
                    delete(obj.drawSquare.xLineHandle);
                end
                if isfield(obj.drawSquare,'yLineHandle') && ishandle(obj.drawSquare.yLineHandle)
                    delete(obj.drawSquare.yLineHandle);
                end
                if ~isfield(obj.drawSquare, 'arrowHandle') || ~ishandle(obj.drawSquare.arrowHandle)
                    obj.drawSquare.arrowHandle = quiver(0, 0, 0, 0, 0, 'Color', 'b', 'LineWidth', 1, 'MaxHeadSize', 10, 'HitTest', 'Off');
                end
            end
            hold off % Allow picture to change when needed
            
            % Draw what needs to be drawn
            switch quadrat
                case 0 % Inside
                    set(obj.drawSquare.xLineHandle, 'XData', [xLimits(1) xLimits(2)]);
                    set(obj.drawSquare.xLineHandle, 'YData', [pos(2) pos(2)]);
                    set(obj.drawSquare.yLineHandle, 'XData', [pos(1) pos(1)]);
                    set(obj.drawSquare.yLineHandle, 'YData', [yLimits(1) yLimits(2)]);
                    
                case 1 % Below
                    set(obj.drawSquare.arrowHandle, 'XData', pos(1));
                    set(obj.drawSquare.arrowHandle, 'YData', yLimits(1)+(yLimits(2)-yLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'UData', 0);
                    set(obj.drawSquare.arrowHandle, 'VData', (yLimits(1)-yLimits(2))/10);
                    
                case 2 % Left
                    set(obj.drawSquare.arrowHandle, 'XData', xLimits(1)+(xLimits(2)-xLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'YData', pos(2));
                    set(obj.drawSquare.arrowHandle, 'UData', (xLimits(1)-xLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'VData', 0);
                    
                case 3 % Below & Left
                    set(obj.drawSquare.arrowHandle, 'XData', xLimits(1)+(xLimits(2)-xLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'YData', yLimits(1)+(yLimits(2)-yLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'UData', (xLimits(1)-xLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'VData', (yLimits(1)-yLimits(2))/10);
                    
                case 4 % Above
                    set(obj.drawSquare.arrowHandle, 'XData', pos(1));
                    set(obj.drawSquare.arrowHandle, 'YData', yLimits(2)+(yLimits(1)-yLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'UData', 0);
                    set(obj.drawSquare.arrowHandle, 'VData', (yLimits(2)-yLimits(1))/10);
                    
                case 6 % Left & Above
                    set(obj.drawSquare.arrowHandle, 'XData', xLimits(1)+(xLimits(2)-xLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'YData', yLimits(2)+(yLimits(1)-yLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'UData', (xLimits(1)-xLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'VData', (yLimits(2)-yLimits(1))/10);
                    
                case 8 % Right
                    set(obj.drawSquare.arrowHandle, 'XData', xLimits(2)+(xLimits(1)-xLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'YData', pos(2));
                    set(obj.drawSquare.arrowHandle, 'UData', (xLimits(2)-xLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'VData', 0);
                    
                case 9 % Right & Below
                    set(obj.drawSquare.arrowHandle, 'XData', xLimits(2)+(xLimits(1)-xLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'YData', yLimits(1)+(yLimits(2)-yLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'UData', (xLimits(2)-xLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'VData', (yLimits(1)-yLimits(2   ))/10);
                    
                case 12 % Right & Above
                    set(obj.drawSquare.arrowHandle, 'XData', xLimits(2)+(xLimits(1)-xLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'YData', yLimits(2)+(yLimits(1)-yLimits(2))/10);
                    set(obj.drawSquare.arrowHandle, 'UData', (xLimits(2)-xLimits(1))/10);
                    set(obj.drawSquare.arrowHandle, 'VData', (yLimits(2)-yLimits(1))/10);
            end
            
            % If 1D, don't draw horizontal line
            if dimension == 1 && isfield(obj.drawSquare,'xLineHandle') && ishandle(obj.drawSquare.xLineHandle)
                delete(obj.drawSquare.xLineHandle);
            end
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%     Track     %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function Track(obj, handles)
            
            Tracker = ClassTracker.GetInstance();
            Tracker.NewTrack
            
            obj.PiezoQueries(handles);
        end
        
        function PlotTrack(obj, handles) %#ok<INUSD>
            
            file = 'AfterTrackingPositions.txt';
            path = 'Data/Tracking/';
            
            
            strFromDate = datestr(now-1,'dd-mmm-yyyy_HH:MM:SS');
            strFromDate = inputdlg('From Date','Plot Tracking Positions',1,{strFromDate});
            
            strToDate = datestr(now,'dd-mmm-yyyy_HH:MM:SS');
            strToDate = inputdlg('From Date','Plot Tracking Positions',1,{strToDate});
            
            fid = fopen([path file]);
            
            C = textscan(fid,'%s%f%f%f%f%f%f%f');
            Dates = C{1};
            rawX = C{2};
            rawY = C{3};
            rawZ = C{4};
            rawCounts = C{5};
            rawS1 = C{6};
            rawS2 = C{7};
            rawS3 = C{8};
            fclose(fid);
            
            numDates = datenum(Dates);
            numFromDate = datenum(strFromDate);
            numToDate = datenum(strToDate);
            
            I = find(numDates>numFromDate);
            iF = I(1);
            I = find(numDates<numToDate);
            iT = I(end);
            
            I = iF:iT;
            num = numDates(iF:iT);
            numFrom = num(1);
            numTo = num(end);
            num = num - num(1);
            
            X = rawX(iF:iT);
            Y = rawY(iF:iT);
            Z = rawZ(iF:iT);
            Counts = rawCounts(iF:iT);
            S1 = rawS1(iF:iT);
            S2 = rawS2(iF:iT);
            S3 = rawS3(iF:iT);
            
            Time = num; %in days
            Time = 24*Time; %In hours
            
            nX = X - X(1);
            nY = Y - Y(1);
            nZ = Z - Z(1);
            
            nS1 = S1 - S1(1);
            nS2 = S2 - S2(1);
            nS3 = S3 - S3(1);
            
            figure(1942);
            subplot(3,1,1);
            plot(Time,Counts);
            title(sprintf('Tracking Positions. From Date : %s To Date : %s',datestr(numFrom),datestr(numTo)));
            legend('Counts');
            subplot(6,1,3);
            plot(Time,S1,'r');
            legend('Intensity');
            subplot(6,1,4);
            plot(Time,S2,'g',Time,S3,'b');
            legend('Temp 1','Temp 2');
            subplot(3,1,3);
            plot(Time,nX,'r',Time,nY,'g',Time,nZ,'b');
            legend('x','y','z');
            xlabel('hours');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%   Colormap    %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function Colormap(obj, handles, currentAxisHandle)
            % Sets the colormap and it's max and min values
            % @param currentAxisHandle(handle) - the handle of the figure
            % we want to set the colotrmap. Sometimes its on the gui and
            % sometimes on a separate figure.
            
            % Set the colors
            obj.SetColormap(currentAxisHandle, handles);
            
            % If the 'Auto' display mode is marked
            if get(handles.CAxisAuto, 'Value')
                image = getimage(currentAxisHandle);
                maxValue = max(max(image));
                if maxValue > 0
                    minValue = min(min(image(image ~= 0)));
                    if (minValue ~= maxValue)
                        caxis(currentAxisHandle, [minValue maxValue]);
                    else % Min and max are the same, there is only one value that is not 0.
                        caxis(currentAxisHandle, 'auto');
                    end
                else % Max value is 0, all values are 0.
                    caxis(currentAxisHandle, 'auto');
                end
                
                % update the GUI's min and max values with the auto values
                minColor = sprintf('%.2f', min(caxis));
                maxColor = sprintf('%.2f', max(caxis));
                set(handles.CAxisMin, 'String', minColor);
                set(handles.CAxisMax, 'String', maxColor);
                set(handles.CAxisMin, 'UserData', num2str(minColor));
                set(handles.CAxisMax, 'UserData', num2str(maxColor));
            else
                % Update the plot with the specified min/max values from the GUI
                caxisMin = get(handles.CAxisMin, 'String');
                caxisMax = get(handles.CAxisMax, 'String');
                set(handles.CAxisMin, 'UserData', num2str(caxisMin));
                set(handles.CAxisMax, 'UserData', num2str(caxisMax));
                caxis(currentAxisHandle, [str2double(caxisMin) str2double(caxisMax)]);
            end
        end
        
        function SetColormap(obj, currentAxisHandle, handles)
            % Set the colormap of the axis on the GUI according to the
            % selection
            
            % get the list of all the options to colormap from the gui
            list = get(handles.Colormap, 'String');
            % locate the chosen option
            val = get(handles.Colormap, 'Value');
            % find the color name from the list
            if iscell(list)
                color = list{val};
            else
                color = list;
            end
            % update the colormap of the GUI
            colormap(currentAxisHandle, color);
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%   Laser    %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function LaserEnable(obj, handles)
            % Enables or disables the laser according to the value in handles.bLaser.
            PBFunctionPool('PBON', 8*get(handles.bLaser, 'Value')); todo = 'not turn off all others outputs';
            obj.SetLaserPower(handles);
        end
        
        function SetLaserPower(obj, handles) %#ok<INUSL>
            % Sets the laser power to the power percent in handles.LaserPower.
            % Percent should be 0-1 and the function will set the AOM
            % voltage accordingly.
            
            percent = get(handles.LaserPower, 'Value');
            DAQmx_Val_Volts = daq.ni.NIDAQmx.DAQmx_Val_Volts;
            DAQmx_Val_GroupByScanNumber = daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber;
            
            [ status, ~, task ] = DAQmxCreateTask([]);
            DAQmxErr(status);
            
            status = DAQmxCreateAOVoltageChan(task, 'dev1/ao0', 0, 1, DAQmx_Val_Volts);
            DAQmxErr(status);
            
            status = DAQmxStartTask(task);
            DAQmxErr(status);
            
            voltage = percent*1;
            status = DAQmxWriteAnalogF64(task, 1, 1, 10, DAQmx_Val_GroupByScanNumber, voltage, 0);
            DAQmxErr(status);
            
            status = DAQmxStopTask(task);
            DAQmxErr(status);
            
            status = DAQmxClearTask(task);
            DAQmxErr(status);
        end
        
        function UpdatetLaserGUI(obj, handles) %#ok<INUSL>
            % Sets the laser power to the power percent given.
            % Percent should be between 0-1 and the function will set the AOM
            % voltage accordingly.
            DAQmx_Val_RSE = daq.ni.NIDAQmx.DAQmx_Val_RSE;
            DAQmx_Val_Volts = daq.ni.NIDAQmx.DAQmx_Val_Volts;
            DAQmx_Val_GroupByScanNumber = daq.ni.NIDAQmx.DAQmx_Val_GroupByScanNumber;
            
            [ status, ~, task ] = DAQmxCreateTask([]);
            DAQmxErr(status);
            
            status = DAQmxCreateAIVoltageChan(task, 'dev1/ai0', '', DAQmx_Val_RSE, 0, 1, DAQmx_Val_Volts, '');
            DAQmxErr(status);
            
            status = DAQmxStartTask(task);
            DAQmxErr(status);
            
            readArray = zeros(1, 1);
            [status, voltage]= DAQmxReadAnalogF64(task, 1, 1, DAQmx_Val_GroupByScanNumber, readArray, 1, int32(0));
            DAQmxErr(status);
            percent = voltage;
            
            status = DAQmxStopTask(task);
            DAQmxErr(status);
            
            status = DAQmxClearTask(task);
            DAQmxErr(status);
            
            if percent<0
                percent = 0;
            elseif percent>1
                percent = 1;
            end
            
            set(handles.LaserPowerPercentage, 'String', sprintf('%d%%', round(100*percent)));
            set(handles.LaserPowerPercentage, 'UserData', sprintf('%d%%', round(100*percent)));
            set(handles.LaserPower, 'Value', percent);
            set(handles.LaserPower, 'UserData', percent);
            % Need to get bLaser from PB once it's a class!
            % This function needs to go away once we have control
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%   Joystick    %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function JoystickControl(obj, handles)
            % Enables or disable the joystick according to the GUI settings.
            % While the joystick is on, updates the location every ~200ms.
            
            obj.stage.JoystickControl(get(handles.bJoystick, 'Value'));
            obj.PiezoQueries(handles);
            while get(handles.bJoystick, 'Value')
                obj.JoystickButtonAction(3, 1);
                obj.PiezoQueries(handles); drawnow();
            end
        end
        
        function JoystickButtonAction(obj, nPoints, tSeperation)
            % Checks if the joystick buttons are pressed and executes commands.
            % 'nPoints' and 'tSeperation' are to avoid glitches.
            % 'nPoints' is the number of points to check before making a decision.
            % 'tSeperation' is the minimum time in seconds between buttons are
            % checked.
            persistent binaryButtonState index clicked timer;
            
            if ~isequal(size(binaryButtonState), [1 nPoints])
                binaryButtonState = zeros(1, nPoints);
                index = 0;
                clicked = 0;
                timer = 0;
            end
            
            if clicked %% Wait after previous button press & initialize parameters
                if (toc(timer) < tSeperation)
                    return
                else
                    clicked = 0;
                    obj.binaryButtonState = zeros(1, nPoints);
                end
            end
            
            binaryButtonState(index+1) = obj.stage.ReturnJoystickButtonState();
            index = mod(index+1, nPoints);
            decision = mode(binaryButtonState);
            
            if (decision ~= 0)
                timer = tic;
                clicked = 1;
            end
            
            switch decision
                case 0
                case 1
                    fprintf('Button 1 is pressed\n');
                case 2
                    fprintf('Button 2 is pressed\n');
                case 3
                    fprintf('Buttons 1 & 2 are pressed\n');
                case 4
                    fprintf('Button 3 is pressed\n');
                case 5
                    fprintf('Buttons 1 & 3 are pressed\n');
                case 6
                    fprintf('Buttons 2 & 3 are pressed\n');
                case 7
                    fprintf('All buttons pressed\n');
                otherwise
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%   Additional    %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function DisplayInFig(obj, handles)
            % Displays the plot that on the GUI on a seperate figure
            % So it can be edited as needed
            fig = figure;
            axes_handle = gca;
            set(fig, 'CurrentAxes', axes_handle);
            obj.PlotAndSave(handles, axes_handle, false);
        end
        
        function SetAxisDisplay(obj, handles)
            % Display the plot according to the selected mode: normal,
            % equal or tight
            
            % get the list of all the options to colormap from the gui
            list = get(handles.AxisDisplay, 'String');
            % locate the chosen option
            val = get(handles.AxisDisplay, 'Value');
            % Update the axis mode
            obj.lastScanedData.axisMode = ['axis xy tight ' list{val}];
            axis manual
            % update the axis mode of the GUI
            obj.PlotAndSave(handles, handles.axes1, false);
        end
        
        function [amlitude, SigmaWidth] = FitGaussian(obj, handles) %#ok<INUSD>
            
            todo = 'Make it work'
            todo = 'From where does gIMG is comming from??'
            
            Fix_Vx = 1-obj.gIMG.bFixVx;
            Fix_Vy = 1-obj.gIMG.bFixVy;
            
            obj.gIMG.STED
            DVx = (obj.gIMG.STED.VX(end)-obj.gIMG.STED.VX(1))*Fix_Vx;
            DVy = (obj.gIMG.STED.VY(end) -obj.gIMG.STED.VY(1))*Fix_Vy;
            
            DVoltage = sqrt(DVx^2+DVy^2);
            
            Inputydata = obj.gIMG.STED.I;
            Inputxdata = (1:length(obj.gIMG.STED.I));
            
            Total_Length = length(Inputxdata);
            
            conversion_in_nm = DVoltage/Total_Length*10^3;
            
            
            min = 1;
            max = length(obj.gIMG.STED.I);
            name = 20;
            measurement_length = 270*10^-9;
            
            Transposedxdata = Inputxdata(round(min):1:round(max));
            Transposedydata = Inputydata(round(min):1:round(max));
            
            xdata = Transposedxdata';
            if size(Transposedydata,1) == 1
                ydata = Transposedydata';
            else
                ydata = Transposedydata;
            end
            
            Length = length(xdata);
            
            sortydata = sort(ydata);
            
            d0 = mean(sortydata(1:round(Length/10)));
            
            a0 = sortydata(end);
            
            b0 = xdata(ydata == a0);
            
            f1 = fittype('a*exp(-(x-b)^2/c)+d');
            xdata,ydata
            fit1 = fit(xdata,ydata,f1,'StartPoint',[a0 b0 5 d0]);
            
            FWHM = 2*sqrt(fit1.c*log(2));
            FWHM_in_nm = FWHM*conversion_in_nm;
            
            FWHM_conf_matrix = confint(fit1,0.95);
            FWHM_conf1 = 2*sqrt(FWHM_conf_matrix(1,3)*log(2));
            FWHM_conf2 = 2*sqrt(FWHM_conf_matrix(2,3)*log(2));
            FWHM_in_nm_conf1 = FWHM_conf1*conversion_in_nm - FWHM_in_nm;
            FWHM_in_nm_conf2 = FWHM_conf2*conversion_in_nm - FWHM_in_nm;
            
            number_of_thicks = 5;
            range = min:(max-min)/number_of_thicks:max;
            range_in_nm = conversion_in_nm*min:conversion_in_nm*(max-min)/number_of_thicks:conversion_in_nm*max;
            
            two_STDW = 2*sqrt((obj.gIMG.STED.X(1).IMG + obj.gIMG.STED.X(2).IMG)*(measurement_length));
            
            figure(1);
            subplot(111);
            plot(xdata, ydata,'o--','Color','blue')
            hold on
            plot(fit1,'r--')
            text(fit1.b+FWHM/2,(fit1.a+fit1.d)/2,strcat('\leftarrow',num2str(FWHM_in_nm),num2str(FWHM_in_nm_conf1),'+',num2str(FWHM_in_nm_conf2),'nm'),'FontSize',14,'Color','red')
            text(fit1.b,fit1.a,strcat('max = ',num2str(fit1.a*10^3),'*10^{-3}'),'FontSize',14,'Color','red')
            set(gca,'XTick',range)
            set(gca,'XTickLabel',range_in_nm, 'FontSize',12)
            xlabel('x / [nm]', 'FontSize',14)
            ylabel('Fluorescence / [arb. unit]', 'FontSize',14)
            
            if length(obj.gIMG.STED.VX) ==1
                xdata = obj.gIMG.STED.VY';
            else
                xdata = obj.gIMG.STED.VX';
            end
            xdata = xdata - xdata(1);
            xdata = xdata *1000; %in nm
            xdata = xdata + 150;
            Length = length(xdata);
            sortydata = sort(ydata);
            d0 = mean(sortydata(1:round(Length/10)));
            a0 = sortydata(end);
            b0 = xdata(ydata == a0);
            f1 = fittype('a*exp(-(x-b)^2/c)+d');
            fit1 = fit(xdata,ydata,f1,'StartPoint',[a0 b0 5000 d0]);
            
            gFit = struct(...
                'fit1', fit1,...
                'FWHM_in_nm', FWHM_in_nm,...
                'xdata', xdata,...
                'ydata', ydata,...
                'edata', two_STDW);
            todo = 'return the Amlitude, sigma, C'
            
        end
        
        function StopMovement(obj, handles) %#ok<INUSD>
            % Sends the Halt command to the stage.
            obj.stage.Halt();
        end
        
        function [negHardLimit, posHardLimit] = GetStageLimits(obj, axis, handles, varargin)  %#ok<INUSL>
            % Return the hard limits of the given axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            [negHardLimit, posHardLimit] = obj.stage.ReturnHardLimits(axis, varargin{:});
        end
        
        function SetSoftLimits(obj, axis, softLimit, negOrPos, varargin)
            % Set the new soft limits- to the stage object
            % if negOrPos = 0 -> then softLimit = lower soft limit
            % if negOrPos = 1 -> then softLimit = higher soft limit
            % This is because each time this function is called only one of
            % the limits updates
            obj.stage.SetSoftLimits(axis, softLimit, negOrPos, varargin{:});
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%   Save Output    %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Saves last scaned parameters
        function SaveScanParameters(obj, varargin)
            % Saves the exact data that was send to scan as a struct. That
            % later is saved to a .mat file with the resulted plot
            
            % Save data and parameters before scan
            if nargin == 3
                obj.lastScanedData = varargin{1};
                handles = varargin{2};
                
                laserPower = get(handles.LaserPowerPercentage, 'String');
                color = get(handles.Colormap, 'Value');
                caxisMin = str2double(get(handles.CAxisMin, 'String'));
                caxisMax = str2double(get(handles.CAxisMax, 'String'));
                list = get(handles.AxisDisplay, 'String');
                val = get(handles.AxisDisplay, 'Value');
                axisMode = sprintf('axis xy tight %s', list{val});
                axis manual
                
                % The Struct's fields and values:
                obj.lastScanedData.data = 'd';
                obj.lastScanedData.xData = 0;
                obj.lastScanedData.yData = 0;
                obj.lastScanedData.laserPower = laserPower;
                obj.lastScanedData.Notes = '';
                obj.lastScanedData.dimentions = 0;
                obj.lastScanedData.curAxis = 0;
                obj.lastScanedData.axisStr = 0;
                obj.lastScanedData.axisMode = axisMode;
                obj.lastScanedData.Colormap = color;
                obj.lastScanedData.caxisMin = caxisMin;
                obj.lastScanedData.caxisMax = caxisMax;
                
            else
                % Save data with the resulted scaned data
                plotMatrixData = varargin{1};
                xdata = varargin{2};
                ydata = varargin{3};
                dim = varargin{4};
                curAxis = varargin{5};
                axisStr = varargin{6};
                handles = varargin{7};
                
                laserPower = get(handles.LaserPowerPercentage, 'String');
                color = get(handles.Colormap, 'Value');
                caxisMin = str2double(get(handles.CAxisMin, 'String'));
                caxisMax = str2double(get(handles.CAxisMax, 'String'));
                list = get(handles.AxisDisplay, 'String');
                val = get(handles.AxisDisplay, 'Value');
                axisMode = sprintf('axis xy tight %s', list{val});
                axis manual
                
                obj.lastScanedData.data = plotMatrixData;
                obj.lastScanedData.xData = xdata;
                obj.lastScanedData.yData = ydata;
                obj.lastScanedData.dimentions = dim;
                obj.lastScanedData.curAxis = curAxis;
                obj.lastScanedData.axisStr = axisStr;
                obj.lastScanedData.laserPower = laserPower;
                obj.lastScanedData.axisMode = axisMode;
                obj.lastScanedData.Colormap = color;
                obj.lastScanedData.caxisMin = caxisMin;
                obj.lastScanedData.caxisMax = caxisMax;
            end
        end
        
        function pos = getPos(obj, varargin)
            pos = obj.stage.Pos('xyz', varargin{:});
        end
        
        function success = EnableTiltAngle(obj, enable, varargin)
            success = obj.stage.EnableTiltCorrection(enable, varargin{:});
        end
        
        function success = SetTiltAngle(obj, valueX, valueY, varargin)
            success = obj.stage.SetTiltAngle(valueX, valueY, varargin{:});
        end
    end
end