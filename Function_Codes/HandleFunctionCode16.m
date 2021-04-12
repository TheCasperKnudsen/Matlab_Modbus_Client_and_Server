function [Message,DataBaseHolding] = HandleFunctionCode16(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,RecivedData,DataBaseHolding)
%HANDLEFUNCTIONCODE10 Handels formating, exceptions and saveing of data for 'Write Multiple Registers''.

    %Check if registers are available
    if IsExceeded(StartingAdress,NumberOfRegisters,DataBaseHolding)
        ErrorCode = uint8(143); %Error cod: 0x8F
        PDU = [ErrorCode; uint8(3)]; % Exception code:  ILLEGAL DATA VALUE
        
        if IsExceeded(StartingAdress,0,DataBaseHolding)
            %Build ERROR PDU
            ErrorCode = uint8(143); %Error cod: 0x8F
            PDU = [ErrorCode; uint8(2)]; % Exception code: ILLEGAL DATA ADDRESS
        end
        
        %Build MBAP
        PDULength = ByteSizeInt(ErrorCode) + 1;
        Length = int16(ByteSizeInt(UnitID) + PDULength);
        MBAP = [TransID; ProtID; Length; UnitID];
        MBAP = PrepMBAP(MBAP);  %Arrange to little Endian
        disp('Write Multiple Registers - ERROR');       
    else
        %Save Data
        for index = 1:1:NumberOfRegisters
            DataBaseHolding(StartingAdress+index-1) = RecivedData(index);
        end
        
        % Build PDU
        PrepedStartingAdress        =  typecast(StartingAdress,'uint8')';
        PrepedNumberOfRegisters     =  Prep16BitData(NumberOfRegisters);
        PDU  = [FunCod; PrepedStartingAdress; PrepedNumberOfRegisters];
        
        %Build MBAP
        PDULength = ByteSizeInt(FunCod) + ByteSizeInt(StartingAdress) + ByteSizeInt(NumberOfRegisters);
        Length = int16(ByteSizeInt(UnitID) + PDULength);
        MBAP = [TransID; ProtID; Length; UnitID];
        MBAP = PrepMBAP(MBAP);  %Arrange to little Endian
        
        disp('Wrote Multiple Registers');
    end

    %Send Message
    Message = [MBAP; PDU];            
end

function bool = IsExceeded(StartingIndex,Number,Array)
    Size = length(Array);
    bool = StartingIndex + Number -1 > Size;
    return
end