classdef SaveLoad < Savable & EventSender
    %SAVELOAD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        mNotes = ''                      % string. the mNotes to be saved and loaded
        mCategory                        % string. the mCategory that this SaveLoad object works with
        mLocalSaveStruct = NaN;          % struct. the last saved\loaded struct
        mLocalStructStatus = '';         % string. the status of the local struct ('loaded' \ 'saved' \ 'autosaved' \ 'not saved!')
        mLoadedFileName = NaN;           % string. last file that was saved\loaded\to-be-saved. only file name - not full path!
        mLoadedFileFullPath = NaN;       % string. last file that was saved\loaded\to-be-saved. full path.
        mSavingFolder                    % string. will be used with saves 
        mLoadingFolder                   % string. is used by obj.previous(), obj.next() and obj.last()
                                         %         can point to PATH_DEFAULT_AUTO_SAVE, or to the mSavingFolder
    end
    
    properties(Dependent = true)
        isStructLoaded
    end
    
    properties(Constant = true)
        EVENT_DELETE_FILE_SUCCESS = 'fileDeletedSuccessfully';
        EVENT_SAVE_SUCCESS_LOCAL_TO_FILE = 'fileSavedSuccessfully';
        EVENT_LOAD_SUCCESS_FILE_TO_LOCAL = 'fileLoadedSuccessfullyToLocalStruct';
        EVENT_LOAD_SUCCESS_LOCAL_TO_SYSTEM = 'localStructLoadedSuccessfullyToSystem';
        
        EVENT_ERR_NO_INTERNAL_BUFFER = 'errNoInternalBufferYet';
        EVENT_ERR_FNF = 'errFileNotFound';
        EVENT_ERR_SUFFIX_INVALID = 'errInvalidSuffix';
        EVENT_ERR_FILE_EXIST = 'errFileExist';
        EVENT_ERR_FILE_INVALID = 'errFileInvalid';
        
        EVENT_FILENAME = 'fileName';
        EVENT_FOLDER = 'folder';
        EVENT_STATUS_LOCAL_STRUCT = 'localStruct_status';
        EVENT_LOCAL_STRUCT = 'localStruct';
        
        PATH_DEFAULT_SAVE = sprintf('%sControl code\\__try\\_ManualSaves\\Setup %s\\', PathHelper.getPathToNvLab(), JsonInfoReader.getJson.setupNumber);
        PATH_DEFAULT_AUTO_SAVE = sprintf('%sControl code\\__try\\_AutoSave\\Setup %s\\', PathHelper.getPathToNvLab(), JsonInfoReader.getJson.setupNumber);
        SAVE_FILE_SUFFIX = '.mat';
        
        STRUCT_STATUS_NOT_SAVED = 'not yet saved!';
        STRUCT_STATUS_SAVED = 'saved';
        STRUCT_STATUS_AUTO_SAVED = 'autosaved';
        STRUCT_STATUS_LOADED = 'loaded';
        STRUCT_STATUS_NOTHING = 'empty';
        
        NAME_PATTERN_BASE_OBJECT = 'SaveLoad_%s';
    end
    
    
    methods(Static, Sealed)
        function obj = getInstance(category)
            % this method gets the rellevant SaveLoad object based on the
            % needed mCategory. so that calling
            % SaveLoad.getInstance('image') will return a SaveLoad
            % different than calling SaveLoad.getInstance('experiments')
            %
            % category - string

            saveLoadName = SaveLoad.getInstanceName(category);
            try
                obj = getObjByName(saveLoadName);
            catch matlabExp %#ok<NASGU>   ---> if wasn't yet created   
                obj = SaveLoad(category);
            end
        end
        
        function saveLoadName = getInstanceName(category)
            saveLoadName = sprintf(SaveLoad.NAME_PATTERN_BASE_OBJECT, category);
        end
        
        function init
            % init the relevant SaveLoad objects.
            % currently only one is special enough to init - the SaveLoad
            % of category image, It's in a derived class as it has
            % different behaviour - it needs to listen to the StageScanner
            % (on events of type EVENT_SCAN_FINISH) to save the scans
            try
                getObjByName(SaveLoadCatImage.NAME);
            catch
                SaveLoadCatImage;  % init this object
            end
        end
    end
    
    methods(Access = protected)
        function obj = SaveLoad(category)
            name = SaveLoad.getInstanceName(category);
            obj@EventSender(name);
            obj@Savable(name);
            BaseObject.addObject(obj);  % so it can be reached by BaseObject.getByName()
            
            obj.mCategory = category;
            obj.mSavingFolder = obj.PATH_DEFAULT_SAVE;  % to be overridden later by the user, if needed...
            obj.mLoadingFolder = obj.PATH_DEFAULT_AUTO_SAVE;      % to be overridden later by the user, if needed...
        end
    end
    
    methods
        function setNotes(obj, newNotes, saveToFileOptionalBoolean)
            shouldSaveToFile = exist('saveToFileOptionalBoolean', 'var') && saveToFileOptionalBoolean;
            if (ischar(newNotes))
                if ~strcmp(newNotes, obj.mNotes)
                    obj.mNotes = newNotes;
                    if isstruct(obj.mLocalSaveStruct)
                        % update the struct (and the file if needed)
                        obj.mLocalSaveStruct.(obj.name) = obj.saveStateAsStruct(obj.mCategory);
                        if shouldSaveToFile
                            obj.saveLocalStructToFile(obj.mLoadedFileFullPath);
                        end
                    else 
                        obj.sendEvent(struct('notes', newNotes));
                    end
                end
            else
                obj.sendWarning('newNotes parameter is not a char-array! ignoring');
            end
        end
                
        function setFileName(obj, newFileName)
            % change the file name to save the struct when needed, using obj.autoSave()
            % newFileName - only the file name, not full path!
            
            if ~ischar(newFileName)
                obj.sendWarning('''newFileName'' can only be a string!');
                return;
            end
            
            if ~endsWith(newFileName, obj.SAVE_FILE_SUFFIX)
                newFileName = sprintf('%s%s', newFileName, obj.SAVE_FILE_SUFFIX);
            end
            obj.mLoadedFileName = newFileName;
            obj.sendEvent(struct(obj.EVENT_FILENAME, obj.mLoadedFileName));
        end
        
        function setLoadingFolder(obj, newLoadingFolderString)
            % set the loading folder to be 'autosave' or another path
            % if newLoadingFolderString == 'autosave':
            %       loading folder will point to PATH_DEFAULT_AUTO_SAVE
            % else if newLoadingFolderString == 'manual_saves':
            %       loading folder will point to obj.mSavingFolder
            % else, the loading folder will point to the new value
            %       AND WILL CHANGE obj.mSavingFolder AS WELL, so 
            %       that next calls to obj.save() will save in the same folder!
            if ~ischar(newLoadingFolderString)
                obj.sendWarning('please call saveLoad.setmLoadingFolder() only will folder full path! only strings will be accepted');
                return
            end
            
            newLoadingFolderString = PathHelper.appendBackslashIfNeeded(newLoadingFolderString);
            
            
            if strcmp(newLoadingFolderString, 'autosave\') || ...
                    strcmp(newLoadingFolderString, obj.PATH_DEFAULT_AUTO_SAVE)
                obj.mLoadingFolder = obj.PATH_DEFAULT_AUTO_SAVE;
            elseif strcmp(newLoadingFolderString, 'manual_saves\')
                obj.mLoadingFolder = obj.mSavingFolder;
            elseif PathHelper.isFolderExists(newLoadingFolderString)
                obj.mLoadingFolder = newLoadingFolderString;
                obj.mSavingFolder = newLoadingFolderString;
            else
                obj.sendWarning(sprintf('can''t set loading folder - path is not a folder! %s', newLoadingFolderString));
            end
            obj.sendEvent(struct(obj.EVENT_FOLDER, obj.mLoadingFolder));
        end
        
        function saveSystemToLocalStruct(obj)
            % saves the system state to the local struct
            structToSave = Savable.saveAllObjects(obj.mCategory);
            obj.mLocalSaveStruct = structToSave;
            obj.mLocalStructStatus = SaveLoad.STRUCT_STATUS_NOT_SAVED;
            obj.mLoadedFileName = sprintf('%s_%s.mat', obj.mCategory, structToSave.(Savable.PROPERTY_TIMESTAMP));
            
            eventStruct = struct(... 
                obj.EVENT_STATUS_LOCAL_STRUCT, obj.mLocalStructStatus, ...
                obj.EVENT_LOCAL_STRUCT, obj.mLocalSaveStruct, ...
                obj.EVENT_FILENAME, obj.mLoadedFileName ...
            );
            obj.sendEvent(eventStruct);
        end
        
        function saveLocalStructToFile(obj, fileFullPath, differentStatusOptional)
            % saves the local struct into an outer file
            % fileFullPath - string
            % differentStatusOptional - string.
            %                           if exists, the status will be this
            %                           argument (default is 'saved')

            myStruct = obj.mLocalSaveStruct;
            if ~isstruct(myStruct)
                errorMsg = 'No local struct has been loaded\saved. Nothing to save! Consider calling obj.saveSystemToLocalStruct() or obj.loadFileToLocal()';                
                obj.sendError(errorMsg);
            end
            
            if ~endsWith(fileFullPath, SaveLoad.SAVE_FILE_SUFFIX)
                errorMsg = sprintf('Incorrect file suffix! (suffix needed: "%s", file to save: "%s"', obj.SAVE_FILE_SUFFIX, fileFullPath);
                obj.sendError(errorMsg, struct(SaveLoad.EVENT_ERR_SUFFIX_INVALID, true, SaveLoad.EVENT_FILENAME, fileFullPath));
            end
            
            if PathHelper.isFileExists(fileFullPath)
                % warningMsg = sprintf('file already exists! overriding... %s', fileFullPath);
                % obj.sendWarning(warningMsg, struct(SaveLoad.EVENT_ERR_FILE_EXIST, true, SaveLoad.EVENT_FILENAME, fileFullPath));
                % un-needed as per Yoav's request
            end
                                   
            obj.mLoadedFileName = PathHelper.getFileNameFromFullPathFile(fileFullPath);
            obj.mLoadedFileFullPath = fileFullPath;
            obj.createFolderIfNeeded(fileFullPath);
            save(fileFullPath, 'myStruct');
            
            if exist('differentStatusOptional', 'var') && ...
                    ischar(differentStatusOptional) && ...
                    ~isempty(differentStatusOptional)
                
                obj.mLocalStructStatus = differentStatusOptional;
                
            else
                obj.mLocalStructStatus = obj.STRUCT_STATUS_SAVED;
            end
            
            folder = PathHelper.getFolderFromFullPathFile(fileFullPath);
            
            structEvent = struct();
            structEvent.(SaveLoad.EVENT_FILENAME) = obj.mLoadedFileName;
            structEvent.(SaveLoad.EVENT_FOLDER) = folder;
            structEvent.(SaveLoad.EVENT_SAVE_SUCCESS_LOCAL_TO_FILE) = true;
            structEvent.(obj.EVENT_STATUS_LOCAL_STRUCT) = obj.mLocalStructStatus;
            obj.sendEvent(structEvent);
        end
        
        function autoSave(obj)
            % saves the state to the local struct
            % and then saves the struct to a file in the AUTOSAVE folder
            obj.saveSystemToLocalStruct();
            
            filename = obj.mLoadedFileName;
            fullPath = sprintf('%s%s', obj.PATH_DEFAULT_AUTO_SAVE, filename);
            
            newStructStatus = obj.STRUCT_STATUS_AUTO_SAVED;
            obj.saveLocalStructToFile(fullPath, newStructStatus);
        end
        
        function save(obj)
            % saves the struct to a file (with the already predefined
            % obj.mLoadedFileName as name) in the obj.mSavingFolder
            
            filename = obj.mLoadedFileName;
            fullPath = sprintf('%s%s', obj.mSavingFolder, filename);
            obj.saveLocalStructToFile(fullPath);
        end
        
        function saveAs(obj, fileFullPath)
            % changes the saving folder and the filename, and than saves the file
            folderAndFile = PathHelper.splitFullPathToFolderAndFile(fileFullPath);
            
            folder = folderAndFile{1};
            obj.mSavingFolder = folder;
            obj.setLoadingFolder(folder);
            
            fileName = folderAndFile{2};
            obj.setFileName(fileName);
            
            obj.saveLocalStructToFile(fileFullPath);
        end
            
        
        function success = loadLocalToSystem(obj, subCategoryOptional)
            % loads the local struct into the system
            % subCategoryOptional - string. the subCat to load to
            if ~isstruct(obj.mLocalSaveStruct)
                warningMsg = 'no local struct has been loaded\saved. nothing to save! consider calling obj.saveSystemToLocalStruct() or obj.loadFileToLocal()';
                obj.sendWarning(warningMsg);
                success = false;
                return
            end
            
            if exist('subCategoryOptional', 'var')
                subCat = subCategoryOptional;
            else
                subCat = Savable.SUB_CATEGORY_DEFAULT;
            end
            
            Savable.loadAllObjects(obj.mLocalSaveStruct, obj.mCategory, subCat);
            obj.sendEvent(struct(obj.EVENT_LOAD_SUCCESS_LOCAL_TO_SYSTEM, true));
            success = true;
        end
        
        function success = loadFileToLocal(obj, fileFullPath, shouldSendErrorsOptional)
            % loads a file to the local struct
            % fileFullPath - string. the file path
            % shouldSendErrorsOptional - optional boolean. if true, errors
            %                            will be sent via obj.sendWarning() 
            %
            sendWarnings = exist('shouldSendErrorsOptional', 'var') && shouldSendErrorsOptional;
            loadedStruct = obj.tryLoadingStruct(fileFullPath, sendWarnings);
            if ~isstruct(loadedStruct)
                success = false;
                return
            end
            
            obj.mLocalSaveStruct = loadedStruct;
            obj.mLoadedFileName = PathHelper.getFileNameFromFullPathFile(fileFullPath);
            obj.mLoadedFileFullPath = fileFullPath;
            obj.mLocalStructStatus = obj.STRUCT_STATUS_LOADED;
            
            structEvent = struct();
            structEvent.(SaveLoad.EVENT_LOAD_SUCCESS_FILE_TO_LOCAL) = true;
            structEvent.(SaveLoad.EVENT_FILENAME) = obj.mLoadedFileName;
            structEvent.(obj.EVENT_LOCAL_STRUCT) = obj.mLocalSaveStruct;
            structEvent.(obj.EVENT_STATUS_LOCAL_STRUCT) = obj.mLocalStructStatus;
            obj.sendEvent(structEvent);
            
            % handle the notes
            if isfield(obj.mLocalSaveStruct.(obj.name), 'mNotes')
                saveFileOnNewNotes = false; % we don't want the file to be saved when the notes change
                obj.setNotes(obj.mLocalSaveStruct.(obj.name).mNotes, saveFileOnNewNotes)
            end
            
            success = true;
        end
        
        function loadPreviousFile(obj)
            % load the previous file to the one currently in use.
            % go through the files in the folder, until finding some file
            % that matches the terms:
            %        @ finishes with '.mat'
            %        @ has same mCategory as obj.mCategory
            irellevant = {obj.STRUCT_STATUS_NOT_SAVED, obj.STRUCT_STATUS_NOTHING};
            
            if any(strcmp(obj.mLocalStructStatus, irellevant))
                obj.sendWarning('can''t load next - no file has been already loaded to be next to!');
                return
            end
            currentFileFullPath = obj.mLoadedFileFullPath;
            
            
            folder = obj.mLoadingFolder;
            allFiles = PathHelper.getAllFilesInFolder(folder, obj.SAVE_FILE_SUFFIX);
            if isempty(allFiles)
                obj.sendWarning('empty folder, can''t load file!');
                return
            end
            
            ispresent = cellfun(@(string) strcmp(currentFileFullPath, string), allFiles);
            % if file not found in folder, make it load the last file
            % (fileIndex will be 1 beyond last file, as it will load the file BEFORE fileIndex)
            if ~any(ispresent)
                fileIndex = length(allFiles) + 1;
            else
                fileIndex = find(ispresent == 1);
            end
            
            if fileIndex == 1
                obj.sendWarning('first file is loaded - no possible previous!');
                return;
                % todo dependent property 'can load next' and 'can load previous'
                % ONE_DAY
            end
            
            start = fileIndex - 1;
            step = -1;
            end_ = 1;
            for index = start : step : end_
                % loop through and load the first with matching terms
                loaded = obj.loadFileToLocal(allFiles{index});
                if loaded
                    return
                end
            end
            obj.sendWarning('all next files can''t be loaded.');
        end
        
        function loadNextFile(obj)
            % load the next file to the one currently in use.
            % go through the files in the folder, until finding some file
            % that matches the terms:
            %        @ finishes with '.mat'
            %        @ has same mCategory as obj.mCategory
            irellevant = {obj.STRUCT_STATUS_NOT_SAVED, obj.STRUCT_STATUS_NOTHING};
            
            if any(strcmp(obj.mLocalStructStatus, irellevant))
                obj.sendWarning('can''t load next - no file has been already loaded to be next to!');
                return
            end
            currentFileFullPath = obj.mLoadedFileFullPath;
            
            
            folder = obj.mLoadingFolder;
            allFiles = PathHelper.getAllFilesInFolder(folder, obj.SAVE_FILE_SUFFIX);
            if isempty(allFiles)
                obj.sendWarning('empty folder, can''t load file!');
                return
            end
            
            ispresent = cellfun(@(string) strcmp(currentFileFullPath, string), allFiles);
            % if file not found in folder, make it load the first file
            % (fileIndex will be than 0, as it will load the file AFTER fileIndex)
            if ~any(ispresent)
                fileIndex = 0;
            else
                fileIndex = find(ispresent == 1);
            end
            
            if fileIndex == length(allFiles)
                obj.sendWarning('last file is loaded - no possible next!');
                return;
                % todo dependent property 'can load next' and 'can load previous'
                % ONE_DAY
            end
            
            for index = fileIndex + 1 : length(allFiles)
                % loop through and load the first with matching terms
                loaded = obj.loadFileToLocal(allFiles{index});
                if loaded
                    return
                end
            end
            obj.sendWarning('all next files can''t be loaded.');
            
        end
        
        function loadLastFile(obj)
            % load the last file in the folder of this loaded file
            % go through the files in the folder, until finding some file
            % that matches the terms:
            %        @ finishes with '.mat'
            %        @ has same mCategory as obj.mCategory
            folder = obj.mLoadingFolder;
            disp(folder)
            allFiles = PathHelper.getAllFilesInFolder(folder, obj.SAVE_FILE_SUFFIX);
            if isempty(allFiles)
                obj.sendWarning('empty folder, can''t load file!');
                return
            end
            
            start = length(allFiles);
            step = -1;
            end_ = 1;
            for index = start : step : end_
                % loop through and load the first with matching terms
                loaded = obj.loadFileToLocal(allFiles{index});
                if loaded
                    return
                end
            end
            obj.sendWarning('this folder has not even ONE file good enough to load.\nSorry!');
            
        end
        
        function deleteCurrentFile(obj)
            % deletes the current file and cleans the struct
            
            illegalStates = {obj.STRUCT_STATUS_NOT_SAVED, obj.STRUCT_STATUS_NOTHING};
            if any(strcmp(obj.mLocalStructStatus, illegalStates))
                obj.sendWarning('can''t delete file - not yet saved! ignoring');
                return
            end
            
            if ~ischar(obj.mLoadedFileFullPath)
                % check that obj.mLoadedFileFullPath is even present
                % obj.mLoadedFileFullPath gets fullfilled in
                % obj.saveLocalStructToFile() and in obj.loadFileToLocal()
                
                obj.sendWarning('can''t delete file - no file saved! ignoring');
                return
            end
            
            if ~PathHelper.isFileExists(obj.mLoadedFileFullPath)
               obj.sendWarning(sprintf('can''t delete file - file not exists! ignoring\n(file name: %s)', obj.mLoadedFileFullPath));
                return
            end 
            
            fullPath = obj.mLoadedFileFullPath;
            delete(fullPath);
            obj.mLoadedFileFullPath = NaN;
            obj.mLoadedFileName = NaN;
            obj.mLocalSaveStruct = NaN;
            obj.mLocalStructStatus = obj.STRUCT_STATUS_NOTHING;
            
            structEvent = struct();
            structEvent.file_full_path = fullPath;
            structEvent.(SaveLoad.EVENT_DELETE_FILE_SUCCESS) = true;
            structEvent.(obj.EVENT_STATUS_LOCAL_STRUCT) = obj.mLocalStructStatus;
            obj.sendEvent(structEvent);
        end
    end
    
    methods(Access = private)
        function createFolderIfNeeded(obj, fileFullPath)
            folderFileCellArray = PathHelper.splitFullPathToFolderAndFile(fileFullPath);
            [folder, ~] = folderFileCellArray{:};
            [status, msg] = mkdir(folder);
            if status ~= 1
                obj.sendWarning(msg)
            end
        end
        
        function loadedStruct = tryLoadingStruct(obj, fileFullPath, shouldSendErrors)
            % try to load a struct from a file
            %
            % fileFullPath - string. the full path
            % shouldSendErrors - boolean. if true, errors will be sent via
            %                    obj.sendWarning()
            %
            % returns - the loaded struct if succeeded, NaN if failed
            loadedStruct = NaN;
            
            if ~PathHelper.isFileExists(fileFullPath)
                warningMsg = sprintf('file not exists! %s', fileFullPath);
                if shouldSendErrors
                    obj.sendWarning(warningMsg, struct(SaveLoad.EVENT_ERR_FNF, true, obj.EVENT_FILENAME, fileFullPath));
                end
                return
            end
            

            if ~endsWith(fileFullPath, SaveLoad.SAVE_FILE_SUFFIX)
                if shouldSendErrors
                    folderAndFilename = PathHelper.splitFullPathToFolderAndFile(fileFullPath);
                    fileName = folderAndFilename{2};
                    warningMsg = sprintf(...
                        'file suffix incorrct! ignoring.\n(suffix needed:"%s", file to load: "%s"', ...
                        obj.SAVE_FILE_SUFFIX, ...
                        fileName);
                    
                    obj.sendWarning(warningMsg, struct(SaveLoad.EVENT_ERR_SUFFIX_INVALID, true, obj.EVENT_FILENAME, fileFullPath));
                end
                return
            end
            
            structToLoad = load(fileFullPath);
            if ~isfield(structToLoad, 'myStruct')
                if shouldSendErrors
                    obj.sendWarning('can''t find the reserved field ''myStruct'' in the file to load. aborting', ...
                        struct(obj.EVENT_ERR_FILE_INVALID, true, obj.EVENT_FILENAME, fileFullPath))
                end
                return
            end
            structToLoad = structToLoad.myStruct;
            structCategory = structToLoad.(Savable.PROPERTY_CATEGORY);
            if ~strcmp(structCategory, obj.mCategory)
                if shouldSendErrors
                    obj.sendWarning(sprintf(' can''t load file - mCategory mismatch! ignoring.\n(file mCategory: "%s", SaveLoad mCategory: "%s"', structCategory, obj.mCategory));
                end
                return
            end
            
            loadedStruct = structToLoad;
        end
    end
    
    %% getters
    methods
        function out = get.isStructLoaded(obj)
            out = isstruct(obj.mLocalSaveStruct);
        end
        
        function structOfThisSavable = getStructToSavable(obj, savable)
            % a savable can access this method to get thier part in the
            % SaveLoad local struct. 
            % savable - the savable object requesting
            % returns - the local struct or nan if not exists
            if ~isstruct(obj.mLocalSaveStruct)
                structOfThisSavable = nan;
                return;
            end
            
            structOfThisSavable = Savable.extractSpecificSavableStruct(savable, obj.mLocalSaveStruct);
        end
    end
    
    %% overriden from Savable
    methods(Access = protected)
        function outStruct = saveStateAsStruct(obj, mCategory) %#ok<*MANU>
            % saves the state as struct.
            if strcmp(mCategory, obj.mCategory)
                outStruct = struct('mNotes', obj.mNotes);
            else
                outStruct = NaN;
            end
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
            % loads the state from a struct previousely saved.
            % if the category fits, always load, no matter what is the sub-category
            if ~strcmp(obj.mCategory, category); return; end
            
            if isfield(savedStruct, 'mNotes') && ischar(savedStruct.mNotes)
                obj.mNotes = savedStruct.mNotes;
                obj.sendEvent(struct('mNotes', obj.mNotes));
            end
        end
        
        function string = returnReadableString(obj, savedStruct)
            string = NaN;
        end
    end
    
    
end

