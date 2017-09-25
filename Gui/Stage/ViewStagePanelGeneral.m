classdef ViewStagePanelGeneral < GuiComponent
    %VIEWSTAGESCANSCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        btnResetStage   % button
        cbxClosedLoop   % checkbox
        
        
        stageName           % string
    end
    
    methods
        function obj = ViewStagePanelGeneral(parent, controller, stage)
            obj@GuiComponent(parent, controller);
            obj.stageName = stage.name;
            
            %%%% panel init %%%%
            panelGeneral = uix.Panel('Parent', parent.component,'Title','General', 'Padding', 5);
            vboxMain = uix.VBox('Parent', panelGeneral, 'Spacing', 5, 'Padding', 0);
            obj.component = vboxMain;
            
            obj.btnResetStage = uicontrol(obj.PROP_BUTTON{:}, 'Parent', vboxMain, 'String', 'Reset Stage');
            obj.cbxClosedLoop = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', vboxMain, 'String', 'Closed Loop');
            
            obj.height = 100;
            obj.width = 105;
            
        end
    end
    
end

