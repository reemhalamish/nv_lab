classdef OldClassStage < EventSender & Savable
    %STAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dummyMode           % boolean. if true, everything will pass
        scanParams          % object of type StageScanParams
        availableAxes       % string. for example - "xy"
    end
    
    properties(Constant = true)
        SCAN_AXES = 'xyz';
        SCAN_AXES_SIZE = 3; % it is the length of SCAN_AXES
        NEEDED_FIELDS_CREATE = {'type'};
    end
    
    methods(Access = protected)
        function obj = OldClassStage(stageNickName, dummyModeBoolean, availableAxes)
            obj@EventSender(stageNickName);
            obj@Savable(stageNickName);
            obj.dummyMode = dummyModeBoolean;
            obj.scanParams = StageScanParams();
            obj.availableAxes = availableAxes;
        end
    end
    
    methods(Static)
        function instance = allStages()
            persistent allStages
         if isempty(allStages) || ~isvalid(allStages)
            allStages = CellContainer;
         end
         instance = allStages;
        end
        
        function stage = getByName(stageName)
            % return a stage by a provided nickname
            % stageName - the stage nickname
            allStages = Stage.allStages();
            for k = 1 : length(allStages.cells)
                curStage = allStages.cells{k};
                if strcmp(curStage.name, stageName)
                    stage = curStage;
                    return
                end
            end
            error('can''t find a stage with name "%s"!', stageName);
        end
        
        
        function obj = create(stageStruct) %#ok<*INUSD>
            % this method is used to load a Stage as new
            %
            % the "stageStruct" HAS TO HAVE this property (or an error will be thrown):
            % "name" - a string
            %
            % the "stageStruct" HAS TO HAVE this property (or an error will be thrown):
            % "available_axes" - a string repr of the axes (example - "xz")
            %
            % the stageStruct can have a 'dummy' property, called "dummy" -
            %   which is a boolean.  
            % if set to true, no actual physics will be involved. good for
            %   testing purposes.  
            % if 'dummy' not exists, the stage will treat it like dummy=false
            %
            missingField = FactoryHelper.usualChecks(stageStruct, Stage.NEEDED_FIELDS_CREATE);
            if ~isnan(missingField)
                error('Can''t find the preserved word "%s" in the main section at the file "setupInfo.json"', missingField);
            end
            
            availableAxes = stageStruct.available_axes;
            
            % assert all the letters are from Stage.SCAN_AXES 
            %       (bad example: xya)
            for i = 1 : length(availableAxes)
                axis = availableAxes(i);
                if isempty(strfind(Stage.SCAN_AXES, axis))
                    error('can''t create a stage with axis "%s", supporting only those axes: "%s"', axis, Stage.SCAN_AXES);
                end
            end
            
            % assert all the letters exist only once (bad example: xyzx)
            for i = 1: Stage.SCAN_AXES_SIZE
                axis = Stage.SCAN_AXES(i);
                if length(strfind(availableAxes,axis)) > 1
                    error('axis ''%s'' exists more than one time. aborting', axis);
                end
            end
            
                
            if isfield(stageStruct, 'dummy')
                dummy = stageStruct.dummy;
            else
                dummy = false;
            end
            
            % create the stage
            obj = Stage(stageStruct.name,dummy, availableAxes);
            
            % add the new stage for next calls to getStageByName()
            allStages = Stage.allStages();
            allStages.cells{end + 1} = obj;
        end
        
        function axisIndex = getAxisIndex(axis)
            % Converts x,y,z into the corresponding index for this
            % controller; if stage only has 'z' then z is 1.
            
            if isnumeric(axis)
                % for example, axis = [1 2]. make it ---> axis = 'xy'
                if any(axis > length(Stage.SCAN_AXES))
                    error('no such axis with index %d! indexes are for %s', axis(axis > length(Stage.SCAN_AXES)), Stage.SCAN_AXES)
                end
                axis = Stage.SCAN_AXES(axis);
            end
            
            if ~ischar(axis)
                error('"axis" parameter should be a char array, or indexes array (ints)!')
            end
            axisIndex = zeros(1, length(axis));
            for i=1:length(axis)
                axisChar = axis(i);
                if isempty(strfind(Stage.SCAN_AXES, axisChar))
                    error('invalid axis: "%s", supported axes: "%s"', axisChar, Stage.SCAN_AXES);
                end
                axisIndex(i) = strfind(Stage.SCAN_AXES, axisChar);
            end
        end
    end

    
    
    %% setters
    methods
        function set.scanParams(obj, newScanParams)
            if isa(newScanParams, 'StageScanParams')
                obj.scanParams = newScanParams;
                obj.sendEvent(newScanParams);
            else
                obj.sendWarning('can''t set obj.scanParams with a an argument not of type "StageScanParams"! ignoring')
            end
        end
    end
    
    %% overriding from Savable
    methods(Access = protected) 
        function outStruct = saveStateAsStruct(obj, category) %#ok<*MANU>
            % saves the state as struct. 
            outStruct = NaN;
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
            % loads the state from a struct.
        end
        
        function string = returnReadableString(obj, savedStruct)
            % return a readable string to be shown.
            string = NaN;
        end
    end
    
end

