classdef ViewImageResultPanelColormap < GuiComponent
    %VIEWSTAGESCANPANELPLOT panel for coloring the image
    %   Detailed explanation goes here
    
    properties
        popupTypes
        cbxAuto
        edtMin
        edtMax
    end
    
    properties (Constant = true)
        TYPE_OPTIONS = {'Jet', 'HSV', 'Hot', 'Cool', ...
            'Spring', 'Summer', 'Autumn', 'Winter', ...
            'Gray', 'Bone', 'Copper', 'Pink', 'Lines'};
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
                'String', '0', ...
                'Callback', @obj.edtMinCallback);
            uicontrol(obj.PROP_LABEL{:}, 'Parent', colormap2ndRow, ...
                'String', 'Max');  % Label
            obj.edtMax = uicontrol(obj.PROP_EDIT{:}, ...
                'Parent', colormap2ndRow, ...
                'String', '1', ...
                'Callback', @obj.edtMaxCallback);
            colormap2ndRow.Widths =  [-1 -1 -1 -1];
            
            vboxMain.Heights = [25 -1];
            obj.height = 100;
            obj.width = 160;
        end
        
        function update(obj)
            viewImage = getObjByName(ViewImageResultImage.NAME);
            axes = viewImage.vAxes;
            if obj.cbxAuto.Value
                obj.autoSetColormapLimits(axes);
            else
                % Update the plot with the specified min/max values from the GUI
                minColor = str2double(obj.edtMin.String);
                maxColor = str2double(obj.edtMax.String);
                obj.edtMin.UserData = minColor;
                obj.edtMax.UserData = maxColor;
                caxis(axes, [minColor maxColor]);
            end
        end
        
        function autoSetColormapLimits(obj,axis)
            img = getimage(axis);
            if isempty(img)
                return;     % Can't fetch limits if there is no data
            end
            maxValue = max(max(img));
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
            minColor = sprintf('%.2f', min(cAxisLimits));
            maxColor = sprintf('%.2f', max(cAxisLimits));
            set(obj.edtMin, 'String', minColor, 'UserData', minColor);
            set(obj.edtMax, 'String', maxColor, 'UserData', maxColor);
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
                obj.edtMin.String = obj.edtMin.UserData;
                EventStation.anonymousError('Minimum colormap value must be a number! Reverting.')
            else
                minVal = str2double(obj.edtMin.String);
                maxVal = str2double(obj.edtMax.String);
                if minVal>maxVal
                    obj.edtMin.String = obj.edtMin.UserData;
                    EventStation.anonymousError('Minimum colormap value can''t be larger than Maximum! Reverting.')
                end
            end
            obj.cbxAuto.Value = false;
            obj.update;
        end
        
        function edtMaxCallback(obj,~,~)
            if ~ValidationHelper.isStringValueANumber(obj.edtMax.String)
                obj.edtMax.String = obj.edtMax.UserData;
                EventStation.anonymousError('Maximum colormap value must be a number! Reverting.')
            else
                minVal = str2double(obj.edtMin.String);
                maxVal = str2double(obj.edtMax.String);
                if minVal>maxVal
                    obj.edtMax.String = obj.edtMax.UserData;
                    EventStation.anonymousError('Maximum colormap value can''t be smaller than Minimum! Reverting.')
                end
            end
            obj.cbxAuto.Value = false;
            obj.update;
        end
    end
    
end

