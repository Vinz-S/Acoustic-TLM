##Scripts to adjust simulation time for simulation length and mesh size
function sTOhmins(secs)
    h = Int((secs-secs%3600)/3600)
    min = Int((secs%3600-secs%3600%60)/60)
    s = round(Int, secs%60)
    return string(h, ":", min, ":", s)
end

function hminsTOs(h,min,s)
    return h*3600 + min*60 + s
end

secs = hminsTOs(6,12,49)

secs = secs*(0.95/0.8)/1.5
sTOhmins(secs)

println("Adjusted tetrahedral time: ", sTOhmins(secs))

ratio = secs/hminsTOs(10,16,61)
4.5/8.3