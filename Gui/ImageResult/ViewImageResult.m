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
            obj.vImage = ViewImageResultImage(obj, controller);
            obj.vHeader.startListeningTo(ImageScanResult.NAME);     % This will insure that header actions will occur after image has updated
            
            obj.height = obj.vHeader.height + obj.vImage.height + 10;
            obj.width = max([obj.vHeader.width, obj.vImage.width]) + 10;
            
            obj.setHeights([obj.vHeader.height, -1]);
        end
    end
end

