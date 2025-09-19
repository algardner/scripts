print("Starting Program")
local component = require("component")
local sides = require("sides")

-- CONSTANTS

-- number of elements to create per loop (max 64)
local stack = 64

-- Supply Barrel sides
local source      = sides.west
local fusionLeft  = sides.top
local xfer        = sides.bottom

-- Fusion Barrel sides
local fusionRight = sides.north
local output      = sides.south
local result      = sides.bottom



-- get list of transposers
local supplyTrans = {}
local procTran

-- go through each transposer and assign it to its position
for address, name in component.list("transposer", true) do
    -- get transposer proxy
    local t = component.proxy(address)
    
    -- check stack and assign to Supply Transposer list
    local s = t.getStackInSlot(source, 2)
    
    -- damage property is the atomic number of the element 
    if s then
        -- get name of element
        local elmentDesc = string.sub(s.label,9) .. " - (" .. s.damage .. ")"
        supplyTrans[s.damage] = {tran = t, name = elmentDesc, label = s.label, atomicNum = s.damage}
    else
        -- no stack means it is the processing transposer
        procTran = t        
    end    
end

-- debug
print("Found elment supply:")
for k,v in pairs(supplyTrans) do
    print(k, v.name) 
end

-- find largest element that is <= atomicNum
function getLargestElementUpTo (atomicNum)
    local largest = 1
    
    for k,v in pairs(supplyTrans) do
        if (v.atomicNum <= atomicNum) and (v.atomicNum > largest) then
            largest = v.atomicNum
        end
    end
    
    return largest
end

-- wait for fusion to finish / starting element to load
function waitForFullResult ()
    while procTran.getSlotStackSize(result, 2) < stack do
        os.sleep(0.5)
    end    
end

-- get the largest element that can be used, and put into result barrel
function getStartingElement (atomicNum)
    -- find the element number
    local startElem = getLargestElementUpTo(atomicNum)
    
    -- move element stack to result
    supplyTrans[startElem].tran.transferItem(source, xfer, stack, 2, 1)
    waitForFullResult()
    
    return startElem
    
end

-- fuse result stack with largest possible element
function fuseResultWithLargest (atomicNum)
    -- get current element in result
    local currentNum = procTran.getStackInSlot(result, 2).damage
    
    -- find the largest element up to the remaining num
    local fuseNum = getLargestElementUpTo(atomicNum - currentNum)
    
    print("    Current element " .. currentNum .. " of " .. atomicNum .. " still needs " .. (atomicNum - currentNum) .. ". Fusing with element: " .. supplyTrans[fuseNum].name .. "...")
    
    -- move element from supply to fusion chamber
    supplyTrans[fuseNum].tran.transferItem(source, fusionLeft, stack, 2, 1)
    
    -- move element from result to fusion chamber
    procTran.transferItem(result, fusionRight, stack, 2, 1)
    
    -- wait for fusion to complete
    waitForFullResult()
    
    -- return atomicNum of new element
    return procTran.getStackInSlot(result, 2).damage
    
end

function createElementInOutput(atomicNum, count)
    for i=1,count do
        
        print("  Creating Element stack " .. i .. " of " .. count .. " with Atomic Num " .. atomicNum)
        
        -- set up starting element
        local currentNum = getStartingElement(atomicNum)
        
        print("    Starting with element: " .. supplyTrans[currentNum].name)
        
        -- loop until desired element reached
        while (currentNum < atomicNum) do
            currentNum = fuseResultWithLargest(atomicNum)
        end 
        
        -- move result to output
        procTran.transferItem(result, output, stack, 2, 1)
        
        -- wait for result & output to empty
        while (procTran.getSlotStackSize(result, 2) > 0) or (procTran.getSlotStackSize(output, 2) > 0) do
            os.sleep(0.5)
        end
        
        print("  Element stack complete.")
    
    end
end

-- Emerald components
-- V2 Cr2 (Be3 Al2 (Si O3)6)2
 
-- 36 Oxygen O-8
-- 12 Silicon Si-14
-- 6 Beryllium Be-4 
-- 4 Aluminium Al-13
-- 2 Chromium Cr-24
-- 2 Vanadium V-23
 
local O  =  8
local Si = 14
local Be =  4
local Al = 13
local Cr = 24
local V  = 23
local C  = 6
 
while true do
    
    print("1. Make Emerald Stack")
    print("2. Make Diamond Block")
    local userInput = io.read()
    
    if userInput == "1" then
    
        print("Starting Emerald Production")
 
        -- V2 Cr2 (Be3 Al2 (Si O3)6)2
 
        -- (Be3 Al2 (Si O3)6)2
        for Be3Al2=1,2 do
 
            -- (Si O3)6
            for SiO3=1,6 do
                print("Generating 1 Silicon")
                createElementInOutput(Si, 1)
 
                print("Generating 3 Oxygen")
                createElementInOutput(O, 3)
            end
 
            print("Generating 3 Beryllium")
            createElementInOutput(Be, 3)
 
            print("Generating 2 Aluminium")
            createElementInOutput(Al, 2)
        end
 
        print("Generating 3 Chromium")
        createElementInOutput(Cr, 2)
 
        print("Generating 2 Vanadium")
        createElementInOutput(V, 2)
 
        print("Emerald Components Complete")
        
    elseif userInput == "2" then
        print("Generating 108 Carbon stacks")
        createElementInOutput(C, 108)
    else
        print("Unknown Option")
    end
        
end

