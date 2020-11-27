function Data = fread16Bit(IPTCP)
%FREAD16BIT
    Data = uint16(fread(IPTCP, 1, 'uint16'));
end
