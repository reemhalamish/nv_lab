classdef (Sealed) ClassDummyStage  < ClassStage
    
    properties (Access = private)
        posRangeLimit = [6500 6500 6500]; % Units set to microns.
        negRangeLimit = [-6500 -6500 -6500]; % Units set to microns.
        posSoftRangeLimit = [6500 6500 6500]; % Default is same as physical limit.
        negSoftRangeLimit = [-6500 -6500 -6500]; % Default is same as physical limit.
        units = 'um';
        defaultVel = 500 % Default velocity is 500 um/s.
        curPos = [0 0 0];
        curVel = [0 0 0];
        tiltOn = 0;
        tiltThetaX = 0;
        tiltThetaY = 0;
        maxScanSize = [1000 1000];
        macroNormalNumberOfPixels = -1;
        macroNumberOfPixels = -1;
        macroNormalScanVector = -1;
        macroScanVector = -1;
        macroNormalScanAxis = -1;
        macroScanAxis = -1;
        macroScanVelocity = -1;
        macroNormalVelocity = -1;
        macroPixelTime = -1;
        macroFixPosition = -1;
        macroIndex = -1;
    end
    
    properties(Constant = true)
        STEP_MINIMUM_SIZE = 1   % double
        STEP_DEFAULT_SIZE = 20  % double
    end
    
    methods (Static, Access = public) % Get instance constructor
        function obj = GetInstance()
            % Returns a singelton instance of this class.
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                name = 'stage dummy';
                availableAxes = ClassStage.SCAN_AXES;
                isScanable = true;
                tiltAvailable = true;
                localObj = ClassDummyStage(name, availableAxes, isScanable, tiltAvailable);
            end
            obj = localObj;
        end
    end
    
    methods
       function obj = ClassDummyStage(name, availableAxes, isScanable, tiltAvailable)
            obj@ClassStage(name, availableAxes);
            if isScanable
                obj.availableProperties.(obj.HAS_FAST_SCAN) = true;
                obj.availableProperties.(obj.HAS_SLOW_SCAN) = true;
            end
            if tiltAvailable
                obj.availableProperties.(obj.TILTABLE) = true;
            end
        end 
    end
    
    methods (Access = public)        
        function LoadPiezoLibrary(obj) %#ok<*MANU>
            fprintf('Dummy library ready.\n');
        end
                
        function Initialization(obj)
            fprintf('Units are in %s for position and %s/s for velocity.\n', obj.units, obj.units);
            fprintf('XYZ physical axes limits are from %d %s to %d %s.\n', obj.negRangeLimit, obj.units, obj.posRangeLimit, obj.units);
            
            % Soft limit check.
            for i=1:3
                fprintf('%s axis - Soft limits are from %.1f%s to %.1f%s.\n', upper(obj.SCAN_AXES(i)), obj.negSoftRangeLimit(i), obj.units, obj.posSoftRangeLimit(i), obj.units);
            end
            
            for i=1:3
                fprintf('%s axis - Position: %.4f %s, Velocity: %d %s/s.\n', upper(obj.SCAN_AXES(i)), obj.curPos(i), obj.units, obj.curVel(i), obj.units);
            end
        end
        
        
        
        function SetSoftLimits(obj, axis, softLimit, negOrPos)
            % Set the new soft limits:
            % if negOrPos = 0 -> then softLimit = lower soft limit
            % if negOrPos = 1 -> then softLimit = higher soft limit
            % This is because each time this function is called only one of
            % the limits updates
            axis = obj.GetAxis(axis);
            if negOrPos == 0
                obj.negSoftRangeLimit(axis) = softLimit;
            else
                obj.posSoftRangeLimit(axis) = softLimit;
            end
        end
        
        
        function SetVelocity(obj, axis, vel)
            % Absolute change in velocity (vel) of axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = obj.GetAxis(axis);
            obj.curVel(axis) = vel;
        end
        
        function maxScanSize = ReturnMaxScanSize(obj, nDimensions)
            % Returns the maximum number of points allowed for an
            % 'nDimensions' scan.
            maxScanSize = obj.maxScanSize(nDimensions);
        end
        function Connect(obj)
        end
        
        function CloseConnection(obj)
        end
        
        function Move(obj, axis, pos)
            % Absolute change in position (pos) of axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = obj.GetAxis(axis);
            
            if ~PointIsInRange(obj, axis, pos) % Check that point is in limits
                error('Move Command is outside the soft limits');
            end
            
            obj.curPos(axis) = pos;
        end
        
        function RelativeMove(obj, axis, change)
            % Relative change in position (pos) of axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            
            % Check limits
            axis = obj.GetAxis(axis);
            [limNeg, limPos] = obj.ReturnLimits(axis);
            newPos = obj.curPos(axis) + change;
            % Either move, or produce error
            if trinary(newPos, [limNeg limPos]) == 1    % i.e., value is within limits
                obj.curPos(axis) = obj.curPos(axis) + change;
            else
                EventStation.anonymousWarning('Position must be between %d and %d! Stage will not move!', limNeg, limPos)
            end
        end
        
        function ScanX(obj, x, y, z, nFlat, nOverRun, tPixel) %#ok<*INUSD>
            %%%%%%%%%%%%%% ONE DIMENSIONAL X SCAN MACRO %%%%%%%%%%%%%%
            % Does a macro scan for x axis.
            % x - A vector with the points to scan, points should have
            % equal distance between them.
            % y/z - The starting points for the other axes.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, ['y' 'z'], [y z]);
            Move(obj, 'x', x(end));
        end
        
        function TriggX(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% ONE DIMENSIONAL X SCAN MACRO %%%%%%%%%%%%%%
            % Does a macro scan for x axis without writing the macro!
            % There is no check that the macro exists or that it matches
            % the data, so care must be taken!
            % x - A vector with the points to scan, points should have
            % equal distance between them.
            % y/z - The starting points for the other axes.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, ['y' 'z'], [y z]);
            Move(obj, 'x', x(end));
        end
        
        
        function ScanY(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% ONE DIMENSIONAL Y SCAN MACRO %%%%%%%%%%%%%%
            % Does a macro scan for y axis.
            % y - A vector with the points to scan, points should have
            % equal distance between them.
            % x/z - The starting points for the other axes.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, ['x' 'z'], [x z]);
            Move(obj, 'y', y(end));
        end
        
        function TriggY(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% ONE DIMENSIONAL Y SCAN MACRO %%%%%%%%%%%%%%
            % Does a macro scan for y axis without writing the macro!
            % There is no check that the macro exists or that it matches
            % the data, so care must be taken!
            % y - A vector with the points to scan, points should have
            % equal distance between them.
            % x/z - The starting points for the other axes.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, ['x' 'z'], [x z]);
            Move(obj, 'y', y(end));
        end
        
        function ScanZ(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% ONE DIMENSIONAL Z SCAN MACRO %%%%%%%%%%%%%%
            % Does a macro scan for z axis.
            % z - A vector with the points to scan, points should have
            % equal distance between them.
            % x/y - The starting points for the other axes.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, ['x' 'y'], [x y]);
            Move(obj, 'z', z(end));
        end
        
        function TriggZ(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% ONE DIMENSIONAL Z SCAN MACRO %%%%%%%%%%%%%%
            % Does a macro scan for y axis without writing the macro!
            % There is no check that the macro exists or that it matches
            % the data, so care must be taken!
            % z - A vector with the points to scan, points should have
            % equal distance between them.
            % x/y - The starting points for the other axes.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, ['x' 'y'], [x y]);
            Move(obj, 'z', z(end));
        end
        
        function PrepareScanX(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanY(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        
        function PrepareScanInTwoDimensions(obj, macroScanAxisVector, normalScanAxisVector, nFlat, nOverRun, tPixel, macroScanAxis, normalScanAxis) %#ok<INUSL>
            %%%%%%%%%%%%%% TWO DIMENSIONAL SCAN MACRO %%%%%%%%%%%%%%
            % Does a macro scan for given axes!
            % scanAxisVector1/2 - Vectors with the points to scan, points
            % should increase with equal distances between them.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            % scanAxis1/2 - The axes to scan (x,y,z or 1 for x, 2 for y and
            % 3 for z).
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            numberOfMacroPixels = length(macroScanAxisVector);
            numberOfNormalPixels = length(normalScanAxisVector);
            
            startPoint = macroScanAxisVector(1);
            %% Prepare Scan
            obj.macroNormalNumberOfPixels = numberOfNormalPixels;
            obj.macroNumberOfPixels = numberOfMacroPixels;
            obj.macroNormalScanVector = normalScanAxisVector;
            obj.macroScanVector = macroScanAxisVector;
            obj.macroNormalScanAxis = normalScanAxis;
            obj.macroScanAxis = macroScanAxis;
            obj.macroPixelTime = tPixel;
            obj.macroIndex = 1;
            Move(obj, obj.macroScanAxis, startPoint);
        end
        
        function PrepareScanXY(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% TWO DIMENSIONAL XY SCAN MACRO %%%%%%%%%%%%%%
            % Prepare a macro scan for xy axes!
            % Scanning is done by calling 'ScanNextLine'.
            % Aborting via 'AbortScan'.
            % x/y - Vectors with the points to scan, points should have
            % equal distance between them.
            % z - The starting points for the other axis.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, 'z', z);
            PrepareScanInTwoDimensions(obj, x, y, nFlat, nOverRun, tPixel, 'x', 'y');
        end
        
        function PrepareScanXZ(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% TWO DIMENSIONAL XZ SCAN MACRO %%%%%%%%%%%%%%
            % Prepare a macro scan for xz axes!
            % Scanning is done by calling 'ScanNextLine'.
            % Aborting via 'AbortScan'.
            % x/z - Vectors with the points to scan, points should have
            % equal distance between them.
            % y - The starting points for the other axis.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, 'y', y);
            PrepareScanInTwoDimensions(obj, x, z, nFlat, nOverRun, tPixel, 'x', 'z');
        end
        
        function PrepareScanYX(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% TWO DIMENSIONAL XY SCAN MACRO %%%%%%%%%%%%%%
            % Prepare a macro scan for xy axes!
            % Scanning is done by calling 'ScanNextLine'.
            % Aborting via 'AbortScan'.
            % x/y - Vectors with the points to scan, points should have
            % equal distance between them.
            % z - The starting points for the other axis.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, 'z', z);
            PrepareScanInTwoDimensions(obj, y, x, nFlat, nOverRun, tPixel, 'y', 'x');
        end
        
        function PrepareScanYZ(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% TWO DIMENSIONAL YZ SCAN MACRO %%%%%%%%%%%%%%
            % Prepare a macro scan for yz axes!
            % Scanning is done by calling 'ScanNextLine'.
            % Aborting via 'AbortScan'.
            % y/z - Vectors with the points to scan, points should have
            % equal distance between them.
            % x - The starting points for the other axis.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, 'x', x);
            PrepareScanInTwoDimensions(obj, y, z, nFlat, nOverRun, tPixel, 'y', 'z');
        end
        
        function PrepareScanZX(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% TWO DIMENSIONAL XZ SCAN MACRO %%%%%%%%%%%%%%
            % Prepare a macro scan for xz axes!
            % Scanning is done by calling 'ScanNextLine'.
            % Aborting via 'AbortScan'.
            % x/z - Vectors with the points to scan, points should have
            % equal distance between them.
            % y - The starting points for the other axis.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, 'y', y);
            PrepareScanInTwoDimensions(obj, z, x, nFlat, nOverRun, tPixel, 'z', 'x');
        end
        
        function PrepareScanZY(obj, x, y, z, nFlat, nOverRun, tPixel)
            %%%%%%%%%%%%%% TWO DIMENSIONAL YZ SCAN MACRO %%%%%%%%%%%%%%
            % Prepare a macro scan for yz axes!
            % Scanning is done by calling 'ScanNextLine'.
            % Aborting via 'AbortScan'.
            % y/z - Vectors with the points to scan, points should have
            % equal distance between them.
            % x - The starting points for the other axis.
            % nFlat - Not used.
            % nOveRun - How many extra points should be taken from each.
            % tPixel - Scan time for each pixel.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (obj.macroIndex ~= -1)
                warning('2D Scan is in progress, either call ''ScanNextLine'' to continue or ''AbortScan'' to cancel.');
            end
            Move(obj, 'x', x);
            PrepareScanInTwoDimensions(obj, z, y, nFlat, nOverRun, tPixel, 'z', 'y');
        end
        
        function [done, forwards] = ScanNextLine(obj)
            % Scans the next line for the 2D scan, to be used after
            % 'PrepareScanXX'.
            % done is set to 1 after the last line has been scanned.
            % No other commands should be used between 'PrepareScanXX' and
            % until 'ScanNextLine' has returned done, or until 'AbortScan'
            % has been called.
            % forwards is set to 1 when the scan is forward and is set to 0
            % when it's backwards
            if (obj.macroIndex == -1)
                error('No scan detected.\nFunction can only be called after ''PrepareScanXX!''');
            end
            
            Move(obj, obj.macroNormalScanAxis, obj.macroNormalScanVector(obj.macroIndex));
            if (mod(obj.macroIndex,2) ~= 0) % Forwards
                for i=1:obj.macroNumberOfPixels
                    Move(obj, obj.macroScanAxis, obj.macroScanVector(i));
%                     pause(obj.macroPixelTime);
                end
                forwards = 1;
            else % Backwards
                for i=obj.macroNumberOfPixels:-1:1
                    Move(obj, obj.macroScanAxis, obj.macroScanVector(i));
%                     pause(obj.macroPixelTime);
                end
                forwards = 0;
            end
            
            done = (obj.macroIndex == obj.macroNormalNumberOfPixels);
            obj.macroIndex = obj.macroIndex+1;
        end
        
        function PrepareRescanLine(obj)
            % Prepares the previous line for rescanning.
            % Scanning is done with "ScanNextLine"
            if (obj.macroIndex == -1)
                warning('No scan detected. Function can only be called after ''PrepareScanXX!''.\nThis will work if attempting to rescan a 1D scan, but macro will be rewritten.\n');
                return
            elseif (obj.macroIndex == 1)
                error('Scan did not start yet. Function can only be called after ''ScanNextLine!''');
            end
            
            % Decrease index
            obj.macroIndex = obj.macroIndex - 1;
            
            % Go back to the start of the line
            if (mod(obj.macroIndex,2) ~= 0)
                Move(obj,obj.macroScanAxis,obj.macroScanVector(1)-obj.macroFixPosition);
            else
                Move(obj,obj.macroScanAxis,obj.macroScanVector(end)+obj.macroFixPosition);
            end
        end
        
        function AbortScan(obj)
            % Aborts the 2D scan defined by 'PrepareScanXX';
            if (obj.macroIndex ~= -1)
%                 if obj.macroScan % Macro Scan
%                     SetVelocity(obj, obj.macroScanAxis, obj.macroNormalVelocity);
%                 else
%                     % Do Nothing
%                 end
                obj.macroIndex = -1;
            end
        end
        
        function JoystickControl(obj, enable)
            % Changes the joystick state for all axes to the value of
            % 'enable' - 1 to turn Joystick on, 0 to turn it off.
        end
        
        function FastScan(obj, enable)
            % Changes the scan between fast & slow mode
            % 'enable' - 1 for fast scan, 0 for slow scan.
        end
        
        function ChangeLoopMode(obj, mode)
            % Changes between closed and open loop.
            % Mode should be either 'Open' or 'Closed'.
        end
        
        function Halt(obj)
            % Halts all stage movements.
        end
        
        function success = SetTiltAngle(obj, thetaXZ, thetaYZ)
            % Sets the tilt angles between Z axis and XY axes.
            % Angles should be in degrees, valid angles are between -5 and 5
            % degrees.
            obj.tiltThetaX = thetaXZ;
            obj.tiltThetaY = thetaYZ;
            success = 1;
        end
        
        function success = EnableTiltCorrection(obj, enable)
            % Enables the tilt correction according to the angles.
            obj.tiltOn = enable;
            success = 1;
        end
        
        
        function Reconnect(obj)
            % Reconnects the controller.
        end
    end
    
    methods(Access = public)
        function ok = PointIsInRange(obj, axis, point)
            % Checks if the given point is within the soft (and hard)
            % limits of the given axis (x,y,z or 1 for x, 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = obj.GetAxis(axis);
            ok = ((point >= obj.negSoftRangeLimit(axis)) & (point <= obj.posSoftRangeLimit(axis)));
        end
        
        function [negSoftLimit, posSoftLimit] = ReturnLimits(obj, axis)
            % Return the soft limits of the given axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = obj.GetAxis(axis);
            negSoftLimit = obj.negSoftRangeLimit(axis);
            posSoftLimit = obj.posSoftRangeLimit(axis);
        end
        
        function [negHardLimit, posHardLimit] = ReturnHardLimits(obj, axis)
            % Return the hard limits of the given axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = obj.GetAxis(axis);
            negHardLimit = obj.negRangeLimit(axis);
            posHardLimit = obj.posRangeLimit(axis);
        end
        
        function pos = Pos(obj, axis)
            % Query and return position of axis (x,y,z or 1 for x, 2 for y
            % and 3 for z)
            % Vectorial axis is possible.
            axis = obj.GetAxis(axis);
            pos = obj.curPos(axis);
        end
        
        function vel = Vel(obj, axis)
            % Query and return velocity of axis (x,y,z or 1 for x, 2 for y
            % and 3 for z)
            % Vectorial axis is possible.
            axis = obj.GetAxis(axis);
            vel = obj.curVel(axis);
        end
        
        function binaryButtonState = ReturnJoystickButtonState(obj)
            % Returns the state of the buttons in 3 bit decimal format.
            % 1 for first button, 2 for second and 4 for the 3rd.
            binaryButtonState = 0;
        end
        
        function [tiltEnabled, thetaXZ, thetaYZ] = GetTiltStatus(obj)
            % Return the status of the tilt control.
            tiltEnabled = obj.tiltOn;
            thetaXZ = obj.tiltThetaX;
            thetaYZ = obj.tiltThetaY;
        end
    end
    
end