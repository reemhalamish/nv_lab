classdef ExpParameter < HiddenMethodsHandle & PropertiesDisplaySorted
    %EXPPARAMETER objects of type experiment-parameter
    %   they can have their name, supported value-types and the actual
    %   values. Additionally, an ExpParameter-object will alyways point to the
    %   experiment using it
    
    properties
        name        % string. Name to be presented in GUI
        type        % string. Could be any of TYPE_LIST
        value = [];  % value of type 'type'
        expName = nan;  % string. Name of associated experiment
    end
    
    properties (Constant)
        TYPE_LOGICAL = 'logical'
        TYPE_BOOLEAN = ExpParameter.TYPE_LOGICAL; % just in case anybody gets confused
        TYPE_DOUBLE = 'double'
        TYPE_VECTOR_OF_DOUBLES = 'vector of doubles'
        ALL_TYPES = {ExpParameter.TYPE_LOGICAL, ExpParameter.TYPE_DOUBLE, ExpParameter.TYPE_VECTOR_OF_DOUBLES}
    end
    
    methods
        function obj = ExpParameter(name, type, value, expName)
            % All parameters are optional (at least for now), but they are
            % dependent on the existence of others:
            %         name
            %       /    \
            %    type    expName
            %     |
            %   value
            obj@HiddenMethodsHandle;
            obj@PropertiesDisplaySorted;
            
            if exist('name', 'var')
                obj.name = name;
            elseif nargin > 0
                EventStation.anonymousWarning('ExpParameter must have a name in order to have other properties. Default parameter was created.');
                return
            end

            if exist('value', 'var')
                if exist('type', 'var')
                    obj.type = type;
                    obj.value = value;
                else
                    EventStation.anonymousWarning('ExpParameter must have a defined type in order to define its value.');
                end
            end
            
            if exist('expName', 'var')
                obj.expName = expName;
            end

        end
        
        function isOk = validateValue(obj, newValue)
            % Check if a new value is valid, according to obj.type
            isOk = false;
            if isempty(newValue)
                isOk = true;
                return  % Design decision: accept empty value, though not strictly "ok"
            end
            switch obj.type
                case obj.TYPE_LOGICAL
                    isOk = ValidationHelper.isTrueOrFalse(newValue);
                case obj.TYPE_DOUBLE
                    isOk = isnumeric(newValue) && isscalar(newValue);
                case obj.TYPE_VECTOR_OF_DOUBLES
                    isOk = isnumeric(newValue);
            end
        end
    end
    
    %% setters
    methods
        function set.type(obj, newType)
            if ~ischar(newType) || ~any(strcmp(obj.ALL_TYPES, newType))
                EventStation.anonymousError('The type of ExpParameter must be one of the pre-defined types!');
            end
            
            obj.type = newType;
            try
                if ~obj.validateValue(obj.value) %#ok<*MCSUP>
                    obj.value = [];     % it is no longer valid, and should be discarded
                end
            catch err
                warning(err.message)
            end
        end
        
        function set.value(obj, newValue)
            if ~obj.validateValue(newValue)
                
                % formatting strings for error
                newType = class(newValue);
                if newType == 'double' && length(newValue)>1; newType = obj.TYPE_VECTOR_OF_DOUBLES; end
                
                parameterName = obj.name;
                if ~isempty(obj.expName); parameterName = sprintf('%s.%s',obj.expName,parameterName); end
                
                EventStation.anonymousError('Trying to define value for %s failed! \nNew value: %s (of type %s) \nExpected type: %s', ...
                    parameterName, newValue, newType, obj.type);
            end
            obj.value = newValue;
            
            if isstring(obj.expName)
                exp = getObjByName(obj.expName);
                exp.sendEventParamChanged();
            end
        end
        
        function set.expName(obj, newExperimentName)
            isValidExpName = ischar(newExperimentName) || isstring(newExperimentName);   % might add more requirements in the future
            if ~isValidExpName
                EventStation.anonymousError('Trying to define parent experiment for %s! Experiment name is invalid', obj.name);
            end
            obj.expName = newExperimentName;
        end
    end
end

