classdef AomNiDaqControlledDouble < SwitchPbControlled
    %AOMNIDAQCONTROLLED handle to layout with two AOMs
    
    properties
        niDaqAomOne     % AomNiDaqControlled
        niDaqAomTwo     % AomNiDaqControlled
        pbChannel       % integer
    end
    
    properties(Constant)
        NEEDED_FIELDS = {'channelOne', 'channelTwo', 'channelSwitch'};
        OPTOINAL_FIELDS = {'currentChannel'}
    end
    
    methods
        % constructor
        function obj = AomNiDaqControlledDouble(name, channelOne, channelTwo)
            obj@SwitchPbControlled(pbChannel);
            obj.niDaqAomOne = AomNiDaqControlled(name, channelOne);
            obj.niDaqAomTwo = AomNiDaqControlled(name, channelTwo);
        end
    end
    
    methods(Static)
        function obj = create(laserName, jsonStruct)
            missingField = FactoryHelper.usualChecks(struct, AomNiDaqControlledDouble.STRUCT_NEEDED_FIELDS);
            if ~isnan(missingField)
                errorMsg = 'Error while creating a PbControlled object (name: "%s"), missing field! (field missing: "%s")';
                error(errorMsg, laserName, missingField);
            end
            
            name = sprintf('%s channel switch', laserName);
            pbControlled = SwitchPbControlled(name, struct.switchChannel);
            
            % check for optional field "currentChannel" and set it correctly
            if isnan(FactoryHelper.usualChecks(struct, AomNiDaqControlledDouble.OPTOINAL_FIELDS))
                % usualChecks() returning nan means everything ok
                switch struct.currentChannel
                    case {1, '1', 'one'}
                        trueforOneFalseForTwo = true;
                    case {2, '2', 'two'}
                        trueforOneFalseForTwo = false;
                end
                 
                pbControlled.isEnabled = trueforOneFalseForTwo;
            end
            
            niDaqChannelOne = jsonStruct.channelOne;
            niDaqChannelTwo = jsonStruct.channelTwo;
            obj = AomNiDaqControlled(name, niDaqChannelOne, niDaqChannelTwo);
        end
    end
    
     %% Overridden from EventListener
    methods
        % event is the event sent from the EventSender
        function onEvent(obj, event) %#ok<INUSD>
            pb = getObjByName(PulseBlaster.NAME);
            trueforOneFalseForTwo = pb.isOn(obj.name);
            if trueforOneFalseForTwo ~= obj.isEnabled
                obj.isEnabled = trueforOneFalseForTwo;
                currentChannel = BooleanHelper.ifTrueElse(trueforOneFalseForTwo,1,2);
                obj.sendEvent(struct('currentChannel', currentChannel));
            end
        end
    end
    
end