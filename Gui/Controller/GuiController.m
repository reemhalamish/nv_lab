classdef GuiController < handle
    %MAINCONTROLLER controls the communication between the GUI and the physics
    %   Detailed explanation goes here
    
    properties(Access = public)
        views  % 1D array of gui components
        windowMinHeight = 0     % will be set when starting to the mainView.height
        windowMinWidth = 0      % will be set when starting to the mainView.width
        figureWindow            % the window
        confirmOnClose          % boolean
        openOnlyOne             % boolean. if strict to open just 1 instance of this window
        startPosition = nan     % point on screen (1x2 double) or nan if not important
        windowName              % string
        screenWidth             % in pixels
        screenHeight            % in pixels
    end
    
    properties(Constant = true)
        POSITION_INDEX_X0_LEFT = 1
        POSITION_INDEX_Y0_BOT = 2
        POSITION_INDEX_WIDTH = 3
        POSITION_INDEX_HEIGHT = 4
    end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %                                                %
            %   Copy & Paste  any one of the lines below!    %
            %       (Some nice callbacks lie here,           %
            %         waiting to be overridden...)           %
            %                                                %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %     %% various callbacks to be overriden if needed
    %     methods
    %         function onAboutToStart(obj)
    %             % callback. things to run right before the window will be drawn
    %             % to the screen.
    %             % child classes can override this method
    %         end
    %
    %         function onStarted(obj)
    %             % callback. thigs to run after the window is already started
    %             % and running.
    %             % child classes can override this method
    %         end
    %         function onSizeChanged(obj, newX0, newY0, newWidth, newHeight)
    %             % callback. thigs to run when the window size is changed
    %             % child classes can override this method
    %         end
    %         function onClose(obj)
    %             % callback. things to run when need to close the GUI.
    %             % child classes can override this method
    %         end
    %     end
    
    methods
        function obj = GuiController(windowName, confirmOnClose, openOnlyOne)
            obj = obj@handle;
            obj.windowName = windowName;
            obj.views = {};
            obj.confirmOnClose = confirmOnClose;
            obj.openOnlyOne = openOnlyOne;
        end
        function start(obj)
            openAlready = GuiController.findOpenOrNan(obj.windowName);
            if obj.openOnlyOne && isobject(openAlready)
                sprintf('%s is already open!', obj.windowName);
                figure(openAlready);
            else
                obj.figureWindow = obj.createNewFigureInvis();
                screenSize = get(groot, 'MonitorPositions');
                obj.screenWidth = screenSize(obj.POSITION_INDEX_WIDTH);
                obj.screenHeight = screenSize(obj.POSITION_INDEX_HEIGHT);
                
                dummyGuiComponent.component = obj.figureWindow;
                mainView = obj.getMainView(dummyGuiComponent);
                obj.windowMinHeight = mainView.height;
                obj.windowMinWidth = mainView.width;
                
                obj.onAboutToStart();
                obj.figureWindow.Visible = 'on';
                obj.onStarted();
            end
        end  % constructor
        
        function addView(obj, view)
            obj.views{end + 1} = view;
        end
        
    end
    
    %% various callbacks to be overriden if needed
    methods
        function onAboutToStart(obj)
            % callback. things to run right before the window will be drawn
            % to the screen.
            % child classes can override this method
        end
        
        function onStarted(obj)
            % callback. thigs to run after the window is already started
            % and running.
            % child classes can override this method
        end
        
        function onSizeChanged(obj, newX0, newY0, newWidth, newHeight)
            % callback. thigs to run when the window size is changed
            % child classes can override this method
        end
        
        function onClose(obj)
            % callback. things to run when need to close the GUI.
            % child classes can override this method
        end
    end
    
    methods
        function callbackCloseRequest(obj, hObject)
            if obj.confirmOnClose
                needToClose = QuestionUserYesNo(...
                    'Close Request Function', ...
                    sprintf('Are you sure you want to close %s?',...
                    obj.windowName));
            else
                needToClose = true;
            end
            
            if needToClose
                fprintf('Closing GUI "%s"\n', obj.windowName);
                for k = 1 : length(obj.views)
                    obj.views{k}.onCloseGui();
                end
                
                obj.onClose();
                delete(hObject);
            end
        end
        
        function callbackSizeChanged(obj)
            % make sure the view isn't too small!
            currentSize = obj.figureWindow.Position(3 : 4);
            [newX0, newY0, newWidth, newHeight] = multipleAssign(obj.figureWindow.Position);
