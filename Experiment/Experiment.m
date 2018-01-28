classdef Experiment < EventSender & EventListener & Savable
    %EXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        expName                 % For retrieving using getExpByName
        mCategory               % For loading (might change in subclasses)
        
        mCurrentXAxisParam      % stores the ExpParameter that is in charge of axis x (which has name and value)
        mCurrentYAxisParam		% stores the ExpParameter that is in charge of axis y (which has name and value)
    end
    
    properties(Constant)
        NAME = 'Experiment'
        
        EVENT_PLOT_UPDATED = 'plotUpdated' % when something changed regarding the plot (new data, change in x\y axis, change in x\y labels)
        EVENT_EXP_RESUMED = 'experimentResumed' % when the experiment is starting to run
        EVENT_EXP_PAUSED = 'experimentPaused' % when the experiment stops from running
        EVENT_PLOT_ANALYZE_FIT = 'plot_analyzie_fit' % when the experiment wants the plot to draw the fitting-function-analysis
        EVENT_PARAM_CHANGED = 'experimentParameterChanged' % when one of the sequence params \ general params is changed
        
        % Exception handling
        EXCEPTION_ID_NO_EXPERIMENT = 'getExp:noExp';
        EXCEPTION_ID_NOT_CURRENT = 'getExp:notCurrExp';
    end
    
    methods
        function sendEventPlotUpdated(obj); obj.sendEvent(struct(obj.EVENT_PLOT_UPDATED, true)); end
        function sendEventExpResumed(obj); obj.sendEvent(struct(obj.EVENT_EXP_RESUMED, true)); end
        function sendEventExpPaused(obj); obj.sendEvent(struct(obj.EVENT_EXP_PAUSED, true)); end
        function sendEventPlotAnalyzeFit(obj); obj.sendEvent(struct(obj.EVENT_PLOT_ANALYZE_FIT, true)); end
        function sendEventParamChanged(obj); obj.sendEvent(struct(obj.EVENT_PARAM_CHANGED, true)); end
        
        function obj = Experiment(expName)
            obj@EventSender(Experiment.NAME);
            obj@Savable(Experiment.NAME);
            obj@EventListener(Tracker.NAME);
            obj.expName = expName;
            
            obj.mCurrentXAxisParam = ExpParameter('X axis', ExpParameter.TYPE_VECTOR_OF_DOUBLES, [], obj.NAME);
            obj.mCurrentYAxisParam = ExpParameter('Y axis', ExpParameter.TYPE_VECTOR_OF_DOUBLES, [], obj.NAME);
            
            % To be overridden by Trackable
            obj.mCategory = Savable.CATEGORY_EXPERIMENTS; 
            
            % copy parameters from previous experiment (if exists) and replace its base object
            prevExp = removeObjIfExists(Experiment.NAME);
            if isa(prevExp, 'Experiment')
                obj.robAndKillPrevExperiment(prevExp); 
            % No need to tell the users otherwise. Perfectly normal.
%             else
%                 EventStation.anonymousWarning('Can''t find previous experiment! Initiating parameters from scratch...');
            end
            addBaseObject(obj);
        end
        
        function cellOfStrings = getAllExpParameterProperties(obj)
            % Get all the property-names of properties from the
            % Experiment object that are from type "ExpParameter"
            allVariableProperties = obj.getAllNonConstProperties();
            isPropExpParam = cellfun(@(x) isa(obj.(x), 'ExpParameter'), allVariableProperties);
            cellOfStrings = allVariableProperties(isPropExpParam);
        end
        
        function robAndKillPrevExperiment(obj, prevExperiment)
            % get all the ExpParameter's from the previous experiment
            % prevExperiment = the previous experiment
            
            for paramNameCell = prevExperiment.getAllExpParameterProperties()
                paramName = paramNameCell{:};
                if isprop(obj, paramName)
                    % if the current experiment has this property also
                    obj.(paramName) = prevExperiment.(paramName);
                    obj.(paramName).expName = obj.expName;  % expParam, I am (now) your parent!
                end
            end
            
            delete(prevExperiment);
        end
        
        function delete(obj) %#ok<INUSD>
            % todo: needed? 
        end
    end
    
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % Event is the event sent from the EventSender
        function onEvent(obj, event) %#ok<INUSL>
            if isfield(event.extraInfo, Tracker.EVENT_TRACKER_ENDED)
                % todo - stuff
            end
        end
    end
    
    
    %% overriding from Savable
    methods(Access = protected)
        function outStruct = saveStateAsStruct(obj, category, type) %#ok<INUSD>
            % Saves the state as struct. if you want to save stuff, make
            % (outStruct = struct;) and put stuff inside. If you dont
            % want to save, make (outStruct = NaN;)
            %
            % category - string. Some objects saves themself only with
            %                    specific category (image/experimetns/etc)
            % type - string.     Whether the objects saves at the beginning
            %                    of the run (parameter) or at its end (result)
            
            outStruct = NaN;
            
            % mCategory is overrided by Tracker, and we need to check it
            if ~strcmp(category,obj.mCategory); return; end
            
            
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<INUSD>
            % loads the state from a struct.
            % to support older versoins, always check for a value in the
            % struct before using it. view example in the first line.
            % category - a string, some savable objects will load stuff
            %            only for the 'image_lasers' category and not for
            %            'image_stages' category, for example
            % subCategory - string. could be empty string
            
            
            
            if isfield(savedStruct, 'some_value')
                obj.my_value = savedStruct.some_value;
            end
        end
        
        function string = returnReadableString(obj, savedStruct) %#ok<INUSD>
            % return a readable string to be shown. if this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '');
            
            string = NaN;
        end
    end
    
end

