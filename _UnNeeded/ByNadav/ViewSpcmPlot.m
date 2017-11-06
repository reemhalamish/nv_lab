classdef ViewSpcmPlot < ViewHBox & EventListener
    %VIEWSPCMPLOT Shows recent readings of SPCM
    %   
    
    properties
        wrap            % positive integer, how many records in plot

        vAxes           % axes view, to use for the plotting
        cbxUsingWrap
        edtWrap
    end
    properties(Constant = true)
        BOTTOM_LABEL = 'time [sec]'; % Text for horiz. axis
        LEFT_LABEL = 'kcps';     % Text for vert. axis
        
        DEFAULT_WRAP_VALUE = 50;    % Value of wrap set in initiation
        DEFAULT_USING_WRAP = true;  % boolean, does this window uses wrap
        
    end
    
    methods
        function obj = ViewSpcmPlot(parent, controller)
            obj@ViewHBox(parent, controller);
            obj@EventListener(SpcmCounter.NAME);
            obj.wrap = obj.DEFAULT_WRAP_VALUE;
            
            obj.vAxes = axes('Parent', obj.component, 'ActivePositionProperty', 'outerposition');
            
            xlabel(obj.vAxes,obj.BOTTOM_LABEL);
            ylabel(obj.vAxes,obj.LEFT_LABEL);
            
            axes()
            %%%% Pane for wrapping data %%%%
            vboxWrap = uix.VBox('Parent',obj.component);
                uix.Empty('Parent', vboxWrap);
                obj.cbxUsingWrap = uicontrol(obj.PROP_CHECKBOX{:}, ...
                    'Parent', vboxWrap, ...
                    'Value', obj.DEFAULT_USING_WRAP, ...
                    'String', 'Wrap?', ...
                    'Callback', @obj.cbxUsingWrapCallback);
                uicontrol(obj.PROP_LABEL{:}, 'Parent', vboxWrap, ...
                    'String', '# of Pts');
                obj.edtWrap = uicontrol(obj.PROP_EDIT{:}, ...
                    'Parent', vboxWrap, ...
                    'String', obj.DEFAULT_WRAP_VALUE, ...
                    'Callback', @obj.edtWrapCallback);
                uix.Empty('Parent', vboxWrap);
                vboxWrap.Heights = [-3 -1 -1 -1 -3];
            obj.component.Widths = [-1 70];
            
            %%%% Define size %%%%
            obj.width = 650;            
            obj.height = 300;
            
        end
        
        function bool = isUsingWrap(obj)
            bool = obj.cbxUsingWrap.Value;
        end
        
        %%%% Callbacks %%%%
        function cbxUsingWrapCallback(obj,~,~)
            obj.recolor(obj.edtWrap,~obj.isUsingWrap)
        end
        function edtWrapCallback(obj,~,~)
            if ~ValidationHelper.isValuePositiveInteger(obj.edtWrap.String)
                EventStation.anonymousWarning('Wrap needs to be a positive integer! Reverting.')
                obj.edtWrap.String = obj.wrap;
            end
            obj.wrap = str2double(obj.edtWrap.String);
        end
    end
    
    %% overridden from EventListener
    methods
        % when event happens, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            spcmCount = event.creator;
            if isfield(event.extraInfo, spcmCount.EVENT_SPCM_COUNTER_UPDATED)   % event = update
                if obj.isUsingWrap
                    [time,kcps,std] = spcmCount.getRecords(obj.wrap);
                else
                    [time,kcps,std] = spcmCount.getRecords;
                end
                dimNum = 1;
                AxesHelper.fillAxes(obj.vAxes, kcps, dimNum, time, nan, obj.BOTTOM_LABEL, obj.LEFT_LABEL);   %Still requires std implementation
                errorbar(obj.vAxes, time, kcps, std);   % needs to be inside $fillAxes
                
                set(obj.vAxes,'XLim',[-inf, inf]);  % Creates smooth "sweep" of data
                drawnow;                            % consider using animatedline
            end
            if isfield(event.extraInfo, spcmCount.EVENT_SPCM_COUNTER_RESET)    % event = reset
                line = obj.vAxes.Children;
                delete(line);
            end
        end
    end
    
end

