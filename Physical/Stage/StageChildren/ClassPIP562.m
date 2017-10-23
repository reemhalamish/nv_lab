classdef (Sealed) ClassPIP562 < ClassPIMicos
    % Created by Yoav Romach, The Hebrew University, October, 2016
    % Used to control PI Micos P-562 stage.
    % libfunctionsview('PI') to view functions
    
    properties (Constant, Access = protected)
        controllerModel = 'E-727';
        validAxes = 'xyz';
        units = 'µm';
    end
    
    properties (Access = protected)
        ID
        posRangeLimit
        negRangeLimit
        posSoftRangeLimit
        negSoftRangeLimit
        defaultVel
        curPos
        curVel
        forceStop
        scanRunning
        macroNormalScanVector
        macroNormalScanAxis
        macroScanAxis
        macroIndex
        scanStruct
    end
    
    properties(Constant = true)
        NAME = 'Stage (Fine) - PI P562'
        
        NEEDED_FIELDS = {'niDaqChannel'}
        
        STEP_MINIMUM_SIZE = 0.0005
        STEP_DEFAULT_SIZE = 0.1
    end
    
    properties(Abstract = true, Constant = true)
    end
    
    methods (Static, Access = public) % Get instance constructor
        function obj = create(stageStruct)
            
            missingField = FactoryHelper.usualChecks(stageStruct, ClassPIP562.NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Trying to create the ClassPIP562 stage, encountered missing field - "%s". aborting',...
                    missingField);
            end
            
            niDaqChannel = stageStruct.niDaqChannel;
            removeObjIfExists(ClassPIP562.NAME);
            obj = ClassPIP562(niDaqChannel);       
        end
    end
    
    methods (Access = private) % Private Functions
        function obj = ClassPIP562(niDaqChannel)
            % Private default constructor.
            name = ClassPIP562.NAME;
            availAxis = ClassPIP562.validAxes;
            isScanable = true;
            obj = obj@ClassPIMicos(name, availAxis, isScanable);
            
            daq = getObjByName(NiDaq.NAME);
            daq.registerChannel(niDaqChannel, obj.name);
            
            obj.ID = -1;
            obj.posRangeLimit = [200 200 200]; % Units set to microns.
            obj.negRangeLimit = [0 0 0]; % Units set to microns.
            obj.posSoftRangeLimit = obj.posRangeLimit;
            obj.negSoftRangeLimit = obj.negRangeLimit;
            obj.defaultVel = 2000; % Default velocity is 2000 um/s.
            obj.curPos = [0 0 0];
            obj.curVel = [0 0 0];
            obj.forceStop = 0;
            obj.scanRunning = 0;
            obj.Connect();
            obj.Initialization();
            obj.scanStruct = struct([]);
        end
        
        function axis = SwitchXYAxis(obj, axis, type) %#ok<INUSL>
            switch type
                case 'szAxes'
                    axis = strrep(strrep(strrep(axis, '1', '9'), '2', '1'), '9', '2');
                case 'integer'
                    axis(axis==1) = 9;
                    axis(axis==2) = 1;
                    axis(axis==9) = 2;
            end
        end
    end
    
    methods (Access = protected) % Overwrite ClassPIMicos functions
        function Initialization(obj)
            % To turn on servo
            ChangeLoopMode(obj, 'Closed')
            
            % AutoZero?
            questionString = sprintf('PI P562 fine stage needs to be AutoZeroed whenever the load or the enviorment changes.\nFailure to AutoZero will mean that the stage will not be able to use its full range.\nNote that this will Move all axes!\nDo you want to AutoZero the stage?');
            referenceString = 'AutoZero';
            referenceCancelString = 'No';
            confirm = questdlg(questionString, 'AutoZero Confirmation', referenceString, referenceCancelString, referenceCancelString);
            switch confirm
                case referenceString
                    Refernce(obj, obj.validAxes)
                case referenceCancelString
                    % Do Nothing
                otherwise
                    % Do Nothing
            end
            Initialization@ClassPIMicos(obj)
        end
        
        function [szAxes, zerosVector] = ConvertAxis(obj, axis)
            % This function switches between the x & y axes for the stage
            % so that it will be a right handed system with the same
            % orienation as the other stages.
            %
            % Returns the corresponding szAxes string needed to
            % communicate with PI controllers that are connected to
            % multiple axes. Also returns a vector containging zeros with
            % the length of the axes.
            % 'axis' can be either a specific axis (x,y,z or 1 for x, 2 for y
            % and 3 for z) or any vectorial combination of them.
            [szAxes, zerosVector] = ConvertAxis@ClassPIMicos(obj, axis);
            szAxes = SwitchXYAxis(obj, szAxes, 'szAxes');
        end
        
        function CheckLimits(obj)
            % This function checks that the soft and hard limits matches
            % the stage.
            [szAxes, zerosVector] = ConvertAxis(obj, obj.validAxes);
            
            % Physical limit check
            [~, posPhysicalLimitDistance] = SendPICommand(obj, 'PI_qTMX', obj.ID, szAxes, zerosVector);
            [~, negPhysicalLimitDistance] = SendPICommand(obj, 'PI_qTMN', obj.ID, szAxes, zerosVector);
            for i=1:length(obj.validAxes)
                if ((negPhysicalLimitDistance(i) ~= obj.negRangeLimit(i)) || (posPhysicalLimitDistance(i) ~= obj.posRangeLimit(i)))
                    error('Physical limits for %s axis are incorrect!\nShould be: %d to %d.\nReal value: %d to %d.\nMaybe units are incorrect?',...
                        upper(obj.validAxes(i)), obj.negRangeLimit(i), obj.posRangeLimit(i), negPhysicalLimitDistance(i), posPhysicalLimitDistance(i))
                else
                    fprintf('%s axis - Physical limits are from %d %s to %d %s.\n', upper(obj.validAxes(i)), obj.negRangeLimit(i), obj.units, obj.posRangeLimit(i), obj.units);
                end
            end
        end
        
        function CheckRefernce(obj, axis)
            % Checks whether the given axis is referenced, and if not, asks
            % for confirmation to refernce it.
            refernced = IsRefernced(obj, axis);
            if ~all(refernced)
                questionString = sprintf('PI P562 fine stage is not zeroed.\nFailure to AutoZero will mean that the stage will not be able to use its full range.\nNote that this will Move all axes!\nDo you want to AutoZero the stage?');
                referenceString = sprintf('AutoZero');
                referenceCancelString = 'Cancel';
                confirm = questdlg(questionString, 'AutoZero Confirmation', referenceString, referenceCancelString, referenceString);
                switch confirm
                    case referenceString
                        Refernce(obj, obj.validAxes)
                    case referenceCancelString
                        % Do Nothing
                    otherwise
                        % Do Nothing
                end
            end
        end
        
        function refernced = IsRefernced(obj, axis)
            % Check AutoZero status for the given axis.
            % 'axis' can be either a specific axis (x,y,z or 1 for x, 2 for y
            % and 3 for z) or any vectorial combination of them.
            [szAxes, zerosVector] = ConvertAxis(obj, axis);
            [~, refernced] = SendPICommand(obj, 'PI_qATZ', obj.ID, szAxes, zerosVector);
        end
        
        function Refernce(obj, axis)
            % Does an AutoZero procedure on the given axis, it is
            % recommended to do the AutoZero on all axes at once.
            % 'axis' can be either a specific axis (x,y,z or 1 for x, 2 for y
            % and 3 for z) or any vectorial combination of them.
            [szAxes, zerosVector] = ConvertAxis(obj, axis);
            SendPICommand(obj, 'PI_ATZ', obj.ID, szAxes, zerosVector, zerosVector+1);
            
            % Check if ready & if AutoZero succeeded
            WaitFor(obj, 'ControllerReady')
            [~, autoZeroed] = SendPICommand(obj, 'PI_qATZ', obj.ID, szAxes, zerosVector);
            if ~all(autoZeroed)
                error('AutoZero failed for controller %s with ID %d: Reason unknown.', obj.controllerModel, obj.ID);
            end
            MovePrivate(obj, axis, 100*ones(size(axis))); % Go back to the center
            WaitFor(obj, 'onTarget', axis)
        end
        
        function PrepareScanInOneDimension(obj, scanAxisVector, nFlat, nOverRun, tPixel, scanAxis)
            % Prepares a one dimensional scan, writes the waveform and 
            % initializes the DDL function.
            % scanAxisVector - A vector with the points to scan, points
            % should increase with equal distances between them.
            % nFlat - How many flat points should be in the beginning of the scan.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel (in seconds).
            % scanAxis - The axis to scan (x,y,z or 1 for x, 2 for y and 3
            % for z).
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
            if tPixel < 0.005
                fprintf('Minimum pixel time is 5ms, %.1fms were given, changing to 5ms\n', 1000*tPixel);
                tPixel = 0.005;
            end
            
            % Get parameters
            if (nOverRun == 0); nOverRun = 1; end % In order to be centered around the pixel we need at least one extra point from each side.
            numberOfPixels = length(scanAxisVector); % This is the number of pixels
            pixelLengthInPoints = tPixel/5e-5; % The wave generator works in 50us points.
            pixelSizeInum = (scanAxisVector(end) - scanAxisVector(1))/(numberOfPixels-1);
            extraDistanceToSideInPoints = pixelLengthInPoints*nOverRun; % Always positive
            extraDistanceToSideInum = pixelSizeInum*nOverRun; % Can be negative
            scanAxis = GetAxis(obj, scanAxis);
            
            % Parameters according to the PI function, look at GCS manual
            % page 115 (PI_WAV_LIN)
            iWaveTableId = 1;
            iOffsetOfFirstPointInWaveTable = nFlat;
            iNumberOfSpeedUpDownPointsOfWave = extraDistanceToSideInPoints/2; % This is taken twice in the GCS code, so only half for each side.
            iNumberOfWavePoints = pixelLengthInPoints*numberOfPixels + 2*iNumberOfSpeedUpDownPointsOfWave; % But this is only taken once, so need to put it twice.
            iSegmentLength = iNumberOfWavePoints+2*iOffsetOfFirstPointInWaveTable;
            dOffsetOfWave = scanAxisVector(1) - extraDistanceToSideInum;
            dAmplitudeOfWave = scanAxisVector(end) - scanAxisVector(1) + 2*extraDistanceToSideInum;

            % Only redefine waveforms if different from previous.
            localScanStruct = struct('scanAxisVector', scanAxisVector, 'nFlat', nFlat, 'nOverRun', nOverRun, 'tPixel', tPixel, 'scanAxis', scanAxis);
            if ~isequal(localScanStruct, obj.scanStruct)
                obj.scanStruct = localScanStruct;
                
                % Clear old stuff
                SendPICommand(obj, 'PI_TWC', obj.ID); % Clears trigger points.
                SendPICommand(obj, 'PI_DTC', obj.ID, [1 2 3], 3); % Clears DDL Data for all axes.
                
                % Define Scan
                SendPICommand(obj, 'PI_WAV_LIN', obj.ID, iWaveTableId, iOffsetOfFirstPointInWaveTable, iNumberOfWavePoints, 0, iNumberOfSpeedUpDownPointsOfWave, dAmplitudeOfWave, dOffsetOfWave, iSegmentLength);
                numberOfTWSCommands = ceil((numberOfPixels+1)/10); % Up to 10 trigger points per command line can be send
                for i=1:numberOfTWSCommands % Defines the positive edges
                    numberOfTWSPoints = 10*(i < numberOfTWSCommands) + (mod(numberOfPixels, 10)+1)*(i == numberOfTWSCommands);
                    triggerChannelIdsArray = ones(1, numberOfTWSPoints);
                    firstTWSPoint = iOffsetOfFirstPointInWaveTable+10*pixelLengthInPoints*(i-1)+iNumberOfSpeedUpDownPointsOfWave;
                    TWSJump = pixelLengthInPoints;
                    lastTWSPoint = iOffsetOfFirstPointInWaveTable+min(pixelLengthInPoints*10*i, iNumberOfWavePoints-iNumberOfSpeedUpDownPointsOfWave);
                    positiveEdgePointNumberArray = firstTWSPoint:TWSJump:lastTWSPoint;
                    positiveSwitchArray = ones(1, numberOfTWSPoints);
                    SendPICommand(obj, 'PI_TWS', obj.ID, triggerChannelIdsArray, positiveEdgePointNumberArray, positiveSwitchArray, numberOfTWSPoints);
                end
                SendPICommand(obj, 'PI_CTO', obj.ID, 1, 3, 4, 1); % Defines output to be synced with generator.
                SendPICommand(obj, 'PI_WSL', obj.ID, SwitchXYAxis(obj, scanAxis, 'integer'), iWaveTableId, 1); % Defines which table to use.
                
                % Initialize DDL
                %             SendPICommand(obj, 'PI_WGC', obj.ID, SwitchXYAxis(obj, scanAxis, 'integer'), 35, 1); % Defines how many cycles should be made, 35 cycles is the default for the DDL function.
                %             SendPICommand(obj, 'PI_WGO', obj.ID, SwitchXYAxis(obj, scanAxis, 'integer'), 65, 1); % 64+1: 64 is for DDL init & 1 is for start
                %             WaitFor(obj, 'WaveGeneratorDone');
                %             SendPICommand(obj, 'PI_WGO', obj.ID, SwitchXYAxis(obj, scanAxis, 'integer'), 0, 1); % Disables the wave generator
                
                % Prepare for Scanning
                SendPICommand(obj, 'PI_WGC', obj.ID, SwitchXYAxis(obj, scanAxis, 'integer'), 1, 1); % Defines how many cycles should be made for the actual scan: only one.
            end
        end
        
        function ScanOneDimension(obj, scanAxisVector, nFlat, nOverRun, tPixel, scanAxis)  %#ok<INUSL>
            %%%%%%%%%%%%%% ONE DIMENSIONAL SCAN %%%%%%%%%%%%%%
            % Does a scan for the given axis.
            % Last 2 variables are for 2D scans.
            % scanAxisVector - A vector with the points to scan, points
            % should increase with equal distances between them.
            % nFlat - How many flat points should be in the beginning of the scan.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel (in seconds).
            % scanAxis - The axis to scan (x,y,z or 1 for x, 2 for y and 3
            % for z).
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            scanAxis = GetAxis(obj, scanAxis);
            SendPICommand(obj, 'PI_WGO', obj.ID, SwitchXYAxis(obj, scanAxis, 'integer'), 129, 1); % 128+1: 128 is for use DDL & 1 is for start
            WaitFor(obj, 'WaveGeneratorDone')
        end
        
        function PrepareScanInTwoDimensions(obj, macroScanAxisVector, normalScanAxisVector, nFlat, nOverRun, tPixel, macroScanAxis, normalScanAxis)
            %%%%%%%%%%%%%% TWO DIMENSIONAL SCAN %%%%%%%%%%%%%%
            % Prepares a scan for given axes!
            % scanAxisVector1/2 - Vectors with the points to scan, points
            % should increase with equal distances between them.
            % nFlat - How many flat points should be in the beginning of the scan.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            % scanAxis1/2 - The axes to scan (x,y,z or 1 for x, 2 for y and
            % 3 for z).
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            PrepareScanInOneDimension(obj, macroScanAxisVector, nFlat, nOverRun, tPixel, macroScanAxis)
            
            normalScanAxis = GetAxis(obj, normalScanAxis);
            macroScanAxis = GetAxis(obj, macroScanAxis);
            obj.macroNormalScanVector = normalScanAxisVector;
            obj.macroNormalScanAxis = normalScanAxis;
            obj.macroScanAxis = macroScanAxis;
            obj.macroIndex = 1;
            obj.scanRunning = 1;
        end
    end
    
    methods (Access = public) %Overwrite ClassPIMicos functions
        function PrepareScanX(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%%%%% ONE DIMENSIONAL X SCAN %%%%%%%%%%%%%%%%%
            % Prepares a scan for X axis, writes the waveform and 
            % initializes the DDL function.
            % x - A vector with the points to scan, points should have
            % equal distance between them.
            % y/z - The starting points for the other axes.
            % nFlat - How many flat points should be in the beginning of the scan.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if obj.scanRunning
                warning('2D Scan is in progress, previous scan canceled');
                AbortScan(obj);
            end
            Move(obj, 'yz', [y z]);
            PrepareScanInOneDimension(obj, x, nFlat, nOverRun, tPixel, 'x');
            QueryPos(obj);
        end
        
        function PrepareScanY(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%%%%% ONE DIMENSIONAL Y SCAN %%%%%%%%%%%%%%%%%
            % Prepares a scan for Y axis, writes the waveform and 
            % initializes the DDL function.
            % y - A vector with the points to scan, points should have
            % equal distance between them.
            % x/z - The starting points for the other axes.
            % nFlat - How many flat points should be in the beginning of the scan.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if obj.scanRunning
                warning('2D Scan is in progress, previous scan canceled');
                obj.scanRunning = 0;
            end
            Move(obj, 'xz', [x z]);
            PrepareScanInOneDimension(obj, y, nFlat, nOverRun, tPixel, 'y');
            QueryPos(obj);
        end
        
        function PrepareScanZ(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%%%%% ONE DIMENSIONAL Z SCAN %%%%%%%%%%%%%%%%%
            % Prepares a scan for Z axis, writes the waveform and 
            % initializes the DDL function.
            % z - A vector with the points to scan, points should have
            % equal distance between them.
            % x/y - The starting points for the other axes.
            % nFlat - How many flat points should be in the beginning of the scan.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if obj.scanRunning
                warning('2D Scan is in progress, previous scan canceled');
                obj.scanRunning = 0;
            end
            Move(obj, 'xy', [x y]);
            PrepareScanInOneDimension(obj, z, nFlat, nOverRun, tPixel, 'z');
            QueryPos(obj);
        end
        
        function forwards = ScanNextLine(obj)
            % Scans the next line for the 2D scan, to be used after
            % 'PrepareScanXX'.
            % No other commands should be used between 'PrepareScanXX' or
            % until 'AbortScan' has been called.
            % forwards is set to 1 when the scan is forward and is set to 0
            % when it's backwards
            if ~obj.scanRunning
                error('No scan detected.\nFunction can only be called after ''PrepareScanXX!''');
            end
            % Scan
            MovePrivate(obj, obj.macroNormalScanAxis, obj.macroNormalScanVector(obj.macroIndex));
            SendPICommand(obj, 'PI_WGO', obj.ID, SwitchXYAxis(obj, obj.macroScanAxis, 'integer'), 129, 1); % 128+1: 128 is for use DDL & 1 is for start
            forwards = 1;
            
            WaitFor(obj, 'WaveGeneratorDone')
            obj.macroIndex = obj.macroIndex+1;
        end
            
        function PrepareRescanLine(obj)
            % Prepares the previous line for rescanning.
            % Scanning is done with "ScanNextLine"
            if ~obj.scanRunning
                warning('No scan detected. Function can only be called after ''PrepareScanXX!''.\nThis will work if attempting to rescan a 1D scan, but macro will be rewritten.\n');
                return
            elseif (obj.macroIndex == 1)
                error('Scan did not start yet. Function can only be called after ''ScanNextLine!''');
            end
            
            % Decrease index
            obj.macroIndex = obj.macroIndex - 1;
        end
        
        function AbortScan(obj)
            % Aborts the 2D scan defined by 'PrepareScanXX';
            if obj.scanRunning
                obj.macroIndex = -1;
                obj.scanRunning = 0;
                SendPICommand(obj, 'PI_WGO', obj.ID, SwitchXYAxis(obj, obj.macroScanAxis, 'integer'), 0, 1); % Sends a stop command to the wave generator.
            end
        end
        
        function maxScanSize = ReturnMaxScanSize(obj, nDimensions) %#ok<INUSD>
            % Returns the maximum number of points allowed for an
            % 'nDimensions' scan.
            todo = 'check size';
            maxScanSize = 1000;
        end
        
        function FastScan(obj, enable) %#ok<INUSD>
            % Changes the scan between fast & slow mode
            % 'enable' - 1 for fast scan, 0 for slow scan.
            todo = 'scan';
        end
    end
end