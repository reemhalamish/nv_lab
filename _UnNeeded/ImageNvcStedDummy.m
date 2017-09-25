function ImageNvcStedDummy
global imageNVCObj

% Creates list of opened figure and check if ImageNVC_STED is already
% open. If it's open, return it.
list = get(0, 'Children');
for i = 1:size(list,1)
    if strcmp(handle(list(i)).Name, 'ImageNVC_STED')
        sprintf('ImageNVC_STED is already open!')
        figure(list(i));
        return
    end
end

%% Parameters
minSize = [1400 600];
fontSize = 10;
PROP_TEXT_NORMAL = {'Style', 'text', 'FontSize', 8, 'ForegroundColor', 'black', 'BackgroundColor', 'white', 'HorizontalAlignment', 'left'};
PROP_LABEL = {'Style', 'edit', 'FontSize', fontSize, 'FontWeight', 'bold', 'ForegroundColor', 'white', 'BackgroundColor', 'black', 'HorizontalAlignment', 'center', 'Enable', 'inactive'};
PROP_EDIT = {'Style', 'edit', 'FontSize', fontSize, 'FontWeight', 'bold', 'ForegroundColor', 'black', 'BackgroundColor', 'white', 'HorizontalAlignment', 'center'};
PROP_BUTTON = {'Style', 'pushbutton', 'FontSize', fontSize, 'FontWeight', 'bold'};
PROP_CHECKBOX = {'Style', 'checkbox', 'FontSize', fontSize};
PROP_POPUP = {'Style', 'popup', 'BackgroundColor', 'white', 'FontSize', fontSize};
PROP_RADIO = {'Style', 'radiobutton', 'FontSize', fontSize};
PROP_SLIDER = {'Style', 'slider'};

%% Create figure
handles.figure = figure('Name', 'ImageNVC_STED', 'Position', [200 200 minSize], 'MenuBar', 'none', 'Toolbar', 'none', ...
    'NumberTitle', 'off', 'CloseRequestFcn', @CloseRequestFcn_Callback);
% Make sure resize doesn't make it too small
handles.figure.SizeChangedFcn = @(~,~) set(handles.figure, 'Position', max([0 0 minSize], handles.figure.Position));

% Creating the main three columns
handles.figureLayout.mainColumns = uix.HBox('Parent', handles.figure, 'Spacing', 5, 'Padding', 5);
handles.figureLayout.leftColumn = uix.VBox('Parent', handles.figureLayout.mainColumns, 'Spacing', 5);
handles.figureLayout.middleColumn = uix.VBox('Parent', handles.figureLayout.mainColumns, 'Spacing', 5);
handles.figureLayout.rightColumn = uix.VBox('Parent', handles.figureLayout.mainColumns, 'Spacing', 5);
set(handles.figureLayout.mainColumns, 'Widths', [570 -1 300]);

% Creating the left column boxes
handles.figureLayout.scanParametersBox = uix.BoxPanel('Parent', handles.figureLayout.leftColumn, 'Title', 'Scan Parameters', 'Padding', 5);

handles.figureLayout.movementAndScanBox = uix.HBox('Parent', handles.figureLayout.leftColumn, 'Spacing', 5);
handles.figureLayout.movementControlBox = uix.BoxPanel('Parent', handles.figureLayout.movementAndScanBox, 'Title', 'Movement Control', 'Padding', 5);
uix.Empty('Parent', handles.figureLayout.movementAndScanBox);
handles.figureLayout.scanBox = uix.BoxPanel('Parent', handles.figureLayout.movementAndScanBox, 'Title', 'Scan', 'Padding', 5);
set(handles.figureLayout.movementAndScanBox, 'Widths', [375 -1 150]);

% handles.figureLayout.stageLimitsFillerBox = uix.HBox('Parent', handles.figureLayout.leftColumn, 'Spacing', 5);
handles.figureLayout.stageLimitsBox = uix.BoxPanel('Parent', handles.figureLayout.leftColumn, 'Title', 'Stage Limits', 'Padding', 5);
% uix.Empty('Parent', handles.figureLayout.stageLimitsFillerBox);
% set(handles.figureLayout.stageLimitsFillerBox, 'Widths', [400 -1]);

set(handles.figureLayout.leftColumn, 'Heights', [200 175 150]);

% Creating the middle column boxes
handles.figureLayout.plotParameters = uix.HBox('Parent', handles.figureLayout.middleColumn, 'Spacing', 5);
uix.Empty('Parent', handles.figureLayout.plotParameters);
handles.figureLayout.plotOptionsBox = uix.BoxPanel('Parent', handles.figureLayout.plotParameters, 'Title', 'Plot Options', 'Padding', 5);
handles.figureLayout.colormapBox = uix.BoxPanel('Parent', handles.figureLayout.plotParameters, 'Title', 'Colormap', 'Padding', 5);
handles.figureLayout.cursorBox = uix.BoxPanel('Parent', handles.figureLayout.plotParameters, 'Title', 'Cursor', 'Padding', 5);
uix.Empty('Parent', handles.figureLayout.plotParameters);
set(handles.figureLayout.plotParameters, 'Widths', [-1 150 200 100 -1]);

handles.axes1 = axes('Parent', uicontainer('Parent', handles.figureLayout.middleColumn), 'ActivePositionProperty', 'outerposition');
colorbar(handles.axes1)
set(handles.figureLayout.middleColumn, 'Heights', [125 -1]);

% Creating the right column boxes
handles.figureLayout.laserControlBox = uix.BoxPanel('Parent', handles.figureLayout.rightColumn, 'Title', 'Green Laser Control', 'Padding', 5);
handles.figureLayout.STEDlaserControlBox = uix.BoxPanel('Parent', handles.figureLayout.rightColumn, 'Title', 'STED Laser Control', 'Padding', 5);
handles.figureLayout.saveImageBox = uix.BoxPanel('Parent', handles.figureLayout.rightColumn, 'Title', 'Save Image', 'Padding', 5);
handles.figureLayout.loadImageBox = uix.BoxPanel('Parent', handles.figureLayout.rightColumn, 'Title', 'Load Image', 'Padding', 5);

handles.figureLayout.trackingAndReset = uix.HBox('Parent', handles.figureLayout.rightColumn, 'Spacing', 5);
handles.figureLayout.trackingBox = uix.BoxPanel('Parent', handles.figureLayout.trackingAndReset, 'Title', 'Tracking', 'Padding', 5);
handles.figureLayout.resetBox = uix.BoxPanel('Parent', handles.figureLayout.trackingAndReset, 'Title', 'Reset', 'Padding', 5);
set(handles.figureLayout.trackingAndReset, 'Widths', [200 -1]);

set(handles.figureLayout.rightColumn, 'Heights', [85 85 80 200 100]);

%% Scan Parameters Area
handles.figureLayout.scanParameters = uix.Grid('Parent', handles.figureLayout.scanParametersBox, 'Spacing', 5);

% 1st Column
uix.Empty('Parent', handles.figureLayout.scanParameters);
handles.figureLayout.scanParametersXLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'X');
handles.figureLayout.scanParametersYLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Y');
handles.figureLayout.scanParametersZLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Z');
uix.Empty('Parent', handles.figureLayout.scanParameters);
handles.bEnableAngle = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scanParameters);

% 2nd Column
handles.figureLayout.scanParametersFromLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'From');
handles.FromX = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.FromY = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.FromZ = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.figureLayout.scanParametersTiltLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Tilt Correction', 'FontSize', 7);
handles.TiltCalculate = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.scanParameters, 'string', 'Calculator');

% 3rd Column
handles.figureLayout.scanParametersToLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'To');
handles.ToX = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.ToY = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.ToZ = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.figureLayout.scanParametersThetaXLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'ThetaX');
handles.ThetaX = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);

% 4th Column
handles.figureLayout.scanParametersNPointsLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', '# Points');
handles.NX = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.NY = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.NZ = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.figureLayout.scanParametersThetaYLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'ThetaY');
handles.ThetaY = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);

