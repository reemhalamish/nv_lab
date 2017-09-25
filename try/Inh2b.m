classdef Inh2b < Inh1 & EventListener
    %INH2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Inh2b
            obj@Inh1();
            obj@EventListener('inh2b');
        end
    end
    
end