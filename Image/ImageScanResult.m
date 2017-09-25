classdef ImageScanResult < Savable & EventSender & EventListener
    %IMAGESCANRESULT stores the last scan-image
    %   it is savable, so the last image can be saved and opened
    
    properties(GetAccess = public, SetAccess = private)
        mData       % the matrix
        mDimNumber  % dimentions number
        mFirstAxis  % vector
        mSecondAxis % vector or point
        mLabelBot   % string
        mLabelLeft  % string
    end
    
    properties(Constant = true)
        NAME = 'imageScanResult'
        IMAGE_FILE_SUFFIX = 'png'

        EVENT_IMAGE_UPDATED = 'imageUpdated';
    end
    
    methods
        function obj = ImageScanResult
            obj@Savable(ImageScanResult.NAME);
            obj@EventSender(ImageScanResult.NAME);
            obj@EventListener({SaveLoadCatImage.NAME, StageScanner.NAME});
        end
        
        function update(obj, newData, dimNumber, firstAxisVector, secondAxisVectorOptional, stringLabelBottom, stringLabelLeft)
            obj.mData = newData;
            obj.mDimNumber = dimNumber;
            obj.mFirstAxis = firstAxisVector;
            obj.mSecondAxis = secondAxisVectorOptional;
            obj.mLabelBot = stringLabelBottom;
            obj.mLabelLeft = stringLabelLeft;
            obj.sendEventImageUpdated();
        end
        
        function sendEventImageUpdated(obj)
            obj.sendEvent(struct(obj.EVENT_IMAGE_UPDATED, true));
        end
        
        function fullpath = savePlottingImage(obj, folder, filename)
            % create a new invisible figure, and than save it with a same
            % filename.
            %
            % folder - string. the path.
            % filename - string. the file that was saved by the SaveLoad
            %
            % returns: the fullpath of the image file that was saved
            
            if isempty(obj.mData) || isempty(obj.mData); return; end
            
            figureInvis = AxesHelper.copyAxes(ViewImageResult.getAxes);
            
            filename = PathHelper.removeDotSuffix(filename);
            filename = [filename '.' ImageScanResult.IMAGE_FILE_SUFFIX];
            fullpath = PathHelper.joinToFullPath(folder, filename);
            
            % Save jpg image
            notes = SaveLoad.getInstance(Savable.CATEGORY_IMAGE).mNotes;
            title(notes); %set the notes as the plot's title
            saveas(figureInvis, fullpath);
            
            % close the figure
            close(figureInvis);
        end
    end
    
    methods(Static = true)
        function init
            removeObjIfExists(ImageScanResult.NAME); 
            addBaseObject(ImageScanResult);
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
                outStruct = NaN;
                return
            end
            
            if isempty(obj.mData)
                outStruct = NaN;
                return
            end
            
            outStruct = struct();
            propNameCell = obj.getAllNonConstProperties();
            for i = 1: length(propNameCell)
                propName = propNameCell{i};
                outStruct.(propName) = obj.(propName);
            end
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
            % loads the state from a struct.
            % to support older versoins, always check for a value in the
            % struct before using it. view example in the first line.
            % subCategory - string. could be empty string

            if ~strcmp(category, Savable.CATEGORY_IMAGE); return; end
            if ~any(strcmp(subCategory, {Savable.CATEGORY_IMAGE_SUBCAT_LASER, Savable.SUB_CATEGORY_DEFAULT})); return; end
            
            hasChanged = false;
            for propNameCell = obj.getAllNonConstProperties()
                propName = propNameCell{:};
                if isfield(savedStruct, propName)
                    obj.(propName) = outStruct.(propName);
                    hasChanged = true;
                end
            end
            if hasChanged
                obj.sendEventImageUpdated();
            end
        end
        
        function string = returnReadableString(obj, savedStruct)
            % return a readable string to be shown. if this object
            % doesn't need a readable string, make (string = NaN;) or
            % (string = '');
            string = NaN;
        end
    end
    
    %% overridden from EventListener
    methods
        % when event happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            % check if event is "loaded file to SaveLoad" and need to show the image
            if strcmp(event.creatorName, SaveLoadCatImage.NAME) ...
                    && isfield(event.extraInfo, SaveLoad.EVENT_LOAD_SUCCESS_FILE_TO_LOCAL)
                category = Savable.CATEGORY_IMAGE;
                % need to load the image!
                saveLoad = SaveLoad.getInstance(category);
                struct = saveLoad.getStructToSavable(obj);
                if ~isempty(struct)
                    obj.loadStateFromStruct(category, struct);
                end
            end
            
            % check if event is "SaveLoad wants to save a file" and need to
            % save an image file of the figure
            if strcmp(event.creatorName, SaveLoadCatImage.NAME) ...
                    && isfield(event.extraInfo, SaveLoad.EVENT_SAVE_SUCCESS_LOCAL_TO_FILE) ...
                    && ~isempty(obj.mData)
                
                folder = event.extraInfo.(SaveLoad.EVENT_FOLDER);
                filename = event.extraInfo.(SaveLoad.EVENT_FILENAME);
                obj.savePlottingImage(folder, filename);
            end
                
            
            % check if event is "scanner has a new line scanned" and need
            % to updated the image
            if strcmp(event.creatorName, StageScanner.NAME) ...
                    && isfield(event.extraInfo, StageScanner.EVENT_SCAN_UPDATED)
                
                extra = event.extraInfo.(StageScanner.EVENT_SCAN_UPDATED);
                % "extra" now points to an object of type EventExtraScanUpdated
                obj.update(extra.scan, extra.dimNumber, extra.getFirstAxis, extra.getSecondAxis, extra.botLabel, extra.leftLabel);
                drawnow
            end
        end
    end
end