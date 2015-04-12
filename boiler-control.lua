-- constants

local burnTimePerFuel = 1600 -- charcoal
local step = 0.05 -- heat factor per tick
local maxHeat = 500
local targetTemp = 250
local maxFuelInBoiler = 4 * 64
local heatInefficiency = 0.8
local pressureInefficiency = 4
local fuelPerCycle = 8
local boilerSide = 'left'
local sourceInvSide = 'right'
local overflowInvSide = 'top'

local oppositeDirection = {
  north = 'south',
  south = 'north',
  east = 'west',
  west = 'east',
  up = 'down',
  down = 'up'
}

local sideToDirection = {
  north = {
    front = 'north',
    right = 'east',
    back = 'south',
    left = 'west',
    top = 'up',
    bottom = 'down'
  },
  east = {
    front = 'east',
    right = 'south',
    back = 'west',
    left = 'north',
    top = 'up',
    bottom = 'down'
  },
  south = {
    front = 'south',
    right = 'west',
    back = 'north',
    left = 'east',
    top = 'up',
    bottom = 'down'
  },
  west = {
    front = 'west',
    right = 'north',
    back = 'east',
    left = 'south',
    top = 'up',
    bottom = 'down'
  }
}

--

local args = {...}

if #args < 2 then
  print("Usage: boiler-control <turtle direction> <boiler blocks> [<target temp>]")
  print("  turtle direction = [north|east|south|west]")
  print("  boiler blocks = count of boiler blocks")
  print("  target temp = target temperature in degrees Celsius")
  return
end

local turtleDir = args[1]
local boilerToTurtleDirection = oppositeDirection[sideToDirection[turtleDir][boilerSide]]
local overflowToTurtleDirection = oppositeDirection[sideToDirection[turtleDir][overflowInvSide]]
local sourceToTurtleDirection = oppositeDirection[sideToDirection[turtleDir][sourceInvSide]]

local boilerBlocks = tonumber(args[2])

if boilerBlocks == nil or boilerBlocks < 1 then
  print("boiler blocks has to be a positive integer")
  return
end

if #args > 2 then
  targetTempOverwrite = tonumber(args[3])

  if targetTempOverwrite ~= nil then
    targetTemp = targetTempOverwrite
  end
end

local refreshTimerId

local boiler = peripheral.wrap(boilerSide)
local sourceInv = peripheral.wrap(sourceInvSide)
local overflowInv = peripheral.wrap(overflowInvSide)

if not boiler then
  print("no boiler found at "..boilerSide.." side")
  return
end

if not sourceInv then
  print("no source inventory found at "..sourceInvSide.." side")
  return
end

if not overflowInv then
  print("no overflow inventory found at "..overflowInvSide.." side")
  return
end

-- derived constants

local x = 1 - 3 * (step / boilerBlocks) / maxHeat
local y = 4 * step / boilerBlocks
local a = boilerBlocks * heatInefficiency
local b = boilerBlocks * (fuelPerCycle * (1 - boilerBlocks * 0.0125) + pressureInefficiency * maxHeat / 1000)

--

function getNumberOfTicks(currentTemp, targetTemp)
  if currentTemp >= targetTemp then
    return 0
  end

  return math.ceil(math.log((targetTemp * (1 - x) - y) / (currentTemp * (1 - x) - y)) / math.log(x))
end

function getBurnTime(startLevel, ticks)
  return a * (startLevel + 1 / maxHeat * ((startLevel * maxHeat - y / (1 - x)) * ((1 - math.pow(x, ticks)) / (1 - math.pow(x, 16)) - 1) + y * (ticks / 16 - 1) / (1 - x))) + b * ticks / 16
end

function getFuelInBoiler()
  local stacks = boiler.getAllStacks()
  local fuel = 0

  for k, stack in pairs(stacks) do
    fuel = fuel + stack.qty
  end

  if boiler.isBurning() then
    fuel = fuel + 1
  end

  return fuel
end

function refuelBoiler(amount)
  local currentStack = 1

  while amount > 0  and currentStack <= 16 do
    local count = turtle.getItemCount(currentStack)
    local amountToPull = math.min(amount, count)

    boiler.pullItem(boilerToTurtleDirection, currentStack, amountToPull)

    amount = amount - amountToPull
    currentStack = currentStack + 1
  end
