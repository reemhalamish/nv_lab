classdef StageScanner < EventSender & EventListener & Savable
    %STAGESCANNER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mScan
        mStageName
        mStageScanParams
        mCurrentlyScanning = false
    end
    
    properties (Constant)
        NAME = 'stageScanner'
        
        EVENT_SCAN_UPDATED = 'scanUpdated'
        EVENT_SCAN_STARTED = 'scanStarted'
        EVENT_SCAN_FINISHED = 'scanFinished'
        EVENT_SCAN_STOPPED_MANUALLY = 'scanStoppedManually'
        % events can be sent with both EVENT_SCAN_FINISHED and EVENT_SCAN_STOPPED_MANUALLY
        % such events will always have EVENT_SCAN_FINISHED = true,
        %                and will have EVENT_SCAN_STOPPED_MANUALLY = (true or false)
        
        PROPERTY_SCAN_PARAMS = 'scanParameters'
        
        TRIALS_AMOUNT_ON_ERROR = 4;
    end
    
    methods (Access = private)
        function obj = StageScanner
            obj@EventSender(StageScanner.NAME);
            obj@Savable(StageScanner.NAME);
            obj@EventListener(SaveLoadCatImage.NAME);
            obj.clear();
        end
    end
    
    methods
        function sendEventScanFinished(obj)
            obj.sendEvent(struct( ...
                obj.EVENT_SCAN_FINISHED, true, ...
                obj.EVENT_SCAN_STOPPED_MANUALLY, false, ...
                obj.PROPERTY_SCAN_PARAMS, obj.mStageScanParams));
        end
        function sendEventScanStopped(obj)
            obj.sendEvent(struct(...
                obj.EVENT_SCAN_FINISHED, true, ...
                obj.EVENT_SCAN_STOPPED_MANUALLY, true, ...
                obj.PROPERTY_SCAN_PARAMS, obj.mStageScanParams));
        end
        function sendEventScanStarting(obj)
            obj.sendEvent(struct(obj.EVENT_SCAN_STARTED, true));
        end
        function sendEventScanUpdated(obj, scanResults)
            axis1 = obj.mStageScanParams.getFirstScanAxisVector;
            axis2 = obj.mStageScanParams.getSecondScanAxisVector;
            phAxes = {axis1, axis2};
            scanAxes = obj.mStageScanParams.getScanAxes;
            stageName = obj.mStageName;
            botLabel = obj.getBottomScanLabel;
            leftLabel = obj.getLeftScanLabel;
            extra = EventExtraScanUpdated(scanResults, phAxes, scanAxes, stageName, botLabel, leftLabel);
            obj.sendEvent(struct(obj.EVENT_SCAN_UPDATED, extra));
        end
        
        function startScan(obj)
            if isnan(obj.mStageName)
                obj.sendError(['Can''t start scan: unknown stage name!' ...
                    'Please call stageScanner.switchTo(your_stage_name)' ...
                    'before calling stageScanner.startScan(). Exiting']);
            end
            
            stage = getObjByName(obj.mStageName);
            obj.mStageScanParams = stage.scanParams.copy;
            isFastScan = obj.mStageScanParams.fastScan;
            stage.FastScan(isFastScan);
            
            % From now on, changes in the GUI (from\to\fixed\numPoints)
            % won't affect the StageScanParmas object stored here.
            
            obj.mCurrentlyScanning = true;
            obj.sendEventScanStarting();
            
            spcm = getObjByName(Spcm.NAME);
            spcm.setSPCMEnable(true);
            
            stage.sanityCheckForScanRange(obj.mStageScanParams);
            
            timerVal = tic;
            disp('Initiating scan...');
            kcpsScanMatrix = obj.scan(stage, spcm, obj.mStageScanParams);
            % kcps = kilo counts per second
            
            while (stage.scanParams.continuous && obj.mCurrentlyScanning)
                kcpsScanMatrix = obj.scan(stage, spcm, obj.mStageScanParams, kcpsScanMatrix);
                drawnow; % todo check what happens if removing this line
            end
            
            if isempty(kcpsScanMatrix)  % Maybe scan did not happen at all
                spcm.setSPCMEnable(false);
                obj.mCurrentlyScanning = false;
                return
            end
            
            toc(timerVal)
            
            spcm.setSPCMEnable(false);
            obj.mScan = kcpsScanMatrix;

            scanStoppedManually = ~obj.mCurrentlyScanning;  % maybe someone has changed this boolean meanwhile
            obj.mCurrentlyScanning = false;                 % So when events are sent, they will know we are done.
            
            if scanStoppedManually
                obj.sendEventScanStopped();
            else
                obj.sendEventScanFinished();
            end
            % (At least) two things should happen by this event:
            % 1. ImageScanResult will update
            % 2. SaveLoad will get the new scan, save it into local
            %    struct, and (if needed) will autosave it.
            
            stage.sendEventPositionChanged;
        end
        
        
        function kcpsScanMatrix = scan(obj, stage, spcm, scanParams, kcpsScanMatrixOptional)
            % Scan the stage.
            % stage - an object deriving from ClassStage
            % spcm - an object deriving from Spcm
            % scanParams - the scan parameters. an object deriving from StageScanParams
            % kcpsScanMatrixOptional - the last scanned matrix, if exists
            skipCreatingMatrix = exist('kcpsScanMatrixOptional', 'var');
            
            kcpsScanMatrix = [];        % Return value for nonvalid dinemsion number
            nDimensions = sum(~scanParams.isFixed);
            switch nDimensions
                case 0
                    EventStation.anonymousWarning('Nothing to scan, dude!');
                    return;
                case 1
                    % One dimensional scanning
                    kcpsScanMatrix = obj.scan1D(stage, spcm, scanParams);
                case 2
                    % 2D scan
                    if skipCreatingMatrix
                        kcpsScanMatrix = obj.scan2D(stage, spcm, scanParams, kcpsScanMatrixOptional);
                    else
                        kcpsScanMatrix = obj.scan2D(stage, spcm, scanParams);
                    end
                case 3
                    EventStation.anonymousWarning('3D scan is not implemented!');
                otherwise
                    EventStation.anonymousWarning('%d-dimensional scan requested. String thoery is not yet implemented!\n', nDimensions);
            end
        end
        
        function kcpsValue = scanPoint(obj, stage, spcm, scanParams)
            % scan "0D"
            % input arg's:
            %    stage - object deriving from ClassStage
            %    spcm - object deriving from Spcm
            %    scanParams - object deriving from StageScanParams
            % output:
            %    kcpsValue - double. Value read by the spcm
            
            % To be used by TrackablePosition. Should NOT be used for
            % actual scanning.
            
            %%%% move to location %%%%
            pos = scanParams.fixedPos;
            phAxes = stage.availableAxes;
            stage.move(phAxes, pos);
            
            %%%% try to scan %%%%
            scanOk = false;
            for trial = 1:StageScanner.TRIALS_AMOUNT_ON_ERROR
                try
                    spcm.prepareReadByTime(scanParams.pixelTime);
                    [kcps, ~] = spcm.readFromTime();
                    spcm.clearTimeRead;
                    if kcps == 0
                        obj.sendError('No Signal Detected!')
                    end
                    scanOk = true;
                    break;
                catch err
                    %                    rethrow(err) % Uncomment to debug
                    warning(err.message);
                    fprintf('Reading from SPCM failed at trial %d, attempting to rescan.\n', trial);
                end
            end
            
            % This line will be reached when break()ing out of the for,
            % or when all trials went without success
            if ~scanOk
                obj.sendError(sprintf('Reading from SPCM failed after %d trials', StageScanner.TRIALS_AMOUNT_ON_ERROR));
            end
            
            kcpsValue = kcps;
        end
        
        function kcpsScanVector = scan1D(obj, stage, spcm, scanParams)
            % scan 1D
            % stage - an object deriving from ClassStage
            % spcm - an object deriving from Spcm
            % scanParams - the scan parameters. an object deriving from StageScanParams
            % returns - a vector of the scan
            
            % If the area to scan is bigger than the maximum scanning-area
            % of the stage, divide it to smallers chunks to scan
 
            % ~~~~ preparing variables: ~~~~
            isFastScan = scanParams.fastScan;
            nFlat = 0;      % A flat section at the start of ramp. parameter not needed genrally, a stage can overwrite if needed
            nOverRun = 0;   % Let the waveform over run the start and end. Not needed genrally, a stage can overwrite if needed
            tPixel = scanParams.pixelTime;
            maxScanSize = stage.ReturnMaxScanSize(1);
            nPixels = length(scanParams.getFirstScanAxisVector());
            kcpsScanVector = zeros(1, nPixels);
            axisToScan = scanParams.getScanAxes; % string of size 1
            x = scanParams.getScanAxisVector(1); %#ok<NASGU> % vector between [min, max] or the fixed position if exist
            y = scanParams.getScanAxisVector(2); %#ok<NASGU> % vector between [min, max] or the fixed position if exist
            z = scanParams.getScanAxisVector(3); %#ok<NASGU> % vector between [min, max] or the fixed position if exist
            
            if ~obj.mCurrentlyScanning
                return
            end
            
            % ~~~~ checks on size of scan ~~~~
            if (nPixels > maxScanSize)
                fprintf('Max number of points to scan is %d, %d were requested for %s axis. Scanning in parts.\n', maxScanSize, nPixels, axisToScan);
            end
            
            % ~~~~ continue scanning until finishing all the scan ~~~~
            
            vectorStartIndex = 1;
            while (vectorStartIndex <= nPixels)
                % every iteration in the "while" scans one chunk
                pixelsLeftToScan = nPixels - vectorStartIndex + 1;
                curPixelsAmountToScan = min(pixelsLeftToScan, maxScanSize);
                vectorEndIndex = vectorStartIndex + curPixelsAmountToScan - 1;
                nPoints = curPixelsAmountToScan + 2*(nFlat + nOverRun);
                timeout = 2*nPoints*tPixel;
                scanOk = false;
                
                % Prepare Scan
                eval(sprintf('stage.PrepareScan%s(x, y, z, nFlat, nOverRun, tPixel);', upper(axisToScan)));
                
                % try to scan
                for trial = 1:StageScanner.TRIALS_AMOUNT_ON_ERROR
                    try
                        if ~obj.mCurrentlyScanning
                            stage.AbortScan();
                            spcm.clearScanRead();  % todo - added to try resolving the problem. wasn't here at the first place!
                            return
                        end
                        
                        spcm.prepareReadByStage(stage.name, curPixelsAmountToScan, timeout, isFastScan);
                        
                        spcm.startScanRead();
                        
                        % scan stage
                        eval(sprintf('stage.Scan%s(x,y,z, nFlat, nOverRun, tPixel);', upper(axisToScan)));
                        
                        % read counter
                        kcps = spcm.readFromScan();
                        spcm.clearScanRead();
                        if ~nnz(kcps)
                            obj.sendError('No Signal Detected!')
                        end
                        scanOk = true;
                        %obj.sendEventScanUpdated(kcpsScanVector); %Yoav: not needed
                        break;
                    catch err
