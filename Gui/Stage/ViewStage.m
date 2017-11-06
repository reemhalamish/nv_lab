classdef ViewStage < ViewVBox
    %ViewStage one full box to view and control the stage
    %   consists of a couple of expandable panels:
    %   1. scan area
    %   2. movement control
    
    properties
    end
    
    methods
        function obj = ViewStage(parent, controller, stage)
            vMainPanel = ViewExpandablePanel(parent, controller, stage.name);
            obj@ViewVBox(vMainPanel, controller);
            
            %%%% ui component init %%%%
            obj.component.Spacing = 5;
            obj.component.Padding = 5;
                        
            
            % 80 tilt correction
            % 105 general
            % 215 scan
            % 320 movement ctrl
            % 391 stage limits
            % 400 scan params
            
            % 105 general
            % 320 movement ctrl
            % 391 stage limits
            
            if stage.isScanable
                hbox1row = ViewHBox(obj, controller, 0, 16);                
                vScanParams = ViewStagePanelScanParams(hbox1row, controller, stage);
                vGeneral = ViewStagePanelGeneral(hbox1row, controller, stage);
                line1 = {vScanParams, vGeneral};
                hbox1row.setWidths([line1{1}.width, -1]);
                
                
                hbox2row = ViewHBox(obj, controller, 0, 16);
                vLimits = ViewStagePanelLimits(hbox2row, controller, stage);
                vTilt = ViewStagePanelTiltCorrection(hbox2row, controller, stage);
                line2 = {vLimits, vTilt};
                hbox2row.setWidths([line2{1}.width, -1]);
                
                hbox3row = ViewHBox(obj, controller, 0, 16);
                vMovement = ViewStagePanelMovementControl(hbox3row, controller, stage);
                vScan = ViewStagePanelScan(hbox3row, controller, stage.name);
                line3 = {vMovement, vScan};
                hbox3row.setWidths([vMovement.width, vScan.width]);
                
                heights = [...
                    max(cellfun(@(p) p.height,line1)), ...
                    max(cellfun(@(p) p.height,line2)), ...
                    max(cellfun(@(p) p.height,line3)) ...
                    ];
                
                widths = [...
                    sum(cellfun(@(p) p.width,line1)) + 15 * length(line1), ...
                    sum(cellfun(@(p) p.width,line2))+ 15 * length(line2), ...
                    sum(cellfun(@(p) p.width,line3))+ 15 * length(line3) ...
                    ];
            else
                hbox1row = ViewHBox(obj, controller, 0, 16);  
                vMovement = ViewStagePanelMovementControl(hbox1row, controller, stage);
                vGeneral = ViewStagePanelGeneral(hbox1row, controller, stage);
                line1 = {vMovement, vGeneral};
                hbox1row.setWidths([-1 vGeneral.width]);
                
                hbox2row = ViewHBox(obj, controller, 0, 16);  
                vLimits = ViewStagePanelLimits(hbox2row, controller, stage);
                vTilt = ViewStagePanelTiltCorrection(hbox2row, controller, stage);
                line2 = {vLimits, vTilt};
                hbox2row.setWidths([vLimits.width, -1]);
                
                heights = [...
                    max(cellfun(@(p) p.height,line1)), ...
                    max(cellfun(@(p) p.height,line2)), ...
                    ];
                
                widths = [...
                    sum(cellfun(@(p) p.width,line1)) + 15 * length(line1), ...
                    sum(cellfun(@(p) p.width,line2))+ 15 * length(line2), ...
                    ];
            end
                  
            
            %%%% init internal settings %%%%
            obj.setHeights(heights);
            obj.height = sum(heights) + 35;
            obj.width = max(widths);
        end
    end
    
end

