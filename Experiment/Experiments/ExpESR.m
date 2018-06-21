classdef ExpESR < Experiment
    %EXPESR ESR (electron spin resonance) experiment
    
    properties (Constant, Hidden)
        EXP_NAME = 'ESR'
    end
    
    properties
        frequency           % double. in MHz
        amplitude           % double. of MW
        mirrorSweepAround   % logical
        
        mode                % string. 'cw' or 'pulsed'
    end
    
    methods
        
        function obj = ExpESR
            obj@Experiment(ExpESR.EXP_NAME);
        end
        
        function LoadSequence(obj)
           % old Load experiment 
        end
    end
    
end

