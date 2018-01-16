classdef ViewImageResultPanelColormap < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for coloring the image
    %   Detailed explanation goes here
    
    properties
        popupTypes
        cbxAuto
        edtMin
        edtMax
        
        minVal = 0;
        maxVal = 1;
    end
    
    properties (Constant = true)
        TYPE_OPTIONS = {'Pink', 'Jet', 'HSV', 'Hot', 'Cool', ...
            'Spring', 'Summer', 'Autumn', 'Winter', ...
            'Gray', 'Bone', 'Copper', 'Lines'};
    end
    
    methods
        function obj = ViewImageResultPanelColormap(parent, controller)
            obj@GuiComponent(parent, controller);
            panel = uix.Panel('Parent', parent.component,'Title','Colormap', 'Padding', 5);
            vboxMain = uix.VBox('Parent', panel, 'Spacing', 5, 'Padding', 0);
            obj.component = vboxMain;
            
            colormap1stRow = uix.HBox('Parent', vboxMain, 'Spacing', 5);
            obj.popupTypes = uicontrol(obj.PROP_POPUP{:}, ...
                'Parent', colormap1stRow, ...
                'String', obj.TYPE_OPTIONS, ...
                'Callback', @obj.popupTypesCallback);
            uix.Empty('Parent', colormap1stRow);
            obj.cbxAuto = uicontrol(obj.PROP_CHECKBOX{:}, ...
                'Parent', colormap1stRow, ...
                'String', 'Auto', ...
                'Value', true, ...
                'Callback', @obj.cbxAutoCallback);
            colormap1stRow.Widths = [-1 15 50];
            
            colormap2ndRow = uix.HBox('Parent', vboxMain, 'Spacing', 5);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', colormap2ndRow, ...
                'String', 'Min');  % Label
            obj.edtMin = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', colormap2ndRow, ...
                'String', obj.minVal, ...
                'Callback', @obj.edtMinCallback);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', colormap2ndRow, ...
                'String', 'Max');  % Label
            obj.edtMax = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', colormap2ndRow, ...
                'String', obj.maxVal, ...
                'Callback', @obj.edtMaxCallback);
            colormap2ndRow.Widths =  [-1 -1 -1 -1];
            
            vboxMain.Heights = [25 -1];
            obj.height = 100;
            obj.width = 160;
        end
        
        function update(obj)
            viewImage = getObjByName(ViewImageResultImage.NAME);
            vAxes = viewImage.vAxes;
            if obj.cbxAuto.Value
                obj.autoSetColormapLimits(vAxes);
            else
                % Update the plot with the specified min/max values from the GUI
                caxis(vAxes, [obj.minVal obj.maxVal]);
            end
        end
        
        function autoSetColormapLimits(obj,axis)
            img = getimage(axis);
            if isempty(img)
                return;     % Can't fetch limits if there is no data
            end
            maxValue = max(max(img(~isinf(img))));
            if maxValue > 0
                minValue = min(min(img(img ~= 0)));
                if (minValue ~= maxValue)
                    caxis(axis, [minValue maxValue]);
                else % Min and max are the same, there is only one value that is not 0.
                    caxis(axis, 'auto');
                end
            else % Max value is 0, all values are 0.
                caxis(axis, 'auto');
            end
            cAxisLimits = caxis(axis);      % A little silly, but caxis returns the limits
                                            % only if there are no extra arguments
            
            % update the GUI's min and max values with the auto values
            obj.minVal = min(cAxisLimits);
            obj.maxVal = max(cAxisLimits);
            obj.edtMin.String = StringHelper.formatNumber(obj.minVal,2);
            obj.edtMax.String = StringHelper.formatNumber(obj.maxVal,2);
        end
        
        %%%% Callbacks %%%%
        function popupTypesCallback(obj,~,~)
            resultImage = getObjByName(ViewImageResultImage.NAME);
            colormapName = obj.TYPE_OPTIONS{obj.popupTypes.Value};
            colormap(resultImage.vAxes,colormapName)
        end
        
        function cbxAutoCallback(obj,~,~)
            if obj.cbxAuto.Value
                obj.update;
            end
        end
        
        function edtMinCallback(obj,~,~)
            if ~ValidationHelper.isStringValueANumber(obj.edtMin.String)
                obj.edtMin.String = StringHelper.formatNumber(obj.minVal,2);
                EventStation.anonymousError('Minimum colormap value must be a number! Reverting.')
            else
                newMinVal = str2double(obj.edtMin.String);
                if newMinVal > obj.maxVal
                    obj.edtMin.String = StringHelper.formatNumber(obj.minVal,2);
                    EventStation.anonymousError('Minimum colormap value can''t be larger than Maximum! Reverting.')
                end
            end
            obj.minVal = newMinVal;
            obj.cbxAuto.Value = false;
            obj.update;
        end
        
        function edtMaxCallback(obj,~,~)
            if ~ValidationHelper.isStringValueANumber(obj.edtMax.String)
                obj.edtMax.String = StringHelper.formatNumber(obj.maxVal,2);
                EventStation.anonymousError('Maximum colormap value must be a number! Reverting.')
            else
                newMaxVal = str2double(obj.edtMax.String);
                if obj.minVal > newMaxVal
                    obj.edtMax.String = StringHelper.formatNumber(obj.maxVal,2);
                    EventStation.anonymousError('Maximum colormap value can''t be smaller than Minimum! Reverting.')
                end
            end
            obj.maxVal = newMaxVal;
            obj.cbxAuto.Value = false;
            obj.update;
        end
    end
    
end

