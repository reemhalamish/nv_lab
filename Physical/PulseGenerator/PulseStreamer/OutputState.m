classdef OutputState < handle
    % OutputState class combines three values (8 digital, 1 analog, 1 analog) which define the output on all ports 
    properties
        digi@uint8 % binary encoded state of the digital outputs
        ao0@int16   % output value of the first analog ao0 channel (range: +/-1V -0x7fff to 0x7fff)
        ao1@int16   % output value of the first analog ao1 channel (range: +/-1V -0x7fff to 0x7fff) 
    end
    
    methods
        function obj = OutputState(digi, ao0, ao1)
            assert((0 <= digi) && (digi < 256))
            assert((-1 <= ao0) && (ao0 <= 1))
            assert((-1 <= ao1) && (ao1 <= 1))
            obj.digi = uint8(digi);
            obj.ao0 = int16(ao0*32767);
            obj.ao1 = int16(ao1*32767);
        end
        function string = getJsonString(obj)
            % create the JSON-RCP string for an PuleMessage object (ticks = 0)
            string = strcat('[0,', num2str(obj.digi), ',', num2str(obj.ao0), ',', num2str(obj.ao1), ']'); 
        end
    end    
    
end

