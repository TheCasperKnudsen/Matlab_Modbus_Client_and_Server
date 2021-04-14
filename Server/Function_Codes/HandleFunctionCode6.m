function [Message,DataBaseHolding] = HandleFunctionCode6(TransID,ProtID,Length,UnitID,FunCod,RegisterAdress,RecivedData,DataBaseHolding)
%HANDLEFUNCTIONCODE6 Handels formating, exceptions and saveing of data for 'Write Singel Register''
    %Check if registers are available
    if RecivedData >= 65535
        ErrorCode = uint8(134); %Error cod: 0x86
        PDU = [ErrorCode; uint8(3)]; % Exception code:  ILLEGAL DATA VALUE
        
        if IsExceeded(StartingAdress,0,DataBaseHolding)
            %Build ERROR PDU
            ErrorCode = uint8(134); %Error cod: 0x86
            PDU = [ErrorCode; uint8(2)]; % Exception code: ILLEGAL DATA ADDRESS
        end
        
        %Build MBAP
        PDULength = ByteSizeInt(ErrorCode) + 1;
        Length = int16(ByteSizeInt(UnitID) + PDULength);
        MBAP = [TransID; ProtID; Length; UnitID];
        MBAP = PrepMBAP(MBAP);  %Arrange to little Endian
        disp('Write Single Register - ERROR');       
    else
        %Save Data
        DataBaseHolding(RegisterAdress) = RecivedData;

        % Build PDU
        PrepedRegisterAdress      =  typecast(RegisterAdress,'uint8')';
        PrepedRecivedData         =  Prep16BitData(RecivedData);
        PDU  = [FunCod; PrepedRegisterAdress; PrepedRecivedData];
        
        %Build MBAP
        PDULength = ByteSizeInt(FunCod) + ByteSizeInt(RegisterAdress) + ByteSizeInt(RecivedData);
        Length = int16(ByteSizeInt(UnitID) + PDULength);
        MBAP = [TransID; ProtID; Length; UnitID];
        MBAP = PrepMBAP(MBAP);  %Arrange to little Endian
        
        disp('Wrote Single Register');
    end

    %Send Message
    Message = [MBAP; PDU];

end