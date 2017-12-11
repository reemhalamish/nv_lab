classdef ViewSave < GuiComponent & EventListener
    %VIEWSAVE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        btnSave;        % the button
        btnSaveAs;      % the button
        edtNotes;       % the input text of "notes"
        category;       % the category to save to. mostly 'image' or 'Experiments'
    end
    
    methods
        % constructor
        function obj = ViewSave(parent, controller, category)
            %%%%%%%% the object to work with %%%%%%%%
            saveLoadPhysical = SaveLoad.getInstance(category);
            
            %%%%%%%% Constructors %%%%%%%%            
            obj@EventListener(saveLoadPhysical.name);
            obj@GuiComponent(parent, controller);
            
            %%%%%%%% Ui components init  %%%%%%%%
            boxPanel = parent.component;
            vboxSaveImage = uix.VBox('Parent', boxPanel, 'Spacing', 5);
            saveImage1stRow = uix.HBox('Parent', vboxSaveImage, 'Spacing', 5);
            
            obj.btnSave = uicontrol(obj.PROP_BUTTON{:}, 'Parent', saveImage1stRow, 'string', 'Save');
            obj.btnSaveAs = uicontrol(obj.PROP_BUTTON{:}, 'Parent', saveImage1stRow, 'string', 'Save As');
            uix.Empty('Parent', saveImage1stRow);  % space
            uicontrol(obj.PROP_LABEL{:}, 'Parent', saveImage1stRow, 'String', 'Notes:'); % the 'Notes' label
            obj.edtNotes = uicontrol(obj.PROP_EDIT{:}, 'Parent', saveImage1stRow);
            saveImage1stRow.Widths = [-4 -5 -1 -4 -8];
            vboxSaveImage.Heights = 35;
            
            %%%%%%%% Ui components set callbacks  %%%%%%%%
            set(obj.edtNotes, 'Callback', @(h,e)obj.respondToInputNotes);
            set(obj.btnSave, 'Callback', @(h,e)obj.respondToSave);
            set(obj.btnSaveAs, 'Callback', @(h,e)obj.respondToSaveAs);
            
            %%%%%%%% set internal values %%%%%%%%
            obj.height = 40;
            obj.width = 400;
            obj.category = category;
            
            %%%%%%% init values from the saveLoad object %%%%%%%
            obj.refresh(saveLoadPhysical);
        end
        
        function respondToInputNotes(obj, ~, ~)
            notesString = get(obj.edtNotes, 'String');
            saveLoad = SaveLoad.getInstance(obj.category);
            saveLoad.setNotes(notesString);
        end
        
        function respondToSave(obj, ~, ~)
            obj.respondToInputNotes(); % to let the notes get into the saveload
            saveLoad = SaveLoad.getInstance(obj.category);
            saveLoad.save();
        end
                
        function respondToSaveAs(obj, ~, ~)
            obj.respondToInputNotes(); % to let the notes get into the saveload
            
            [fileName,fullPathFolder,~] = uiputfile('.mat','Save As...');
            if ~ischar(fileName) || ~ischar(fullPathFolder)
                % the user pressed cancel
                return
            end
            fullPathFolder = PathHelper.appendBackslashIfNeeded(fullPathFolder);
            
            saveLoad = SaveLoad.getInstance(obj.category);
            saveLoad.saveAs([fullPathFolder fileName]);
        end
        
        function refresh(obj, saveLoadObject)
            % refresh the view on the screen
            %
            % saveLoadObject - the saveLoad to take info from
            
            obj.edtNotes.String = saveLoadObject.mNotes;
        end
    end
        
        
    % overridden from EventListener
    methods
        % When events happen, this function jumps.
        %
        % event is the event sent from the EventSender
        function onEvent(obj, event) %#ok<INUSD>
            saveLoad = SaveLoad.getInstance(obj.category);
            obj.refresh(saveLoad);
        end
    end
    
end

