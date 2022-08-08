local build = {}

local function bool_to_number(value)
    return value and 1 or 0
  end

function build.run(code, mem, stack)
    local pc = 1
    local top = 0

    while true do
        --[[
            io.write("--> ")
            for i = 1, top do io.write(stack[i], " ") end
            io.write("\n", code[pc], "\n")
        -- ]]
        if code[pc] == "ret" then
            return
        elseif code[pc] == "print" then
            print(stack[top])

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
        elseif code[pc] == "sml_eq" then
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
        else error("unknow instruction")
        end
        pc = pc + 1
    end
end

return build