end

function cleanupInventory()
  -- remove everything but charcoal
  for slot = 1, 16 do
    local itemDetail = turtle.getItemDetail(slot)

    if itemDetail and (itemDetail.name ~= "minecraft:coal" or itemDetail.damage ~= 1) then
      overflowInv.pullItem(overflowToTurtleDirection, slot)
    end
  end

  -- remove excess charcoal
  for slot = 13, 16 do
    if turtle.getItemCount(slot) > 0 then
      overflowInv.pullItem(overflowToTurtleDirection, slot)
    end
  end
end

function getFuelStock()
  local count = 0

  for slot = 1, 16 do
    local itemDetail = turtle.getItemDetail(slot)

    if itemDetail and itemDetail.name == 'minecraft:coal' and itemDetail.damage == 1 then
      count = count + itemDetail.count
    end
  end

  return count
end

function stockupFuel()
  cleanupInventory()

  local fuelCount = getFuelStock()
  local fuelMissing = 12 * 64 - fuelCount

  while fuelMissing > 0 do
    sourceInv.condenseItems()
    local fuelTransferred = sourceInv.pushItem(sourceToTurtleDirection, 1, fuelMissing)
    fuelMissing = fuelMissing - fuelTransferred
  end
end

function tick()
  local currentTemp = boiler.getTemperature()
  local steamProduced = targetTemp / maxHeat * boilerBlocks * 10
  local target = targetTemp
  local burnTicksNeeded = getNumberOfTicks(currentTemp, target)
  local burnTimeNeeded = burnTicksNeeded / 20
  local burnTimeFuel = getBurnTime(currentTemp / maxHeat, burnTicksNeeded)
  local fuelNeeded = math.ceil(burnTimeFuel / burnTimePerFuel)
  local fuelInBoiler = getFuelInBoiler()

  term.clear()
  term.setCursorPos(1, 1)
  write("target temp: ")
  term.setTextColor(colors.green)
  write(">"..targetTemp.."<\n")
  term.setTextColor(colors.white)
  print("steam produced at "..targetTemp..": "..steamProduced)
  print("current temp: "..currentTemp)
  print("burn time needed to reach "..target..": "..burnTimeNeeded)
  print("fuel needed to reach "..target..": "..fuelNeeded)
  print("fuel in boiler: "..fuelInBoiler)
  print("\nup/down: +/- 1 degree")
  print("shift up/down: +/- 10 degrees")
  print("q: quit")
  print("\nTODO: take out fuel if temp is too high")

  if fuelInBoiler < fuelNeeded then
    local fuelDelta = fuelNeeded - fuelInBoiler
    local fuelSpaceInBoiler = maxFuelInBoiler - fuelInBoiler
    local refuelAmount = math.min(fuelDelta, fuelSpaceInBoiler)

    refuelBoiler(refuelAmount)
    stockupFuel()
  end

  refreshTimerId = os.startTimer(0.5)
end

function monitorModifierKeys()
  local shiftTimer

  while true do
    local e, param1 = os.pullEvent()

    if e == 'key' then
      local keyCode = param1

      if keyCode == 42 or keyCode == 54 then
        os.queueEvent('shift', true)
        shiftTimer = os.startTimer(0.4)
      end
    elseif e == 'timer' then
      if param1 == shiftTimer then
        os.queueEvent('shift', false)
      end
    end
  end
end

function main()
  local shift = false

  stockupFuel()
  tick()

  while true do
    local event, param1 = os.pullEvent()

    if event == 'key' then
      local keyCode = param1
      local delta = 1
      local change = false
      if shift then
        delta = 10
      end

      if keyCode == keys.up then -- up
        targetTemp = math.min(maxHeat, targetTemp + delta)
        change = true
      elseif keyCode == keys.down then -- down
        targetTemp = math.max(20, targetTemp - delta)
        change = true
      elseif keyCode == keys.q then
        os.startTimer(0.2)
        os.pullEvent()
        return
      end

      if change then
        os.cancelTimer(refreshTimerId)
        tick()
      end
    elseif event == 'timer' then
      if param1 == refreshTimerId then
        tick()
      end
    elseif event == 'shift' then
      shift = param1
    end
  end
end

pcall(function()
  parallel.waitForAny(main, monitorModifierKeys)
end)
