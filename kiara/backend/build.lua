local pt = require "pt"
local build = {}

local function bool_to_number(value)
    return value and 1 or 0
  end

local function recursiveAllocator(d, depth)
    local current_size = d[depth]
    local array = {size=current_size}

    if depth == #d then
        return array
    end

    for i = 1, current_size do
        array[i] = recursiveAllocator(d, depth + 1)
    end

    return array
end

local function ndarray(d)
    -- source: https://gist.github.com/alexholehouse/6190193
    return recursiveAllocator(d, 1)
end

function build.run(code, mem, stack, top)
    local pc = 1

    while true do
        --[[
            io.write("--> ")
            for i = 1, top do io.write(stack[i], " ") end
            io.write("\n", code[pc], "\n")
        -- ]]
        if code[pc] == "ret" then
            return top
        elseif code[pc] == "call" then
            pc = pc + 1
            local code = code[pc]
            top = build.run(code, mem, stack, top)
        elseif code[pc] == "print" then
            if type(stack[top]) == "table" then
                local arr = stack[top]
                
                io.write("[")
                for i=1, arr.size do
                    if arr[i] == nil then
                        io.write("nil")
                    else
                        io.write(arr[i])
                    end
                    if i ~= arr.size then
                        io.write(", ")
                    end
                end
                io.write("]")
                

            else
                print(stack[top])
            end
            

            top = top - 1
        elseif code[pc] == "push" then
            pc = pc + 1
            top = top + 1
            stack[top] = code[pc]
        elseif code[pc] == "not" then
            stack[top] = bool_to_number(stack[top]  == 0)
        elseif code[pc] == "minus" then
            stack[top] = -stack[top]
        elseif code[pc] == "add" then
            stack[top - 1] = stack[top - 1] + stack[top]
            top = top - 1
        elseif code[pc] == "sub" then
            stack[top - 1] = stack[top - 1] - stack[top]
            top = top - 1
        elseif code[pc] == "mul" then
            stack[top - 1] = stack[top - 1] * stack[top]
            top = top - 1
        elseif code[pc] == "div" then
            stack[top - 1] = stack[top - 1] / stack[top]
            top = top - 1
        elseif code[pc] == "rem" then
            stack[top - 1] = stack[top - 1] % stack[top]
            top = top - 1
        elseif code[pc] == "pow" then
            stack[top - 1] = stack[top - 1] ^ stack[top]
            top = top - 1
        elseif code[pc] == "sml" then
            stack[top - 1] = bool_to_number(stack[top - 1] < stack[top])
            top = top - 1
        elseif code[pc] == "big" then
            stack[top - 1] = bool_to_number(stack[top - 1] > stack[top])
            top = top - 1
        elseif code[pc] == "big_eq" then
            stack[top - 1] = bool_to_number(stack[top - 1] >= stack[top])
            top = top - 1
        elseif code[pc] == "sml_eql" then
            stack[top - 1] = bool_to_number(stack[top - 1] <= stack[top])
            top = top - 1
        elseif code[pc] == "equal" then
            stack[top - 1] = bool_to_number(stack[top - 1] == stack[top])
            top = top - 1
        elseif code[pc] == "not_equal" then
            stack[top - 1] = bool_to_number(stack[top - 1] ~= stack[top])
            top = top - 1
        elseif code[pc] == "load" then
            pc = pc + 1
            local id = code[pc]
            top = top + 1
            stack[top] = mem[id]
        elseif code[pc] == "store" then
            pc = pc + 1
            local id = code[pc]
            mem[id] = stack[top]
            top = top - 1
        elseif code[pc] == "newarray" then
            local size = stack[top]
            stack[top] = {size=size}
        elseif code[pc] == "multnewarray" then
            -- print("\n")
            -- print("--------------------")

            local lvls = stack[top]
            -- print(lvls)
            -- print(pt.pt(stack))
            
            local nd = {}
            for i = 1, lvls do
                nd[i] = stack[i]
            end
            
            local multarr = ndarray(nd)
            -- print(pt.pt(multarr))
            stack[top] = multarr
            -- print("--------------------")
            -- print("\n")
        elseif code[pc] == "getarray" then
            local array = stack[top - 1]
            local index = stack[top]
            
            -- print(">> " .. pt.pt(array))
            if index > array.size then
                error("index out of range. max array size: " .. array.size)
            end

            stack[top - 1] = array[index]
            top = top - 1
        elseif code[pc] == "setarray" then
            local array = stack[top - 2]
            local index = stack[top - 1]
            local value = stack[top]
            
            print(">> " .. array.size)

            if index > array.size then
                error("index out of range. max array size: " .. array.size)
            end

            array[index] = value
            top = top - 3
        elseif code[pc] == "jmp" then
            local index = stack[top]
            pc = code[pc + 1]
        elseif code[pc] == "jmpZ" then
            pc = pc + 1
            if stack[top] == 0 or stack[top] == nil then
                pc = code[pc]
            end
        else error("unknow instruction: " .. code[pc])
        end
        pc = pc + 1
    end
end

return build
