classdef GuiControllerTrackablePosition < GuiController
    %GUICONTROLLERTRACKABLEPOSITION Gui Controller for position tracking.
    %To be united into controller for the tracker as a whole
    
    properties
    end
       
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

            % For trackables we need to first create a working experiment,
            % if needed
            try
                getExpByName(Tracker.TRACKABLE_POSITION_NAME)
            catch
                stageName = 'stage fine';
                laserName = '';
                TrackablePosition(stageName,laserName);
            end
            
            view = ViewTrackablePosition(figureWindowParent, obj);
        end
        
        function onAboutToStart(obj)
            % callback. things to run right before the window will be drawn
            % to the screen.
            % child classes can override this method
            obj.moveToMiddleOfScreen();
        end
        
        function onSizeChanged(obj, newX0, newY0, newWidth, newHeight) %#ok<INUSD>
            % Callback. Things to run when the window size is changed
            % child classes can override this method
            view = obj.views{:};
            view.legend1.Location = 'northwest';
        end

    end
    
end