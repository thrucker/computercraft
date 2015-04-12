local argv = {...}

if not argv[1] then
    print("Usage:\nperihelp [side/device]");
    return
end

local p = peripheral.wrap(argv[1])

if not p then
    print("Cannot wrap peripheral!")
    return
end

if not p.getAdvancedMethodsData then
    print("Peripheral Does not support\ngetAdvancedMethodsData!")
    return
end

local data = p.getAdvancedMethodsData()
local lines = {}

if not data then
    print("No Data!")
    return
end


local function writeln(str)
    lines[#lines+1] = str
end
writeln("")
for fk, fn in pairs(data) do
    local fname = ":o" .. fk .. "("

    for ak, a in ipairs(fn.args) do
        fname = fname .. a.name .. ","
    end

    if #fn.args > 0 then fname = fname:sub(1,#fname - 1) end
    fname = fname .. ")"
    writeln(fname)
    writeln("")
    writeln(" "..fn.description)
    writeln("")
    writeln(":l Returns")
    for rk, r in pairs(fn.returnTypes) do
        writeln(":l "..rk.." "..r)
    end

    for ak, a in ipairs(fn.args) do
        writeln(" :lArgument "..tostring(ak).." ("..a.name..")::")
        writeln("  :gType:: :w"..a.type)
        writeln("  "..a.description)
    end

    writeln(":q---------------")
end

---------------
--SysX MAN engine start

local aln = 1

local function rLine(lid)
    if lines[lid] then
        local ti = 0
        while ti < #(lines[lid]) do
            ti = ti + 1
            if lines[lid]:sub(ti,ti) == ":" then
                local op = lines[lid]:sub(ti+1,ti+1)
                ti = ti + 1
                if op == ":" then
                    write(":");
                elseif op == "w" then
                    term.setTextColor(colors.white)
                elseif op == "o" then
                    term.setTextColor(colors.orange)
                elseif op == "m" then
                    term.setTextColor(colors.magenta)
                elseif op == "l" then
                    term.setTextColor(colors.lime)
                elseif op == "p" then
                    term.setTextColor(colors.pink)
                elseif op == "a" then
                    term.setTextColor(colors.gray)
                elseif op == "c" then
                    term.setTextColor(colors.cyan)
                elseif op == "q" then
                    term.setTextColor(colors.purple)
                elseif op == "n" then
                    term.setTextColor(colors.brown)
                elseif op == "g" then
                    term.setTextColor(colors.green)
                elseif op == "r" then
                    term.setTextColor(colors.red)
                elseif op == "b" then
                    term.setTextColor(colors.black)

                elseif op == "W" then
                    term.setBackgroundColor(colors.white)
                elseif op == "O" then
                    term.setBackgroundColor(colors.orange)
                elseif op == "M" then
                    term.setBackgroundColor(colors.magenta)
                elseif op == "L" then
                    term.setBackgroundColor(colors.lime)
                elseif op == "P" then
                    term.setBackgroundColor(colors.pink)
                elseif op == "A" then
                    term.setBackgroundColor(colors.gray)
                elseif op == "C" then
                    term.setBackgroundColor(colors.cyan)
                elseif op == "Q" then
                    term.setBackgroundColor(colors.purple)
                elseif op == "W" then
                    term.setBackgroundColor(colors.brown)
                elseif op == "G" then
                    term.setBackgroundColor(colors.green)
                elseif op == "R" then
                    term.setBackgroundColor(colors.red)
                elseif op == "B" then
                    term.setBackgroundColor(colors.black)
                else
                    write("!NIMPL!")
                end

            else
                write(lines[lid]:sub(ti,ti))
            end
        end
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end

local sx,sy = term.getSize()

local function render()
    term.clear()
    term.setCursorPos(1,1)
    local px,py = term.getCursorPos()
    while py < sy do
        rLine(py+aln-1)
        if px<sy then write("\n") end
        px,py = term.getCursorPos()
    end
end
render()

while true do
    local e = {os.pullEvent()}
    if e[1] == "key" then
        if e[2] == 16 then
            os.startTimer(0.2)
            os.pullEvent()
            write("\n")
            return
        elseif e[2] == 200 then
            aln = aln - 1
        elseif e[2] == 208 then
            aln = aln + 1
        elseif e[2] == 203 then
            aln = aln - sy
        elseif e[2] == 205 then
            aln = aln + sy
        end
    elseif e[1] == "mouse_scroll" then
        aln = aln + e[2]
    end
    if aln >= #lines-sy+1 then aln = #lines - sy + 1 end
    if aln < 1 then aln = 1 end
    render()
end