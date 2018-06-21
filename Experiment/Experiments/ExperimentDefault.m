classdef ExperimentDefault < Experiment
    %EXPDEFAULT Default experiment, to be run before any actual experiment
    %starts
    
    properties (Constant, Hidden)
        EXP_NAME = '';
    end
    
    methods
        function loadSequence(obj) %#ok<*MANU>
        end
        
        function plotResults(obj)
        end
        
    end
    
end