%             warning('why above not working???')
%            
%             p = obj.figureWindow.Position;
%             disp(p)
%             newX0 = p(1); newY0 = p(2); newWidth =p(3); newHeight = p(4);
            obj.onSizeChanged(newX0, newY0, newWidth, newHeight);
            windowMinSize = [obj.windowMinWidth obj.windowMinHeight];
            if ~any(windowMinSize > currentSize); return; end
            newSize = max(windowMinSize, currentSize);
            currentStartPoint = obj.figureWindow.Position(1 : 2);
            obj.figureWindow.Position = [currentStartPoint newSize];
        end
    end
    
    %% helper methods
    methods
        function toFullscreen(obj)
            % change the object size to be fullscreen
            obj.figureWindow.Position = [0,0, obj.screenWidth, obj.screenHeight];
        end
        
        function toAlmostFullscreen(obj)
            % change the figure size to be almost fullscreen - leaving only
            % the "start" windows-bottom visible
            obj.figureWindow.Position = [2,40, obj.screenWidth - 3, obj.screenHeight - 65];
        end
        
        function maximize(obj)
            % maximize the window.
            % this function can only run AFTER the window has been rendered
            warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
            jFrame = get(handle(obj.figureWindow),'JavaFrame');
            set(jFrame,'Maximized',true);
        end
        
        function moveToMiddleOfScreen(obj)
            oldPos = obj.figureWindow.Position;
            fWidth = max(oldPos(obj.POSITION_INDEX_WIDTH), obj.windowMinWidth);
            fHeight = max(oldPos(obj.POSITION_INDEX_HEIGHT), obj.windowMinHeight);
            spaceX = max(obj.screenWidth - fWidth, 0);
            spaceY = max(obj.screenHeight - fHeight, 0);
            newX0 = spaceX / 2;
            newY0 = spaceY / 2;
            obj.figureWindow.Position = [newX0 newY0 fWidth fHeight];
        end
        
        function figureWindow = createNewFigureInvis(obj)
            % the figure is being created invisible so that it will take
            % less time to load it (changing strings inside etc).
            % only when it's ready, someone will need to call -
            % figureWindow.Visible = 'on'
            if isnan(obj.startPosition)
                startPos = [50 50];
            else
                startPos = obj.startPosition;
            end
            figureWindow = figure('Name', obj.windowName, ...
                'Position', [startPos obj.windowMinWidth obj.windowMinHeight], ...
                'MenuBar', 'none',...
                'Toolbar', 'none', ...
                'NumberTitle', 'off',...
                'Visible', 'off', ...
                ...
                ... % closing - if need to close anything else, make it in this callback
                'CloseRequestFcn', @(hObject, eventdata, handles) obj.callbackCloseRequest(hObject), ...
                ...
                ... % Make sure resize doesn't make it too small
                'SizeChangedFcn', @(hObject, eventdata, handles) obj.callbackSizeChanged);
        end
    end
    
    %% to be overriden
    methods(Abstract)
        view = getMainView(obj, figureWindowParent)
        % this function should get the main View of this GUI.
        % can call any view constructor with the params:
        % parent=figureWindowParent, controller=obj
    end
    
    methods(Static = true)
        function openWindow = findOpenOrNan(windowName)
            % looks for a window with this name. if found, return it. else
            % - returns NaN
            openWindow = NaN;
            list = get(0, 'Children');
            for i = 1:size(list,1)
                if strcmp(handle(list(i)).Name, windowName)
                    openWindow = list(i);
                    return
                end
            end
        end
    end
    
end

