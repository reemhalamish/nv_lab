classdef PathHelper
    %PATHHELPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function nvLabFolderPath = getPathToNvLab()
            googleDriveFolder = sprintf('%s\\Google Drive\\', getenv('USERPROFILE'));
            nvLabFolderName = 'NV Lab';
            nvLabFolderPath = PathHelper.recuresiveFindFolder(googleDriveFolder, nvLabFolderName);
            
            if ~ischar(nvLabFolderPath); error('can''t find NV Lab folder!!'); end
        end
        
        function folderString = recuresiveFindFolder(startingPositionPath, folderNameToSearchString)
            startingPositionPath = PathHelper.appendBackslashIfNeeded(startingPositionPath);
            folderString = nan;  % if nothing will be found later on
            
            listing = dir(startingPositionPath);
            relevant = listing([listing.isdir]);  % looking only for folders
            relevant = relevant(~strcmp({relevant.name}, '.'));
            relevant = relevant(~strcmp({relevant.name}, '..'));
            % the first 2 options are "." and "..", ignore them
            
            % base case 1: no more folders deeper down
            if isempty(relevant); return; end  
            
            isHere = find(strcmp({relevant.name}, folderNameToSearchString));
            % "isHere" now is a number (index) or empty, so we can use "if"
            if isHere  
                % base case 2: fond the folder
                folderString = PathHelper.joinToFullPath(startingPositionPath, relevant(isHere).name);
                folderString = PathHelper.appendBackslashIfNeeded(folderString);
                return
            else  % start the recurstion
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
            % fullPath      - string. exapmle: 'C:\reem\file.txt'
            % folderAndFile - cell with two strings. 'folder' and 'file'. 
            %                 example: {'C:\reem\','file.txt'}
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
            %%% checks the input and appends a backslash if needed
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
            %%% get all the files from a folder
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
            
            allFileNames = {};
            for i = 1 : length(allFilesInFolder)
                fileName = allFilesInFolder(i).name;
                fullPath = [inputFolder fileName];
                if PathHelper.isFileExists(fullPath) && endsWith(fullPath, optionalSuffix)
                    allFileNames{end + 1} = fullPath; % TODO how better??
                end
            end
        end
        
        function fullpath = joinToFullPath(folder, fileName)
            % convert a folder with a filename to one file fullpath
            % for example:
            % folder = 'c:\reem'       (ending backslash is optional)
            % filename = 'myfile.txt'
            % fullpath ----> 'c:\reem\myfile.txt'
            
            folder = PathHelper.appendBackslashIfNeeded(folder);
            fullpath = sprintf('%s%s', folder, fileName);
        end
    end
end

