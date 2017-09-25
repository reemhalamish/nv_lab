classdef ExpParameter < HiddenMethodsHandle & PropertiesDisplaySorted
    %EXPPARAMETER objects of type experiment-parameter
    %   they can have their name, supported value-types and the actual
    %   values. also, an ExpParameter-object will alyways point to the
    %   experiment using it
    
    properties
        type
        value = []
        name
        exp = nan;
    end
    
    properties(Constant = true)
        TYPE_BOOLEAN = 'boolean'
        TYPE_DOUBLE = 'double'
        TYPE_VECTOR_OF_DOUBLES = 'vector of doubles'
        ALL_TYPES = {ExpParameter.TYPE_BOOLEAN, ExpParameter.TYPE_DOUBLE, ExpParameter.TYPE_VECTOR_OF_DOUBLES}
    end
    
    methods
        function obj = ExpParameter
            obj@HiddenMethodsHandle;
            obj@PropertiesDisplaySorted;
        end
        
        function isOk = validateValue(obj, newValue)
            % check if a new value is ok type-wise
            switch (obj.type)
                case ExpParameter.TYPE_BOOLEAN
                    isOk = ValidationHelper.isTrueOrFalse(newValue);
                case ExpParameter.TYPE_DOUBLE
                    isOk = isnumeric(newValue) && length(newValue) == 1;
                case ExpParameter.TYPE_VECTOR_OF_DOUBLES
                    isOk = isnumeric(newValue);
            end
        end
    end
    
    methods(Static = true)
        function expParam = createDefault(paramType, paramName, paramValueOptional, expOptional)
            expParam = ExpParameter();
            expParam.type = paramType;
            expParam.name = paramName;
            if exist('paramValueOptional', 'var') && ~isempty(paramValueOptional)
                expParam.value = paramValueOptional;
            end
            
            if exist('expOptional', 'var') && ~isempty(expOptional)
                expParam.exp = expOptional;
            end
        end
    end
    
    %% setters
    methods
        function set.type(obj, newType)
            if ~ischar(newType);                        EventStation.anonymousError('new value for obj.type can only be one of the pre-defined types!'); end
            if ~any(strcmp(obj.ALL_TYPES, newType));    EventStation.anonymousError('new value for obj.type can only be one of the pre-defined types!'); end
            obj.type = newType;
        end
        function set.value(obj, newValue)
            if ~obj.validateValue(newValue); EventStation.anonymousError('new value for obj.value can''t pass the validation! \ntype: (%s), \nvalue: (%s)\n', obj.type, newValue);   end %#ok<MCSUP>
            obj.value = newValue;
            
            if isa(obj.exp, 'Experiment'); obj.exp.sendEventParamChanged(); end %#ok<MCSUP>
        end
        
        function set.exp(obj, newExperiment)
            if ~isa(newExperiment, 'Experiment')
                EventStation.anonymousError('can only set obj.exp with an experiment! this property is for viewing the parent-experiment of this ExpParameter!\nvalue got in:\n%s', newExperiment);
            end
            obj.exp = newExperiment;
        end
    end
    
end