% 5th Column
handles.figureLayout.scanParametersFixLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Fix');
handles.bFixX = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scanParameters);
handles.bFixY = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scanParameters);
handles.bFixZ = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scanParameters);
uix.Empty('Parent', handles.figureLayout.scanParameters);
uix.Empty('Parent', handles.figureLayout.scanParameters);

% 6th Column
handles.figureLayout.scanParametersPositionLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Fine');
handles.FixX = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.FixY = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.FixZ = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
uix.Empty('Parent', handles.figureLayout.scanParameters);
handles.CenterFineStage = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.scanParameters, 'string', 'Center');

% 7th Column
handles.figureLayout.scanParametersPositionLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Coarse');
handles.CoarseX = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.CoarseY = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
handles.CoarseZ = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);
uix.Empty('Parent', handles.figureLayout.scanParameters);
handles.bCoarseClose = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Closed Loop', 'Fontsize', 8);

% 8th Column
handles.figureLayout.scanParametersPositionLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', 'Scan Around');
handles.figureLayout.ScanAroundX = uix.HBox('Parent', handles.figureLayout.scanParameters, 'Spacing', 5);
handles.figureLayout.ScanAroundY = uix.HBox('Parent', handles.figureLayout.scanParameters, 'Spacing', 5);
handles.figureLayout.ScanAroundZ = uix.HBox('Parent', handles.figureLayout.scanParameters, 'Spacing', 5);
handles.figureLayout.scanParametersTimeLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.scanParameters, 'String', sprintf('Pixel Time'));
handles.FixDT = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.scanParameters);

% Scan Around
handles.ScanAroundX = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.ScanAroundX);
handles.ScanAroundXButton = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.ScanAroundX, 'string', 'Set');
handles.ScanAroundY = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.ScanAroundY);
handles.ScanAroundYButton = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.ScanAroundY, 'string', 'Set');
handles.ScanAroundZ = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.ScanAroundZ);
handles.ScanAroundZButton = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.ScanAroundZ, 'string', 'Set');

set(handles.figureLayout.scanParameters, 'Widths', [-1 80 80 80 25 60 80 100], 'Heights', [-3 -5 -5 -5 -3 -5]);

%% Movement Area
handles.figureLayout.movementControl = uix.HBox('Parent', handles.figureLayout.movementControlBox, 'Spacing', 5);
handles.figureLayout.movementControlStageSelectColumn = uix.VBox('Parent', handles.figureLayout.movementControl, 'Spacing', 5);
uix.Empty('Parent', handles.figureLayout.movementControl);
handles.figureLayout.movementControlLabelColumn = uix.VBox('Parent', handles.figureLayout.movementControl, 'Spacing', 5);
handles.figureLayout.movementControlArrowColumn = uix.VBox('Parent', handles.figureLayout.movementControl, 'Spacing', 5);
uix.Empty('Parent', handles.figureLayout.movementControl);
handles.figureLayout.movementControlOthersColumn = uix.VBox('Parent', handles.figureLayout.movementControl, 'Spacing', 5);
set(handles.figureLayout.movementControl, 'Widths', [75 -1 15 130 -1 100]);

% Stage Select Column
handles.figureLayout.movementControlSelectStageLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.movementControlStageSelectColumn, 'String', 'Select Stage', 'Fontsize', 8);
handles.bSelectCoarseStage = uicontrol(PROP_RADIO{:}, 'Parent', handles.figureLayout.movementControlStageSelectColumn, 'string', 'Corase');
handles.bSelectFineStage = uicontrol(PROP_RADIO{:}, 'Parent', handles.figureLayout.movementControlStageSelectColumn, 'string', 'Fine');
uix.Empty('Parent', handles.figureLayout.movementControlStageSelectColumn);
handles.figureLayout.movementControlStep = uix.HBox('Parent', handles.figureLayout.movementControlStageSelectColumn, 'Spacing', 5);
handles.figureLayout.movementControlStepLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.movementControlStep, 'String', 'Step:');
handles.StepSize = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.movementControlStep);
set(handles.figureLayout.movementControlStageSelectColumn, 'Heights', [-2 -2 -2 -2 -3]);

% Label Column
handles.figureLayout.movementControlXLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.movementControlLabelColumn, 'String', 'X');
handles.figureLayout.movementControlYLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.movementControlLabelColumn, 'String', 'Y');
handles.figureLayout.movementControlZLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.movementControlLabelColumn, 'String', 'Z');

% Arrow Column
handles.figureLayout.movementControlXArrow = uix.HBox('Parent', handles.figureLayout.movementControlArrowColumn, 'Spacing', 5);
handles.XLeft = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlXArrow, 'string', '¬', 'FontName', 'Symbol', 'FontSize', 20);
handles.XRight = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlXArrow, 'string', '®', 'FontName', 'Symbol', 'FontSize', 20);
handles.figureLayout.movementControlYArrow = uix.HBox('Parent', handles.figureLayout.movementControlArrowColumn, 'Spacing', 5);
handles.YLeft = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlYArrow, 'string', '¬', 'FontName', 'Symbol', 'FontSize', 20);
handles.YRight = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlYArrow, 'string', '®', 'FontName', 'Symbol', 'FontSize', 20);
handles.figureLayout.movementControlZArrow = uix.HBox('Parent', handles.figureLayout.movementControlArrowColumn, 'Spacing', 5);
handles.ZLeft = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlZArrow, 'string', '¬', 'FontName', 'Symbol', 'FontSize', 20);
handles.ZRight = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlZArrow, 'string', '®', 'FontName', 'Symbol', 'FontSize', 20);

% Others Column
handles.FixPos = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlOthersColumn, 'string', 'Fix Position');
handles.QueryPos = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlOthersColumn, 'string', 'Query Position');
handles.StopMovement = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.movementControlOthersColumn, 'string', 'Halt Stages!', 'ForegroundColor', 'white', 'BackgroundColor', 'red', 'Fontsize', 13);

%% Scan Area
handles.figureLayout.scan = uix.VBox('Parent', handles.figureLayout.scanBox, 'Spacing', 5);
handles.Scan = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.scan, 'string', 'Scan', 'ForegroundColor', 'white', 'BackgroundColor', 'green', 'Fontsize', 14);
handles.StopScan = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.scan, 'string', 'Stop Scan', 'ForegroundColor', 'white', 'BackgroundColor', 'red', 'Fontsize', 14);
handles.bScanCont = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scan, 'string', 'Continuous');
handles.figureLayout.scanLastLine = uix.HBox('Parent', handles.figureLayout.scan, 'Spacing', 5);
handles.bFastScan = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scanLastLine, 'string', 'Fast');
handles.bAutoSaveImg = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.scanLastLine, 'string', 'Autosave');
set(handles.figureLayout.scanLastLine, 'Widths', [-2 -3]);
set(handles.figureLayout.scan, 'Heights', [-2 -2 -1 -1]);

%% Stage Limits Area
handles.figureLayout.stageLimits = uix.Grid('Parent', handles.figureLayout.stageLimitsBox, 'Spacing', 5);

% 1st Column
handles.figureLayout.stageLimitsXLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'F');
handles.figureLayout.stageLimitsXLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'X');
handles.figureLayout.stageLimitsYLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Y');
handles.figureLayout.stageLimitsZLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Z');

% 2nd Column
handles.figureLayout.stageLimitsLowerLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Lower');
handles.XFinellimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits, 'Enable', 'inactive', 'BackgroundColor', [0.8 0.8 0.8]);
handles.YFinellimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits, 'Enable', 'inactive', 'BackgroundColor', [0.8 0.8 0.8]);
handles.ZFinellimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits, 'Enable', 'inactive', 'BackgroundColor', [0.8 0.8 0.8]);

% 3rd Column
handles.figureLayout.stageLimitsLowerLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Upper');
handles.XFineulimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits, 'Enable', 'inactive', 'BackgroundColor', [0.8 0.8 0.8]);
handles.YFineulimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits, 'Enable', 'inactive', 'BackgroundColor', [0.8 0.8 0.8]);
handles.ZFineulimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits, 'Enable', 'inactive', 'BackgroundColor', [0.8 0.8 0.8]);

