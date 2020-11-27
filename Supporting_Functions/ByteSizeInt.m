function bytes = ByteSizeInt(variable)
%BYTESIZEINT Returns size of intenger value in bytes
    string = class(variable);
    bitsString = extractAfter(string,"int");
    if isempty(bitsString)
        error('Input must be int or uint')
        return
    end
    bits = str2num(bitsString);
    bytes = bits/8;
end