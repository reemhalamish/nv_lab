classdef ViewExperimentPlot < ViewVBox & EventListener
    %VIEWEXPERIMENTPLOT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        expName
        nDim = 1;   % data is 1D 99% of the time. Can be overridden by subclasses
        
        vAxes
        btnStartStop
    end
    
    properties
        DEFAULT_EMPTY_DATA = [0; NaN];
    end
    
    methods
        
        function obj = ViewExperimentPlot(expName, parent, controller)
            obj@ViewVBox(parent, controller);
            obj@EventListener(Experiment.NAME);
            obj.expName = expName;
            
            fig = obj.component;    % for brevity
            obj.vAxes1 = axes('Parent', fig, ...
                'NextPlot', 'replacechildren');
            obj.btnStartStop = ButtonStartStop(fig);
                obj.btnStartStop.startCallback = @obj.btnStartCallback;
                obj.btnStartStop.stopCallback  = @obj.btnStopCallback;
            fig.Heights = [-1, 30];
        end
        
        
        %%% Callbacks %%%
        function btnStopCallback(obj, ~, ~)
            exp = obj.getExperiment;
            exp.pause;
        end
        
        function btnStartCallback(obj, ~, ~)
            exp = obj.getExperiment;
            exp.run;
        end
        
        %%% Plotting %%%
        function plot(obj)
            % Check whether we have anything to plot
            exp = obj.getExperiment;
            data = exp.results;
            
            if isempty(obj.vAxes.Children)
                % Nothing is plotted yet
                if isnan(data) || isempty(data)
                    % Default plot
                    firstAxisVector = obj.DEFAULT_EMPTY_DATA(1);
                    data = obj.DEFAULT_EMPTY_DATA(2);
                else
                    % First plot
                    firstAxisVector = exp.mCurrentXAxisParam.value;
                end
                bottomLabel = exp.mCurrentXAxisParam.label;
                leftLabel = exp.mCurrentYAxisParam.label;
                AxesHelper.fill(obj.vAxes, data, obj.nDim, ...
                    firstAxisVector, [], bottomLabel, leftLabel);
                
                % Maybe this experiment shows more than one x/y-axis
                if ~isnan(exp.topParam)
                    AxesHelper.addAxisAcross(obj.vAxes, 'x', ...
                        exp.topParam.value, ...
                        exp.topParam.label)
                end
                if ~isnan(exp.rightParam)
                    AxesHelper.addAxisAcross(obj.vAxes, 'y', ...
                        exp.rightParam.value, ...
                        exp.rightParam.label)
                end
            else
                firstAxisVector = exp.mCurrentXAxisParam.value;
                AxesHelper.update(obj.vAxes, data, obj.nDim, firstAxisVector)
            end

        end
        
        
        function refresh(obj)
            exp = obj.getExperiment;
            obj.btnStartStop.isRunning = ~exp.stopFlag;
            obj.plot;
        end
        
    end
    
    methods
        function exp = getExperiment(obj)
            if Experiment.current(obj.expName)
                exp = getObjByName(Experiment.NAME);
            else
                [expNamesCell, expClassNamesCell] = Experiment.getExperimentNames();
                ind = strcmp(obj.expName, expNamesCell); % index of obj.expName in list
                
                % We use @str2func which is superior to @eval, when possible
                className = str2func(expClassNamesCell{ind}); % function handle for the class
                exp = className();
            end
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            % We're listening to all experiments, but only care if the
            % experiment is "ours".
            if strcmp(event.creator.EXP_NAME, obj.expName)
                obj.refresh;
            end
        end
    end
    
end