% 4th Column
uix.Empty('Parent', handles.figureLayout.stageLimits);
uix.Empty('Parent', handles.figureLayout.stageLimits);
uix.Empty('Parent', handles.figureLayout.stageLimits);
uix.Empty('Parent', handles.figureLayout.stageLimits);

% 5th Column
handles.figureLayout.stageLimitsXLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'C');
handles.figureLayout.stageLimitsXLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'X');
handles.figureLayout.stageLimitsYLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Y');
handles.figureLayout.stageLimitsZLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Z');

% 6th Column
handles.figureLayout.stageLimitsLowerLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Lower');
handles.Xllimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits);
handles.Yllimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits);
handles.Zllimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits);

% 7rd Column
handles.figureLayout.stageLimitsLowerLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Upper');
handles.Xulimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits);
handles.Yulimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits);
handles.Zulimit = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimits);

% 8th Column
uix.Empty('Parent', handles.figureLayout.stageLimits);
uix.Empty('Parent', handles.figureLayout.stageLimits);
uix.Empty('Parent', handles.figureLayout.stageLimits);
uix.Empty('Parent', handles.figureLayout.stageLimits);

% 9th Column
handles.figureLayout.stageLimitsAxisLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Axis');
handles.SetXAxisLimit = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.stageLimits, 'string', 'X');
handles.SetYAxisLimit = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.stageLimits, 'string', 'Y');
handles.SetZAxisLimit = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.stageLimits, 'string', 'Z');

% 10th Column
handles.figureLayout.stageLimitsLimitLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Choose Limit', 'Fontsize', 8);
handles.UpperLimit = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.stageLimits, 'string', 'Upper');
handles.LowerLimit = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.stageLimits, 'string', 'Lower');
uix.Empty('Parent', handles.figureLayout.stageLimits);

% 11th Column
handles.figureLayout.stageLimitsSetLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.stageLimits, 'String', 'Set To');
handles.SetLimitToMax = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.stageLimits, 'string', 'Max');
handles.SetLimitToPosition = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.stageLimits, 'string', 'Current Position');
handles.figureLayout.stageLimitsSetLimitAround = uix.HBox('Parent', handles.figureLayout.stageLimits, 'Spacing', 5);
handles.SetLimitAround = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.stageLimitsSetLimitAround, 'string', 'Around:');
handles.LimitAround = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.stageLimitsSetLimitAround);
set(handles.figureLayout.stageLimitsSetLimitAround, 'Widths', [-5 -3]);

set(handles.figureLayout.stageLimits, 'Widths', [15 55 55 5 15 55 55 5 35 80 -1], 'Heights', [-3 -5 -5 -5]);

%% Plot Options Area
handles.figureLayout.plotOptions = uix.VBox('Parent', handles.figureLayout.plotOptionsBox, 'Spacing', 5);
handles.SetRange = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.plotOptions, 'string', '<html><center>Set Scan Parameters<br>From Image</center>', 'Fontsize', 8);
handles.figureLayout.plotStyle = uix.HBox('Parent', handles.figureLayout.plotOptions, 'Spacing', 5);
handles.figureLayout.plotStyleLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.plotStyle, 'String', 'Plot Style:');
handles.AxisDisplay = uicontrol(PROP_POPUP{:}, 'Parent', handles.figureLayout.plotStyle, 'String', {'normal', 'equal', 'square'});
handles.DispInFig = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.plotOptions, 'string', 'Open in Figure');

set(handles.figureLayout.plotOptions, 'Heights', [-5 -4 -4]);

%% Colormap Area
handles.figureLayout.colormap = uix.VBox('Parent', handles.figureLayout.colormapBox, 'Spacing', 5);
handles.figureLayout.colormap1stRow = uix.HBox('Parent', handles.figureLayout.colormap, 'Spacing', 5);
handles.Colormap = uicontrol(PROP_POPUP{:}, 'Parent', handles.figureLayout.colormap1stRow, 'String', {'Jet', 'HSV', 'Hot', 'Cool', 'Spring', 'Summer', 'Autumn', 'Winter', 'Gray', 'Bone', 'Copper', 'Pink', 'Lines'});
uix.Empty('Parent', handles.figureLayout.colormap1stRow);
handles.CAxisAuto = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.colormap1stRow, 'string', 'Auto');
set(handles.figureLayout.colormap1stRow, 'Widths', [-1 15 50]);

handles.figureLayout.colormap2ndRow = uix.HBox('Parent', handles.figureLayout.colormap, 'Spacing', 5);
handles.figureLayout.colormapMinLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.colormap2ndRow, 'String', 'Min');
handles.CAxisMin = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.colormap2ndRow);
handles.figureLayout.colormapMaxLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.colormap2ndRow, 'String', 'Max');
handles.CAxisMax = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.colormap2ndRow);

set(handles.figureLayout.colormap, 'Heights', [-1 -2]);

%% Cursor Area
handles.figureLayout.cursor = uix.VBox('Parent', handles.figureLayout.cursorBox, 'Spacing', 5);
handles.bCursorMarker = uicontrol(PROP_RADIO{:}, 'Parent', handles.figureLayout.cursor, 'string', 'Marker');
handles.bZoom = uicontrol(PROP_RADIO{:}, 'Parent', handles.figureLayout.cursor, 'string', 'Zoom');
handles.bCursorLocation = uicontrol(PROP_RADIO{:}, 'Parent', handles.figureLayout.cursor, 'string', 'Location');

%% Laser Control Area
handles.figureLayout.laserControl = uix.VBox('Parent', handles.figureLayout.laserControlBox, 'Spacing', 5);
handles.figureLayout.laserControl1stRow = uix.HBox('Parent', handles.figureLayout.laserControl, 'Spacing', 5);
handles.bLaser = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.laserControl1stRow, 'string', 'Enable');
handles.figureLayout.laserControlPowerLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.laserControl1stRow, 'String', 'Power:');
handles.LaserPowerPercentage = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.laserControl1stRow);
handles.LaserPower = uicontrol(PROP_SLIDER{:}, 'Parent', handles.figureLayout.laserControl);

%% STEDLaser Control Area
handles.figureLayout.STEDlaserControl = uix.VBox('Parent', handles.figureLayout.STEDlaserControlBox, 'Spacing', 5);
handles.figureLayout.STEDlaserControl1stRow = uix.HBox('Parent', handles.figureLayout.STEDlaserControl, 'Spacing', 5);
handles.bSTEDLaser = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.STEDlaserControl1stRow, 'string', 'Enable');
handles.figureLayout.STEDlaserControlPowerLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.STEDlaserControl1stRow, 'String', 'Power:');
handles.STEDLaserPowerPercentage = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.STEDlaserControl1stRow);
handles.STEDLaserPower = uicontrol(PROP_SLIDER{:}, 'Parent', handles.figureLayout.STEDlaserControl);

%% Save Image Area
handles.figureLayout.saveImage = uix.VBox('Parent', handles.figureLayout.saveImageBox, 'Spacing', 5);
handles.figureLayout.saveImage1stRow = uix.HBox('Parent', handles.figureLayout.saveImage, 'Spacing', 5);
handles.Save = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.saveImage1stRow, 'string', 'Save');
handles.SaveAs = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.saveImage1stRow, 'string', 'Save As');
uix.Empty('Parent', handles.figureLayout.saveImage1stRow);
handles.figureLayout.saveImageNotesLabel = uicontrol(PROP_LABEL{:}, 'Parent', handles.figureLayout.saveImage1stRow, 'String', 'Notes:');
set(handles.figureLayout.saveImage1stRow, 'Widths', [-2 -2 -3 -2]);

handles.SaveNotes = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.saveImage, 'HorizontalAlignment', 'left', 'FontWeight', 'normal', 'ForegroundColor', 'Black', 'BackgroundColor', 'white', 'FontSize', 8);
set(handles.figureLayout.saveImage, 'Heights', [-2 -1]);

