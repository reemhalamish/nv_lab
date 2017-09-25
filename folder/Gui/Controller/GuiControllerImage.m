classdef GuiControllerImage < GuiController
    %GUICONTROLLERIMAGE Gui Controller for the image GUI
    %   
    
    
    methods
        function obj = GuiControllerImage()
            shouldConfirmOnExit = true;
            openOnlyOne = true;
            windowName = 'ImageNVC_touch_new';
            obj = obj@GuiController(windowName, shouldConfirmOnExit, openOnlyOne);
        end
        
        function view = getMainView(obj, figureWindowParent)
            % this function should get the main View of this GUI.
            % can call any view constructor with the params:
            % parent=figureWindowParent, controller=obj
            view = ViewMainImage(figureWindowParent, obj);
        end
        
        function onClose(obj)
            % callback. things to run when need to close the GUI.
            StageControlEvents.sendCloseConnection;
        end
    end
    
end

