classdef PathHelper
    %PATHHELPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function nvLabFolderPath = getPathToNvLab()
            googleDriveFolder = sprintf('%s\\Google Drive\\', getenv('USERPROFILE'));
            nvLabFolderName = 'NV Lab';
            nvLabFolderPath = PathHelper.recuresiveFindFolder(googleDriveFolder, nvLabFolderName);
            
            if ~ischar(nvLabFolderPath); EventStation.anonymousError('Can''t find NV Lab folder!!'); end
        end
        
        function devOrProdString = SetupMode
            % Determines whether to use dev(elopment) or prod(uction)
            % folder for saving and loading, according to json
            jsonStruct = JsonInfoReader.getJson();
            isDev = strcmp(jsonStruct.setupNumber, '999');  % The only setup in dev mode is 999, all else are in prod.
            devOrProdString = BooleanHelper.ifTrueElse(isDev, 'dev', 'prod');
        end
        
        function folderString = recuresiveFindFolder(startingPositionPath, folderNameToSearchString)
            startingPositionPath = PathHelper.appendBackslashIfNeeded(startingPositionPath);
            folderString = nan;  % if nothing will be found later on
            
            listing = dir(startingPositionPath);
            relevant = listing([listing.isdir]);  % looking only for folders
            relevant = relevant(~strcmp({relevant.name}, '.'));
            relevant = relevant(~strcmp({relevant.name}, '..'));
            % ^ The first 2 items are "." and "..", ignore them
            
            % Base case 1: no more folders deeper down
            if isempty(relevant); return; end  
            
            isHere = find(strcmp({relevant.name}, folderNameToSearchString));
            % "isHere" is now either a number (index) or empty, so we can use "if"
            if isHere  
                % Base case 2: found the folder
                folderString = PathHelper.joinToFullPath(startingPositionPath, relevant(isHere).name);
                folderString = PathHelper.appendBackslashIfNeeded(folderString);
                return
            else  % start the recursion
                for folderIndex = 1 : length(relevant)
                    newBaseFolder = [startingPositionPath relevant(folderIndex).name];
                    folderString = PathHelper.recuresiveFindFolder(newBaseFolder, folderNameToSearchString);
                    if ischar(folderString); return; end
                end
            end
        end
        
        function filepath = removeDotSuffix(filePathMaybeWithDotSuffix)
            if ~any(filePathMaybeWithDotSuffix == '.')
                filepath = filePathMaybeWithDotSuffix;
                return
            end
            filepath = filePathMaybeWithDotSuffix(1 : find(filePathMaybeWithDotSuffix == '.', 1, 'last') - 1);
        end
        
        function folderAndFile = splitFullPathToFolderAndFile(fullPath)
            % fullPath      - string. For exapmle: 'C:\reem\file.txt'
            % folderAndFile - cell with two strings: 'folder' and 'file'. 
            %                 For example: {'C:\reem\','file.txt'}
            %
            % See also MATLAB native function "fileparts"
            
            pathSplitted = strsplit(fullPath, '\\');
            fileName = pathSplitted(end);
            folderName = fullPath(1 : find(fullPath=='\', 1, 'last'));
            folderName = PathHelper.appendBackslashIfNeeded(folderName);  % clean it
            folderAndFile = [folderName, fileName];
        end
        
        function out = isFileExists(fileFullPath)
            out = exist(fileFullPath, 'file') == 2; 
            % 2 is for files. 7 for folders. 0 means not exists
        end
        
        function out = isFolderExists(folderFullPath)
            out = exist(folderFullPath, 'file') == 7; 
            % 2 is for files. 7 for folders. 0 means not exists
        end
        
        function string = appendBackslashIfNeeded(inputFolder)
            %%% Checks the input and appends a backslash if needed
            %
            % inputFolder - string
            %
            string = inputFolder;
            if ~endsWith(string, '\')
                string = [string '\'];
            end
        end
        
        function folderName = getFolderFromFullPathFile(inputFileString)
            %%% retreives the folder from a file
            %
            % inputFileString - string
            %
            folderAndFile = PathHelper.splitFullPathToFolderAndFile(inputFileString);
            [folderName, ~] = folderAndFile{:};
        end
        
        function fileName = getFileNameFromFullPathFile(inputFileString)
            %%% retreives the filename from a full path
            %
            % inputFileString - string
            %
            folderAndFile = PathHelper.splitFullPathToFolderAndFile(inputFileString);
            [~, fileName] = folderAndFile{:};
        end
        
        function allFileNames = getAllFilesInFolder(inputFolder, optionalSuffix)
            %%% Returns names of all relevant files in a folder
            %
            % allFilesInFolder - cell of strings - files in full path
            % optionalSuffix - optional string. if exists, only filenames
            %                   that end with the pattern will be returned 
            %
            % allFiles - struct array
            %
            if ~exist('optionalSuffix', 'var')
                optionalSuffix = '';
            end
            
            inputFolder = PathHelper.appendBackslashIfNeeded(inputFolder);
            allFilesInFolder = dir(inputFolder);
            allFilesInFolder = allFilesInFolder(3 : end);   % the first two aren't relevant
            
            len = length(allFilesInFolder);
            temp = cell(1,len);
            isRelevant = false(1, len);
            for i = 1:len
                fileName = allFilesInFolder(i).name;
                fullPath = [inputFolder fileName];
                if PathHelper.isFileExists(fullPath) && endsWith(fullPath, optionalSuffix)
                    temp{i} = fullPath;
                    isRelevant(i) = true;
                end
            end
            allFileNames = temp(isRelevant);
        end
        
        function fullpath = joinToFullPath(folder, fileName)
            % convert a folder with a filename to one file fullpath
            % for example:
            % folder = 'c:\reem'       (ending backslash is optional)
            % filename = 'myfile.txt'
            % fullpath ----> 'c:\reem\myfile.txt'
            %
            % See also MATLAB native function "fullfile" 
            
            folder = PathHelper.appendBackslashIfNeeded(folder);
            fullpath = sprintf('%s%s', folder, fileName);
        end
    end
end

