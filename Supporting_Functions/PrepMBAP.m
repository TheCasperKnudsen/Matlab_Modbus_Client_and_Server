function PrepedMBAP = PrepMBAP(MBAP)
%PREPMBAP Converts the Modbus Application Header to Little Indian and casts to a 7x1 8 bit array
    TransID    = Prep16BitData(MBAP(1));
    ProtID      = Prep16BitData(MBAP(2));
    Length     = Prep16BitData(MBAP(3));
    UnitID      = MBAP(4);
    PrepedMBAP = [TransID; ProtID; Length; UnitID];
end
