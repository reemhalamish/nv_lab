classdef StageScanParams < handle
    %STAGESCANPARAMS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % all below are number-arrays with size 1x3
        from
        to
        numPoints
        fixedPos
        
        % boolean(logicals \ 1\0)-with size 1x3
        isFixed
        
        % double
        pixelTime
        
        % all below are logicals (boolean)
        continuous
        fastScan
        autoSave
    end
    
    methods
        function obj = StageScanParams(from, to, numPoints, fixedPos, isFixed, pixelTime, continuous, fastScan, autoSave)
            
            %%%% default no-args constructor if needed %%%%
            if nargin == 0
                obj.from = zeros(1,length(ClassStage.SCAN_AXES));
                obj.to = zeros(1,length(ClassStage.SCAN_AXES));
                obj.fixedPos = zeros(1,length(ClassStage.SCAN_AXES));
                obj.numPoints = 2 * ones(1,length(ClassStage.SCAN_AXES));
                obj.isFixed = zeros(1,length(ClassStage.SCAN_AXES));
                obj.pixelTime = 0.015;
                obj.continuous = false;
                obj.fastScan = false;
                obj.autoSave = false;
                return
            end
            
            %%%% input params checks %%%%
            objectsToCheckNumeric1x3Vector = {'from', 'to', 'numPoints', 'fixedPos'};
            
            for i = 1 : length(objectsToCheckNumeric1x3Vector)
                funcParamName = objectsToCheckNumeric1x3Vector{i};
                funcParamValue = eval(funcParamName);
                if ~isnumeric(funcParamValue) || length(funcParamValue) ~= 3
                    EventStation.anonymousError('"%s" parameter should be a 1x3 number array!', funcParamName)
                end
            end
            
            % check if "pixelTime" is a positive double
            if ~ValidationHelper.isInBorders(pixelTime, 0, inf) ...
                    || pixelTime == 0
                EventStation.anonymousError('"pixelTime" parameter should be a positive double!')
            end
            
            % check if "isFixed" is logical array of size 3
            isFixedIsBooleanArray = all(or(isFixed==0, isFixed==1));
            if ~isFixedIsBooleanArray || length(isFixed) ~= 3
                EventStation.anonymousError('"isFixed" parameter should be a 1x3 boolean array!')
            end
            
            % check if the 3 booleans are actually booleans
            objects_to_check_boolean = {'continuous', 'fastScan', 'autoSave'};
            for i = 1 : length(objects_to_check_boolean)
                funcParamName = objects_to_check_boolean{i};
                funcParamValue = eval(funcParamName);
                if funcParamValue ~= 0 && funcParamValue ~= 1
                    EventStation.anonymousError('"%s" should be logical!', funcParamName);
                end
            end
            
            
            
            %%%% create object %%%%
            obj.from = from;
            obj.to = to;
            obj.numPoints = numPoints;
            obj.fixedPos = fixedPos;
            obj.isFixed = isFixed;
            obj.pixelTime = pixelTime;
            obj.continuous = continuous;
            obj.fastScan = fastScan;
            obj.autoSave = autoSave;
        end
        
        function outStruct = asStruct(obj)
            outStruct = jsondecode(jsonencode(obj));
        end
        
        function wasChanged = updateByLimit(obj, axis, newLimNeg, newLimPos)
            % axis - the axis to change
            % newLimNeg, newLimPos - the new limits to consider
            % supports vectorial axis!
            % NO INPUT CHECKS!
            axis = ClassStage.getAxis(axis);
            oldFrom = obj.from;
            oldTo = obj.to;
            oldFixedPos = obj.fixedPos;
            
            from_ = obj.from(axis);
            from_(from_ > newLimPos) = newLimPos(from_ > newLimPos);
            from_(from_ < newLimNeg) = newLimNeg(from_ < newLimNeg);
            obj.from(axis) = from_;
            
            to_ = obj.to(axis);            
            to_(to_ > newLimPos) = newLimPos(to_ > newLimPos);
            to_(to_ < newLimNeg) = newLimNeg(to_ < newLimNeg);
            obj.to(axis) = to_;
            
            fixedPos_ = obj.fixedPos(axis);
            fixedPos_(fixedPos_ > newLimPos) = newLimPos(fixedPos_ > newLimPos);
            fixedPos_(fixedPos_ < newLimNeg) = newLimNeg(fixedPos_ < newLimNeg);
            obj.fixedPos(axis) = fixedPos_;
            
            sameAsBefore = all(oldFrom == obj.from) ...
                && all(oldTo == obj.to) ...
                && all(oldFixedPos == obj.fixedPos) ...
                ;
            wasChanged = ~sameAsBefore;
        end
        
        function newScanParams = copy(obj)
            newScanParams = StageScanParams.fromStruct(obj.asStruct());
        end
                
    end
    
    % getters
    methods
        function string = getScanAxes(obj)
            string = '';
            for i = 1 : ClassStage.SCAN_AXES_SIZE
                if ~obj.isFixed(i)
                    axis = ClassStage.SCAN_AXES(i);
                    string = [string axis]; %#ok<AGROW>
                end
            end
        end
        
        function string = getFixedAxes(obj)
            obj.sendWarningIfNotScannable();
            string = '';
            for i = 1 : ClassStage.SCAN_AXES_SIZE
                if obj.isFixed(i)
                    axis = ClassStage.SCAN_AXES(i);
                    string = [string axis]; %#ok<AGROW>
                end
            end
        end
        
        function index = getFirstScanAxisIndex(obj)
            obj.sendWarningIfNotScannable();
            for i = 1 : ClassStage.SCAN_AXES_SIZE
                if ~obj.isFixed(i)
                    index = i;
                    return
                end
            end
            index = -1;
        end
        
        function index = getSecondScanAxisIndex(obj)
            isScanable = obj.sendWarningIfNotScannable;
            if ~isScanable
                index = -1;
                return
            end
            
            for i = obj.getFirstScanAxisIndex + 1 : ClassStage.SCAN_AXES_SIZE
                if ~obj.isFixed(i)
                    index = i;
                    return
                end
            end
            index = -1;  % if not found
        end

        function axis = getFirstScanAxisVector(obj)
            obj.sendWarningIfNotScannable();
            axis = obj.getScanAxisVector(obj.getFirstScanAxisIndex);
        end
        
        function axis = getSecondScanAxisVector(obj)
            axis = obj.getScanAxisVector(obj.getSecondScanAxisIndex);
        end
        
        function axisVector = getScanAxisVector(obj, axisIndex)
            % gets a vector to scan, by the axis-index
            % or, if it's a fixed position, gets the position
            if axisIndex < 0 || axisIndex > length(obj.from)
                axisVector = [];
                return
            end
            
            if obj.isFixed(axisIndex)
                axisVector = obj.fixedPos(axisIndex);
                return
            end
            
            first = obj.from(axisIndex);
            last = obj.to(axisIndex);
            jumps = obj.numPoints(axisIndex) -1;
            dist = (last - first) / jumps;
            axisVector = first : dist : last;
        end
        
        function string1Letter = getFirstScanAxisLetter(obj)
            string1Letter = ClassStage.SCAN_AXES(obj.getFirstScanAxisIndex);
        end
        function string1Letter = getSecondScanAxisLetter(obj)
            % returns a 1char string, or empty string if this scan
            % parameters object doesn't request a 2 dim scan
            index = obj.getSecondScanAxisIndex;
            if index > ClassStage.SCAN_AXES_SIZE || index <= 0
                string1Letter = '';
                return
            end
            string1Letter = ClassStage.SCAN_AXES(obj.getSecondScanAxisIndex);
        end
    end
    
    % helper methods
    methods(Access = protected)
        function isOk = sendWarningIfNotScannable(obj)
            if all(obj.isFixed)
                EventStation.anonymousWarning('Attention - StageScanParams object is not scan-friendly! all the axes are fixed!');
                isOk = false;
            else
                isOk = true;
            end
        end
        
    end
    
    methods(Static = true)
        function obj = fromStruct(inputStruct)
            neededFields = properties(StageScanParams)';
            
            obj =  StageScanParams;
            for fieldIndex = 1 : length(neededFields)
                fieldName = neededFields{fieldIndex};
                if isfield(inputStruct, fieldName)
                    obj.(fieldName) = inputStruct.(fieldName)';
                else
                    warning('couldn''t find field "%s" in struct. using default value.', fieldName, obj.(fieldName));
                end
            end
        end
    end
    
end

