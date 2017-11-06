classdef GuiControllerSpcmCounter < GuiController
    %GUICONTROLLERSPCMCOUNTER Gui Controller for the SPCM counter
    %   
    
    methods
        
        function obj = GuiControllerSpcmCounter()
            Setup.init;
            shouldConfirmOnExit = false;
            openOnlyOne = true;
            windowName = 'SPCM Counter';
            obj = obj@GuiController(windowName, shouldConfirmOnExit, openOnlyOne);
        end
        
        function view = getMainView(obj, figureWindowParent)
            % this function should get the main View of this GUI.
            % can call any view constructor with the params:
            % parent=figureWindowParent, controller=obj
            view = ViewSpcm(figureWindowParent, obj);
        end
        
        function onAboutToStart(obj)
            % Callback. Things to run right before the window will be drawn
            % to the screen.
            % Child classes can override this method
            obj.moveToMiddleOfScreen();
        end
        
        function onClose(obj)
            % callback. things to run when need to close the GUI.
            spcmCounter = getObjByName(SpcmCounter.NAME);
            if ~spcmCounter.isOn; return; end
            EventStation.anonymousWarning('SPCM Counter is now turned off');
            spcmCounter.stop;
            spcmCounter.reset;
                % maybe implement static property of class that counts
                % instances
        end
    end
    
end

