classdef ViewError < GuiComponent & EventListener
    %VIEWERROR showing the errors
    %   Detailed explanation goes here
    
    properties(Access = protected, Constant = true)
        PROP_ERROR_TEXT = {'Style', 'text', 'ForegroundColor', 'red','BackgroundColor', 'white', 'HorizontalAlignment', 'center'};
        PROP_ERROR_MSG = {'FontSize',14,'String', 'Errors will be displayed here!'};
        PROP_ERROR_FROM = {'FontSize',12, 'String', ''};
        PROP_ERROR_MAIN = {'BackgroundColor', 'white', 'Spacing', 20, 'Padding', 5};
        DELAY_SHOW_ERRORS_SEC = 12;
    end
    
    properties(Access = protected)
        timerDisappearError;
        tvFrom
        tvMsg
    end
    
    methods
        function obj = ViewError(parent, controller)
            %%%%%% parent constructors %%%%%%
            obj@GuiComponent(parent, controller);
            obj@EventListener();
            obj.setListeningForAll(true);
            
            %%%%%% UI initialization %%%%%%
            obj.width = 800;   % for the screen
            obj.height = 60;   % for the screen
            
            obj.component = uix.HBox(obj.PROP_ERROR_MAIN{:}, 'Parent', parent.component);
            obj.tvFrom = uicontrol(obj.PROP_ERROR_TEXT{:}, obj.PROP_ERROR_FROM{:}, 'Parent', obj.component);
            obj.tvMsg = uicontrol(obj.PROP_ERROR_TEXT{:}, obj.PROP_ERROR_MSG{:}, 'Parent', obj.component);
            obj.component.Widths = [-3 -10];
            obj.cleanErrorAfterTime()
        end
        
        
        %% destructor
        function delete(obj)
            obj.exitTimersIfNeeded();
        end
    end
    
    methods(Access = protected)
        function cleanErrorAfterTime(obj)
            obj.exitTimersIfNeeded();
            
            obj.timerDisappearError = timer('TimerFcn',@(x,y)obj.displayOff,'StartDelay',ViewError.DELAY_SHOW_ERRORS_SEC);
            start(obj.timerDisappearError);
        end
        
        function displayOff(obj)
            set(obj.component, 'Visible', 'off');
        end
        
       
        function exitTimersIfNeeded(obj)
            try
                if (isobject(obj.timerDisappearError))
                    % if it was running from a previous error
                    stop(obj.timerDisappearError);
                    delete(obj.timerDisappearError);
                end
            catch err
                disp(err)
            end
        end
    end
    
    
    methods
        %% when error event happen, this function jumps.
        % extraInfo is a struct sent from the physics
        function out = onEvent(obj, event)
            if ~(event.isError)
                out = false;
                return
            end
            eventSender = event.creatorName;
            errorMsg = event.extraInfo.(Event.ERROR_MSG);
            obj.tvFrom.String = sprintf('from %s', eventSender);
            obj.tvMsg.String = errorMsg;
            set(obj.component, 'Visible', 'on');
            
            out = true;
            obj.cleanErrorAfterTime();
        end
    end
end

