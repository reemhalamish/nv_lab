classdef AomDoubleNiDaqControlled < LaserPartAbstract
    %AOMDOUBLENIDAQCONTROLLED handle to layout with two AOMs
    
    properties
        canSetEnabled = false;
        canSetValue = true;     % By default, we set the value of the current active channel
    end
    
    properties (Dependent)
        activeChannel
        values
    end
    
    properties (Hidden)
        aomOne          % AomNiDaqControlled
        aomTwo          % AomNiDaqControlled
        swapSwitch      % string
    end
    
    properties (Constant)
        NEEDED_FIELDS = {'channelOne', 'channelTwo', 'swapChannelName'};
        OPTIONAL_FIELDS = {'currentChannel', 'minVal', 'maxVal'}
    end
    
    methods
        function obj = AomDoubleNiDaqControlled(laserName, pgChannelName, channelOne, channelTwo, minVal, maxVal)
            obj@LaserPartAbstract(laserName, minVal, maxVal, NiDaq.UNITS);
            
            swapperName = sprintf('%s swapper', laserName);
            NameOne = sprintf('%s channel #1', laserName);
            NameTwo = sprintf('%s channel #2', laserName);
            
            obj.swapSwitch = SwitchPgControlled(swapperName, pgChannelName);
            obj.aomOne = AomNiDaqControlled(NameOne, channelOne, minVal, maxVal);
            obj.aomTwo = AomNiDaqControlled(NameTwo, channelTwo, minVal, maxVal);
        end     % constructor
    end
       
    %% For dependent properties
    methods
        function set.activeChannel(obj, newChannel)
            % The switch swaps between controlling via AOM 1 and 2.
            % Channel 1 is active, if it's "on", and channel 2 -- if it's
            % "off"
            switch newChannel
                case {1, '1', 'one'}
                    trueforOneFalseForTwo = true;
                case {2, '2', 'two'}
                    trueforOneFalseForTwo = false;
            end
            obj.swapSwitch.isEnabled = trueforOneFalseForTwo;
        end
        function channel = get.activeChannel(obj)
            channel = BooleanHelper.ifTrueElse(obj.swapSwitch.isEnabled, 1, 2);
        end
        
        function mValues = get.values(obj)
            value1 = obj.aomOne.value;
            value2 = obj.aomTwo.value;
            mValues = [value1, value2];
        end
    end
    
    %% Overridden from LaserPartAbstract
    %%%% These functions call physical objects. Tread with caution! %%%%
    methods (Access = protected)
        function setValueRealWorld(obj, newValue)
            % Sets the voltage value in physical laser part
            switch obj.activeChannel
                case 1
                    obj.aomOne.value = newValue;
                case 2
                    obj.aomTwo.value = newValue;
            end
        end

        function value = getValueRealWorld(obj)
            % Gets the voltage value from physical laser part
            switch obj.activeChannel
                case 1
                    value = obj.aomOne.value;
                case 2
                    value = obj.aomTwo.value;
            end
        end
    end
    
    %% Factory
    methods (Static)
        function obj = create(laserName, jsonStruct)
            missingField = FactoryHelper.usualChecks(jsonStruct, AomDoubleNiDaqControlled.NEEDED_FIELDS);
            if ~isnan(missingField)
                errorMsg = 'Error while creating a Double AOM object (name: "%s"), missing field! (field missing: "%s")';
                error(errorMsg, laserName, missingField);
            end
            % We want to get either values set in json, or empty variables
            % (which will be handled by NiDaqControlled constructor):
            jsonStruct = FactoryHelper.supplementStruct(jsonStruct, AomDoubleNiDaqControlled.OPTIONAL_FIELDS);
            
            name = sprintf('%s Double AOM', laserName);
            
            niDaqChannelOne = jsonStruct.channelOne.channel;
            niDaqChannelTwo = jsonStruct.channelTwo.channel;
            swapSwitch = jsonStruct.swapChannelName;
            minVal = jsonStruct.minVal;
            maxVal = jsonStruct.maxVal;
            
            obj = AomDoubleNiDaqControlled(name, swapSwitch, ...
                niDaqChannelOne, niDaqChannelTwo, minVal, maxVal);
            
            % check for optional field "currentChannel" and set it correctly
            if ~isempty(jsonStruct.currentChannel)
                % usualChecks() returning nan means everything ok
                obj.activeChannel = jsonStruct.currentChannel;
            end
        end
    end
    
end