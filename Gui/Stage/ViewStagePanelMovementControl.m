classdef ViewStagePanelMovementControl < GuiComponent & EventListener
    %VIEWSTAGESCANSCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        btnMoveLeft         % 1x3 button
        btnMoveRight        % 1x3 button
        btnMoveStageToFixedPos  % button
        
        btnSendToFixed      % button
        btnMoveToBlue       % button
        % only one of those two ^ will be displayed
        
        edtSteps            % edit-text 
        btnHaltStage        % button
        cbxJoystick         % checkbox

        tvCurPos            % 1x3 text-view for current position
        edtCurPos           % 1x3 edit-input for current position input
        hboxCurPos          % 1x3 vbox that holds those ^ 2 views
        
        edtCurPosValue      % 1x3 double that holds the values in edtCurPos. 
                            % when an edt is visible, this always holds the
                            % numeric value shown. if it's invisible, this
                            % always stores Infinity
        
        stageName           % string
        stageAxes           % string. example: "xy"    end
    end
    
    methods
        function obj = ViewStagePanelMovementControl(parent, controller, stage)
            obj@GuiComponent(parent, controller);
            obj@EventListener(stage.name);
            obj.stageName = stage.name;
            obj.stageAxes = stage.availableAxes;
            axesLen = length(obj.stageAxes);
            
            %%%% panel init %%%%
            panelMain = uix.Panel('Parent', parent.component,'Title','Movement Control', 'Padding', 5);
            hboxMain = uix.HBox('Parent', panelMain, 'Spacing', 25, 'Padding', 0);
            vboxLeft = uix.VBox('Parent',hboxMain, 'Spacing', 6); % will contain the grid and "step"
            
            
            %%%% step %%%%
            hboxStep = uix.HBox('Parent', vboxLeft, 'Spacing', 5);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', hboxStep, 'String', 'Step:');
            obj.edtSteps = uicontrol(obj.PROP_EDIT{:}, 'Parent', hboxStep);
            hboxStep.Widths = [-1 -1];
            stepHeightNoSpacing = 25;
            
            
            %%%% the left side grid %%%%
            gridLeftSide = uix.Grid('Parent', vboxLeft, 'Spacing', 5);
            
            % 1st column: xyz labels
            for i = 1: axesLen
                uicontrol(obj.PROP_LABEL{:}, 'Parent', gridLeftSide, 'String', upper(obj.stageAxes(i)));
            end
            
            % 2nd column: arrow left
            obj.btnMoveLeft = gobjects(1, axesLen);
            for i = 1: axesLen
                obj.btnMoveLeft(i) = uicontrol(obj.PROP_BUTTON{:}, ...
                    'Parent', gridLeftSide, ...
                    'String', '¬', ...
                    'FontName', 'Symbol', ...
                    'FontSize', 20);
            end
            
            % 3rd column: current position
            obj.tvCurPos = gobjects(1, axesLen);
            obj.edtCurPos = gobjects(1, axesLen);
            obj.hboxCurPos = gobjects(1, axesLen);
            obj.edtCurPosValue = inf * ones(1, axesLen);
            enableEdt = ~stage.isScanable;
            % ^ only enable if stage is not scanable
            for i = 1: axesLen
                obj.hboxCurPos(i) = uix.HBox('Parent', gridLeftSide, 'Padding', 0, 'Spacing', 0);
                obj.tvCurPos(i) = uicontrol(obj.PROP_EDIT{:},'Parent', obj.hboxCurPos(i), 'Enable', BooleanHelper.boolToOnOff(enableEdt));
                obj.edtCurPos(i) = uicontrol(obj.PROP_EDIT{:},'Parent', obj.hboxCurPos(i), 'ForegroundColor', 'blue');
                obj.showEdtCurPos(i, false);   % hide the edit-input until it's needed - when user inputs data
            end
            
            % 4th column: arrow right
            obj.btnMoveRight = gobjects(1, axesLen);
            for i = 1: axesLen
                obj.btnMoveRight(i) = uicontrol(obj.PROP_BUTTON{:}, ...
                    'Parent', gridLeftSide, ...
                    'String', '®', ...
                    'FontName', 'Symbol', ...
                    'FontSize', 20);
            end
            
            if enableEdt
                gridWidths = [20 35 70 35];
            else
                gridWidths = [20 35 50 35];
            end
            gridWithdsRel = -gridWidths;
            heightGridTotalNoSpacing = 90;
            lineHeight = heightGridTotalNoSpacing / axesLen;
            gridHeights = lineHeight * ones(1, axesLen);
            set(gridLeftSide, 'Widths', gridWithdsRel, 'Heights', gridHeights);
            gridLeftHeightTotal = heightGridTotalNoSpacing + 5 * axesLen;
            gridLeftWidthTotal = sum(gridWidths) + 4 * length(gridWidths);
            
            %%%% vbox left - all inner components are ready %%%%
            vboxLeft.Heights = [stepHeightNoSpacing heightGridTotalNoSpacing+10];
            vboxLeftHeightTotal = gridLeftHeightTotal + stepHeightNoSpacing + 42;
            
            
            %%%% buttons (fix, query, halt) & joystick %%%%
            vboxRight = uix.VBox('Parent',hboxMain, 'Spacing', 6);
            if enableEdt        % Stage is not scannable
                obj.btnMoveToBlue = uicontrol(obj.PROP_BUTTON{:}, ...
                    'Parent', vboxRight, ...
                    'String', 'Move To Blue', ...
                    'Enable', 'off');   % the starting state - off
                heights = [-2 -2];
                joystickHeight = -1;    % if it is available
            else
                obj.btnMoveStageToFixedPos = uicontrol(obj.PROP_BUTTON{:}, ...
                    'Parent', vboxRight, ...
                    'String', sprintf('Fixed %s Current', StringHelper.RIGHT_ARROW), ...
                    'TooltipString', 'Move stage to the fixed position');
                obj.btnSendToFixed = uicontrol(obj.PROP_BUTTON{:}, ...
                    'Parent', vboxRight, ...
                    'String', sprintf('Current %s Fixed', StringHelper.RIGHT_ARROW), ...
                    'TooltipString', 'Set fixed position to actual stage position');
                heights = [-5 -5 -5];
                joystickHeight = -1;    % if it is available
            end
            obj.btnHaltStage = uicontrol(obj.PROP_BUTTON_BIG_RED{:}, ...
                'Parent', vboxRight, ...
                'String', 'Halt Stages');
            if stage.hasJoystick
                obj.cbxJoystick = uicontrol(obj.PROP_CHECKBOX{:}, ...
                    'Parent', vboxRight, ...
                    'String', 'Joystick');
                heights = [heights joystickHeight];
            end
            vboxRight.Heights = heights;
            rightSideTotalWidth = 120;
            
            %%%% set mainHbox widths %%%%
            widthsMain = [gridLeftWidthTotal, rightSideTotalWidth];
            widthsRelative = widthsMain * -1 ;
            hboxMain.Widths = widthsRelative;
            
            %%%% callbacks %%%%
            obj.edtSteps.Callback = @(h,e) obj.edtStepSizeCallback();
            obj.btnMoveStageToFixedPos.Callback = @(h,e) obj.btnMoveStageToFixedPosCallback();
            obj.btnHaltStage.Callback = @(h,e) StageControlEvents.sendHalt;
            
            if enableEdt
                obj.btnMoveToBlue.Callback = @(h,e) obj.btnMoveToBlueCallback();
                for i = 1 : axesLen
                    obj.tvCurPos(i).Callback = @(h,e) obj.tvCurPosCallback(i);
                    obj.edtCurPos(i).Callback = @(h,e) obj.checkEdtCurPosValue(i);
                end
            else
                obj.btnSendToFixed.Callback = @(h,e) obj.btnSendToFixedNonScanableCallback();
            end
            
            for i = 1:axesLen
                isLeft = true;
                obj.btnMoveLeft(i).Callback = @(h,e) obj.btnMoveCallback(i,isLeft);
                obj.btnMoveRight(i).Callback = @(h,e) obj.btnMoveCallback(i,~isLeft);
            end
            
            
            %%%% internal values %%%%
            obj.width = sum(widthsMain) + (hboxMain.Spacing -3) * length(widthsMain);
            obj.height = vboxLeftHeightTotal;
            
            obj.refresh();
        end
        
        function refresh(obj)
            stage = getObjByName(obj.stageName);
            
            obj.edtSteps.String = StringHelper.formatNumber(stage.stepSize);
            currentPosition = stage.Pos(obj.stageAxes);
            for i = 1: length(obj.stageAxes)
                obj.tvCurPos(i).String = StringHelper.formatNumber(currentPosition(i));
            end
        end
        
        function edtStepSizeCallback(obj)
            stepSizeString = obj.edtSteps.String;
            stage = getObjByName(obj.stageName);
            try
                if ~ValidationHelper.isStringValueANumber(stepSizeString)
                    error('Step size must be a valid number! Reverting.');
                end
                if ~ValidationHelper.isStringValueInBorders(stepSizeString, stage.STEP_MINIMUM_SIZE, inf)
                    error('step size must be >= minimum step-size! reverting.\nminimum step-size: %d, wanted step size: %s', stage.STEP_MINIMUM_SIZE, stepSizeString);
                end
            catch err
                obj.edtSteps.String = StringHelper.formatNumber(stage.stepSize);
                EventStation.anonymousError(err.message);
            end
            
            stage.stepSize = str2double(stepSizeString);
        end
        
        function btnMoveCallback(obj,index,trueForLeftFalseForRight)
            axis = ClassStage.getAxis(obj.stageAxes(index));
            stage = getObjByName(obj.stageName);
            step = BooleanHelper.ifTrueElse(trueForLeftFalseForRight,-1,1)*stage.stepSize;
            stage.relativeMove(axis,step);
        end
        
        function btnMoveStageToFixedPosCallback(obj)
            stage = getObjByName(obj.stageName);
            stage.moveByScanParams();
        end
        
        function btnSendToFixedNonScanableCallback(obj)
            stage = getObjByName(obj.stageName);
            stage.sendPosToScanParams();
        end
        
        function btnMoveToBlueCallback(obj)
            stage = getObjByName(obj.stageName);
            isBeingGrayed = true;
            for i = 1 : length(obj.stageAxes)
                obj.btnMoveLeft(i).Enable = 'off';
                obj.recolor(obj.tvCurPos(i),isBeingGrayed)
                obj.btnMoveRight(i).Enable = 'off';
            end
            
            for i = 1 : length(obj.stageAxes)
                axis = ClassStage.getAxis(obj.stageAxes(i));
                pos = obj.edtCurPosValue(i); 
                if pos ~= inf
                    stage.move(axis, pos);
                    obj.clearEdtCurPos(i);
                end 
            end
            
            isBeingGrayed = false;
            for i = 1 : length(obj.stageAxes)
                obj.btnMoveLeft(i).Enable = 'on';
                obj.recolor(obj.tvCurPos(i),isBeingGrayed)
                obj.btnMoveRight(i).Enable = 'on';
            end
            obj.btnMoveToBlue.Enable = 'off';
        end
        
        function tvCurPosCallback(obj, index)
            axis = ClassStage.getAxis(obj.stageAxes(index));
            stage = getObjByName(obj.stageName);
            [limNeg, limPos] = stage.ReturnLimits(axis);
            if ValidationHelper.isStringValueInBorders(obj.tvCurPos(index).String, limNeg, limPos)
                obj.edtCurPos(index).String = obj.tvCurPos(index).String;
                obj.showEdtCurPos(index, true);
                obj.checkEdtCurPosValue(index);
            else
                EventStation.anonymousWarning('Position must be a number between %d and %d, reverting!', limNeg, limPos)
            end
            
            stage = getObjByName(obj.stageName);
            axis = ClassStage.getAxis(obj.stageAxes(index));
            pos = stage.Pos(axis);
            obj.tvCurPos(index).String = pos;
            obj.btnMoveToBlue.Enable = 'on';
            
        end
        
        function showEdtCurPos(obj, index, shouldShow)
            % this function sets the view of the obj.edtCurPos edit-input
            % shouldShow - boolean (logical) - the new state
            % index - the index axis
            if shouldShow
                obj.hboxCurPos(index).Widths = [-1 -1];
                uicontrol(obj.edtCurPos(index)); % also request focus
            else
                obj.hboxCurPos(index).Widths = [-1 0];
            end
        end
        
        function checkEdtCurPosValue(obj, index)
            % checks that the obj.edtCurPos string is a valid value.
            % reverts the value if not valid based on obj.edtCurPosValue
            % or updates obj.edtCurPosValue based on the edt
            axis = ClassStage.getAxis(obj.stageAxes(index));
            stage = getObjByName(obj.stageName);
            [limNeg, limPos] = stage.ReturnLimits(axis);
            if ValidationHelper.isStringValueInBorders(obj.edtCurPos(index).String, limNeg, limPos)
                obj.edtCurPosValue(index) = str2double(obj.edtCurPos(index).String);
            elseif isempty(obj.edtCurPos(index).String)
                % delete it
                obj.clearEdtCurPos(index);
                % make sure to update the button as well:
                if all(obj.edtCurPosValue == inf)
                    obj.btnSendToFixed.Enable = 'off';
                end
                return
            else
                EventStation.anonymousWarning('must be a number between %d and %d, reverting!', limNeg, limPos)
            end
            obj.edtCurPos(index).String = StringHelper.formatNumber(obj.edtCurPosValue(index));
        end
        
        function clearEdtCurPos(obj, index)
            % clears the gui from the edit-input, also clears the
            % value stored as a numeric value
            obj.edtCurPos(index).String = '';
            obj.edtCurPosValue(index) = inf;
            obj.showEdtCurPos(index, false);
            set(gcf, 'CurrentObject',gcf);
            % ^ removes the focus from the edt and sets the focus to the
            % current figure itself
        end
            
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if event.isError ...
                    || isfield(event.extraInfo, ClassStage.EVENT_STEP_SIZE_CHANGED) ...
                    || isfield(event.extraInfo, ClassStage.EVENT_POSITION_CHANGED)
                obj.refresh();
            end
        end
    end
    
end