%% Load Image Area
handles.figureLayout.loadImage = uix.VBox('Parent', handles.figureLayout.loadImageBox, 'Spacing', 5);
handles.strLoadedFile = uicontrol(PROP_TEXT_NORMAL{:}, 'Parent', handles.figureLayout.loadImage, 'String', 'Loaded File Name');
handles.figureLayout.loadImageButtonRow = uix.HBox('Parent', handles.figureLayout.loadImage, 'Spacing', 5);
handles.Load = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.loadImageButtonRow, 'string', 'Load...', 'FontSize', 8);
handles.LoadPrevious = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.loadImageButtonRow, 'string', 'Previous', 'FontSize', 8);
handles.LoadNext = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.loadImageButtonRow, 'string', 'Next', 'FontSize', 8);
handles.Delete = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.loadImageButtonRow, 'string', 'Delete', 'FontSize', 8);
handles.UpdateNotes = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.loadImageButtonRow, 'string', 'Update Notes', 'FontSize', 8);
set(handles.figureLayout.loadImageButtonRow, 'Widths', [-4 -6 -3 -4 -7]);

handles.strLoadedFileInfo = uicontrol(PROP_TEXT_NORMAL{:}, 'Parent', handles.figureLayout.loadImage, 'String', 'Loaded File Info');
handles.LoadedNotes = uicontrol(PROP_EDIT{:}, 'Parent', handles.figureLayout.loadImage, 'String', 'Notes', 'HorizontalAlignment', 'left', 'FontWeight', 'normal', 'FontSize', 8);
set(handles.figureLayout.loadImage, 'Heights', [-2 -3 -10 -2]);

%% Tracking Area
handles.figureLayout.tracking = uix.VBox('Parent', handles.figureLayout.trackingBox, 'Spacing', 5);
handles.Track = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.tracking, 'string', 'Track', 'ForegroundColor', 'white', 'BackgroundColor', 'blue', 'Fontsize', 14);
handles.bTrackCont = uicontrol(PROP_CHECKBOX{:}, 'Parent', handles.figureLayout.tracking, 'string', 'Continuous Tracking');

%% Reset Area
handles.figureLayout.reset = uix.VBox('Parent', handles.figureLayout.resetBox, 'Spacing', 5);

handles.ResetPiezo = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.reset, 'string', 'Reset Stage');
handles.ResetDAQ = uicontrol(PROP_BUTTON{:}, 'Parent', handles.figureLayout.reset, 'string', 'Reset DAQ');

%% Set Callbacks

% From
set(handles.FromX, 'callback', {@FromX_Callback, handles});
set(handles.FromY, 'callback', {@FromY_Callback, handles});
set(handles.FromZ, 'callback', {@FromZ_Callback, handles});

% To
set(handles.ToX, 'callback', {@ToX_Callback, handles});
set(handles.ToY, 'callback', {@ToY_Callback, handles});
set(handles.ToZ, 'callback', {@ToZ_Callback, handles});

% # Points
set(handles.NX, 'callback', {@NX_Callback, handles});
set(handles.NY, 'callback', {@NY_Callback, handles});
set(handles.NZ, 'callback', {@NZ_Callback, handles});

% Fix
set(handles.FixX, 'callback', {@FixX_Callback, handles});
set(handles.FixY, 'callback', {@FixY_Callback, handles});
set(handles.FixZ, 'callback', {@FixZ_Callback, handles});
set(handles.CenterFineStage, 'callback', {@CenterFineStage_Callback, handles});

% Coarse
set(handles.CoarseX, 'callback', {@CoarseX_Callback, handles});
set(handles.CoarseY, 'callback', {@CoarseY_Callback, handles});
set(handles.CoarseZ, 'callback', {@CoarseZ_Callback, handles});
set(handles.bCoarseClose , 'callback', {@bCoarseClose_Callback, handles});

% Scan Around
set(handles.ScanAroundX, 'callback', {@ScanAroundX, handles});
set(handles.ScanAroundXButton, 'callback', {@ScanAroundXButton, handles});
set(handles.ScanAroundY, 'callback', {@ScanAroundY, handles});
set(handles.ScanAroundYButton, 'callback', {@ScanAroundYButton, handles});
set(handles.ScanAroundZ, 'callback', {@ScanAroundZ, handles});
set(handles.ScanAroundZButton, 'callback', {@ScanAroundZButton, handles});


% Angles
set(handles.TiltCalculate, 'callback', {@TiltCalculate_Callback, handles});
set(handles.bEnableAngle, 'callback', {@bEnableAngle_Callback, handles});
set(handles.ThetaX, 'callback', {@AngleValidation_Callback, handles});
set(handles.ThetaY, 'callback', {@AngleValidation_Callback, handles});

% Time
set(handles.FixDT, 'callback', {@FixDT_Callback, handles});

% Movmement
set(handles.bSelectCoarseStage, 'callback', {@bSelectCoarseStage_Callback, handles});
set(handles.bSelectFineStage, 'callback', {@bSelectFineStage_Callback, handles});

set(handles.XLeft, 'callback', {@XLeft_Callback, handles});
set(handles.XRight, 'callback', {@XRight_Callback, handles});
set(handles.YLeft, 'callback', {@YLeft_Callback, handles});
set(handles.YRight, 'callback', {@YRight_Callback, handles});
set(handles.ZLeft, 'callback', {@ZLeft_Callback, handles});
set(handles.ZRight, 'callback', {@ZRight_Callback, handles});

set(handles.FixPos, 'callback', {@FixPos_Callback, handles});
set(handles.QueryPos, 'callback', {@QueryPos_Callback, handles});
set(handles.StopMovement, 'callback', {@StopMovement_Callback, handles});
set(handles.StepSize, 'callback', {@StepSize_Callback, handles});

% Scan Panel
set(handles.Scan, 'callback', {@Scan_Callback, handles});
set(handles.StopScan, 'callback', {@StopScan_Callback, handles});

% Stage limits and control
set(handles.Xllimit, 'callback', {@Xllimit_Callback, handles});
set(handles.Yllimit, 'callback', {@Yllimit_Callback, handles});
set(handles.Zllimit, 'callback', {@Zllimit_Callback, handles});
set(handles.Xulimit, 'callback', {@Xulimit_Callback, handles});
set(handles.Yulimit, 'callback', {@Yulimit_Callback, handles});
set(handles.Zulimit, 'callback', {@Zulimit_Callback, handles});

set(handles.SetLimitToMax, 'callback', {@SetLimitToMax_Callback, handles});
set(handles.SetLimitToPosition, 'callback', {@SetLimitToPosition_Callback, handles});
set(handles.SetLimitAround, 'callback', {@SetLimitAround_Callback, handles});
set(handles.LimitAround, 'callback', {@LimitAround_Callback, handles});

% Stage
set(handles.ResetPiezo, 'callback', {@ResetPiezo_Callback, handles});
set(handles.ResetDAQ, 'callback', {@ResetDAQ_Callback, handles});

% Plot Options
set(handles.SetRange, 'callback', {@SetRange_Callback, handles});
set(handles.DispInFig, 'callback', {@DispInFig_Callback, handles});
set(handles.AxisDisplay, 'callback', {@AxisDisplay_Callback, handles});

% Colormap
set(handles.Colormap, 'callback', {@Colormap_Callback, handles});
set(handles.CAxisMin, 'callback', {@CAxisMin_Callback, handles});
set(handles.CAxisMax, 'callback', {@CAxisMax_Callback, handles});
set(handles.CAxisAuto, 'callback', {@CAxisAuto_Callback, handles});

% Cursor
set(handles.bCursorMarker, 'callback', {@bCursorMarker_Callback, handles});
set(handles.bZoom, 'callback', {@bZoom_Callback, handles});
set(handles.bCursorLocation, 'callback', {@bCursorLocation_Callback, handles});

% Laser
set(handles.bLaser, 'callback', {@bLaser_Callback, handles});
set(handles.LaserPowerPercentage, 'callback', {@LaserPowerPercentage_Callback, handles});
set(handles.LaserPower, 'callback', {@LaserPower_Callback, handles});

