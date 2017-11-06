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
        DEFAULT_EMPTY_STRUCT = struct('time',0,'kcps',NaN,'std',NaN);
        ZERO_STRUCT = struct('time',0,'kcps',0,'std',0);
    end
    
    methods
        function obj = SpcmCounter
            obj@EventSender(SpcmCounter.NAME);
            obj.integrationTimeMillisec = obj.INTEGRATION_TIME_DEFAULT_MILLISEC;
            obj.records = obj.DEFAULT_EMPTY_STRUCT;
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
                % creating data to be saved
                [kcps,std] = spcm.readFromTime;
                %%%% replace with obj.newRecord(time,kcps,std)
                    time = obj.records(end).time + integrationTime/1000;
                    obj.records(end + 1) = struct('time',time,'kcps',kcps,'std',std);
                %%%% (upto here)
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
            obj.records = obj.DEFAULT_EMPTY_STRUCT;
            obj.sendEventReset;
        end
        
        function newRecord(obj,time,kpcs,std) %#ok<INUSD>
            % creates new record in a struct of the type "record" =
            % record.{time,kcps,std}, with proper validation.
        end
        
        function [time,kcps,std] = getRecords(obj,lenOpt)
            lenRecords = length(obj.records);
            if ~exist('lenOpt','var')
                lenOpt = lenRecords;
            end
            
            difference = lenRecords - lenOpt;
            if difference < 0
                padding = abs(difference) - 1;
                maxTime = lenOpt*obj.integrationTimeMillisec/1000;  % Create time for end of wrap
                zeroStruct = struct('time', maxTime, 'kcps', 0, 'std', 0);
                data = [obj.records, ...
                    repelem(obj.DEFAULT_EMPTY_STRUCT,padding), ...
                    zeroStruct];
            elseif difference == 0
                data = obj.records;
            else
                position = difference + 1;
                data = obj.records(position:end);
            end
            
            time = [data.time];
            kcps = [data.kcps];
            std = [data.std];
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