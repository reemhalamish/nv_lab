classdef StageScanner < EventSender & Savable
    %STAGESCANNER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mScan
        mStageName
        mStageScanParams
        mCurrentlyScanning = false
    end
    
    properties(Constant = true)
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
    
    methods(Access = private)
        function obj = StageScanner
            obj@EventSender(StageScanner.NAME);
            obj@Savable(StageScanner.NAME);
            addBaseObject(obj);
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
            dimNumber = obj.getScanDimensions;
            axis1 = obj.mStageScanParams.getFirstScanAxisVector();
            axis2 = obj.mStageScanParams.getSecondScanAxisVector();
            axes = {axis1, axis2};
            botLabel = obj.getBottomScanLabel;
            leftLabel = obj.getLeftScanLabel;
            extra = EventExtraScanUpdated(scanResults, dimNumber, axes, botLabel, leftLabel);
            obj.sendEvent(struct(obj.EVENT_SCAN_UPDATED, extra));
        end
        
        function startScan(obj)
            if isnan(obj.mStageName); obj.sendError('Can''t start scan: unknown stage name! please call stageScanner.switchTo(your_stage_name) before calling stageScanner.startScan(). exiting'); end
            
            obj.mCurrentlyScanning = true;
            obj.sendEventScanStarting();
            % todo here the track will need to catch this!
            
            
            spcm = getObjByName(Spcm.NAME);
            spcm.setSPCMEnable(true);
            
            stage = getObjByName(obj.mStageName);
            obj.mStageScanParams = stage.scanParams.copy;
            isFastScan = obj.mStageScanParams.fastScan;
            stage.FastScan(isFastScan);
            
            % from now on, changes in the GUI (from\to\fixed\numPoints)
            % won't affect the StageScanParmas object stored here.
            
            timerVal = tic;
            disp('Initiating scan...');
            kcpsScanMatrix = obj.scan(stage, spcm, obj.mStageScanParams);
            % kcps = kilo counts per second
            
            while (stage.scanParams.continuous && obj.mCurrentlyScanning)
                %Yoav: Should not update during scan, probably next
                %line should stay commented
%                 obj.mStageScanParams = stage.scanParams.copy;
                kcpsScanMatrix = obj.scan(stage, spcm, obj.mStageScanParams, kcpsScanMatrix);
                drawnow; % todo check what happens if removing this line
            end
            toc(timerVal)
            
            spcm.setSPCMEnable(false);
            obj.mScan = kcpsScanMatrix;
            
