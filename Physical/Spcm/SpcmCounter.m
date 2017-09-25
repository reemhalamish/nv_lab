classdef SpcmCounter < EventSender
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
        
        NAME = 'SpcmCounter';
        INTEGRATION_TIME_DEFAULT_MILLISEC = 100;
    end
    
    methods
        function obj = SpcmCounter
            obj@EventSender(SpcmCounter.NAME);
            obj.integrationTimeMillisec = obj.INTEGRATION_TIME_DEFAULT_MILLISEC;
            obj.records = [];
            obj.isOn = false;
        end
        
        function sendEventReset(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_RESET,true));end
        function sendEventStarted(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_STARTED,true));end
        function sendEventUpdated(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_UPDATED,true));end
        function sendEventStopped(obj); obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_STOPPED,true));end
        
        function run(obj)
            obj.isOn = true;    % redundant?
            obj.sendEventStarted;
            integrationTime = obj.integrationTimeMillisec;
            
            spcm = getObjByName(Spcm.NAME);
            spcm.setSPCMEnable(true);
            spcm.prepareReadByTime(integrationTime/1000);
            while obj.isOn
                obj.records(end + 1) = spcm.readFromTime;
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
            older = removeObjIfExists(SpcmCounter.NAME);
            if isa(older, 'SpcmCounter')
                older.stop;
                pause((older.integrationTimeMillisec + 1) / 1000);
                older.integrationTimeMillisec = 'older!!!';
            end
            
            newCounter = SpcmCounter;
            addBaseObject(newCounter);
        end     % Calls destructor when operated twice
    end
end