classdef GuiControllerTrackablePosition < GuiController
    %GUICONTROLLERTRACKABLEPOSITION Gui Controller for position tracking.
    %To be united into controller for the tracker as a whole
    
    methods
        function obj = GuiControllerTrackablePosition()
            Setup.init;
            shouldConfirmOnExit = false;
            windowName = 'Track Stage Position';
            openOnlyOne = true;  
            
            obj = obj@GuiController(windowName, shouldConfirmOnExit, openOnlyOne);
        end
        
        function view = getMainView(obj, figureWindowParent)
            % This function should get the main View of this GUI.
            % It can call any view constructor with the params:
            % parent=figureWindowParent, controller=obj
            
            % By this stage we assume the position trackable has already
            % been initiated, and need no further checking
            view = ViewTrackablePosition(figureWindowParent, obj);
        end
        
        function onAboutToStart(obj)
            % callback. Things to run right before the window will be drawn
            % to the screen.
            % child classes can override this method
            obj.moveToMiddleOfScreen();
        end
        
        function onStarted(obj)
            % callback. Things to run after the window is already started
            % and running.
            % child classes can override this method
            view = obj.views{:};
            view.refresh;
        end
        
        function onSizeChanged(obj, newX0, newY0, newWidth, newHeight) %#ok<INUSD>
            % Callback. Things to run when the window size is changed
            % child classes can override this method
            view = obj.views{:};
            view.legend1.Location = 'northwest';
        end

    end
    
end