classdef ViewImageResult < ViewVBox
    %VIEWSTAGESCAN this view shows the scan results of the imaging
    %   consists of a header part and the image (axes) part 
    
    properties
        vHeader % the options view
        vImage  % the image view
    end
    
    methods
        function obj = ViewImageResult(parent, controller)
            obj@ViewVBox(parent, controller);
            obj.vHeader = ViewImageResultHeader(obj, controller);
            try removeBaseObject(ViewImageResultImage.NAME); catch; end;
            obj.vImage = ViewImageResultImage(obj, controller);
            
            obj.height = obj.vHeader.height + obj.vImage.height + 10;
            obj.width = max([obj.vHeader.width, obj.vImage.width]) + 10;
            
            obj.setHeights([obj.vHeader.height, -1]);
        end
    end
    
    methods(Static = true)
        function axesFig = getAxes
            % get the axes() in the GUI figure
            view = getObjByName(ViewImageResultImage.NAME);
            axesFig = view.vAxes;
        end
    end
end

