classdef ExperimentDefault < Experiment
    %EXPDEFAULT Default experiment, to be run before any actual experiment
    %           starts
    
    properties (Constant, Hidden)
        EXP_NAME = '';
    end
    
    methods
        function prepare(obj) %#ok<*MANU>
        end
        
        function perform(obj)
        end
        
        function analyze(obj)
        end
    end
    
end

