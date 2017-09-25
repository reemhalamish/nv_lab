classdef ViewBooleanSwitch < EventListener & GuiComponent
    % VIEWLASERLASER the component in the LaserView that handles the aom
    % GUI part (in addition to another component, ViewLaserLaser which handles
    % the laser GUI part
    
    properties
        %%%% Ui related %%%
        cbxEnabled             % the check box
        
        %%%% the laser aom to send requests to %%%%
        physicsBooleanSwitch
    end
    
    methods
        
        %% constructor
        function obj = ViewBooleanSwitch(parent, controller, booleanPhysical, stringToDisplay)
            % parent - gui component
            % controller - the main GUI controller
            
            %%%%%%%% init variables %%%%%%%%
            switchNameToListen = booleanPhysical.name;
            
            %%%%%%%% Constructors %%%%%%%%
            obj@EventListener(switchNameToListen);
            obj@GuiComponent(parent, controller);
            
            %%%%%%%% the boolean switch physics object %%%%%%%%
            obj.physicsBooleanSwitch = booleanPhysical;
                        
            %%%%%%%% Ui components init  %%%%%%%%
            parentBox = parent.component;
            obj.cbxEnabled = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', parentBox, 'string', stringToDisplay);
            obj.component = obj.cbxEnabled;
            obj.refresh();
            obj.height = 40;
            obj.width = 40;
            
            
            %%%%%%%% Ui components set callbacks  %%%%%%%%
            set(obj.cbxEnabled, 'Callback', @(h,e)obj.respondToCheckbox);
            
            
        end
        
        function respondToCheckbox(obj)
            obj.requestSwitchEnabled(get(obj.cbxEnabled, 'Value'));
        end
        
    end
    
    methods(Access = protected)
        
        function refresh(obj)
            obj.setSwitchEnabledInternally(obj.physicsBooleanSwitch.isEnabled);
        end
        
        %% internal function for changing the checkbox "enabled"
        function setSwitchEnabledInternally(obj, newBoolValue)
            set(obj.cbxEnabled, 'Value', newBoolValue);
        end % function setLaserEnabled
        

        
        %% this methods actually request stuff from the physics. carefull!
        function requestSwitchEnabled(obj, newBoolValue)
            obj.physicsBooleanSwitch.isEnabled = newBoolValue;
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

