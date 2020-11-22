function PrepedData = Prep16BitData(Data)
%PREP16BITDATA Converts to Little Indian and casts to a 2x1 8 bit array
    %Convert to Little Indian
    PrepedData = swapbytes(Data);
    %Cast to 8 bit array
    PrepedData = typecast(PrepedData,'uint8')';
end

