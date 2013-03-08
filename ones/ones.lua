while true do
    num = io.read("*number")
    if not num then break end

    local ones = 0
    for i = 0, num do 
        local temp = i
        while temp > 0 do
            if temp % 10 == 1 then ones = ones + 1 end
            temp = math.floor(temp / 10)
        end
    end
    
    print(ones)
end