%                         rethrow(err) % Uncomment to debug
                        warning(err.message);
                        
                        if ~obj.mCurrentlyScanning
                            stage.AbortScan();
                            return
                        end
                        fprintf('Scan failed at trial %d, attempting to rescan.\n', trial);
                    end
                end
                
                
                % This line will be reached when break()ing out of the for,
                % or when all trials went without success
                stage.AbortScan();
                if ~scanOk; obj.sendError(sprintf('Scan failed after %d trials', StageScanner.TRIALS_AMOUNT_ON_ERROR));end
                
                % Update the scan results in the returned vector
                kcpsScanVector(vectorStartIndex: vectorEndIndex) = kcps;
                
                % Go tell everybody
                obj.sendEventScanUpdated(kcpsScanVector);
                
                % Prepare the next scan chunk
                vectorStartIndex = vectorEndIndex + 1;
                
            end
        end
        
        function kcpsScanMatrix = scan2D(obj, stage, spcm, scanParams, optionalKcpsScanMatrix)
            % Scans a 2D image.
            % stage - an object deriving from ClassStage
            % spcm - an object deriving from Spcm
            % scanParams - the scan parameters. an object deriving from StageScanParams
            % optionalKcpsScanMatrix - if exists, the previous scan results
            % returns - a matrix of the scan
            
            
            % Method:
            % First, check what would be the best way to scan (minimize
            % amount of scans needed)
            % Then, call scan2dChunk for each chunk to get scan results and combine them together
            
            % The movement between pixels in each line is called "axis a",
            % while movement between lines is called "axis b"
            
            if ~obj.mCurrentlyScanning
                return
            end
            
            % ~~~~ preparing variables: ~~~~
            maxScanSize = stage.ReturnMaxScanSize(2);
            [axisAIndex, axisBIndex] = StageScanner.optimize2dScanDirections(maxScanSize, scanParams.copy);
            axisCIndex = setdiff(ClassStage.getAxis(ClassStage.SCAN_AXES), [axisAIndex, axisBIndex]);
            % axis c is where the zero point is not moving throgh the scan
            isFlipped = axisAIndex > axisBIndex;  % (for example, if axis y is before axis x, than "isFlipped" == true)
            isFastScan = scanParams.fastScan;    % a boolean
            tPixel = scanParams.pixelTime;   % time for each pixel
            numPointsAxisA = scanParams.numPoints(axisAIndex);
            numLinesAxisB = scanParams.numPoints(axisBIndex);
            letterAxisA = ClassStage.getAxis(axisAIndex);       %todo: needed?
            letterAxisB = ClassStage.getAxis(axisBIndex);       %todo: needed?
            vectorAxisA = scanParams.getScanAxisVector(axisAIndex);
            vectorAxisB = scanParams.getScanAxisVector(axisBIndex);
            pointAxisC = scanParams.getScanAxisVector(axisCIndex);
            chunksPerLine = ceil(numPointsAxisA / maxScanSize);
            
            if exist('optionalKcpsScanMatrix', 'var')
                kcpsScanMatrix = optionalKcpsScanMatrix;
            else
                if isFlipped
                    kcpsScanMatrix = zeros(numPointsAxisA, numLinesAxisB);
                else
                    kcpsScanMatrix = zeros(numLinesAxisB, numPointsAxisA);
                end
            end
            obj.mScan = kcpsScanMatrix;
            
            
            %%%%%% iterate through the chunks and scan each chunk %%%%%%%
            startIndexAxisA = 1;
            for chunkIndex = 1 : chunksPerLine
                if ~obj.mCurrentlyScanning
                    break;
                end
                
                pixelsLeftAxisA = numPointsAxisA - startIndexAxisA + 1;
                chunkSizeAxisA = min(maxScanSize, pixelsLeftAxisA);
                endIndexAxisA = startIndexAxisA + chunkSizeAxisA - 1;
                chunkAxisA = vectorAxisA(startIndexAxisA:endIndexAxisA);
                chunkAxisB = vectorAxisB;  % no restriction on number of lines!
                kcpsScanMatrix = obj.scan2dChunk(...
                    kcpsScanMatrix, spcm, stage, tPixel, chunkAxisA, chunkAxisB, ...
                    axisAIndex, axisBIndex, pointAxisC, isFastScan, isFlipped, ...
                    1, length(chunkAxisB), ...
                    startIndexAxisA, endIndexAxisA);
                obj.mScan = kcpsScanMatrix;
                obj.sendEventScanUpdated(kcpsScanMatrix);
            end
        end
        
        function kcpsMatrix = scan2dChunk(...
                obj, ...  StageScanner object
                kcpsMatrix, ... scan matrix (maybe partly filled)
                spcm, ... Spcm object
                stage, ... Stage object. to scan
                tPixel, ... double. Time per pixel (in sec)
                axisAPixelsPerLine, ... vector of double
                axisBLinesPerScan, ... vector of double
                axisADirectionIndex, ... integer. Index in {1, 2, 3} for "xyz"
                axisBDirectionIndex, ... integer. Index in {1, 2, 3} for "xyz"
                axisCPoint0, ... scalar. Zero point in the 3rd axis
                isFastScan, ... logical
                isFlipped, ... logical. Is the matrix flipped or not
                matrixIndexLineStart, ... integer. Index at which to start inserting lines to the matrix
                matrixIndexLineEnd, ... integer. Index at which to stop inserting lines to the matrix
                matrixIndexPixelInLineStart, ... integer. Index at which to start inserting pixels to the line in the matrix
                matrixIndexPixelInLineEnd ... integer. Index in which to stop inserting pixels to the line in the matrix
                )
            % This function scans a chunk from the scan-matrix
            if length(axisAPixelsPerLine) ~= matrixIndexPixelInLineEnd - matrixIndexPixelInLineStart + 1
                obj.sendError('Can''t scan - mismatch size of vector!')
            end
            if length(axisBLinesPerScan) ~= matrixIndexLineEnd - matrixIndexLineStart + 1
                obj.sendError('Can''t scan - mismatch size of vector!')
            end
            
            if ~obj.mCurrentlyScanning; return; end %Yoav: Will create error because no output. Nadav: or will it?
            
            % for each in {x, y, z}, it could be one of:
            % the axisA vector, the axisB vector, or the axisC point
            [x, y, z] = obj.getXYZfor2dScanChunk(axisAPixelsPerLine, axisBLinesPerScan, axisADirectionIndex, axisBDirectionIndex, axisCPoint0); %#ok<ASGLU>
            nPixels = length(axisAPixelsPerLine);
            timeout = 2*nPixels*tPixel;
            
            % prepare scan
            nFlat = 0;      % A flat section at the start of ramp. parameter not needed genrally, a stage can overwrite if needed. BACKWARD_COPITABILITY
            nOverRun = 0;   % Let the waveform over run the start and end. Not needed genrally, a stage can overwrite if needed. BACKWARD_COPITABILITY
            axesLettersUpper = upper(ClassStage.SCAN_AXES([axisADirectionIndex, axisBDirectionIndex]));
            eval(sprintf('stage.PrepareScan%s(x, y, z, nFlat, nOverRun, tPixel);', axesLettersUpper));
            spcm.prepareReadByStage(stage.name, nPixels, timeout, isFastScan);
            
            % do the scan
            spcm.startScanRead();
            for lineIndex = matrixIndexLineStart : matrixIndexLineEnd
                if ~obj.mCurrentlyScanning; break; end
                success = false;
                for trial = 1 : StageScanner.TRIALS_AMOUNT_ON_ERROR
                    try
                        wasScannedForward = stage.ScanNextLine();
                        % forwards - if true, the line was scanned normally,
                        %            if false - should flip the results
                        kcpsVector = spcm.readFromScan();
                                                
                        kcpsVector = BooleanHelper.ifTrueElse(wasScannedForward, kcpsVector, fliplr(kcpsVector));
                        if isFlipped
                            kcpsMatrix(matrixIndexPixelInLineStart: matrixIndexPixelInLineEnd, lineIndex) = kcpsVector;
                        else
                            kcpsMatrix(lineIndex, matrixIndexPixelInLineStart: matrixIndexPixelInLineEnd) = kcpsVector;
                        end
                        obj.sendEventScanUpdated(kcpsMatrix);
                        success = true;
                        break;
                    catch err
