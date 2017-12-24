classdef Tracker < EventSender & EventListener & Savable
    %TRACKER In charge of all trackables (tracking experiments)
    
    properties (Access = private)
        mLocalStruct = struct;
    end
    
    properties(Constant = true)
        NAME = 'Tracker'
        TRACKABLE_POSITION_NAME = 'trackablePosition';
        % To be implemented
            % TRACKABLE_POWER_NAME = 'trackablePower';
            % TRACKABLE_FREQUENCY_NAME = 'trackableFrequency';
            % TRACKABLE_MAGNETIC_NAME = 'trackableMagnetic';
        TRACKABLE_EXPERIMENTS_NAME = {Tracker.TRACKABLE_POSITION_NAME}; % for now
        
        EVENT_TRACKER_FINISHED = 'trackerFinished'
    end
    
    methods
        function sendEventTrackerFinished(obj)
            obj.sendEvent(struct(obj.EVENT_TRACKER_FINISHED,true));
        end
        
        function obj = Tracker
            obj@Savable(Tracker.NAME);
            obj@EventSender(Tracker.NAME);
            obj@EventListener(Tracker.TRACKABLE_EXPERIMENTS_NAME);
        end
        
        function startTrackable(obj,name)
            switch name
                case obj.TRACKABLE_POSITION_NAME
                    TrackablePosition;
                otherwise
                    % This should not happen
            end
            % todo: open Tracker GUI, if it is not already open
        end
    end
    
            %% overriding from Savable
        methods(Access = protected)
            function outStruct = saveStateAsStruct(obj, category, type) %#ok<*MANU>
                % Saves the state as struct. if you want to save stuff, make
                % (outStruct = struct;) and put stuff inside. If you dont
                % want to save, make (outStruct = NaN;)
                %
                % category - string. Some objects saves themself only with
                %                    specific category (image/experimetns/etc)
                % type - string.     Whether the objects saves at the beginning
                %                    of the run (parameter) or at its end (result)
                outStruct = NaN;
                
                if ~strcmp(category, obj.CATEGORY_TRACKER)
                    return
                end
                
                switch type
                    case Savable.TYPE_PARAMS
                        % do nothing, for now
                    case Savable.TYPE_RESULTS
                        outStruct = obj.mLocalStruct;
                end
            end
    
            function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
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
    
            function string = returnReadableString(obj, savedStruct)
                % return a readable string to be shown. if this object
                % doesn't need a readable string, make (string = NaN;) or
                % (string = '');
    
                string = NaN;
            end
        end
    
        methods (Static)
            function categoryName = mCategory
                categoryName = Savable.CATEGORY_TRACKER;
            end
        end
    
        %% overridden from EventListener
        methods
            % When events happen, this function jumps.
            % event is the event sent from the EventSender
            function onEvent(obj, event)
                if isfield(event.extraInfo, Tracker.EVENT_TRACKABLE_EXP_ENDED)
                    % does 2 things: 1. saves trackable history into the
                    % tracker history. 2. Sends event that this trackable
                    % finished, and now things should happen (Main
                    % experiment can be resumed, SavLoad will autosave,
                    % etc.)
                    trackable = getObjByName(Trackable.NAME);   % Trackable.NAME == 'Experiment', but that's ok
                    trackableName = trackable.name;             % trackable.name (lowercase) == 'TrackableX', where X is the tracked property
                    obj.mLocalStruct.(trackableName) = trackable.convertHistoryToStructToSave;
                    obj.sendEventTrackerFinished; 
                end
            end
        end
    
end

