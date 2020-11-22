DataBaseHolding = uint16([111,222,333,444])
DataBaseInput = uint16([11,22,33,44])

while 1
    ModBusTCP = openConnection('192.168.87.134', 502)
    while ~ModBusTCP.BytesAvailable
        %wait for the response to be in the buffer
    end
   [DataBaseInput,DataBaseHolding] = handleRequest(ModBusTCP,DataBaseInput,DataBaseHolding)
   fclose(ModBusTCP);
   break;
end

function ModBusTCP = openConnection(ipaddress, port)
    ModBusTCP=tcpip(ipaddress, port,'NetworkRole', 'Server'); %Create the tcpip obeject
    set(ModBusTCP, 'InputBufferSize', 512); %assign the buffer
    ModBusTCP.ByteOrder='bigEndian'; %specify the order in which bytes are transmitted
    try 
        if ~strcmp(ModBusTCP.Status,'open') 
            fopen(ModBusTCP);
            disp(['TCP/IP connection opened with host:', ipaddress]);
        end
    catch fault % display error if the channel is not opened.
        if ~strcmp(ModBusTCP.Status,'open') % check if the channel is really closed
            disp(fault);
            disp(['Error: Can''t establish TCP/IP connection with: ',ipaddress,':',num2str(port)] ); 
            disp('You can check the following:');
            disp('- If the cable is plugged in correctly ');
            disp('- Whether the Codesys controller is turned on.');
            disp('- Your firewall settings');
        end
    end
end

function [DataBaseInput,DataBaseHolding] = handleRequest(ModBusTCP,DataBaseInput,DataBaseHolding)
    % Read MBAP
    TransID    = fread16Bit(ModBusTCP);
    ProtID      = fread16Bit(ModBusTCP);
    Length     = fread16Bit(ModBusTCP);
    UnitID      = fread8Bit(ModBusTCP);
    
    %Handle PDU
    FunCod  = fread8Bit(ModBusTCP);
    switch FunCod
        
        case 4 % Read Multiple Input Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters   = fread16Bit(ModBusTCP);
            Message = HandleFunctionCode3(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,DataBaseInput);
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataInput = DataBaseInput; 
            return
            
        case 3 % Read Multiple Holding Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters   = fread16Bit(ModBusTCP);
            Message = HandleFunctionCode3(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,DataBaseHolding);
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBase = DataBaseHolding; 
            return
            
        case 6
            
            
            disp('Wrote Single Holding Register');
            
            return
        case 16
            
            disp('Wrote Multiple Holding Registers');            
            return 
        otherwise % Not tested
            FunCodResponce = int16(-2);
            Length = int16(ModbusHeaderLength + ByteSizeInt(FunCodResponce));
            
            MBAP = [transID; ProtID; Length; UnitID];
            PDU = [FunCod];
            Message = [MBAP,PDU];
            
            fwrite(ModBusTCP, Message,'int8');
            UpdatedDataBase = DataBaseHolding;
            
            disp('Recived bad Request');
            return
    end
end