% STED Laser
set(handles.bSTEDLaser, 'callback', {@bSTEDLaser_Callback, handles});
set(handles.STEDLaserPowerPercentage, 'callback', {@STEDLaserPowerPercentage_Callback, handles});
set(handles.STEDLaserPower, 'callback', {@STEDLaserPower_Callback, handles});

% Save
set(handles.Save, 'callback', {@Save_Callback, handles});
set(handles.SaveAs, 'callback', {@SaveAs_Callback, handles});

% Load
set(handles.Load, 'callback', {@Load_Callback, handles});
set(handles.LoadPrevious, 'callback', {@LoadPrevious_Callback, handles});
set(handles.LoadNext, 'callback', {@LoadNext_Callback, handles});
set(handles.Delete, 'callback', {@Delete_Callback, handles});
set(handles.UpdateNotes, 'callback', {@UpdateNotes_Callback, handles});

% Track
set(handles.Track, 'callback', {@Track_Callback, handles});

%% Open ClassImageSTED
try
    imageNVCObj = ClassImageSTED.GetInstance();
    % imageNVCObj.Start(handles);
catch err
    delete(handles.figure);
    rethrow(err);
end

%% Functions

% TiltCalculate GUI
    function TiltCalculate_Callback(hObject, eventdata, handles)
        % Creates list of opened figure and check if TiltCalculate GUI is
        % already open, if so, return it.
        figuresList = get(0, 'Children');
        for k = 1:size(figuresList,1)
            if strcmp(handle(figuresList(k)).Name, 'TiltCalculate')
                figure(figuresList(k));
                return;
            end
        end
        % if not opened, open a new one.
        
        handles.TiltCalculateFig = figure('position', [792 449 380 210], 'Name', 'TiltCalculate');
        handles.TiltCalculateFig = uipanel(handles.TiltCalculateFig, 'BackgroundColor', [0.941 0.941 0.941]);
        
        xColumn = 20;
        yColumn = xColumn+70;
        zColumn = yColumn+70;
        buttonColumn = zColumn + 70;
        buttomRow = 20;
        rowSpace = 38;
        row1 = buttomRow + rowSpace;
        row2 = buttomRow + (2*rowSpace);
        row3 = buttomRow + (3*rowSpace);
        row4 = buttomRow + (4*rowSpace);
        
        width = 60;
        height = 30;
        
        handles.xCoordinateLabel = uicontrol(handles.TiltCalculateFig, 'Style', 'text', 'position', [xColumn+10 row4 30 20],...
            'ForegroundColor', [0.502 0.502 0.502],...
            'string', 'x', 'FontSize', 10);
        handles.yCoordinateLabel = uicontrol(handles.TiltCalculateFig, 'Style', 'text', 'position', [yColumn+12 row4 30 20],...
            'ForegroundColor', [0.502 0.502 0.502],...
            'string', 'y', 'FontSize', 10);
        handles.zCoordinateLabel = uicontrol(handles.TiltCalculateFig, 'Style', 'text', 'position', [zColumn+12 row4 40 20],...
            'ForegroundColor', [0.502 0.502 0.502],...
            'string', 'z', 'FontSize', 10);
        
        % x coordinate
        handles.x1 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [xColumn row3 width height],...
            'ForegroundColor', 'black',...
            'string', 'x1', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
        handles.x2 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [xColumn row2 width height],...
            'ForegroundColor', 'black',...
            'string', 'x2', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
        handles.x3 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [xColumn row1 width height],...
            'ForegroundColor', 'black',...
            'string', 'x3', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
        
        % y coordinate
        handles.y1 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [yColumn row3 width height],...
            'ForegroundColor', 'black',...
            'string', 'y1', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center',...
            'FontUnits','pixels', 'FontName','MS Sans Serif');
        handles.y2 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [yColumn row2 width height],...
            'ForegroundColor', 'black',...
            'string', 'y2', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center',...
            'FontUnits','pixels', 'FontName','MS Sans Serif');
        handles.y3 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [yColumn row1 width height],...
            'ForegroundColor', 'black',...
            'string', 'y3', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center',...
            'FontUnits','pixels', 'FontName','MS Sans Serif');
        
        % z coordinate
        handles.z1 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [zColumn row3 width height],...
            'ForegroundColor', 'black',...
            'string', 'z1', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
        handles.z2 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [zColumn row2 width height],...
            'ForegroundColor', 'black',...
            'string', 'z2', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
        handles.z3 = uicontrol(handles.TiltCalculateFig, 'Style', 'edit', 'position', [zColumn row1 width height],...
            'ForegroundColor', 'black',...
            'string', 'z3', 'FontSize', fontSize, 'FontWeight', 'bold',...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
        
        % Button
        handles.set1 = uicontrol(handles.TiltCalculateFig, 'Style', 'pushbutton', ...
            'position', [buttonColumn row3 width+50 height],...
            'string', 'Set to current point', 'FontSize',8);
        handles.set2 = uicontrol(handles.TiltCalculateFig, 'Style', 'pushbutton', ...
            'position', [buttonColumn row2 width+50 height],...
            'string', 'Set to current point', 'FontSize',8);
        handles.set3 = uicontrol(handles.TiltCalculateFig, 'Style', 'pushbutton', ...
            'position', [buttonColumn row1 width+50 height],...
            'string', 'Set to current point', 'FontSize',8);
        
        handles.CalculateAngles = uicontrol(handles.TiltCalculateFig, 'Style', 'pushbutton', ...
            'position', [xColumn+9 buttomRow 3*width height],...
            'string', 'Calculate angles', 'FontSize',8);
        
        set(handles.set1, 'callback', {@SetFromCurrentPos_Callback, handles, 1});
        set(handles.set2, 'callback', {@SetFromCurrentPos_Callback, handles, 2});
        set(handles.set3, 'callback', {@SetFromCurrentPos_Callback, handles, 3});
        set(handles.CalculateAngles, 'callback', {@CalculateAngles_Callback, handles});
    end

%% Validation functions
    function oldValue = CheckValueInLimits(hObject, lowerLimit, upperLimit)
        % Checks if the value written in hObject 'String' is within the limits,
        % if not, restores the old value.
        % Old value is stored in the 'UserData' and in handled via this
        % function.
        oldValue = get(hObject, 'UserData');
        value = str2double(get(hObject, 'String'));
        if (isnan(value) || value <  lowerLimit || value > upperLimit)
            fprintf('Value should be between %.4f & %.4f!\n', lowerLimit, upperLimit);
            set(hObject, 'String', oldValue);
            oldValue = -inf;
        else
            set(hObject, 'UserData', value);
        end
    end

    function MovementControl(control, handles)
        % Enables or disables (Greys out) the movement control buttons.
        % Control can be either 'On' or 'Off'
        set(handles.XLeft, 'Enable', control);
        set(handles.YLeft, 'Enable', control);
        set(handles.ZLeft, 'Enable', control);
        set(handles.XRight, 'Enable', control);
        set(handles.YRight, 'Enable', control);
        set(handles.ZRight, 'Enable', control);
        set(handles.FixPos, 'Enable', control);
        set(handles.Scan, 'Enable', control);
        set(handles.QueryPos, 'Enable', control);
    end

    function CheckValueIsNatural(hObject)
        % Checks if the value written in hObject 'String' is a positive
        % integer, if not, restores the old value.
        % Old value is stored in the 'UserData' and in handled via this
        % function.
        oldValue = get(hObject, 'UserData');
        value = str2double(get(hObject, 'String'));
        if (isnan(value) || mod(value,1) ~= 0 || value <= 0)
            fprintf('Value should a positive integer!\n');
            set(hObject, 'String', oldValue);
        else
            set(hObject, 'UserData', value);
        end
    end

    function CheckValueIsPositive(hObject)
        % Checks if the value written in hObject 'String' is a positive
        % number, if not, restores the old value.
        % Old value is stored in the 'UserData' and in handled via this
        % function.
        oldValue = get(hObject, 'UserData');
        value = str2double(get(hObject, 'String'));
        if (isnan(value) || value <= 0)
            fprintf('Value should a positive!\n');
            set(hObject, 'String', oldValue);
        else
            set(hObject, 'UserData', value);
        end
    end

    function OneAxisMaxUpdate(axis, handles)
        % handles    structure with handles to all objects in the GUI
        % Get hard limits of the axis
        [negHardLimit, posHardLimit] = imageNVCObj.GetStageLimits(axis, handles); %#ok<ASGLU>
        
        % Update with the hard limit according to the selected limit
        if get(handles.UpperLimit, 'Value')
            eval(sprintf('set(handles.%sulimit, ''String'', posHardLimit)', upper(axis)));
            eval(sprintf('set(handles.%sulimit, ''UserData'', posHardLimit)', upper(axis)));
        end
        
        if get(handles.LowerLimit, 'Value')
            eval(sprintf('set(handles.%sllimit, ''String'', negHardLimit)', upper(axis)));
            eval(sprintf('set(handles.%sllimit, ''UserData'', negHardLimit)', upper(axis)));
        end
    end

    function OneAxisSetLimitToPosition(axis, handles)
        fixPosition = eval(sprintf('str2double(get(handles.Fix%s, ''String''))', upper(axis))); %#ok<NASGU>
        
        if get(handles.UpperLimit, 'Value')
            eval(sprintf('set(handles.%sulimit, ''String'', fixPosition)', upper(axis)));
            eval(sprintf('set(handles.%sulimit, ''UserData'', fixPosition)', upper(axis)));
        end
        
        if get(handles.LowerLimit, 'Value')
            eval(sprintf('set(handles.%sllimit, ''String'', fixPosition)', upper(axis)));
            eval(sprintf('set(handles.%sllimit, ''UserData'', fixPosition)', upper(axis)));
        end
        
    end

    function OneAxisSetLimitAround(axis, handles)
        aroundValue = str2double(get(handles.LimitAround, 'String'));
        isUpperLimit = get(handles.UpperLimit, 'Value');
        islowerLimit = get(handles.LowerLimit, 'Value');
        fix = eval(sprintf('str2double(get(handles.Fix%s, ''String''))', upper(axis)));
        
        % get hard limits of the axis
        [negHardLimit, posHardLimit] = imageNVCObj.GetStageLimits(axis, handles);
        
        % Set upper limit
        if isUpperLimit
            newUpper = fix +  aroundValue;
            if  newUpper > posHardLimit
                newUpper = posHardLimit; %#ok<NASGU>
            end
            eval(sprintf('set(handles.%sulimit, ''String'', num2str(newUpper))', upper(axis)));
            eval(sprintf('set(handles.%sulimit, ''UserData'', num2str(newUpper))', upper(axis)));
        end
        
        % Set lower limit
        if islowerLimit
            newlower = fix -  aroundValue;
            if  newlower < negHardLimit
                newlower = negHardLimit; %#ok<NASGU>
            end
            eval(sprintf('set(handles.%sllimit, ''String'', num2str(newlower))', upper(axis)));
            eval(sprintf('set(handles.%sllimit, ''UserData'', num2str(newlower))', upper(axis)));
        end
    end

%% GUI callbacks
    function FromX_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.FromX, str2double(get(handles.XFinellimit, 'String')), ...
            str2double(get(handles.XFineulimit, 'String')));
    end

    function ToX_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.ToX, str2double(get(handles.XFinellimit, 'String')),...
            str2double(get(handles.XFineulimit, 'String')));
    end

    function FromY_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.FromY, str2double(get(handles.YFinellimit, 'String')), ...
            str2double(get(handles.YFineulimit, 'String')));
    end

    function ToY_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.ToY, str2double(get(handles.YFinellimit, 'String')), ...
            str2double(get(handles.YFineulimit, 'String')));
    end

    function FromZ_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.FromZ, str2double(get(handles.ZFinellimit, 'String')), ...
            str2double(get(handles.ZFineulimit, 'String')));
    end

    function ToZ_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.ToZ, str2double(get(handles.ZFinellimit, 'String')), ...
            str2double(get(handles.ZFineulimit, 'String')));
    end

    function NX_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueIsNatural(handles.NX);
    end

    function NY_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueIsNatural(handles.NY);
    end

    function NZ_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueIsNatural(handles.NZ);
    end

    function FixX_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.FixX, str2double(get(handles.XFinellimit, 'String')), ...
            str2double(get(handles.XFineulimit, 'String')));
    end

    function FixY_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.FixY, str2double(get(handles.YFinellimit, 'String')), ...
            str2double(get(handles.YFineulimit, 'String')));
    end

    function FixZ_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.FixZ, str2double(get(handles.ZFinellimit, 'String')), ...
            str2double(get(handles.ZFineulimit, 'String')));
    end

    function CoarseX_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.CoarseX, str2double(get(handles.Xllimit, 'String')), ...
            str2double(get(handles.Xulimit, 'String')));
    end

    function CoarseY_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.CoarseY, str2double(get(handles.Yllimit, 'String')), ...
            str2double(get(handles.Yulimit, 'String')));
    end

    function CoarseZ_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.CoarseZ, str2double(get(handles.Zllimit, 'String')), ...
            str2double(get(handles.Zulimit, 'String')));
    end

    function FixDT_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.FixDT, eps, 1);
    end

    function bCoarseClose_Callback(hObject, eventdata, handles) 
        % handles    structure with handles to all objects in the GUI
        if get(hObject, 'value')
            mode = 'closed';
        else
            mode = 'open';
        end
        imageNVCObj.ChangeLoopMode(mode, 'Coarse', handles);
    end

    function CenterFineStage_Callback(hObject, eventdata, handles) %#ok<INUSD>
        % handles    structure with handles to all objects in the GUI
        fprintf('Not yet implemented\n');
    end

    function ScanAroundX(hObject, eventdata, handles) 
        CheckValueIsPositive(handles.ScanAroundX);
    end

    function ScanAroundY(hObject, eventdata, handles) 
        CheckValueIsPositive(handles.ScanAroundY);
    end

    function ScanAroundZ(hObject, eventdata, handles) 
        CheckValueIsPositive(handles.ScanAroundZ);
    end

    function ScanAroundXButton(hObject, eventdata, handles)
        around = str2double(get(handles.ScanAroundX, 'String'));
        pos = str2double(get(handles.FixX, 'String'));
        set(handles.FromX, 'String', num2str(pos-around, '%.3f'));
        FromX_Callback(handles.FromX, eventdata, handles);
        set(handles.ToX, 'String', num2str(pos+around, '%.3f'));
        ToX_Callback(handles.ToX, eventdata, handles);
    end

    function ScanAroundYButton(hObject, eventdata, handles)
        around = str2double(get(handles.ScanAroundY, 'String'));
        pos = str2double(get(handles.FixY, 'String'));
        set(handles.FromY, 'String', num2str(pos-around, '%.3f'));
        FromY_Callback(handles.FromY, eventdata, handles);
        set(handles.ToY, 'String', num2str(pos+around, '%.3f'));
        ToY_Callback(handles.ToY, eventdata, handles);
    end

    function ScanAroundZButton(hObject, eventdata, handles)
        around = str2double(get(handles.ScanAroundZ, 'String'));
        pos = str2double(get(handles.FixZ, 'String'));
        set(handles.FromZ, 'String', num2str(pos-around, '%.3f'));
        FromZ_Callback(handles.FromZ, eventdata, handles);
        set(handles.ToZ, 'String', num2str(pos+around, '%.3f'));
        ToZ_Callback(handles.ToZ, eventdata, handles);
    end

