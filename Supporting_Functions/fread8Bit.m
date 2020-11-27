function Data = fread8Bit(IPTCP)
%FREAD8BIT
    Data = uint8(fread(IPTCP, 1, 'uint8'));
end
