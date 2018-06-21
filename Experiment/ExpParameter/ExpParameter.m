classdef (Abstract) ExpParameter < HiddenMethodsHandle & PropertiesDisplaySorted
    %EXPPARAMETER objects of type experiment-parameter
    %   ep = EXPPARAMETER(name) creates an empty parameter
    %
    %   ep = EXPPARAMETER(name,value) creates a parameter with VALUE
    %
    %   ep = EXPPARAMETER(___,expName) creates a parameter which is
    %   assigned to an experiment named EXP_NAME
    %
    %   An experiment parameter can have a name, supported value-types and the actual
    %   values. Additionally, an ExpParameter-object will alyways point to the
    %   experiment using it
    
    properties (Abstract, SetAccess = protected)
        type            % string.
    end
    
    properties
        name            % string. Name to be presented in GUI
        value = [];     % value of type 'type'
        expName = nan;  % string. Name of associated experiment
    end
    
    properties (Constant, Hidden)
        TYPE_LOGICAL = 'logical'
        TYPE_DOUBLE = 'double'
        TYPE_VECTOR_OF_DOUBLES = 'vector of doubles'
    end
    
    methods
        function obj = ExpParameter(name, value, expName)
            % All parameters except name are optional
            obj@HiddenMethodsHandle;
            obj@PropertiesDisplaySorted;
            
            obj.name = name;
            if exist('value', 'var'); obj.value = value; end
            if exist('expName', 'var'); obj.expName = expName; end
        end
    end
    
    methods (Static, Abstract)
        isOk = validateValue(newValue)
        % Check if a new value is valid, according to obj.type
    end
    
    %% setters
    methods
        function set.value(obj, newValue)
            if ~isempty(newValue) && ~obj.validateValue(newValue)
                
                % Formatting strings for error
                newType = class(newValue);
                if newType == 'double' && length(newValue)>1; newType = obj.TYPE_VECTOR_OF_DOUBLES; end
                
                parameterName = obj.name; %#ok<*MCSUP>
                % If we know the name of the associated experiment, we want to include it in the error message:
                if obj.isAssociatedToExp; parameterName = sprintf('%s.%s', obj.expName,parameterName); end
                
                EventStation.anonymousError('Trying to define value for %s failed! \nNew value: %s (of type %s) \nExpected type: %s', ...
                    parameterName, newValue, newType, obj.type);
            end
            obj.value = newValue;
            
            if obj.isAssociatedToExp
                exp = getObjByName(Experiment.NAME);
                exp.sendEventParamChanged();
            end
        end
        
        function set.expName(obj, newExperimentName)
            charArray = char(newExperimentName);    % So strcmp could work. If the casting is improper, strcmp would return false
            if ~strcmp(charArray, Experiment.getExperimentNames)
                EventStation.anonymousError('Trying to define parent experiment for %s! Experiment name is invalid', obj.name);
            end
            obj.expName = newExperimentName;
        end
        
        function tf = isAssociatedToExp(obj)
            tf = ~isnan(obj.expName) && ~isempty(obj.expName);
        end
    end
end