% --- Executes on button press in Scan.
    function Scan_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        MovementControl('Off', handles);
        try
            imageNVCObj.ImageScan('Scan', handles)
        catch err
            StopScan_Callback(handles.StopScan,eventdata, handles);
            rethrow(err);
        end
        MovementControl('On', handles);
    end

% --- Executes on button press in StopScan.
    function StopScan_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.StopScan(handles)
        MovementControl('On', handles);
    end

    function bSelectCoarseStage_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        if get(handles.bSelectCoarseStage, 'Value')
            set(handles.bSelectFineStage, 'Value', 0);
        else
            set(handles.bSelectCoarseStage, 'Value', 1);
        end
    end

    function bSelectFineStage_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        if get(handles.bSelectFineStage, 'Value')
            set(handles.bSelectCoarseStage, 'Value', 0);
        else
            set(handles.bSelectFineStage, 'Value', 1);
        end
    end

% --- Executes on button press in XLeft.
    function XLeft_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.PiezoSingleStep('xDec', handles);
    end

% --- Executes on button press in YLeft.
    function YLeft_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.PiezoSingleStep('yDec', handles);
    end

% --- Executes on button press in ZLeft.
    function ZLeft_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.PiezoSingleStep('zDec', handles);
        
    end

% --- Executes on button press in XRight.
    function XRight_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.PiezoSingleStep('xInc', handles);
    end

