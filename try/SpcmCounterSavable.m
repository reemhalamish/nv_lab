classdef SpcmCounterSavable < EventSender & Savable
    %SPCMCOUNTER Read counts from SPCM via timer
    %   when switched on (reset), inits the vector of reads to be empty,
    %   and start a timer to read every 100ms.
    %   every time the timer clocks, a new read will be added to the
    %   vector, and EVENT_SPCM_COUNTER_UPDATED will be sent.
    %   another events needed are EVENT_SPCM_COUNTER_STARTED, EVENT_SPCM_COUNTER_RESET and
    %   EVENT_SPCM_COUNTER_STOPPED.
    %   reset - when the vector is being erased
    %   started - when the timer starts running
    %   stopped - when the timer stopps
    %   updated - when a new record joins the vector
    %
    %   there will be only ONE counter in the system. it will be initiated
    %   when Setup.init
    %   
    
    properties
        records     % vector, saves all previous scans since reset
        isOn        % logic, is in scanning mode
        integrationTimeMillisec     % float, in milliseconds
    end
    
    properties (Constant = true)
        EVENT_SPCM_COUNTER_RESET = 'SpcmCounterReset';
        EVENT_SPCM_COUNTER_STARTED = 'SpcmCounterStarted';
        EVENT_SPCM_COUNTER_UPDATED = 'SpcmCounterUpdated';
        EVENT_SPCM_COUNTER_STOPPED = 'SpcmCounterStopped';
        
        NAME = 'SpcmCounterSavable';
        INTEGRATION_TIME_DEFAULT_MILLISEC = 100;
        
        SAVABLE_RECORDS = 'records';
    end
    
    methods
        function obj = SpcmCounterSavable
            obj@EventSender(SpcmCounter.NAME);
            obj@Savable(SpcmCounter.NAME);
            obj.integrationTimeMillisec = obj.INTEGRATION_TIME_DEFAULT_MILLISEC;
            obj.records = [];
            obj.isOn = false;
        end
        
        function sendEventReset(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_RESET,true));end
        function sendEventStarted(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_STARTED,true));end
        function sendEventUpdated(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_UPDATED,true));end
        function sendEventStopped(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_STOPPED,true));end
        
        function run(obj)
            obj.isOn = true;
            obj.sendEventStarted;
            integrationTime = obj.integrationTimeMillisec;
            
            spcm = getObjByName(Spcm.NAME);
            spcm.setSPCMEnable(true);
            spcm.prepareReadByTime(integrationTime/1000);
            while obj.isOn
                temp = spcm.readFromTime;       % takes time; maybe reset in the meantime
                obj.records(end + 1) = temp;    
                obj.sendEventUpdated;
                if integrationTime ~= obj.integrationTimeMillisec
                    integrationTime = obj.integrationTimeMillisec;
                    spcm.clearTimeRead;
                    spcm.prepareReadByTime(integrationTime/1000);
                end
            end
            spcm.clearTimeRead;
            spcm.setSPCMEnable(false);
            
            obj.sendEventStopped;
        end
        
        function stop(obj)
            obj.isOn = false;
        end
        
        function reset(obj)
            obj.records = [];
            obj.sendEventReset;
        end
    end
    
    methods (Static = true)
        function init
            older = removeObjIfExists(SpcmCounterSavable.NAME);
            if isa(older, 'SpcmCounterSavable')
                older.stop;
                pause((older.integrationTimeMillisec + 1) / 1000);
                older.integrationTimeMillisec = 'older!!!';
            end
            
            newCounter = SpcmCounter;
            addBaseObject(newCounter);
        end     % Calls destructor when operated twice
    end
    
            %% overriding from Savable
        methods(Access = protected)
            function outStruct = saveStateAsStruct(obj, category) %#ok<*MANU>
                % saves the state as struct. if you want to save stuff, make
                % (outStruct = struct;) and put stuff inside. if you dont
                % want to save, make (outStruct = NaN;)
                %
                % category - string. some objects saves themself only with
                % specific category (image/experimetns/etc)
                if category == Savable.CATEGORY_IMAGE
                    outStruct = struct(obj.SAVABLE_RECORDS, obj.records);
                else
                    outStruct = NaN;
                end
            end
    
            function loadStateFromStruct(obj, savedStruct, category, subCategory) 
                % loads the state from a struct.
                % to support older versoins, always check for a value in the
                % struct before using it. view example in the first line.
                % category - a string, some savable objects will load stuff
                %            only for the 'image_lasers' category and not for
                %            'image_stages' category, for example
                % subCategory - string. could be empty string
    
                if ~strcmp(category,Savable.CATEGORY_IMAGE) || ...
                        ~strcmp(subCategory,obj.SAVABLE_RECORDS ...  % reem - the sub-category is defined in Savable, it has nothing to do with a specific object!
                        )
                    return;
                end
    
                if ~isfield(savedStruct, obj.SAVABLE_RECORDS); return; end
                obj.records = savedStruct.(obj.SAVABLE_RECORDS);
            end
    
            function string = returnReadableString(obj, savedStruct)
                % return a readable string to be shown. if this object
                % doesn't need a readable string, make (string = NaN;) or
                % (string = '');
    
                string = NaN;
                
                if isfield(savedStruct, obj.SAVABLE_RECORDS)
                    string = sprintf('SPCM Counter: %s records', length(obj.records));
                end
                
                % reem - awesome. this is exactly what we want.
            end
        end
end