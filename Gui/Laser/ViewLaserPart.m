classdef ViewLaserPart < ViewHBox & EventListener
    % VIEWLASERLASER GUI component that handles a laser part
    % could be the aom or a laser
    properties
        %%%% Ui related %%%
        cbxEnabled             % the check box
        edtPowerPercentage     % the edit text
        sliderPower            % the slider
        
        %%%% the laser part to send requests to %%%%
        laserPart
    end
    
    methods
        
        %% constructor
        function obj = ViewLaserPart(parent, controller, laserPartPhysical, nameToDisplay)
            % parent - gui component
            % controller - the main GUI controller
            % laserPartPhysical - object of type LaserPartAbstract 
            % (LaserPartAbstract is in the folder Physical\Laser)
            
            %%%%%%%% init variables %%%%%%%%
            nameToListen = laserPartPhysical.name;
            
            %%%%%%%% Constructors %%%%%%%%
            obj@EventListener(nameToListen);
            obj@ViewHBox(parent, controller);
            
            %%%%%%%% the laser physics object %%%%%%%%
            obj.laserPart = laserPartPhysical;
            
            %%%%%%%% Ui components init  %%%%%%%%            
            partRow = obj.component;
            partRow.Spacing = 5;            
            
%             label = uicontrol('Parent', partRow, obj.PROP_LABEL{:}, 'String', nameToDisplay); % obj.headerProps got by inheritance from GuiComponent %
%             labelWidth = obj.getWidth(label);
            
            obj.cbxEnabled = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', partRow, 'string', 'Enable');
            obj.edtPowerPercentage = uicontrol(obj.PROP_EDIT{:}, 'Parent', partRow);
            obj.sliderPower = uicontrol(obj.PROP_SLIDER{:}, 'Parent', partRow);
            
            widths = [70, 50, 150];
            set(partRow, 'Widths', widths);
            
            
            %%%%%%%% Ui components set values  %%%%%%%%
            obj.width = sum(widths) + 20;
            obj.height = 30;            
            
            %%%%%%%% set callbacks for "setEnabled" and "setValue" %%%%%%%%
            
            if (laserPartPhysical.canSetEnabled())
                set(obj.cbxEnabled, 'Callback', @(h,e)obj.respondToCheckbox); 
            else
                set(obj.cbxEnabled, 'Enable', 'off');
            end
            
            if (laserPartPhysical.canSetValue())
                set(obj.sliderPower, 'Callback', @(h,e)obj.respondToSlider);
                set(obj.edtPowerPercentage, 'Callback', @(h,e)obj.respondToEdit);
                set(obj.sliderPower, 'visible', 'on');
                set(obj.edtPowerPercentage, 'enable', 'on');
            else
                set(obj.sliderPower, 'enable', 'off');
                set(obj.edtPowerPercentage, 'enable', 'off');
            end
            
            obj.refresh();
        end
        
        function respondToEdit(obj)
            newValue = get(obj.edtPowerPercentage, 'String');
            newValue = cell2mat(regexp(newValue,'^-?\d+','match'));  % leave only digits (maybe proceeded by a minus sign)
            newValue = str2double(newValue);
            obj.requestNewValue(newValue);
        end
        
        function respondToSlider(obj)
            newValue = get(obj.sliderPower,'Value');
            % newValue now is in [0, 1]
            obj.requestNewValue(round(newValue * 100));
        end
        
        function respondToCheckbox(obj)
            obj.requestNewEnabled(get(obj.cbxEnabled, 'Value'));
        end
        
    end
    
    methods(Access = protected)
        
        function refresh(obj)
            obj.setValueInternally(obj.laserPart.currentValue);
            obj.setEnabledInternally(obj.laserPart.isEnabled);
        end
        
        %% internal setter for the new value
        % newLaserValue is a number between [0,100]
        function out = setValueInternally(obj, newLaserValue)
            set(obj.edtPowerPercentage, 'String', strcat(num2str(newLaserValue),'%'));
            set(obj.sliderPower, 'Value', newLaserValue/100);
            out = true;
        end
        
        %% internal function for changing the checkbox "enabled"
        function setEnabledInternally(obj, newBoolValueEnabled)
            set(obj.cbxEnabled, 'Value', newBoolValueEnabled);
        end % function setLaserEnabled
        
        %% this methods actually request stuff from the physics. carefull!
        function requestNewValue(obj, newValue)
            obj.laserPart.setNewValue(newValue);
            % if the physics got our change - it will send an event to notify us
            % if not, it will send an error Event to notify us
        end
        
        %% this methods actually request stuff from the physics. carefull!
        function requestNewEnabled(obj, newBoolValue)
            obj.laserPart.setEnabled(newBoolValue);
            % if the physics got our change - it will send an event to notify us
            % if not, it will send an error Event to notify us
        end
        
    end  % methods
    
    %% overriding methods!
    methods
        function out = onEvent(obj, event) %#ok<*INUSD,*INUSL>
            % we don't need the event details. we can ask the details directly from the laser!
            obj.refresh();
            out = true;
        end
    end
    
end

