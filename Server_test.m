    
ModBusTCP = openConnection(ipaddress, port)
while 1
    while ~ModBusTCP.BytesAvailable
        %wait for the response to be in the buffer
    end
   DataBase = handleRequest(ModBusTCP,DataBase)
end

function ModBusTCP = openConnection(ipaddress, port)
    ModBusTCP=tcpip(ipaddress, port); %Create the tcpip obeject
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

function UpdatedDataBase = handleRequest(ModBusTCP,DataBaseHolding)
    % Read MBAP
    TransID = fread(ModBusTCP,1, 'int16');
    ProtID =  fread(ModBusTCP,1, 'int16');
    Lenght =  fread(ModBusTCP,1, 'int16');
    UnitID = fread(ModBusTCP,1, 'int8');
    
    %Handle PDU
    FunCod = fread(ModBusTCP,1, 'int8');
    switch FunCod
        case 4
            disp('Read Input Registers'); 
            
            UpdatedDataBase = DataBase;
            return
        case 3
            %Read command
            StartingAdress = fread(ModBusTCP,1, 'int16');
            NumberOfRegisters = fread(ModBusTCP,1, 'int16');
            
            %Check if registers are available
            if IsExceeded(StartingAdress,NumberOfRegisters,DataBaseHolding)
                %Build PDU
                PDU = uint8(131); %Error cod: 0x83
                PDU = [PDU uint8(2)]; % Exception code: ILLEGAL DATA ADDRESS
                
                %Build MBAP
                Length = int16(ModbusHeaderLenght + 16);
                MBAP = [transID; ProtID; Lenght; UnitID];
                disp('Read Multiple Holding Registers - ERROR');                
            
            else
                %Build MBAP
                Length = int16(ModbusHeaderLenght + NumberOfRegisters*2);
                MBAP = [transID; ProtID; Lenght; UnitID];

                %Build PDU
                PDU = FunCod;
                for Index = 0:1:NumberOfRegisters-1
                    PDU = [PDU int16(DataBaseHolding(StartingAdress+Index))]
                end
                disp('Read Multiple Holding Registers');    
            end
            
            %Send Message
            Message = [MBAP PDU];
            fwrite(ModBusTCP, Message,'int8');
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
            Length = int16(ModbusHeaderLenght + ByteSizeInt(FunCodResponce));
            
            MBAP = [transID; ProtID; Lenght; UnitID];
            PDU = [FunCod];
            Message = [MBAP,PDU];
            
            fwrite(ModBusTCP, Message,'int8');
            UpdatedDataBase = DataBaseHolding;
            
            disp('Recived bad Request');
            return
    end
end


% ========== Supporting functions ========== 
function bytes = ByteSizeInt(variable)
    string = class(variable);
    bitsString = extractAfter(string,"int");
    if isempty(bitsString)
        error('Input must be int or uint')
        return
    end
    bits = str2num(bitsString);
    bytes = bits/8;
end

function bool =IsExceeded(StartingIndex,Number,Array)
    Size = length(Array);
    bool = StartingIndex + Number <= Size;
    return
end

% ========== Constants ========== 
function ans = ModbusHeaderLenght
    % As the header is [transID; ProtID; Lenght; UnitID]
    % The defined length is 7*8bit
    ans = 7;
end