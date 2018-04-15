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
            % This function should get the main View of this GUI.
            % It can call any view constructor with the params:
            % parent=figureWindowParent, controller=obj
            view = ViewMainImage(figureWindowParent, obj);
        end
        
        function onStarted(obj)
            obj.windowMinHeight = 1;
            obj.windowMinWidth = 1;
        end
        
        function onClose(obj)
            % Callback. Things to run when need to close the GUI.
            try
                imageScanResult = getObjByName(ImageScanResult.NAME);
                imageScanResult.checkGraphicAxes;       % Tell it that vAxes are no longer available (without being EventSender)
            catch
                % Could not find ImageScanResult, so nothing needs updating.
            end
%             StageControlEvents.sendCloseConnection;
                        % requires GUI for closing connection demand
        end
    end
    
end