%             %%%%% autoSave %%%%%
%             if obj.mStageScanParams.autoSave
%                 currentScanParams = stage.scanParams;    % save current as temp
%                 stage.scanParams = obj.mStageScanParams;  % revert to old ones
%                 obj.autosaveAfterScan(); % so saving will be with the old scan parameters
%                 stage.scanParams = currentScanParams;  % and... bring them back
%             end
            

            % autosave - when sending this event there will be a save.
            % so let's save with the correct scan parameters
            currentScanParams = stage.scanParams;    % save current as temp
            stage.scanParams = obj.mStageScanParams;  % revert to old ones
            obj.sendEventScanFinished();  % to be catched by the saveLoad
            stage.scanParams = currentScanParams;  % and... bring them back
            
            scanStoppedManually = ~obj.mCurrentlyScanning; % maybe someone has changed this boolean meanwhile
            if scanStoppedManually
                obj.sendEventScanStopped();
            end
            
            stage.sendEvent(struct(ClassStage.EVENT_POSITION_CHANGED, true));
            obj.mCurrentlyScanning = false;
        end
        
        
        function kcpsScanMatrix = scan(obj, stage, spcm, scanParams, kcpsScanMatrixOptional)
            % scan the stage.
            % stage - an object deriving from ClassStage
            % spcm - an object deriving from Spcm
            % scanParams - the scan parameters. an object deriving from StageScanParams
            % kcpsScanMatrixOptional - the last scanned matrix, if exists
            skipCreatingMatrix = exist('kcpsScanMatrixOptional', 'var');
            if ~skipCreatingMatrix
                stage.sanityChecksRaiseErrorIfNeeded(scanParams);
                % because we already trust the scan params
            end
            
            kcpsScanMatrix = [];        % Return value for nonvalid dinemsion number
            nDimentions = sum(~scanParams.isFixed);
            switch nDimentions
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
                    EventStation.anonymousWarning('3D scan not implemented!');
                otherwise
                    EventStation.anonymousWarning('%d dimensional scan request. String thoery not yet implemented!\n', nDimensions);
            end
        end
        
        function kcpsScanVector = scan1D(obj, stage, spcm, scanParams)
            % scan 1D
            % stage - an object deriving from ClassStage
            % spcm - an object deriving from Spcm
            % scanParams - the scan parameters. an object deriving from StageScanParams
            % returns - a vector of the scan
            
            % if the area to scan is bigger than the maximum scanning-area
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
                fprintf('Max number of points to scan is %d, %d were given for %s axis, scanning in parts.\n', maxScanSize, nPixels, axisToScan);
            end
            
            % ~~~~ continue scanning until finishing all the scan ~~~~
            
            vectorStartIndex = 1;
            while (vectorStartIndex <= nPixels)
                % every iteration in the "while" scans one chunk
                pixelsLeftToScan = nPixels - vectorStartIndex + 1;
                curPixelsAmountToScan = min(pixelsLeftToScan, maxScanSize);
                vectorEndIndex = vectorStartIndex + curPixelsAmountToScan - 1;
                nPoints = curPixelsAmountToScan + 2*(nFlat + nOverRun);
                timeout = 10*nPoints*tPixel;
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
                        rethrow(err) % Uncomment to debug
                        warning(err.message);
                        
                        if ~obj.mCurrentlyScanning
                            stage.AbortScan();
                            return
                        end
                        fprintf('Scan failed at trial %d, attempting to rescan.\n', trial);
                    end
                end
                
                
                % this line will be reached when break()ing out of the for,
                % or when all trials went without success
                stage.AbortScan();
                if ~scanOk; obj.sendError(sprintf('Scan failed after %d trials', StageScanner.TRIALS_AMOUNT_ON_ERROR));end
                
                kcpsScanVector(vectorStartIndex: vectorEndIndex) = kcps;
                % update the scan results in the returned vector
                
                obj.sendEventScanUpdated(kcpsScanVector);
                % update the world
                
                vectorStartIndex = vectorEndIndex + 1;
                % prepare the next scan chunk
            end
        end
        
        function kcpsScanMatrix = scan2D(obj, stage, spcm, scanParams, optionalKcpsScanMatrix)
            % scans a 2D image.
            % stage - an object deriving from ClassStage
            % spcm - an object deriving from Spcm
            % scanParams - the scan parameters. an object deriving from StageScanParams
            % optionalKcpsScanMatrix - if exists, the previous scan results
            % returns - a matrix of the scan
            
            
            % way to work:
            % first, check what would be the best way to scan (minimize
            % amount of scans needed)
            % than, call scan2dChunk for each chunk to get scan results and combine them together
            
            % the movement between pixels in each line is called "axis a",
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
            letterAxisA = ClassStage.getAxis(axisAIndex);
            letterAxisB = ClassStage.getAxis(axisBIndex);
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
                obj, ...  the StageScanner object
                kcpsMatrix, ... the (helf filled maybe) scan matrix
                spcm, ... the spcm object
                stage, ... ths stage object to scan
                tPixel, ... timeout per pixel
                axisAPixelsPerLine, ... vector
                axisBLinesPerScan, ... vector
                axisADirectionIndex, ... index in {1, 2, 3} for "xyz"
                axisBDirectionIndex, ... index in {1, 2, 3} for "xyz"
                axisCPoint0, ... scalar. the zero point in the 3rd axis
                isFastScan, ... logical
                isFlipped, ... logical - is the matrix flipped or not
                matrixIndexLineStart, ... the index in which to start insert lines to the matrix
                matrixIndexLineEnd, ... the index in which to stop insert lines to the matrix
                matrixIndexPixelInLineStart, ... the index in which to start inserting pixels to the line in the matrix
                matrixIndexPixelInLineEnd ... the index in which to stop inserting pixels to the line in the matrix
                )
            % this function scans a chunk from the scan-matrix
            if length(axisAPixelsPerLine) ~= matrixIndexPixelInLineEnd - matrixIndexPixelInLineStart + 1
                obj.sendError('can''t scan - mismatch size of vector!')
            end
            if length(axisBLinesPerScan) ~= matrixIndexLineEnd - matrixIndexLineStart + 1
                obj.sendError('can''t scan - mismatch size of vector!')
            end
            
            if ~obj.mCurrentlyScanning; return; end %Yoav: Will create error because no output
            
            % for each in {x, y, z}, it could be one of:
            % the axisA vector, the axisB vector, or the axisC point
            [x, y, z] = obj.getXYZfor2dScanChunk(axisAPixelsPerLine, axisBLinesPerScan, axisADirectionIndex, axisBDirectionIndex, axisCPoint0); %#ok<ASGLU>
            
            % prepare scan
            nFlat = 0;      % A flat section at the start of ramp. parameter not needed genrally, a stage can overwrite if needed. BACKWARD_COPITABILITY
            nOverRun = 0;   % Let the waveform over run the start and end. Not needed genrally, a stage can overwrite if needed. BACKWARD_COPITABILITY
            axesLettersUpper = upper(ClassStage.SCAN_AXES([axisADirectionIndex, axisBDirectionIndex]));
            eval(sprintf('stage.PrepareScan%s(x, y, z, nFlat, nOverRun, tPixel);', axesLettersUpper));
            spcm.prepareReadByStage(stage.name, length(axisAPixelsPerLine), tPixel, isFastScan);
            
            % do the scan
            for lineIndex = matrixIndexLineStart : matrixIndexLineEnd
                if ~obj.mCurrentlyScanning; break; end
                for trial = 1 : StageScanner.TRIALS_AMOUNT_ON_ERROR
                    try
                        isStartedLine = false;
                        spcm.startScanRead()
                        
                        isStartedLine = true;
                        wasScannedForward = stage.ScanNextLine();
                        % forwards - if true, the line was scanned normally,
                        % false - should flip the results
                        kcpsVector = spcm.readFromScan();
                        kcpsVector = BooleanHelper.ifTrueElse(wasScannedForward, kcpsVector, fliplr(kcpsVector));
                        if isFlipped
                            kcpsMatrix(matrixIndexPixelInLineStart: matrixIndexPixelInLineEnd, lineIndex) = kcpsVector;
                        else
                            kcpsMatrix(lineIndex, matrixIndexPixelInLineStart: matrixIndexPixelInLineEnd) = kcpsVector;
                        end
                        obj.sendEventScanUpdated(kcpsMatrix);
                        break;
                    catch err
                        rethrow(err);  % Uncomment to debug
                        obj.sendWarning(err.message);
                        if ~obj.mCurrentlyScanning
                            stage.AbortScan();
                            return;
                        end
                        
                        fprintf('Line %d failed at trial %d, attempting to rescan line.\n', i, trial);
                        
                        if ~isStartedLine
                            try
                                stage.PrepareRescanLine(); % Prepare to rescan the line
                            catch err2
                                stage.AbortScan();
                                rethrow(err2)
                            end
                        end
                        
                        
                        
                    end % try catch
                end % for trial = 1 : StageScanner.TRIALS_AMOUNT_ON_ERROR
                
                
            end % lineIndex = 1 : length(axisBLinesPerScan)
            stage.AbortScan();
        end
        
        function [x,y,z] = getXYZfor2dScanChunk(obj, axisAPointsPerLine, axisBLinesPerScan, axisADirectionIndex, axisBDirectionIndex, axisCPoint0) %#ok<STOUT,INUSL>
            % converts from "axisA", "axisB", to xyz: calculates the vectors for x,y,z to be used in scan2dChunk()
            for letter = ClassStage.SCAN_AXES
                % iterate over the string "xyz" letter by letter
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
        end
        
        function switchTo(obj, newStageName)
            if obj.mCurrentlyScanning && ~strcmp(obj.mStageName, newStageName)
                obj.sendError('can''t switch stage when scan running!');
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
            obj.mCurrentlyScanning = false;
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
        
        function boolean = isScanReady(obj)
            boolean = ~isnan(obj.mScan);
        end
        
        function string = getBottomScanLabel(obj)
            axisString = '%s (\x03bcm)';    % the '\x03bc' string is converted to upright greek mu
            axisLetters = obj.mStageScanParams.getScanAxes;
            switch obj.getScanDimensions
                case 1
                    string = sprintf(axisString, axisLetters);
                case 2
                    string = sprintf(axisString, axisLetters(1));
                otherwise
                    string = 'bottom label :)';
            end
        end
        
        function string = getLeftScanLabel(obj)
            switch obj.getScanDimensions
                case 1
                    string = 'kcps';
                case 2
                    axisString = '%s (\x03bcm)';
                    axisLetters = obj.mStageScanParams.getScanAxes;
                    string = sprintf(axisString, axisLetters(2));
                otherwise
                    string = 'left label :)';
            end
        end
    end
    
    methods(Static)
        function obj = init
            try
                obj = getObjByName(StageScanner.NAME);
                return
            catch
                obj = StageScanner;
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
            
            % option ONE: scan each line by axis 1, move between lines in axis 2
            % calculate how much many would be needed than:
            timesMaxInFirst = ceil(firstAxisNumPoints / stageMaxScanSizeInt);
            totalTimesOptionOne = timesMaxInFirst * secondAxisNumPoints;
            
            % option TWO: scan each line by axis 2, move between lines in axis 1
            % calculate how many scans would be needed than:
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
    
    %% overriding from Savable
    methods(Access = protected)
        function outStruct = saveStateAsStruct(obj, category) %#ok<*MANU>
            % saves the state as struct. if you want to save stuff, make
            % (outStruct = struct;) and put stuff inside. if you dont
            % want to save, make (outStruct = NaN;)
            %
            % category - string. some objects saves themself only with
            % specific category (image/experimetns/etc)
            if ~strcmp(category, Savable.CATEGORY_IMAGE)
                outStruct = nan;
                return
            end
            
            if isnan(obj.mScan)
                outStruct = NaN;
                return
            end
            
            outStruct = struct;
            outStruct.scan = obj.mScan;
            outStruct.scanParams = obj.mStageScanParams.asStruct();
            outStruct.stageName = obj.mStageName;
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
            % loads the state from a struct.
            % to support older versoins, always check for a value in the
            % struct before using it. view example in the first line.
            if ~strcmp(category, Savable.CATEGORY_IMAGE); return; end
            if ~any(strcmp(subCategory, {Savable.CATEGORY_IMAGE_SUBCAT_STAGE})); return; end
            
            
            for field = {'scan', 'scanParams', 'stageName'}
                if ~isfield(savedStruct, field{:})
                    return
                end
            end
            try
                getObjByName(savedStruct.stageName);
            catch
                obj.sendWarning(sprintf('can''t load stage! no stage with name "%s"', savedStruct.stageName));
                return
            end
            obj.mStageScanParams = StageScanParams.fromStruct(savedStruct.scanParams);
            stage = getObjByName(savedStruct.stageName);
            stage.scanParams = obj.mStageScanParams; % this will send an event that the scan-parameters have changed
            
            obj.mScan = savedStruct.scan;
            obj.mStageName = savedStruct.stageName;
            obj.sendEventScanUpdated(savedStruct.scan);
        end
        
        function string = returnReadableString(obj, savedStruct)
            % return a readable string to be shown. if this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '');
            
            string = NaN;
            for field = {'scan', 'scanParams', 'stageName'}
                if ~isfield(savedStruct, field{:})
                    return
                end
            end
            
            string = ['axes: ' obj.mStageScanParams.getScanAxes];
        end
    end
end
