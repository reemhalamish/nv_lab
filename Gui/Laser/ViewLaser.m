classdef ViewLaser < GuiComponent
    %VIEWLASER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        % constructor
        function obj = ViewLaser(parent, controller, laserGate)
            
            %%%%%%%% init variables %%%%%%%%
            laserAvail = laserGate.isLaserAvail();
            aomAvail = laserGate.isAomAvail();
            
            %%%%%%%% Constructors %%%%%%%%
            obj@GuiComponent(parent, controller);
            
            %%%%%%%% Ui components init  %%%%%%%%
            % boxPanel = uix.BoxPanel('Parent', parent.component, 'Title', sprintf('Laser Control - %s', laserGate.name));
            boxPanel = ViewExpandablePanel(parent, controller, sprintf('Laser Control - %s', laserGate.name));
            laserControlBox = uix.VBox('Parent', boxPanel.component, 'Spacing', 5, 'Padding', 5);
            obj.component = laserControlBox;
            
            cbxMaster = ViewBooleanSwitch(obj, controller, laserGate.aomSwitch, 'Fast AOM Enable');
            heights = [cbxMaster.height];
            width = cbxMaster.width;
            
            if (laserAvail)
                laserView = ViewLaserPart(obj, controller, laserGate.laser, 'Laser:');
                heights = [heights, laserView.height];
                width = max(width, laserView.width);
            end
            
            if (aomAvail)
                aomView = ViewLaserPart(obj, controller, laserGate.aom, 'AOM:');
                heights = [heights, aomView.height];
                width = max(width, aomView.width);
            end
            
            
            %%%%%%%% Ui components set values  %%%%%%%%
            set(laserControlBox, 'Heights', heights);
            obj.width = width + 20;
            obj.height = sum(heights) + 5 * length(heights) + 30;
            
        end % constructor
    end  % methods
end

