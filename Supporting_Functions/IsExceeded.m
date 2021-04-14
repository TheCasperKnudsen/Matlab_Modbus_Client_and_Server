function bool = IsExceeded(StartingIndex,Number,Array)
    Size = length(Array);
    bool = StartingIndex + Number  -1 > Size;
    return
end