% --- Executes on button press in YRight.
    function YRight_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.PiezoSingleStep('yInc', handles);
    end

% --- Executes on button press in ZRight.
    function ZRight_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.PiezoSingleStep('zInc', handles);
    end

% --- Executes on button press in FixPos.
    function FixPos_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.FixLocations(handles);
    end

% --- Executes on button press in QueryPos.
    function QueryPos_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.PiezoQueries(handles);
    end

% --- Executes on button press in StopMovement
    function StopMovement_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.StopMovement(handles);
    end

    function StepSize_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueIsPositive(handles.StepSize);
    end

    function Xllimit_Callback(hObject, eventdata, handles)
        % Get hard limits, compare and then change soft limits'
        % handles    structure with handles to all objects in the GUI
        upperLimit = str2double(get(handles.Xulimit, 'String'));
        
        [negHardLimit, ~] = imageNVCObj.GetStageLimits('x', handles, 'coarse');
        oldValue = CheckValueInLimits(handles.Xllimit, negHardLimit, upperLimit);
        if oldValue ~= -inf
            imageNVCObj.SetSoftLimits('x', str2double(get(handles.Xllimit, 'String')), 0, 'coarse');
        end
    end

    function Xulimit_Callback(hObject, eventdata, handles)
        % Get hard limits, compare and then change soft limits'
        % handles    structure with handles to all objects in the GUI
        lowerLimit = str2double(get(handles.Xllimit, 'String'));
        
        [~, posHardLimit] = imageNVCObj.GetStageLimits('x', handles, 'coarse');
        oldValue = CheckValueInLimits(handles.Xulimit, lowerLimit, posHardLimit);
        if oldValue ~= -inf
            imageNVCObj.SetSoftLimits('x', str2double(get(handles.Xulimit, 'String')), 1, 'coarse');
        end
    end

    function Yllimit_Callback(hObject, eventdata, handles)
        % Get hard limits, compare and then change soft limits'
        % handles    structure with handles to all objects in the GUI
        upperLimit = str2double(get(handles.Yulimit, 'String'));
        
        [negHardLimit, ~] = imageNVCObj.GetStageLimits('y', handles, 'coarse');
        oldValue = CheckValueInLimits(handles.Yllimit, negHardLimit, upperLimit);
        if oldValue ~= -inf
            imageNVCObj.SetSoftLimits('y', str2double(get(handles.Yllimit, 'String')), 0, 'coarse');
        end
    end

    function Yulimit_Callback(hObject, eventdata, handles)
        % Get hard limits, compare and then change soft limits'
        % handles    structure with handles to all objects in the GUI
        lowerLimit = str2double(get(handles.Yllimit, 'String'));
        
        [~, posHardLimit] = imageNVCObj.GetStageLimits('y', handles, 'coarse');
        oldValue = CheckValueInLimits(handles.Yulimit, lowerLimit, posHardLimit);
        if oldValue ~= -inf
            imageNVCObj.SetSoftLimits('y', str2double(get(handles.Yulimit, 'String')), 1, 'coarse');
        end
    end

    function Zllimit_Callback(hObject, eventdata, handles)
        % Get hard limits, compare and then change soft limits'
        % handles    structure with handles to all objects in the GUI
        upperLimit = str2double(get(handles.Zulimit, 'String'));
        
        [negHardLimit, ~] = imageNVCObj.GetStageLimits('z', handles, 'coarse');
        oldValue = CheckValueInLimits(handles.Zllimit, negHardLimit, upperLimit);
        if oldValue ~= -inf
            imageNVCObj.SetSoftLimits('z', str2double(get(handles.Zllimit, 'String')), 0, 'coarse');
        end
    end

    function Zulimit_Callback(hObject, eventdata, handles)
        % Get hard limits, compare and then change soft limits'
        % handles    structure with handles to all objects in the GUI
        lowerLimit = str2double(get(handles.Zllimit, 'String'));
        
        [~, posHardLimit] = imageNVCObj.GetStageLimits('z', handles, 'coarse');
        oldValue = CheckValueInLimits(handles.Zulimit, lowerLimit, posHardLimit);
        if oldValue ~= -inf
            imageNVCObj.SetSoftLimits('z', str2double(get(handles.Zulimit, 'String')), 1, 'coarse');
        end
    end

% --- Executes on button press in SetRange.
    function SetRange_Callback(hObject, eventdata, handles)
        % hObject    handle to SetRange (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        imageNVCObj.ImageScan('SetRange', handles);
    end

% --- Executes on button press in SetLimitToMax.
    function SetLimitToMax_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        
        % change the selected limit on each selected axis.
        if get(handles.SetXAxisLimit, 'Value')
            OneAxisMaxUpdate('x', handles)
        end
        
        if get(handles.SetYAxisLimit, 'Value')
            OneAxisMaxUpdate('y', handles)
        end
        
        if get(handles.SetZAxisLimit, 'Value')
            OneAxisMaxUpdate('z', handles)
        end
    end

% --- Executes on button press in SetLimitToPosition.
    function SetLimitToPosition_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        if get(handles.SetXAxisLimit, 'Value')
            OneAxisSetLimitToPosition('x', handles);
        end
        
        if get(handles.SetYAxisLimit, 'Value')
            OneAxisSetLimitToPosition('y', handles)
        end
        
        if get(handles.SetZAxisLimit, 'Value')
            OneAxisSetLimitToPosition('z', handles)
        end
    end

% --- Executes on button press in SetLimitAround.
    function SetLimitAround_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        if get(handles.SetXAxisLimit, 'Value')
            OneAxisSetLimitAround('x', handles)
        end
        
        if get(handles.SetYAxisLimit, 'Value')
            OneAxisSetLimitAround('y', handles)
        end
        
        if get(handles.SetZAxisLimit, 'Value')
            OneAxisSetLimitAround('z', handles)
        end
    end

    function LimitAround_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueIsPositive(handles.LimitAround);
    end

% --- Executes on button press in Track.
    function Track_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.Track(handles);
    end

% --- Executes on button press in ResetPiezo.
    function ResetPiezo_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ResetPiezo(handles);
    end

% --- Executes on button press in bLaser.
    function bLaser_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.LaserEnable(handles);
    end

    function bSTEDLaser_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.STEDLaserEnable(handles);
    end

% --- Executes on button press in ResetDAQ.
    function ResetDAQ_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ResetDAQ(handles);
        bLaser_Callback(handles.bLaser,eventdata, handles);
    end

% --- Executes on selection change in Colormap.
    function Colormap_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.SetColormap(handles.axes1, handles);
    end

    function CAxisMin_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.CAxisMin, 0, str2double(get(handles.CAxisMax, 'String')));
        set(handles.CAxisAuto, 'Value',0);
        imageNVCObj.Colormap(handles, handles.axes1) %#ok<*INUSL>
    end

    function CAxisMax_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        CheckValueInLimits(handles.CAxisMax, str2double(get(handles.CAxisMin, 'String')), 1e6);
        % Turn off the auto mode
        set(handles.CAxisAuto, 'Value',0);
        imageNVCObj.Colormap(handles, handles.axes1) %#ok<*INUSL>
    end

