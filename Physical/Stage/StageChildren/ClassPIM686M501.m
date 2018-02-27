classdef (Sealed) ClassPIM686M501 < ClassStage
    %CLASSPIM686M501 Wrapper class for ClassPIM686 & ClassPIM501

    properties (Access = protected)
        stageCoarseZ
        stageCoarseXY
    end
    
    properties(Constant = true)
        NAME = 'Stage (coarse) - ClassPIM686&PIM501'
        AVAILABLE_AXES = 'xyz'
        
        STEP_MINIMUM_SIZE = 0.3
        STEP_DEFAULT_SIZE = 100
    end
    
    methods (Static, Access = public) % Get instance constructor
        function obj = GetInstance()
            % No need for singleton here
            obj = ClassPIM686M501;
        end
        
        function warningScanUnimplemented
            warning('Scan is not implemented for coarse stages');
        end
    end
    
    methods (Access = private) % Private Functions
        function obj = ClassPIM686M501
            % Private default constructor
            name = ClassPIM686M501.NAME;
            availableAxes = ClassPIM686M501.AVAILABLE_AXES;
%             tiltAvailable = true;         todo: implement
            
            obj@ClassStage(name, availableAxes);
            obj.stageCoarseXY = ClassPIM686.GetInstance();
            obj.stageCoarseZ = ClassPIM501.GetInstance();
            
            obj.availableProperties.(obj.HAS_CLOSED_LOOP) = true;
            obj.availableProperties.(obj.HAS_OPEN_LOOP) = true;
        end 
    end
    
    methods (Access = public) % Implement ClassStage Abstracts
        function CloseConnection(obj)
            % Closes the connection to the stages.
            obj.stageCoarseZ.CloseConnection();
            obj.stageCoarseXY.CloseConnection();
        end
        
        function Reconnect(obj)
            % Reconnects the controller.
            obj.stageCoarseZ.Reconnect();
            obj.stageCoarseXY.Reconnect();
        end
        
        function ok = PointIsInRange(obj, axis, point)
            % Checks if the given point is within the soft (and hard)
            % limits of the given axis (x,y,z or 1 for x, 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis.
                ok = obj.stageCoarseZ.PointIsInRange(axis, point);
            elseif all(axis ~= 3) % No Z Axis.
                ok = obj.stageCoarseXY.PointIsInRange(axis, point);
            else % Mixture.
                ok = obj.stageCoarseZ.PointIsInRange(axis(axis==3), point) ...
                    & obj.stageCoarseXY.PointIsInRange(axis(axis~=3), point);
            end
        end
        
        function [negSoftLimit, posSoftLimit] = ReturnLimits(obj, axis)
            % Return the soft limits of the given axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis
                [negSoftLimit, posSoftLimit] = obj.stageCoarseZ.ReturnLimits(axis);
            elseif all(axis ~= 3) % No Z Axis
                [negSoftLimit, posSoftLimit] = obj.stageCoarseXY.ReturnLimits(axis);
            else % Mixture
                zAxisBool = (axis == 3);
                xyAxesBool = (axis ~= 3);
                [negSoftLimit(xyAxesBool), posSoftLimit(xyAxesBool)] = obj.stageCoarseXY.ReturnLimits(axis(xyAxesBool));
                [negSoftLimit(zAxisBool),  posSoftLimit(zAxisBool)]  = obj.stageCoarseZ.ReturnLimits(axis(zAxisBool));
            end
        end
        
        function [negHardLimit, posHardLimit] = ReturnHardLimits(obj, axis)
            % Return the hard limits of the given axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis.
                [negHardLimit, posHardLimit] = obj.stageCoarseZ.ReturnHardLimits(axis);
            elseif all(axis ~= 3) % No Z Axis.
                [negHardLimit, posHardLimit] = obj.stageCoarseXY.ReturnHardLimits(axis);
            else % Mixture.
                zAxisBool = (axis == 3);
                xyAxesBool = (axis ~= 3);
                [negHardLimit(xyAxesBool), posHardLimit(xyAxesBool)] = obj.stageCoarseXY.ReturnHardLimits(axis(xyAxesBool));
                [negHardLimit(zAxisBool), posHardLimit(zAxisBool)] = obj.stageCoarseZ.ReturnHardLimits(axis(zAxesBool));
            end
        end
        
        function SetSoftLimits(obj, axis, softLimit, negOrPos)
            % Set the new soft limits:
            % if negOrPos = 0 -> then softLimit = lower soft limit
            % if negOrPos = 1 -> then softLimit = higher soft limit
            % This is because each time this function is called only when
            % one of the limits updates.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis
                obj.stageCoarseZ.SetSoftLimits(axis, softLimit, negOrPos);
            elseif all(axis ~= 3) % No Z Axis
                obj.stageCoarseXY.SetSoftLimits(axis, softLimit, negOrPos);
            else % Mixture
                obj.stageCoarseZ.SetSoftLimits(axis(axis==3), softLimit(axis==3), negOrPos);
                obj.stageCoarseXY.SetSoftLimits(axis(axis~=3), softLimit(axis~=3), negOrPos);
            end
        end
        
        function pos = Pos(obj, axis)
            % Query and return position of axis (x,y,z or 1 for x, 2 for y
            % and 3 for z)
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis.
                pos = obj.stageCoarseZ.Pos(axis);
            elseif all(axis ~= 3) % No Z Axis.
                pos = obj.stageCoarseXY.Pos(axis);
            else % Mixture.
                pos(axis==3) = obj.stageCoarseZ.Pos(axis(axis==3));
                pos(axis~=3) = obj.stageCoarseXY.Pos(axis(axis~=3));
            end
        end
        
        function vel = Vel(obj, axis)
            % Query and return velocity of axis (x,y,z or 1 for x, 2 for y
            % and 3 for z)
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis.
                vel = obj.stageCoarseZ.Vel(axis);
            elseif all(axis ~= 3) % No Z Axis.
                vel = obj.stageCoarseXY.Vel(axis);
            else % Mixture.
                if axis(end) ~= 3; error('Last axis is not Z, unsupported'); end;
                velZ = obj.stageCoarseZ.Vel(axis(axis==3));
                velXY = obj.stageCoarseXY.Vel(axis(axis~=3));
                vel = [velXY, velZ];
            end
        end
        
        function Move(obj, axis, pos)
            % Absolute change in position (pos) of axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis.
                obj.stageCoarseZ.Move(axis, pos);
            elseif all(axis ~= 3) % No Z Axis.
                obj.stageCoarseXY.Move(axis, pos);
            else % Mixture.
                obj.stageCoarseZ.Move(axis(axis==3), pos(axis==3));
                obj.stageCoarseXY.Move(axis(axis~=3), pos(axis~=3));
            end
        end
        
        function RelativeMove(obj, axis, change)
            % Relative change in position (pos) of axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis.
                obj.stageCoarseZ.RelativeMove(axis, change);
            elseif all(axis ~= 3) % No Z Axis.
                obj.stageCoarseXY.RelativeMove(axis, change);
            else % Mixture.
                obj.stageCoarseZ.RelativeMove(axis(axis==3), change(axis==3));
                obj.stageCoarseXY.RelativeMove(axis(axis~=3), change(axis~=3));
            end
        end
        
        function Halt(obj)
            % Halts all stage movements.
            obj.stageCoarseZ.Halt();
            obj.stageCoarseXY.Halt();
        end
        
        function SetVelocity(obj, axis, vel)
            % Absolute change in velocity (vel) of axis (x,y,z or 1 for x,
            % 2 for y and 3 for z).
            % Vectorial axis is possible.
            axis = GetAxis(obj, axis);
            if all(axis == 3) % Only Z Axis.
                obj.stageCoarseZ.SetVelocity(axis, vel);
            elseif all(axis ~= 3) % No Z Axis.
                obj.stageCoarseXY.SetVelocity(axis, vel);
            else % Mixture.
                obj.stageCoarseZ.SetVelocity(axis(axis==3), vel(axis==3));
                obj.stageCoarseXY.SetVelocity(axis(axis~=3), vel(axis~=3));
            end
        end
        
        function JoystickControl(obj, enable)
            % Changes the joystick state for all axes to the value of
            % 'enable' - 1 to turn Joystick on, 0 to turn it off.
            if all(axis == 3) % Only Z Axis.
                obj.stageCoarseZ.JoystickControl(enable);
            elseif all(axis ~= 3) % No Z Axis.
                obj.stageCoarseXY.JoystickControl(enable);
            else % Mixture.
                obj.stageCoarseZ.JoystickControl(enable);
                obj.stageCoarseXY.JoystickControl(enable);
            end
        end
        
        function binaryButtonState = ReturnJoystickButtonState(obj)
            % Returns the state of the buttons in 3 bit decimal format.
            % 1 for first button, 2 for second and 4 for the 3rd.
            if all(axis == 3) % Only Z Axis.
                binaryButtonState = obj.stageCoarseZ.ReturnJoystickButtonState();
            elseif all(axis ~= 3) % No Z Axis.
                binaryButtonState = obj.stageCoarseXY.ReturnJoystickButtonState();
            else % Mixture.
                binaryButtonState = obj.stageCoarseZ.ReturnJoystickButtonState();
                binaryButtonState = binaryButtonState + obj.stageCoarseXY.ReturnJoystickButtonState();
            end
        end
        
        function FastScan(obj, enable)
            % Changes the scan between the fast & the slow modes.
            % 'enable' - 1 for fast scan, 0 for slow scan.
            if all(axis == 3) % Only Z Axis.
                obj.stageCoarseZ.FastScan(enable);
            elseif all(axis ~= 3) % No Z Axis.
                obj.stageCoarseXY.FastScan(enable);
            else % Mixture.
                obj.stageCoarseZ.FastScan(enable);
                obj.stageCoarseXY.FastScan(enable);
            end
        end
        
        function ChangeLoopMode(obj, mode)
            % Changes between closed and open loop.
            % Mode should be either 'Open' or 'Closed'.
            if all(axis == 3) % Only Z Axis.
                obj.stageCoarseZ.ChangeLoopMode(mode);
            elseif all(axis ~= 3) % No Z Axis.
                obj.stageCoarseXY.ChangeLoopMode(mode);
            else % Mixture.
                obj.stageCoarseZ.ChangeLoopMode(mode);
                obj.stageCoarseXY.ChangeLoopMode(mode);
            end
        end
        
        function success = SetTiltAngle(obj, thetaXZ, thetaYZ)
            % Sets the tilt angles between Z axis and XY axes.
            % Angles should be in degrees, valid angles are between -5 and 5
            % degrees.
            success = 0;
            obj.warningScanUnimplemented();
        end
        
        function success = EnableTiltCorrection(obj, enable)
            % Enables the tilt correction according to the angles.
            success = 0;
            obj.warningScanUnimplemented();
        end
        
        function [tiltEnabled, thetaXZ, thetaYZ] = GetTiltStatus(obj)
            % Return the status of the tilt control.
            tiltEnabled = 0;
            thetaXZ = 0;
            thetaYZ = 0;
        end
    end
    
    %% overriding from Savable
    % This pseudo-stage should not return string.
    methods(Access = protected)
        function string = returnReadableString(obj, savedStruct)
            % return a readable string to be shown. if this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '';)
            
            string = NaN;
        end
    end
    
    %% Blank/warning Implementions of scan methods
    methods (Access = public)
        function PrepareScanX(obj, x, y, z, nFlat, nOverRun, tPixel)  %#ok<*INUSD>
        end
        function PrepareScanY(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanXY(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanXZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanYX(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanYZ(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanZX(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareScanZY(obj, x, y, z, nFlat, nOverRun, tPixel)
        end
        function PrepareRescanLine(obj) %#ok<MANU>
        end
        
        function ScanX(obj, x, y, z, nFlat, nOverRun, tPixel)
            obj.warningScanUnimplemented();
        end
        function ScanY(obj, x, y, z, nFlat, nOverRun, tPixel)
            obj.warningScanUnimplemented();
        end
        function ScanZ(obj, x, y, z, nFlat, nOverRun, tPixel)
            obj.warningScanUnimplemented();
        end
        
        function AbortScan(obj) %#ok<MANU>
        end
        
        function forwards = ScanNextLine(obj)
            obj.warningScanUnimplemented();
            forwards = 1;
        end
        function maxScanSize = ReturnMaxScanSize(obj, nDimensions)
            obj.warningScanUnimplemented();
            maxScanSize = 0;
        end
    end
end