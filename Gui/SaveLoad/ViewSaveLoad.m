classdef ViewSaveLoad < GuiComponent & EventListener
    %VIEWSAVELOAD view to save and load
    %   contains the ViewSave and the ViewLoad
    
    properties
        saveView    % the child view
        tvFileName  % shows the file name with status
        loadView    % the child view
        
        categoryToSave  % string. the category to save ('image', 'experiments', etc...)
    end
    
    properties(Constant = true)
        DELAY_BG_COLOR_BACK_SEC = 0.2;
        GREEN_BG_COLOR = [0.1 1 0.1];
        RED_BG_COLOR = [1 0.1 0.1];
    end
    
    methods
        % constructor
        function obj = ViewSaveLoad(parent, controller, categoryToSave)
            % categoryToSave - string. which category should you save
            % (mostly 'image' or 'experiments')
            
            panel = ViewExpandablePanel(parent, controller, 'Save & Load Image');
            obj@GuiComponent(panel, controller);
            
            saveLoad = SaveLoad.getInstance(categoryToSave);
            obj@EventListener(saveLoad.name);
            
            vbox = uix.VBox('Parent', panel.component, 'Spacing', 5, 'Padding', 5);
            obj.component = vbox;
            obj.categoryToSave = categoryToSave;
            
            
            obj.saveView = ViewSave(obj, controller, categoryToSave);
            obj.tvFileName = uicontrol(obj.PROP_TEXT_NORMAL{:}, 'Parent', obj.component, 'String', 'File Name - ');
            obj.loadView = ViewLoad(obj, controller, categoryToSave);
            heights = [obj.saveView.height, 20, obj.loadView.height];
            widths = [obj.saveView.width, obj.loadView.width];
            
            set(vbox, 'Heights', heights);
            set(vbox, 'Padding', 5);
            set(vbox, 'Spacing', 5);
            
            obj.height = sum(heights) + length(heights) * 8;
            obj.width = max(widths);
            panel.height = obj.height;
            
        end
    end
    
    
    methods
        %% when event happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            
            %%%% display the filename status %%%%
            if ~event.isError
                if isfield(event.extraInfo, SaveLoad.EVENT_STATUS_LOCAL_STRUCT)
                    status = event.extraInfo.(SaveLoad.EVENT_STATUS_LOCAL_STRUCT);
                else
                    status = NaN;
                end
                
                if isfield(event.extraInfo, SaveLoad.EVENT_FILENAME)
                    fileName = PathHelper.getFileNameFromFullPathFile(event.extraInfo.(SaveLoad.EVENT_FILENAME));
                else
                    fileName = NaN;
                end
                
                fileJustDeleted = isfield(event.extraInfo, SaveLoad.EVENT_DELETE_FILE_SUCCESS);
                shouldDisplayNewString = ischar(fileName) || ischar(status) || fileJustDeleted;
                
                if shouldDisplayNewString
                    if fileJustDeleted
                        % if is a deleted file, remove as well
                        toDisplay = sprintf('File Name -');
                        
                    elseif ischar(fileName) && ischar(status)
                        toDisplay = sprintf('File Name - %s (%s)', fileName, status);
                    elseif ischar(fileName)
                        toDisplay = sprintf('File Name - %s', fileName);
                    elseif ischar(status)
                        toDisplay = sprintf('File Name - %s', status);                        
                    end
                    obj.tvFileName.String = toDisplay;
                end
            end
        end
    end
end

