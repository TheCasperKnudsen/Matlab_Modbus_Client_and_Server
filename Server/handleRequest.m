function [UpdatedDataInput,UpdatedDataBaseHolding,UpdatedCoils] = handleRequest(ModBusTCP,DataBaseInput,DataBaseHolding,DataBaseCoils)
    UpdatedDataBaseHolding = DataBaseHolding; % In case Holding is not written
    UpdatedDataInput = DataBaseInput; % Input cannot be written
    UpdatedCoils = DataBaseCoils;     % Coils cannot be written  
    
    % Read MBAP
    TransID     = fread16Bit(ModBusTCP);
    ProtID      = fread16Bit(ModBusTCP);
    Length      = fread16Bit(ModBusTCP);
    UnitID      = fread8Bit(ModBusTCP);
    
    %Handle PDU
    FunCod  = fread8Bit(ModBusTCP);
    switch FunCod
        
        case 4 % Read Multiple Input Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters       = fread16Bit(ModBusTCP);
            Message = HandleFunctionCode4(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,DataBaseInput);
            
            fwrite(ModBusTCP, Message,'uint8');
            return
            
        case 3 % Read Multiple Holding Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters       = fread16Bit(ModBusTCP);
            Message = HandleFunctionCode3(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,DataBaseHolding);
            
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBaseHolding = DataBaseHolding; 
            return
            
        case 6 % Write Single Register
            RegisterAdress          = fread16Bit(ModBusTCP);
            RecivedData             = fread16Bit(ModBusTCP);
            [Message,DataBaseHolding] = HandleFunctionCode6(TransID,ProtID,Length,UnitID,FunCod,RegisterAdress,RecivedData,DataBaseHolding);
            
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBaseHolding = DataBaseHolding; 
            return
            
        case 16 % Write Multiple Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters       = fread16Bit(ModBusTCP);
            ByteCount               = fread8Bit(ModBusTCP);
            RecivedData = uint16(zeros(NumberOfRegisters,1));
            for index = 1:1:NumberOfRegisters
                %Recives Little endian data
                RecivedData(index) = fread16Bit(ModBusTCP);
            end
            
            [Message,DataBaseHolding] = HandleFunctionCode16(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,RecivedData,DataBaseHolding);
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBaseHolding = DataBaseHolding; 
            return
            
        otherwise % Not tested
            disp('Recived Bad Request');
            return
    end
end

