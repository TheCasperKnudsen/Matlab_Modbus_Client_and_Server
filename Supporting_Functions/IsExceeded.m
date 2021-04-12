function bool = IsExceeded(StartingIndex,Number,Array)
    Size = length(Array);
    bool = StartingIndex + Number  >= Size;
    return
end
