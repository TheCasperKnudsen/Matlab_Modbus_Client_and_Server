function Message = HandleFunctionCode4(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,DataBaseInput)
%HANDLEFUNCTIONCODE4 Handels formating and exceptions for 'Read Multiple
%Input Registers'.

    %Check if registers are available
    if IsExceeded(StartingAdress,NumberOfRegisters,DataBaseInput)
        ErrorCode = uint8(132); %Error cod: 0x84
        PDU = [ErrorCode; uint8(3)]; % Exception code: ILLEGAL DATA VALUE
        
        if IsExceeded(StartingAdress,0,DataBaseHolding)
            %Build ERROR PDU
            ErrorCode = uint8(132); %Error cod: 0x84
            PDU = [ErrorCode; uint8(2)]; % Exception code: ILLEGAL DATA ADDRESS
        end

        %Build MBAP
        PDULength = ByteSizeInt(ErrorCode) + 1;
        Length = int16(ByteSizeInt(UnitID) + PDULength);
        MBAP = [TransID; ProtID; Length; UnitID];
        MBAP = PrepMBAP(MBAP);  %Arrange to little Endian

        disp('Read Multiple Input Registers - ERROR');                

    else
        %Build PDU
        NumberOfDataBytes = uint8(NumberOfRegisters*2);
        PDU = [FunCod; NumberOfDataBytes];
        for Index = 0:1:NumberOfRegisters-1
            Data = DataBaseInput(StartingAdress+Index);
            Data = Prep16BitData(Data);
            PDU = [PDU; Data];
        end

        %Build MBAP
        PDULength = ByteSizeInt(FunCod) + ByteSizeInt(NumberOfDataBytes) + NumberOfDataBytes;
        Length = int16(ByteSizeInt(UnitID) + PDULength);
        MBAP = [TransID; ProtID; Length; UnitID];
        MBAP = PrepMBAP(MBAP);  %Arrange to little Endian

        disp('Read Multiple Input Registers');    
    end

    %Send Message
    Message = [MBAP; PDU];
end
