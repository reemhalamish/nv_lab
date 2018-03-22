classdef ViewLaserPart < ViewHBox & EventListener
    % VIEWLASERLASER GUI component that handles a laser part
    % could be the aom controller for the laser, or the laser source controller
    properties
        %%%% UI related %%%
        cbxEnabled             % check box
        edtPowerPercentage     % edit-text
        sliderPower            % slider
        
        %%%% properties of the laser %%%%
        mLaserPartName
        minValue
        maxValue
        units
    end
    
    properties (Constant)
        SIGNIFICANT_DIGITS = 2
        
        WIDTHS = [70, 50, 180]
        ROW_HEIGHT = 30
    end
    
    methods
        % constructor
        function obj = ViewLaserPart(parent, controller, laserPartPhysical, nameToDisplay)
            % parent - gui component
            % controller - the main GUI controller
            % laserPartPhysical - object of derived from LaserPartAbstract 
            % (LaserPartAbstract is in the folder Physical\Laser)
            
            %%%% init variables %%%%
            nameToListen = laserPartPhysical.name;
            
            %%%% Constructors %%%%
            obj@EventListener(nameToListen);
            obj@ViewHBox(parent, controller);
            
            %%%% the laser physics object %%%%
            obj.mLaserPartName = nameToListen;
            obj.minValue = laserPartPhysical.minValue;
            obj.maxValue = laserPartPhysical.maxValue;
            obj.units = laserPartPhysical.units;
            
            % UI components init
            partRow = obj.component;
            partRow.Spacing = 5;            
            
%             label = uicontrol('Parent', partRow, obj.PROP_LABEL{:}, 'String', nameToDisplay); % obj.headerProps got by inheritance from GuiComponent %
%             labelWidth = obj.getWidth(label);
            
            obj.cbxEnabled = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', partRow, ...
                'String', nameToDisplay, ...
                'Callback', @obj.cbxEnabledCallback);
            obj.edtPowerPercentage = uicontrol(obj.PROP_EDIT{:}, 'Parent', partRow);
            obj.sliderPower = uicontrol(obj.PROP_SLIDER{:}, 'Parent', partRow, ...
                'Min', obj.minValue, 'Max', obj.maxValue);
            
            set(partRow, 'Widths', obj.WIDTHS);
            
            
            %%%% UI components set values  %%%%
            obj.width = sum(obj.WIDTHS) + 20;
            obj.height = obj.ROW_HEIGHT;            
            
            
            % Set functionality for "setEnabled" and "setValue" %%%%
            if ~laserPartPhysical.canSetEnabled
                obj.cbxEnabled.Enable = 'off';
            end
            
            if laserPartPhysical.canSetValue
                set(obj.sliderPower, 'Callback', @obj.sliderPowerCallback, ...
                    'Visible', 'on');
                set(obj.edtPowerPercentage, 'Callback', @obj.edtPowerPercentageCallback, ...
                    'Enable', 'on');
            else
                obj.sliderPower.Enable = 'off';
                obj.edtPowerPercentage.Enable = 'off';
            end
            
            obj.refresh();
        end
        
        
        %%%% Callbacks %%%%
        function edtPowerPercentageCallback(obj, ~, ~)
            newValue = obj.edtPowerPercentage.String;
            newValue = regexp(newValue, '^-?\d+(\.\d+)?', 'match', 'once');  % leave only digits (maybe with decimal point or proceeded by a minus sign)
            obj.requestNewValue(str2double(newValue));
        end
        
        function sliderPowerCallback(obj, ~, ~)
            newValue = get(obj.sliderPower, 'Value');
            obj.requestNewValue(newValue);
        end
        
        function cbxEnabledCallback(obj, ~, ~)
            obj.requestNewEnabled(get(obj.cbxEnabled, 'Value'));
        end
        
    end
    
    methods (Access = protected)
        
        function refresh(obj)
            % Get values from laser part
            value = obj.laserPart.value;
            tf = obj.laserPart.isEnabled;
            % Update in GUI
            obj.setValueInternally(value);
            obj.setEnabledInternally(tf);
        end
        
        % Internal setter for the new value
        function out = setValueInternally(obj, newLaserValue)
            % newLaserValue - double.
            newValString = num2str(newLaserValue);
            set(obj.edtPowerPercentage, 'String', strcat(newValString, obj.units));
            set(obj.sliderPower, 'Value', newLaserValue);
            out = true;
        end
        
        % Internal function for changing the checkbox "enabled"
        function setEnabledInternally(obj, newBoolValueEnabled)
            set(obj.cbxEnabled, 'Value', newBoolValueEnabled);
        end % function setLaserEnabled
		
		function laserPartObject = laserPart(obj)
			% get the laser part
			laserPartObject = getObjByName(obj.mLaserPartName);
		end
        
    end  % methods
    
    %% These methods actually request stuff from the physics. Carefull!
    methods (Access = protected)
        function requestNewValue(obj, newValue)
            % newValue - double. Already in proper units
            obj.laserPart.value = round(newValue, obj.SIGNIFICANT_DIGITS);
            
            % If the physics got our change - it will send an event to notify us
            % If not, it will send an error Event to notify us
            pause(0.05)         % todo: do it better (uiwait)
        end
        
        function requestNewEnabled(obj, newBoolValue)
            obj.laserPart.isEnabled = newBoolValue;
            % If the physics got our change - it will send an event to notify us
            % If not, it will send an error Event to notify us
            pause(0.05)         % todo: do it better (uiwait)
        end
    end
    
    %% Overridden from EventListener
    methods
        function onEvent(obj, event) %#ok<INUSD>
            % We don't need the event details -- we can ask for what we
            % need directly from the laser!
            obj.refresh();
        end
    end
    
end

