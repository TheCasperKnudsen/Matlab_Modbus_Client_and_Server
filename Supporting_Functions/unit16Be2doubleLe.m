function [DoubleLittleEndian] = unit16Be2doubleLe(BigEndian16bitArray)
    % Flip to get the Little Endian byte order:
    BigEndian16bitArray = typecast(flip(BigEndian16bitArray),'double');
    
    % Flip to get the original Data order:
    DoubleLittleEndian = flip(BigEndian16bitArray);
end

