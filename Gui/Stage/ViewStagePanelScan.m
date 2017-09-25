classdef ViewStagePanelScan < GuiComponent & EventListener
    %VIEWSTAGESCANSCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        btnScan             % the holy main button!
        btnStopScan         % button
        cbxContinous        % checkbox
        cbxFastScan         % checkbox
        cbxAutoSave         % checkbox
        edtPixelTime        % edit text
        
        stageName           % string
    end
    methods
        function obj = ViewStagePanelScan(parent, controller, stageName)
            obj@GuiComponent(parent, controller);
            obj@EventListener(stageName);
            obj.stageName = stageName;
            
            %%%% Scan panel init %%%%
            panelScan = uix.Panel('Parent', parent.component,'Title','Scan', 'Padding', 5);
            hboxMain = uix.HBox('Parent', panelScan, 'Spacing', 5, 'Padding', 0);
            vboxFirst = uix.VBox('Parent', hboxMain, 'Spacing', 5, 'Padding', 0);
            
            %%%% scan, stop scan, pixel time %%%%
            obj.btnScan = uicontrol(obj.PROP_BUTTON_BIG_GREEN{:}, 'Parent', vboxFirst, 'String', 'Scan');
            obj.btnStopScan = uicontrol(obj.PROP_BUTTON_BIG_RED{:},'Parent', vboxFirst,'String', 'Stop Scan');
            hboxPixelTime = uix.HBox('Parent', vboxFirst, 'Spacing', 3, 'Padding', 0);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxPixelTime, 'String', 'Pixel Time', 'FontSize', 8);
            obj.edtPixelTime = uicontrol(obj.PROP_EDIT{:}, 'Parent', hboxPixelTime);
            hboxPixelTime.Widths = [-3 -2];
            vboxFirst.Heights = [-1 -1 -1];
            
            %%%% Continous FastScan AutoSave %%%%
            vboxSecond = uix.VBox('Parent', hboxMain, 'Spacing', 5, 'Padding', 0);
            obj.cbxContinous = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', vboxSecond, 'String', 'Continuous');
            obj.cbxFastScan = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', vboxSecond, 'String', 'Fast Scan');
            obj.cbxAutoSave = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', vboxSecond, 'String', 'Auto-Save');
            
            
            vboxSecond.Heights = [-1 -1 -1];
            hboxMain.Widths = [110 84];
            
            %%%% callbacks %%%%
            obj.cbxAutoSave.Callback = @(h,e) obj.cbxAutoSaveCallback;
            obj.cbxContinous.Callback = @(h,e) obj.cbxContCallback;
            obj.cbxFastScan.Callback = @(h,e) obj.cbxFastScanCallback;
            obj.edtPixelTime.Callback = @(h,e) obj.edtPixelTimeCallback;
            obj.btnScan.Callback = @(h,e) obj.btnScanCallback;
            obj.btnStopScan.Callback = @(h,e) obj.btnStopScanCallback;
            
            %%%% internal values %%%%
            obj.height = 130;
            obj.width = 215;
            obj.refresh();  % init values
        end
        
        
        function refresh(obj)
            stage = getObjByName(obj.stageName);
            scanParams = stage.scanParams;
            obj.cbxAutoSave.Value = scanParams.autoSave;
            obj.cbxContinous.Value = scanParams.continuous;
            obj.cbxFastScan.Value = scanParams.fastScan;
            obj.edtPixelTime.String = scanParams.pixelTime;
        end
        
        function cbxAutoSaveCallback(obj)
            stage = getObjByName(obj.stageName);
            scanParams = stage.scanParams;
            scanParams.autoSave = obj.cbxAutoSave.Value;
            stage.sendEventScanParamsChanged();
        end
        
        function cbxContCallback(obj)
            stage = getObjByName(obj.stageName);
            scanParams = stage.scanParams;
            scanParams.continuous = obj.cbxContinous.Value;
            stage.sendEventScanParamsChanged();
        end
        
        function cbxFastScanCallback(obj)
            stage = getObjByName(obj.stageName);
            scanParams = stage.scanParams;
            scanParams.fastScan = obj.cbxFastScan.Value;
            stage.sendEventScanParamsChanged();
        end
        
        function edtPixelTimeCallback(obj)
            stage = getObjByName(obj.stageName);
            scanParams = stage.scanParams;
            if ~ValidationHelper.isValueNonNegative(obj.edtPixelTime.String)
                obj.edtPixelTime.String = scanParams.pixelTime;
                EventStation.anonymousError('"pixel time" has to be non-negative number! reverting.');
            end
            scanParams.pixelTime = str2double(obj.edtPixelTime.String);
            stage.sendEventScanParamsChanged();
        end
        
        function btnScanCallback(obj)
            scanner = getObjByName(StageScanner.NAME);
            scanner.switchTo(obj.stageName);
            scanner.startScan();
        end
        function btnStopScanCallback(obj)
            scanner = getObjByName(StageScanner.NAME);
            scanner.stopScan();
        end
    end
    
    %% overridden from EventListener
    methods
        % when event happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if event.isError || isfield(event.extraInfo, ClassStage.EVENT_SCAN_PARAMS_CHANGED)
                obj.refresh();
            end
        end
    end
end

