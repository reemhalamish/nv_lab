classdef Inh1 < EventListener
    %INH1 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Inh1()
            obj@EventListener('inh1');
        end
    end
    
end