% --- Executes on button press in CAxisAuto.
    function CAxisAuto_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.Colormap(handles, handles.axes1);
    end

% --- Executes on selection change in AxisDisplay.
    function AxisDisplay_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.SetAxisDisplay(handles);
    end

    function bCursorMarker_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        if get(handles.bCursorMarker, 'Value')
            set(handles.bZoom, 'Value', 0);
            set(handles.bCursorLocation, 'Value', 0);
            imageNVCObj.SetCursor(handles);
        else
            set(handles.bCursorMarker, 'Value', 1);
        end
    end

% --- Executes on button press in bZoom.
    function bZoom_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        if get(handles.bZoom, 'Value')
            set(handles.bCursorLocation, 'Value', 0);
            set(handles.bCursorMarker, 'Value', 0);
            imageNVCObj.SetCursor(handles);
        else
            set(handles.bZoom, 'Value', 1);
        end
    end

% --- Executes on button press in bZoom.
    function bCursorLocation_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        if get(handles.bCursorLocation, 'Value')
            set(handles.bZoom, 'Value', 0);
            set(handles.bCursorMarker, 'Value', 0);
            imageNVCObj.SetCursor(handles);
        else
            set(handles.bCursorLocation, 'Value', 1);
        end
    end

% --- Executes on button press in SaveImage.
    function Save_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ImageSave('Save', handles);
    end

% --- Executes on button press in SaveAs.
    function SaveAs_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ImageSave('SaveAs', handles);
    end

% --- Executes on button press in Load.
    function Load_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ImageLoad('Load', handles);
    end

% --- Executes on button press in LoadPrevious.
    function LoadPrevious_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ImageLoad('LoadPrevious', handles);
    end

% --- Executes on button press in LoadNext.
    function LoadNext_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ImageLoad('LoadNext', handles);
    end

% --- Executes on button press in Delete.
    function Delete_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.ImageLoad('Delete', handles);
        
    end

% --- Executes on button press in UpdateNotes.
    function UpdateNotes_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.UpdateNotes(handles);
    end

% --- Executes on button press in DispInFig.
    function DispInFig_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.DisplayInFig(handles);
    end

    function LaserPowerPercentage_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        set(hObject, 'String', cell2mat(regexp(get(handles.LaserPowerPercentage,'String'),'^\d+','match'))); % Remove the %
        CheckValueInLimits(handles.LaserPowerPercentage, 0, 100); % Check value
        set(handles.LaserPower, 'Value', str2double(get(handles.LaserPowerPercentage,'String'))/100) % Set the bar
        imageNVCObj.SetLaserPower(handles); % Set power according to the bar
        set(hObject, 'String', sprintf('%d%%', round(str2double(get(handles.LaserPowerPercentage, 'String'))))); % Add the %
    end

% --- Executes on slider movement.
    function LaserPower_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.SetLaserPower(handles);
        set(handles.LaserPowerPercentage, 'String', sprintf('%d%%', round(100*get(handles.LaserPower,'Value'))))
        set(handles.LaserPowerPercentage, 'UserData', sprintf('%d%%', round(100*get(handles.LaserPower,'Value'))))
    end

    function STEDLaserPowerPercentage_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        set(hObject, 'String', cell2mat(regexp(get(handles.STEDLaserPowerPercentage,'String'),'^\d+','match'))); % Remove the %
        CheckValueInLimits(handles.STEDLaserPowerPercentage, 0, 100); % Check value
        set(handles.LaserPower, 'Value', str2double(get(handles.STEDLaserPowerPercentage,'String'))/100) % Set the bar
        imageNVCObj.SetSTEDLaserPower(handles); % Set power according to the bar
        set(hObject, 'String', sprintf('%d%%', round(str2double(get(handles.STEDLaserPowerPercentage, 'String'))))); % Add the %
    end

% --- Executes on slider movement.
    function STEDLaserPower_Callback(hObject, eventdata, handles)
        % handles    structure with handles to all objects in the GUI
        imageNVCObj.SetSTEDLaserPower(handles);
        set(handles.STEDLaserPowerPercentage, 'String', sprintf('%d%%', round(100*get(handles.STEDLaserPower,'Value'))))
        set(handles.STEDLaserPowerPercentage, 'UserData', sprintf('%d%%', round(100*get(handles.STEDLaserPower,'Value'))))
    end

    function SetFromCurrentPos_Callback(hObject, eventdata, handles, rowNum)
        % Sets the tilt angle calculator row from the current pos.
        pos = imageNVCObj.getPos(); %#ok<NASGU>
        
        eval(sprintf('set(handles.x%d, ''String'', num2str(pos(1)))', rowNum));
        eval(sprintf('set(handles.x%d, ''UserData'', num2str(pos(1)))', rowNum));
        
        eval(sprintf('set(handles.y%d, ''String'', num2str(pos(2)))', rowNum));
        eval(sprintf('set(handles.y%d, ''UserData'', num2str(pos(2)))', rowNum));
        
        eval(sprintf('set(handles.z%d, ''String'', num2str(pos(3)))', rowNum));
        eval(sprintf('set(handles.z%d, ''UserData'', num2str(pos(3)))', rowNum));
    end

    function CalculateAngles_Callback(hObject, eventdata, handles)
        % Calculates the tilt angles
        
        deltaX12 = str2double(get(handles.x2, 'String')) - str2double(get(handles.x1, 'String'));
        deltaX23 = str2double(get(handles.x3, 'String')) - str2double(get(handles.x2, 'String'));
        
        deltaY12 = str2double(get(handles.y2, 'String')) - str2double(get(handles.y1, 'String'));
        deltaY23 = str2double(get(handles.y3, 'String')) - str2double(get(handles.y2, 'String'));
        
        deltaZ12 = str2double(get(handles.z2, 'String')) - str2double(get(handles.z1, 'String'));
        deltaZ23 = str2double(get(handles.z3, 'String')) - str2double(get(handles.z2, 'String'));
        
        anglesVec = atan([deltaX12 deltaY12; deltaX23 deltaY23]^-1*[deltaZ12; deltaZ23])*180/pi;
        
        anglesVec(isnan(anglesVec)) = 0; % This means that deltaZ was zero, so angle should be zero
        
        set(handles.ThetaX, 'String', anglesVec(1));
        set(handles.ThetaY, 'String', anglesVec(2));
        
        AngleValidation_Callback(hObject, eventdata, handles);
    end

    function bEnableAngle_Callback(hObject, eventdata, handles)
        % Enables or disables the tilt angle correction
        enable = get(handles.bEnableAngle, 'Value');
        success = imageNVCObj.EnableTiltAngle(enable);
        if ~success
            set(handles.bEnableAngle, 'Value', ~enable);
        end
    end

    function AngleValidation_Callback(hObject, eventdata, handles)
        oldValueX = get(handles.ThetaX, 'UserData');
        oldValueY = get(handles.ThetaY, 'UserData');
        valueX = str2double(get(handles.ThetaX, 'String'));
        valueY = str2double(get(handles.ThetaY, 'String'));
        
        success = imageNVCObj.SetTiltAngle(valueX, valueY);
        
        if ~success
            set(handles.ThetaX, 'String', oldValueX);
            set(handles.ThetaY, 'String', oldValueY);
        else
            set(handles.ThetaX, 'UserData', valueX);
            set(handles.ThetaY, 'UserData', valueY);
        end
    end

    function CloseRequestFcn_Callback(hObject, eventdata, handles) %#ok<INUSD>
        try
            selection = questdlg('Are you sure you want to close ImageNVC_STED?',...
                'Close Request Function',...
                'Yes','No','Yes');
            switch selection
                case 'Yes'
                    imageNVCObj.Close()
                    delete(gcf)
                case 'No'
                    return
            end
        catch err
            delete(gcf)
            rethrow(err)
        end
    end
end