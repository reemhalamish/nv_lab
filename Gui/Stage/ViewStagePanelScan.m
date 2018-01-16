classdef ViewStagePanelScan < GuiComponent & EventListener
    %VIEWSTAGESCANSCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        btnScan             % the Holy Main Button!
        btnStopScan         % button
        cbxContinuous       % checkbox
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
            panelScan = uix.Panel('Parent', parent.component,'Title', 'Scan', 'Padding', 5);
            vboxMain = uix.VBox('Parent', panelScan, 'Spacing', 5, 'Padding', 0);
            
            obj.btnScan = uicontrol(obj.PROP_BUTTON_BIG_GREEN{:}, 'Parent', vboxMain, 'String', 'Scan');
            obj.btnStopScan = uicontrol(obj.PROP_BUTTON_BIG_RED{:},'Parent', vboxMain,'String', 'Stop Scan');
            hboxPixelTime = uix.HBox('Parent', vboxMain, 'Spacing', 3, 'Padding', 0);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxPixelTime, 'String', 'Pixel time', 'FontSize', 8);
            obj.edtPixelTime = uicontrol(obj.PROP_EDIT{:}, 'Parent', hboxPixelTime);
            hboxPixelTime.Widths = [-3 -2];
            
            % Get scan speed parameters from stage
            stage = getObjByName(obj.stageName);
            fastScannable = stage.hasFastScan;
            slowScannable = stage.hasSlowScan;
            enable = BooleanHelper.boolToOnOff(fastScannable && slowScannable);
            value = fastScannable;      % If fast scan is implemented, it is the default
            
            % Create checkboxes
            obj.cbxContinuous = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', vboxMain, 'String', 'Continuous');
            obj.cbxFastScan = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', vboxMain, 'String', 'Fast Scan', 'Enable', enable, 'Value', value);
            obj.cbxAutoSave = uicontrol(obj.PROP_CHECKBOX{:}, 'Parent', vboxMain, 'String', 'Auto-Save');
            
            vboxMain.Heights = [-3 -3 -3 -2 -2 -2];
            
            %%%% callbacks %%%%
            obj.cbxAutoSave.Callback = @(h,e) obj.cbxAutoSaveCallback;
            obj.cbxContinuous.Callback = @(h,e) obj.cbxContCallback;
            obj.cbxFastScan.Callback = @(h,e) obj.cbxFastScanCallback;
            obj.edtPixelTime.Callback = @(h,e) obj.edtPixelTimeCallback;
            obj.btnScan.Callback = @(h,e) obj.btnScanCallback;
            obj.btnStopScan.Callback = @(h,e) obj.btnStopScanCallback;
            
            %%%% internal values %%%%
            obj.height = 215;
            obj.width = 120;
            obj.refresh();  % init values
        end
        
        
        function refresh(obj)
            stage = getObjByName(obj.stageName);
            scanParams = stage.scanParams;
            obj.cbxAutoSave.Value = scanParams.autoSave;
            obj.cbxContinuous.Value = scanParams.continuous;
            obj.cbxFastScan.Value = scanParams.fastScan;
            obj.edtPixelTime.String = StringHelper.formatNumber(scanParams.pixelTime);
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
            scanParams.continuous = obj.cbxContinuous.Value;
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
            if ~ValidationHelper.isValuePositive(obj.edtPixelTime.String)
                obj.edtPixelTime.String = StringHelper.formatNumber(scanParams.pixelTime);
                EventStation.anonymousError('"Pixel time" has to be a positive number! Reverting.');
            end
            scanParams.pixelTime = str2double(obj.edtPixelTime.String);
            stage.sendEventScanParamsChanged();
        end
        
        function btnScanCallback(obj)
            scanner = getObjByName(StageScanner.NAME);
            scanner.switchTo(obj.stageName);
            obj.btnScan.Enable = 'off'; % Can't be pressed while scan is running
            scanner.startScan();
            obj.btnScan.Enable = 'on';
        end
        function btnStopScanCallback(obj)
            scanner = getObjByName(StageScanner.NAME);
            scanner.stopScan();
            obj.btnScan.Enable = 'on';  % If scan was aborted by error
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if event.isError || isfield(event.extraInfo, ClassStage.EVENT_SCAN_PARAMS_CHANGED)
                obj.refresh();
            end
        end
    end
end

