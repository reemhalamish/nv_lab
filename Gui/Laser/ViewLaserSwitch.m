classdef ViewBooleanSwitch < PhysicsListener & GuiComponent
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
        function obj = ViewBooleanSwitch(parent, controller, booleanPhysics)
            % parent - gui component
            % controller - the main GUI controller
            
            %%%%%%%% init variables %%%%%%%%
            switchNameToListen = booleanPhysics.name;
            
            %%%%%%%% Constructors %%%%%%%%
            obj@PhysicsListener(switchNameToListen);
            obj@GuiComponent(parent, controller);
            
            %%%%%%%% the laser physics object %%%%%%%%
            obj.physicsBooleanSwitch = booleanPhysics;
            
            %%%%%%%% Ui components init  %%%%%%%%
            parentBox = parent.component;
            
            obj.cbxEnabled = uicontrol(obj.checkboxProps{:}, 'Parent', parentBox, 'string', 'Fast Enable');
            
            %%%%%%%% Ui components set values  %%%%%%%%
            obj.width = 150;
            obj.height = 20;
            
            obj.refresh();
            
            
            %%%%%%%% Ui components set callbacks  %%%%%%%%
            set(obj.cbxEnabled, 'Callback', @(h,e)obj.respondToCheckbox);
            
            
        end
        
        function respondToCheckbox(obj)
            obj.requestaomSwitchNewEnabled(get(obj.cbxAomEnabled, 'Value'));
        end
        
    end
    
    methods(Access = protected)
        
        function refresh(obj)
            obj.setAomSwitchEnabledInternally(obj.aomSwitch.isEnabled);
        end
        
        %% internal function for changing the checkbox "enabled"
        function setAomSwitchEnabledInternally(obj, newBoolValue)
            set(obj.cbxaomSwitchSwitchEnabled, 'Value', newBoolValue);
        end % function setLaserEnabled
        
        %% this methods actually request stuff from the physics. carefull!
        function requestaomSwitchNewValue(obj, newValue)
            obj.aomSwitch.setNewValue(newValue);
            % if the physics got our change - it will send an event to notify us
            % if not, it will send an error Event to notify us
        end
        
        %% this methods actually request stuff from the physics. carefull!
        function requestaomSwitchNewEnabled(obj, newBoolValue)
            obj.aomSwitch.setEnabled(newBoolValue);
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
        
        % overriding
        function out = getHeights(obj) %#ok<*MANU>
            out = [40 40];
        end
        
        % overriding
        function out = getWidths(obj) %#ok<*MANU>
            out = obj.width;
        end
    end
    
end

