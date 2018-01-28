classdef ViewDoubleAom < ViewVBox & EventListener
    % VIEWDOUBLEAOM A GUI component that handles a layout with two AOMs,
    % which can be switched fast from one to another
    
    % !!!!! Not Working Yet !!!!!!
    
    properties
        %%%% UI related %%%
        % AOM 1
        radioChoose1            % radio button
        edtPowerPercentage1     % edit-text
        sliderPower1            % slider
        % AOM 2
        radioChoose2            % radio button
        edtPowerPercentage2     % edit-text
        sliderPower2            % slider
        
        %%%% the laser part name (to send requests and to listen to) %%%%
        mLaserPartName
    end
    
    methods
        
        %% constructor
        function obj = ViewDoubleAom(parent, controller, laserPartPhysical)
            % parent - gui component
            % controller - the main GUI controller
            % laserPartPhysical - object of derived from LaserPartAbstract 
            % (LaserPartAbstract is in the folder Physical\Laser)
            
            %%%%%%%% init variables %%%%%%%%
            nameToListen = laserPartPhysical.name;
            
            %%%%%%%% Constructors %%%%%%%%
            obj@EventListener(nameToListen);
            obj@ViewVBox(parent, controller);
            
            %%%%%%%% the laser physics object %%%%%%%%
            obj.mLaserPartName = nameToListen;
            
            
            % UI components init
            widths = [70, 50, 150];
            rowHeight = 30;
            
            partRow1 = uix.HBox('Parent', obj.component, 'Spacing', 5);
                obj.radioChoose1 = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', partRow1, ...
                    'Callback', @obj.);
                obj.edtPowerPercentage1 = uicontrol(obj.PROP_EDIT{:}, 'Parent', partRow1);
                obj.sliderPower1 = uicontrol(obj.PROP_SLIDER{:}, 'Parent', partRow1);
                partRow1.Widths = widths;
                
            partRow2 = uix.HBox('Parent', obj.component, 'Spacing', 5);
                obj.radioChoose2 = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', partRow2, ...
                    'Callback', @obj.);
                obj.edtPowerPercentage2 = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', partRow2, 'Callback', @obj.sliderPowerCallback);
                obj.sliderPower2 = uicontrol(obj.PROP_SLIDER{:}, ...
                    'Parent', partRow2, 'Callback', @obj.edtPowerPercentageCallback);
                partRow2.Widths = widths;
            
            %%%%%%%% UI components set values  %%%%%%%%
            obj.width = sum(widths) + 20;
            obj.height = 2*rowHeight + 20;            
            
            obj.refresh();
        end
        
        
        %%%% Callbacks %%%%
        function edtPowerPercentageCallback(obj, ~, ~)
            newValue = obj.edtPowerPercentage.String;
            newValue = cell2mat(regexp(newValue,'^-?\d+','match'));  % leave only digits (maybe proceeded by a minus sign)
            newValue = str2double(newValue);
            obj.requestNewValue(newValue);
        end
        
        function sliderPowerCallback(obj, ~, ~)
            newValue = get(obj.sliderPower,'Value');
            % newValue now is in [0, 1]
            obj.requestNewValue(round(newValue * 100));
        end
        
        function cbxEnabledCallback(obj, ~, ~)
            obj.requestNewEnabled(get(obj.cbxEnabled, 'Value'));
        end
        
    end
    
    methods (Access = protected)
        
        function refresh(obj)
            obj.setValueInternally(obj.laserPart.currentValue);
            obj.setEnabledInternally(obj.laserPart.isEnabled);
        end
        
        % Internal setter for the new value
        function out = setValueInternally(obj, newLaserValue)
            % newLaserValue - double. Between [0,100]
            set(obj.edtPowerPercentage, 'String', strcat(num2str(newLaserValue),'%'));
            set(obj.sliderPower, 'Value', newLaserValue/100);
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
            obj.laserPart.setNewValue(newValue);
            % If the physics got our change - it will send an event to notify us
            % If not, it will send an error Event to notify us
        end
        
        function requestNewEnabled(obj, newBoolValue)
            obj.laserPart.setEnabled(newBoolValue);
            % If the physics got our change - it will send an event to notify us
            % If not, it will send an error Event to notify us
        end
    end
    
    %% Overriding methods!
    methods
        function onEvent(obj, event) %#ok<INUSD>
            % We don't need the event details. we can ask the details directly from the laser!
            obj.refresh();
        end
    end
    
end