%                         rethrow(err);  % Uncomment to debug
                        obj.sendWarning(err.message);
                        if ~obj.mCurrentlyScanning
                            stage.AbortScan();
                            spcm.clearScanRead();
                            return;
                        end
                        
                        fprintf('Line %d failed at trial %d, attempting to rescan line.\n', lineIndex, trial);
                        
                        try
                            stage.PrepareRescanLine(); % Prepare to rescan the line
                        catch err2
                            stage.AbortScan();
                            spcm.clearScanRead();
                            rethrow(err2)
                        end
                    end % try catch
                end % for trial = 1 : StageScanner.TRIALS_AMOUNT_ON_ERROR
                
                if ~success
                    % We failed at reading the line, so there is probably
                    % no point in scanning next line
                    obj.mCurrentlyScanning = false;     % will abort the scan
                end
            end % lineIndex = 1 : length(axisBLinesPerScan)
            stage.AbortScan();
            spcm.clearScanRead();
        end
        
        function [x,y,z] = getXYZfor2dScanChunk(obj, axisAPointsPerLine, axisBLinesPerScan, axisADirectionIndex, axisBDirectionIndex, axisCPoint0) %#ok<INUSD,STOUT,INUSL>
            % Converts from "axisA", "axisB", to xyz: calculates the vectors for x,y,z to be used in scan2dChunk()
            for letter = ClassStage.SCAN_AXES
                % Iterate over the string "xyz" letter by letter
                ll = lower(letter);
                switch ClassStage.getAxis(letter)
                    case axisADirectionIndex
                        eval(sprintf('%s = axisAPointsPerLine;', ll));
                    case axisBDirectionIndex
                        eval(sprintf('%s = axisBLinesPerScan;', ll));
                    otherwise
                        eval(sprintf('%s = axisCPoint0;', ll));
                end
            end
        end
        
        
        function stopScan(obj)
            obj.mCurrentlyScanning = false;
            % todo: check maybe we need also
            %   stage = getObjByName(obj.mStageName);
            %   stage.scanRunning = false;
        end
        
        function switchTo(obj, newStageName)
            if obj.mCurrentlyScanning && ~strcmp(obj.mStageName, newStageName)
                obj.sendError('Can''t switch stage when scan running!');
            end
            obj.mStageName = newStageName;
        end
        
        function autosaveAfterScan(obj)
            saveLoad = SaveLoad.getInstance(Savable.CATEGORY_IMAGE);
            saveLoad.autoSave();
        end
        
        function number = getScanDimensions(obj)
            number = sum(~obj.mStageScanParams.isFixed);
        end
    end
    
    methods
        function clear(obj)
            if (obj.mCurrentlyScanning)
                obj.stopScan();
            end
            
            obj.mScan = nan;
            obj.mStageName = nan;
            obj.mStageScanParams = nan;
            obj.mCurrentlyScanning = false;     % probably redundant; appears in obj.stopScan
        end
        
        function dummyScan(obj)
            obj.sendEventScanStarting();
            obj.mStageName = ClassStage.getStages{1}.name;
            data = 5 + peaks;
            obj.mScan = data;
            obj.mStageScanParams = StageScanParams([0,0,0], [48,48,48], [49,49,49], [0,0,0], [false false true], 1, 0, 0, 0);
            obj.sendEventScanUpdated(data);
            obj.sendEventScanFinished();
            obj.autosaveAfterScan();
        end
        
        function value = dummyScanGaussian(obj,scanParams)
            pos = scanParams.fixedPos;
            stage = getObjByName(obj.mStageName);
            phAxes = stage.availableAxes;
            stage.move(phAxes, pos);
            
            X = scanParams.getScanAxisVector(1);
            Y = scanParams.getScanAxisVector(2);
            Z = scanParams.getScanAxisVector(3);
            f = @(x,y,z) 100*exp(-((z+5).^2+x.^2+(y-7).^2)/100);   % some test function
            value = f(X,Y,Z);
        end
        
        function boolean = isScanReady(obj)
            boolean = ~isnan(obj.mScan);
        end
        
        function string = getBottomScanLabel(obj)
            axisLetters = obj.mStageScanParams.getScanAxes;
            switch obj.getScanDimensions
                case 1
                    string = sprintf('%s [%s]', axisLetters, StringHelper.MICRON); % for example, 'x (?m)'
                case 2
                    string = sprintf('%s [%s]', axisLetters(1), StringHelper.MICRON); % (as above)
                otherwise
                    string = 'bottom label :)';
            end
        end
        
        function string = getLeftScanLabel(obj)
            switch obj.getScanDimensions
                case 1
                    string = 'kcps';
                case 2
                    axisLetters = obj.mStageScanParams.getScanAxes;
                    string = sprintf('%s [%s]', axisLetters(2), StringHelper.MICRON); % for example, 'y (?m)'
                otherwise
                    string = 'left label :)';
            end
        end
    end
    
    methods (Static)
        function obj = init
            try
                obj = getObjByName(StageScanner.NAME);
            catch
                obj = StageScanner;
                addBaseObject(obj);
            end
        end
        
        function [axisAIndex, axisBIndex] = optimize2dScanDirections(stageMaxScanSizeInt, scanParams)
            % calculates the best way to scan a 2d scan (given by the scanParams)
            % the movement between pixels in each line is called "axis a",
            % while movement between lines is called "axis b"
            %
            % returns:
            % axisAIndex - for each line in the 2d-scan, scan the pixels in the line in this direction
            % axisBIndex - move between lines in this direction
            %
            % for example, in a 2D scan (XY) where x is [0...30] and y is
            % [0...70] and maxScanSize is 100, the returned values will be:
            % axisAIndex  = 2 (Y)
            % axisBIndex  = 1 (X)
            % as the optimized results will be 30 scans
            
            firstAxisIndex = scanParams.getFirstScanAxisIndex();
            secondAxisIndex = scanParams.getSecondScanAxisIndex();
            
            firstAxisNumPoints = scanParams.numPoints(firstAxisIndex);
            secondAxisNumPoints = scanParams.numPoints(secondAxisIndex);
            
            % Option ONE: scan each line by axis 1, move between lines in axis 2
            % Calculate how many steps would be needed then:
            timesMaxInFirst = ceil(firstAxisNumPoints / stageMaxScanSizeInt);
            totalTimesOptionOne = timesMaxInFirst * secondAxisNumPoints;
            
            % Option TWO: scan each line by axis 2, move between lines in axis 1
            % Calculate how many steps would be needed then:
            timesMaxInSecond = ceil(secondAxisNumPoints / stageMaxScanSizeInt);
            totalTimesOptionTwo = timesMaxInSecond * firstAxisNumPoints;
            
            if totalTimesOptionOne <= totalTimesOptionTwo
                axisAIndex = firstAxisIndex;
                axisBIndex = secondAxisIndex;
            else
                axisAIndex = secondAxisIndex;
                axisBIndex = firstAxisIndex;
            end
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            % Check if event is "loaded file to SaveLoad" and need to show the image
            if strcmp(event.creator.name, SaveLoadCatImage.NAME) ...
                    && isfield(event.extraInfo, SaveLoad.EVENT_LOAD_SUCCESS_FILE_TO_LOCAL)
                % Need to load the image!
                category = Savable.CATEGORY_IMAGE;
                subcat = Savable.SUB_CATEGORY_DEFAULT;
                saveLoad = event.creator;
                struct = saveLoad.getStructToSavable(obj);
                if ~isempty(struct)
                    obj.loadStateFromStruct(struct, category, subcat);
                end
            end
        end
    end
    
    %% overriding from Savable
    methods (Access = protected)
        function outStruct = saveStateAsStruct(obj, category, type)
            % Saves the state as struct. if you want to save stuff, make
            % (outStruct = struct;) and put stuff inside. If you dont
            % want to save, make (outStruct = NaN;)
            %
            % category - string. Some objects saves themself only with
            %                    specific category (image/experimetns/etc)
            % type - string.     Whether the objects saves at the beginning
            %                    of the run (parameter) or at its end (result)
            if ~strcmp(category, Savable.CATEGORY_IMAGE)
                outStruct = nan;
                return
            end
            
            outStruct = struct;
            switch type
                case Savable.TYPE_PARAMS
                    outStruct.scanParams = obj.mStageScanParams.asStruct();
                    outStruct.stageName = obj.mStageName;
                case Savable.TYPE_RESULTS
                    if isnan(obj.mScan)
                        outStruct = NaN;
                    else
                        outStruct.scan = obj.mScan;
                    end
            end
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory)
            % Loads the state from a struct.
            % to support older versions, always check for a value in the
            % struct before using it. View example in the first line.
            if ~strcmp(category, Savable.CATEGORY_IMAGE); return; end
            if ~any(strcmp(subCategory, {Savable.CATEGORY_IMAGE_SUBCAT_STAGE})); return; end
            
            
            % for field = {'scan', 'scanParams', 'stageName'} - removed 'scan', for when scan has not yet been saved.
            for field = {'scanParams', 'stageName'}
                if ~isfield(savedStruct, field{:})
                    return
                end
            end
            if ~isfield(savedStruct, 'scan')
                savedStruct.scan = [];
                obj.sendWarning('No scan results found. Loading only scan parameters');
            end
            try
                getObjByName(savedStruct.stageName);
            catch
                obj.sendWarning(sprintf('Can''t load stage! No stage with name "%s"', savedStruct.stageName));
                return
            end
            obj.mStageScanParams = StageScanParams.fromStruct(savedStruct.scanParams);
            stage = getObjByName(savedStruct.stageName);
            stage.scanParams = obj.mStageScanParams; % This will send an event that the scan-parameters have changed
            
            obj.mScan = savedStruct.scan;
            obj.mStageName = savedStruct.stageName;
            obj.sendEventScanUpdated(savedStruct.scan);
        end
        
        function string = returnReadableString(~, savedStruct)
            % Return a readable string to be shown. If this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '');
            
            string = NaN;
            % for field = {'scan', 'scanParams', 'stageName'} - removed 'scan', for when scan has not yet been saved.
            for field = {'scanParams', 'stageName'}
                if ~isfield(savedStruct, field{:})
                    return
                end
            end
            
            % Getting initial information from scan parameters, ...
            params = savedStruct.scanParams;
            scanAxes = find(~params.isFixed);
            fixAxes = find(params.isFixed);
            
            stageName = savedStruct.stageName;
            
            % so we can create the output string
            string = sprintf('Scanning %s %s:', stageName, upper(scanAxes));
            
            indentation = 5;
            for i = 1:length(fixAxes)
                index = fixAxes(i);
                ax = ClassStage.GetLetterFromAxis(index);
                position = params.fixedPos(index);
                axisString = sprintf('%s position: %.3f', upper(ax), position);
                string = sprintf('%s\n%s', string, ...
                    StringHelper.indent(axisString, indentation));
            end
            for i = 1:length(scanAxes)
                index = scanAxes(i);
                ax = ClassStage.GetLetterFromAxis(index);
                from = params.from(index);
                to = params.to(index);
                numPoints = params.numPoints(index);
                axisString = sprintf('%s: %d points from %.3f to %.3f', upper(ax), numPoints, from, to);
                string = sprintf('%s\n%s', string, ...
                    StringHelper.indent(axisString, indentation));
            end

        end
    end
end