classdef ViewImageResultImage < GuiComponent & EventListener & BaseObject
    %VIEWIMAGERESULTIMAGE view that shows the scan results
    %   it is being used by other GUI components (such as the various
    %   options above it) as well as the StageScanner when it needs to
    %   duplicate the axes() object (which is obj.vAxes)
    
    % todo: check why this does not call destructor when closed
    
    properties
        vAxes       % the axes view to use for the plotting
%        vColorbar   % colorbar axes view. todo: implement. Without it
%                       copying the colorbar will remove label
    end
    properties(Constant = true)
        NAME = 'ViewImageResultImage';
    end
    
    methods
        function obj = ViewImageResultImage(parent, controller)
            obj@GuiComponent(parent, controller);
            obj@EventListener(ImageScanResult.NAME);
            obj@BaseObject(ViewImageResultImage.NAME);
            addBaseObject(obj);
            
            obj.component = uicontainer('parent', parent.component);
            obj.vAxes = axes('Parent', obj.component, 'ActivePositionProperty', 'outerposition');

            colorbar(obj.vAxes);
            axes(); % creating floating axes() so that default calls to axes (such as image() surf() etc.) won't reach this view but the invis floating one
            
            % update the axes with a scan if exists
            stageScanner = getObjByName(StageScanner.NAME);
            if stageScanner.isScanReady
                dim = stageScanner.getScanDimensions;
                sp = stageScanner.mStageScanParams;
                firstAxis = sp.getFirstScanAxisVector;
                secondOptionalAxis = sp.getSecondScanAxisVector;
                botLabel = stageScanner.getBottomScanLabel;
                leftLabel = stageScanner.getLeftScanLabel;
                AxesHelper.fillAxes(obj.vAxes, stageScanner.mScan, dim, firstAxis, secondOptionalAxis, botLabel, leftLabel);
                obj.parent.vHeader.updateAxes;  % let the other views in the header draw on the axes
            end
            
            obj.height = 600;   % minimum
            obj.width = 600;    % minimum
        end
        
        function delete(obj)
            try
                removeBaseObject(obj.NAME);
            catch err
                EventStation.anonymousWarning(err.message);
            end
        end
    end
    
    
    %% overridden from EventListener
    methods
        % when event happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if isfield(event.extraInfo, ImageScanResult.EVENT_IMAGE_UPDATED)
                isr = getObjByName(ImageScanResult.NAME);
                AxesHelper.fillAxes(obj.vAxes, isr.mData, isr.mDimNumber, isr.mFirstAxis, isr.mSecondAxis, isr.mLabelBot, isr.mLabelLeft);
            end
        end
    end
end