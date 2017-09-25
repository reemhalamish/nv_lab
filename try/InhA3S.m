classdef InhA3S < InhA3 & EventSender
    %INHA3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = InhA3S
            obj@InhA3();
            obj@EventSender('abcd');
        end
    end
    
end

