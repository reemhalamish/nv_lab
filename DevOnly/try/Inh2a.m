classdef Inh2a < Inh1 & EventListener
    %INH2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Inh2a
            obj@Inh1();
            obj@EventListener('inh2a');
        end
    end
    
end

