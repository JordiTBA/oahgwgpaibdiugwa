
local EmbeddedModules = {}

-- Module: farm/ui.lua
EmbeddedModules["farm/ui.lua"] = function()
    local m = {}
    local Window
    local Core
    local Player
    local Garden
    local Plant

    -- Store ALL toggle references for config sync after reconnect
    m.ToggleReferences = {}
    m.NumberBoxReferences = {}
    m.SelectBoxReferences = {}

    function m:init(_window, _core, _player, _garden, _plant)
        Window = _window
        Core = _core
        Player = _player
        Garden = _garden
        Plant = _plant

        self:CreateFarmTab()
    end

    function m:CreateFarmTab()
        local tab = Window:AddTab({
            Name = "Farm",
            Icon = "🌾",
        })

        self:AddPlantingSection(tab)
        self:AddWateringSection(tab)
        self:AddSprinklerSection(tab)
        self:AddHarvestingSection(tab)
        self:AddMovingSection(tab)
        self:AddShovelSection(tab)
        self:AddReclaimPlantSection(tab)
    end

    function m:AddPlantingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Planting",
            Icon = "🌱",
            Expanded = false,
        })

        local seedsToPlantSelectBox = accordion:AddSelectBox({
            Name = "Select seeds to auto plant",
            Options = {"Loading..."},
            Placeholder = "Select seeds...",
            MultiSelect = true,
            Flag = "SeedsToPlant",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local seeds = Plant:GetPlantRegistry()
                    local formattedSeeds = {}
                    for _, seedData in pairs(seeds) do
                        table.insert(formattedSeeds, {
                            text = string.format("[%s] %s Type: %s", seedData.rarity, seedData.plant, seedData.types),
                            value = seedData.plant
                        })
                    end
                    optionsData.updateOptions(formattedSeeds)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("SeedsToPlant")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local seeds = Plant:GetPlantRegistry()
                local formattedSeeds = {}
                for _, seedData in pairs(seeds) do
                    table.insert(formattedSeeds, {
                        text = string.format("[%s] %s Type: %s", seedData.rarity, seedData.plant, seedData.types),
                        value = seedData.plant
                    })
                end
                updateOptions(formattedSeeds)
            end
        })

        -- Store reference and restore saved value
        if seedsToPlantSelectBox then
            m.SelectBoxReferences["SeedsToPlant"] = seedsToPlantSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("SeedsToPlant")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    seedsToPlantSelectBox:Set(savedValue)
                end
            end)()
        end

        local seedsToPlantCountNumberBox = accordion:AddNumberBox({
            Name = "Set the number of seeds to plant",
            Placeholder = "Enter number of seeds...",
            Flag = "SeedsToPlantCount",
            Min = 0,
            Max = 800,
            Default = 1,
            Increment = 1,
        })


        m.NumberBoxReferences["SeedsToPlantCount"] = seedsToPlantCountNumberBox

        accordion:AddSelectBox({
            Name = "Position planting seeds",
            Flag = "PlantingPosition",
            Options = {"Random", "Center Right", "Center Left", "Inside Center Right", "Inside Center Left", "Front Right", "Front Left", "Back Right", "Back Left"},
            Default = "Random",
            MultiSelect = false,
            Placeholder = "Select position...",
        })

        accordion:AddButton({Text = "Planting Once", Callback = function()
            local selectedSeeds = Window:GetConfigValue("SeedsToPlant") or {}
            local seedsToPlantCount = Window:GetConfigValue("SeedsToPlantCount") or 1

            print("Selected Seeds:", selectedSeeds)
            print("Number of Seeds to Plant:", seedsToPlantCount)

            Plant:PlantSeed(selectedSeeds[1], seedsToPlantCount)
        end})

        local togglePlantseeds = accordion:AddToggle({
            Name = "Enable Auto Planting",
            Flag = "AutoPlantSeeds",
            Default = false,
            Callback = function(state)
               if state then
                    print("Auto Planting Enabled:", state)
                    Plant:StartAutoPlanting()
                else
                    print("Auto Planting Disabled:", state)
                end
            end,
        })


        m.ToggleReferences["AutoPlantSeeds"] = togglePlantseeds
    end

    function m:AddWateringSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Watering",
            Icon = "💧",
            Expanded = false,
        })

        accordion:AddSelectBox({
            Name = "Watering Position",
            Flag = "WateringPosition",
            Options = {"Growing Plants", "Center Right", "Center Left", "Inside Center Right", "Inside Center Left", "Front Right", "Front Left", "Back Right", "Back Left"},
            Default = "Front Right",
            MultiSelect = false,
            Placeholder = "Select position...",
        })

        local wateringEachNumberBox = accordion:AddNumberBox({
            Name = "Set the Each Watering",
            Placeholder = "Enter number of waterings...",
            Flag = "WateringEach",
            Min = 1,
            Max = 100,
            Default = 5,
            Increment = 1,
        })

        m.NumberBoxReferences["WateringEach"] = wateringEachNumberBox

        local wateringDelayNumberBox = accordion:AddNumberBox({
            Name = "Set the number of waterings delay",
            Placeholder = "Enter watering delay...",
            Flag = "WateringDelay",
            Min = 1,
            Max = 800,
            Default = 10,
            Increment = 1,
        })

        m.NumberBoxReferences["WateringDelay"] = wateringDelayNumberBox

        accordion:AddSeparator()

        local toggleStopWatering = accordion:AddToggle({
            Name = "Stop Auto Watering If No Growing Plants",
            Flag = "StopWateringIfNoGrowingPlants",
            Default = true,
        })

        m.ToggleReferences["StopWateringIfNoGrowingPlants"] = toggleStopWatering

        local toggleWateringplants = accordion:AddToggle({
            Name = "Enable Auto Watering",
            Flag = "AutoWateringPlants",
            Default = false,
            Callback = function(state)
               if state then
                    Plant:AutoWateringPlants()
                end
            end,
        })

        m.ToggleReferences["AutoWateringPlants"] = toggleWateringplants
    end

    function m:AddSprinklerSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Sprinkler",
            Icon = "💦",
            Expanded = false,
        })

        local sprinklersSelectBox = accordion:AddSelectBox({
            Name = "Select sprinklers",
            Options = {"Loading..."},
            Placeholder = "Select sprinklers...",
            MultiSelect = true,
            Flag = "SprinklersToPlace",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local sprinklers = Plant:GetSprinklersRegistry()
                    local formattedSprinklers = {}
                    for _, sprinklerData in pairs(sprinklers) do
                        table.insert(formattedSprinklers, {
                            text = string.format("%s (%s)", sprinklerData.name, Core:FormatNumber(sprinklerData.quantity)),
                            value = sprinklerData.name
                        })
                    end
                    optionsData.updateOptions(formattedSprinklers)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("SprinklersToPlace")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local sprinklers = Plant:GetSprinklersRegistry()
                local formattedSprinklers = {}
                for _, sprinklerData in pairs(sprinklers) do
                    table.insert(formattedSprinklers, {
                        text = string.format("%s (%s)", sprinklerData.name, Core:FormatNumber(sprinklerData.quantity)),
                        value = sprinklerData.name
                    })
                end
                updateOptions(formattedSprinklers)
            end
        })

        -- Store reference and restore saved value
        if sprinklersSelectBox then
            m.SelectBoxReferences["SprinklersToPlace"] = sprinklersSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("SprinklersToPlace")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    sprinklersSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSelectBox({
            Name = "Position placing sprinklers",
            Flag = "SprinklerPlacingPosition",
            Options = {"Random", "Center Right", "Center Left", "Inside Center Right", "Inside Center Left", "Front Right", "Front Left", "Back Right", "Back Left"},
            Default = "Random",
            MultiSelect = false,
            Placeholder = "Select position...",
        })

        accordion:AddSeparator()

        accordion:AddButton({Text = "Place Sprinklers Once", Callback = function()
            local selectedSprinklers = Window:GetConfigValue("SprinklersToPlace") or {}
            local sprinklerPlacingPosition = Window:GetConfigValue("SprinklerPlacingPosition") or "Random"

            for _, sprinklerName in pairs(selectedSprinklers) do
                Plant:PlaceSprinkler(sprinklerName, sprinklerPlacingPosition)
            end
        end})

        local togglePlacesprinklers = accordion:AddToggle({
            Name = "Enable Auto Place Sprinklers",
            Flag = "AutoPlaceSprinklers",
            Default = false,
        })

        m.ToggleReferences["AutoPlaceSprinklers"] = togglePlacesprinklers

        accordion:AddSeparator()

        accordion:AddButton({
            Text = "Remove Selected Sprinklers",
            Variant = "warning",
            Callback = function()
                Plant:RemoveSprinklers()
            end
        })
    end

    function m:AddHarvestingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Harvest",
            Icon = "🌿",
            Expanded = false,
        })

        local plantsToHarvestSelectBox = accordion:AddSelectBox({
            Name = "Select plants to auto harvest",
            Flag = "PlantsToHarvest",
            MultiSelect = true,
            Placeholder = "Select plants...",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local plants = Plant:GetListGardenPlants()
                    local formattedPlants = {}
                    for _, dataPlant in pairs(plants) do
                        table.insert(formattedPlants, {
                            text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                            value = dataPlant.plant,
                        })
                    end
                    optionsData.updateOptions(formattedPlants)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("PlantsToHarvest")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local plants = Plant:GetListGardenPlants()
                local formattedPlants = {}
                for _, dataPlant in pairs(plants) do
                    table.insert(formattedPlants, {
                        text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                        value = dataPlant.plant,
                    })
                end

                updateOptions(formattedPlants)
            end
        })

        -- Store reference and restore saved value
        if plantsToHarvestSelectBox then
            m.SelectBoxReferences["PlantsToHarvest"] = plantsToHarvestSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("PlantsToHarvest")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    plantsToHarvestSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSeparator()

        accordion:AddSelectBox({
            Name = "Weight Mode",
            Flag = "HarvestWeightMode",
            Options = {"None", "Above", "Below"},
        })

        local harvestWeightValueNumberBox = accordion:AddNumberBox({
            Name = "Weight Value (KG)",
            Placeholder = "Enter weight value...",
            Flag = "HarvestWeightValue",
            Min = 0.01,
            Max = 100000.00,
            Default = 1.00,
            Decimals = 2,
            Increment = 1.00,
        })

        m.NumberBoxReferences["HarvestWeightValue"] = harvestWeightValueNumberBox

        accordion:AddSeparator()

        accordion:AddSelectBox({
            Name = "Variant Mode",
            Flag = "HarvestVariantMode",
            Options = {"None", "Include", "Exclude"},
        })

        local harvestVariantSelectBox = accordion:AddSelectBox({
            Name = "Variant Name",
            Options = {"Loading..."},
            Placeholder = "Select variant...",
            MultiSelect = true,
            Flag = "HarvestVariantValue",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.5) -- Wait for Plant:Init() to complete
                    local variants = Plant:GetAllVariants()
                    local formattedVariants = {}

                    for _, variantName in pairs(variants) do
                        table.insert(formattedVariants, {
                            text = variantName,
                            value = variantName,
                        })
                    end

                    optionsData.updateOptions(formattedVariants)

                    -- Restore saved value after options are loaded
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("HarvestVariantValue")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local variants = Plant:GetAllVariants()
                local formattedVariants = {}

                for _, variantName in pairs(variants) do
                    table.insert(formattedVariants, {
                        text = variantName,
                        value = variantName,
                    })
                end

                updateOptions(formattedVariants)
            end
        })

        -- Store reference and try immediate restoration
        if harvestVariantSelectBox then
            m.SelectBoxReferences["HarvestVariantValue"] = harvestVariantSelectBox
            coroutine.wrap(function()
                task.wait(0.8) -- Wait for options to be loaded first
                local savedValue = Window:GetConfigValue("HarvestVariantValue")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    harvestVariantSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSeparator()

        accordion:AddSelectBox({
            Name = "Mutation Mode",
            Flag = "HarvestMutationsMode",
            Options = {"None", "Include", "Exclude"},
        })

        local harvestMutationSelectBox = accordion:AddSelectBox({
            Name = "Mutation Name",
            Options = {"Loading..."},
            Placeholder = "Select mutation...",
            MultiSelect = true,
            Flag = "HarvestMutationsValue",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.5) -- Wait for Plant:Init() to complete
                    local mutations = Plant:GetAllMutations()
                    local formattedMutations = {}

                    for name, data in pairs(mutations) do
                        table.insert(formattedMutations, {
                            text = string.format("%s x%d", name, data.ValueMulti or 1),
                            value = name,
                        })
                    end

                    optionsData.updateOptions(formattedMutations)

                    -- Restore saved value after options are loaded
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("HarvestMutationsValue")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local mutations = Plant:GetAllMutations()
                local formattedMutations = {}

                for name, data in pairs(mutations) do
                    table.insert(formattedMutations, {
                        text = string.format("%s x%d", name, data.ValueMulti or 1),
                        value = name,
                    })
                end

                updateOptions(formattedMutations)
            end
        })

        -- Store reference and try immediate restoration
        if harvestMutationSelectBox then
            m.SelectBoxReferences["HarvestMutationsValue"] = harvestMutationSelectBox
            coroutine.wrap(function()
                task.wait(0.8) -- Wait for options to be loaded first
                local savedValue = Window:GetConfigValue("HarvestMutationsValue")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    harvestMutationSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSeparator()

        local harvestDelayNumberBox = accordion:AddNumberBox({
            Name = "Auto Harvest Delay (seconds)",
            Placeholder = "Enter auto harvest delay...",
            Flag = "HarvestDelay",
            Min = 0.01,
            Max = 600.00,
            Default = 0.05,
            Decimals = 2,
            Increment = 0.01,
        })

        m.NumberBoxReferences["HarvestDelay"] = harvestDelayNumberBox

        local toggleHarvestplants = accordion:AddToggle({
            Name = "Auto Harvest Plants 🌿",
            Default = false,
            Flag = "AutoHarvestPlants",
            Callback = function(Value)
                if Value then
                    Plant:StartAutoHarvesting()
                end
            end,
        })

        m.ToggleReferences["AutoHarvestPlants"] = toggleHarvestplants

        local toggleSellfruits = accordion:AddToggle({
            Name = "Auto Sell Fruits If Inventory Full 🛒",
            Default = false,
            Flag = "AutoSellFruits",
        })

        m.ToggleReferences["AutoSellFruits"] = toggleSellfruits
    end

    function m:AddMovingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Move Plants",
            Icon = "🚜",
            Expanded = false,
        })

        local plantToMoveSelectBox = accordion:AddSelectBox({
            Name = "Select plant to move",
            Flag = "PlantToMove",
            MultiSelect = false,
            Placeholder = "Select plant...",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local plants = Plant:GetListGardenPlants()
                    local formattedPlants = {}
                    for _, dataPlant in pairs(plants) do
                        table.insert(formattedPlants, {
                            text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                            value = dataPlant.plant,
                        })
                    end
                    optionsData.updateOptions(formattedPlants)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("PlantToMove")
                    if savedValue and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local plants = Plant:GetListGardenPlants()
                local formattedPlants = {}
                for _, dataPlant in pairs(plants) do
                    table.insert(formattedPlants, {
                        text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                        value = dataPlant.plant,
                    })
                end

                updateOptions(formattedPlants)
            end
        })

        -- Store reference and restore saved value
        if plantToMoveSelectBox then
            m.SelectBoxReferences["PlantToMove"] = plantToMoveSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("PlantToMove")
                if savedValue and savedValue ~= "" then
                    plantToMoveSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSelectBox({
            Name = "Select destination",
            Flag = "MoveDestination",
            Options = {"Center Right", "Center Left", "Inside Center Right", "Inside Center Left", "Front Right", "Front Left", "Back Right", "Back Left"},
            Default = "Front Right",
            MultiSelect = false,
            Placeholder = "Select destination...",
        })

        accordion:AddButton({Text = "Move Plant", Callback = function()
            Plant:MovePlant()
        end})
    end

    function m:AddShovelSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Shovel",
            Icon = "🪓",
            Expanded = false,
        })

        local plantToShovelSelectBox = accordion:AddSelectBox({
            Name = "Select plant to shovel",
            Flag = "PlantToShovel",
            Placeholder = "Select plant...",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local plants = Plant:GetListGardenPlants()
                    local formattedPlants = {}
                    for _, dataPlant in pairs(plants) do
                        table.insert(formattedPlants, {
                            text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                            value = dataPlant.plant,
                        })
                    end
                    optionsData.updateOptions(formattedPlants)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("PlantToShovel")
                    if savedValue and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local plants = Plant:GetListGardenPlants()
                local formattedPlants = {}
                for _, dataPlant in pairs(plants) do
                    table.insert(formattedPlants, {
                        text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                        value = dataPlant.plant,
                    })
                end

                updateOptions(formattedPlants)
            end
        })

        -- Store reference and restore saved value
        if plantToShovelSelectBox then
            m.SelectBoxReferences["PlantToShovel"] = plantToShovelSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("PlantToShovel")
                if savedValue and savedValue ~= "" then
                    plantToShovelSelectBox:Set(savedValue)
                end
            end)()
        end

        local plantsToShovelCountNumberBox = accordion:AddNumberBox({
            Name = "Set the number of plants to shovel",
            Placeholder = "Enter number of plants...",
            Flag = "PlantsToShovelCount",
            Min = 0,
            Max = 800,
            Default = 1,
            Increment = 1,
        })

        m.NumberBoxReferences["PlantsToShovelCount"] = plantsToShovelCountNumberBox

        accordion:AddButton({Text = "Shovel Selected Plant", Callback = function()
            Plant:ShovelSelectedPlants()
        end})

        accordion:AddSeparator()

        local fruitsToShovelSelectBox = accordion:AddSelectBox({
            Name = "Select fruits to auto shovel",
            Flag = "FruitsToShovel",
            MultiSelect = true,
            Placeholder = "Select fruits...",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local plants = Plant:GetListGardenPlants()
                    local formattedPlants = {}
                    for _, dataPlant in pairs(plants) do
                        table.insert(formattedPlants, {
                            text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                            value = dataPlant.plant,
                        })
                    end
                    optionsData.updateOptions(formattedPlants)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("FruitsToShovel")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local plants = Plant:GetListGardenPlants()
                local formattedPlants = {}
                for _, dataPlant in pairs(plants) do
                    table.insert(formattedPlants, {
                        text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                        value = dataPlant.plant,
                    })
                end

                updateOptions(formattedPlants)
            end
        })

        -- Store reference and restore saved value
        if fruitsToShovelSelectBox then
            m.SelectBoxReferences["FruitsToShovel"] = fruitsToShovelSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("FruitsToShovel")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    fruitsToShovelSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSeparator()

        accordion:AddSelectBox({
            Name = "Fruits Weight Mode",
            Flag = "ShovelFruitsWeightMode",
            Options = {"None", "Above", "Below"},
        })

        local shovelFruitsWeightValueNumberBox = accordion:AddNumberBox({
            Name = "Fruits Weight Value (KG)",
            Placeholder = "Enter weight value...",
            Flag = "ShovelFruitsWeightValue",
            Min = 0.01,
            Max = 100000.00,
            Default = 1.00,
            Decimals = 2,
            Increment = 1.00,
        })

        m.NumberBoxReferences["ShovelFruitsWeightValue"] = shovelFruitsWeightValueNumberBox

        accordion:AddSeparator()

        accordion:AddSelectBox({
            Name = "Fruits Variant Mode",
            Flag = "ShovelFruitsVariantMode",
            Options = {"None", "Include", "Exclude"},
        })

        local shovelVariantSelectBox = accordion:AddSelectBox({
            Name = "Fruits Variant Name",
            Options = {"Loading..."},
            Placeholder = "Select variant...",
            MultiSelect = true,
            Flag = "ShovelFruitsVariantValue",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.5) -- Wait for Plant:Init() to complete
                    local variants = Plant:GetAllVariants()
                    local formattedVariants = {}

                    for _, variantName in pairs(variants) do
                        table.insert(formattedVariants, {
                            text = variantName,
                            value = variantName,
                        })
                    end

                    optionsData.updateOptions(formattedVariants)

                    -- Restore saved value after options are loaded
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("ShovelFruitsVariantValue")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local variants = Plant:GetAllVariants()
                local formattedVariants = {}

                for _, variantName in pairs(variants) do
                    table.insert(formattedVariants, {
                        text = variantName,
                        value = variantName,
                    })
                end

                updateOptions(formattedVariants)
            end
        })

        -- Store reference and try immediate restoration
        if shovelVariantSelectBox then
            m.SelectBoxReferences["ShovelFruitsVariantValue"] = shovelVariantSelectBox
            coroutine.wrap(function()
                task.wait(0.8) -- Wait for options to be loaded first
                local savedValue = Window:GetConfigValue("ShovelFruitsVariantValue")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    shovelVariantSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSeparator()

        accordion:AddSelectBox({
            Name = "Fruits Mutation Mode",
            Flag = "ShovelFruitsMutationsMode",
            Options = {"None", "Include", "Exclude"},
        })

        local shovelMutationSelectBox = accordion:AddSelectBox({
            Name = "Fruits Mutation Name",
            Options = {"Loading..."},
            Placeholder = "Select mutation...",
            MultiSelect = true,
            Flag = "ShovelFruitsMutationsValue",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.5) -- Wait for Plant:Init() to complete
                    local mutations = Plant:GetAllMutations()
                    local formattedMutations = {}

                    for name, data in pairs(mutations) do
                        table.insert(formattedMutations, {
                            text = string.format("%s x%d", name, data.ValueMulti or 1),
                            value = name,
                        })
                    end

                    optionsData.updateOptions(formattedMutations)

                    -- Restore saved value after options are loaded
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("ShovelFruitsMutationsValue")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local mutations = Plant:GetAllMutations()
                local formattedMutations = {}

                for name, data in pairs(mutations) do
                    table.insert(formattedMutations, {
                        text = string.format("%s x%d", name, data.ValueMulti or 1),
                        value = name,
                    })
                end

                updateOptions(formattedMutations)
            end
        })

        -- Store reference and try immediate restoration
        if shovelMutationSelectBox then
            m.SelectBoxReferences["ShovelFruitsMutationsValue"] = shovelMutationSelectBox
            coroutine.wrap(function()
                task.wait(0.8) -- Wait for options to be loaded first
                local savedValue = Window:GetConfigValue("ShovelFruitsMutationsValue")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    shovelMutationSelectBox:Set(savedValue)
                end
            end)()
        end

        accordion:AddSeparator()

        local shovelFruitsDelayNumberBox = accordion:AddNumberBox({
            Name = "Auto Shovel Fruits Delay (seconds)",
            Placeholder = "Enter auto harvest delay...",
            Flag = "ShovelFruitsDelay",
            Min = 0.01,
            Max = 600.00,
            Default = 0.05,
            Decimals = 2,
            Increment = 0.01,
        })

        m.NumberBoxReferences["ShovelFruitsDelay"] = shovelFruitsDelayNumberBox

        local toggleAutoShovelFruits = accordion:AddToggle({
            Name = "Auto Shovel Fruits",
            Default = false,
            Flag = "AutoShovelFruits"
        })

        m.ToggleReferences["AutoShovelFruits"] = toggleAutoShovelFruits
    end

    function m:AddReclaimPlantSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Reclaim Plant",
            Icon = "♻️",
            Expanded = false,
        })

        local plantToReclaimSelectBox = accordion:AddSelectBox({
            Name = "Select plant to reclaim",
            Flag = "PlantToReclaim",
            Placeholder = "Select plant...",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local plants = Plant:GetListGardenPlants()
                    local formattedPlants = {}
                    for _, dataPlant in pairs(plants) do
                        table.insert(formattedPlants, {
                            text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                            value = dataPlant.plant,
                        })
                    end
                    optionsData.updateOptions(formattedPlants)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("PlantToReclaim")
                    if savedValue and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local plants = Plant:GetListGardenPlants()
                local formattedPlants = {}
                for _, dataPlant in pairs(plants) do
                    table.insert(formattedPlants, {
                        text = string.format("[%s] %s (%s) Type: %s", dataPlant.rarity, dataPlant.plant, tostring(dataPlant.quantity), dataPlant.types),
                        value = dataPlant.plant,
                    })
                end

                updateOptions(formattedPlants)
            end
        })

        -- Store reference and restore saved value
        if plantToReclaimSelectBox then
            m.SelectBoxReferences["PlantToReclaim"] = plantToReclaimSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("PlantToReclaim")
                if savedValue and savedValue ~= "" then
                    plantToReclaimSelectBox:Set(savedValue)
                end
            end)()
        end

        local plantsToReclaimCountNumberBox = accordion:AddNumberBox({
            Name = "Set the number of plants to reclaim",
            Placeholder = "Enter number of plants...",
            Flag = "PlantsToReclaimCount",
            Min = 0,
            Max = 800,
            Default = 1,
            Increment = 1,
        })


        m.NumberBoxReferences["PlantsToReclaimCount"] = plantsToReclaimCountNumberBox

        accordion:AddButton({Text = "Reclaim Selected Plant", Callback = function()
            Plant:ReclaimSelectedPlants()
        end})
    end


    -- Function to refresh all toggle UI states from config
    function m:RefreshToggleStates()
        if not Window then
            warn("FarmUI:RefreshToggleStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, toggleAPI in pairs(self.ToggleReferences) do
            local success, err = pcall(function()
                if toggleAPI and toggleAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        toggleAPI:SetValue(configValue, false)
                        print(string.format("  ✓ [Farm] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Farm] %s - Toggle API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Farm] %s - Error: %s", flagName, tostring(err)))
            end
        end

        return refreshedCount
    end

    -- Function to refresh all numberbox UI states from config
    function m:RefreshNumberBoxStates()
        if not Window then
            warn("UI:RefreshNumberBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, numberBoxAPI in pairs(self.NumberBoxReferences) do
            local success, err = pcall(function()
                if numberBoxAPI and numberBoxAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        numberBoxAPI:SetValue(configValue)
                        print(string.format("  ✓ %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ %s - NumberBox API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("Refreshed %d numberboxes successfully", refreshedCount))
        return refreshedCount
    end

    -- Function to refresh all selectbox UI states from config
    function m:RefreshSelectBoxStates()
        if not Window then
            warn("FarmUI:RefreshSelectBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, selectBoxAPI in pairs(self.SelectBoxReferences) do
            local success, err = pcall(function()
                if selectBoxAPI and selectBoxAPI.Set then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        if type(configValue) == "table" and #configValue > 0 then
                            selectBoxAPI:Set(configValue)
                            print(string.format("  ✓ [Farm] %s = %d items", flagName, #configValue))
                            refreshedCount = refreshedCount + 1
                        elseif type(configValue) == "string" and configValue ~= "" then
                            selectBoxAPI:Set(configValue)
                            print(string.format("  ✓ [Farm] %s = %s", flagName, configValue))
                            refreshedCount = refreshedCount + 1
                        end
                    end
                else
                    warn(string.format("  ✗ [Farm] %s - SelectBox API missing Set method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Farm] %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("[Farm] Refreshed %d selectboxes successfully", refreshedCount))
        return refreshedCount
    end

    return m
end

-- Module: special/webhook.lua
EmbeddedModules["special/webhook.lua"] = function()
    local m = {}

    local Window
    local Core
    local Discord

    local WEBHOOK_USERNAME = "jordi_galer  Hub"
    local WEBHOOK_AVATAR = "https://i.ibb.co.com/5X81cGVH/pandorahub-removebg-preview.png"

    local PlayerName
    local LastHatchTime = 0
    local HatchCount = {}
    local HatchTotal = {}
    local InitialStockEgg = {}
    local DataService

    -- Helper function untuk mendapatkan waktu saat ini
    local function GetTime()
        -- Format: • Month Date | Hour:Minute AM/PM
        -- Contoh: • November 18 | 10:30 PM
        return "• " .. os.date("%B %d") .. " | " .. os.date("%I:%M %p")
    end

    function m:Init(_window, _core, _discord)
        Window = _window
        Core = _core
        Discord = _discord

        PlayerName = Core.LocalPlayer.Name or "Unknown"
        LastHatchTime = tick()
        DataService = require(Core.ReplicatedStorage.Modules.DataService)
    end

    function m:NightmareMutation(_petType, _remains)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""
        _remains = _remains or 0

        if url == "" then
            return
        end

        local pingContent = ""

        if _remains <= 0 then
            pingContent = pingId ~= "" and ("<@"..pingId..">") or ("@everyone")
        end

        local message = {
            username = WEBHOOK_USERNAME,      
            avatar_url = WEBHOOK_AVATAR,       
            content = pingContent, 
            embeds = {{
                title = "**jordi_galerHub**",
                type = 'rich',
                color = tonumber("0x8B0000"),
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = "**Nightmare Mutation : **",
                    value = "> Pet Type: ``"..(_petType or"N/A").."``"..
                           "\n> Remains Queue: ``"..(_remains or"N/A").."``",
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }
        Discord:SendMessage(url, message)
    end

    function m:Leveling(_petName, _petLevel, _remains)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""
        _remains = _remains or 0

        if url == "" then
            return
        end

        local pingContent = ""

        if _remains <= 0 then
            pingContent = pingId ~= "" and ("<@"..pingId..">") or ("@everyone")
        end

        local message = {
            username = WEBHOOK_USERNAME,       
            avatar_url = WEBHOOK_AVATAR,       
            content = pingContent, 
            embeds = {{
                title = "**jordi_galerHub**",
                type = 'rich',
                color = tonumber("0x8B0000"),
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = "**Pet has reached to level : " ..(_petLevel or"N/A").."**",
                    value = "> Pet Name: ``"..(_petName or"N/A").."``"..
                           "\n> Remains Queue: ``"..(_remains or"N/A").."``",
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }
        Discord:SendMessage(url, message)
    end

    function m:Bulking(_petName, _petWeight, _remains)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""
        _remains = _remains or 0

        if url == "" then
            return
        end

        local pingContent = ""

        if _remains <= 0 then
            pingContent = pingId ~= "" and ("<@"..pingId..">") or ("@everyone")
        end

        local message = {
            username = WEBHOOK_USERNAME,      
            avatar_url = WEBHOOK_AVATAR,       
            content = pingContent, 
            embeds = {{
                title = "**jordi_galerHub**",
                type = 'rich',
                color = tonumber("0x8B0000"),
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = "**Pet has reached to weight : " ..(tonumber(_petWeight) and string.format("%.2f", tonumber(_petWeight)) or "N/A").." KG**",
                    value = "> Pet Name: ``"..(_petName or"N/A").."``"..
                           "\n> Remains Queue: ``"..(_remains or"N/A").."``",
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }
        Discord:SendMessage(url, message)
    end

    return m
end

-- Module: shop/season_pass.lua
EmbeddedModules["shop/season_pass.lua"] = function()
    local m = {}

    local Window
    local Core

    local ShopData
    local DataService
    local CurrentSeason

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        DataService = require(Core.ReplicatedStorage.Modules.DataService)
        ShopData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassShopData)
        local seasonPassData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassData)
        CurrentSeason = seasonPassData.CurrentSeason or ""

        _core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuySeasonPasses")
        end, function()
            self:StartBuySeasonPassItems()
        end)
    end

    function m:GetItemRepository()
        return ShopData.ShopItems or {}
    end

    function m:GetStock(itemName)
        local shopData = DataService:GetData()
        local stock = 0
        if not shopData then
            return stock
        end

        stock = shopData.SeasonPass[CurrentSeason].Stocks[itemName] or 0

        if type(stock) ~= "number" then
            return stock.Stock or 0
        end

        return stock
    end

    function m:GetAvailableSeasonPassesItems()
        local availableItems = {}
        local items = self:GetItemRepository()

        for itemName, _ in pairs(items) do
            local stock = self:GetStock(itemName)
            availableItems[itemName] = stock
        end

        return availableItems
    end

    function m:StartBuySeasonPassItems()
        if not Window:GetConfigValue("AutoBuySeasonPasses") then
            return
        end

        local ignoreItems = Window:GetConfigValue("IgnoreSeasonPassItems") or {}

        for itemName, stock in pairs(self:GetAvailableSeasonPassesItems()) do
            if stock <= 0 or table.find(ignoreItems, itemName) then
                continue
            end

            for i=1, stock do
                Core.ReplicatedStorage.GameEvents.SeasonPass.BuySeasonPassStock:FireServer(itemName)
                task.wait(0.15)
            end
        end
    end

    return m
end

-- Module: event/new_year/shop.lua
EmbeddedModules["event/new_year/shop.lua"] = function()
    local m = {}

    local Window
    local Core

    local ShopData
    local DataService

    function m:Init(_core, _window)
        Core = _core
        Window = _window

        ShopData = require(Core.ReplicatedStorage.Data.EventShopData)
        DataService = require(Core.ReplicatedStorage.Modules.DataService)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuyNewYearShop")
        end, function()
            self:StartAutoBuyNewYearShop()
        end)
    end

    function m:GetItemRepository(merchant)
        return ShopData[merchant] or {}
    end

    function m:GetDetailItem(merchant, itemName)
        local items = self:GetItemRepository(merchant)
        return items[itemName] or nil
    end

    function m:GetStock(shopName, itemName)
        local shopData = DataService:GetData()
        local stock = 0
        if not shopData then
            return stock
        end

        stock = shopData.EventShopStock[shopName].Stocks[itemName] or 0

        if type(stock) ~= "number" then
            return stock.Stock or 0
        end

        return stock
    end

    function m:StartAutoBuyNewYearShop()
        if not Window:GetConfigValue("AutoBuyNewYearShop") then
            return
        end

        local MerchantName = "New Years Shop"
        local ignoreItemToBuy = Window:GetConfigValue("IgnoreNewYearShopItems") or {}
        local itemsToBuy = self:GetItemRepository(MerchantName)
        local purchaseMultiplyAmount = Window:GetConfigValue("PurchaseMultiplyAmount") or 1

        for itemName, _ in pairs(itemsToBuy) do
            if table.find(ignoreItemToBuy, itemName) then
                continue
            end

            local stock = self:GetStock(MerchantName, itemName)
            if stock <= 0 then
                continue
            end

            for i = 1, stock * purchaseMultiplyAmount do
                coroutine.wrap(function()
                    Core.ReplicatedStorage.GameEvents.BuyEventShopStock:FireServer(itemName, MerchantName)
                end)()
            end
        end
    end

    return m

end

-- Module: event/new_year/ui.lua
EmbeddedModules["event/new_year/ui.lua"] = function()
    local m = {}

    local Window
    local Core
    local Shop
    local Rarity

    m.ToggleReferences = {}
    m.SelectBoxReferences = {}

    function m:Init(_core, _window, _shop, _rarity)
        Core = _core
        Window = _window
        Shop = _shop
        Rarity = _rarity

        local tab = Window:AddTab({
            Name = "New Year Event",
            Icon = "🎉",
        })

        self:NewYearShopSection(tab)
        self:CalendarEventSection(tab)
    end

    function m:NewYearShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "New Year Shop",
            Icon = "🛒",
            Default = false,
        })

        local ignoreShopItemsSelectBox = accordion:AddSelectBox({
            Name = "Ignore New Year Shop Items",
            Options = {"Loading..."},
            MultiSelect = true,
            Flag = "IgnoreNewYearShopItems",
            Placeholder = "Select items to ignore...",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.5) -- Wait for data to be available
                    local itemNames = self:GetFormattedShopItems()
                    if #itemNames > 0 then
                        optionsData.updateOptions(itemNames)
                    end

                    -- Restore saved value
                    local savedValue = Window:GetConfigValue("IgnoreNewYearShopItems")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local itemNames = self:GetFormattedShopItems()
                if #itemNames > 0 then
                    updateOptions(itemNames)
                else
                    updateOptions({{text = "No items available", value = ""}})
                end
            end
        })

        if ignoreShopItemsSelectBox then
            m.SelectBoxReferences["IgnoreNewYearShopItems"] = ignoreShopItemsSelectBox
            coroutine.wrap(function()
                task.wait(0.8)
                local savedValue = Window:GetConfigValue("IgnoreNewYearShopItems")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    ignoreShopItemsSelectBox:Set(savedValue)
                end
            end)()
        end

        local toggleAutoBuy = accordion:AddToggle({
            Name = "Auto Buy New Year Shop Items",
            Default = false,
            Flag = "AutoBuyNewYearShop"
        })
        m.ToggleReferences["AutoBuyNewYearShop"] = toggleAutoBuy
    end

    function m:GetFormattedShopItems()
        local itemNames = {}

        local success, items = pcall(function()
            return Shop:GetItemRepository("New Years Shop")
        end)

        if not success or not items or type(items) ~= "table" then
            return itemNames
        end

        local sortedList = {}
        for itemName, data in pairs(items) do
            if type(data) == "table" then
                data._name = itemName
                table.insert(sortedList, data)
            end
        end

        if #sortedList == 0 then
            return itemNames
        end

        table.sort(sortedList, function(a, b)
            local rarityA = (Rarity and Rarity.RarityOrder and Rarity.RarityOrder[a.SeedRarity]) or 99
            local rarityB = (Rarity and Rarity.RarityOrder and Rarity.RarityOrder[b.SeedRarity]) or 99

            if rarityA == rarityB then
                local layoutA = a.LayoutOrder or 0
                local layoutB = b.LayoutOrder or 0
                if layoutA == layoutB then
                    return (a._name or "") < (b._name or "")
                else
                    return layoutA < layoutB
                end
            end

            return rarityA < rarityB
        end)

        for _, data in pairs(sortedList) do
            local rarity = data.SeedRarity or "Unknown"
            local name = data._name or "Unknown"
            local itemType = data.ItemType or "Item"
            table.insert(itemNames, {
                text = "[" .. rarity .. "] " .. name .. " (" .. itemType .. ")",
                value = name
            })
        end

        return itemNames
    end

    function m:CalendarEventSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Calendar Event",
            Icon = "📅",
            Default = false,
        })

        local toggleAutoClaimCalendar = accordion:AddToggle({
            Name = "Auto Claim Calendar Event Rewards",
            Default = false,
            Flag = "AutoClaimCalendarRewards"
        })
        m.ToggleReferences["AutoClaimCalendarRewards"] = toggleAutoClaimCalendar
    end

    function m:RefreshToggleStates()
        local refreshedCount = 0

        for flag, toggle in pairs(self.ToggleReferences) do
            local savedValue = Window:GetConfigValue(flag)
            if savedValue ~= nil then
                pcall(function()
                    toggle:Set(savedValue)
                    refreshedCount = refreshedCount + 1
                end)
            end
        end

        return refreshedCount
    end

    function m:RefreshSelectBoxStates()
        local refreshedCount = 0

        for flag, selectBox in pairs(self.SelectBoxReferences) do
            local savedValue = Window:GetConfigValue(flag)
            if savedValue ~= nil then
                pcall(function()
                    if type(savedValue) == "table" and #savedValue > 0 then
                        selectBox:Set(savedValue)
                        refreshedCount = refreshedCount + 1
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        selectBox:Set(savedValue)
                        refreshedCount = refreshedCount + 1
                    end
                end)
            end
        end

        return refreshedCount
    end

    return m

end


-- Module: misc/remove.lua
EmbeddedModules["misc/remove.lua"] = function()
    local m = {}

    local Window
    local Core
    local SpiderWebConnection

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        self:RemoveSystemNotifications()
    end

    -- Remove Spider Web FX (from spider pet skill)
    function m:RemoveSpiderWebFX()
        -- Remove all existing SpiderWebFX folders
        for _, child in pairs(Core.Workspace:GetChildren()) do
            if child.Name == "SpiderWebFX" then
                child:Destroy()
            end
        end
    end

    -- Start auto-removing spider web FX
    function m:StartAutoRemoveSpiderWebFX()
        -- Remove existing ones first
        self:RemoveSpiderWebFX()

        -- Setup connection to remove new ones
        if not SpiderWebConnection then
            SpiderWebConnection = Core.Workspace.ChildAdded:Connect(function(child)
                if child.Name == "SpiderWebFX" and Window:GetConfigValue("RemoveSpiderWebFX") then
                    task.wait(0.1) -- Small delay to ensure it's fully loaded
                    child:Destroy()
                end
            end)
        end
    end

    -- Stop auto-removing spider web FX
    function m:StopAutoRemoveSpiderWebFX()
        if SpiderWebConnection then
            SpiderWebConnection:Disconnect()
            SpiderWebConnection = nil
        end
    end

    function m:RemoveSystemNotifications()
        local isDisabled = Window:GetConfigValue("RemoveSystemNotifications") or false
        local notificationGui = Core.LocalPlayer.PlayerGui["Top_Notification"].Frame

        if notificationGui then
            notificationGui.Visible = not isDisabled
        else
            warn("Top_Notification GUI not found!")
        end
    end

    return m
end

-- Module: farm/plant.lua
EmbeddedModules["farm/plant.lua"] = function()
    local m = {}
    local Window
    local Core
    local Player
    local Garden
    local PlantsPhysical
    local ObjectsPhysical
    local Rarity
    local MutationHandler
    local VariantColors
    local AllMutations

    m.IsAutoFavUnFavFruitsRunning = false
    m.ThreadStartAutoFavUnFavFruits = nil

    function m:Init(_window, _core, _player, _garden, _rarity)
        Window = _window
        Core = _core
        Player = _player
        Garden = _garden
        Rarity = _rarity

        local myGarden = Garden:GetMyFarm()
        if not myGarden then
            warn("Failed to find player's garden")
            return
        end

        local important = myGarden:FindFirstChild("Important")
        PlantsPhysical = important:FindFirstChild("Plants_Physical")
        ObjectsPhysical = important:FindFirstChild("Objects_Physical")

        MutationHandler = require(Core.ReplicatedStorage.Modules.MutationHandler)
        VariantColors = require(Core.ReplicatedStorage.Data.VariantColors)

        AllMutations = MutationHandler:GetMutations()

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoPlantSeeds")
        end, function()
            self:StartAutoPlanting()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoWateringPlants")
        end, function()
            self:AutoWateringPlants()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoHarvestPlants")
        end, function()
            self:StartAutoHarvesting()
        end, 1)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoPlaceSprinklers")
        end, function()
            self:AutoPlaceSprinklers()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoShovelFruits")
        end, function()
            self:StartAutoShovelFruits()
        end, 1)
    end

    function m:GetAllMutations()
        return AllMutations or {}
    end

    function m:GetVariantColors(variantName)
        return VariantColors:GetColor3(variantName)
    end

    function m:GetAllVariants()
        local variants = {}
        for variantName, _ in pairs(VariantColors.Colors or {}) do
            table.insert(variants, variantName)
        end

        return variants
    end

    function m:GetPlantRegistry()
        local success, seedRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.SeedData)
        end)

        if not success then
            warn("Failed to get seed registry:", seedRegistry)
            return {}
        end

        if not seedRegistry then
            warn("SeedData is nil or not found")
            return {}
        end

       -- Convert SeedData to UI format {text = ..., value = ...}
        local formattedSeeds = {}
        for seedName, seedData in pairs(seedRegistry) do
            local plantTypes = self:FindPlantTypeByName(seedName)

            table.insert(formattedSeeds, {
                seed = seedData.SeedName or seedName,
                plant = seedName,
                rarity = seedData.SeedRarity or "Unknown",
                types = plantTypes and table.concat(plantTypes, ", ") or "Unknown",
            })
        end

        -- Sort seeds alphabetically (ascending order) - Safe for all executors
        if #formattedSeeds > 0 then
            table.sort(formattedSeeds, function(a, b)
                local rarityA = Rarity.RarityOrder[a.rarity] or 99
                local rarityB = Rarity.RarityOrder[b.rarity] or 99

                if rarityA == rarityB then
                    return a.plant < b.plant
                end

                return rarityA < rarityB
            end)
        end

        return formattedSeeds
    end

    function m:FindPlantRegistryByName(plantName)
        local plants = self:GetPlantRegistry()
        for _, plantData in pairs(plants) do
            if plantData.plant == plantName then
                return plantData
            end
        end

        return nil
    end

    function m:FindPlantRegistryByName(plantName)
        local plants = self:GetPlantRegistry()
        for _, plantData in pairs(plants) do
            if plantData.plant == plantName then
                return plantData
            end
        end

        return nil
    end

    function m:FindPlantTypeByName(plantName)
        local plantsData = require(Core.ReplicatedStorage.Modules.PlantTraitsData)
        local plantTraits = plantsData.Traits or {}
        local listPlantType = {}

        for plantType, plants in pairs(plantTraits) do
            for _, plant in ipairs(plants) do
                if plant == plantName then
                    table.insert(listPlantType, plantType)
                    break
                end
            end
        end

        return listPlantType
    end

    function m:GetListSeedsAtInventory()
        local seedList = {}
        for _, tool in pairs(Player:GetAllTools()) do
            local toolType = tool:GetAttribute("b")
            if toolType == "n" then
                local seedName = tool:GetAttribute("Seed") or ""
                local seedQty = tool:GetAttribute("Quantity") or 0
                local seedData = self:FindPlantRegistryByName(seedName)
                local plantTypes = self:FindPlantTypeByName(seedName)

                table.insert(seedList, {
                    seed = seedData and seedData.seed or "Unknown",
                    plant = seedData and seedData.plant or seedName,
                    quantity = seedQty,
                    rarity = seedData and seedData.rarity or "Unknown",
                    types = plantTypes and table.concat(plantTypes, ", ") or "Unknown",
                })
            end
        end

        -- Sort seeds by rarity and then alphabetically
        if #seedList > 0 then
            table.sort(seedList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.rarity] or 99
                local rarityB = Rarity.RarityOrder[b.rarity] or 99

                if rarityA == rarityB then
                    return a.plant < b.plant
                end

                return rarityA < rarityB
            end)
        end

        return seedList
    end

    function m:PlantSeed(_seedName, _numToPlant, _plantingPosition)
        if not _seedName or type(_seedName) ~= "string" then
            Window:ShowWarning("Auto Planting", "Invalid seed name")
            return false
        end

        if #PlantsPhysical:GetChildren() >= 800 then
            Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
            return false
        end

        local tool
        local toolQuantity = 0

        for _, t in next, Player:GetAllTools() do
            local toolType = t:GetAttribute("b")
            local toolSeed = t:GetAttribute("Seed")
            if toolType == "n" and toolSeed == _seedName then
                tool = t
                toolQuantity = t:GetAttribute("Quantity") or 0
                break
            end
        end

        if toolQuantity < _numToPlant then
            _numToPlant = toolQuantity
        end

        if not tool then
            Window:ShowWarning("Auto Planting", "No seed for: " .. _seedName)

            return false
        end

        local tasks = Player:GetTaskByTool(tool)
        if tasks and #tasks > 0 then
            task.wait(5)
            return false
        end

        local position = Garden:GetFarmRandomPosition()
        if _plantingPosition == "Front Right" then
            position = Garden:GetFarmFrontRightPosition()
        elseif _plantingPosition == "Front Left" then
            position = Garden:GetFarmFrontLeftPosition()
        elseif _plantingPosition == "Back Right" then
            position = Garden:GetFarmBackRightPosition()
        elseif _plantingPosition == "Back Left" then
            position = Garden:GetFarmBackLeftPosition()
        elseif _plantingPosition == "Inside Center Right" then
            position = Garden:GetFarmInsideCenterRightPosition()
        elseif _plantingPosition == "Inside Center Left" then
            position = Garden:GetFarmInsideCenterLeftPosition()
        elseif _plantingPosition == "Center Right" then
            position = Garden:GetFarmCenterRightPosition()
        elseif _plantingPosition == "Center Left" then
            position = Garden:GetFarmCenterLeftPosition()
        end
        if not position then
            Window:ShowWarning("Auto Planting", "Failed to get farm position for planting")
            return false
        end

        local plantTask = function(_numToPlant, _seedName, _position)
            for i = 1, _numToPlant do
                if #PlantsPhysical:GetChildren() >= 800 then
                    Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
                    break
                end            
                Core.ReplicatedStorage.GameEvents.Plant_RE:FireServer(_position, _seedName)
                -- Small delay between planting actions
                task.wait(0.15)
            end
        end

        Player:AddToQueue(
            tool,       -- tool
            3,          -- priority (medium)
            function()
                plantTask(_numToPlant, _seedName, position)
            end
        )
    end

    function m:FindPlants(plantName)
        if not plantName or type(plantName) ~= "string" then
            Window:ShowWarning("Planting", "Invalid plant name")
            return nil
        end

        if not PlantsPhysical then
            Window:ShowWarning("Planting", "PlantsPhysical not found")
            return nil
        end

        local foundPlants = {}
        for _, plant in pairs(PlantsPhysical:GetChildren()) do
            if plant.Name == plantName then
                table.insert(foundPlants, plant)
            end
        end

        return #foundPlants > 0 and foundPlants or nil
    end

    function m:StartAutoPlanting()
        local seedsToPlant = Window:GetConfigValue("SeedsToPlant") or {}
        local seedToPlantCount = Window:GetConfigValue("SeedsToPlantCount") or 1
        local plantingPosition = Window:GetConfigValue("PlantingPosition") or "Random"

        -- Cache plant count once at the beginning
        if #PlantsPhysical:GetChildren() >= 800 then
            Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
            task.wait(30) -- Much longer wait when farm is full
            return
        end

        local plantsNeeded = false

        for _, seedName in pairs(seedsToPlant) do
            if #PlantsPhysical:GetChildren() >= 800 then
                Window:ShowWarning("Auto Planting", "Farm is full, stopping auto planting.")
                break
            end
            local existingPlants = self:FindPlants(seedName) or {}
            local numExisting = #existingPlants
            local numToPlant = math.max(0, seedToPlantCount - numExisting)

            Window:ShowInfo("Auto Planting", "Planting " .. tostring(numToPlant) .. " of " .. seedName)
            if numToPlant > 0 then
                self:PlantSeed(seedName, numToPlant, plantingPosition)
                plantsNeeded = true
            end
        end

        if not plantsNeeded then
            task.wait(60) -- Much longer wait when nothing to do
        else
            task.wait(15) -- Moderate wait when work was done
        end
    end

    function m:AutoWateringPlants()
        local wateringCan
        local wateringDelay = Window:GetConfigValue("WateringDelay") or 10
        local wateringEach = Window:GetConfigValue("WateringEach") or 5
        local wateringPosition = Window:GetConfigValue("WateringPosition") or "Front Right"
        local stopIfNoGrowingPlants = Window:GetConfigValue("StopWateringIfNoGrowingPlants") or true
        local position = Garden:GetFarmRandomPosition()

        for _, Tool in next, Player:GetAllTools() do
            local toolType = Tool:GetAttribute("b")
            if toolType == "o" then
                wateringCan = Tool
                break
            end
        end

        if not wateringCan then
            return
        end

        local growingPlants = self:GetAllGrowingPlants()
        if #growingPlants < 1 and stopIfNoGrowingPlants then
            return
        end

        local tasks = Player:GetTaskByTool(wateringCan)
        if tasks and #tasks > 0 then
            task.wait(10)
            return
        end

        if wateringPosition == "Growing Plants" then
            position = growingPlants[1]:GetPivot().Position
        elseif wateringPosition == "Inside Center Right" then
            position = Garden:GetFarmInsideCenterRightPosition()
        elseif wateringPosition == "Inside Center Left" then
            position = Garden:GetFarmInsideCenterLeftPosition()
        elseif wateringPosition == "Center Right" then
            position = Garden:GetFarmCenterRightPosition()
        elseif wateringPosition == "Center Left" then
            position = Garden:GetFarmCenterLeftPosition()
        elseif wateringPosition == "Front Right" then
            position = Garden:GetFarmFrontRightPosition()
        elseif wateringPosition == "Front Left" then
            position = Garden:GetFarmFrontLeftPosition()
        elseif wateringPosition == "Back Right" then
            position = Garden:GetFarmBackRightPosition()
        elseif wateringPosition == "Back Left" then
            position = Garden:GetFarmBackLeftPosition()
        end

        local wateringTask = function(position, each)
            local watered = 0
            if wateringPosition == "Growing Plants" then
                Window:ShowInfo("Auto Watering", "Watering ".. tostring(#growingPlants) .. " growing plants. (" .. growingPlants[1].Name .. ")")
            else
                Window:ShowInfo("Auto Watering", "Watering " .. tostring(each) .. " times at position: " .. tostring(wateringPosition))
            end

            for i = 1, each do
                local success = pcall(function()
                    Core.ReplicatedStorage.GameEvents.Water_RE:FireServer(Vector3.new(position.X, 0, position.Z))
                end)

                if success then
                    watered = watered + 1
                end

                task.wait(1.5) -- Slightly longer delay to reduce server load
            end

            task.wait(0.5) -- Longer final wait
        end

        Player:AddToQueue(
            wateringCan,   -- tool
            99,             -- priority (very low)
            function()
                wateringTask(position, wateringEach)
            end
        )
        task.wait(math.max(wateringDelay, 5)) -- Minimum 5 second delay
    end

    function m:EligibleToHarvest(plant)    
        local Prompt = plant:FindFirstChild("ProximityPrompt", true)

        if not Prompt then
            local customPrompt = string.format("%s_ProximityPrompt", plant.Name)
            Prompt = plant:FindFirstChild(customPrompt, true)
        end

        if not Prompt then return false end
        if not Prompt.Enabled then return false end

        return true
    end

    function m:GetAllGrowingPlants()
        if not PlantsPhysical then
            warn("PlantsPhysical not found")
            return {}
        end

        local growingPlants = {}
        for _, plant in pairs(PlantsPhysical:GetChildren()) do
            local prompt = plant:FindFirstChild("ProximityPrompt", true)
            if not prompt then
                local customPrompt = string.format("%s_ProximityPrompt", plant.Name)
                prompt = plant:FindFirstChild(customPrompt, true)
            end

            if not prompt then
                table.insert(growingPlants, plant)
            end
        end

        return growingPlants
    end

    function m:IsMaxInventory()
        local character = Core.LocalPlayer
        local backpack = Core:GetBackpack()
        if not character or not backpack then
            Window:ShowWarning("Inventory Check", "Character or Backpack not found")
            return false
        end

        local bonusBackpack = character:GetAttribute("BonusBackpackSize") or 0
        local maxCapacity = 200 + bonusBackpack
        local currentItems = 0

        for _, item in pairs(backpack:GetChildren()) do
            if item:GetAttribute("b") == "j" then
                currentItems = currentItems + 1
            end
        end

        return currentItems >= maxCapacity
    end

    function m:GetFruitPlant(plan)
        local fruits = {}

        for _, child in pairs(plan.Fruits:GetChildren()) do
            table.insert(fruits, child)
        end

        return fruits
    end

    function m:GetPlantDetail(_plant)
        if not _plant or not _plant:IsA("Model") then
            warn("Invalid plant")
            return nil
        end

        local prompt = _plant:FindFirstChild("ProximityPrompt", true)
        if not prompt then
            local customPrompt = string.format("%s_ProximityPrompt", _plant.Name)
            prompt = _plant:FindFirstChild(customPrompt, true)
        end

        local parentFruit = prompt and prompt.Parent.Parent.Parent
        local fruits = {}

        if not prompt or not parentFruit then
            -- No prompt means not ready to harvest, so no fruits
            fruits = {}
        elseif parentFruit and parentFruit.Name == "Fruits" then
            for _, fruit in pairs(parentFruit:GetChildren()) do
                table.insert(fruits, fruit)
            end
        else
            fruits = { _plant }
        end

        local doneGrowTime = _plant:GetAttribute("DoneGrowTime") or math.huge

        local detail = {
            name = _plant.Name or "Unknown",
            position = _plant:GetPivot().Position or Vector3.new(0,0,0),
            isGrowing = not prompt or false,
            fruits = {},
        }

        for _, fruit in pairs(fruits) do
            local mutations = {}

            for attributeName, attributeValue in pairs(fruit:GetAttributes()) do
                if attributeValue == true then
                    table.insert(mutations, attributeName)
                end
            end

            -- Detect variant: first try attributes, then fall back to a child StringValue named `Variant`
            local variant = fruit:GetAttribute("Variant")
                or fruit:GetAttribute("VariantName")
                or fruit:GetAttribute("VariantType")

            if not variant then
                -- Some maps store variant as a StringValue child (e.g. Grow/Variant.Value = "Silver")
                local variantObject

                local growFolder = fruit:FindFirstChild("Grow")
                if growFolder then
                    variantObject = growFolder:FindFirstChild("Variant")
                end

                if not variantObject then
                    variantObject = fruit:FindFirstChild("Variant")
                end

                if variantObject and variantObject:IsA("StringValue") then
                    variant = variantObject.Value
                end
            end

            table.insert(detail.fruits, {
                isEligibleToHarvest = self:EligibleToHarvest(fruit),
                mutations = mutations,
                model = fruit,
                variant = fruit.Variant.Value or "Normal",
                weight = fruit.Weight.Value or 0,
            })
        end

        return detail
    end

    function m:SingleHarvestFruit(_fruit)
        if not _fruit or not _fruit:IsA("Model") then
            warn("Invalid plant or fruit")
            return false
        end

        if not self:EligibleToHarvest(_fruit) then
            return false
        end

        if self:IsMaxInventory() then
            return false
        end

        local success, err = pcall(function()
            Core.ReplicatedStorage.GameEvents.Crops.Collect:FireServer({_fruit})
        end)

        if not success then
            warn("Failed to harvest item:", _fruit.Name, "Error:", err)
            return false
        end

        return true
    end

    function m:HarvestFruit(_fruit)
        if not _fruit or not _fruit:IsA("Model") then
            warn("Invalid plant or fruit")
            return false
        end

        if not self:EligibleToHarvest(_fruit) then
            return false
        end

        if self:IsMaxInventory() then
            return false
        end

        local success, err = pcall(function()
            Core.ReplicatedStorage.GameEvents.Crops.Collect:FireServer({_fruit})
        end)

        if not success then
            warn("Failed to harvest item:", _fruit.Name, "Error:", err)
            return false
        end

        return true
    end

    function m:SellAllFruits()
        local lastPosition = Player:GetPosition()
        Player:TeleportToPosition(Core.Workspace.Tutorial_Points.Tutorial_Point_2.CFrame.Position)
        task.wait(0.5) -- Wait before checking again
        Core.ReplicatedStorage.GameEvents.Sell_Inventory:FireServer()
        task.wait(0.5) -- Wait before checking again
        Player:TeleportToPosition(lastPosition)
    end

    function m:StartAutoHarvesting()
        if Window:GetConfigValue("AutoHarvestPlants") ~= true then
            warn("Auto harvesting is disabled in config")
            return
        end

        if self:IsMaxInventory() and Window:GetConfigValue("AutoSellFruits") == true then
            Window:ShowInfo("Auto Harvesting", "Inventory full, selling all fruits...")
            self:SellAllFruits()
        elseif self:IsMaxInventory() then
            task.wait(10) -- Wait before checking again
            return
        end

        local plantsToHarvest = Window:GetConfigValue("PlantsToHarvest") or {}
        if #plantsToHarvest == 0 then
            warn("No plants selected for auto harvesting")
            task.wait(10) -- Wait before checking again
            return
        end

        local weightMode = Window:GetConfigValue("HarvestWeightMode") or "None"
        local weightValue = Window:GetConfigValue("HarvestWeightValue") or 0
        local variantMode = Window:GetConfigValue("HarvestVariantMode") or "None"
        local variantValue = Window:GetConfigValue("HarvestVariantValue") or {}
        local mutationsMode = Window:GetConfigValue("HarvestMutationsMode") or "None"
        local mutationsValue = Window:GetConfigValue("HarvestMutationsValue") or {}

        -- Use FilterMyFruits to get all harvestable fruits
        local filteredFruits = self:FilterMyFruits(
            plantsToHarvest,
            weightValue,
            weightMode,
            variantValue,
            variantMode,
            mutationsValue,
            mutationsMode
        )

        if #filteredFruits == 0 then
            return
        end

        local delayBetweenHarvests = Window:GetConfigValue("HarvestDelay") or 0.05
        local harvestTimeout = 60 -- 1 minute max for entire harvest cycle
        local startTime = tick()

        for _, fruitDetail in pairs(filteredFruits) do
            -- Timeout check to prevent infinite processing
            if tick() - startTime > harvestTimeout then
                warn("Auto Harvesting timed out after " .. harvestTimeout .. " seconds")
                break
            end

            if self:IsMaxInventory() then
                break
            end

            if not fruitDetail.isEligibleToHarvest then
                continue
            end

            -- Safety check: ensure model still exists
            local model = fruitDetail.model
            if not model or not model.Parent then
                continue
            end

            self:SingleHarvestFruit(model)
            task.wait(delayBetweenHarvests) -- Small delay between harvests
        end
    end

    function m:MovePlant()
        local plantToMove = Window:GetConfigValue("PlantToMove")
        if not plantToMove or type(plantToMove) ~= "string" then
            Window:ShowWarning("Plant Mover", "No plant selected to move.")
            return
        end
        local moveDestination = Window:GetConfigValue("MoveDestination")
        if not moveDestination or type(moveDestination) ~= "string" then
            Window:ShowWarning("Plant Mover", "Invalid move destination selected.")
            return
        end

        local plants = self:FindPlants(plantToMove) or {}

        if #plants == 0 then
            Window:ShowWarning("Plant Mover", "No plants found to move.")
            return
        end

        local position = Garden:GetFarmRandomPosition()
        if moveDestination == "Front Right" then
            position = Garden:GetFarmFrontRightPosition()
        elseif moveDestination == "Front Left" then
            position = Garden:GetFarmFrontLeftPosition()
        elseif moveDestination == "Back Right" then
            position = Garden:GetFarmBackRightPosition()
        elseif moveDestination == "Back Left" then
            position = Garden:GetFarmBackLeftPosition()
        elseif moveDestination == "Inside Center Right" then
            position = Garden:GetFarmInsideCenterRightPosition()
        elseif moveDestination == "Inside Center Left" then
            position = Garden:GetFarmInsideCenterLeftPosition()
        elseif moveDestination == "Center Right" then
            position = Garden:GetFarmCenterRightPosition()
        elseif moveDestination == "Center Left" then
            position = Garden:GetFarmCenterLeftPosition()
        end
        if not position then
            Window:ShowWarning("Plant Mover", "Failed to get farm position for moving")
            return
        end

        local flatPosition = Vector3.new(position.X, 0, position.Z)

        local trowel
        for _, Tool in next, Player:GetAllTools() do
            local toolType = Tool:GetAttribute("b")
            if toolType == "b" then
                trowel = Tool
                break
            end
        end
        if not trowel then
            Window:ShowWarning("Plant Mover", "No trowel found in inventory")
            return
        end


        local moveTask = function(plants, position)
            for _, plant in pairs(plants) do
                if not plant or not plant:IsA("Model") then
                    continue
                end

                local flatPlantPosition = Vector3.new(plant:GetPivot().Position.X, 0, plant:GetPivot().Position.Z)
                local magnitudePlant = (flatPlantPosition - flatPosition).Magnitude
                if magnitudePlant > -5 and magnitudePlant < 5 then
                    continue
                end

                local success = pcall(function()
                    Core.ReplicatedStorage.GameEvents.TrowelRemote:InvokeServer(
                        "Pickup",
                        trowel,
                        plant
                    )
                end)

                if success then
                    task.wait(0.5) -- Small delay between moves
                end

                local successPlace = pcall(function()
                    Core.ReplicatedStorage.GameEvents.TrowelRemote:InvokeServer(
                        "Place",
                        trowel,
                        plant,
                        CFrame.new(position.X, 0.5, position.Z)
                    )
                end)

                if not successPlace then
                    Window:ShowWarning("Plant Mover", "Failed to place plant: " .. plant.Name)
                end
            end
        end

        Player:AddToQueue(
            trowel,     -- tool
            10,          -- priority (high)
            function()
                moveTask(plants, position)
            end
        )
    end

    function m:GetListGardenPlants()
        local plantList = {}
        if not PlantsPhysical then
            warn("PlantsPhysical not found")
            return plantList
        end

        for _, plant in pairs(PlantsPhysical:GetChildren()) do
            if not plantList[plant.Name] then
                plantList[plant.Name] = 1
            else
                plantList[plant.Name] = plantList[plant.Name] + 1
            end
        end

        local formattedPlantList = {}
        for plantName, count in pairs(plantList) do
            local plantData = self:FindPlantRegistryByName(plantName)
            table.insert(formattedPlantList, {
                plant = plantName,
                quantity = count,
                types = plantData.types or "Unknown",
                rarity = plantData and plantData.rarity or "Unknown",
                seed = plantData and plantData.seed or "Unknown",
            })
        end

        -- Sort plants by rarity and then alphabetically
        if #formattedPlantList > 0 then
            table.sort(formattedPlantList, function(a, b)
                local rarityA = Rarity.RarityOrder[a.rarity] or 99
                local rarityB = Rarity.RarityOrder[b.rarity] or 99
                if rarityA == rarityB then
                    return a.plant < b.plant
                end
                return rarityA < rarityB
            end)
        end

        return formattedPlantList
    end

    function m:ShovelSelectedPlants()
        local plantToShovel = Window:GetConfigValue("PlantToShovel") or ""
        if not plantToShovel then
            Window:ShowWarning("Plant Shoveler", "No plants selected to shovel.")
            return
        end

        local shovel
        for _, Tool in next, Player:GetAllTools() do
            local uuid = Tool:GetAttribute("UUID")
            if uuid == "SHOVEL" then
                shovel = Tool
                break
            end
        end
        if not shovel then
            Window:ShowWarning("Plant Shoveler", "No shovel found in inventory")
            return
        end


        local shovelTask = function(plantToShovel)
            local maxPlantsToShovel = Window:GetConfigValue("PlantsToShovelCount") or 1
            local totalShoveled = 0

            local plants = self:FindPlants(plantToShovel) or {}
            if plants == 0 then
                Window:ShowWarning("Plant Shoveler", "No plants found to shovel.")
                return
            end

            Window:ShowInfo("Plant Shoveler", "Shoveling up to " .. tostring(maxPlantsToShovel) .. "/" .. tostring(#plants) .. " of " .. plantToShovel)

            for _, plant in pairs(plants) do
                if totalShoveled >= maxPlantsToShovel then
                    Window:ShowInfo("Plant Shoveler", "Finished shoveling " .. tostring(totalShoveled) .. " plants of " .. plantToShovel)
                    return
                end
                if not plant or not plant:IsA("Model") then
                    continue
                end

                local success, result = pcall(function()
                    local primaryPart = plant.PrimaryPart
                    Core.ReplicatedStorage.GameEvents.Remove_Item:FireServer(plant[primaryPart.Name])
                end)

                if not success then
                    Window:ShowWarning("Plant Shoveler", "Failed to shovel plant: " .. plant.Name .. " Error: " .. tostring(result))
                    continue
                end
                task.wait(0.5) -- Small delay between shovels
                totalShoveled = totalShoveled + 1
            end
        end

        Player:AddToQueue(
            shovel,     -- tool
            20,          -- priority (medium-high)
            function()
                shovelTask(plantToShovel)
            end
        )
    end

    function m:ReclaimSelectedPlants()
        local plantToReclaim = Window:GetConfigValue("PlantToReclaim") or ""
        if not plantToReclaim then
            Window:ShowWarning("Plant Reclaimer", "No plants selected to reclaim.")
            return
        end

        local reclaimTool
        for _, tool in next, Player:GetAllTools() do
            if tool.Name:match("Reclaimer") then
                reclaimTool = tool
                break
            end
        end
        if not reclaimTool then
            Window:ShowWarning("Plant Reclaimer", "No reclaimer found in inventory")
            return
        end

        local reclaimTask = function(plantToReclaim)
            local plants = self:FindPlants(plantToReclaim) or {}

            if plants == 0 then
                Window:ShowWarning("Plant Reclaimer", "No plants found to reclaim.")
                return
            end

            Window:ShowInfo("Plant Reclaimer", "Reclaiming " .. tostring(#plants) .. " of " .. plantToReclaim)

            local maxPlantsToReclaim = Window:GetConfigValue("PlantsToReclaimCount") or 1
            local totalReclaimed = 0
            for _, plant in pairs(plants) do
                if totalReclaimed >= maxPlantsToReclaim then
                    Window:ShowInfo("Plant Reclaimer", "Finished reclaiming " .. tostring(totalReclaimed) .. " plants of " .. plantToReclaim)
                    return
                end

                if not plant or not plant:IsA("Model") then
                    continue
                end

                local success, result = pcall(function()
                    Core.ReplicatedStorage.GameEvents.ReclaimerService_RE:FireServer(
                        "TryReclaim",
                        plant
                    )
                end)

                if not success then
                    Window:ShowWarning("Plant Reclaimer", "Failed to reclaim plant: " .. plant.Name .. " Error: " .. tostring(result))
                    continue
                end
                task.wait(0.5) -- Small delay between reclaims
                totalReclaimed = totalReclaimed + 1
            end
        end

        Player:AddToQueue(
            reclaimTool,
            20,         -- priority (low)
            function()
                reclaimTask(plantToReclaim)
            end
        )
    end

    function m:GetSprinklersRegistry()
        local sprinklers = {}
        local sprinklerData = require(Core.ReplicatedStorage.Data.SprinklerData)
        for sprinklerName, _ in pairs(sprinklerData.SprinklerDurations) do
            sprinklers[sprinklerName] = 0
        end

        for _, tool in next, Player:GetAllTools() do
            if tool:GetAttribute("b") ~= "d" then
                continue
            end

            local sprinklerName = tool:GetAttribute("f")
            if sprinklers[sprinklerName] then
                sprinklers[sprinklerName] = tool:GetAttribute("e") or 0
            end
        end

        local listSprinklers = {}
        for sprinklerName, quantity in pairs(sprinklers) do
            table.insert(listSprinklers, {
                name = sprinklerName,
                quantity = quantity,
            })
        end

        table.sort(listSprinklers, function(a, b)
            return a.name < b.name
        end)

        return listSprinklers
    end

    function m:AutoPlaceSprinklers()
        if not Window:GetConfigValue("AutoPlaceSprinklers") then
            return
        end

        local selectedSprinkler = Window:GetConfigValue("SprinklersToPlace") or {}
        if not selectedSprinkler then
            Window:ShowWarning("Auto Sprinkler", "No sprinkler type selected")
            return
        end

        local placedSprinklers = {}
        for _, sprinkler in pairs(self:FindPlacedSprinklers()) do
            placedSprinklers[sprinkler.Name] = sprinkler.Lifetime
        end

        local sprinklerNotPlaced = {}
        for _, sprinklerName in pairs(selectedSprinkler) do
            if not placedSprinklers[sprinklerName] then
                table.insert(sprinklerNotPlaced, sprinklerName)
            end
        end

        if #sprinklerNotPlaced == 0 then
            -- Get faster lifetime sprinkler to wait for
            local minLifetime = math.huge -- Initialize with a very large number
            for _, lifetime in pairs(placedSprinklers) do
                if lifetime < minLifetime then
                    minLifetime = lifetime
                end
            end

            -- If no valid lifetime found, default to 30 seconds
            if minLifetime == math.huge then
                minLifetime = 30
            end

            Window:ShowInfo("Auto Sprinkler", "Waiting " .. tostring(math.floor(minLifetime)) .. "s for next sprinkler.")
            task.wait(minLifetime + 0.1) -- Wait a bit longer than the minimum lifetime
            return
        end

        local selectedSprinklerPosition = Window:GetConfigValue("SprinklerPlacingPosition") or "Random"
        for _, sprinklerName in pairs(sprinklerNotPlaced) do
            local placed = self:PlaceSprinkler(sprinklerName, selectedSprinklerPosition)
            task.wait(0.1) -- Small delay between placing different sprinklers
        end
    end

    function m:FindPlacedSprinklers()
        local placedSprinklers = {}
        for _, obj in pairs(ObjectsPhysical:GetChildren()) do
            local lifetime = obj:GetAttribute("Lifetime") or 0
            if lifetime <= 0 then
                continue
            end

            local owner = obj:GetAttribute("OWNER") or ""
            if owner ~= Core.LocalPlayer.Name then
                continue
            end

            table.insert(placedSprinklers, {
                Name = obj.Name,
                Lifetime = lifetime,
                Model = obj,
            })
        end

        return placedSprinklers
    end

    function m:PlaceSprinkler(_sprinklerName, _position)
        if not _sprinklerName or type(_sprinklerName) ~= "string" then
            Window:ShowWarning("Sprinkler Placing", "Invalid sprinkler name")
            return false
        end

        local tool
        for _, t in next, Player:GetAllTools() do
            local toolType = t:GetAttribute("b")
            local toolSprinkler = t:GetAttribute("f")
            if toolType == "d" and toolSprinkler == _sprinklerName then
                tool = t
                break
            end
        end

        if not tool then
            Window:ShowWarning("Sprinkler Placing", "No sprinkler found for: " .. _sprinklerName)
            return false
        end

        local tasks = Player:GetTaskByTool(tool)
        if tasks and #tasks > 0 then
            return false
        end

        local position = Garden:GetFarmRandomPosition()
        if _position == "Front Right" then
            position = Garden:GetFarmFrontRightPosition()
        elseif _position == "Front Left" then
            position = Garden:GetFarmFrontLeftPosition()
        elseif _position == "Back Right" then
            position = Garden:GetFarmBackRightPosition()
        elseif _position == "Back Left" then
            position = Garden:GetFarmBackLeftPosition()
        elseif _position == "Inside Center Right" then
            position = Garden:GetFarmInsideCenterRightPosition()
        elseif _position == "Inside Center Left" then
            position = Garden:GetFarmInsideCenterLeftPosition()
        elseif _position == "Center Right" then
            position = Garden:GetFarmCenterRightPosition()
        elseif _position == "Center Left" then
            position = Garden:GetFarmCenterLeftPosition()
        end

        if not position then
            Window:ShowWarning("Sprinkler Placing", "Failed to get farm position for sprinkler")
            return false
        end

        -- Generate a random rotation for natural placement
        local function getRandomCFrame(pos)
            local randomAngle = math.rad(math.random(0, 360))
            return CFrame.new(pos.X, 0.5, pos.Z) * CFrame.Angles(0, randomAngle, 0)
        end

        local taskPlace = function(cframe)
            Core.ReplicatedStorage.GameEvents.SprinklerService:FireServer(
                "Create",
                cframe
            )
            task.wait(0.5) -- Add delay after placement
        end

        local isTaskCompleted = false
        local callbackPlace = function()
            isTaskCompleted = true
        end

        local queueResult = Player:AddToQueue(
            tool,
            20,         -- priority (low)
            function()
                local cframe = getRandomCFrame(position)
                taskPlace(cframe)
            end,
            function()
                callbackPlace()
            end
        )

        if not queueResult then
            Window:ShowWarning("Sprinkler Placing", "Failed to add task to queue")
            return false
        end

        -- Wait with timeout
        local timeout = 60
        local elapsed = 0
        while not isTaskCompleted and elapsed < timeout do
            task.wait(1)
            elapsed = elapsed + 1
        end

        if not isTaskCompleted then
            Window:ShowWarning("Sprinkler Placing", "Task timed out")
            return false
        end

        Window:ShowInfo("Sprinkler Placing", "Placed sprinkler: " .. _sprinklerName)

        return true
    end

    function m:RemoveSprinklers()
        local sprinklersToRemove = Window:GetConfigValue("SprinklersToPlace") or {}
        if #sprinklersToRemove == 0 then
            Window:ShowWarning("Sprinkler Remover", "No sprinklers selected to remove.")
            return
        end

        local placedSprinklers = {}
        for _, sprinkler in pairs(self:FindPlacedSprinklers()) do
            placedSprinklers[sprinkler.Name] = sprinkler
        end

        local shovel
        for _, Tool in next, Player:GetAllTools() do
            local uuid = Tool:GetAttribute("UUID")
            if uuid == "SHOVEL" then
                shovel = Tool
                break
            end
        end

        if not shovel then
            Window:ShowWarning("Sprinkler Remover", "No shovel found in inventory")
            return
        end

        local tasks = Player:GetTaskByTool(shovel)
        if tasks and #tasks > 0 then
            return
        end

        local removeTask = function(_placedSprinklers)
            for _, sprinkler in pairs(_placedSprinklers) do
                local sprinklerModel = sprinkler.Model or nil
                if not sprinklerModel then
                    warn("Sprinkler Remover", "No model found for sprinkler: " .. sprinkler.Name)
                    continue
                end

                local sprinklerPrimaryPart = sprinklerModel.PrimaryPart
                if not sprinklerPrimaryPart then
                    warn("Sprinkler Remover", "No primary part found for sprinkler: " .. sprinkler.Name)
                    continue
                end

                local success, result = pcall(function()
                    Core.ReplicatedStorage.GameEvents.DeleteObject:FireServer(sprinklerModel)
                end)

                if not success then
                    Window:ShowWarning("Sprinkler Remover", "Failed to remove sprinkler: " .. sprinkler.Name .. " Error: " .. tostring(result))
                    continue
                end

                Window:ShowWarning("Sprinkler Remover", "Removed sprinkler: " .. sprinkler.Name)
                task.wait(0.5) -- Small delay between removals
            end
        end

        local isTaskCompleted = false
        local callbackRemove = function()
            isTaskCompleted = true
        end

        local queueResult = Player:AddToQueue(
            shovel,
            20,         -- priority (low)
            function()
                removeTask(placedSprinklers)
            end,
            function()
                callbackRemove()
            end
        )

        if not queueResult then
            Window:ShowWarning("Sprinkler Remover", "Failed to add task to queue")
            return
        end

        -- Wait with timeout
        local timeout = 120
        local elapsed = 0
        while not isTaskCompleted and elapsed < timeout do
            task.wait(1)
            elapsed = elapsed + 1
        end

        if not isTaskCompleted then
            Window:ShowWarning("Sprinkler Remover", "Task timed out after " .. timeout .. " seconds")
        end
    end

    function m:GetFruitsOnInventory()
        local myFruits = {}

        local backpack = Core:GetBackpack()
        if not backpack then
            return myFruits
        end

        for _, fruit in pairs(backpack:GetChildren()) do
            if fruit:GetAttribute("b") == "j" then
                table.insert(myFruits, fruit)
            end
        end

        return myFruits
    end

    function m:GetAllOwnedFruitsOnGarden()
        local myFruits = {}
        local listPlant = self:GetListGardenPlants() or {}

        warn(string.format("[GetAllOwnedFruitsOnGarden] Found %d plant types in garden config", #listPlant))

        if #listPlant < 1 then
            warn("[GetAllOwnedFruitsOnGarden] No plants in garden config, trying GetAllGrowingPlants...")
            -- Fallback: try to get all growing plants directly
            local growingPlants = self:GetAllGrowingPlants() or {}
            warn(string.format("[GetAllOwnedFruitsOnGarden] Found %d growing plants", #growingPlants))

            for _, plant in pairs(growingPlants) do
                local plantDetail = self:GetPlantDetail(plant)
                if plantDetail and plantDetail.fruits then
                    for _, fruitDetail in pairs(plantDetail.fruits) do
                        if fruitDetail.isEligibleToHarvest then
                            table.insert(myFruits, fruitDetail)
                        end
                    end
                end
            end

            warn(string.format("[GetAllOwnedFruitsOnGarden] Total harvestable fruits (fallback): %d", #myFruits))
            return myFruits
        end

        local startTime = tick()
        local timeout = 10 -- seconds

        -- Find all plants
        local myPlants = {}
        for _, plant in pairs(listPlant) do
            if tick() - startTime > timeout then
                warn("[GetAllOwnedFruitsOnGarden] Timeout reached while finding plants")
                break
            end

            local foundPlants = self:FindPlants(plant.plant) or {}
            warn(string.format("[GetAllOwnedFruitsOnGarden] Found %d plants of type: %s", #foundPlants, plant.plant or "unknown"))
            for _, p in pairs(foundPlants) do
                table.insert(myPlants, p)
            end
        end

        warn(string.format("[GetAllOwnedFruitsOnGarden] Total plants found: %d", #myPlants))

        if #myPlants < 1 then
            return myFruits
        end

        -- Get plant details and collect fruits
        for _, plant in pairs(myPlants) do
            if tick() - startTime > timeout then
                warn("[GetAllOwnedFruitsOnGarden] Timeout reached while processing plants")
                break
            end

            local plantDetail = self:GetPlantDetail(plant)
            if plantDetail and plantDetail.fruits then
                for _, fruitDetail in pairs(plantDetail.fruits) do
                    if fruitDetail.isEligibleToHarvest then
                        table.insert(myFruits, fruitDetail)
                    end
                end
            end
        end

        warn(string.format("[GetAllOwnedFruitsOnGarden] Total harvestable fruits: %d", #myFruits))
        return myFruits
    end

    -- filtering parameters:
    -- Name Fruits: array of fruit names
    -- Weight Mode: "Above", "Below", "None"
    -- Variant Mode: "Include", "Exclude", "None"
    -- Mutations Mode: "Include", "Exclude", "None"
    function m:FilterMyFruits(_nameFruits, _weight, _weightMode, _variant, _variantMode, _mutations, _mutationsMode)
        local filteredFruits = {}

        if not _nameFruits or type(_nameFruits) ~= "table" or #_nameFruits == 0 then
            return filteredFruits
        end

        -- Set default values
        _weight = _weight or 0
        _weightMode = _weightMode or "None"
        _variant = _variant or {}
        _variantMode = _variantMode or "None"
        _mutations = _mutations or {}
        _mutationsMode = _mutationsMode or "None"

        local startTime = tick()
        local timeout = 10 -- seconds

        for _, fruit in pairs(self:GetAllOwnedFruitsOnGarden()) do
            -- Check timeout
            if tick() - startTime > timeout then
                Window:ShowWarning("Filter Fruits", "Timeout reached, returning " .. tostring(#filteredFruits) .. " filtered fruits")
                break
            end

            local modelFruit = fruit.model or nil
            if not modelFruit then
                continue
            end

            local fruitName = modelFruit.Name or "Unknown Fruit"
            if not table.find(_nameFruits, fruitName) then
                continue
            end

            local fruitWeight = fruit.weight or 0
            local fruitVariant = fruit.variant or "Normal"

            -- Weight filtering
            if _weightMode == "Above" and fruitWeight < _weight then
                continue
            elseif _weightMode == "Below" and fruitWeight > _weight then
                continue
            end

            -- Variant filtering
            if _variantMode == "Include" and not table.find(_variant, fruitVariant) then
                continue
            elseif _variantMode == "Exclude" and table.find(_variant, fruitVariant) then
                continue
            end

            -- Mutations filtering
            if _mutationsMode == "Include" and #_mutations > 0 then
                -- For Include mode: only process if mutations are selected
                local fruitMutations = fruit.mutations or {}

                -- Skip fruits with no mutations
                if #fruitMutations == 0 then
                    continue
                end

                -- Check if fruit has all required mutations
                local hasMutation = false
                for _, mutation in pairs(_mutations) do
                    if table.find(fruitMutations, mutation) then
                        hasMutation = true
                        break
                    end
                end

                if not hasMutation then
                    continue
                end
            elseif _mutationsMode == "Exclude" and #_mutations > 0 then
                -- For Exclude mode: skip if fruit has any of the excluded mutations
                local fruitMutations = fruit.mutations or {}
                local shouldSkip = false

                for _, mutation in pairs(_mutations) do
                    if table.find(fruitMutations, mutation) then
                        shouldSkip = true
                        break
                    end
                end

                if shouldSkip then
                    continue
                end
            end

            table.insert(filteredFruits, fruit)
        end

        return filteredFruits
    end

    function m:StartAutoShovelFruits()
        if not Window:GetConfigValue("AutoShovelFruits") then
            return
        end

        local fruitsToShovel = Window:GetConfigValue("FruitsToShovel") or {}
        if #fruitsToShovel == 0 then
            Window:ShowWarning("Auto Shovel Fruits", "No fruits selected to shovel.")
            return
        end

        local weightMode = Window:GetConfigValue("ShovelFruitsWeightMode") or "None"
        local weightValue = Window:GetConfigValue("ShovelFruitsWeightValue") or 0
        local variantMode = Window:GetConfigValue("ShovelFruitsVariantMode") or "None"
        local variantValue = Window:GetConfigValue("ShovelFruitsVariantValue") or {}
        local mutationsMode = Window:GetConfigValue("ShovelFruitsMutationsMode") or "None"
        local mutationsValue = Window:GetConfigValue("ShovelFruitsMutationsValue") or {}

        -- Use FilterMyFruits to get all harvestable fruits
        local filteredFruits = self:FilterMyFruits(
            fruitsToShovel,
            weightValue,
            weightMode,
            variantValue,
            variantMode,
            mutationsValue,
            mutationsMode
        )

        if #filteredFruits == 0 then
            return
        end

        local delayBetweenShovels = Window:GetConfigValue("ShovelFruitsDelay") or 0.05

        local shovel
        for _, Tool in next, Player:GetAllTools() do
            local uuid = Tool:GetAttribute("UUID")
            if uuid == "SHOVEL" then
                shovel = Tool
                break
            end
        end
        if not shovel then
            Window:ShowWarning("Auto Shovel Fruits", "No shovel found in inventory")
            return
        end

        local shovelTask = function(_fruitsToShovel)
            for _, fruitDetail in pairs(_fruitsToShovel) do
                local modelFruit = fruitDetail.model or nil
                if not modelFruit then
                    continue
                end

                local prompt = modelFruit:FindFirstChild("ProximityPrompt", true)

                if not prompt then
                    local customPrompt = string.format("%s_ProximityPrompt", modelFruit.Name)
                    prompt = modelFruit:FindFirstChild(customPrompt, true)
                end

                if not prompt then
                    warn("Auto Shovel Fruits", "No proximity prompt found for fruit: " .. modelFruit.Name)
                    continue
                end

                modelFruit = prompt.Parent or modelFruit

                local success, result = pcall(function()
                    Core.ReplicatedStorage.GameEvents.Remove_Item:FireServer(modelFruit)
                end)

                if not success then
                    Window:ShowWarning("Auto Shovel Fruits", "Failed to shovel fruit: " .. modelFruit.Name .. " Error: " .. tostring(result))
                    continue
                end

                task.wait(delayBetweenShovels) -- Small delay between shovels
            end
        end

        local isTaskCompleted = false
        local queueResult = Player:AddToQueue(
            shovel,
            20,         -- priority (low)
            function()
                shovelTask(filteredFruits)
            end,
            function()
                isTaskCompleted = true
            end
        )

        -- If AddToQueue failed, exit early
        if not queueResult then
            Window:ShowWarning("Auto Shovel Fruits", "Failed to add shovel task to queue")
            return
        end

        -- Wait with timeout to prevent infinite blocking
        local timeout = 120 -- 2 minutes max
        local elapsed = 0
        while not isTaskCompleted and elapsed < timeout do
            task.wait(1)
            elapsed = elapsed + 1
        end

        if not isTaskCompleted then
            Window:ShowWarning("Auto Shovel Fruits", "Task timed out after " .. timeout .. " seconds")
        end
    end

    return m
end

-- Module: pet/egg.lua
EmbeddedModules["pet/egg.lua"] = function()
    local m = {}

    local Core
    local Player
    local Window
    local Garden
    local Pet
    local Webhook
    local Inventory

    local AutoHatchConnection
    local IsHatchingInProgress = false
    local LastNotificationTime = {}
    local TotalRecoveredEggs = 0
    m.CycleHatchCounter = 0

    function m:SetInventoryModule(_inventory)
        Inventory = _inventory
    end

    function m:Init(_core, _player, _window, _garden, _pet, _webhook)
        Core = _core
        Player = _player
        Window = _window
        Garden = _garden
        Pet = _pet
        Webhook = _webhook

        local EggReadyToHatchRemote = Core.ReplicatedStorage.GameEvents.EggReadyToHatch_RE
        AutoHatchConnection = EggReadyToHatchRemote.OnClientEvent:Connect(function()
            self:StartAutoHatching()
        end)

        task.spawn(function()
            self:StartAutoHatching()
        end)
    end

    function m:StartAutoHatching()
        if not Window:GetConfigValue("AutoHatchEggs") then
            return
        end

        -- If already processing, don't start another process
        if IsHatchingInProgress then
            warn("Hatching already in progress, waiting...")
            return
        end

        IsHatchingInProgress = true

        -- Execute hatch
        self:HatchEgg()

        task.wait(1)
        IsHatchingInProgress = false
    end

    function m:StopAutoHatching()
        if AutoHatchConnection then
            AutoHatchConnection:Disconnect()
            AutoHatchConnection = nil
        end
    end

    function m:GetEggRegistry()
        local success, petRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry)
        end)

        if not success then
            Window:ShowWarning("Egg Registry", "Failed to load Pet Registry module.")
            return {}
        end

        local eggList = petRegistry.PetEggs
        if not eggList then
            Window:ShowWarning("Egg Registry", "PetEggs is nil or not found in Pet Registry module.")
            return {}
        end

        return eggList
    end

    function m:GetAllOwnedEggs()
        local myEggs = {}

        for _, tool in next, Player:GetAllTools() do
            local toolType = tool:GetAttribute("b")
            toolType = toolType and string.lower(toolType) or ""

            if toolType == "c" then
                table.insert(myEggs, tool)
            end
        end

        return myEggs
    end

    function m:FindEggOwnedEgg(eggName)
        for _, tool in next, self:GetAllOwnedEggs() do
            local toolName = tool:GetAttribute("h")

            if toolName == eggName then
                return tool
            end
        end
        return nil
    end

    function m:GetAllPlacedEggs()
        local placedEggs = {}
        local MyFarm = Garden:GetMyFarm()

        if not MyFarm then
            Window:ShowWarning("Farm", "My farm not found!")
            return placedEggs
        end

        local objectsPhysical = MyFarm.Important.Objects_Physical
        if not objectsPhysical then
            Window:ShowWarning("Farm", "Objects_Physical not found!")
            return placedEggs
        end

        for _, egg in pairs(objectsPhysical:GetChildren()) do
            if egg.Name ~= "PetEgg" then
                continue
            end

            local owner = egg:GetAttribute("OWNER")
            if owner == Core.LocalPlayer.Name then
                table.insert(placedEggs, egg)
            end
        end

        return placedEggs
    end

    function m:GetPlacedEggDetail(_eggID)
        local success, dataService = pcall(function()
            return require(Core.ReplicatedStorage.Modules.DataService)
        end)
        if not success or not dataService then
            warn("Failed to load DataService module.")
        end

        local allData = dataService:GetData()
        if not allData then
            warn("No data available from DataService")
            return nil
        end

        local saveSlots = allData.SaveSlots
        if not saveSlots then
            warn("SaveSlots not found in data")
            return nil
        end

        local savedObjects = saveSlots.AllSlots[saveSlots.SelectedSlot].SavedObjects

        if savedObjects and _eggID and savedObjects[_eggID] then
            return savedObjects[_eggID].Data
        end

        -- Fallback method
        warn("Falling back to ReplicationClass method")
        local replicationClass = Core.ReplicatedStorage.Modules.ReplicationClass
        local dataStreamReplicator = replicationClass.new("DataStreamReplicator")
        dataStreamReplicator:YieldUntilData()

        local replicationData = dataStreamReplicator:YieldUntilData().Table
        local playerData = replicationData[Core.LocalPlayer.Name] or replicationData[tostring(Core.LocalPlayer.UserId)]

        if playerData and playerData[_eggID] then
            return playerData[_eggID].Data
        end

        warn("Placed egg detail not found for egg ID: " .. tostring(_eggID))
        return nil
    end

    function m:PlacingEgg()
        local eggName = Window:GetConfigValue("EggPlacing") or ""
        local maxEggs = Window:GetConfigValue("MaxPlaceEggs") or 0
        local positionType = Window:GetConfigValue("PositionToPlaceEggs") or "Random"
        local position = Garden:GetFarmRandomPosition()

        if positionType == "Front Right" then
            position = Garden:GetFarmFrontRightPosition()
        elseif positionType == "Front Left" then
            position = Garden:GetFarmFrontLeftPosition()
        elseif positionType == "Back Right" then
            position = Garden:GetFarmBackRightPosition()
        elseif positionType == "Back Left" then
            position = Garden:GetFarmBackLeftPosition()
        elseif positionType == "Center Right" then
            position = Garden:GetFarmCenterRightPosition()
        elseif positionType == "Center Left" then
            position = Garden:GetFarmCenterLeftPosition()
        end

        if eggName == "" then
            return
        end

        if maxEggs < 1 then
            return
        end

        local eggOwnedName = self:FindEggOwnedEgg(eggName)

        if not eggOwnedName then
            return
        end

        local totalOwnedEggs = eggOwnedName:GetAttribute("e") or 0
        local maxEggCanPlace = math.min(totalOwnedEggs, maxEggs)

        local placeEggTask = function(_maxEggCanPlace, _eggTool, _position, _positionType)
            local attemptCount = 0
            local maxAttempts = 15

            -- Unequip any held item first (e.g., newly hatched pet)
            Player:UnequipTool()
            task.wait(0.3)

            while #self:GetAllPlacedEggs() < _maxEggCanPlace do
                if Player:GetEquippedTool() ~= _eggTool then
                    -- Unequip first in case holding something else (like a pet)
                    Player:UnequipTool()
                    task.wait(0.2)
                    Player:EquipTool(_eggTool)
                    task.wait(0.5) -- Small delay to ensure tool is equipped
                end

                local newPosition = Garden:GetFarmRandomPosition()

                local success, err = pcall(function()
                    if attemptCount >= maxAttempts then
                        newPosition = Garden:GetFarmRandomPosition()
                    elseif string.find(_positionType, "Center") then
                        local eggSpacing = 4

                        local angleStep = (2 * math.pi) / _maxEggCanPlace
                        local radius = eggSpacing / (2 * math.sin(angleStep / 2))
                        radius = math.max(eggSpacing, radius)

                        -- Distribute eggs evenly around the circle
                        local angle = angleStep * attemptCount

                        local xOffset = math.cos(angle) * radius
                        local zOffset = math.sin(angle) * radius

                        newPosition = Vector3.new(_position.X + xOffset, _position.Y, _position.Z + zOffset)
                    elseif string.find(_positionType, "Front") then
                        local zPosition = _position.Z - (attemptCount * 3)
                        if Garden.MailboxPosition.Z > 0 then
                            zPosition = _position.Z + (attemptCount * 3)
                        end

                        newPosition = Vector3.new(_position.X, _position.Y, zPosition)
                    elseif string.find(_positionType, "Back") then
                        local zPosition = _position.Z + (attemptCount * 3)
                        if Garden.MailboxPosition.Z > 0 then
                            zPosition = _position.Z - (attemptCount * 3)
                        end

                        newPosition = Vector3.new(_position.X, _position.Y, zPosition)
                    end
                end)

                Core.ReplicatedStorage.GameEvents.PetEggService:FireServer("CreateEgg", newPosition)
                task.wait(0.15) -- Small delay to avoid spamming

                attemptCount = attemptCount + 1
            end
        end

        -- Add to queue with high priority (1)
        Player:AddToQueue(
            eggOwnedName,           -- tool
            1,                      -- priority (high)
            function()
                placeEggTask(maxEggCanPlace, eggOwnedName, position, positionType)
            end
        )
    end

    function m:HatchEgg()
        if #self:GetAllPlacedEggs() == 0 then
            self:PlacingEgg()
            while #self:GetAllPlacedEggs() < 1 do
                task.wait(1)
            end
        end

        -- Start glitches if enabled
        if Inventory then
            Inventory:StartAutoFavUnfavGear()
            Inventory:StartAutoFavUnfavBoneBlossom()
        end

        -- Wait for eggs to be ready using while loop
        while true do
            local readyCount = 0
            local maxTimeToHatch = 0

            for _, egg in pairs(self:GetAllPlacedEggs()) do
                if not egg or not egg.Parent then -- Check if egg still exists
                    continue
                end

                local timeToHatch = egg:GetAttribute("TimeToHatch") or 0
                if timeToHatch > 0 then
                    maxTimeToHatch = math.max(maxTimeToHatch, timeToHatch)
                else
                    readyCount = readyCount + 1
                end
            end

            if readyCount == #self:GetAllPlacedEggs() then
                break
            end

            local currentTime = tick()
            local notifCooldown = 60 -- 1 minute
            local notifKey = "egg_waiting"

            if not LastNotificationTime[notifKey] or (currentTime - LastNotificationTime[notifKey]) >= notifCooldown then
                Window:ShowInfo("Egg Hatching", "Waiting for eggs to be ready to hatch...")
                LastNotificationTime[notifKey] = currentTime
            end

            task.wait(math.min(maxTimeToHatch, 5)) -- Check every second
        end

        local hatchPetTeam = Window:GetConfigValue("HatchPetTeam") or ""
        local specialHatchPetTeam = Window:GetConfigValue("SpecialHatchPetTeam") or nil
        local specialHatchingPets = Window:GetConfigValue("SpecialHatchingPet") or {}
        local weightThresholdSpecialHatching = Window:GetConfigValue("WeightThresholdSpecialHatching") or math.huge
        local boostBeforeHatch = Window:GetConfigValue("AutoBoostBeforeHatch") or false
        local boostBeforeSpecialHatch = Window:GetConfigValue("AutoBoostBeforeSpecialHatch") or false
        local luckyHatchCount = 0
        local luckySellCount = 0

        -- Optional configurable delay (in seconds) after Hatch team is fully active
        local hatchTeamDelaySeconds = Window:GetConfigValue("HatchTeamDelaySeconds") or 5

        if hatchPetTeam == "" then
            Window:ShowWarning("Egg Hatching", "No Hatch Pet Team selected. Please set HatchPetTeam in the UI before using Auto Hatch.")
            return
        end

        if hatchPetTeam ~= "" then
            Window:ShowInfo("Egg Hatching", "Ensuring hatch pet team is active: " .. hatchPetTeam)
            -- Use the same robust team enforcement as SellPet:
            -- this will unequip non-team pets and repeatedly try to equip
            -- the full Hatch Pet Team until it is active.
            if Pet.EnsureTeamActiveForRole then
                Pet:EnsureTeamActiveForRole(hatchPetTeam, "hatch", "Egg Hatching")
            else
                -- Fallback to a simple team change if helper is not available.
                Pet:ChangeTeamPets(hatchPetTeam, "hatch")
            end

            -- Give a small buffer (2–3 seconds) after team is fully active before hatching
            task.wait(hatchTeamDelaySeconds)

            if boostBeforeHatch then
                Window:ShowInfo("Egg Hatching", "Boosting all active pets before hatch")
                Pet:BoostAllActivePets()
            end
        end

        local notificationHatchConnection = Core.ReplicatedStorage.GameEvents.Notification.OnClientEvent:Connect(function(message)
            if string.find(string.lower(message), "lucky hatch") then
                luckyHatchCount = luckyHatchCount + 1
            elseif string.find(string.lower(message), "lucky pet") then
                luckySellCount = luckySellCount + 1
            end
        end)

        local specialHatchingEgg = {}
        for _, egg in pairs(self:GetAllPlacedEggs()) do
            local eggUUID = egg:GetAttribute("OBJECT_UUID")
            local eggData = self:GetPlacedEggDetail(eggUUID)
            local baseWeight = eggData and eggData.BaseWeight or 1
            local petName = eggData and eggData.Type or "Unknown"

            local isSpecialPet = false
            if table.find(specialHatchingPets, petName) then
                Window:ShowInfo("Egg Hatching", "Deferring hatching of special pet " .. petName .. " to special hatch team.")
                table.insert(specialHatchingEgg, egg)
                continue
            end

            if baseWeight > weightThresholdSpecialHatching then
                Window:ShowInfo("Egg Hatching", "Deferring hatching of " .. petName .. " (Weight: " .. tostring(baseWeight) .. ") to special hatch team.")
                table.insert(specialHatchingEgg, egg)
                continue
            end

            Core.ReplicatedStorage.GameEvents.PetEggService:FireServer("HatchPet", egg)
            task.wait(0.1) -- Small delay between regular egg hatches
        end

        task.wait(1)

        local dontHatchSpecialPets = Window:GetConfigValue("DontHatchSpecialPets") or false
        if not dontHatchSpecialPets and specialHatchPetTeam and #specialHatchingEgg > 0 then
            Window:ShowInfo("Egg Hatching", "Ensuring special hatch pet team is active: " .. specialHatchPetTeam)
            if Pet.EnsureTeamActiveForRole then
                Pet:EnsureTeamActiveForRole(specialHatchPetTeam, "special_hatch", "Egg Hatching (Special)")
            else
                -- Fallback to a simple team change if helper is not available.
                Pet:ChangeTeamPets(specialHatchPetTeam, "special_hatch")
            end

            -- Small buffer before special hatches as well
            task.wait(hatchTeamDelaySeconds)

            if boostBeforeSpecialHatch then
                Window:ShowInfo("Egg Hatching", "Boosting all active pets before special hatch")
                Pet:BoostAllActivePets()
            end
        end

        if not dontHatchSpecialPets and specialHatchPetTeam and #specialHatchingEgg > 0 then
            for _, egg in pairs(specialHatchingEgg) do
                local eggUUID = egg:GetAttribute("OBJECT_UUID")
                local eggData = self:GetPlacedEggDetail(eggUUID)
                local baseWeight = eggData and eggData.BaseWeight or 1
                local petName = eggData and eggData.Type or "Unknown"
                Core.ReplicatedStorage.GameEvents.PetEggService:FireServer("HatchPet", egg)
                task.wait(0.15) -- Small delay to avoid spamming

                task.spawn(function()
                    local eggName = egg:GetAttribute("EggName") or "Unknown"
                    -- Send to user's personal webhook (all special hatches)
                    Webhook:HatchEgg(petName, eggName, baseWeight)
                    -- Send to heavy hatch alert channel (weight >= 6kg)
                    Webhook:HeavyHatchWebhook(petName, eggName, baseWeight)
                    -- Send to divine hatch alert channel (Divine+ rarity AND weight >= 4kg)
                    Webhook:DivineHatchWebhook(petName, eggName, baseWeight)
                end)
            end

            task.wait(1)
        end

        task.spawn(function()
            task.wait(5)
            Window:ShowInfo("Egg Hatching", "Lucky Hatches: " .. tostring(luckyHatchCount))
        end)

        local isAutoSellAfterHatch = Window:GetConfigValue("AutoSellPetsAfterHatching") or false
        local corePetTeam = Window:GetConfigValue("CorePetTeam") or nil
        local sellOnCycleHatchCount = Window:GetConfigValue("SellOnCycleHatchCount") or 1
        self.CycleHatchCounter = self.CycleHatchCounter + 1

        -- Save counter value BEFORE resetting for webhook
        local cycleCounterForWebhook = self.CycleHatchCounter

        if isAutoSellAfterHatch and self.CycleHatchCounter >= sellOnCycleHatchCount then
            Pet:SellPet()
            self.CycleHatchCounter = 0
            Window:ShowInfo("Egg Hatching", "Total Lucky Sell: " .. tostring(luckySellCount))
        else
            Player:UnequipTool()
            Window:ShowInfo("Egg Hatching", "Not selling pets after hatching, returning to core pet team...")

            if corePetTeam and corePetTeam ~= "" then
                if Pet.EnsureTeamActiveForRole then
                    Pet:EnsureTeamActiveForRole(corePetTeam, "core", "Egg Hatching - Restore Core Team")
                else
                    Pet:ChangeTeamPets(corePetTeam, "core")
                end
            end
        end

        Window:ShowInfo("Egg Hatching", "Completed hatching eggs, placing new eggs...")
        self:PlacingEgg()

        task.spawn(function()
            task.wait(1)
            notificationHatchConnection:Disconnect()
            local eggName = Window:GetConfigValue("EggPlacing") or "N/A"
            local tooolEgg = self:FindEggOwnedEgg(eggName)
            local totalOwnedEggs = tooolEgg and (tooolEgg:GetAttribute("e") or 0) or 0

            -- Use saved counter value (3/3) instead of current value (0/3)
            Webhook:Statistics(eggName, totalOwnedEggs, Window:GetConfigValue("MaxPlaceEggs") or 0, #Pet:GetAllOwnedPets() or 0, luckyHatchCount or 0, luckySellCount or 0, cycleCounterForWebhook, sellOnCycleHatchCount)
        end)

        -- Stop glitches
        if Inventory then
            Inventory:StopAutoFavUnfavGear()
            Inventory:StopAutoFavUnfavBoneBlossom()
        end

        -- Calculate luck/deficit for auto-rejoin feature
        local isSellingOnCycleHatch = isAutoSellAfterHatch and cycleCounterForWebhook >= sellOnCycleHatchCount
        self:LuckHatchEggCalculation(luckyHatchCount, luckySellCount, isSellingOnCycleHatch, cycleCounterForWebhook)
    end

    function m:LuckHatchEggCalculation(_totalLuckEggsHatched, _totalLuckSellingPets, _isSellingPets, _cycleHatchCounter)
        local maxEggs = Window:GetConfigValue("MaxPlaceEggs") or 0
        local totalEggsRecovered = 0

        if _isSellingPets then
            -- Prevent division by zero
            if _cycleHatchCounter > 0 then
                totalEggsRecovered = _totalLuckEggsHatched + math.floor(_totalLuckSellingPets / _cycleHatchCounter)
            else
                totalEggsRecovered = _totalLuckEggsHatched
            end
        else
            totalEggsRecovered = _totalLuckEggsHatched
            maxEggs = maxEggs / 2
        end
        local totalEggsNotRecovered = maxEggs - totalEggsRecovered

        if totalEggsNotRecovered > 0 then
            -- Deficit: not enough lucky hatches -> decrease recovered total
            TotalRecoveredEggs = TotalRecoveredEggs - totalEggsNotRecovered
            Window:ShowWarning("Bad Luck", "Deficit Eggs: " .. tostring(totalEggsNotRecovered) .. " (Total Recovered: " .. tostring(TotalRecoveredEggs) .. ")")
        else
            -- Surplus: more lucky hatches than expected -> increase recovered total
            local surplusAmount = math.abs(totalEggsNotRecovered)
            TotalRecoveredEggs = TotalRecoveredEggs + surplusAmount
            Window:ShowInfo("Fairly lucky", "Surplus Eggs: " .. tostring(surplusAmount) .. " (Total Recovered: " .. tostring(TotalRecoveredEggs) .. ")")
        end

        local deficitEggThreshold = Window:GetConfigValue("DeficitEggThreshold") or 5

        -- If total recovered goes negative beyond threshold, rejoin
        if TotalRecoveredEggs <= -deficitEggThreshold and Window:GetConfigValue("AutoRejoinIfBadLuck") then
            Window:ShowWarning("Bad Luck", "Bad Luck deficit reached threshold of " .. tostring(deficitEggThreshold) .. " (Current: " .. tostring(TotalRecoveredEggs) .. "), rejoining server...")
            Core:Rejoin()
        end
    end

    return m
end

-- Module: pet/pet.lua
EmbeddedModules["pet/pet.lua"] = function()
    local Core
    local Player
    local Window
    local Garden
    local PetTeam
    local Webhook
    local Rarity
    local Plant
    local Inventory

    local m = {}

    function m:SetInventoryModule(_inventory)
        Inventory = _inventory
    end

    function m:EnsureTeamActiveForRole(teamName, teamType, label)
        if not teamName or teamName == "" then
            return false
        end

        label = label or "Team"

        Window:ShowInfo(label, "Preparing " .. label .. " Pet Team: " .. tostring(teamName))

        -- 1x normal team change to keep CurrentPetTeam and cooldown tracking consistent.
        pcall(function()
            self:ChangeTeamPets(teamName, teamType)
        end)

        -- Resolve desired pets in the team
        local teamPets = {}
        local ok, result = pcall(function()
            return PetTeam:FindPetTeam(teamName)
        end)
        if ok and result then
            teamPets = result
        else
            Window:ShowWarning(label, "Failed to resolve Pet Team: " .. tostring(teamName) .. ". Proceeding without strict team enforcement.")
        end

        local desiredSet = {}
        for _, petID in ipairs(teamPets) do
            desiredSet[petID] = true
        end

        local totalSlots = 8

        while true do
            -- Step 1: Unequip any active pets that are NOT part of the desired team
            local activePetsMap = self:GetAllActivePets() or {}
            local activeCount = 0
            for petID, _ in pairs(activePetsMap) do
                activeCount = activeCount + 1
                if next(desiredSet) ~= nil and not desiredSet[petID] then
                    self:UnequipPet(petID)
                    task.wait(0.25)
                end
            end

            -- Recompute active pets after unequips
            activePetsMap = self:GetAllActivePets() or {}
            activeCount = 0
            for _, _ in pairs(activePetsMap) do
                activeCount = activeCount + 1
            end

            -- Step 2: Equip missing team members if there are free slots
            local freeSlots = totalSlots - activeCount
            if freeSlots > 0 and #teamPets > 0 then
                for _, petID in ipairs(teamPets) do
                    if freeSlots <= 0 then
                        break
                    end

                    if not activePetsMap[petID] then
                        self:EquipPet(petID)
                        freeSlots = freeSlots - 1
                        task.wait(0.25)
                    end
                end
            end

            -- Step 3: Check if all desired team pets are now active
            activePetsMap = self:GetAllActivePets() or {}
            local allActive = true
            if #teamPets > 0 then
                for _, petID in ipairs(teamPets) do
                    if not activePetsMap[petID] then
                        allActive = false
                        break
                    end
                end
            else
                -- If the team is empty or unresolved, don't block the flow.
                allActive = true
            end

            if allActive then
                Window:ShowInfo(label, "Pet Team is now fully active.")
                return true
            end

            -- Small cooldown between attempts before re-checking
            task.wait(0.5)
        end
    end

    m.CurrentPetTeam = "core"

    local PetSkillConnection
    local AutoPickupLastTime = {}
    local LastAutoBulkingV2State = false
    local LastTeamChangeTime = 0
    local TEAM_CHANGE_COOLDOWN = 3 -- seconds; adjust via code if needed

    function m:Init(_core, _player, _window, _garden, _petTeam, _webhook, _rarity, _plant)
        Core = _core
        Player = _player
        Window = _window
        Garden = _garden
        PetTeam = _petTeam
        Webhook = _webhook
        Rarity = _rarity
        Plant = _plant

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBoostPets")
        end, function()
            self:AutoBoostSelectedPets()
        end)

        -- Nightmare / Leveling / Bulking automation is now handled by special.lua

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoUseMachineAgeBreaker")
        end, function()
            self:AutoUseMachineAgeBreaker()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoPickupPets")
        end, function()
            self:AutoPickupPets()
        end, 1)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoFeedActivePet")
        end, function()
            self:StartAutoFeedActivePet()
        end)
    end

    function m:GetPetReplicationData()
        local replicationClass = require(Core.ReplicatedStorage.Modules.ReplicationClass)
        local activePetsReplicator = replicationClass.new("ActivePetsService_Replicator")
        return activePetsReplicator:YieldUntilData().Table
    end

    function m:GetAllActivePets()
        local success, replicationData = pcall(function()
            return self:GetPetReplicationData()
        end)

        if not success then
            return nil
        end

        if not replicationData or not replicationData.ActivePetStates then
            return nil
        end

        local activePetStates = replicationData.ActivePetStates
        local playerName = Core.LocalPlayer.Name
        local playerId = tostring(Core.LocalPlayer.UserId)

        local playerPets = activePetStates[playerName] 
                        or activePetStates[playerId]
                        or activePetStates[tonumber(playerId)]

        if not playerPets then
            warn("No active pets found for player: " .. playerName)
            return nil
        end

        return playerPets
    end

    function m:GetPlayerPetData()
        local success, replicationData = pcall(self.GetPetReplicationData, self)
        if not success then
            warn("Failed to get replication data:" .. tostring(replicationData))
            return nil
        end

        if not replicationData or not replicationData.PlayerPetData then
            warn("Invalid PlayerPetData structure")
            return nil
        end

        local playerPetData = replicationData.PlayerPetData
        local playerName = Core.LocalPlayer.Name
        local playerId = tostring(Core.LocalPlayer.UserId)

        -- Try multiple ways to find player's data
        local playerData = playerPetData[playerName] 
                        or playerPetData[playerId]
                        or playerPetData[tonumber(playerId)]

        if not playerData then
            warn("No pet data found for player:" .. playerName)
            return nil
        end

        return playerData
    end

    function m:GetPetData(_petID)
        local playerData = self:GetPlayerPetData()
        if playerData and playerData.PetInventory then
            return playerData.PetInventory.Data[_petID]
        end
        return nil
    end

    function m:EquipPet(_petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return false
        end

        local success = pcall(function()
            local position = CFrame.new(Garden:GetFarmCenterPosition())
            if not position then
                Window:ShowWarning("Equip Pet","Failed to get farm center position")
            end

            Core.ReplicatedStorage.GameEvents.PetsService:FireServer(
                "EquipPet",
                _petID,
                position
            )
        end)

        if not success then
            Window:ShowWarning("Equip Pet","Failed to equip pet:" .. _petID)
            return false
        end

        return true
    end

    function m:UnequipPet(_petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return false
        end

        local success = pcall(function()
            Core.ReplicatedStorage.GameEvents.PetsService:FireServer(
                "UnequipPet",
                _petID
            )
        end)

        if not success then
            Window:ShowWarning("Unequip Pet","Failed to unequip pet:" .. _petID)
            return false
        end

        return true
    end

    function m:GetCurrentPetTeam()
        return self.CurrentPetTeam
    end

    function m:ChangeTeamPets(_teamName, _teamType)
        if not _teamName or _teamName == "" then
            return false
        end

        -- Global cooldown to prevent rapid team switching that can bug pet skills/state.
        -- However, for critical flows like hatching ("hatch") and selling ("sell"),
        -- we bypass the cooldown so that the slot can always switch cleanly even if
        -- a previous team change happened recently.
        local now = tick()
        local ignoreCooldown = (_teamType == "sell" or _teamType == "hatch")
        if not ignoreCooldown and now - LastTeamChangeTime < TEAM_CHANGE_COOLDOWN then
            warn(string.format(
                "Skipping team change to %s (%s): still in cooldown (%.2fs remaining)",
                tostring(_teamName),
                tostring(_teamType),
                TEAM_CHANGE_COOLDOWN - (now - LastTeamChangeTime)
            ))
            return false
        end
        LastTeamChangeTime = now

        self.CurrentPetTeam = _teamType

        local pets = PetTeam:FindPetTeam(_teamName)

        if not pets or #pets == 0 then
            Window:ShowWarning("Change Team Pet","No pets found in the team:" .. _teamName)
            return false
        end

        -- Deactivate all current active pets
        local activePets = self:GetAllActivePets()

        if not activePets then
            -- Replication data not yet available; log and rely on the safety wait loop below
            Window:ShowWarning("Change Team Pet", "Active pets replication unavailable; relying on safety wait loop before equipping new team.")
            activePets = {}
        end

        for petID, _ in pairs(activePets) do
            local success = pcall(function()
                self:UnequipPet(petID)
            end)

            if not success then
                Window:ShowWarning("Change Team Pet","Failed to unequip pet:" .. petID)
            end

            task.wait(0.25) -- Longer delay to ensure server processes
        end

        -- Wait for unequip to complete
        task.wait(1)

        -- EXTRA SAFETY: wait until there are no active pets (or timeout) before equipping the new team.
        -- This helps avoid situations where skills/cooldowns bug because old pets are still considered active.
        local maxWait = 5 -- seconds (slightly longer to be safer)
        local startTime = tick()
        local cleared = false

        while tick() - startTime < maxWait do
            local currentActive = self:GetAllActivePets()
            local count = 0

            if currentActive then
                for _, _ in pairs(currentActive) do
                    count = count + 1
                end
            else
                -- If replication data is unavailable, assume there may still be active pets.
                -- Do not break early; wait until we either get valid data with 0 pets or hit timeout.
                warn("Change Team Pet: replication data unavailable while waiting for unequip; continuing to wait...")
            end

            if currentActive and count == 0 then
                cleared = true
                break
            end

            task.wait(0.2)
        end

        -- If we never observed a state with zero active pets, abort this team change to avoid mixing teams
        if not cleared then
            Window:ShowWarning(
                "Change Team Pet",
                "Timeout waiting for active pets to clear before equipping new team: " .. tostring(_teamName) .. ". Aborting team change."
            )
            return false
        end

        -- Activate pets in the selected team
        for _, petID in pairs(pets) do
            local success = pcall(function()
                self:EquipPet(petID)
            end)

            if not success then
                Window:ShowWarning("Change Team Pet","Failed to equip pet:" .. petID)
            end

            task.wait(0.25) -- Longer delay between equips
        end

        -- Final wait to ensure all equips are processed
        task.wait(1)

        -- Auto Switch Pet feature: switch from one pet to another after team change
        coroutine.wrap(function()
            if not Window:GetConfigValue("AutoSwitchPet") then
                return
            end

            local switchPetTeam = Window:GetConfigValue("SwitchPetTeam") or ""
            if not switchPetTeam or switchPetTeam == "" then
                return
            end

            -- Fix: Compare both as lowercase for case-insensitive matching
            if string.lower(_teamName) ~= string.lower(switchPetTeam) then
                return
            end

            local fromPetRaw = Window:GetConfigValue("SwitchFromPetAfterChangeTeam") or ""
            local toPetRaw = Window:GetConfigValue("SwitchToPetAfterChangeTeam") or ""

            -- Fix: Handle table vs string (SelectBox might return table with value field)
            local fromPet = fromPetRaw
            local toPet = toPetRaw

            if type(fromPetRaw) == "table" then
                fromPet = fromPetRaw.value or fromPetRaw[1] or ""
            end
            if type(toPetRaw) == "table" then
                toPet = toPetRaw.value or toPetRaw[1] or ""
            end

            if fromPet == "" or toPet == "" then
                return
            end

            local delay = Window:GetConfigValue("DelaySwitchPetAfterChangeTeam") or 20

            task.wait(delay)

            local success = pcall(function()
                self:UnequipPet(fromPet)
            end)

            if not success then
                Window:ShowWarning("Change Team Pet", "Failed to unequip pet for switch: " .. tostring(fromPet))
                return
            end

            -- Fix: Increased delay from 0.05s to 0.5s for server to process unequip
            task.wait(0.5)

            local successEquip = pcall(function()
                self:EquipPet(toPet)
            end)

            if not successEquip then
                Window:ShowWarning("Change Team Pet", "Failed to equip pet for switch: " .. tostring(toPet))
                return
            end
        end)()

        return true
    end


    function m:IsSafeChangeTeamPets()
        if m.CurrentPetTeam == "manual" or m.CurrentPetTeam == "core" then
            return true
        end

        return false
    end


    function m:BoostPet(_petID)
        Core.ReplicatedStorage.GameEvents.PetBoostService:FireServer(
            "ApplyBoost",
            _petID
        )
    end

    function m:GetListTypeBoosts()
        return {
            {text = "Small Toy", value = "PASSIVE_BOOST-0.1"},
            {text = "Medium Toy", value = "PASSIVE_BOOST-0.2"},
            {text = "Large Toy", value = "PASSIVE_BOOST-0.3"},
        }
    end

    function m:EligiblePetUseBoost(_petID, _boostType, _boostAmount)
        local petData = self:GetPetData(_petID)
        local isEligible = true

        if not petData or not petData.PetData then
            return false
        end

        for key, value in pairs(petData.PetData) do
            if type(value) ~= "table" then
                continue
            end
            if key ~= "Boosts" and #value < 1 then
                continue
            end

            for i, boostInfo in ipairs(value) do
                local currentBoostType = boostInfo.BoostType
                local currentBoostAmount = boostInfo.BoostAmount

                if currentBoostType == _boostType and currentBoostAmount == _boostAmount then
                    isEligible = false
                end
            end
        end
        return isEligible
    end

    function m:BoostSelectedPets()
        local petIDs = Window:GetConfigValue("BoostPets") or {}
        if #petIDs == 0 then
            Window:ShowWarning("Boost Pets","No pets selected for boosting.")
            return
        end

        local boostTypes = Window:GetConfigValue("BoostType") or {}
        if #boostTypes == 0 then
            Window:ShowWarning("Boost Pets", "No boost types selected.")
            return
        end

        for _, boostType in pairs(boostTypes) do
            local extractedType = {}
            for match in string.gmatch(boostType, "([^%-]+)") do
                table.insert(extractedType, match)
            end

            if #extractedType ~= 2 then
                Window:ShowWarning("Boost Pets", "Invalid boost type format:" .. boostType)
                continue
            end

            local toolType = extractedType[1]
            local toolAmount = tonumber(extractedType[2])
            local boostTool = nil

            for _, tool in next, Player:GetAllTools() do
                local tType = tool:GetAttribute("q")
                local tAmount = tool:GetAttribute("o")

                if tType == toolType and tAmount == toolAmount then
                    boostTool = tool or nil
                    break
                end
            end

            if not boostTool then
                continue
            end

            local boostingPetTask = function(_petIDs, _boostType, _boostAmount, _boostTool)
                for _, petID in pairs(_petIDs) do
                    local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                    if not isEligible then
                        continue
                    end

                    self:BoostPet(petID)
                    task.wait(0.15)
                end
            end

            Player:AddToQueue(
                boostTool,               -- tool
                10,                  -- priority (high)
                function()
                    boostingPetTask(petIDs, toolType, toolAmount, boostTool)
                end    -- task function
            )
        end
    end

    function m:AutoBoostSelectedPets()
        local autoBoost = Window:GetConfigValue("AutoBoostPets") or false
        if not autoBoost then
            return
        end

        local petIDs = Window:GetConfigValue("BoostPets") or {}
        if #petIDs == 0 then
            Window:ShowWarning("Boost Pets", "No pets selected for boosting.")
            return
        end

        local boostTypes = Window:GetConfigValue("BoostType") or {}
        if #boostTypes == 0 then
            Window:ShowWarning("Boost Pets", "No boost types selected.")
            return
        end

        local hasEligiblePet = false
        for _, petID in pairs(petIDs) do
            for _, boostType in pairs(boostTypes) do
                local extractedType = {}
                for match in string.gmatch(boostType, "([^%-]+)") do
                    table.insert(extractedType, match)
                end
                if #extractedType ~= 2 then
                    continue
                end

                local toolType = extractedType[1]
                local toolAmount = tonumber(extractedType[2])
                local isEligible = self:EligiblePetUseBoost(petID, toolType, toolAmount)
                if isEligible then
                    hasEligiblePet = true
                    break
                end
            end
            if hasEligiblePet then
                break
            end
        end

        if not hasEligiblePet then
            return
        end

        self:BoostSelectedPets()
    end

    function m:BoostAllActivePets()
        local boostTool = {}

        for _, tool in next, Player:GetAllTools() do
            local toolType = tool:GetAttribute("q")

            if toolType == "PASSIVE_BOOST" then
                table.insert(boostTool, tool)
            end
        end

        if #boostTool == 0 then
            Window:ShowWarning("Boost Pets", "No boost tool found in inventory.")
            return
        end

        for _, tool in next, boostTool do
            local boostType = tool:GetAttribute("q")
            local boostAmount = tool:GetAttribute("o")
            local isTaskCompleted = false

            local boostingPetTask = function(_boostType, _boostAmount)
                Window:ShowInfo("Boost Pets", "Starting boost task for tool: " .. tool.Name)
                local activePetsMap = self:GetAllActivePets() or {}
                for petID, _ in pairs(activePetsMap) do
                    local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                    if not isEligible then
                        continue
                    end

                    Window:ShowInfo("Boost Pets", "Boosting pet: " .. petID .. " with " .. _boostType .. " amount: " .. _boostAmount)
                    self:BoostPet(petID)
                    task.wait(0.15)
                end
            end

            local boostingPetCallback = function()
                isTaskCompleted = true
            end

            Player:AddToQueue(
                tool,               -- tool
                1,                  -- priority (high)
                function()
                    boostingPetTask(boostType, boostAmount)
                end,    -- task function
                function()
                    boostingPetCallback()
                end     -- callback function
            )

            -- Wait until task is completed
            while isTaskCompleted == false do
                task.wait(1)
            end
        end
    end

    function m:GetAllOwnedPets()
        local myPets = {}

        for _, tool in next, Player:GetAllTools() do
            local toolType = tool:GetAttribute("b")
            toolType = toolType or ""
            if toolType == "l" then
                table.insert(myPets, tool)
            end
        end

        return myPets
    end

    function m:GetPetDetail(_petID)
        local success, petMutationRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)
        end)

        if not success then
            Window:ShowWarning("Pet Details", "Failed to load PetMutationRegistry: " .. tostring(petMutationRegistry))
            petMutationRegistry = nil
        end

        local petData = self:GetPetData(_petID)
        if not petData then
            Window:ShowWarning("Pet Details", "Pet data not found for UUID:" .. _petID)
            return nil
        end

        local petDetail = petData.PetData

        if not petDetail then
            Window:ShowWarning("Pet Details", "Pet detail is nil for UUID:" .. _petID)
            return nil
        end

        local isActive = false
        local activePets = self:GetAllActivePets() or {}
        for petID, _ in pairs(activePets) do
            if petID == _petID then
                isActive = true
                break
            end
        end

        local mutationType = petDetail.MutationType or ""
        if mutationType == "Gold" then
            mutationType = "Golden"
        end
        local mutation = ""

        if petMutationRegistry and petMutationRegistry.EnumToPetMutation and mutationType ~= "" then
            mutation = petMutationRegistry.EnumToPetMutation[mutationType] or ""
        end

        local petRegistry = require(Core.ReplicatedStorage.Data.PetRegistry)
        local petList = petRegistry.PetList or {}
        local defaultPet = petList[petData.PetType] or nil

        local baseWeight = petDetail.BaseWeight or 1
        local function calculateWeightAtAge(age)
            if age <= 0 then
                return baseWeight
            end

            local weightIncrement = baseWeight * 0.1

            return baseWeight + (weightIncrement * age)
        end

        return {
            ID = _petID,
            Name = petDetail.Name or "Unnamed",
            Type = petData.PetType or "Unknown",
            BaseWeight = baseWeight,
            BaseWeightAge1 = calculateWeightAtAge(1),
            CurrentWeight = calculateWeightAtAge(petDetail.Level or 0),
            Age = petDetail.Level or 0,
            IsFavorited = petDetail.IsFavorite or false,
            IsActive = isActive,
            Mutation = mutation,
            CurrentHunger = petDetail.Hunger or 0,
            MaxHunger = defaultPet and defaultPet.DefaultHunger or 0
        }
    end

    function m:GetAllMyPets()
        local myPets = {}
        local pets = {}

        for _, tool in pairs(self:GetAllOwnedPets()) do
            local petID = tool:GetAttribute("PET_UUID")
            if not petID then
                Window:ShowWarning("Pet Details", "Pet tool missing PET_UUID attribute:" .. tool.Name)
                continue
            end

            table.insert(pets, {
                ID = petID,
                IsActive = false
            })
        end

        local activePetsMap = self:GetAllActivePets() or {}
        for petID, _ in pairs(activePetsMap) do
            if not petID then
                Window:ShowWarning("Pet Details", "Active pet entry missing PET_UUID")
                continue
            end

            table.insert(pets, {
                ID = petID,
                IsActive = true
            })
        end

        for _, pet in pairs(pets) do
            local petDetail = self:GetPetDetail(pet.ID)
            if not petDetail  then
                Window:ShowWarning("Pet Details", "Pet detail not found for UUID:" .. pet.ID)
                continue
            end

            table.insert(myPets, {
                ID = petDetail.ID,
                Name = petDetail.Name,
                Type = petDetail.Type,
                BaseWeight = petDetail.BaseWeight,
                BaseWeightAge1 = petDetail.BaseWeightAge1,
                CurrentWeight = petDetail.CurrentWeight,
                Age = petDetail.Age,
                IsActive = pet.IsActive,
                IsFavorited = petDetail.IsFavorited,
                Mutation = petDetail.Mutation
            })
        end

        -- Sort by active status first, then by type, then by age descending
        table.sort(myPets, function(a, b)
            if a.IsActive ~= b.IsActive then
                return a.IsActive -- Active pets first
            elseif a.Type ~= b.Type then
                return a.Type < b.Type -- Alphabetical by type
            else
                return a.Age > b.Age -- Older pets first
            end
        end)

        return myPets
    end

    function m:SerializePet(pet)
        if not pet then return "" end
        local weight = tonumber(pet.BaseWeight) or 0
        local age = tonumber(pet.Age) or 0
        local mutationPrefix = (pet.Mutation and pet.Mutation ~= "") and ("[" .. pet.Mutation .. "] ") or ""
        local activeSuffix = pet.IsActive and " (Active)" or ""
        return string.format("%s%s %.2f KG (age %d) - %s%s",
            mutationPrefix,
            pet.Type or "Unknown",
            weight,
            age,
            pet.Name or "Unnamed",
            activeSuffix
        )
    end

    function m:FindEggByPetName(petName)
        local PetEggs = require(Core.ReplicatedStorage.Data.PetRegistry.PetEggs)

        -- List of eggs to exclude (fake/test eggs)
        local excludedEggs = {
            ["Fake Egg"] = true,
            -- Add other test/fake eggs here if needed
        }

        -- Iterate through all eggs
        for eggName, eggData in pairs(PetEggs) do
            -- Skip excluded eggs
            if excludedEggs[eggName] then
                continue
            end

            -- Check if RarityData and Items exist
            if eggData.RarityData and eggData.RarityData.Items then
                -- Check if the pet exists in this egg
                if eggData.RarityData.Items[petName] then
                    return eggName -- Return the egg name
                end
            end
        end

        return "Fake Egg" -- Pet not found in any egg
    end

    function m:GetPetRegistry()
        local success, petRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry)
        end)

        if not success then
            Window:ShowWarning("Pet Registry", "Failed to get pet registry:" .. petRegistry)
            return {}
        end

        local petList = petRegistry.PetList
        if not petList then
            Window:ShowWarning("Pet Registry", "PetList is nil or not found")
            return {}
        end

        -- Convert PetList to UI format {text = ..., value = ...}
        local listPets = {}
        for petName, petData in pairs(petList) do
            local eggName = self:FindEggByPetName(petName)
            table.insert(listPets, {
                Name = petName,
                Rarity = petData.Rarity or "Unknown",
                Egg = eggName
            })
        end

        if #listPets < 1 then
            return {}
        end

        -- Sort pets alphabetically (ascending order)
        table.sort(listPets, function(a, b)
            local eggA = a.Egg or "Unknown"
            local eggB = b.Egg or "Unknown"
            if eggA ~= eggB then
                return string.lower(tostring(eggA)) < string.lower(tostring(eggB))
            end

            local rarityA = Rarity.RarityOrder[a.Rarity] or 99
            local rarityB = Rarity.RarityOrder[b.Rarity] or 99
            if rarityA ~= rarityB then
                return rarityA < rarityB
            end

            return string.lower(tostring(a.Name)) < string.lower(tostring(b.Name))
        end)

        return listPets
    end

    function m:SellPet()
        -- Start glitches if enabled
        if Inventory then
            Inventory:StartAutoFavUnfavGear()
            Inventory:StartAutoFavUnfavBoneBlossom()
        end

        local petNames = Window:GetConfigValue("PetToSell") or {}
        local weighLessThan = Window:GetConfigValue("WeightThresholdSellPet") or 1
        local ageLessThan = Window:GetConfigValue("AgeThresholdSellPet") or 1
        local sellPetTeam = Window:GetConfigValue("SellPetTeam") or nil
        local boostBeforeSelling = Window:GetConfigValue("AutoBoostBeforeSelling") or false
        local corePetTeam = Window:GetConfigValue("CorePetTeam") or nil

        if #petNames == 0 then
            Window:ShowWarning("Sell Pets", "No pet names selected for selling.")
            if corePetTeam then
                Window:ShowInfo("Sell Pets", "Reverting to Core Pet Team: " .. corePetTeam)
                self:ChangeTeamPets(corePetTeam, "core")
            end
            -- Stop glitches before early return
            if Inventory then
                Inventory:StopAutoFavUnfavGear()
                Inventory:StopAutoFavUnfavBoneBlossom()
            end
            return
        end

        if sellPetTeam then
            self:EnsureTeamActiveForRole(sellPetTeam, "sell", "Sell Pets")

            if boostBeforeSelling then
                Window:ShowInfo("Sell Pets", "Boosting all active pets before selling")
                self:BoostAllActivePets()
            end
        end

        task.wait(1)
        Window:ShowInfo("Sell Pets", "Preparing pets for selling...")

        -- Prevent for held pet
        Player:UnequipTool()
        task.wait(0.2)

        -- Build list of pets to sell and favorite pets to protect
        local petsToSellCount = 0
        for _, tool in pairs(self:GetAllOwnedPets()) do
            local isFavorited = tool:GetAttribute("d") or false
            if isFavorited then
                continue
            end

            local petID = tool:GetAttribute("PET_UUID")
            local petDetail = self:GetPetDetail(petID)
            if not petDetail then
                -- Favorite unknown pets for safety
                Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(tool)
                task.wait(0.05)
                continue
            end

            local petName = petDetail.Type or "Unknown"
            local petWeight = petDetail.BaseWeight or 20
            local petAge = petDetail.Age or 0

            -- Check if pet matches sell criteria
            local isPetNameMatched = table.find(petNames, petName) ~= nil
            local matchesWeight = petWeight < weighLessThan
            local matchesAge = petAge < ageLessThan

            if isPetNameMatched and matchesWeight and matchesAge then
                -- This pet matches criteria and will be sold
                petsToSellCount = petsToSellCount + 1
            else
                -- Favorite to protect from SellAllPets_RE
                Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(tool)
                task.wait(0.05)
            end
        end

        task.wait(0.5)
        Window:ShowInfo("Sell Pets", string.format("Selling %d pets using SellAllPets_RE...", petsToSellCount))

        -- Use SellAllPets_RE to sell all matching pets at once
        Core.ReplicatedStorage.GameEvents.SellAllPets_RE:FireServer()
        task.wait(1) -- Wait for server to process

        Window:ShowInfo("Sell Pets", string.format("Sold %d pet(s)", petsToSellCount))

        if corePetTeam then
            Window:ShowInfo("Sell Pets", "Reverting to Core Pet Team: " .. corePetTeam)

            if self.EnsureTeamActiveForRole then
                local ok = self:EnsureTeamActiveForRole(corePetTeam, "core", "Sell Pets - Restore Core Team")
                if not ok then
                    Window:ShowWarning(
                        "Sell Pets",
                        "Failed to fully restore Core Pet Team: " .. tostring(corePetTeam) .. ". Please check your active pets manually."
                    )
                end
            else
                local success = self:ChangeTeamPets(corePetTeam, "core")
                if not success then
                    Window:ShowWarning(
                        "Sell Pets",
                        "Failed to change back to Core Pet Team: " .. tostring(corePetTeam) .. ". Please check your active pets manually."
                    )
                end
            end
        end

        -- Stop glitches
        if Inventory then
            Inventory:StopAutoFavUnfavGear()
            Inventory:StopAutoFavUnfavBoneBlossom()
        end
    end

    function m:GetModelPet(_petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return nil
        end

        -- Cari di semua descendant
        for _, petMover in ipairs(workspace.PetsPhysical:GetChildren()) do
            local modelPet = petMover:FindFirstChild(_petID)
            if modelPet then
                return modelPet
            end
        end

        Window:ShowWarning("Get Model Pet", "Model not found")
        return nil
    end

    function m:CleansingMutation(_petID)
        Window:ShowInfo("Cleansing Mutation", "Cleansing mutation for pet ID: " .. _petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return false
        end

        -- Ensure the avatar is not currently holding any tool (including Cleansing Shard)
        if Player.UnequipTool then
            Player:UnequipTool()
            task.wait(0.2)
        end

        local cleansingTool
        for _, tool in next, Player:GetAllTools() do
            local toolName = tool:GetAttribute("u")

            if toolName == "Cleansing Pet Shard" then
                cleansingTool = tool or nil
                break
            end
        end

        if not cleansingTool then
            Window:ShowWarning("Cleansing Mutation", "No cleansing tool found")
            return false
        end

        local isTaskCompleted = false
        local cleansingTask = function(_petID)
            local petMover = self:GetModelPet(_petID)
            if not petMover then
                Window:ShowWarning("Cleansing Mutation", "PetMover not found for pet ID: " .. _petID)
                return
            end

            Window:ShowInfo("Cleansing Mutation", "Applying cleansing shard to pet ID: " .. _petID)
            local success, error = pcall(function()
                Core.ReplicatedStorage.GameEvents.PetShardService_RE:FireServer(
                    "ApplyShard",
                    petMover
                )
            end)

            if not success then
                Window:ShowWarning("Cleansing Mutation", "Failed to apply cleansing shard: " .. error)
            end
            task.wait(1) -- Wait to ensure server processes the shard application
        end

        local cleansingCallback = function()
            isTaskCompleted = true
        end

        Player:AddToQueue(
            cleansingTool,               -- tool
            10,                  -- priority (high)
            function()
                cleansingTask(_petID)
            end,    -- task function
            function()
                cleansingCallback()
            end -- callback function
        )

        return true
    end


    function m:GetMachineAgeBreakerData()
        local DataService = require(Core.ReplicatedStorage.Modules.DataService)

        local data = DataService:GetData()
        if not data then
            Window:ShowWarning("Machine Age Breaker", "Failed to get player data for Machine Age Breaker.")
            return nil
        end

        return data.PetAgeBreakMachine or nil
    end

    function m:GetMachineAgeBreakerStatus()
        local machineData = self:GetMachineAgeBreakerData()
        if not machineData then
            return {
                Status = "Not Available"
            }
        end

        local TimeHelper = require(Core.ReplicatedStorage.Modules.TimeHelper)

        if machineData.IsRunning or machineData.TimeLeft > 0 then
            return {
                Status = "Running",
                Data = {
                    FormatedTimeLeft = TimeHelper:GenerateColonFormatFromTime(machineData.TimeLeft),
                    TimeLeft = machineData.TimeLeft
                }
            }
        elseif machineData.PetReady then
            return {
                Status = "Claim Pet"
            }
        elseif machineData.SubmittedPet then
            return {
                Status = "Select Dupes"
            }
        else
            return {
                Status = "Submit Pet"
            }
        end
    end

    function m:FilterMyPets(params)
        local allPets = self:GetAllMyPets()
        local filteredPets = {}

        -- Set default value if not specified
        local petType = params.petType or {}
        local modeWeight = params.modeWeight or "none"
        local baseWeightType = params.baseWeightType or "BaseWeightAge1"
        local modeAge = params.modeAge or "none"
        local weight = params.weight or {0, 0}
        local age = params.age or {0, 0}
        if type(weight) == "number" then
            weight = {weight, weight}
        end
        if type(age) == "number" then
            age = {age, age}
        end
        local modeMutation = params.modeMutation or "none"
        local mutation = params.mutation or {}
        local includeActive = params.includeActive
        if includeActive == nil then includeActive = true end
        local includeFavorited = params.includeFavorited or false

        for _, pet in pairs(allPets) do
            if not includeActive and pet.IsActive then
                continue
            end

            if not includeFavorited and pet.IsFavorited then
                continue
            end

            -- Get the weight value based on baseWeightType
            local petWeight = pet[baseWeightType] or pet.BaseWeightAge1

            if string.lower(modeWeight) == "above" and petWeight < weight[1] then
                continue
            elseif string.lower(modeWeight) == "below" and petWeight > weight[1] then
                continue
            elseif string.lower(modeWeight) == "between" and (petWeight < weight[1] or petWeight > weight[2]) then
                continue
            end

            if string.lower(modeAge) == "above" and pet.Age < age[1] then
                continue
            elseif string.lower(modeAge) == "below" and pet.Age > age[1] then
                continue
            elseif string.lower(modeAge) == "between" and (pet.Age < age[1] or pet.Age > age[2]) then
                continue
            end

            if #petType > 0 and not table.find(petType, pet.Type) then
                continue
            end

            if string.lower(modeMutation) == "include" and not table.find(mutation, pet.Mutation) then
                continue
            elseif string.lower(modeMutation) == "exclude" and table.find(mutation, pet.Mutation) then
                continue
            end

            table.insert(filteredPets, pet)
        end

        return filteredPets
    end

    function m:AutoUseMachineAgeBreaker()
        local autoUseMachine = Window:GetConfigValue("AutoUseMachineAgeBreaker") or false
        if not autoUseMachine then
            return
        end

        local gameEvents = Core.ReplicatedStorage.GameEvents

        if self:GetMachineAgeBreakerStatus().Status == "Claim Pet" then
            Window:ShowInfo("Machine Age Breaker", "Claiming pet from Age Breaker.")
            gameEvents.PetAgeLimitBreak_Claim:FireServer()
        end

        if self:GetMachineAgeBreakerStatus().Status == "Running" then
            if Window:GetConfigValue("AgeBreakerSkipUseToken") then
                Window:ShowInfo("Machine Age Breaker", "Using Token to skip wait time for Age Breaker")
                Core.ReplicatedStorage.GameEvents.TradeEvents.TradeTokens.Purchase:InvokeServer(3453278902)

                -- Wait for server to process token purchase
                task.wait(2)

                -- Check if status changed to "Claim Pet" after using token
                local statusAfterToken = self:GetMachineAgeBreakerStatus()
                if statusAfterToken.Status == "Claim Pet" then
                    Window:ShowInfo("Machine Age Breaker", "Token used successfully. Claiming pet now.")
                    gameEvents.PetAgeLimitBreak_Claim:FireServer()
                    task.wait(1)
                    return
                else
                    Window:ShowWarning("Machine Age Breaker", "Token purchase may have failed or is still processing. Status: " .. tostring(statusAfterToken.Status))
                    return
                end
            end

            local duration = self:GetMachineAgeBreakerStatus().Data.TimeLeft + 1
            Window:ShowInfo("Machine Age Breaker", string.format("Waiting for it to complete: %s", self:GetMachineAgeBreakerStatus().Data.FormatedTimeLeft), duration)
            for i = duration, 1, -1 do
                local lastStatus = self:GetMachineAgeBreakerStatus()
                if lastStatus.Status ~= "Running" then
                    break
                end

                task.wait(1)
            end
        end

        -- Get Target Pets
        local targetPetType = Window:GetConfigValue("AgeBreakerTargetPetTypes") or {}
        local targetPetAge = Window:GetConfigValue("AgeBreakerTargetAge") or 125
        local forceFavoritePet = Window:GetConfigValue("AgeBreakerForceUseFavoriteTargetAndSacrifice") or false
        local targetPets = self:FilterMyPets({
            petType = targetPetType,
            weight = 0,
            modeWeight = "none",
            age = {100, targetPetAge},
            modeAge = "between",
            mutation = {},
            modeMutation = "none",
            includeActive = false,
            includeFavorited = forceFavoritePet
        }) or {}
        if #targetPets == 0 then
            Window:ShowWarning("Machine Age Breaker", "No target pets selected for Age Breaker.")
            return
        end

        -- Get Sacrifice Pets
        local sacrificePetAgeThreshold = Window:GetConfigValue("AgeBreakerSacrificeAgeThreshold") or 10
        local sacrificePetWeightThreshold = Window:GetConfigValue("AgeBreakerSacrificeWeightThreshold") or 3.0
        local sacrificePets = self:FilterMyPets({
            petType = targetPetType,
            weight = sacrificePetWeightThreshold,
            modeWeight = "below",
            age = sacrificePetAgeThreshold,
            modeAge = "below",
            mutation = {},
            modeMutation = "none",
            includeActive = false,
            includeFavorited = forceFavoritePet
        }) or {}
        if #sacrificePets == 0 then
            Window:ShowWarning("Machine Age Breaker", "No sacrifice pets selected for Age Breaker.")
            return
        end

        if self:GetMachineAgeBreakerStatus().Status == "Submit Pet" then
            -- Get pet at inventory
            local toolPet = nil
            local targetPet = nil

            for _, pet in pairs(targetPets) do
                if pet.IsActive then
                    continue
                end

                if pet.Age >= targetPetAge then
                    continue
                end

                if pet.IsFavorited and not forceFavoritePet then
                    continue
                end

                for _, tool in pairs(self:GetAllOwnedPets()) do
                    local toolPetID = tool:GetAttribute("PET_UUID")
                    if toolPetID ~= pet.ID then
                        continue
                    end

                    if tool:GetAttribute("d") and forceFavoritePet then
                        Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(tool)
                        task.wait(1)
                    end

                    toolPet = tool
                    targetPet = pet
                    break
                end

                if toolPet and targetPet then
                    break
                end
            end

            if not toolPet then
                Window:ShowWarning("Machine Age Breaker", "No valid target pet found for Age Breaker.")
                return
            end

            local isTaskCompleted = false
            local submitPetTask = function()
                Window:ShowInfo("Machine Age Breaker", "Submitting pet for Age Breaker.")

                gameEvents.PetAgeLimitBreak_SubmitHeld:FireServer()
                task.wait(2)

                Window:SetConfigValue("AgeBreakerMachineLastSubmitPetID", targetPet.ID or "")
                Window:SetConfigValue("AgeBreakerMachineLastSubmitPetType", targetPet.Type or "Unknown")
                Window:SetConfigValue("AgeBreakerMachineLastSubmitPetAge", targetPet.Age or 0)
            end

            local submitPetCallback = function()
                Window:ShowInfo("Machine Age Breaker", "Pet submitted for Age Breaker.")
                isTaskCompleted = true
            end

            Player:AddToQueue(
                toolPet,               -- tool
                1,                  -- priority (high)
                function()
                    submitPetTask()
                end,    -- task function
                function()
                    submitPetCallback()
                end -- callback function
            )

            while isTaskCompleted == false do
                task.wait(1)
            end
        end

        if self:GetMachineAgeBreakerStatus().Status == "Select Dupes" then
            local sacrificePet = nil
            for _, pet in pairs(sacrificePets) do
                if pet.IsActive then
                    continue
                end

                if pet.IsFavorited and not forceFavoritePet then
                    continue
                end

                sacrificePet = pet
                break
            end

            if not sacrificePet then
                Window:ShowWarning("Machine Age Breaker", "No valid sacrifice pet found for Age Breaker.")
                return
            end

            local success, response = pcall(function()
                gameEvents.PetAgeLimitBreak_Submit:FireServer({[1] = sacrificePet.ID})
            end)

            if not success then
                Window:ShowWarning("Machine Age Breaker", "Failed to submit sacrifice pet for Age Breaker: " .. tostring(response))
                return
            end

            Window:ShowInfo("Machine Age Breaker", "Selecting duplicate pets for Age Breaker.")
        end
    end

    function m:AutoPickupPets()
        if not Window:GetConfigValue("AutoPickupPets") then
            return
        end

        if PetSkillConnection then
            return
        end

        PetSkillConnection = Core.ReplicatedStorage.GameEvents.PetCooldownsUpdated.OnClientEvent:Connect(function(...)
            local args = {...}

            local petID = args[1]
            local skillsData = args[2]

            if not petID or not skillsData then
                return
            end

            local targetPetIDs = Window:GetConfigValue("PickupTargetPets") or {}
            local pickupDelay = Window:GetConfigValue("PickupDelayAfterUseSkill") or 0.5
            local placeDelay = Window:GetConfigValue("PlaceDelayAfterUseSkill") or 0.1

            if not table.find(targetPetIDs, petID) then
                return
            end

            for _, skillInfo in pairs(skillsData) do
                local skillTime = skillInfo.Time or 0
                local skillName = skillInfo.Passive or ""

                if skillName == "" or skillName == nil or skillName == "Movement Variation" then
                    continue
                end

                if skillTime <= 0 then
                    task.wait(pickupDelay)
                    self:UnequipPet(petID)

                    task.wait(placeDelay)

                    if self:IsSafeChangeTeamPets() then
                        self:EquipPet(petID)
                    end
                end
            end
        end)
    end

    function m:StopAutoPickupPets()
        if PetSkillConnection then
            PetSkillConnection:Disconnect()
            PetSkillConnection = nil
        end
    end

    function m:StartAutoFeedActivePet()
        if not Window:GetConfigValue("AutoFeedActivePet") then
            return
        end

        local targetPetIDs = Window:GetConfigValue("FeedTargetPets") or {}
        if #targetPetIDs == 0 then
            return
        end

        local hungerThreshold = Window:GetConfigValue("HungerThresholdAutoFeedActivePet") or 50
        local activePets = self:GetAllActivePets() or {}

        for petId, _ in pairs(activePets) do
            -- Skip if pet is not in target list
            if not table.find(targetPetIDs, petId) then
                continue
            end

            local petDetail = self:GetPetDetail(petId)
            if not petDetail then
                Window:ShowWarning("Auto Feed Active Pet", "Pet detail not found for UUID: " .. petId)
                continue
            end

            -- Get hunger directly from pet data if MaxHunger is not available
            local currentHunger = petDetail.CurrentHunger or 0
            local maxHunger = petDetail.MaxHunger or 0

            -- If MaxHunger is 0, try to get it from active pet state
            if maxHunger <= 0 then
                local activePetState = activePets[petId]
                if activePetState and activePetState.Hunger then
                    currentHunger = activePetState.Hunger.Current or currentHunger
                    maxHunger = activePetState.Hunger.Max or 100
                end
            end

            -- Skip if still no valid MaxHunger
            if maxHunger <= 0 then
                continue
            end

            local hungerPercentage = (currentHunger / maxHunger) * 100

            if hungerPercentage >= hungerThreshold then
                continue
            end

            -- Get ignore list
            local ignoreFruits = Window:GetConfigValue("IgnoreFruitsForFeed") or {}

            -- Get fruits from inventory
            local fruitsOnInventory = {}
            if Plant and Plant.GetFruitsOnInventory then
                local allFruits = Plant:GetFruitsOnInventory() or {}
                -- Filter out ignored fruits
                for _, fruit in pairs(allFruits) do
                    local fruitName = fruit.Name or "Unknown"
                    if not table.find(ignoreFruits, fruitName) then
                        table.insert(fruitsOnInventory, fruit)
                    end
                end
            else
                -- Fallback: get directly from backpack
                local backpack = Core:GetBackpack()
                if backpack then
                    for _, item in pairs(backpack:GetChildren()) do
                        if item:GetAttribute("b") == "j" then
                            local fruitName = item.Name or "Unknown"
                            if not table.find(ignoreFruits, fruitName) then
                                table.insert(fruitsOnInventory, item)
                            end
                        end
                    end
                end
            end

            -- Get fruits from garden
            local fruitsOnGarden = {}
            if Plant and Plant.GetAllOwnedFruitsOnGarden then
                local allGardenFruits = Plant:GetAllOwnedFruitsOnGarden() or {}
                -- Filter out ignored fruits
                for _, fruitDetail in pairs(allGardenFruits) do
                    local fruitModel = fruitDetail.model
                    if fruitModel then
                        local fruitName = fruitModel.Name or "Unknown"
                        if not table.find(ignoreFruits, fruitName) then
                            table.insert(fruitsOnGarden, fruitDetail)
                        end
                    end
                end
            end

            if #fruitsOnInventory == 0 and #fruitsOnGarden == 0 then
                Window:ShowWarning("Auto Feed Active Pet", "No fruits found on inventory or garden to feed pets.")
                return
            elseif #fruitsOnInventory == 0 and #fruitsOnGarden > 0 then
                Window:ShowInfo("Auto Feed Active Pet", "No fruits found on inventory. Collecting fruits from garden...")

                local harvestSuccess = false
                if Plant and Plant.HarvestFruit then
                    harvestSuccess = Plant:HarvestFruit(fruitsOnGarden[1].model)
                end

                if not harvestSuccess then
                    return
                end

                task.wait(0.5)

                -- Re-check inventory after harvest and apply ignore filter
                fruitsOnInventory = {}
                if Plant and Plant.GetFruitsOnInventory then
                    local allFruits = Plant:GetFruitsOnInventory() or {}
                    -- Filter out ignored fruits
                    for _, fruit in pairs(allFruits) do
                        local fruitName = fruit.Name or "Unknown"
                        if not table.find(ignoreFruits, fruitName) then
                            table.insert(fruitsOnInventory, fruit)
                        end
                    end
                else
                    local backpack = Core:GetBackpack()
                    if backpack then
                        for _, item in pairs(backpack:GetChildren()) do
                            if item:GetAttribute("b") == "j" then
                                local fruitName = item.Name or "Unknown"
                                if not table.find(ignoreFruits, fruitName) then
                                    table.insert(fruitsOnInventory, item)
                                end
                            end
                        end
                    end
                end

                if #fruitsOnInventory == 0 then
                    Window:ShowWarning("Auto Feed Active Pet", "No fruits found on inventory after collecting from garden.")
                    return
                end
            end

            local fruitToUse = fruitsOnInventory[1]
            local feedTaskCompleted = false

            local feedTask = function()
                Window:ShowInfo("Auto Feed Active Pet", "Feeding pet: " .. petDetail.Name .. " (Hunger: " .. string.format("%.2f%%", hungerPercentage) .. ", Threshold: " .. tostring(hungerThreshold) .. "%)")

                local success, response = pcall(function()
                    return Core.ReplicatedStorage.GameEvents.ActivePetService:FireServer("Feed", petId)
                end)

                task.wait(1)

                if not success then
                    Window:ShowError("Auto Feed Active Pet", "Failed to feed pet: " .. tostring(response))
                end
            end

            Player:AddToQueue(
                fruitToUse,               -- tool
                1,                  -- priority (high)
                function()
                    feedTask()
                end,    -- task function
                function()
                    feedTaskCompleted = true
                end -- callback function
            )

            while feedTaskCompleted == false do
                task.wait(1)
            end
        end
    end

    return m
end

-- Module: notification/ui.lua
EmbeddedModules["notification/ui.lua"] = function()
    local m = {}

    local Window
    local Webhook

    -- Store ALL textbox references for config sync after reconnect
    m.TextBoxReferences = {}

    function m:Init(_window, _webhook)
        Window = _window
        Webhook = _webhook
    end

    function m:CreateNotificationTab()
        local tab = Window:AddTab({
            Name = "Notifications",
            Icon = "🔔",
        })

        local webhookURLTextBox = tab:AddTextBox({
            Name = "Discord Webhook URL (for notifications)",
            Default = "",
            Flag = "DiscordWebhookURL",
            Placeholder = "https://discord.com/api/webhooks/...",
            MaxLength = 500,
        })
        m.TextBoxReferences["DiscordWebhookURL"] = webhookURLTextBox

        tab:AddSeparator()

        local pingIDTextBox = tab:AddTextBox({
            Name = "Discord Ping ID (optional)",
            Default = "",
            Flag = "DiscordPingID",
            Placeholder = "123456789012345678",
            MaxLength = 50,
        })
        m.TextBoxReferences["DiscordPingID"] = pingIDTextBox

        tab:AddSeparator()

        tab:AddButton({
            Text = "Send Test",
            Callback = function()
                task.spawn(function()
                    Webhook:TestWebhook()
                end)
            end
        })
    end

    -- Function to refresh all textbox UI states from config
    function m:RefreshTextBoxStates()
        if not Window then
            warn("NotificationUI:RefreshTextBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, textBoxAPI in pairs(self.TextBoxReferences) do
            local success, err = pcall(function()
                if textBoxAPI and textBoxAPI.SetText then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        textBoxAPI:SetText(configValue)
                        print(string.format("  ✓ [Notification] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Notification] %s - TextBox API missing SetText method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Notification] %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("[NOTIFICATION] Refreshed %d textboxes successfully", refreshedCount))
        return refreshedCount
    end

    return m
end

-- Module: ../module/core.lua
EmbeddedModules["../module/core.lua"] = function()
    local m = {}

    local Window

    local IsAutoExecuteOnJoin = true
    local IsHasQueueOnTeleport = false

    function m:Init(_window)
        Window = _window

        IsAutoExecuteOnJoin = Window:GetConfigValue("AutoExecuteScriptsOnJoin") or true
    end

    -- Services
    m.Players = game:GetService("Players")
    m.ReplicatedStorage = game:GetService("ReplicatedStorage")
    m.TeleportService = game:GetService("TeleportService")
    m.UserInputService = game:GetService("UserInputService")
    m.GuiService = game:GetService("GuiService")
    m.Workspace = game:GetService("Workspace")
    m.VirtualUser = game:GetService("VirtualUser")
    m.MarketplaceService = game:GetService("MarketplaceService")
    m.PlaceId = game.PlaceId
    m.JobId = game.JobId
    m.IsWindowOpen = false

    -- Player reference
    m.LocalPlayer = m.Players.LocalPlayer
    m.HttpService = game:GetService("HttpService")

    function m:GetPlayerByName(name)
        for _, player in pairs(self.Players or {}) do
            if player.Name:lower() == name:lower() then
                return player
            end
        end
        return nil
    end

    function m:GetPlayerById(userId)
        for _, player in pairs(self.Players or {}) do
            if player.UserId == userId then
                return player
            end
        end
        return nil
    end

    function m:GetServers(cursor)
        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100",
            self.PlaceId
        )

        if cursor then
            url = url .. "&cursor=" .. cursor
        end

        local success, result = pcall(function()
            return self.HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success then
            return result
        else
            warn("Failed to fetch server data:", result)
            return nil
        end
    end

    -- Dynamic getters
    function m:GetCharacter()
        return self.LocalPlayer.Character
    end

    function m:GetHumanoid()
        local char = self:GetCharacter()
        return char and char:FindFirstChildOfClass("Humanoid") or nil
    end

    function m:GetHumanoidRootPart()
        local char = self:GetCharacter()
        return char and char:FindFirstChild("HumanoidRootPart") or nil
    end

    function m:GetBackpack()
        return self.LocalPlayer:FindFirstChild("Backpack")
    end

    function m:GetPlayerGui()
        return self.LocalPlayer:FindFirstChild("PlayerGui")
    end

    function m:Rejoin()
        if not self.PlaceId or not self.JobId then
            warn("Core:Rejoin - PlaceId or JobId is nil, cannot rejoin.")
            return
        end

        -- Refresh config value before deciding
        IsAutoExecuteOnJoin = Window:GetConfigValue("AutoExecuteScriptsOnJoin")
        if IsAutoExecuteOnJoin == nil then
            IsAutoExecuteOnJoin = true
        end

        -- If player is alone on server, just teleport to any server (JobId might be invalid/closing)
        local IsSingle = #self.Players:GetPlayers() <= 1
        if IsSingle then
            if IsAutoExecuteOnJoin and not IsHasQueueOnTeleport then
                queue_on_teleport("loadstring(game:HttpGet('https://api.pandorahub.net/loader.lua'))()")
                IsHasQueueOnTeleport = true
            end
            self.TeleportService:Teleport(self.PlaceId, self.LocalPlayer)
            return
        end

        -- Save current scripts to re-execute after teleport
        if IsAutoExecuteOnJoin and not IsHasQueueOnTeleport then
            queue_on_teleport("loadstring(game:HttpGet('https://api.pandorahub.net/loader.lua'))()")
            IsHasQueueOnTeleport = true
        end

        -- Private server: just teleport back to same place
        if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
            self.TeleportService:Teleport(self.PlaceId, self.LocalPlayer)
            return
        end

        self.TeleportService:TeleportToPlaceInstance(self.PlaceId, self.JobId, self.LocalPlayer)
    end

    function m:HopServer()
        -- Save current scripts to re-execute after teleport
        if IsAutoExecuteOnJoin and not IsHasQueueOnTeleport then
            queue_on_teleport("loadstring(game:HttpGet('https://api.pandorahub.net/loader.lua'))()")
            IsHasQueueOnTeleport = true
        end

        if self.PlaceId then
            self.TeleportService:Teleport(self.PlaceId, self.LocalPlayer)
        else
            warn("Core:HopServer - PlaceId is nil, cannot hop server.")
        end
    end

    function m:StringToCFrame(str)
        local cframePosition = CFrame.new(0.0, 0.0, 0.0)

        local values = string.split(str, ",")
        for i, v in ipairs(values) do
            values[i] = tonumber(v)
        end

        if #values == 3 then
            cframePosition = CFrame.new(Vector3.new(values[1], values[2], values[3]))
        elseif #values == 12 then
            cframePosition = CFrame.new(
                values[1], values[2], values[3],
                values[4], values[5], values[6],
                values[7], values[8], values[9],
                values[10], values[11], values[12]
            )
        else
            warn("Position string is invalid.")
            return nil
        end

        return cframePosition
    end

    function m:FormatNumber(number)
        local is_integer = (number == math.floor(number))

        local int_part, dec_part

        if is_integer then
            int_part = tostring(math.floor(number))
        else
            -- Untuk desimal, format dengan 2 digit di belakang koma
            local formatted = string.format("%.2f", number)
            int_part, dec_part = formatted:match("^(-?%d+)%.(%d+)$")
        end

        local k
        while true do  
            int_part, k = int_part:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
            if k == 0 then break end
        end

        if dec_part then
            return int_part .. "," .. dec_part
        else
            return int_part
        end
    end

    function m:FormatChance(chance)
        if chance <= 0 then return "impossible" end
        local odds = 1 / chance

        local suffixes = {
            {1e9, "B"},
            {1e6, "M"},
            {1e3, "K"},
        }

        for _, s in ipairs(suffixes) do
            local div, label = s[1], s[2]
            if odds >= div then
                return string.format("1 in %.1f%s", odds / div, label)
            end
        end

        return string.format("1 in %.1f", odds)
    end

    function m:FormatTime(seconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local secs = math.floor(seconds % 60)

        local timeParts = {}
        if hours > 0 then
            table.insert(timeParts, string.format("%dh", hours))
        end
        if minutes > 0 then
            table.insert(timeParts, string.format("%dm", minutes))
        end
        if secs > 0 or #timeParts == 0 then
            table.insert(timeParts, string.format("%ds", secs))
        end

        return table.concat(timeParts, " ")
    end

    -- Table to track active loops
    local activeLoops = {}

    function m:MakeLoop(_isEnableFunc, _func, _delay)
        local function resolveDelay()
            if type(_delay) == "function" then
                return _delay()
            end
            return _delay or 3 -- Ensure default delay is applied
        end

        local loop = coroutine.create(function()
            while self.IsWindowOpen do
                local isEnabled = false

                -- Handle both function and direct value
                if type(_isEnableFunc) == "function" then
                    isEnabled = _isEnableFunc()
                else
                    isEnabled = _isEnableFunc
                end

                if not isEnabled then
                    task.wait(1) -- Wait when disabled
                    continue
                end

                _func()
                task.wait(resolveDelay()) -- Use resolved delay
            end
        end)

        table.insert(activeLoops, loop)
        coroutine.resume(loop)
        return loop
    end

    function m:StopAllLoops()
        for _, loop in ipairs(activeLoops) do
            if loop and coroutine.status(loop) ~= "dead" then
                coroutine.close(loop)
            end
        end
        table.clear(activeLoops)
    end

    function m:BroadcastChat(message)
        if not message or type(message) ~= "string" or message == "" then
            warn("BroadcastChat - Invalid message")
            return false
        end

        local success, err = pcall(function()
            game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(message)
        end)

        if not success then
            warn("BroadcastChat - Failed to send message:", err)
            return false
        end

        return true
    end

    return m
end

-- Module: misc/cosmetic.lua
EmbeddedModules["misc/cosmetic.lua"] = function()
    local m = {}

    local Window
    local Core

    local CosmeticService

    function m:Init(_window, _core)
        Core = _core
        Window = _window

        CosmeticService = require(Core.ReplicatedStorage.Modules.CosmeticServices.CosmeticService)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoPlaceCosmetic")
        end, function()
            self:StartAutoPlaceCosmetic()
        end, function()
            return Window:GetConfigValue("IntervalCosmeticPlaceDelay") or 60
        end)
    end

    function m:GetAllCosmetics()
        local cosmetics = CosmeticService:GetAllCosmetics() or {}
        local cosmeticData = {}

        for k, v in pairs(cosmetics) do
            cosmeticData[v.Name] = cosmeticData[v.Name] or {
                Name = v.Name,
                Equipped = {},
                OnInventory = {},
            }

            if CosmeticService:IsCosmeticEquipped(k) then
                table.insert(cosmeticData[v.Name].Equipped, k)
            else
                table.insert(cosmeticData[v.Name].OnInventory, k)
            end
        end

        table.sort(cosmeticData, function(a, b)
            return a.Name < b.Name
        end)

        return cosmeticData
    end

    function m:StartAutoPlaceCosmetic()
        if not Window:GetConfigValue("AutoPlaceCosmetic") then
            return
        end

        local selectedCosmetics = Window:GetConfigValue("CosmeticToPlace") or {}

        if not selectedCosmetics or #selectedCosmetics == 0 then
            Window:ShowWarning("Cosmetic", "Please select a cosmetic to place.")
            return
        end

        local allCosmetics = self:GetAllCosmetics()
        local totalToPlace = Window:GetConfigValue("TotalEachCosmeticToPlace") or 1

        for _, cosmeticName in pairs(selectedCosmetics) do
            local cosmeticData = allCosmetics[cosmeticName]
            if not cosmeticData then
                Window:ShowWarning("Cosmetic", "Cosmetic '" .. cosmeticName .. "' not found in inventory.")
            end
            local totalAvailable = #cosmeticData.OnInventory + #cosmeticData.Equipped
            local min = math.min(totalToPlace, totalAvailable)
            Window:ShowInfo("Cosmetic", "Placing: " .. cosmeticName .. " " .. min .. "x")

            local hasPlaced = 0
            for _, id in pairs(cosmeticData.Equipped or {}) do
                if hasPlaced >= totalToPlace then
                    break
                end

                Core.ReplicatedStorage.GameEvents.CosmeticService:FireServer("Unequip", id)
                task.wait(0.01) -- Small delay to ensure unequip
                Core.ReplicatedStorage.GameEvents.CosmeticService:FireServer("Equip", id)
                task.wait(0.01) -- Small delay to ensure equip

                hasPlaced = hasPlaced + 1
            end

            for _, id in pairs(cosmeticData.OnInventory or {}) do
                if hasPlaced >= totalToPlace then
                    break
                end

                Core.ReplicatedStorage.GameEvents.CosmeticService:FireServer("Equip", id)
                task.wait(0.01) -- Small delay to ensure equip

                hasPlaced = hasPlaced + 1
            end
        end
    end

    return m
end

-- Module: farm/garden.lua
EmbeddedModules["farm/garden.lua"] = function()
    local m = {}
    local Window
    local Core
    local Player
    local AutoHarvestThread
    local AutoHarvesting = false
    local BackpackConnection
    local PlantConnection
    local WateringConnection
    local PlantsLocation
    m.MailboxPosition = Vector3.new(0, 0, 0)

    function m:Init(_window, _core, _player)
        Window = _window
        Core = _core
        Player = _player

        local important = self:GetMyFarm():FindFirstChild("Important")
        PlantsLocation = important:FindFirstChild("Plant_Locations")

        local mailbox = self:GetMyFarm():FindFirstChild("Mailbox")
        if mailbox then
            m.MailboxPosition = mailbox:GetPivot().Position
        end

    end

    function m:GetMyFarm()
    	local farms = Core.Workspace.Farm:GetChildren()

    	for _, farm in next, farms do
            local important = farm.Important
            local data = important.Data
            local owner = data.Owner

    		if owner.Value == Core.LocalPlayer.Name then
    			return farm
    		end
    	end
    end

    function m:GetArea(_base)
        local center = _base:GetPivot()
    	local size = _base.Size

    	-- Bottom left
    	local x1 = math.ceil(center.X - (size.X/2))
    	local z1 = math.ceil(center.Z - (size.Z/2))

    	-- Top right
    	local x2 = math.floor(center.X + (size.X/2))
    	local z2 = math.floor(center.Z + (size.Z/2))

    	return x1, z1, x2, z2
    end

    function m:GetFarmCenterPosition()
        local farmParts = PlantsLocation:GetChildren()
        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        -- Calculate center from all farm parts
        local totalX, totalZ = 0, 0
        local totalY = 4 -- Default height for farm
        local partCount = 0

        for _, part in pairs(farmParts) do
            if part:IsA("BasePart") then
                local pos = part.Position
                totalX = totalX + pos.X
                totalZ = totalZ + pos.Z
                totalY = math.max(totalY, pos.Y + part.Size.Y/2) -- Use highest Y position
                partCount = partCount + 1
            end
        end

        if partCount > 0 then
            local centerX = totalX / partCount
            local centerZ = totalZ / partCount
            return Vector3.new(centerX, totalY, centerZ)
        end
    end

    function m:GetFarmCenterLeftPosition()
        local farmParts = PlantsLocation:GetChildren()
        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        return farmLand:GetPivot().Position
    end

    function m:GetFarmCenterRightPosition()
        local farmParts = PlantsLocation:GetChildren()
        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        return farmLand:GetPivot().Position
    end

    function m:GetFarmFrontRightPosition()
        local farmParts = PlantsLocation:GetChildren()

        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if  m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        local x1, z1, x2, z2 = self:GetArea(farmLand)

        local x = math.max(x1, x2)
        local z = math.max(z1, z2)

        if m.MailboxPosition.Z > 0 then
            x = math.min(x1, x2)
            z = math.min(z1, z2)
        end

        return Vector3.new(x, 4, z)
    end

    function m:GetFarmFrontLeftPosition()
        local farmParts = PlantsLocation:GetChildren()

        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if  m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        local x1, z1, x2, z2 = self:GetArea(farmLand)

        local x = math.min(x1, x2)
        local z = math.max(z1, z2)

        if m.MailboxPosition.Z > 0 then
            x = math.max(x1, x2)
            z = math.min(z1, z2)
        end

        return Vector3.new(x, 4, z)
    end

    function m:GetFarmBackRightPosition()
        local farmParts = PlantsLocation:GetChildren()
        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if  m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        local x1, z1, x2, z2 = self:GetArea(farmLand)

        local x = math.max(x1, x2)
        local z = math.min(z1, z2)

        if m.MailboxPosition.Z > 0 then
            x = math.min(x1, x2)
            z = math.max(z1, z2)
        end

        return Vector3.new(x, 4, z)
    end

    function m:GetFarmBackLeftPosition()
        local farmParts = PlantsLocation:GetChildren()
        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if  m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        local x1, z1, x2, z2 = self:GetArea(farmLand)

        local x = math.min(x1, x2)
        local z = math.min(z1, z2)

        if m.MailboxPosition.Z > 0 then
            x = math.max(x1, x2)
            z = math.max(z1, z2)
        end

        return Vector3.new(x, 4, z)
    end

    function m:GetFarmRandomPosition()
        local farmParts = PlantsLocation:GetChildren()

        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local FarmLand = farmParts[math.random(1, #farmParts)]

        local x1, z1, x2, z2 = self:GetArea(FarmLand)
        local x = math.random(x1, x2)
        local z = math.random(z1, z2)

        return Vector3.new(x, 4, z)
    end

    function m:GetFarmInsideCenterLeftPosition()
        local farmParts = PlantsLocation:GetChildren()
        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        local x1, z1, x2, z2 = self:GetArea(farmLand)

        local x = math.min(x1, x2)
        local z = math.floor((z1 + z2) / 2)

        if m.MailboxPosition.Z > 0 then
            x = math.max(x1, x2)
        end

        return Vector3.new(x, 4, z)
    end

    function m:GetFarmInsideCenterRightPosition()
        local farmParts = PlantsLocation:GetChildren()
        if #farmParts < 1 then
            return Vector3.new(0, 4, 0)
        end

        local farmLand = farmParts[1]
        if m.MailboxPosition.Z > 0 then
            if farmParts[1]:GetPivot().X < farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        else
            if farmParts[1]:GetPivot().X > farmParts[2]:GetPivot().X then
                farmLand = farmParts[2]
            end
        end

        local x1, z1, x2, z2 = self:GetArea(farmLand)

        local x = math.max(x1, x2)
        local z = math.floor((z1 + z2) / 2)

        if m.MailboxPosition.Z > 0 then
            x = math.min(x1, x2)
        end

        return Vector3.new(x, 4, z)
    end

    -- Performance: Get all farms
    function m:GetAllFarms()
        return Core.Workspace.Farm:GetChildren()
    end

    -- Performance: Hide/Show plants in a specific farm
    function m:SetFarmPlantsVisibility(farm, visible)
        if not farm then return end

        local important = farm:FindFirstChild("Important")
        if not important then return end

        local plantsPhysical = important:FindFirstChild("Plants_Physical")
        if not plantsPhysical then return end

        for _, plant in pairs(plantsPhysical:GetDescendants()) do
            if plant:IsA("BasePart") then
                plant.Transparency = visible and 0 or 1
            elseif plant:IsA("Decal") or plant:IsA("Texture") then
                plant.Transparency = visible and 0 or 1
            elseif plant:IsA("ParticleEmitter") or plant:IsA("Trail") or plant:IsA("Beam") then
                plant.Enabled = visible
            elseif plant:IsA("BillboardGui") or plant:IsA("SurfaceGui") then
                plant.Enabled = visible
            end
        end
    end

    -- Performance: Hide/Show objects (sprinklers, decorations) in a specific farm
    function m:SetFarmObjectsVisibility(farm, visible)
        if not farm then return end

        local important = farm:FindFirstChild("Important")
        if not important then return end

        local objectsPhysical = important:FindFirstChild("Objects_Physical")
        if not objectsPhysical then return end

        for _, obj in pairs(objectsPhysical:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Transparency = visible and 0 or 1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = visible and 0 or 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = visible
            elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                obj.Enabled = visible
            end
        end
    end

    -- Performance: Hide my garden plants
    function m:HideMyGardenPlants()
        local myFarm = self:GetMyFarm()
        if myFarm then
            self:SetFarmPlantsVisibility(myFarm, false)
        end
    end

    -- Performance: Show my garden plants
    function m:ShowMyGardenPlants()
        local myFarm = self:GetMyFarm()
        if myFarm then
            self:SetFarmPlantsVisibility(myFarm, true)
        end
    end

    -- Performance: Hide other players' garden plants
    function m:HideOtherGardenPlants()
        local myFarm = self:GetMyFarm()
        local allFarms = self:GetAllFarms()

        for _, farm in pairs(allFarms) do
            if farm ~= myFarm then
                self:SetFarmPlantsVisibility(farm, false)
            end
        end
    end

    -- Performance: Show other players' garden plants
    function m:ShowOtherGardenPlants()
        local myFarm = self:GetMyFarm()
        local allFarms = self:GetAllFarms()

        for _, farm in pairs(allFarms) do
            if farm ~= myFarm then
                self:SetFarmPlantsVisibility(farm, true)
            end
        end
    end

    -- Performance: Hide my garden objects
    function m:HideMyGardenObjects()
        local myFarm = self:GetMyFarm()
        if myFarm then
            self:SetFarmObjectsVisibility(myFarm, false)
        end
    end

    -- Performance: Show my garden objects
    function m:ShowMyGardenObjects()
        local myFarm = self:GetMyFarm()
        if myFarm then
            self:SetFarmObjectsVisibility(myFarm, true)
        end
    end

    -- Performance: Hide other players' garden objects
    function m:HideOtherGardenObjects()
        local myFarm = self:GetMyFarm()
        local allFarms = self:GetAllFarms()

        for _, farm in pairs(allFarms) do
            if farm ~= myFarm then
                self:SetFarmObjectsVisibility(farm, false)
            end
        end
    end

    -- Performance: Show other players' garden objects
    function m:ShowOtherGardenObjects()
        local myFarm = self:GetMyFarm()
        local allFarms = self:GetAllFarms()

        for _, farm in pairs(allFarms) do
            if farm ~= myFarm then
                self:SetFarmObjectsVisibility(farm, true)
            end
        end
    end

    -- Performance: Setup connection to auto-hide new plants
    function m:SetupPlantHidingConnection(hideMyPlants, hideOtherPlants, hideMyObjects, hideOtherObjects)
        local myFarm = self:GetMyFarm()
        local allFarms = self:GetAllFarms()

        -- Hide plants on new descendants added
        for _, farm in pairs(allFarms) do
            local important = farm:FindFirstChild("Important")
            if important then
                local plantsPhysical = important:FindFirstChild("Plants_Physical")
                local objectsPhysical = important:FindFirstChild("Objects_Physical")

                if plantsPhysical then
                    plantsPhysical.DescendantAdded:Connect(function(descendant)
                        local isMyFarm = (farm == myFarm)
                        local shouldHide = (isMyFarm and hideMyPlants) or (not isMyFarm and hideOtherPlants)

                        if shouldHide then
                            task.wait(0.1) -- Small delay to ensure part is fully loaded
                            if descendant:IsA("BasePart") then
                                descendant.Transparency = 1
                            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                                descendant.Transparency = 1
                            elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
                                descendant.Enabled = false
                            elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
                                descendant.Enabled = false
                            end
                        end
                    end)
                end

                if objectsPhysical then
                    objectsPhysical.DescendantAdded:Connect(function(descendant)
                        local isMyFarm = (farm == myFarm)
                        local shouldHide = (isMyFarm and hideMyObjects) or (not isMyFarm and hideOtherObjects)

                        if shouldHide then
                            task.wait(0.1)
                            if descendant:IsA("BasePart") then
                                descendant.Transparency = 1
                            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                                descendant.Transparency = 1
                            elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Beam") then
                                descendant.Enabled = false
                            elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
                                descendant.Enabled = false
                            end
                        end
                    end)
                end
            end
        end
    end

    return m
end

-- Module: shop/egg.lua
EmbeddedModules["shop/egg.lua"] = function()
    local m = {}

    local Window
    local Core

    local ShopData
    local DataService

    function m:Init(_window, _core)
        Window = _window
        Core = _core


        DataService = require(Core.ReplicatedStorage.Modules.DataService)
        ShopData = require(Core.ReplicatedStorage.Data.PetEggData)

        _core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuyEggs")
        end, function()
            self:StartBuyEgg()
        end)
    end

    function m:GetItemRepository()
        return ShopData or {}
    end

    function m:GetStock(itemName)
        local shopData = DataService:GetData()
        local stock = 0
        if not shopData then
            warn("No shop data found")
            return stock
        end

        for _, data in shopData.PetEggStock.Stocks do
            if data.EggName == itemName then
                stock = stock + data.Stock
            end
        end

        return stock
    end

    function m:GetAvailableItems()
        local availableItems = {}
        local items = self:GetItemRepository()

        for itemName, _ in pairs(items) do
            local stock = self:GetStock(itemName)
            availableItems[itemName] = stock
        end

        return availableItems
    end

    function m:StartBuyEgg()
        if not Window:GetConfigValue("AutoBuyEggs") then
            return
        end

        local ignoreItems = Window:GetConfigValue("IgnoreEggItems") or {}
        for eggName, stock in pairs(self:GetAvailableItems()) do
            if stock <= 0 or table.find(ignoreItems, eggName) then
                continue
            end
            for i=1, stock do
                 Core.ReplicatedStorage.GameEvents.BuyPetEgg:FireServer(eggName)
                 task.wait(0.15)
            end
        end
    end

    return m
end

-- Module: pet/webhook.lua
EmbeddedModules["pet/webhook.lua"] = function()
    local m = {}

    local Window
    local Core
    local Discord

    local WEBHOOK_USERNAME = "jordi_galer  Hub"
    local WEBHOOK_AVATAR = "https://i.ibb.co.com/5X81cGVH/pandorahub-removebg-preview.png"
    local HEAVY_HATCH_WEBHOOK_URL = "https://discord.com/api/webhooks/1451326910184292436/QEqdOJhUcjLj6G7cJKQ4OHWoghMFUSaFCpD65N9e8ErYi9yLRfHryzpn7gEtv2-WdrLa"
    local HEAVY_HATCH_WEIGHT_THRESHOLD = 6
    local DIVINE_HATCH_WEBHOOK_URL = "https://discord.com/api/webhooks/1451395630147834063/8eCnfUfZIrpRuNUvSXC6x_v1XcYki0TKDeHyVcBgixQJEHz-wlwL6cyg5ebw_i9ehDlJ"
    local DIVINE_HATCH_WEIGHT_THRESHOLD = 4
    local DIVINE_RARITY_THRESHOLD = 5 -- Divine = 6, Prismatic = 7, Transcendent = 8

    local PlayerName
    local LastHatchTime = 0
    local HatchCount = {}
    local HatchTotal = {}
    local InitialStockEgg = {}
    local TotalLuckyHatch = 0
    local TotalLuckySell = 0
    local DataService
    local Rarity

    -- Helper function untuk mendapatkan waktu saat ini
    local function GetTime()
        -- Format: • Month Date | Hour:Minute AM/PM
        -- Contoh: • November 18 | 10:30 PM
        return "• " .. os.date("%B %d") .. " | " .. os.date("%I:%M %p")
    end

    function m:Init(_window, _core, _discord, _rarity)
        Window = _window
        Core = _core
        Discord = _discord
        Rarity = _rarity

        PlayerName = Core.LocalPlayer.Name or "Unknown"
        LastHatchTime = tick()
        DataService = require(Core.ReplicatedStorage.Modules.DataService)
    end

    function m:HatchEgg(_petName, _eggName, _baseWeight)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""

        if url == "" then
            return
        end

        -- Get pet rarity from PetRegistry
        local petRarity = "Unknown"
        local success, petRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry)
        end)

        if success and petRegistry and petRegistry.PetList then
            local petData = petRegistry.PetList[_petName]
            if petData then
                petRarity = petData.Rarity or "Unknown"
            end
        end

        local weightIncrement = _baseWeight * 0.1
        local baseweight1 = _baseWeight + (1 * weightIncrement)
        local bronto = (baseweight1 * 0.3) + baseweight1

        local weightStatus = (
            (_baseWeight >= 8 and "Titanic") or
            (_baseWeight >= 5 and _baseWeight < 8 and "Semi Titanic") or
            (_baseWeight >= 3 and _baseWeight < 5 and "Huge") or
            "Small"
        )

       local message = {
            username = WEBHOOK_USERNAME,       
            avatar_url = WEBHOOK_AVATAR,       
            content = pingId ~= "" and ("<@"..pingId..">") or ("@everyone"),
            embeds = {{
                title = "**jordi_galerHub — Hatch Alerts**", -- Typo fixed: Alrets -> Alerts
                type = 'rich',
                color = tonumber("0xFFD700"), 
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = "**Hatched : **",
                    value = "> 🐾 Pet Name: ``".._petName.."``"..
                           "\n> 🥚 Hatched From: ``"..(_eggName or "N/A").."``"..
                           '\n> ✨ Rarity: ``'..petRarity..'``'..
                           '\n> ⚖️ Weight: ``'..(baseweight1 and string.format("%.2f", baseweight1).." KG" or "N/A")..'``'..
                           "\n> 📊 Status: ``"..weightStatus.."``"..
                           '\n> 🦕 Bronto: ``'..(bronto and string.format("%.2f", bronto).." KG" or "N/A")..'``', -- Fixed syntax here
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR 
                }
            }}
        }

        Discord:SendMessage(url, message)
    end

    function m:HeavyHatchWebhook(_petName, _eggName, _baseWeight)
        -- Only send webhook if base weight is above threshold (6kg)
        if _baseWeight < HEAVY_HATCH_WEIGHT_THRESHOLD then
            return
        end

        -- Get pet rarity from PetRegistry
        local petRarity = "Unknown"
        local success, petRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry)
        end)

        if success and petRegistry and petRegistry.PetList then
            local petData = petRegistry.PetList[_petName]
            if petData then
                petRarity = petData.Rarity or "Unknown"
            end
        end

        local weightIncrement = _baseWeight * 0.1
        local baseweight1 = _baseWeight + (1 * weightIncrement)
        local bronto = (baseweight1 * 0.3) + baseweight1

        local weightStatus = (
            (_baseWeight >= 8 and "Titanic") or
            (_baseWeight >= 6 and _baseWeight < 8 and "Semi Titanic") or
            (_baseWeight >= 5 and _baseWeight < 6 and "Heavy") or
            "Normal"
        )

        local message = {
            username = WEBHOOK_USERNAME,
            avatar_url = WEBHOOK_AVATAR,
            content = "",
            embeds = {{
                title = "**🏹 Hunting Hatch Alert!!**",
                type = 'rich',
                color = tonumber("0x8B0000"),
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ``'..string.sub(PlayerName, 1, 4).."****"..'``',
                    inline = false
                }, {
                    name = "**Hatched Pet : **",
                    value = "> 🐾 Pet Name: ``".._petName.."``"..
                           "\n> 🥚 Hatched From: ``"..(_eggName or "N/A").."``"..
                           '\n> ✨ Rarity: ``'..petRarity..'``'..
                           '\n> ⚖️ Base Weight: ``'..string.format("%.2f", _baseWeight).." KG"..'``'..
                           '\n> 📈 Weight +1 Age: ``'..string.format("%.2f", baseweight1).." KG"..'``'..
                           "\n> 📊 Status: ``"..weightStatus.."``"..
                           '\n> 🦕 Bronto Potential: ``'..string.format("%.2f", bronto).." KG"..'``',
                    inline = false
                }},
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }

        Discord:SendMessage(HEAVY_HATCH_WEBHOOK_URL, message)
    end

    function m:DivineHatchWebhook(_petName, _eggName, _baseWeight)
        -- Whitelist pet yang diperbolehkan
        local allowedPets = {
            ["Mimic Octopus"] = true,
            ["Raccoon"] = true,
            ["Kitsune"] = true
        }

        -- Filter: hanya pet yang ada di whitelist dengan base weight >= 4kg
        if not allowedPets[_petName] or _baseWeight < DIVINE_HATCH_WEIGHT_THRESHOLD then
            return
        end

        -- Get pet rarity from PetRegistry
        local petRarity = "Unknown"
        local rarityOrder = 0
        local success, petRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry)
        end)

        if success and petRegistry and petRegistry.PetList then
            local petData = petRegistry.PetList[_petName]
            if petData then
                petRarity = petData.Rarity or "Unknown"
                -- Get rarity order number
                if Rarity and Rarity.RarityOrder then
                    rarityOrder = Rarity.RarityOrder[petRarity] or 0
                end
            end
        end

        local weightIncrement = _baseWeight * 0.1
        local baseweight1 = _baseWeight + (1 * weightIncrement)
        local bronto = (baseweight1 * 0.3) + baseweight1

        local weightStatus = (
            (_baseWeight >= 8 and "Titanic") or
            (_baseWeight >= 6 and _baseWeight < 8 and "Semi Titanic") or
            (_baseWeight >= 4 and _baseWeight < 6 and "Heavy") or
            "Normal"
        )

        local message = {
            username = WEBHOOK_USERNAME,
            avatar_url = WEBHOOK_AVATAR,
            content = "",
            embeds = {{
                title = "**Mukbang Hatch Alert!**",
                type = 'rich',
                color = tonumber("0xFFD700"), -- Gold color
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ``'..string.sub(PlayerName, 1, 4).."****"..'``',
                    inline = false
                }, {
                    name = "**Hatched Pet : **",
                    value = "> 🐾 Pet Name: ``".._petName.."``"..
                           "\n> 🥚 Hatched From: ``"..(_eggName or "N/A").."``"..
                           '\n> ✨ Rarity: ``'..petRarity..'``'..
                           '\n> ⚖️ Base Weight: ``'..string.format("%.2f", _baseWeight).." KG"..'``'..
                           '\n> 📈 Weight +1 Age: ``'..string.format("%.2f", baseweight1).." KG"..'``'..
                           "\n> 📊 Status: ``"..weightStatus.."``"..
                           '\n> 🦕 Bronto Potential: ``'..string.format("%.2f", bronto).." KG"..'``',
                    inline = false
                }},
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }

        Discord:SendMessage(DIVINE_HATCH_WEBHOOK_URL, message)
    end

    function m:Statistics(_eggName, _amount, _hatchedEgg, _totalPet, _luckyHatch, _luckySell, _cycleHatchCounter, _sellOnCycleHatchCount)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local gameData = DataService:GetData()

        -- Set default values for cycle parameters
        _cycleHatchCounter = _cycleHatchCounter or 0
        _sellOnCycleHatchCount = _sellOnCycleHatchCount or 1

        if url == "" then
            return
        end

        if InitialStockEgg[_eggName] == nil then
            InitialStockEgg[_eggName] = _amount
        end

        HatchCount[_eggName] = (HatchCount[_eggName] or 0) + 1
        HatchTotal[_eggName] = (HatchTotal[_eggName] or 0) + _hatchedEgg

        -- Track cumulative lucky hatch/sell totals
        TotalLuckyHatch = TotalLuckyHatch + (_luckyHatch or 0)

        local petsInventoryCapcity = 0
        for key, value in pairs(gameData.GardenCoinShopStats.LifetimePurchases or {}) do
            if string.find(string.lower(key), "pet inventory capacity") then
                petsInventoryCapcity = petsInventoryCapcity + (value * 10)
            end
        end

        local petPounchUses = gameData.PetsData.PetPounchUses or 0
        local purchasePetInventorySlot = (gameData.PetsData.PurchasePetInventory or 0) * 5
        local totalMaxInventoryPet = 60 + petPounchUses + purchasePetInventorySlot + petsInventoryCapcity

        -- Check if cycle is enabled and if this is the last cycle
        local isCycleEnabled = _sellOnCycleHatchCount > 1
        -- Last cycle is when counter reaches the threshold (e.g., 3/3), not after reset (0/3)
        local isLastCycle = _cycleHatchCounter >= _sellOnCycleHatchCount

        -- Show lucky sell on last cycle or when cycle is disabled
        local shouldShowLuckySell = not isCycleEnabled or isLastCycle
        local luckySellDisplay = shouldShowLuckySell and tostring(_luckySell or 'N/A') or "Skipped"
        local totalRecoveryEgg = (_luckyHatch or 0) + (shouldShowLuckySell and (_luckySell or 0) or 0)

        -- Track cumulative lucky sell only when selling
        if shouldShowLuckySell then
            TotalLuckySell = TotalLuckySell + (_luckySell or 0)
        end

        -- Get server/game version
        local serverVersion = "N/A"
        pcall(function()
            serverVersion = tostring(game.PlaceVersion)
        end)

        local message = {
            username = WEBHOOK_USERNAME,
            avatar_url = WEBHOOK_AVATAR,
            content = "",
            embeds = {{
                title = "**jordi_galer  Hub — Hatch Summary**",
                type = 'rich',
                color = tonumber("0x8B0000"), -- Blood Moon color (dark crimson red)
                fields = {{
                    name = '**Profile : ** \n',
                    value = "> 👤 Username : ||"..PlayerName.."||"..
                    '\n> 🥚 Egg Name: ``'..(_eggName or"N/A").."``"..
                    '\n> 🎒 Pet on backpack: ``'..(_totalPet or"N/A").."/"..totalMaxInventoryPet.."``"..
                    '\n> 🌐 Server Version: ``'..serverVersion.."``",

                    inline = false
                }, {
                    name = "**Egg Statistics : **",
                    value = (function()
                        local netResult = _amount - (InitialStockEgg[_eggName] or _amount)

                        return "> 📦 Egg Before: ``"..(tostring(InitialStockEgg[_eggName]) or 'N/A').."``"..
                               '\n> 📊 Current Amount: ``'..(tostring(_amount) or 'N/A').."``"..
                               '\n> 📈 Net Result: ``'..tostring(netResult).."``"..
                               '\n> 🍀 Lucky Hatch: ``'..(tostring(_luckyHatch) or 'N/A').."``"..
                               '\n> 💰 Lucky Sell: ``'..luckySellDisplay.."``"..
                               '\n> ✨ Total Recovery Egg: ``'..(tostring(totalRecoveryEgg) or 'N/A').."``"
                    end)(),
                    inline = false
                },{
                    name = "**Hatch Statistics : **",
                    value = '> 🔁 Hatch Cycles: ``'..(tostring(HatchCount[_eggName]) or 'N/A')..'``'..
                            '\n> 🐣 Total Hatched: ``'..(tostring(HatchTotal[_eggName]) or 'N/A')..'``'..
                            '\n> ⏱️ Duration: ``'..string.format("%d Minutes %d Seconds", math.floor((tick() - LastHatchTime) / 60), math.floor((tick() - LastHatchTime) % 60))..'``'..
                            (isCycleEnabled and ('\n> ⚙️ Sell Cycle Hatch: ``'.._cycleHatchCounter..' / '.._sellOnCycleHatchCount..'``') or ''),
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }

        LastHatchTime = tick()
        Discord:SendMessage(url, message)
    end

    function m:NightmareMutation(_petType, _remains)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""
        _remains = _remains or 0

        if url == "" then
            return
        end

        local pingContent = ""

        if _remains <= 0 then
            pingContent = pingId ~= "" and ("<@"..pingId..">") or ("@everyone")
        end

        local message = {
            username = WEBHOOK_USERNAME,      
            avatar_url = WEBHOOK_AVATAR,       
            content = pingContent, 
            embeds = {{
                title = "**jordi_galer  Hub**",
                type = 'rich',
                color = tonumber("0x8B00FF"),
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = "**Nightmare Mutation : **",
                    value = "> Pet Type: ``"..(_petType or"N/A").."``"..
                           "\n> Remains Queue: ``"..(_remains or"N/A").."``",
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }
        Discord:SendMessage(url, message)
    end

    function m:Leveling(_petName, _petLevel, _remains)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""
        _remains = _remains or 0

        if url == "" then
            return
        end

        local pingContent = ""

        if _remains <= 0 then
            pingContent = pingId ~= "" and ("<@"..pingId..">") or ("@everyone")
        end

        local message = {
            username = WEBHOOK_USERNAME,       
            avatar_url = WEBHOOK_AVATAR,       
            content = pingContent, 
            embeds = {{
                title = "**jordi_galer  Hub**",
                type = 'rich',
                color = tonumber("0x00FF00"),
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = "**Pet has reached to level : " ..(_petLevel or"N/A").."**",
                    value = "> Pet Name: ``"..(_petName or"N/A").."``"..
                           "\n> Remains Queue: ``"..(_remains or"N/A").."``",
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }
        Discord:SendMessage(url, message)
    end

    function m:Bulking(_petName, _petWeight, _remains)
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""
        _remains = _remains or 0

        if url == "" then
            return
        end

        local pingContent = ""

        if _remains <= 0 then
            pingContent = pingId ~= "" and ("<@"..pingId..">") or ("@everyone")
        end

        local message = {
            username = WEBHOOK_USERNAME,      
            avatar_url = WEBHOOK_AVATAR,       
            content = pingContent, 
            embeds = {{
                title = "**jordi_galer  Hub**",
                type = 'rich',
                color = tonumber("0x0000FF"),
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> 👤 Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = "**Pet has reached to weight : " ..(tonumber(_petWeight) and string.format("%.2f", tonumber(_petWeight)) or "N/A").." KG**",
                    value = "> Pet Name: ``"..(_petName or"N/A").."``"..
                           "\n> Remains Queue: ``"..(_remains or"N/A").."``",
                    inline = false
                }},
                -- TAMBAHAN FOOTER DI SINI
                footer = {
                    text = GetTime(),
                    icon_url = WEBHOOK_AVATAR
                }
            }}
        }
        Discord:SendMessage(url, message)
    end

    return m
end

-- Module: pet/ui.lua
EmbeddedModules["pet/ui.lua"] = function()
    local m = {}
    local Window
    local PetTeam
    local Egg
    local Pet
    local Garden
    local Player
    local Inventory
    local Core
    local Plant

    -- Keep references to toggles so we can sync UI state
    m.ManualNightmareToggle = nil
    m.IdleNightmareToggle = nil

    -- Store ALL toggle references for config sync after reconnect
    m.ToggleReferences = {}
    m.SelectBoxReferences = {}
    m.NumberBoxReferences = {}

    function m:Init(_window, _petTeam, _egg, _pet, _garden, _player, _core, _plant)
        Window = _window
        PetTeam = _petTeam
        Egg = _egg
        Pet = _pet
        Garden = _garden
        Player = _player
        Core = _core
        Plant = _plant

        self:CreatePetTab()
    end

    function m:SetInventoryModule(_inventory)
        Inventory = _inventory
    end

    function m:CreatePetTab()
        local tab = Window:AddTab({
            Name = "Pet",
            Icon = "😺",
        })

        self:AddPetTeamsSection(tab)
        self:AddEggsSection(tab)
        self:AddSellSection(tab)
        self:BoostPetsSection(tab)
        self:AddPickupSection(tab)
        self:SwitchPetSection(tab)
        self:AddGlitchSection(tab)
    end

    function m:AddPetTeamsSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Pet Teams",
            Icon = "🛠️",
            Expanded = false,
        })

        local petTeamName = accordion:AddTextBox({
            Name = "Team Name",
            Placeholder = "Enter team name example: exp, hatch, sell, etc...",
            Default = "",
        })

        accordion:AddButton({Text = "Save Team", Callback = function()

            local teamName = petTeamName.GetText()
            if teamName and teamName ~= "" then
                print("Please enter a valid team name.")

            end

            local activePets = Pet:GetAllActivePets()
            if not activePets then
                print("No active pets found.")
                return
            end

            local listActivePets = {}
            for petID, petState in pairs(activePets) do
                table.insert(listActivePets, petID)
            end

            print("Creating pet team:", teamName)
            PetTeam:SaveTeamPets(teamName, listActivePets)

            petTeamName.Clear()
        end})

        accordion:AddSeparator()

        local selectTeam = accordion:AddSelectBox({
            Name = "Select a pet team to set as core, change, or delete.",
            Options = PetTeam:GetAllPetTeams(),
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                print("Get total pet teams:", #listTeamPet)

                for _, team in pairs(listTeamPet) do
                    print("Found pet team:", team)
                    table.insert(currentOptionsSet, {text = team, value = team})
                end

                updateOptions(currentOptionsSet)
            end
        })

        -- Declare labelCoreTeam variable first (forward declaration)
        local labelCoreTeam

        accordion:AddButton({Text = "Set Core Team", Callback = function()
            local selectedTeam = selectTeam.GetSelected()
            if selectedTeam and #selectedTeam > 0 then
                local teamName = selectedTeam[1]
                Window:SetConfigValue("CorePetTeam", teamName)
                labelCoreTeam:SetText("Current Core Team: " .. teamName)
            end    
        end})

        -- Create the label after the button
        labelCoreTeam = accordion:AddLabel("Current Core Team: " .. (Window:GetConfigValue("CorePetTeam") or "None"))

        accordion:AddSeparator()

        accordion:AddButton({Text = "Change Team", Callback = function()
            local selectedTeam = selectTeam.GetSelected()
            if selectedTeam and #selectedTeam > 0 then
                local teamName = selectedTeam[1]
                Window:ShowInfo("Pet Team", "Changing to pet team: " .. teamName)
                Pet:ChangeTeamPets(teamName, "manual")    
            end
        end})

        accordion:AddButton({
            Text = "Delete Selected Team",
            Variant = "danger",
            Callback = function()
                local selectedTeam = selectTeam.GetSelected()
                if selectedTeam and #selectedTeam > 0 then
                    local teamName = selectedTeam[1]
                    PetTeam:DeleteTeamPets(teamName)
                    selectTeam.Clear()
                end
            end
        })
    end

    function m:AddEggsSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Eggs",
            Icon = "🥚",
            Expanded = false,
        })

        local eggPlacingSelectBox = accordion:AddSelectBox({
            Name = "Select an egg to place in your farm",
            Options = {"Loading..."},
            Placeholder = "Select Egg...",
            MultiSelect = false,
            Flag = "EggPlacing",
            OnInit = function(api, optionsData)
                print("[DEBUG] EggPlacing OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("EggPlacing")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "EggPlacing", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "EggPlacing", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local formattedEggs = {}
                local listdEggs = Egg:GetEggRegistry()

                if listdEggs and type(listdEggs) == "table" then
                    for egg, _ in pairs(listdEggs) do
                        table.insert(formattedEggs, {text = egg, value = egg})
                    end

                    -- Sort eggs alphabetically (ascending order)
                    if #formattedEggs > 0 then
                        table.sort(formattedEggs, function(a, b)
                            if not a or not b or not a.text or not b.text then
                                return false
                            end
                            return string.lower(tostring(a.text)) < string.lower(tostring(b.text))
                        end)
                    end
                end

                updateOptions(formattedEggs)
            end
        })

        -- Store reference immediately after creation
        if eggPlacingSelectBox then
            m.SelectBoxReferences["EggPlacing"] = eggPlacingSelectBox
            print("[DEBUG] Stored EggPlacing SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("EggPlacing")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    eggPlacingSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    eggPlacingSelectBox:Set(savedValue)
                end
            end
        end

        local maxPlaceEggsNumberBox = accordion:AddNumberBox({
            Name = "Max Place Eggs",
            Placeholder = "Enter max eggs...",
            Default = 0,
            Min = 0,
            Max = 13,
            Increment = 1,
            Flag = "MaxPlaceEggs",
        })
        m.NumberBoxReferences["MaxPlaceEggs"] = maxPlaceEggsNumberBox

        local positionToPlaceEggsSelectBox = accordion:AddSelectBox({
            Name = "Position to Place Eggs",
            Options = {"Random", "Front Right", "Front Left", "Back Right", "Back Left", "Center Right", "Center Left"},
            Default = "Random",
            MultiSelect = false,
            Placeholder = "Select position...",
            Flag = "PositionToPlaceEggs",
            OnInit = function(api, optionsData)
                local savedValue = Window:GetConfigValue("PositionToPlaceEggs")
                if savedValue ~= nil and savedValue ~= "" then
                    api:Set(savedValue)
                end
            end,
        })

        if positionToPlaceEggsSelectBox then
            m.SelectBoxReferences["PositionToPlaceEggs"] = positionToPlaceEggsSelectBox
            local savedValue = Window:GetConfigValue("PositionToPlaceEggs")
            if savedValue ~= nil and savedValue ~= "" then
                positionToPlaceEggsSelectBox:Set(savedValue)
            end
        end

        accordion:AddButton({Text = "Place Selected Egg", Callback = function()
            Egg:PlacingEgg()    
        end})

        accordion:AddSeparator()

        local hatchPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Pet Team for Hatch",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "HatchPetTeam",
            OnInit = function(api, optionsData)
                print("[DEBUG] HatchPetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("HatchPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "HatchPetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "HatchPetTeam", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end

                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if hatchPetTeamSelectBox then
            m.SelectBoxReferences["HatchPetTeam"] = hatchPetTeamSelectBox
            print("[DEBUG] Stored HatchPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("HatchPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    hatchPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    hatchPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local toggleAutoBoostBeforeHatch = accordion:AddToggle({
            Name = "Auto Boost Pets Before Hatching",
            Default = false,
            Flag = "AutoBoostBeforeHatch",
        })
        m.ToggleReferences["AutoBoostBeforeHatch"] = toggleAutoBoostBeforeHatch

        accordion:AddSeparator()

        local specialHatchingPetSelectBox = accordion:AddSelectBox({
            Name = "Select Special Pet",
            Options = {"Loading..."},
            Placeholder = "Select Special Pet...",
            MultiSelect = true,
            Flag = "SpecialHatchingPet",
            OnInit = function(api, optionsData)
                print("[DEBUG] SpecialHatchingPet OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("SpecialHatchingPet")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "SpecialHatchingPet", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "SpecialHatchingPet", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                updateOptions(formattedPets)
            end
        })

        -- Store reference immediately after creation
        if specialHatchingPetSelectBox then
            m.SelectBoxReferences["SpecialHatchingPet"] = specialHatchingPetSelectBox
            print("[DEBUG] Stored SpecialHatchingPet SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("SpecialHatchingPet")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    specialHatchingPetSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    specialHatchingPetSelectBox:Set(savedValue)
                end
            end
        end

        accordion:AddLabel("Or If Weight is Higher Than")
        local weightThresholdSpecialNumberBox = accordion:AddNumberBox({
            Name = "Weight Threshold",
            Placeholder = "Enter weight...",
            Default = 0.0,
            Min = 0.0,
            Max = 20.0,
            Increment = 1.0,
            Decimals = 2,
            Flag = "WeightThresholdSpecialHatching",
        })
        m.NumberBoxReferences["WeightThresholdSpecialHatching"] = weightThresholdSpecialNumberBox

        local specialHatchPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Pet Team for Special Hatch",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "SpecialHatchPetTeam",
            OnInit = function(api, optionsData)
                print("[DEBUG] SpecialHatchPetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("SpecialHatchPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "SpecialHatchPetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "SpecialHatchPetTeam", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if specialHatchPetTeamSelectBox then
            m.SelectBoxReferences["SpecialHatchPetTeam"] = specialHatchPetTeamSelectBox
            print("[DEBUG] Stored SpecialHatchPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("SpecialHatchPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    specialHatchPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    specialHatchPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local toggleDontHatchSpecial = accordion:AddToggle({
            Name = "Don't Hatch Special Pets",
            Default = false,
            Flag = "DontHatchSpecialPets",
        })
        m.ToggleReferences["DontHatchSpecialPets"] = toggleDontHatchSpecial

        local toggleAutoBoostBeforeSpecial = accordion:AddToggle({
            Name = "Auto Boost Pets Before Special Hatching",
            Default = false,
            Flag = "AutoBoostBeforeSpecialHatch",
        })
        m.ToggleReferences["AutoBoostBeforeSpecialHatch"] = toggleAutoBoostBeforeSpecial

        accordion:AddSeparator()

        local toggleAutoHatch = accordion:AddToggle({
            Name = "Auto Hatch Eggs",
            Default = false,
            Flag = "AutoHatchEggs",
            Callback = function(value)
                if value then
                    Egg:StartAutoHatching()
                else
                    Egg:StopAutoHatching()
                end
            end
        })
        m.ToggleReferences["AutoHatchEggs"] = toggleAutoHatch

        accordion:AddSeparator()

        local deficitEggThresholdNumberBox = accordion:AddNumberBox({
            Name = "Deficit Egg Threshold",
            Placeholder = "Enter threshold...",
            Default = 5,
            Min = 1,
            Max = 100,
            Increment = 1,
            Flag = "DeficitEggThreshold",
        })
        m.NumberBoxReferences["DeficitEggThreshold"] = deficitEggThresholdNumberBox

        local toggleAutoRejoinBadLuck = accordion:AddToggle({
            Name = "Auto Rejoin If Deficit Egg Is Detected More Than Threshold",
            Default = false,
            Flag = "AutoRejoinIfBadLuck"
        })
        m.ToggleReferences["AutoRejoinIfBadLuck"] = toggleAutoRejoinBadLuck
    end

    function m:AddSellSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Sell Pets",
            Icon = "💰",
            Expanded = false,
        })

        local petToSellSelectBox = accordion:AddSelectBox({
            Name = "Select Pet to Sell",
            Options = {"Loading..."},
            Placeholder = "Select Pet...",
            MultiSelect = true,
            Flag = "PetToSell",
            OnInit = function(api, optionsData)
                print("[DEBUG] PetToSell OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("PetToSell")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "PetToSell", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "PetToSell", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                updateOptions(formattedPets)
            end,
        })

        -- Store reference immediately after creation
        if petToSellSelectBox then
            m.SelectBoxReferences["PetToSell"] = petToSellSelectBox
            print("[DEBUG] Stored PetToSell SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("PetToSell")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    petToSellSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    petToSellSelectBox:Set(savedValue)
                end
            end
        end

        local weightThresholdSellNumberBox = accordion:AddNumberBox({
            Name = "And If Base Weight Is Less Than Or Equal",
            Placeholder = "Enter weight...",
            Default = 1.0,
            Min = 0.5,
            Max = 20.0,
            Increment = 1.0,
            Decimals = 2,
            Flag = "WeightThresholdSellPet",
        })
        m.NumberBoxReferences["WeightThresholdSellPet"] = weightThresholdSellNumberBox

        local ageThresholdSellNumberBox = accordion:AddNumberBox({
            Name = "And If Age Is Less Than Or Equal",
            Placeholder = "Enter age...",
            Default = 1,
            Min = 1,
            Max = 100,
            Increment = 1,
            Flag = "AgeThresholdSellPet",
        })
        m.NumberBoxReferences["AgeThresholdSellPet"] = ageThresholdSellNumberBox

        local sellPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Pet Team to Use for Selling",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "SellPetTeam",
            OnInit = function(api, optionsData)
                print("[DEBUG] SellPetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("SellPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "SellPetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "SellPetTeam", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end

                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if sellPetTeamSelectBox then
            m.SelectBoxReferences["SellPetTeam"] = sellPetTeamSelectBox
            print("[DEBUG] Stored SellPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("SellPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    sellPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    sellPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        accordion:AddButton(
            {
                Text = "Sell Selected Pet",
                Variant = "warning",
                Callback = function()
                    Pet:SellPet()
                end
            }
        )

        accordion:AddSeparator()

        local sellOnCycleHatchNumberBox = accordion:AddNumberBox({
            Name = "Sell On Cycle Hatch Count",
            Placeholder = "Enter cycle count...",
            Default = 1,
            Min = 1,
            Max = 100,
            Increment = 1,
            Flag = "SellOnCycleHatchCount",
        })
        m.NumberBoxReferences["SellOnCycleHatchCount"] = sellOnCycleHatchNumberBox

        accordion:AddLabel(function()
            local sellOnCycleHatchCount = Window:GetConfigValue("SellOnCycleHatchCount") or 1
            local cycleHatchCounter = Egg.CycleHatchCounter or 0
            return "Current Cycle Hatch Count Selling: " .. tostring(cycleHatchCounter) .. " / " .. tostring(sellOnCycleHatchCount)
        end)

        local toggleAutoBoostBeforeSelling = accordion:AddToggle({
            Name = "Auto Boost Pets Before Selling",
            Default = false,
            Flag = "AutoBoostBeforeSelling",
        })
        m.ToggleReferences["AutoBoostBeforeSelling"] = toggleAutoBoostBeforeSelling

        local toggleAutoSell = accordion:AddToggle({
            Name = "Auto Sell Pets After Hatching",
            Default = false,
            Flag = "AutoSellPetsAfterHatching",
        })
        m.ToggleReferences["AutoSellPetsAfterHatching"] = toggleAutoSell
    end

    function m:BoostPetsSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Boost Pets",
            Icon = "⚡",
            Expanded = false,
        })

        local boostPetsSelectBox = accordion:AddSelectBox({
            Name = "Pets Use for Boosting",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = true,
            Flag = "BoostPets",
            OnInit = function(api, optionsData)
                print("[DEBUG] BoostPets OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("BoostPets")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "BoostPets", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "BoostPets", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if boostPetsSelectBox then
            m.SelectBoxReferences["BoostPets"] = boostPetsSelectBox
            print("[DEBUG] Stored BoostPets SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("BoostPets")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    boostPetsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    boostPetsSelectBox:Set(savedValue)
                end
            end
        end

        local boostTypeSelectBox = accordion:AddSelectBox({
            Name = "Boost Type",
            Options = Pet:GetListTypeBoosts(),
            Placeholder = "Select Boost Type...",
            MultiSelect = true,
            Flag = "BoostType",
            OnInit = function(api, optionsData)
                local savedValue = Window:GetConfigValue("BoostType")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end
            end,
        })

        if boostTypeSelectBox then
            m.SelectBoxReferences["BoostType"] = boostTypeSelectBox
            local savedValue = Window:GetConfigValue("BoostType")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    boostTypeSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    boostTypeSelectBox:Set(savedValue)
                end
            end
        end

        accordion:AddButton({Text = "Boost Pets Now", Callback = function()
            Pet:BoostSelectedPets()
        end})

        local toggleAutoBoost = accordion:AddToggle({
            Name = "Auto Boost Pets",
            Default = false,
            Flag = "AutoBoostPets",
            Callback = function(value)
                if value then
                    Pet:AutoBoostSelectedPets()
                end
            end
        })
        m.ToggleReferences["AutoBoostPets"] = toggleAutoBoost

        accordion:AddSeparator()

        -- Auto Feed Section (combined from reference)
        local feedTargetPetsSelectBox = accordion:AddSelectBox({
            Name = "Only Feed On Pets",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "FeedTargetPets",
            OnInit = function(api, optionsData)
                print("[DEBUG] FeedTargetPets OnInit called")
                local savedValue = Window:GetConfigValue("FeedTargetPets")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "FeedTargetPets", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "FeedTargetPets", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if feedTargetPetsSelectBox then
            m.SelectBoxReferences["FeedTargetPets"] = feedTargetPetsSelectBox
            print("[DEBUG] Stored FeedTargetPets SelectBox API reference (direct assignment)")
            local savedValue = Window:GetConfigValue("FeedTargetPets")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    feedTargetPetsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    feedTargetPetsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreFruitsSelectBox = accordion:AddSelectBox({
            Name = "Select Ignore Fruits for Auto Feeding Active Pet",
            Options = {"Loading..."},
            Placeholder = "Select Fruits...",
            MultiSelect = true,
            Flag = "IgnoreFruitsForAutoFeedActivePet",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local seeds = Plant:GetPlantRegistry()
                    local formattedSeeds = {}
                    for _, seedData in pairs(seeds) do
                        table.insert(formattedSeeds, {
                            text = string.format("[%s] %s", seedData.rarity, seedData.plant),
                            value = seedData.plant
                        })
                    end
                    optionsData.updateOptions(formattedSeeds)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("IgnoreFruitsForAutoFeedActivePet")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local seeds = Plant:GetPlantRegistry()
                local formattedSeeds = {}
                for _, seedData in pairs(seeds) do
                    table.insert(formattedSeeds, {
                        text = string.format("[%s] %s", seedData.rarity, seedData.plant),
                        value = seedData.plant
                    })
                end
                updateOptions(formattedSeeds)
            end
        })

        -- Store reference and restore saved value
        if ignoreFruitsSelectBox then
            m.SelectBoxReferences["IgnoreFruitsForAutoFeedActivePet"] = ignoreFruitsSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("IgnoreFruitsForAutoFeedActivePet")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    ignoreFruitsSelectBox:Set(savedValue)
                end
            end)()
        end

        local hungerThresholdNumberBox = accordion:AddNumberBox({
            Name = "Percentage Hunger Threshold to Auto Feed Active Pet",
            Placeholder = "Enter hunger threshold...",
            Default = 50,
            Min = 0,
            Max = 100,
            Increment = 1,
            Flag = "HungerThresholdAutoFeedActivePet",
        })
        m.NumberBoxReferences["HungerThresholdAutoFeedActivePet"] = hungerThresholdNumberBox

        local toggleAutoFeed = accordion:AddToggle({
            Name = "Auto Feed Fruit to Active Pet",
            Default = false,
            Flag = "AutoFeedActivePet",
            Callback = function(value)
                if value then
                    Pet:StartAutoFeedActivePet()
                end
            end
        })
        m.ToggleReferences["AutoFeedActivePet"] = toggleAutoFeed
    end

    function m:AddPickupSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Pickup Pets",
            Icon = "📦",
            Expanded = false,
        })

        -- Store selectbox API directly when created, not in OnInit
        local pickupPetsSelectBox = accordion:AddSelectBox({
            Name = "Select Pets for Pickup After Use Skill",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "PickupTargetPets",
            OnInit = function(api, optionsData)
                -- Still keep this for backward compatibility
                print("[DEBUG] PickupTargetPets OnInit called")

                -- Load saved pets from config and set initial value
                local savedPets = Window:GetConfigValue("PickupTargetPets")
                if savedPets and type(savedPets) == "table" and #savedPets > 0 then
                    print("[DEBUG] Found saved PickupTargetPets:", #savedPets, "pets")
                    api:Set(savedPets)
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if pickupPetsSelectBox then
            m.SelectBoxReferences["PickupTargetPets"] = pickupPetsSelectBox
            print("[DEBUG] Stored PickupTargetPets SelectBox API reference (direct assignment)")

            -- Immediately try to restore saved value
            local savedPets = Window:GetConfigValue("PickupTargetPets")
            if savedPets and type(savedPets) == "table" and #savedPets > 0 then
                print("[DEBUG] Restoring PickupTargetPets from config:", #savedPets, "pets")
                pickupPetsSelectBox:Set(savedPets)
            end
        end

        local pickupDelayNumberBox = accordion:AddNumberBox({
            Name = "Pickup Delay (Seconds)",
            Placeholder = "Enter delay in seconds...",
            Default = 0.5,
            Min = 0.1,
            Max = 10,
            Increment = 0.1,
            Decimals = 2,
            Flag = "PickupDelayAfterUseSkill",
        })
        m.NumberBoxReferences["PickupDelayAfterUseSkill"] = pickupDelayNumberBox

        local placeDelayNumberBox = accordion:AddNumberBox({
            Name = "Place Delay (Seconds)",
            Placeholder = "Enter delay in seconds...",
            Default = 0.1,
            Min = 0.1,
            Max = 10,
            Increment = 0.1,
            Decimals = 2,
            Flag = "PlaceDelayAfterUseSkill",
        })
        m.NumberBoxReferences["PlaceDelayAfterUseSkill"] = placeDelayNumberBox

        local toggleAutoPickup = accordion:AddToggle({
            Name = "Auto Pickup Pets",
            Default = false,
            Flag = "AutoPickupPets",
            Callback = function(value)
                if value then
                    Pet:AutoPickupPets()
                else
                    Pet:StopAutoPickupPets()
                end
            end
        })
        m.ToggleReferences["AutoPickupPets"] = toggleAutoPickup
    end

    function m:SwitchPetSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Switch Active Pet",
            Icon = "🔄",
            Expanded = false,
        })

        local switchPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Pet Team To Switch When Changing",
            Options = PetTeam:GetAllPetTeams(),
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "SwitchPetTeam",
            OnInit = function(api, optionsData)
                local savedValue = Window:GetConfigValue("SwitchPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end

                updateOptions(currentOptionsSet)
            end
        })

        if switchPetTeamSelectBox then
            m.SelectBoxReferences["SwitchPetTeam"] = switchPetTeamSelectBox
            local savedValue = Window:GetConfigValue("SwitchPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    switchPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    switchPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local switchFromPetSelectBox = accordion:AddSelectBox({
            Name = "Select Pet To Switch From",
            Options = {"Loading..."},
            Placeholder = "Select Pet...",
            MultiSelect = false,
            Flag = "SwitchFromPetAfterChangeTeam",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    local teamName = Window:GetConfigValue("SwitchPetTeam") or ""
                    if teamName == "" then
                        return
                    end

                    local pets = PetTeam:FindPetTeam(teamName) or {}
                    if #pets == 0 then
                        return
                    end

                    local currentOptionsSet = {}

                    for _, petID in pairs(pets) do
                        local pet = Pet:GetPetDetail(petID)
                        table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                    end

                    optionsData.updateOptions(currentOptionsSet)

                    -- Restore saved value
                    local savedValue = Window:GetConfigValue("SwitchFromPetAfterChangeTeam")
                    if savedValue ~= nil and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local teamName = Window:GetConfigValue("SwitchPetTeam") or ""
                if teamName == "" then
                    return
                end

                local pets = PetTeam:FindPetTeam(teamName) or {}
                if #pets == 0 then
                    return
                end

                local currentOptionsSet = {}

                for _, petID in pairs(pets) do
                    local pet = Pet:GetPetDetail(petID)
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        if switchFromPetSelectBox then
            m.SelectBoxReferences["SwitchFromPetAfterChangeTeam"] = switchFromPetSelectBox
        end

        local switchToPetSelectBox = accordion:AddSelectBox({
            Name = "Select Pet To Switch To",
            Options = {"Loading..."},
            Placeholder = "Select Pet...",
            MultiSelect = false,
            Flag = "SwitchToPetAfterChangeTeam",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    local pets = Pet:GetAllMyPets()
                    local currentOptionsSet = {}

                    for _, pet in pairs(pets) do
                        table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                    end
                    optionsData.updateOptions(currentOptionsSet)

                    -- Restore saved value
                    local savedValue = Window:GetConfigValue("SwitchToPetAfterChangeTeam")
                    if savedValue ~= nil and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        if switchToPetSelectBox then
            m.SelectBoxReferences["SwitchToPetAfterChangeTeam"] = switchToPetSelectBox
        end

        accordion:AddSeparator()

        local delaySwitchNumberBox = accordion:AddNumberBox({
            Name = "Delay Switch Pet After Change Team (Seconds)",
            Placeholder = "Enter seconds...",
            Default = 20,
            Min = 1,
            Max = 120,
            Increment = 1,
            Flag = "DelaySwitchPetAfterChangeTeam",
        })
        m.NumberBoxReferences["DelaySwitchPetAfterChangeTeam"] = delaySwitchNumberBox

        local toggleAutoSwitchPet = accordion:AddToggle({
            Name = "Auto Switch Pet",
            Default = false,
            Flag = "AutoSwitchPet"
        })
        m.ToggleReferences["AutoSwitchPet"] = toggleAutoSwitchPet
    end

    function m:AddGlitchSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Glitch Features",
            Icon = "👾",
            Expanded = false,
        })

        -- Bone Blossom Glitch
        local toggleAutoFavUnfavBoneBlossom = accordion:AddToggle({
            Name = "Enable Glitch Bone Blossom (Active during Hatch/Sell)",
            Default = false,
            Flag = "AutoFavUnfavBoneBlossom",
        })
        m.ToggleReferences["AutoFavUnfavBoneBlossom"] = toggleAutoFavUnfavBoneBlossom

        accordion:AddSeparator()

        -- Gear Glitch
        local gearSelectBox = accordion:AddSelectBox({
            Name = "Select Gear for Glitch",
            Options = {"Loading..."},
            Placeholder = "Select gears...",
            MultiSelect = true,
            Flag = "AutoFavUnfavGearSelect",
            OnInit = function(api, optionsData)
                print("[DEBUG] AutoFavUnfavGearSelect OnInit called")
                local savedValue = Window:GetConfigValue("AutoFavUnfavGearSelect")
                if savedValue ~= nil and savedValue ~= "" and Inventory then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        -- Validate saved gears against current inventory
                        local validGears = Inventory:ValidateGearSelections(savedValue)
                        if #validGears > 0 then
                            api:Set(validGears)
                            print(string.format("[SelectBox] Restored %s: %d valid items (filtered from %d)", "AutoFavUnfavGearSelect", #validGears, #savedValue))
                        end
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        -- For single string value, check if gear exists
                        if Inventory:HasGear(savedValue) then
                            api:Set(savedValue)
                            print(string.format("[SelectBox] Restored %s: %s", "AutoFavUnfavGearSelect", savedValue))
                        end
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                if not Inventory then
                    updateOptions({})
                    return
                end

                local gears = Inventory:GetGearRegistry()
                local formattedGears = {}

                for _, gearInfo in pairs(gears) do
                    -- Show gear name with quantity for better info
                    local displayText = gearInfo.name
                    if gearInfo.quantity and gearInfo.quantity > 1 then
                        displayText = string.format("%s (x%d)", gearInfo.name, gearInfo.quantity)
                    end
                    table.insert(formattedGears, {
                        text = displayText,
                        value = gearInfo.name,
                    })
                end

                if #formattedGears == 0 then
                    table.insert(formattedGears, {
                        text = "No gears found in inventory",
                        value = "",
                    })
                end

                updateOptions(formattedGears)
            end
        })

        if gearSelectBox then
            m.SelectBoxReferences["AutoFavUnfavGearSelect"] = gearSelectBox
            print("[DEBUG] Stored AutoFavUnfavGearSelect SelectBox API reference")
            local savedValue = Window:GetConfigValue("AutoFavUnfavGearSelect")
            if savedValue ~= nil and savedValue ~= "" and Inventory then
                if type(savedValue) == "table" and #savedValue > 0 then
                    -- Validate saved gears against current inventory
                    local validGears = Inventory:ValidateGearSelections(savedValue)
                    if #validGears > 0 then
                        gearSelectBox:Set(validGears)
                    end
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    -- For single string value, check if gear exists
                    if Inventory:HasGear(savedValue) then
                        gearSelectBox:Set(savedValue)
                    end
                end
            end
        end

        local toggleAutoFavUnfavGear = accordion:AddToggle({
            Name = "Enable Glitch Gear (Active during Hatch/Sell)",
            Default = false,
            Flag = "AutoFavUnfavGear",
        })
        m.ToggleReferences["AutoFavUnfavGear"] = toggleAutoFavUnfavGear
    end


    -- Function to refresh all selectbox UI states from config
    function m:RefreshSelectBoxStates()
        if not Window then
            warn("[PET] RefreshSelectBoxStates - Window not initialized")
            return 0
        end

        -- Count entries properly (# operator doesn't work for dictionary tables)
        local totalRefs = 0
        for _ in pairs(self.SelectBoxReferences) do
            totalRefs = totalRefs + 1
        end

        print(string.format("[PET] RefreshSelectBoxStates called, found %d selectbox references", totalRefs))

        if totalRefs > 0 then
            print("[PET] SelectBoxReferences keys:")
            for k, v in pairs(self.SelectBoxReferences) do
                print("  - " .. k .. " : " .. tostring(v ~= nil and "API exists" or "nil"))
            end
        else
            warn("[PET] WARNING: SelectBoxReferences is empty! This means OnInit was not called or selectboxes were not stored properly.")
        end

        local refreshedCount = 0

        for flagName, selectBoxAPI in pairs(self.SelectBoxReferences) do
            local success, err = pcall(function()
                if selectBoxAPI and type(selectBoxAPI) == "table" and selectBoxAPI.Set then
                    local configValue = Window:GetConfigValue(flagName)

                    if configValue ~= nil and configValue ~= "" then
                        -- Check if it's a table with items or a non-empty string
                        local hasValue = false
                        if type(configValue) == "table" and #configValue > 0 then
                            hasValue = true
                        elseif type(configValue) == "string" and configValue ~= "" then
                            hasValue = true
                        end

                        if hasValue then
                            -- Use Set() method to update UI without triggering callbacks
                            selectBoxAPI:Set(configValue)
                            local valueStr = type(configValue) == "table" and (#configValue .. " items") or tostring(configValue)
                            print(string.format("  ✓ [PET SelectBox] %s = %s", flagName, valueStr))
                            refreshedCount = refreshedCount + 1
                        end
                    else
                        print(string.format("  ⊘ [PET SelectBox] %s - No saved value in config", flagName))
                    end
                else
                    warn(string.format("  ✗ [PET SelectBox] %s - API missing or invalid (type: %s, has Set: %s)",
                        flagName,
                        type(selectBoxAPI),
                        selectBoxAPI and type(selectBoxAPI.Set) or "nil"))
                end
            end)

            if not success then
                warn(string.format("  ✗ [PET SelectBox] %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("[PET] Refreshed %d selectboxes successfully", refreshedCount))
        return refreshedCount
    end

    -- Function to refresh all toggle UI states from config
    function m:RefreshToggleStates()
        if not Window then
            warn("PetUI:RefreshToggleStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, toggleAPI in pairs(self.ToggleReferences) do
            local success, err = pcall(function()
                if toggleAPI and toggleAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        toggleAPI:SetValue(configValue, false)
                        print(string.format("  ✓ [Pet] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Pet] %s - Toggle API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Pet] %s - Error: %s", flagName, tostring(err)))
            end
        end

        return refreshedCount
    end

    -- Function to refresh all numberbox UI states from config
    function m:RefreshNumberBoxStates()
        if not Window then
            warn("PetUI:RefreshNumberBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, numberBoxAPI in pairs(self.NumberBoxReferences) do
            local success, err = pcall(function()
                if numberBoxAPI and numberBoxAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        numberBoxAPI:SetValue(configValue)
                        print(string.format("  ✓ [Pet] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Pet] %s - NumberBox API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Pet] %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("[PET] Refreshed %d numberboxes successfully", refreshedCount))
        return refreshedCount
    end

    return m
end

-- Module: auto/crafting.lua
EmbeddedModules["auto/crafting.lua"] = function()
    local m = {}

    local Window
    local Core

    local MachineTypes = {}
    local CraftingRecipeRegistry
    local Recipes
    local CraftingUtil
    local Plant
    local LastNotificationTime = {}

    function m:Init(window, core, plant)
        Window = window
        Core = core
        Plant = plant

        CraftingRecipeRegistry = require(Core.ReplicatedStorage.Data.CraftingData.CraftingRecipeRegistry)
        Recipes = CraftingRecipeRegistry.ItemRecipes
        CraftingUtil = require(Core.ReplicatedStorage.Modules.CraftingService.CraftingGlobalObjectService)

        self:InitCraftingRecipes()

        Core:MakeLoop(
            function()
                return Window:GetConfigValue("AutoCraftingGear")
            end, 
            function()
                self:CraftingController( 
                    workspace.CraftingTables.EventCraftingWorkBench,
                    Window:GetConfigValue("CraftingGearItem")
                )
            end
        )

        Core:MakeLoop(
            function()
                return Window:GetConfigValue("AutoCraftingSeeds")
            end, 
            function()
                self:CraftingController( 
                    workspace.CraftingTables.SeedEventCraftingWorkBench,
                    Window:GetConfigValue("CraftingSeedItem")
                )
            end
        )
    end

    function m:GetCraftingObjectType(craftingStation)
        return craftingStation:GetAttribute("CraftingObjectType")
    end 

    function m:InitCraftingRecipes()
        if #MachineTypes > 0 then
            return MachineTypes
        end

        MachineTypes = CraftingRecipeRegistry.RecipiesSortedByMachineType or {}

        return MachineTypes
    end

    function m:GetMachineTypes()
        local machineTypes =  {}

        for machineType, _ in pairs(MachineTypes) do
            table.insert(machineTypes, machineType)
        end

        return machineTypes
    end

    function m:GetAllCraftingItems(craftingStation)
        local machineType = self:GetCraftingObjectType(craftingStation)
        local craftingItems = {}

        for item, _ in pairs(MachineTypes[machineType] or {}) do
            table.insert(craftingItems, item)
        end

        -- Sort the crafting items alphabetically
        table.sort(craftingItems)

        return craftingItems
    end

    function m:GetCraftingData(craftingStation, craftingItem)
        local machineType = self:GetCraftingObjectType(craftingStation)
        local data = {}

        for items, detail in pairs(MachineTypes[machineType] or {}) do
            if items == craftingItem then
                table.insert(data, detail)
                break
            end
        end

        return data
    end

    function m:GetCraftingRecipes(craftingStation, craftingItem)
        local craftingData = self:GetCraftingData(craftingStation, craftingItem)
        local craftingInputs = {}
        local recipes = {}

        if #craftingData == 0 then
            return recipes
        end

        for _, detail in pairs(craftingData) do
            if type(detail) == "table" and detail.Inputs then
                for _, input in pairs(detail.Inputs) do
                    table.insert(craftingInputs, input)
                end
                continue
            end
        end

        for i, input in pairs(craftingInputs) do
            local dataItems
            table.insert(recipes, input)
        end

        return recipes
    end

    function m:GetCraftingStationStatus(craftingStation)
        local data = CraftingUtil:GetIndividualCraftingMachineData(craftingStation, self:GetCraftingObjectType(craftingStation))
        if not data or not data.RecipeId then
            return "Idle"
        end

        local unsubmittedItems = self:GetUnsubmittedItems(craftingStation)
        if #unsubmittedItems > 0 then
            return "Waiting for Item"
        end

        local craftingItem = data.CraftingItems and data.CraftingItems[1]
        if craftingItem then
            if craftingItem.IsDone then
                return "Ready to Claim"
            else
                return "On Progress"
            end
        end

        return "Ready to Start"
    end

    function m:SetRecipe(craftingStation, craftingItem)
        if not craftingStation or not craftingItem then
            return
        end

        Core.ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "SetRecipe",
            craftingStation,
            self:GetCraftingObjectType(craftingStation),
            craftingItem
        )
    end

    function m:SubmitCraftingRequest(craftingStation)
        local craftingHandler = require(Core.ReplicatedStorage.Modules.CraftingStationHandler)

        local success, error = pcall(function() 
            craftingHandler:SubmitAllRequiredItems(craftingStation) 
        end)

        if not success then
            return
        end

        local unsubmittedItems = self:GetUnsubmittedItems(craftingStation)

        if #unsubmittedItems == 0 then
            return
        end

        local needFruits = {}
        for _, item in pairs(unsubmittedItems) do
            if item.ItemType == "Holdable" then
                table.insert(needFruits, item.ItemData.ItemName)
            end
        end

        if #needFruits == 0 then
            return
        end

        local stationKey = craftingStation.Name .. "_submit"
        local stationDisplayName = craftingStation.Name:gsub("(%u)", " %1"):gsub("^%s+", "")
        local currentTime = tick()
        local notifCooldown = 60 -- 1 minute in seconds

        for _, fruit in pairs(needFruits) do
            local plants = Plant:FindPlants(fruit) or {}

            if #plants == 0 then
                if not LastNotificationTime[stationKey] or (currentTime - LastNotificationTime[stationKey]) >= notifCooldown then
                    Window:ShowWarning(stationDisplayName, "No plants found for: " .. fruit)
                    LastNotificationTime[stationKey] = currentTime
                end
                continue
            end

            for _, plant in pairs(plants) do
                local plantDetail = Plant:GetPlantDetail(plant)
                local successHarvest
                if not plantDetail or #plantDetail.fruits == 0 then
                    continue
                end

                for _, harvestingFruit in pairs(plantDetail.fruits) do
                    if not harvestingFruit.isEligibleToHarvest then
                        continue
                    end

                    successHarvest = pcall(function()
                        Plant:HarvestFruit(harvestingFruit.model)
                    end)
                end

                if successHarvest then
                    break
                end
            end
        end
    end

    function m:StartCrafting(craftingStation)
        local unsubmittedItems = self:GetUnsubmittedItems(craftingStation)

        if #unsubmittedItems > 0 then
            return
        end

        local OpenRecipeEvent = Core.ReplicatedStorage.GameEvents.OpenRecipeBindableEvent

        local success, error = pcall(function()
            Core.ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
                "Craft",
                craftingStation,
                self:GetCraftingObjectType(craftingStation)
            )
        end)

        if not success then
            local stationKey = craftingStation.Name .. "_start_error"
            local stationDisplayName = craftingStation.Name:gsub("(%u)", " %1"):gsub("^%s+", "")
            local currentTime = tick()
            local notifCooldown = 60

            if not LastNotificationTime[stationKey] or (currentTime - LastNotificationTime[stationKey]) >= notifCooldown then
                Window:ShowWarning(stationDisplayName, "Error starting crafting: " .. tostring(error))
                LastNotificationTime[stationKey] = currentTime
            end
            return
        end
    end

    function m:CraftingController(craftingStation, craftingItem)
        if not craftingStation or not craftingItem then
            warn("CraftingController: Invalid crafting station or item.")
            return
        end

        local stationKey = craftingStation.Name
        local stationDisplayName = craftingStation.Name:gsub("(%u)", " %1"):gsub("^%s+", "")
        local currentTime = tick()
        local notifCooldown = 60 -- 1 minute in seconds

        local function showTimedInfo(message)
            if not LastNotificationTime[stationKey] or (currentTime - LastNotificationTime[stationKey]) >= notifCooldown then
                Window:ShowInfo(stationDisplayName, message)
                LastNotificationTime[stationKey] = currentTime
            end
        end

        showTimedInfo("Starting crafting process for item: " .. craftingItem)

        if self:GetCraftingStationStatus(craftingStation) == "Idle" then
            showTimedInfo("Setting recipe for item: " .. craftingItem)
            self:SetRecipe(craftingStation, craftingItem)
            task.wait(0.5) -- Wait for 0.5 seconds to allow the station to update its status
        end

        while self:GetCraftingStationStatus(craftingStation) == "Waiting for Item" do
            showTimedInfo("Waiting for items to be submitted for crafting.")
            self:SubmitCraftingRequest(craftingStation)

            wait(5) -- Wait for 5 seconds before checking again
        end

        if  self:GetCraftingStationStatus(craftingStation) == "Ready to Start" then
            showTimedInfo("Starting crafting for item: " .. craftingItem)
            self:StartCrafting(craftingStation)
            task.wait(0.5) -- Wait for 0.5 seconds to allow the crafting process to start
        end

        while self:GetCraftingStationStatus(craftingStation) == "On Progress" do
            showTimedInfo("Crafting in progress for item: " .. craftingItem)
            wait(1) -- Wait for 1 second before checking again
        end

        if self:GetCraftingStationStatus(craftingStation) == "Ready to Claim" then
            showTimedInfo("Claiming crafted item: " .. craftingItem)
            local success, error = pcall(function()
                Core.ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
                    "Claim",
                    craftingStation,
                    self:GetCraftingObjectType(craftingStation),
                    1
                )
            end)

            if not success then
                Window:ShowWarning(stationDisplayName, "Error claiming crafted item: " .. error)
                return
            end

            task.wait(0.5) -- Wait for 0.5 seconds to allow the
        end
    end

    function m:GetSubmittedItems(craftingStation)
    	local machineData = CraftingUtil:GetIndividualCraftingMachineData(craftingStation, self:GetCraftingObjectType(craftingStation))
        local submittedItems = {}

        if not (machineData and machineData.RecipeId) then
    		return submittedItems
    	end

        if not Recipes[machineData.RecipeId] then
    		return submittedItems
    	end

        for item, _ in machineData.InputItems do
    		submittedItems[tostring(item)] = true
    	end

        return submittedItems
    end

    function m:GetUnsubmittedItems(craftingStation)
        local submitted = self:GetSubmittedItems(craftingStation)
        local machineData = CraftingUtil:GetIndividualCraftingMachineData(craftingStation, self:GetCraftingObjectType(craftingStation))

        local recipe = machineData and machineData.RecipeId and Recipes[machineData.RecipeId]
        local result = {}

        if not recipe then
            return result
        end

        for id, input in pairs(recipe.Inputs) do
            if not submitted[tostring(id)] then
                table.insert(result, input)
            end
        end

        return result
    end

    return m
end

-- Module: inventory/trade.lua
EmbeddedModules["inventory/trade.lua"] = function()
    local m = {}

    local Window
    local Core
    local Player
    local Pets

    local RequestGiftConnection
    local QueueAcceptGifts = {}

    function m:Init(_core, _window, _player, _pets)
        Core = _core
        Window = _window
        Player = _player
        Pets = _pets

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoAcceptGifts")
        end, function()
            self:StartAutoAcceptGifts()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoGiftPets")
        end, function()
            self:AutoGiftPets()
        end)
    end

    function m:StartAutoAcceptGifts()
        if not Window:GetConfigValue("AutoAcceptGifts") then
            return
        end

        -- Check for existing gift notifications when toggle is activated
        if not RequestGiftConnection then
            local giftNotificationFrame = Core.LocalPlayer.PlayerGui.Gift_Notification.Frame

            -- Add existing gift notifications to queue
            for _, child in pairs(giftNotificationFrame:GetChildren()) do
                if child.Name == "Gift_Notification" then
                    local holder = child:FindFirstChild("Holder")
                    if holder then
                        local itemName = holder:FindFirstChild("TextLabel")
                        local acceptButton = child.Holder.Frame.Accept

                        -- Check if this gift is not already in queue
                        local alreadyInQueue = false
                        for _, giftData in pairs(QueueAcceptGifts) do
                            if giftData.AcceptButton == acceptButton then
                                alreadyInQueue = true
                                break
                            end
                        end

                        if not alreadyInQueue then
                            Window:ShowInfo("Auto Accept Gifts", "Found existing gift request: " .. (itemName and itemName.Text or "Unknown Item"))
                            table.insert(QueueAcceptGifts, {
                                AcceptButton = acceptButton
                            })
                        end
                    end
                end
            end

            -- Setup connection for new gift notifications
            RequestGiftConnection = giftNotificationFrame.ChildAdded:Connect(function(child)
                if child.Name == "Gift_Notification" then
                    local holder = child:FindFirstChild("Holder")
                    if not holder then
                        warn("AutoAcceptGifts: Holder not found in Gift_Notification")
                        return
                    end

                    local itemName = holder:FindFirstChild("TextLabel")
                    local acceptButton = child.Holder.Frame.Accept

                    Window:ShowInfo("Auto Accept Gifts", "Get Request to Accept: " .. (itemName and itemName.Text or "Unknown Item"))

                    -- Add to queue
                    table.insert(QueueAcceptGifts, {
                        AcceptButton = acceptButton
                    })
                end
            end)
        end

        for _, giftData in pairs(QueueAcceptGifts) do
            if not Window:GetConfigValue("AutoAcceptGifts") then
                break
            end

            if not giftData.AcceptButton then
                warn("AutoAcceptGifts: AcceptButton not found in giftData")
                continue
            end

            -- Check if accept button still exists and is valid
            if not giftData.AcceptButton.Parent then
                warn("AutoAcceptGifts: Accept button no longer exists in UI, skipping...")
                continue
            end

            Window:ShowInfo("Auto Accept Gifts", "Accepting Gift...")

            -- Try multiple methods to click the accept button
            local clickSuccess = pcall(function()
                -- Method 1: MouseButton1Click
                for _, connection in pairs(getconnections(giftData.AcceptButton.MouseButton1Click)) do
                    connection:Fire()
                end
            end)

            if not clickSuccess then
                -- Method 2: Activated
                warn("AutoAcceptGifts: Falling back to Activated event click method.")
                clickSuccess = pcall(function()
                    for _, connection in pairs(getconnections(giftData.AcceptButton.Activated)) do
                        connection:Fire()
                    end
                end)
            end

            if not clickSuccess then
                -- Method 3: Simulate click using VirtualUser
                warn("AutoAcceptGifts: Falling back to VirtualUser click method.")
                clickSuccess = pcall(function()
                    Core.VirtualUser:ClickButton1(giftData.AcceptButton)
                end)
            end

            if not clickSuccess then
                warn("AutoAcceptGifts: Failed to click Accept button using all methods.")
                continue
            end

            Window:ShowInfo("Auto Accept Gifts", "Waiting trade to complete...")

            local tradeCompleted = false
            local timeoutCounter = 0
            local maxTimeout = 15 -- 15 seconds timeout

            local notificationConnection = Core.ReplicatedStorage.GameEvents.Notification.OnClientEvent:Connect(function(message)
                local normalizedMessage = string.lower(message)
                if string.find(normalizedMessage, "trade") or string.find(normalizedMessage, "gift") then
                    Window:ShowInfo("Auto Accept Gifts", message)
                    tradeCompleted = true
                end
            end)

            while not tradeCompleted and Window:GetConfigValue("AutoAcceptGifts") and timeoutCounter < maxTimeout do
                task.wait(1)
                timeoutCounter = timeoutCounter + 1
            end

            if timeoutCounter >= maxTimeout then
                Window:ShowWarning("Auto Accept Gifts", "Trade completion timeout, moving to next gift...")
            end

            -- Remove Queue entry
            for index, gift in pairs(QueueAcceptGifts) do
                if gift == giftData then
                    table.remove(QueueAcceptGifts, index)
                    break
                end
            end

            notificationConnection:Disconnect()
        end
    end

    function m:StopAutoAcceptGifts()
        if RequestGiftConnection then
            RequestGiftConnection:Disconnect()
            RequestGiftConnection = nil
        end

        QueueAcceptGifts = {}
    end

    function m:AutoGiftPets()
        if not Window:GetConfigValue("AutoGiftPets") then
            return
        end

        local targetPlayerUserId = Window:GetConfigValue("AutoGiftPlayer") or nil

        if not targetPlayerUserId then
            Window:ShowWarning("Auto Gift Pets", "No player selected to gift pets.")
            return
        end

        local targetPlayer = Core.Players:GetPlayerByUserId(targetPlayerUserId)

        if not targetPlayer then
            Window:ShowWarning("Auto Gift Pets", "Target player not found.")
            return
        end

        local selectedPets = Window:GetConfigValue("AutoGiftPetType") or {}
        if not selectedPets or #selectedPets == 0 then
            Window:ShowWarning("Auto Gift Pets", "No pet type selected to gift.")
            return
        end


        local ownedPets = Pets:GetAllOwnedPets() or {}
        if not ownedPets or #ownedPets == 0 then
            Window:ShowWarning("Auto Gift Pets", "No owned pets found to gift.")
            return
        end

        -- New settings: delay between gifts and optional weight filter
        local petAgeFilterMode = Window:GetConfigValue("AutoGiftPetAgeMode") or "None" -- "None", "Below" or "Above"
        local petAgeFilterValue = Window:GetConfigValue("AutoGiftPetAge") or 1
        local weightFilterMode = Window:GetConfigValue("AutoGiftPetWeightMode") or "None" -- "None", "Below" or "Above"
        local weightFilterValue = Window:GetConfigValue("AutoGiftPetWeightValue") or 0
        local giftDelay = Window:GetConfigValue("AutoGiftPetsDelay") or 5
        local quantityLimit = Window:GetConfigValue("AutoGiftPetQuantity") or 0 -- 0 = unlimited

        -- Counter for gifted pets
        local giftedCount = 0

        for _, tool in pairs(ownedPets) do
            if not Window:GetConfigValue("AutoGiftPets") then
                break
            end

            -- Check if quantity limit is reached (0 = unlimited)
            if quantityLimit > 0 and giftedCount >= quantityLimit then
                Window:ShowInfo("Auto Gift Pets", string.format("Quantity limit reached (%d/%d pets gifted)", giftedCount, quantityLimit))
                break
            end

            local petID = tool:GetAttribute("PET_UUID")
            if not petID then
                Window:ShowWarning("Auto Gift Pets", "Pet tool missing PET_UUID attribute:" .. tool.Name)
                continue
            end

            local petData = Pets:GetPetDetail(petID)
            if not petData then
                warn("AutoGiftPets: Unable to get pet data for PET_UUID:", petID)
                continue
            end

            if not table.find(selectedPets, petData.Type) then
                continue
            end

            local petAge = petData.Age or 0
            if petAgeFilterMode == "Below" and petAge > petAgeFilterValue then
                continue
            elseif petAgeFilterMode == "Above" and petAge < petAgeFilterValue then
                continue
            end

            local petWeight = petData.BaseWeight or 0
            if weightFilterMode == "Below" and petWeight > weightFilterValue then
                continue
            elseif weightFilterMode == "Above" and petWeight < weightFilterValue then
                continue
            end

            -- Optional delay between each gift (in seconds)
            if giftDelay > 0 then
                task.wait(giftDelay)
            end

            if petData.IsFavorited and Window:GetConfigValue("AutoGiftForceFavoritedPets") then
                Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(tool)
                task.wait(1)
            elseif petData.IsFavorited then
                continue
            end

            local taskCompleted = false
            local giftPetTask = function(_petData, _targetPlayer, _petGiftingService)
                Window:ShowInfo("Auto Gift Pets", "Gifting pet: " .. (_petData.Name or "Unknown Pet") .. " to player: " .. _targetPlayer.Name)

                -- Confirm gift via FireServer
                local confirmSuccess, confirmErr = pcall(function()
                    Core.ReplicatedStorage.GameEvents.PetGiftingService:FireServer("GivePet", _targetPlayer)
                    task.wait(3)
                end)

                if not confirmSuccess then
                    Window:ShowWarning("Auto Gift Pets", "Failed to confirm gift: " .. tostring(confirmErr))
                    task.wait(0.5)
                    return
                end

                Window:ShowInfo("Auto Gift Pets", "Successfully gifted pet: " .. (_petData.Name or "Unknown Pet") .. " to player: " .. _targetPlayer.Name)
            end

            local taskCallback = function()
                taskCompleted = true
            end

            Player:AddToQueue(
                tool,
                80,
                function()
                    giftPetTask(petData, targetPlayer, petGiftingService)
                end,
                function()
                    taskCallback()
                end
            )

            -- Increment gifted count
            giftedCount = giftedCount + 1

            local tradeCompleted = false
            local notificationConnection = Core.ReplicatedStorage.GameEvents.Notification.OnClientEvent:Connect(function(message)
                local normalizedMessage = string.lower(message)
                if string.find(normalizedMessage, "trade") or string.find(normalizedMessage, "gift") then
                    Window:ShowInfo("Auto Gift Pets", message)
                    tradeCompleted = true
                end
            end)

            while not tradeCompleted and not taskCompleted and Window:GetConfigValue("AutoGiftPets") do
                task.wait(1)
            end

            notificationConnection:Disconnect()
        end

    end

    return m
end

-- Module: https://raw.githubusercontent.com/k1r4-id/ez-rbx-ui-custome/refs/heads/main/release/ez-rbx-ui.lua
EmbeddedModules["https://raw.githubusercontent.com/k1r4-id/ez-rbx-ui-custome/refs/heads/main/release/ez-rbx-ui.lua"] = function()
    -- Bundled Lua Script
    -- Generated by Lua Bundler
    -- https://github.com/alfin-efendy/lua-bundler

    local EmbeddedModules = {}

    -- Module: utils/config
    EmbeddedModules["utils/config"] = function()
        local Config = {}
        local HttpService = game:GetService("HttpService")

        function Config:NewConfig(config)
        	-- Support both old style (string, string) and new style (table)
        	local configName, directory

        	if type(config) == "table" then
        		-- New style: table parameter
        		configName = config.ConfigName or config.FileName or config.Name
        		directory = config.Directory or config.FolderName
        	elseif type(config) == "string" then
        		-- Old style: first parameter is configName
        		configName = config
        		directory = nil
        	else
        		warn("EzUI:NewConfig: config must be a string or table")
        		return nil
        	end

        	if not configName or type(configName) ~= "string" then
        		warn("EzUI:NewConfig: configName must be a string")
        		return nil
        	end

        	-- Use custom directory or default to EzUI Configuration folder
        	local customDirectory = directory
        	if customDirectory and type(customDirectory) ~= "string" then
        		warn("EzUI:NewConfig: directory must be a string, using default")
        		customDirectory = nil
        	end

        	-- Create independent storage for this custom config
        	local Flags = {}

        	-- Save function for this custom config
        	local function SaveConfiguration()
        		print("EzUI.CustomConfig: Saving configuration for", configName)

        		-- Filter out keys with nil values
        		local dataToSave = {}
        		local hasData = false

        		for key, value in pairs(Flags) do
        			if value ~= nil then
        				dataToSave[key] = value
        				hasData = true
        			end
        		end

        		if not hasData then
        			print("EzUI.CustomConfig: No valid data to save for " .. configName)
        			return false
        		end

        		if not writefile or not isfolder or not makefolder then
        			warn("EzUI.CustomConfig: File operations not available")
        			return false
        		end

        		-- Use custom directory or default to EzUI folder structure
        		local dynamicFolderName, dynamicConfigurationFolder, filePath

        		if customDirectory then
        			-- Custom directory path
        			dynamicFolderName = customDirectory
        			dynamicConfigurationFolder = customDirectory
        			filePath = dynamicConfigurationFolder .. "/" .. configName .. ".json"
        		else
        			-- Default EzUI folder structure
        			dynamicFolderName = EzUI.Configuration.FolderName or "EzUI"
        			dynamicConfigurationFolder = dynamicFolderName .. "/Configurations"
        			filePath = dynamicConfigurationFolder .. "/" .. configName .. ".json"
        		end

        		-- Create folders if they don't exist
        		if not isfolder(dynamicFolderName) then
        			makefolder(dynamicFolderName)
        		end

        		-- Only create Configurations subfolder if not using custom directory
        		if not customDirectory and not isfolder(dynamicConfigurationFolder) then
        			makefolder(dynamicConfigurationFolder)
        		end

        		-- Save to JSON file
        		local success, result = pcall(function()
        			writefile(filePath, HttpService:JSONEncode(dataToSave))
        		end)

        		if success then
        			local savedCount = 0
        			for _ in pairs(dataToSave) do
        				savedCount = savedCount + 1
        			end
        			print("EzUI.CustomConfig: " .. configName .. " saved to " .. filePath .. " (" .. savedCount .. " keys)")
        			return true
        		else
        			warn("EzUI.CustomConfig: Failed to save " .. configName .. ": " .. tostring(result))
        			return false
        		end
        	end

        	-- Load function for this custom config
        	local function LoadConfiguration()
        		if not readfile or not isfile then
        			warn("EzUI.CustomConfig: File operations not available")
        			return false
        		end

        		-- Use custom directory or default to EzUI folder structure
        		local filePath

        		if customDirectory then
        			-- Custom directory path
        			filePath = customDirectory .. "/" .. configName .. ".json"
        		else
        			-- Default EzUI folder structure
        			local dynamicFolderName = EzUI.Configuration.FolderName or "EzUI"
        			local dynamicConfigurationFolder = dynamicFolderName .. "/Configurations"
        			filePath = dynamicConfigurationFolder .. "/" .. configName .. ".json"
        		end

        		if not isfile(filePath) then
        			print("EzUI.CustomConfig: No file found for " .. configName .. " at " .. filePath)
        			return false
        		end

        		local success, configData = pcall(function()
        			print("EzUI.CustomConfig: Loading configuration from " .. filePath)
        			-- Decode JSON data
        			return HttpService:JSONDecode(readfile(filePath))
        		end)

        		if not success then
        			warn("EzUI.CustomConfig: Failed to load " .. configName .. ": " .. tostring(configData))
        			return false
        		end

        		-- Apply loaded data and update components
        		local applied = 0
        		for flagName, flagValue in pairs(configData) do
        			print("EzUI.CustomConfig: Loaded", flagName, "=", flagValue)
        			Flags[flagName] = flagValue
        			applied = applied + 1
        		end

        		print("EzUI.CustomConfig: " .. configName .. " loaded (" .. applied .. " settings applied)")
        		return true
        	end

        	local configAPI = {}

        	-- Get value by key
        	function configAPI:GetValue(key)
        		if not key then
        			warn("EzUI.CustomConfig.GetValue: key parameter is required")
        			return nil
        		end
        		return Flags[key]
        	end

        	-- Set value by key and update associated components
        	function configAPI:SetValue(key, value)
        		if not key then
        			warn("EzUI.CustomConfig.SetValue: key parameter is required")
        			return false
        		end

        		print("EzUI.CustomConfig: Setting", key, "to", value)

        		Flags[key] = value

        		SaveConfiguration()
        		return true
        	end

        	-- Get all key-value pairs
        	function configAPI:GetAll()
        		local result = {}
        		for key, value in pairs(Flags) do
        			if value ~= nil then
        				result[key] = value
        			end
        		end
        		return result
        	end

        	-- Get All Keys
        	function configAPI:GetAllKeys()
        		local keys = {}
        		for key, value in pairs(Flags) do
        			if value ~= nil then
        				table.insert(keys, key)
        			end
        		end
        		return keys
        	end

        	-- Delete a specific key
        	function configAPI:DeleteKey(key)
        		if not key then
        			warn("EzUI.CustomConfig.DeleteKey: key parameter is required")
        			return false
        		end

        		if Flags[key] ~= nil then
        			Flags[key] = nil

        			SaveConfiguration()
        			return true
        		else
        			warn("EzUI.CustomConfig.DeleteKey: key '" .. key .. "' not found")
        			return false
        		end
        	end

        	-- Get configuration info
        	function configAPI:GetInfo()
        		local folderName, configFolder, filePath

        		if customDirectory then
        			folderName = customDirectory
        			configFolder = customDirectory
        			filePath = customDirectory .. "/" .. configName .. ".json"
        		else
        			folderName = EzUI.Configuration.FolderName or "EzUI"
        			configFolder = folderName .. "/Configurations"
        			filePath = configFolder .. "/" .. configName .. ".json"
        		end

        		return {
        			ConfigName = configName,
        			CustomDirectory = customDirectory,
        			FolderName = folderName,
        			ConfigFolder = configFolder,
        			FilePath = filePath,
        			IsCustomDirectory = customDirectory ~= nil
        		}
        	end

        	-- Manual save
        	function configAPI:Save()
        		return SaveConfiguration()
        	end

        	-- Manual load
        	function configAPI:Load()
        		return LoadConfiguration()
        	end

        	-- Return custom configuration object
        	return configAPI
        end

        return Config
    end

    -- Module: components/accordion
    EmbeddedModules["components/accordion"] = function()
        --[[
        	Accordion Component
        	EzUI Library - Modular Component

        	Creates a collapsible accordion with dynamic content
        	Uses proven logic from old ui.lua for reliable expand/collapse behavior
        ]]

        -- Component modules (will be loaded by Window)
        local Accordion = {}

        local Colors
        local Button
        local Toggle
        local TextBox
        local NumberBox
        local SelectBox
        local Label
        local Separator

        -- Initialize component modules
        function Accordion:Init(_colors, _button, _toggle, _textbox, _numberbox, _selectbox, _label, _separator)
        	Colors = _colors
        	Button = _button
        	Toggle = _toggle
        	TextBox = _textbox
        	NumberBox = _numberbox
        	SelectBox = _selectbox
        	Label = _label
        	Separator = _separator
        end

        function Accordion:Create(config)
        	-- Configuration
        	local title = config.Title or config.Name or "Accordion"
        	local expanded = config.Expanded or config.Open or config.DefaultExpanded or false
        	local icon = config.Icon or ""
        	local tabContent = config.Parent
        	local accordionStartY = config.Y or 0

        	-- Accordion state
        	local isExpanded = expanded
        	local callback = config.Callback -- function dipanggil saat expand/collapse/toggle
        	local accordionContentHeight = 0

        	-- Main accordion container
        	local accordionContainer = Instance.new("Frame")
        	accordionContainer.Size = UDim2.new(1, -20, 0, 30) -- Initial height just for header
        	accordionContainer.Position = UDim2.new(0, 10, 0, accordionStartY)
        	accordionContainer.BackgroundTransparency = 1
        	accordionContainer.ClipsDescendants = false -- Allow content to show
        	accordionContainer.ZIndex = 3
        	accordionContainer.Parent = tabContent

        	-- Store reference to this accordion
        	accordionContainer:SetAttribute("AccordionStartY", accordionStartY)
        	accordionContainer:SetAttribute("IsAccordion", true)

        	-- Accordion header (clickable)
        	local accordionHeader = Instance.new("TextButton")
        	accordionHeader.Size = UDim2.new(1, 0, 0, 30)
        	accordionHeader.Position = UDim2.new(0, 0, 0, 0)
        	accordionHeader.BackgroundColor3 = Colors.Surface.Default
        	accordionHeader.BorderSizePixel = 0
        	accordionHeader.Text = ""
        	accordionHeader.ZIndex = 4
        	accordionHeader.Parent = accordionContainer

        	-- Header round corners
        	local headerCorner = Instance.new("UICorner")
        	headerCorner.CornerRadius = UDim.new(0, 4)
        	headerCorner.Parent = accordionHeader

        	-- Expand/Collapse arrow
        	local accordionArrow = Instance.new("TextLabel")
        	accordionArrow.Size = UDim2.new(0, 30, 1, 0)
        	accordionArrow.Position = UDim2.new(0, 5, 0, 0)
        	accordionArrow.BackgroundTransparency = 1
        	accordionArrow.Text = isExpanded and "▼" or "►"
        	accordionArrow.TextColor3 = Colors.Text.Secondary
        	accordionArrow.TextSize = 12
        	accordionArrow.Font = Enum.Font.SourceSansBold
        	accordionArrow.ZIndex = 5
        	accordionArrow.Parent = accordionHeader

        	-- Icon (optional)
        	local accordionIcon = Instance.new("TextLabel")
        	accordionIcon.Size = UDim2.new(0, 25, 1, 0)
        	accordionIcon.Position = UDim2.new(0, 30, 0, 0)
        	accordionIcon.BackgroundTransparency = 1
        	accordionIcon.Text = icon
        	accordionIcon.TextColor3 = Colors.Text.Primary
        	accordionIcon.TextXAlignment = Enum.TextXAlignment.Center
        	accordionIcon.Font = Enum.Font.SourceSans
        	accordionIcon.TextSize = 14
        	accordionIcon.ZIndex = 5
        	accordionIcon.Parent = accordionHeader

        	-- Accordion title
        	local accordionTitle = Instance.new("TextLabel")
        	accordionTitle.Size = UDim2.new(1, -70, 1, 0)
        	accordionTitle.Position = UDim2.new(0, 60, 0, 0)
        	accordionTitle.BackgroundTransparency = 1
        	accordionTitle.Text = title
        	accordionTitle.TextColor3 = Colors.Text.Primary
        	accordionTitle.TextXAlignment = Enum.TextXAlignment.Left
        	accordionTitle.Font = Enum.Font.SourceSansBold
        	accordionTitle.TextSize = 14
        	accordionTitle.ZIndex = 5
        	accordionTitle.Parent = accordionHeader

        	-- Accordion content container (no scroll)
        	local accordionContent = Instance.new("Frame")
        	accordionContent.Size = UDim2.new(1, 0, 0, 0) -- Start with 0 height
        	accordionContent.Position = UDim2.new(0, 0, 0, 32) -- Below header
        	accordionContent.BackgroundColor3 = Colors.Background.Tertiary
        	accordionContent.BorderSizePixel = 0
        	accordionContent.Visible = isExpanded
        	accordionContent.ClipsDescendants = false -- Don't clip content
        	accordionContent.ZIndex = 4
        	accordionContent.Parent = accordionContainer

        	-- Round corners for content
        	local contentCorner = Instance.new("UICorner")
        	contentCorner.CornerRadius = UDim.new(0, 4)
        	contentCorner.Parent = accordionContent

        	-- Add padding to accordion content
        	local contentPadding = Instance.new("UIPadding")
        	contentPadding.PaddingTop = UDim.new(0, 5)
        	contentPadding.PaddingBottom = UDim.new(0, 5)
        	contentPadding.PaddingLeft = UDim.new(0, 5)
        	contentPadding.PaddingRight = UDim.new(0, 5)
        	contentPadding.Parent = accordionContent

        	-- Content layout
        	local contentLayout = Instance.new("UIListLayout")
        	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        	contentLayout.Padding = UDim.new(0, 5)
        	contentLayout.Parent = accordionContent

        	-- Track layout order for accordion content (UIListLayout handles actual positioning)
        	local accordionCurrentY = 1

        	-- Function to update positions of all components below this accordion (FROM UI.LUA)
        	local function updateComponentsBelow()
        		-- Get current accordion bottom position
        		local accordionBottom = accordionContainer.Position.Y.Offset + accordionContainer.Size.Y.Offset

        		-- Create a list of all components with their Y positions
        		local components = {}
        		for _, child in pairs(tabContent:GetChildren()) do
        			if child:IsA("GuiObject") and child ~= accordionContainer then
        				-- Check if this component has a stored start Y position
        				local componentStartY = child:GetAttribute("ComponentStartY")
        				if componentStartY and componentStartY > accordionStartY then
        					table.insert(components, {
        						component = child,
        						originalY = componentStartY,
        						currentY = child.Position.Y.Offset
        					})
        				end
        			end
        		end

        		-- Sort components by their original Y position
        		table.sort(components, function(a, b)
        			return a.originalY < b.originalY
        		end)

        		-- Update positions of components that come after this accordion
        		local nextY = accordionBottom + 5
        		for _, componentData in ipairs(components) do
        			componentData.component.Position = UDim2.new(0, 10, 0, nextY)
        			-- Add the component's height to calculate next position
        			nextY = nextY + componentData.component.Size.Y.Offset + 5
        		end
        	end

        	-- Function to recalculate total tab height (FROM UI.LUA)
        	local function recalculateTabHeight()
        		-- Wait to ensure all size updates are rendered
        		task.wait()

        		-- Callback to parent tab to recalculate
        		if config.OnHeightChanged then
        			config.OnHeightChanged()
        		end
        	end

        	-- Function to update accordion container size (FROM UI.LUA)
        	local function updateAccordionSize()
        		-- Get the actual content size from UIListLayout
        		local actualContentHeight = contentLayout.AbsoluteContentSize.Y + 20 -- Add padding
        		accordionContentHeight = actualContentHeight

        		-- Update accordion container size
        		local totalHeight = 35 + (isExpanded and accordionContentHeight or 0)
        		accordionContainer.Size = UDim2.new(1, -20, 0, totalHeight)

        		-- Update accordion content frame size
        		if isExpanded then
        			accordionContent.Size = UDim2.new(1, 0, 0, accordionContentHeight)
        		end

        		-- Update positions of components below
        		updateComponentsBelow()

        		-- Recalculate total tab height
        		recalculateTabHeight()
        	end

        	-- Auto-update accordion size when content layout changes (now that updateAccordionSize is defined)
        	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        		-- Always update the content height, regardless of expanded state
        		updateAccordionSize()
        	end)

        	-- Animation function for smooth expand/collapse (FROM UI.LUA)
        	local function animateAccordion()
        		local TweenService = game:GetService("TweenService")

        		-- Calculate sizes BEFORE any changes
        		local oldContainerHeight = accordionContainer.Size.Y.Offset
        		local targetContentHeight = isExpanded and accordionContentHeight or 0
        		local targetContainerHeight = 35 + targetContentHeight
        		local heightDifference = targetContainerHeight - oldContainerHeight

        		-- Store components that come after this accordion BEFORE size changes
        		local componentsBelow = {}
        		local accordionBottom = accordionContainer.Position.Y.Offset + oldContainerHeight

        		for _, child in pairs(tabContent:GetChildren()) do
        			if child:IsA("GuiObject") and child ~= accordionContainer then
        				local childY = child.Position.Y.Offset
        				if childY > accordionBottom then
        					table.insert(componentsBelow, {
        						component = child,
        						currentY = childY,
        						targetY = childY + heightDifference
        					})
        				end
        			end
        		end

        		-- Update arrow direction
        		accordionArrow.Text = isExpanded and "▼" or "►"

        		-- Show content immediately if expanding
        		if isExpanded then
        			accordionContent.Visible = true
        		end

        		-- Animate container size
        		local containerTween = TweenService:Create(
        			accordionContainer,
        			TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        			{Size = UDim2.new(1, -20, 0, targetContainerHeight)}
        		)

        		-- Animate content size
        		local contentTween = TweenService:Create(
        			accordionContent,
        			TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        			{Size = UDim2.new(1, 0, 0, targetContentHeight)}
        		)

        		-- Animate components below
        		for _, componentData in ipairs(componentsBelow) do
        			local componentTween = TweenService:Create(
        				componentData.component,
        				TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        				{Position = UDim2.new(0, 10, 0, componentData.targetY)}
        			)
        			componentTween:Play()
        		end

        		containerTween:Play()
        		contentTween:Play()

        		-- Handle animation completion
        		containerTween.Completed:Connect(function()
        			-- Hide content after collapse animation
        			if not isExpanded then
        				accordionContent.Visible = false
        			end

        			-- Wait for next frame to ensure sizes are updated
        			task.wait()

        			-- Recalculate total tab height
        			recalculateTabHeight()
        		end)
        	end

        	-- Header click handler
        	accordionHeader.MouseButton1Click:Connect(function()
        		isExpanded = not isExpanded
        		animateAccordion()
        	end)

        	-- Header hover effects
        	accordionHeader.MouseEnter:Connect(function()
        		accordionHeader.BackgroundColor3 = Colors.Surface.Hover
        	end)

        	accordionHeader.MouseLeave:Connect(function()
        		accordionHeader.BackgroundColor3 = Colors.Surface.Default
        	end)

        	-- Create accordion API
        	local accordionAPI = {
        		Container = accordionContainer,
        		ContentFrame = accordionContent,
        	}

        	-- Create accordion API
        	local accordionAPI = {
        		Container = accordionContainer,
        		ContentFrame = accordionContent,
        	}

        	-- Accordion control methods
        	function accordionAPI:Expand()
        		if not isExpanded then
        			isExpanded = true
        			animateAccordion()
        			if callback then callback(true) end -- true = dibuka
        		end
        	end

        	function accordionAPI:Collapse()
        		if isExpanded then
        			isExpanded = false
        			animateAccordion()
        			if callback then callback(false) end -- false = ditutup
        		end
        	end

        	function accordionAPI:Toggle()
        	isExpanded = not isExpanded
        	animateAccordion()
        	if callback then callback(isExpanded) end -- true/false
        	return isExpanded
        	end

        	function accordionAPI:IsExpanded()
        		return isExpanded
        	end

        	function accordionAPI:SetTitle(newTitle)
        		title = newTitle
        		accordionTitle.Text = newTitle
        	end

        	function accordionAPI:SetIcon(newIcon)
        		icon = newIcon
        		accordionIcon.Text = newIcon
        	end

        	function accordionAPI:GetHeight()
        		return accordionContainer.AbsoluteSize.Y
        	end

        	function accordionAPI:GetContentHeight()
        		return accordionContentHeight
        	end

        	-- Add Label method
        	function accordionAPI:AddLabel(labelConfig)
        		if not Label then return nil end

        		local lblConfig
        		if type(labelConfig) == "string" then
        			lblConfig = {Text = labelConfig}
        		elseif type(labelConfig) == "function" then
        			lblConfig = {Text = labelConfig}
        		elseif type(labelConfig) == "table" then
        			lblConfig = labelConfig
        		else
        			lblConfig = {}
        		end

        		lblConfig.Parent = accordionContent
        		lblConfig.Y = 0
        		lblConfig.IsForAccordion = true
        		-- Size and Color are already passed through if they exist in labelConfig table

        		local labelAPI = Label:Create(lblConfig)
        		if labelAPI and labelAPI.Label then
        			-- UIListLayout will handle positioning automatically
        			labelAPI.Label.LayoutOrder = accordionCurrentY
        			accordionCurrentY = accordionCurrentY + 1 -- Just increment counter for LayoutOrder
        		end

        		-- Update accordion size (the connection should handle this automatically)
        		updateAccordionSize()

        		if isExpanded then
        			animateAccordion()
        		end

        		return labelAPI
        	end

        	-- Add Button method
        	function accordionAPI:AddButton(buttonConfig)
        		if not Button then return nil end

        		local btnConfig
        		if type(buttonConfig) == "string" then
        			btnConfig = {Text = buttonConfig}
        		elseif type(buttonConfig) == "table" then
        			btnConfig = buttonConfig
        		else
        			btnConfig = {}
        		end

        		btnConfig.Parent = accordionContent
        		btnConfig.Y = 0
        		btnConfig.IsForAccordion = true
        		btnConfig.EzUI = config.EzUI
        		btnConfig.SaveConfiguration = config.SaveConfiguration
        		btnConfig.RegisterComponent = config.RegisterComponent

        		local buttonAPI = Button:Create(btnConfig)
        		if buttonAPI and buttonAPI.Button then
        			buttonAPI.Button.LayoutOrder = accordionCurrentY
        			accordionCurrentY = accordionCurrentY + 1 -- UIListLayout handles positioning
        		end
        		updateAccordionSize()

        		if isExpanded then
        			animateAccordion()
        		end

        		return buttonAPI
        	end

        	-- Add Toggle method
        	function accordionAPI:AddToggle(toggleConfig)
        		if not Toggle then return nil end

        		toggleConfig = toggleConfig or {}
        		toggleConfig.Parent = accordionContent
        		toggleConfig.Y = 0
        		toggleConfig.IsForAccordion = true
        		toggleConfig.EzUI = config.EzUI
        		toggleConfig.SaveConfiguration = config.SaveConfiguration
        		toggleConfig.RegisterComponent = config.RegisterComponent
        		toggleConfig.Settings= config.Settings

        		local toggleAPI = Toggle:Create(toggleConfig)
        		if toggleAPI and toggleAPI.Toggle then
        			toggleAPI.Toggle.LayoutOrder = accordionCurrentY
        			accordionCurrentY = accordionCurrentY + 1 -- UIListLayout handles positioning
        		end
        		updateAccordionSize()

        		if isExpanded then
        			animateAccordion()
        		end

        		return toggleAPI
        	end

        	-- Add TextBox method
        	function accordionAPI:AddTextBox(textboxConfig)
        		if not TextBox then return nil end

        		textboxConfig = textboxConfig or {}
        		textboxConfig.Parent = accordionContent
        		textboxConfig.Y = 0
        		textboxConfig.IsForAccordion = true
        		textboxConfig.EzUI = config.EzUI
        		textboxConfig.SaveConfiguration = config.SaveConfiguration
        		textboxConfig.RegisterComponent = config.RegisterComponent
        		textboxConfig.Settings= config.Settings

        		local textboxAPI = TextBox:Create(textboxConfig)
        		if textboxAPI and textboxAPI.TextBox then
        			textboxAPI.TextBox.LayoutOrder = accordionCurrentY
        			accordionCurrentY = accordionCurrentY + 1 -- UIListLayout handles positioning
        		end
        		updateAccordionSize()

        		if isExpanded then
        			animateAccordion()
        		end

        		return textboxAPI
        	end

        	-- Add NumberBox method
        	function accordionAPI:AddNumberBox(numberboxConfig)
        		if not NumberBox then return nil end

        		numberboxConfig = numberboxConfig or {}
        		numberboxConfig.Parent = accordionContent
        		numberboxConfig.Y = 0
        		numberboxConfig.IsForAccordion = true
        		numberboxConfig.EzUI = config.EzUI
        		numberboxConfig.SaveConfiguration = config.SaveConfiguration
        		numberboxConfig.RegisterComponent = config.RegisterComponent
        		numberboxConfig.Settings= config.Settings

        		local numberboxAPI = NumberBox:Create(numberboxConfig)
        		if numberboxAPI and numberboxAPI.NumberBox then
        			numberboxAPI.NumberBox.LayoutOrder = accordionCurrentY
        			accordionCurrentY = accordionCurrentY + 1 -- UIListLayout handles positioning
        		end
        		updateAccordionSize()

        		if isExpanded then
        			animateAccordion()
        		end

        		return numberboxAPI
        	end

        	-- Add SelectBox method
        	function accordionAPI:AddSelectBox(selectboxConfig)
        		if not SelectBox then return nil end

        		selectboxConfig = selectboxConfig or {}
        		selectboxConfig.Parent = accordionContent
        		selectboxConfig.Y = 0
        		selectboxConfig.IsForAccordion = true
        		selectboxConfig.ScreenGui = config.ScreenGui
        		selectboxConfig.EzUI = config.EzUI
        		selectboxConfig.SaveConfiguration = config.SaveConfiguration
        		selectboxConfig.RegisterComponent = config.RegisterComponent
        		selectboxConfig.Settings= config.Settings

        		local selectboxAPI = SelectBox:Create(selectboxConfig)
        		if selectboxAPI and selectboxAPI.SelectBox then
        			selectboxAPI.SelectBox.LayoutOrder = accordionCurrentY
        			accordionCurrentY = accordionCurrentY + 1 -- UIListLayout handles positioning
        		end
        		updateAccordionSize()

        		if isExpanded then
        			animateAccordion()
        		end

        		return selectboxAPI
        	end

        	-- Add Separator method
        	function accordionAPI:AddSeparator(separatorConfig)
        		if not Separator then return nil end

        		separatorConfig = separatorConfig or {}
        		separatorConfig.Parent = accordionContent
        		separatorConfig.Y = 0
        		separatorConfig.IsForAccordion = true

        		local separatorAPI = Separator:Create(separatorConfig)
        		if separatorAPI and separatorAPI.Separator then
        			separatorAPI.Separator.LayoutOrder = accordionCurrentY
        			accordionCurrentY = accordionCurrentY + 1 -- UIListLayout handles positioning
        		end
        		updateAccordionSize()

        		if isExpanded then
        			animateAccordion()
        		end

        		return separatorAPI
        	end

        	-- Initialize with expanded state
        	if isExpanded then
        		updateAccordionSize()
        		-- Don't animate on initial load, just set the size directly
        		accordionContainer.Size = UDim2.new(1, -20, 0, 35 + accordionContentHeight)
        		accordionContent.Size = UDim2.new(1, 0, 0, accordionContentHeight)
        		accordionContent.Visible = true
        		accordionArrow.Text = "▼"
        	end

        	return accordionAPI
        end

        return Accordion

    end

    -- Module: components/button
    EmbeddedModules["components/button"] = function()
        --[[
        	Button Component
        	EzUI Library - Modular Component

        	Creates a clickable button with hover effects
        ]]
        local Button = {}

        local Colors

        function Button:Init(_colors)
        	Colors = _colors
        end

        function Button:Create(config)
        	local text = config.Text or config.Label or config.Title or config.Name or "Button"
        	local callback = config.Callback or function() end
        	local variant = config.Variant or "primary"
        	local parentContainer = config.Parent
        	local currentY = config.Y or 0
        	local isForAccordion = config.IsForAccordion or false

        	-- Handle case where Parent might be a component API object instead of Instance
        	if parentContainer and type(parentContainer) == "table" then
        		-- Look for common GUI object properties in component APIs
        		if parentContainer.Frame then
        			parentContainer = parentContainer.Frame
        		elseif parentContainer.Button then
        			parentContainer = parentContainer.Button
        		elseif parentContainer.Label then
        			parentContainer = parentContainer.Label
        		elseif parentContainer.Container then
        			parentContainer = parentContainer.Container
        		else
        			-- List available keys for debugging
        			local keys = {}
        			for k, v in pairs(parentContainer) do
        				table.insert(keys, tostring(k))
        			end
        			warn("Button:Create - Parent is a table but no GUI object found. Keys:", table.concat(keys, ", "))
        			parentContainer = nil
        		end
        	end

        	-- Validate parent is an Instance
        	if parentContainer and not typeof(parentContainer) == "Instance" then
        		warn("Button:Create - Parent must be an Instance, got:", typeof(parentContainer))
        		parentContainer = nil
        	end

        	-- Function to get variant colors (UMBRELLA CORP: Updated with Umbrella Red)
        	local function getVariantColors(variantName)
        		local variants = {
        			primary = {
        				background = Colors.Umbrella.Red,
        				backgroundHover = Colors.Umbrella.RedBright,
        				backgroundActive = Colors.Umbrella.RedDark,
        				text = Colors.Text.Primary,
        				border = Colors.Umbrella.RedDark
        			},
        			secondary = {
        				background = Colors.Surface.Default,
        				backgroundHover = Colors.Surface.Hover,
        				backgroundActive = Colors.Surface.Active,
        				text = Colors.Text.Primary,
        				border = Colors.Umbrella.Red
        			},
        			success = {
        				background = Colors.Button.Success,
        				backgroundHover = Colors.Button.SuccessHover,
        				backgroundActive = Colors.Button.SuccessActive,
        				text = Colors.Text.Primary,
        				border = Colors.Button.Success
        			},
        			warning = {
        				background = Colors.Button.Warning,
        				backgroundHover = Colors.Button.WarningHover,
        				backgroundActive = Colors.Button.WarningActive,
        				text = Colors.Background.Primary,
        				border = Colors.Button.Warning
        			},
        			danger = {
        				background = Colors.Umbrella.Red,
        				backgroundHover = Colors.Umbrella.RedBright,
        				backgroundActive = Colors.Umbrella.RedDark,
        				text = Colors.Text.Primary,
        				border = Colors.Umbrella.RedDark
        			},
        			info = {
        				background = Colors.Status.Info,
        				backgroundHover = Color3.fromRGB(120, 170, 255),
        				backgroundActive = Color3.fromRGB(80, 130, 235),
        				text = Colors.Text.Primary,
        				border = Colors.Status.Info
        			},
        			light = {
        				background = Colors.Surface.Elevated,
        				backgroundHover = Colors.Surface.Hover,
        				backgroundActive = Colors.Surface.Active,
        				text = Colors.Text.Primary,
        				border = Colors.Border.Light
        			},
        			dark = {
        				background = Colors.Background.Primary,
        				backgroundHover = Colors.Background.Secondary,
        				backgroundActive = Colors.Surface.Active,
        				text = Colors.Text.Primary,
        				border = Colors.Border.Dark
        			}
        		}

        		return variants[variantName] or variants.primary
        	end

        	local variantColors = getVariantColors(variant)

        	local button = Instance.new("TextButton")
        	if isForAccordion then
        		-- Make button width responsive to content (takes full available width)
        		button.Size = UDim2.new(1, -10, 0, 25)
        		-- Don't set Position for accordion buttons - let UIListLayout handle it
        		button.BorderSizePixel = 0
        		button.TextSize = 12
        		button.ZIndex = 5

        		-- Round corners for accordion button
        		local buttonCorner = Instance.new("UICorner")
        		buttonCorner.CornerRadius = UDim.new(0, 4)
        		buttonCorner.Parent = button

        		-- Border for secondary variant
        		if variant == "secondary" then
        			local buttonBorder = Instance.new("UIStroke")
        			buttonBorder.Color = variantColors.border
        			buttonBorder.Thickness = 1
        			buttonBorder.Parent = button
        		end

        		-- Button hover effects for accordion
        		button.MouseEnter:Connect(function()
        			button.BackgroundColor3 = variantColors.backgroundHover
        		end)

        		button.MouseLeave:Connect(function()
        			button.BackgroundColor3 = variantColors.background
        		end)
        	else
        		-- UMBRELLA CORP: 30px height for better spacing (5px gap with +35 increment), 150px width, 16px padding, 6px corner, 14px text, Gotham Semibold
        		button.Size = UDim2.new(0, 150, 0, 30)
        		button.Position = UDim2.new(0, 10, 0, currentY)
        		button.BorderSizePixel = 0
        		button.TextSize = 14
        		button.ZIndex = 3
        		button:SetAttribute("ComponentStartY", currentY)

        		-- Round corners (6px)
        		local buttonCorner = Instance.new("UICorner")
        		buttonCorner.CornerRadius = UDim.new(0, 6)
        		buttonCorner.Parent = button

        		-- Padding
        		local buttonPadding = Instance.new("UIPadding")
        		buttonPadding.PaddingLeft = UDim.new(0, 16)
        		buttonPadding.PaddingRight = UDim.new(0, 16)
        		buttonPadding.Parent = button

        		-- Glow for primary button (UMBRELLA CORP: red glow, transparency 0.8)
        		if variant == "primary" or variant == "danger" then
        			local buttonGlow = Instance.new("UIStroke")
        			buttonGlow.Color = Colors.Umbrella.Red
        			buttonGlow.Thickness = 1
        			buttonGlow.Transparency = 0.8
        			buttonGlow.Parent = button
        		end

        		-- Border for secondary variant
        		if variant == "secondary" then
        			local buttonBorder = Instance.new("UIStroke")
        			buttonBorder.Color = variantColors.border
        			buttonBorder.Thickness = 1
        			buttonBorder.Transparency = 0.9
        			buttonBorder.Parent = button
        		end

        		-- Shadow (UMBRELLA CORP: Black, transparency 0.7, rounded corners)
        		local buttonShadow = Instance.new("Frame")
        		buttonShadow.Size = UDim2.new(1, 2, 1, 2)
        		buttonShadow.Position = UDim2.new(0, -1, 0, 1)
        		buttonShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        		buttonShadow.BackgroundTransparency = 0.7
        		buttonShadow.BorderSizePixel = 0
        		buttonShadow.ZIndex = button.ZIndex - 1
        		buttonShadow.Parent = button

        		-- Rounded corners for shadow - match button corner radius
        		local shadowCorner = Instance.new("UICorner")
        		shadowCorner.CornerRadius = UDim.new(0, 6)
        		shadowCorner.Parent = buttonShadow
        	end
        	button.BackgroundColor3 = variantColors.background
        	button.Text = text
        	button.TextColor3 = variantColors.text
        	button.Font = Enum.Font.GothamBold
        	button.TextScaled = false  -- Keep original text size
        	button.TextWrapped = false -- Don't wrap text to new lines
        	button.TextTruncate = Enum.TextTruncate.AtEnd -- Add ... at end if text is too long
        	button.Parent = parentContainer

        	-- Add hover effects for non-accordion buttons (UMBRELLA CORP: 0.15s Quad transition, glow 0.8 → 0.4)
        	if not isForAccordion then
        		button.MouseEnter:Connect(function()
        			local TweenService = game:GetService("TweenService")
        			local hoverTween = TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        				BackgroundColor3 = variantColors.backgroundHover
        			})
        			hoverTween:Play()

        			-- Update glow on hover
        			local glow = button:FindFirstChild("UIStroke")
        			if glow and (variant == "primary" or variant == "danger") then
        				local glowTween = TweenService:Create(glow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        					Transparency = 0.4
        				})
        				glowTween:Play()
        			end
        		end)

        		button.MouseLeave:Connect(function()
        			local TweenService = game:GetService("TweenService")
        			local leaveTween = TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        				BackgroundColor3 = variantColors.background
        			})
        			leaveTween:Play()

        			-- Reset glow
        			local glow = button:FindFirstChild("UIStroke")
        			if glow and (variant == "primary" or variant == "danger") then
        				local glowTween = TweenService:Create(glow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        					Transparency = 0.8
        				})
        				glowTween:Play()
        			end
        		end)
        	end

        	if callback then
        		button.MouseButton1Click:Connect(callback)
        	end

        	-- Create Button API
        	local buttonAPI = {
        		Button = button
        	}

        	function buttonAPI:SetText(newText)
        		button.Text = newText or ""
        	end

        	function buttonAPI:GetText()
        		return button.Text
        	end

        	function buttonAPI:SetCallback(newCallback)
        		callback = newCallback or function() end
        		button.MouseButton1Click:Connect(callback)
        	end

        	function buttonAPI:SetEnabled(enabled)
        		button.Active = enabled
        		if enabled then
        			button.BackgroundColor3 = variantColors.background
        		else
        			-- Create a disabled version by reducing opacity/brightness
        			local r, g, b = variantColors.background.R, variantColors.background.G, variantColors.background.B
        			button.BackgroundColor3 = Color3.fromRGB(
        				math.floor(r * 255 * 0.5),
        				math.floor(g * 255 * 0.5),
        				math.floor(b * 255 * 0.5)
        			)
        		end
        	end

        	function buttonAPI:SetVariant(newVariant)
        		variant = newVariant or "primary"
        		variantColors = getVariantColors(variant)

        		-- Update button colors
        		button.BackgroundColor3 = variantColors.background
        		button.TextColor3 = variantColors.text
        		if isForAccordion then
        			button.BorderColor3 = variantColors.border
        		end
        	end

        	function buttonAPI:GetVariant()
        		return variant
        	end

        	return buttonAPI
        end

        return Button

    end

    -- Module: components/numberbox
    EmbeddedModules["components/numberbox"] = function()
        --[[
        	NumberBox Component
        	EzUI Library - Modular Component

        	Creates a numeric input field with increment/decrement buttons
        ]]
        local NumberBox = {}

        local Colors

        function NumberBox:Init(_colors)
        	Colors = _colors
        end

        function NumberBox:Create(config)
        	local name = config.Name or config.Title or ""
        	local placeholder = config.Placeholder or "Enter number..."
        	local defaultValue = config.Default or 0
        	local callback = config.Callback or function() end
        	local minValue = config.Min or -math.huge
        	local maxValue = config.Max or math.huge
        	local increment = config.Increment or 1
        	local decimals = config.Decimals or 0
        	local flag = config.Flag
        	local parentContainer = config.Parent
        	local currentY = config.Y or 0
        	local isForAccordion = config.IsForAccordion or false
        	local EzUI = config.EzUI
        	local saveConfiguration = config.SaveConfiguration
        	local registerComponent = config.RegisterComponent
        	local settings = config.Settings

        	-- Handle case where Parent might be a component API object instead of Instance
        	if parentContainer and type(parentContainer) == "table" then
        		-- Look for common GUI object properties in component APIs
        		if parentContainer.Frame then
        			parentContainer = parentContainer.Frame
        		elseif parentContainer.Button then
        			parentContainer = parentContainer.Button
        		elseif parentContainer.Label then
        			parentContainer = parentContainer.Label
        		elseif parentContainer.Container then
        			parentContainer = parentContainer.Container
        		else
        			-- List available keys for debugging
        			local keys = {}
        			for k, v in pairs(parentContainer) do
        				table.insert(keys, tostring(k))
        			end
        			warn("NumberBox:Create - Parent is a table but no GUI object found. Keys:", table.concat(keys, ", "))
        			parentContainer = nil
        		end
        	end

        	-- Validate parent is an Instance
        	if parentContainer and not typeof(parentContainer) == "Instance" then
        		warn("NumberBox:Create - Parent must be an Instance, got:", typeof(parentContainer))
        		parentContainer = nil
        	end

        	-- NumberBox state
        	local currentValue = defaultValue

        	-- Load from flag (supports both EzUI.Flags and custom config)
        	if flag then
        		local flagValue = nil

        		-- Check if using custom config object
        		if settings and type(settings.GetValue) == "function" then
        			flagValue = settings:GetValue(flag)
        		end

        		if flagValue ~= nil then
        			currentValue = flagValue
        			defaultValue = currentValue
        		end
        	end

        	-- Main numberbox container
        	local numberBoxContainer = Instance.new("Frame")
        	if isForAccordion then
        		numberBoxContainer.Size = UDim2.new(1, -10, 0, 25)
        		-- Don't set Position for accordion numberboxes - let UIListLayout handle it
        		numberBoxContainer.ZIndex = 6
        	else
        		numberBoxContainer.Size = UDim2.new(1, -20, 0, 30)
        		numberBoxContainer.Position = UDim2.new(0, 10, 0, currentY)
        		numberBoxContainer.ZIndex = 3
        		numberBoxContainer:SetAttribute("ComponentStartY", currentY)
        	end
        	numberBoxContainer.BackgroundTransparency = 1
        	numberBoxContainer.ClipsDescendants = true -- Ensure text doesn't overflow container
        	numberBoxContainer.Parent = parentContainer

        	-- Number input box
        	local numberBox = Instance.new("TextBox")
        	if isForAccordion then
        		numberBox.Size = UDim2.new(1, -45, 1, 0)
        		numberBox.TextSize = 12
        		numberBox.ZIndex = 7
        	else
        		numberBox.Size = UDim2.new(1, -60, 1, 0)
        		numberBox.TextSize = 14
        		numberBox.ZIndex = 4
        	end
        	numberBox.Position = UDim2.new(0, 0, 0, 0)
        	numberBox.BackgroundColor3 = Colors.Input.Background
        	numberBox.BorderColor3 = Colors.Input.Border
        	numberBox.BorderSizePixel = 1
        	numberBox.Text = decimals > 0 and string.format("%." .. decimals .. "f", defaultValue) or tostring(defaultValue)
        	numberBox.PlaceholderText = placeholder
        	numberBox.TextColor3 = Colors.Input.Text
        	numberBox.PlaceholderColor3 = Colors.Input.Placeholder
        	numberBox.Font = Enum.Font.SourceSans
        	numberBox.TextXAlignment = Enum.TextXAlignment.Center
        	numberBox.TextYAlignment = Enum.TextYAlignment.Center
        	numberBox.TextScaled = false -- Prevent text from scaling down automatically
        	numberBox.ClipsDescendants = true -- Clip text that overflows the TextBox
        	numberBox.ClearTextOnFocus = false
        	numberBox.Parent = numberBoxContainer

        	-- Add padding to NumberBox
        	local padding = Instance.new("UIPadding")
        	padding.PaddingLeft = UDim.new(0, 8)
        	padding.PaddingRight = UDim.new(0, 8)
        	padding.PaddingTop = UDim.new(0, 0)
        	padding.PaddingBottom = UDim.new(0, 0)
        	padding.Parent = numberBox

        	-- Round corners for number box
        	local numberCorner = Instance.new("UICorner")
        	numberCorner.CornerRadius = UDim.new(0, 4)
        	numberCorner.Parent = numberBox

        	-- Increment button (up arrow)
        	local incrementBtn = Instance.new("TextButton")
        	if isForAccordion then
        		incrementBtn.Size = UDim2.new(0, 20, 0, 12)
        		incrementBtn.Position = UDim2.new(1, -22, 0, 1)
        		incrementBtn.TextSize = 8
        		incrementBtn.ZIndex = 7
        	else
        		incrementBtn.Size = UDim2.new(0, 25, 0, 14)
        		incrementBtn.Position = UDim2.new(1, -30, 0, 1)
        		incrementBtn.TextSize = 10
        		incrementBtn.ZIndex = 4
        	end
        	incrementBtn.BackgroundColor3 = Colors.Surface.Default
        	incrementBtn.BorderColor3 = Colors.Border.Default
        	incrementBtn.BorderSizePixel = 1
        	incrementBtn.Text = "▲"
        	incrementBtn.TextColor3 = Colors.Text.Secondary
        	incrementBtn.Font = Enum.Font.SourceSans
        	incrementBtn.Parent = numberBoxContainer

        	-- Decrement button (down arrow)
        	local decrementBtn = Instance.new("TextButton")
        	if isForAccordion then
        		decrementBtn.Size = UDim2.new(0, 20, 0, 12)
        		decrementBtn.Position = UDim2.new(1, -22, 0, 13)
        		decrementBtn.TextSize = 8
        		decrementBtn.ZIndex = 7
        	else
        		decrementBtn.Size = UDim2.new(0, 25, 0, 14)
        		decrementBtn.Position = UDim2.new(1, -30, 0, 15)
        		decrementBtn.TextSize = 10
        		decrementBtn.ZIndex = 4
        	end
        	decrementBtn.BackgroundColor3 = Colors.Surface.Default
        	decrementBtn.BorderColor3 = Colors.Border.Default
        	decrementBtn.BorderSizePixel = 1
        	decrementBtn.Text = "▼"
        	decrementBtn.TextColor3 = Colors.Text.Secondary
        	decrementBtn.Font = Enum.Font.SourceSans
        	decrementBtn.Parent = numberBoxContainer

        	-- Calculate heights based on whether we have a title label
        	local hasTitle = name and name ~= ""
        	local labelHeight = hasTitle and 18 or 0
        	local inputHeight = isForAccordion and 25 or 30
        	local totalHeight = labelHeight + inputHeight + (hasTitle and 2 or 0) -- 2px spacing between label and input

        	-- Adjust container size
        	if isForAccordion then
        		numberBoxContainer.Size = UDim2.new(1, -10, 0, totalHeight)
        	else
        		numberBoxContainer.Size = UDim2.new(1, -20, 0, totalHeight)
        	end

        	-- Title label (if name is provided)
        	if hasTitle then
        		local titleLabel = Instance.new("TextLabel")
        		titleLabel.Size = UDim2.new(1, 0, 0, labelHeight)
        		titleLabel.Position = UDim2.new(0, 0, 0, 0)
        		titleLabel.BackgroundTransparency = 1
        		titleLabel.Text = name
        		titleLabel.TextColor3 = Colors.Text.Primary
        		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        		titleLabel.Font = Enum.Font.SourceSans
        		titleLabel.TextSize = isForAccordion and 12 or 14
        		titleLabel.ZIndex = isForAccordion and 7 or 4
        		titleLabel.Parent = numberBoxContainer
        	end

        	-- Adjust numberBox position and size
        	if hasTitle then
        		numberBox.Position = UDim2.new(0, 0, 0, labelHeight + 2) -- Add spacing below title
        		numberBox.Size = UDim2.new(1, -60, 0, inputHeight)
        	else
        		numberBox.Position = UDim2.new(0, 0, 0, 0)
        	end

        	-- Adjust increment and decrement button positions
        	if hasTitle then
        		-- Position buttons relative to numberBox when title exists
        		local buttonY = labelHeight + 2
        		if isForAccordion then
        			incrementBtn.Position = UDim2.new(1, -22, 0, buttonY + 1)
        			decrementBtn.Position = UDim2.new(1, -22, 0, buttonY + 13)
        		else
        			incrementBtn.Position = UDim2.new(1, -30, 0, buttonY + 1)
        			decrementBtn.Position = UDim2.new(1, -30, 0, buttonY + 15)
        		end
        	else
        		-- Keep original positions when no title
        		if isForAccordion then
        			incrementBtn.Position = UDim2.new(1, -22, 0, 1)
        			decrementBtn.Position = UDim2.new(1, -22, 0, 13)
        		else
        			incrementBtn.Position = UDim2.new(1, -30, 0, 1)
        			decrementBtn.Position = UDim2.new(1, -30, 0, 15)
        		end
        	end

        	-- Function to validate and update value
        	local function updateValue(newValue)
        		-- Clamp to min/max
        		newValue = math.max(minValue, math.min(maxValue, newValue))

        		-- Round to decimal places
        		if decimals > 0 then
        			local multiplier = 10 ^ decimals
        			newValue = math.floor(newValue * multiplier + 0.5) / multiplier
        		else
        			newValue = math.floor(newValue + 0.5)
        		end

        		currentValue = newValue

        		-- Update text box display
        		if decimals > 0 then
        			numberBox.Text = string.format("%." .. decimals .. "f", newValue)
        		else
        			numberBox.Text = tostring(newValue)
        		end

        		-- Save to configuration
        		if flag then
        			settings:SetValue(flag, currentValue)
        		end
        		-- Call user callback
        		local success, errorMsg = pcall(function()
        			callback(currentValue)
        		end)

        		if not success then
        			warn("NumberBox callback error:", errorMsg)
        		end

        		return newValue
        	end 

        	-- Text change handler with validation
        	numberBox.FocusLost:Connect(function()
        		local inputText = numberBox.Text
        		local numValue = tonumber(inputText)

        		if numValue then
        			updateValue(numValue)
        		else
        			-- Invalid input, revert to current value
        			if decimals > 0 then
        				numberBox.Text = string.format("%." .. decimals .. "f", currentValue)
        			else
        				numberBox.Text = tostring(currentValue)
        			end
        		end
        	end)

        	-- Increment button handler
        	incrementBtn.MouseButton1Click:Connect(function()
        		updateValue(currentValue + increment)
        	end)

        	-- Decrement button handler
        	decrementBtn.MouseButton1Click:Connect(function()
        		updateValue(currentValue - increment)
        	end)

        	-- Button hover effects
        	incrementBtn.MouseEnter:Connect(function()
        		incrementBtn.BackgroundColor3 = Colors.Surface.Hover
        	end)

        	incrementBtn.MouseLeave:Connect(function()
        		incrementBtn.BackgroundColor3 = Colors.Surface.Default
        	end)

        	decrementBtn.MouseEnter:Connect(function()
        		decrementBtn.BackgroundColor3 = Colors.Surface.Hover
        	end)

        	decrementBtn.MouseLeave:Connect(function()
        		decrementBtn.BackgroundColor3 = Colors.Surface.Default
        	end)

        	-- Focus effects
        	numberBox.Focused:Connect(function()
        		numberBox.BorderColor3 = Colors.Input.BorderFocus
        	end)

        	numberBox.FocusLost:Connect(function()
        		numberBox.BorderColor3 = Colors.Input.Border
        	end)

        	-- Return NumberBox API
        	local numberBoxAPI = {
        		NumberBox = numberBoxContainer
        	}

        	function numberBoxAPI:GetValue()
        		return currentValue
        	end

        	function numberBoxAPI:SetValue(newValue)
        		local numValue = tonumber(newValue)
        		if numValue then
        			updateValue(numValue)
        		else
        			warn("NumberBox SetValue: Expected number, got " .. type(newValue))
        		end
        	end

        	function numberBoxAPI:SetMin(newMin)
        		minValue = tonumber(newMin) or -math.huge
        		updateValue(currentValue)
        	end

        	function numberBoxAPI:SetMax(newMax)
        		maxValue = tonumber(newMax) or math.huge
        		updateValue(currentValue)
        	end

        	function numberBoxAPI:SetIncrement(newIncrement)
        		increment = tonumber(newIncrement) or 1
        	end

        	function numberBoxAPI:Clear()
        		updateValue(0)
        	end

        	function numberBoxAPI:Focus()
        		numberBox:CaptureFocus()
        	end

        	function numberBoxAPI:Blur()
        		numberBox:ReleaseFocus()
        	end

        	function numberBoxAPI:SetCallback(newCallback)
        		callback = newCallback or function() end
        	end

        	function numberBoxAPI:Set(newValue)
        		local numValue = tonumber(newValue)
        		if numValue then
        			updateValue(numValue)
        		end
        	end

        	-- Register component for flag-based updates
        	if registerComponent then
        		registerComponent(flag, numberBoxAPI)
        	end

        	return numberBoxAPI
        end

        return NumberBox
    end

    -- Module: components/selectbox
    EmbeddedModules["components/selectbox"] = function()
        --[[
        local Colors = require(game.ReplicatedStorage.utils.colors)
        	SelectBox Component
        	EzUI Library - Modular Component

        	Creates a dropdown select box with search and multi-select support
        	Note: This is a simplified modular version. For full features, use the main UI library.
        ]]
        local SelectBox = {}

        local Colors

        function SelectBox:Init(_colors)
        	Colors = _colors
        end

        function SelectBox:Create(config)
        	local name = config.Name or config.Title or ""
        	local rawOptions = config.Options or {"Option 1", "Option 2", "Option 3"}
        	local placeholder = config.Placeholder or "Select option..."
        	local multiSelect = config.MultiSelect or false
        	local callback = config.Callback or function() end
        	local onDropdownOpen = config.OnDropdownOpen or function() end
        	local onInit = config.OnInit or function() end
        	local bottomSheetMaxHeight = config.BottomSheetHeight or config.MaxHeight or 320
        	local flag = config.Flag
        	local parentContainer = config.Parent
        	local currentY = config.Y or 0
        	local isForAccordion = config.IsForAccordion or false
        	local screenGui = config.ScreenGui
        	local EzUI = config.EzUI
        	local saveConfiguration = config.SaveConfiguration
        	local registerComponent = config.RegisterComponent
        	local settings = config.Settings

        	-- Handle case where Parent might be a component API object instead of Instance
        	if parentContainer and type(parentContainer) == "table" then
        		-- Look for common GUI object properties in component APIs
        		if parentContainer.Frame then
        			parentContainer = parentContainer.Frame
        		elseif parentContainer.Button then
        			parentContainer = parentContainer.Button
        		elseif parentContainer.Label then
        			parentContainer = parentContainer.Label
        		elseif parentContainer.Container then
        			parentContainer = parentContainer.Container
        		else
        			-- List available keys for debugging
        			local keys = {}
        			for k, v in pairs(parentContainer) do
        				table.insert(keys, tostring(k))
        			end
        			warn("SelectBox:Create - Parent is a table but no GUI object found. Keys:", table.concat(keys, ", "))
        			parentContainer = nil
        		end
        	end

        	-- Validate parent is an Instance
        	if parentContainer and not typeof(parentContainer) == "Instance" then
        		warn("SelectBox:Create - Parent must be an Instance, got:", typeof(parentContainer))
        		parentContainer = nil
        	end

        	-- Normalize options to {text, value} format
        	local options = {}
        	for i, option in ipairs(rawOptions) do
        		if type(option) == "string" then
        			table.insert(options, {text = option, value = option})
        		elseif type(option) == "table" and option.text and option.value then
        			table.insert(options, option)
        		end
        	end

        	local selectedValues = {}
        	local isOpen = false

        	-- Title configuration
        	local hasTitle = name and name ~= ""
        	local labelHeight = isForAccordion and 16 or 18
        	local selectHeight = isForAccordion and 25 or 30
        	local totalHeight = hasTitle and (labelHeight + selectHeight + 2) or selectHeight

        	-- Load from flag (supports both EzUI.Flags and custom config)
        	if flag then
        		local flagValue = nil

        		-- Check if using custom config object
        		if settings and type(settings.GetValue) == "function" then
        			flagValue = settings:GetValue(flag)
        		end

        		if flagValue ~= nil then
        			if type(flagValue) == "table" then
        				selectedValues = flagValue
        			elseif flagValue ~= "" then
        				selectedValues = {flagValue}
        			end
        		end
        	end

        	-- Main container
        	local selectContainer = Instance.new("Frame")
        	if isForAccordion then
        		selectContainer.Size = UDim2.new(1, 0, 0, totalHeight)
        		-- Don't set Position for accordion selectboxes - let UIListLayout handle it
        		selectContainer.ZIndex = 6
        	else
        		selectContainer.Size = UDim2.new(1, -20, 0, totalHeight)
        		selectContainer.Position = UDim2.new(0, 10, 0, currentY)
        		selectContainer.ZIndex = 3
        		selectContainer:SetAttribute("ComponentStartY", currentY)
        	end
        	selectContainer.BackgroundTransparency = 1
        	selectContainer.ClipsDescendants = false
        	selectContainer.Parent = parentContainer

        	-- Title label (if name is provided)
        	local titleLabel = nil
        	if hasTitle then
        		titleLabel = Instance.new("TextLabel")
        		titleLabel.Size = UDim2.new(1, 0, 0, labelHeight)
        		titleLabel.Position = UDim2.new(0, 0, 0, 0)
        		titleLabel.BackgroundTransparency = 1
        		titleLabel.Text = name
        		titleLabel.TextColor3 = Colors.Text.Primary
        		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        		titleLabel.Font = Enum.Font.SourceSans
        		titleLabel.TextSize = isForAccordion and 12 or 14
        		titleLabel.ZIndex = isForAccordion and 7 or 4
        		titleLabel.Parent = selectContainer
        	end

        	-- Select button (modern design)
        	local selectButton = Instance.new("TextButton")
        	if hasTitle then
        		selectButton.Size = UDim2.new(1, 0, 0, selectHeight)
        		selectButton.Position = UDim2.new(0, 0, 0, labelHeight + 2)
        	else
        		selectButton.Size = UDim2.new(1, 0, 1, 0)
        		selectButton.Position = UDim2.new(0, 0, 0, 0)
        	end
        	selectButton.BackgroundColor3 = Colors.Input.Background
        	selectButton.BorderSizePixel = 0
        	selectButton.Text = "  " .. placeholder
        	selectButton.TextColor3 = Colors.Text.Secondary
        	selectButton.TextXAlignment = Enum.TextXAlignment.Left
        	selectButton.Font = Enum.Font.Gotham
        	selectButton.TextSize = isForAccordion and 12 or 14
        	selectButton.TextScaled = false
        	selectButton.ClipsDescendants = true
        	selectButton.ZIndex = isForAccordion and 7 or 4
        	selectButton.Parent = selectContainer

        	-- Chips container for multi-select (scrollable, tighter spacing)
        	local chipsContainer = Instance.new("ScrollingFrame")
        	chipsContainer.Size = UDim2.new(1, -24, 1, -2) -- Reduced gap to arrow
        	chipsContainer.Position = UDim2.new(0, 8, 0, 1)
        	chipsContainer.BackgroundTransparency = 1
        	chipsContainer.BorderSizePixel = 0
        	chipsContainer.ClipsDescendants = true
        	chipsContainer.ScrollBarThickness = 0 -- Hide scrollbar for cleaner look
        	chipsContainer.ScrollingDirection = Enum.ScrollingDirection.X -- Horizontal scroll
        	chipsContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be auto-calculated
        	chipsContainer.ZIndex = selectButton.ZIndex + 1
        	chipsContainer.Parent = selectButton
        	chipsContainer.Visible = false -- Initially hidden

        	-- Chips layout
        	local chipsLayout = Instance.new("UIListLayout")
        	chipsLayout.FillDirection = Enum.FillDirection.Horizontal
        	chipsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        	chipsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        	chipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        	chipsLayout.Padding = UDim.new(0, 4)
        	chipsLayout.Wraps = false -- No wrapping since we're scrolling horizontally
        	chipsLayout.Parent = chipsContainer

        	-- Modern rounded corners
        	local selectCorner = Instance.new("UICorner")
        	selectCorner.CornerRadius = UDim.new(0, 8)
        	selectCorner.Parent = selectButton

        	-- Subtle border effect
        	local selectStroke = Instance.new("UIStroke")
        	selectStroke.Color = Colors.Input.Border
        	selectStroke.Thickness = 1
        	selectStroke.Parent = selectButton

        	-- Padding for better text spacing (further reduced right padding)
        	local selectPadding = Instance.new("UIPadding")
        	selectPadding.PaddingLeft = UDim.new(0, 8)
        	selectPadding.PaddingRight = UDim.new(0, 24)
        	selectPadding.PaddingTop = UDim.new(0, 1)
        	selectPadding.PaddingBottom = UDim.new(0, 1)
        	selectPadding.Parent = selectButton

        	-- Modern arrow icon (embedded in select button, tighter positioning)
        	local arrow = Instance.new("TextLabel")
        	if hasTitle then
        		arrow.Size = UDim2.new(0, 20, 0, selectHeight)
        		arrow.Position = UDim2.new(1, -20, 0, labelHeight + 2)
        	else
        		arrow.Size = UDim2.new(0, 20, 1, 0)
        		arrow.Position = UDim2.new(1, -20, 0, 0)
        	end
        	arrow.BackgroundTransparency = 1
        	arrow.Text = "▼"
        	arrow.TextColor3 = Colors.Text.Secondary
        	arrow.TextXAlignment = Enum.TextXAlignment.Center
        	arrow.TextYAlignment = Enum.TextYAlignment.Center
        	arrow.Font = Enum.Font.GothamBold
        	arrow.TextSize = isForAccordion and 14 or 16
        	arrow.ZIndex = isForAccordion and 8 or 5
        	arrow.Parent = selectContainer

        	-- Find the window frame container
        	local windowFrame = screenGui and screenGui:FindFirstChild("Frame") or selectContainer.Parent
        	while windowFrame and not (windowFrame.Name:find("Frame") and windowFrame.Parent == screenGui) do
        		windowFrame = windowFrame.Parent
        		if windowFrame == screenGui or not windowFrame then
        			windowFrame = screenGui:FindFirstChildOfClass("Frame")
        			break
        		end
        	end

        	-- Bottom sheet overlay (TextButton for click detection)
        	local bottomSheetOverlay = Instance.new("TextButton")
        	bottomSheetOverlay.Size = UDim2.new(1, 0, 1, 0)
        	bottomSheetOverlay.Position = UDim2.new(0, 0, 0, 0)
        	bottomSheetOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        	bottomSheetOverlay.BackgroundTransparency = 0.5
        	bottomSheetOverlay.BorderSizePixel = 0
        	bottomSheetOverlay.Text = ""
        	bottomSheetOverlay.Visible = false
        	bottomSheetOverlay.ZIndex = 100
        	bottomSheetOverlay.Parent = windowFrame or screenGui or selectContainer.Parent

        	-- Bottom sheet container (customizable height)
        	local bottomSheetHeight = math.min(#options * 35 + 90, bottomSheetMaxHeight)
        	local bottomSheet = Instance.new("Frame")
        	bottomSheet.Size = UDim2.new(1, -40, 0, bottomSheetHeight)
        	bottomSheet.Position = UDim2.new(0, 20, 1, 0) -- Start below window
        	bottomSheet.BackgroundColor3 = Colors.Surface.Default
        	bottomSheet.BorderSizePixel = 0
        	bottomSheet.ZIndex = 101
        	bottomSheet.Parent = bottomSheetOverlay

        	-- Modern rounded corners for bottom sheet
        	local bottomSheetCorner = Instance.new("UICorner")
        	bottomSheetCorner.CornerRadius = UDim.new(0, 12)
        	bottomSheetCorner.Parent = bottomSheet

        	-- Handle bar at top of bottom sheet (smaller)
        	local handleBar = Instance.new("Frame")
        	handleBar.Size = UDim2.new(0, 32, 0, 3)
        	handleBar.Position = UDim2.new(0.5, -16, 0, 6)
        	handleBar.BackgroundColor3 = Colors.Text.Secondary
        	handleBar.BorderSizePixel = 0
        	handleBar.ZIndex = 102
        	handleBar.Parent = bottomSheet

        	local handleCorner = Instance.new("UICorner")
        	handleCorner.CornerRadius = UDim.new(0, 1.5)
        	handleCorner.Parent = handleBar

        	-- Title for bottom sheet (smaller)
        	local sheetTitle = Instance.new("TextLabel")
        	sheetTitle.Size = UDim2.new(1, -32, 0, 24)
        	sheetTitle.Position = UDim2.new(0, 16, 0, 16)
        	sheetTitle.BackgroundTransparency = 1
        	sheetTitle.Text = name ~= "" and name or "Select Option"
        	sheetTitle.TextColor3 = Colors.Text.Primary
        	sheetTitle.TextXAlignment = Enum.TextXAlignment.Left
        	sheetTitle.TextYAlignment = Enum.TextYAlignment.Center
        	sheetTitle.Font = Enum.Font.GothamBold
        	sheetTitle.TextSize = 16
        	sheetTitle.ZIndex = 102
        	sheetTitle.Parent = bottomSheet

        	-- Modern search box (smaller)
        	local searchBox = Instance.new("TextBox")
        	searchBox.Size = UDim2.new(1, -32, 0, 32)
        	searchBox.Position = UDim2.new(0, 16, 0, 48)
        	searchBox.BackgroundColor3 = Colors.Input.Background
        	searchBox.BorderSizePixel = 0
        	searchBox.PlaceholderText = "🔍 Search options..."
        	searchBox.Text = ""
        	searchBox.TextColor3 = Colors.Text.Primary
        	searchBox.Font = Enum.Font.Gotham
        	searchBox.TextSize = 13
        	searchBox.TextXAlignment = Enum.TextXAlignment.Left
        	searchBox.ZIndex = 102
        	searchBox.Parent = bottomSheet

        	-- Search box styling
        	local searchCorner = Instance.new("UICorner")
        	searchCorner.CornerRadius = UDim.new(0, 6)
        	searchCorner.Parent = searchBox

        	local searchPadding = Instance.new("UIPadding")
        	searchPadding.PaddingLeft = UDim.new(0, 12)
        	searchPadding.PaddingRight = UDim.new(0, 12)
        	searchPadding.Parent = searchBox

        	-- Options container (scrollable, smaller)
        	local optionsScrollFrame = Instance.new("ScrollingFrame")
        	optionsScrollFrame.Size = UDim2.new(1, -32, 1, -96)
        	optionsScrollFrame.Position = UDim2.new(0, 16, 0, 88)
        	optionsScrollFrame.BackgroundTransparency = 1
        	optionsScrollFrame.BorderSizePixel = 0
        	optionsScrollFrame.ScrollBarThickness = 4
        	optionsScrollFrame.ScrollBarImageColor3 = Colors.Accent.Primary
        	optionsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        	optionsScrollFrame.ZIndex = 102
        	optionsScrollFrame.Parent = bottomSheet

        	local optionsContainer = Instance.new("Frame")
        	optionsContainer.Size = UDim2.new(1, 0, 0, 0) -- Auto-size based on content
        	optionsContainer.Position = UDim2.new(0, 0, 0, 0)
        	optionsContainer.BackgroundTransparency = 1
        	optionsContainer.ZIndex = 103
        	optionsContainer.Parent = optionsScrollFrame

        	-- List layout
        	local listLayout = Instance.new("UIListLayout")
        	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        	listLayout.Parent = optionsContainer

        	-- Forward declarations
        	local updateDisplayText, refreshOptions, removeSelectedValue

        	-- Update display text and chips
        	function updateDisplayText()
        		-- Clear existing chips
        		for _, child in pairs(chipsContainer:GetChildren()) do
        			if child:IsA("Frame") then
        				child:Destroy()
        			end
        		end

        		if #selectedValues == 0 then
        			-- Show placeholder text
        			selectButton.Text = "  " .. placeholder
        			selectButton.TextColor3 = Colors.Text.Secondary
        			chipsContainer.Visible = false
        		elseif multiSelect and #selectedValues > 0 then
        			-- Hide button text and show chips
        			selectButton.Text = ""
        			chipsContainer.Visible = true

        			local totalWidth = 0

        			-- Create chips for all selected items
        			for i, value in ipairs(selectedValues) do
        				local displayText = value
        				for _, option in ipairs(options) do
        					if option.value == value then
        						displayText = option.text
        						break
        					end
        				end

        				-- Create chip container
        				local chip = Instance.new("Frame")
        				chip.Size = UDim2.new(0, 0, 0, selectHeight - 8) -- Auto-width, fit height
        				chip.BackgroundColor3 = Colors.Accent.Primary
        				chip.BorderSizePixel = 0
        				chip.ZIndex = chipsContainer.ZIndex + 1
        				chip.LayoutOrder = i
        				chip.Parent = chipsContainer

        				-- Chip corner radius
        				local chipCorner = Instance.new("UICorner")
        				chipCorner.CornerRadius = UDim.new(0, (selectHeight - 8) / 2) -- Pill shape
        				chipCorner.Parent = chip

        				-- Chip text
        				local chipText = Instance.new("TextLabel")
        				chipText.Size = UDim2.new(1, -20, 1, 0) -- Leave space for X button
        				chipText.Position = UDim2.new(0, 8, 0, 0)
        				chipText.BackgroundTransparency = 1
        				chipText.Text = displayText
        				chipText.TextColor3 = Color3.fromRGB(255, 255, 255)
        				chipText.TextXAlignment = Enum.TextXAlignment.Left
        				chipText.TextYAlignment = Enum.TextYAlignment.Center
        				chipText.Font = Enum.Font.Gotham
        				chipText.TextSize = isForAccordion and 10 or 12
        				chipText.TextScaled = false
        				chipText.ZIndex = chip.ZIndex + 1
        				chipText.Parent = chip

        				-- X button for removing chip
        				local removeButton = Instance.new("TextButton")
        				removeButton.Size = UDim2.new(0, 16, 0, 16)
        				removeButton.Position = UDim2.new(1, -18, 0.5, -8)
        				removeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        				removeButton.BackgroundTransparency = 0.2
        				removeButton.BorderSizePixel = 0
        				removeButton.Text = "×"
        				removeButton.TextColor3 = Colors.Accent.Primary
        				removeButton.TextSize = 12
        				removeButton.Font = Enum.Font.GothamBold
        				removeButton.ZIndex = chip.ZIndex + 2
        				removeButton.Parent = chip

        				-- X button corner radius
        				local removeCorner = Instance.new("UICorner")
        				removeCorner.CornerRadius = UDim.new(0, 8)
        				removeCorner.Parent = removeButton

        				-- X button hover effect
        				removeButton.MouseEnter:Connect(function()
        					removeButton.BackgroundTransparency = 0
        				end)

        				removeButton.MouseLeave:Connect(function()
        					removeButton.BackgroundTransparency = 0.2
        				end)

        				-- Remove chip on click
        				removeButton.MouseButton1Click:Connect(function()
        					removeSelectedValue(value)
        				end)

        				-- Auto-size chip based on text
        				local textBounds = game:GetService("TextService"):GetTextSize(
        					displayText,
        					chipText.TextSize,
        					chipText.Font,
        					Vector2.new(200, chipText.AbsoluteSize.Y)
        				)
        				local chipWidth = textBounds.X + 32 -- Text width + padding + X button
        				chip.Size = UDim2.new(0, chipWidth, 0, selectHeight - 8)

        				-- Add to total width for canvas sizing
        				totalWidth = totalWidth + chipWidth + 4 -- Include padding
        			end

        			-- Update canvas size for horizontal scrolling
        			chipsContainer.CanvasSize = UDim2.new(0, math.max(totalWidth, chipsContainer.AbsoluteSize.X), 0, 0)
        		else
        			-- Single select mode
        			local displayText = selectedValues[1]
        			for _, option in ipairs(options) do
        				if option.value == selectedValues[1] then
        					displayText = option.text
        					break
        				end
        			end
        			selectButton.Text = "  " .. (displayText or "Unknown")
        			selectButton.TextColor3 = Colors.Text.Primary
        			chipsContainer.Visible = false
        		end
        	end

        	-- Remove a selected value (for chip removal)
        	function removeSelectedValue(value)
        		for i, val in ipairs(selectedValues) do
        			if val == value then
        				table.remove(selectedValues, i)
        				break
        			end
        		end
        		updateDisplayText()
        		refreshOptions()

        		-- Save to configuration
        		if flag then
        			local valueToSave = multiSelect and selectedValues or (selectedValues[1] or "")
        			settings:SetValue(flag, valueToSave)
        		end

        		callback(selectedValues, value)
        	end

        	-- Show/hide bottom sheet with animation
        	local TweenService = game:GetService("TweenService")

        	local function showBottomSheet()
        		bottomSheetOverlay.Visible = true

        		-- Call OnDropdownOpen callback when dropdown is opened
        		if onDropdownOpen then
        			onDropdownOpen(options, function(newOptions)
        				-- Callback function to update options
        				if newOptions and type(newOptions) == "table" then
        					-- Update options with new data
        					rawOptions = newOptions
        					options = {}
        					for i, option in ipairs(rawOptions) do
        						if type(option) == "string" then
        							table.insert(options, {text = option, value = option})
        						elseif type(option) == "table" and option.text and option.value then
        							table.insert(options, option)
        						end
        					end

        					-- Refresh the options display
        					refreshOptions()
        				end
        			end)
        		end

        		-- Animate overlay fade in
        		local overlayTween = TweenService:Create(bottomSheetOverlay, 
        			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        			{BackgroundTransparency = 0.3}
        		)
        		overlayTween:Play()

        		-- Animate bottom sheet slide up from bottom of window
        		local sheetTween = TweenService:Create(bottomSheet, 
        			TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), 
        			{Position = UDim2.new(0, 20, 1, -bottomSheetHeight - 20)}
        		)
        		sheetTween:Play()

        		-- Animate arrow rotation
        		local arrowTween = TweenService:Create(arrow, 
        			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        			{Rotation = 180}
        		)
        		arrowTween:Play()
        		refreshOptions()
        		updateDisplayText()
        	end

        	local function hideBottomSheet()
        		-- Animate overlay fade out
        		local overlayTween = TweenService:Create(bottomSheetOverlay, 
        			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        			{BackgroundTransparency = 1}
        		)

        		-- Animate bottom sheet slide down to bottom of window
        		local sheetTween = TweenService:Create(bottomSheet, 
        			TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), 
        			{Position = UDim2.new(0, 20, 1, 20)}
        		)

        		-- Animate arrow rotation back
        		local arrowTween = TweenService:Create(arrow, 
        			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        			{Rotation = 0}
        		)
        		arrowTween:Play()

        		sheetTween:Play()
        		overlayTween:Play()

        		overlayTween.Completed:Connect(function()
        			bottomSheetOverlay.Visible = false
        		end)
        		refreshOptions()
        		updateDisplayText()
        	end

        	local function searchOptions(query)
        		local searchText = query:lower()
        		local visibleCount = 0
        		for _, child in pairs(optionsContainer:GetChildren()) do
        			if child:IsA("TextButton") then
        				local optionTextLabel = child:FindFirstChild("TextLabel")
        				if optionTextLabel then
        					local optionText = string.lower(optionTextLabel.Text)
        					local isVisible = searchText == "" or string.find(optionText, searchText, 1, true) ~= nil
        					child.Visible = isVisible
        					if isVisible then
        						visibleCount = visibleCount + 1
        					end
        				end
        			end
        		end
        		-- Update scroll canvas size based on visible items
        		local visibleHeight = visibleCount * 50
        		optionsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, visibleHeight)
        	end

        	-- Create options
        	function refreshOptions()
        		-- Save current search text
        		local searchTextBefore = searchBox and searchBox.Text or ""

        		for _, child in pairs(optionsContainer:GetChildren()) do
        			if child:IsA("TextButton") or child:IsA("UIListLayout") then
        				if child:IsA("TextButton") then
        					child:Destroy()
        				end
        			end
        		end

        		-- Update canvas size for scrolling (smaller option height)
        		local totalHeight = #options * 35
        		optionsContainer.Size = UDim2.new(1, 0, 0, totalHeight)
        		optionsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

        		-- Update bottom sheet height based on current options count
        		local newBottomSheetHeight = math.min(#options * 35 + 90, bottomSheetMaxHeight)
        		if newBottomSheetHeight ~= bottomSheetHeight then
        			bottomSheetHeight = newBottomSheetHeight
        			bottomSheet.Size = UDim2.new(1, -40, 0, bottomSheetHeight)
        		end

        		for i, option in ipairs(options) do
        			-- Modern option button (smaller)
        			local optionButton = Instance.new("TextButton")
        			optionButton.Size = UDim2.new(1, 0, 0, 35)
        			optionButton.Position = UDim2.new(0, 0, 0, (i-1) * 35)
        			optionButton.BackgroundColor3 = Colors.Surface.Default
        			optionButton.BackgroundTransparency = 0
        			optionButton.BorderSizePixel = 0
        			optionButton.Text = ""
        			optionButton.ZIndex = 103
        			optionButton.Parent = optionsContainer

        			-- Option text (smaller)
        			local optionText = Instance.new("TextLabel")
        			optionText.Size = UDim2.new(1, -48, 1, 0)
        			optionText.Position = UDim2.new(0, 16, 0, 0)
        			optionText.BackgroundTransparency = 1
        			optionText.Text = option.text
        			optionText.TextColor3 = Colors.Text.Primary
        			optionText.TextXAlignment = Enum.TextXAlignment.Left
        			optionText.TextYAlignment = Enum.TextYAlignment.Center
        			optionText.Font = Enum.Font.Gotham
        			optionText.TextSize = 13
        			optionText.ZIndex = 104
        			optionText.Parent = optionButton

        			-- Modern checkmark/selection indicator (smaller)
        			local checkmark = Instance.new("Frame")
        			checkmark.Size = UDim2.new(0, 16, 0, 16)
        			checkmark.Position = UDim2.new(1, -28, 0.5, -8)
        			checkmark.BackgroundColor3 = Colors.Status.Success
        			checkmark.BorderSizePixel = 0
        			checkmark.Visible = false
        			checkmark.ZIndex = 104
        			checkmark.Parent = optionButton

        			local checkCorner = Instance.new("UICorner")
        			checkCorner.CornerRadius = UDim.new(0, 8)
        			checkCorner.Parent = checkmark

        			local checkIcon = Instance.new("TextLabel")
        			checkIcon.Size = UDim2.new(1, 0, 1, 0)
        			checkIcon.BackgroundTransparency = 1
        			checkIcon.Text = "✓"
        			checkIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
        			checkIcon.TextXAlignment = Enum.TextXAlignment.Center
        			checkIcon.TextYAlignment = Enum.TextYAlignment.Center
        			checkIcon.Font = Enum.Font.GothamBold
        			checkIcon.TextSize = 10
        			checkIcon.ZIndex = 105
        			checkIcon.Parent = checkmark

        			-- Check if selected
        			local isSelected = false
        			for _, val in ipairs(selectedValues) do
        				if val == option.value then
        					isSelected = true
        					break
        				end
        			end

        			if isSelected then
        				checkmark.Visible = true
        				optionButton.BackgroundColor3 = Colors.Input.Background
        				optionText.TextColor3 = Colors.Status.Success
        			end

        			-- Hover effect
        			optionButton.MouseEnter:Connect(function()
        				if not isSelected then
        					optionButton.BackgroundColor3 = Colors.Input.Background
        				end
        			end)

        			optionButton.MouseLeave:Connect(function()
        				if not isSelected then
        					optionButton.BackgroundColor3 = Colors.Surface.Default
        				end
        			end)

        			-- Click handler
        			optionButton.MouseButton1Click:Connect(function()
        				if multiSelect then
        					local found = false
        					for j, val in ipairs(selectedValues) do
        						if val == option.value then
        							table.remove(selectedValues, j)
        							found = true
        							break
        						end
        					end

        					if not found then
        						table.insert(selectedValues, option.value)
        					end

        					refreshOptions()
        					updateDisplayText()

        					-- Save to configuration (for multi-select)
        					if flag then
        						local valueToSave = selectedValues
        						settings:SetValue(flag, valueToSave)
        					end

        					callback(selectedValues, option.value)
        				else
        					-- Single select mode - update selected values
        					selectedValues = {option.value}

        					-- Refresh all options to update checkmarks (remove old, show new)
        					refreshOptions()

        					-- Update display text
        					updateDisplayText()

        					-- Save to configuration
        					if flag then
        						local valueToSave = selectedValues[1] or ""
        						settings:SetValue(flag, valueToSave)
        					end

        					-- Call callback
        					callback(selectedValues, option.value)

        					-- Close dropdown with slight delay to show selection feedback
        					task.wait(0.15)
        					isOpen = false
        					hideBottomSheet()
        				end
        			end)

        			-- Hover effects
        			optionButton.MouseEnter:Connect(function()
        				if not isSelected then
        					optionButton.BackgroundColor3 = Colors.Dropdown.OptionHover
        				end
        			end)

        			optionButton.MouseLeave:Connect(function()
        				if not isSelected then
        					optionButton.BackgroundColor3 = Colors.Dropdown.Option
        				end
        			end)
        		end

        		-- Restore value search after refresh
        		if searchBox then
        			searchOptions(searchTextBefore)
        		end
        	end

        	-- Toggle bottom sheet
        	local function toggleBottomSheet()
        		isOpen = not isOpen
        		if isOpen then
        			showBottomSheet()
        		else
        			hideBottomSheet()
        		end
        	end

        	-- Button handlers
        	selectButton.MouseButton1Click:Connect(toggleBottomSheet)

        	-- Overlay click to close
        	bottomSheetOverlay.MouseButton1Click:Connect(function()
        		if isOpen then
        			isOpen = false
        			hideBottomSheet()
        		end
        	end)

        	-- Search filter
        	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        		searchOptions(searchBox.Text)
        	end)

        	-- Initial setup
        	refreshOptions()
        	updateDisplayText()

        	-- SelectBox API
        	local selectBoxAPI = {
        		SelectBox = selectContainer
        	}

        	function selectBoxAPI:GetSelected()
        		return selectedValues
        	end

        	function selectBoxAPI:SetSelected(values)
        		selectedValues = type(values) == "table" and values or (values ~= "" and {values} or {})
        		refreshOptions()
        		updateDisplayText()
        	end

        	function selectBoxAPI:Clear()
        		selectedValues = {}
        		refreshOptions()
        		updateDisplayText()
        	end

        	function selectBoxAPI:Refresh(newOptions)
        		rawOptions = newOptions
        		options = {}
        		for i, option in ipairs(rawOptions) do
        			if type(option) == "string" then
        				table.insert(options, {text = option, value = option})
        			elseif type(option) == "table" and option.text and option.value then
        				table.insert(options, option)
        			end
        		end
        		selectedValues = {}
        		refreshOptions()
        		updateDisplayText()
        	end

        	function selectBoxAPI:Set(values)
        		selectedValues = type(values) == "table" and values or (values ~= "" and {values} or {})
        		updateDisplayText()
        	end

        	function selectBoxAPI:Cleanup()
        		if bottomSheetOverlay then
        			bottomSheetOverlay:Destroy()
        		end
        		if selectContainer then
        			selectContainer:Destroy()
        		end
        	end

        	-- Register component
        	if registerComponent then
        		registerComponent(flag, selectBoxAPI)
        	end

        	-- Execute OnInit callback after component is fully created
        	if onInit and type(onInit) == "function" then
        		-- Preserve selected values before calling onInit
        		local preservedSelectedValues = selectedValues

        		-- Call OnInit with selectBoxAPI and options update function
        		onInit(selectBoxAPI, {
        			currentOptions = options,
        			updateOptions = function(newOptions)
        				-- Callback function to update options on initialization
        				if newOptions and type(newOptions) == "table" then
        					-- Update options with new data
        					rawOptions = newOptions
        					options = {}
        					for i, option in ipairs(rawOptions) do
        						if type(option) == "string" then
        							table.insert(options, {text = option, value = option})
        						elseif type(option) == "table" and option.text and option.value then
        							table.insert(options, option)
        						end
        					end

        					-- Restore selected values after options update
        					selectedValues = preservedSelectedValues

        					-- Refresh the options display
        					refreshOptions()
        					-- Update display text after refreshing options
        					updateDisplayText()
        				end
        			end
        		})
        	end

        	return selectBoxAPI
        end

        return SelectBox
    end

    -- Module: components/textbox
    EmbeddedModules["components/textbox"] = function()
        --[[
        	TextBox Component
        	EzUI Library - Modular Component

        	Creates a text input field with character counter
        ]]
        local TextBox = {}

        local Colors

        function TextBox:Init(_colors)
        	Colors = _colors
        end

        function TextBox:Create(config)
        	local name = config.Name or config.Title or ""
        	local placeholder = config.Placeholder or "Enter text..."
        	local defaultText = config.Default or ""
        	local callback = config.Callback or function() end
        	local maxLength = config.MaxLength or 100
        	local multiline = config.Multiline or false
        	local flag = config.Flag
        	local parentContainer = config.Parent
        	local currentY = config.Y or 0
        	local isForAccordion = config.IsForAccordion or false
        	local EzUI = config.EzUI
        	local saveConfiguration = config.SaveConfiguration
        	local registerComponent = config.RegisterComponent
        	local settings = config.Settings

        	-- Button configuration
        	local buttons = config.Buttons or {} -- Array of button configs: {Text="Submit", Callback=function() end}
        	local hasButtons = #buttons > 0

        	-- Handle case where Parent might be a component API object instead of Instance
        	if parentContainer and type(parentContainer) == "table" then
        		-- Look for common GUI object properties in component APIs
        		if parentContainer.Frame then
        			parentContainer = parentContainer.Frame
        		elseif parentContainer.Button then
        			parentContainer = parentContainer.Button
        		elseif parentContainer.Label then
        			parentContainer = parentContainer.Label
        		elseif parentContainer.Container then
        			parentContainer = parentContainer.Container
        		else
        			-- List available keys for debugging
        			local keys = {}
        			for k, v in pairs(parentContainer) do
        				table.insert(keys, tostring(k))
        			end
        			warn("TextBox:Create - Parent is a table but no GUI object found. Keys:", table.concat(keys, ", "))
        			parentContainer = nil
        		end
        	end

        	-- Validate parent is an Instance
        	if parentContainer and not typeof(parentContainer) == "Instance" then
        		warn("TextBox:Create - Parent must be an Instance, got:", typeof(parentContainer))
        		parentContainer = nil
        	end

        	-- TextBox state
        	local currentText = defaultText

        	-- Load from flag (supports both EzUI.Flags and custom config)
        	if flag then
        		local flagValue = nil

        		-- Check if using custom config object
        		if settings and type(settings.GetValue) == "function" then
        			print("Loading TextBox value for flag:", flag)
        			flagValue = settings:GetValue(flag)
        		else
        			warn("No settings object to load TextBox value.", flag)
        		end

        		if flagValue ~= nil then
        			currentText = flagValue
        			defaultText = currentText
        		end
        	end

        	-- Calculate heights based on whether we have a title label (UMBRELLA CORP: 34px input height, 14px text)
        	local hasTitle = name and name ~= ""
        	local labelHeight = hasTitle and 18 or 0
        	local inputHeight = multiline and (isForAccordion and 60 or 80) or (isForAccordion and 25 or 34)
        	local totalHeight = labelHeight + inputHeight + (hasTitle and 6 or 0) -- 6px spacing between label and input

        	-- Main textbox container
        	local textBoxContainer = Instance.new("Frame")
        	if isForAccordion then
        		textBoxContainer.Size = UDim2.new(1, -10, 0, totalHeight)
        		textBoxContainer.Position = UDim2.new(0, 5, 0, currentY)
        		textBoxContainer.ZIndex = 6
        	else
        		textBoxContainer.Size = UDim2.new(1, -20, 0, totalHeight)
        		textBoxContainer.Position = UDim2.new(0, 10, 0, currentY)
        		textBoxContainer.ZIndex = 3
        		textBoxContainer:SetAttribute("ComponentStartY", currentY)
        	end
        	textBoxContainer.BackgroundTransparency = 1
        	textBoxContainer.ClipsDescendants = true -- Ensure text doesn't overflow container
        	textBoxContainer.Parent = parentContainer

        	-- Title label (if name is provided)
        	local titleLabel = nil
        	if hasTitle then
        		titleLabel = Instance.new("TextLabel")
        		titleLabel.Size = UDim2.new(1, 0, 0, labelHeight)
        		titleLabel.Position = UDim2.new(0, 0, 0, 0)
        		titleLabel.BackgroundTransparency = 1
        		titleLabel.Text = name
        		titleLabel.TextColor3 = Colors.Text.Primary
        		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        		titleLabel.Font = Enum.Font.SourceSans
        		titleLabel.TextSize = isForAccordion and 12 or 14
        		titleLabel.ZIndex = isForAccordion and 7 or 4
        		titleLabel.Parent = textBoxContainer
        	end

        	-- Calculate button width (each button is 80px wide + 5px spacing)
        	local buttonWidth = hasButtons and (#buttons * 85) or 0 -- 80px + 5px spacing per button

        	-- TextBox input (UMBRELLA CORP: 34px height, 12px padding, 6px corner, 14px text)
        	local textBox = Instance.new("TextBox")
        	if hasTitle then
        		textBox.Size = UDim2.new(1, -buttonWidth, 0, inputHeight)
        		textBox.Position = UDim2.new(0, 0, 0, labelHeight + 6)
        	else
        		if hasButtons then
        			textBox.Size = UDim2.new(1, -buttonWidth, 1, 0)
        		else
        			textBox.Size = UDim2.new(1, 0, 1, 0)
        		end
        		textBox.Position = UDim2.new(0, 0, 0, 0)
        	end
        	textBox.BackgroundColor3 = Colors.Input.Background
        	textBox.BorderSizePixel = 0
        	textBox.Text = defaultText
        	textBox.PlaceholderText = placeholder
        	textBox.TextColor3 = Colors.Input.Text
        	textBox.PlaceholderColor3 = Colors.Input.Placeholder
        	textBox.Font = Enum.Font.Gotham
        	textBox.TextSize = isForAccordion and 12 or 14
        	textBox.TextXAlignment = Enum.TextXAlignment.Left
        	textBox.TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        	textBox.MultiLine = multiline
        	textBox.TextWrapped = multiline
        	textBox.TextScaled = false -- Prevent text from scaling down automatically
        	textBox.ClearTextOnFocus = false
        	textBox.ClipsDescendants = true -- Clip text that overflows the TextBox
        	textBox.ZIndex = isForAccordion and 7 or 4
        	textBox.Parent = textBoxContainer

        	-- Add padding to TextBox (UMBRELLA CORP: 12px horizontal, 8px vertical)
        	local padding = Instance.new("UIPadding")
        	padding.PaddingLeft = UDim.new(0, 12)
        	padding.PaddingRight = UDim.new(0, 12)
        	padding.PaddingTop = multiline and UDim.new(0, 8) or UDim.new(0, 0)
        	padding.PaddingBottom = multiline and UDim.new(0, 8) or UDim.new(0, 0)
        	padding.Parent = textBox

        	-- Round corners (UMBRELLA CORP: 6px)
        	local corner = Instance.new("UICorner")
        	corner.CornerRadius = UDim.new(0, 6)
        	corner.Parent = textBox

        	-- Default border (gray, transparency 0.6)
        	local defaultBorder = Instance.new("UIStroke")
        	defaultBorder.Color = Colors.Input.Border
        	defaultBorder.Thickness = 1
        	defaultBorder.Transparency = 0.6
        	defaultBorder.Parent = textBox

        	-- Red focus glow (UMBRELLA CORP: Umbrella Red, pulsing 0.7 ↔ 0.5, 1.5s Sine)
        	local focusGlow = Instance.new("UIStroke")
        	focusGlow.Name = "FocusGlow"
        	focusGlow.Color = Colors.Umbrella.Red
        	focusGlow.Thickness = 1
        	focusGlow.Transparency = 1
        	focusGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        	focusGlow.Parent = textBox

        	-- Pulsing glow animation (only when focused)
        	local isFocused = false
        	task.spawn(function()
        		local TweenService = game:GetService("TweenService")
        		while textBox and textBox.Parent do
        			if isFocused then
        				local fadeIn = TweenService:Create(focusGlow, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.5})
        				local fadeOut = TweenService:Create(focusGlow, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.7})
        				fadeIn:Play()
        				fadeIn.Completed:Wait()
        				fadeOut:Play()
        				fadeOut.Completed:Wait()
        			else
        				task.wait(0.1)
        			end
        		end
        	end)

        	-- Character counter (if maxLength is set)
        	local charCounter = nil
        	if maxLength and maxLength > 0 then
        		charCounter = Instance.new("TextLabel")
        		charCounter.Size = UDim2.new(0, 50, 0, 15)
        		charCounter.Position = UDim2.new(1, -55, 1, -18)
        		charCounter.BackgroundTransparency = 1
        		charCounter.Text = string.len(currentText) .. "/" .. maxLength
        		charCounter.TextColor3 = Colors.Text.Tertiary
        		charCounter.Font = Enum.Font.SourceSans
        		charCounter.TextSize = isForAccordion and 10 or 12
        		charCounter.TextXAlignment = Enum.TextXAlignment.Right
        		charCounter.ZIndex = isForAccordion and 8 or 5
        		charCounter.Parent = textBoxContainer
        	end

        	-- Create buttons (if configured)
        	local buttonObjects = {}
        	if hasButtons then
        		local buttonY = hasTitle and (labelHeight + 2) or 0
        		local buttonHeight = inputHeight

        		for i, buttonConfig in ipairs(buttons) do
        			local buttonText = buttonConfig.Text or "Button"
        			local buttonCallback = buttonConfig.Callback or function() end
        			local buttonVariant = buttonConfig.Variant or "primary"

        			-- Calculate button position (buttons are positioned from right to left)
        			local buttonX = (1 - (i * 85 / textBoxContainer.AbsoluteSize.X)) -- 85px per button from right

        			local button = Instance.new("TextButton")
        			button.Size = UDim2.new(0, 80, 0, buttonHeight)
        			button.Position = UDim2.new(1, -i * 85 + 5, 0, buttonY) -- 5px spacing from edge
        			button.BackgroundColor3 = buttonVariant == "primary" and Colors.Accent.Primary or Colors.Surface.Default
        			button.BorderSizePixel = 0
        			button.Text = buttonText
        			button.TextColor3 = buttonVariant == "primary" and Color3.fromRGB(255, 255, 255) or Colors.Text.Primary
        			button.Font = Enum.Font.SourceSans
        			button.TextSize = isForAccordion and 11 or 13
        			button.ZIndex = isForAccordion and 7 or 4
        			button.Parent = textBoxContainer

        			-- Button corner radius
        			local buttonCorner = Instance.new("UICorner")
        			buttonCorner.CornerRadius = UDim.new(0, 4)
        			buttonCorner.Parent = button

        			-- Button hover effects
        			button.MouseEnter:Connect(function()
        				if buttonVariant == "primary" then
        					button.BackgroundColor3 = Colors.Accent.Hover
        				else
        					button.BackgroundColor3 = Colors.Surface.Hover
        				end
        			end)

        			button.MouseLeave:Connect(function()
        				if buttonVariant == "primary" then
        					button.BackgroundColor3 = Colors.Accent.Primary
        				else
        					button.BackgroundColor3 = Colors.Surface.Default
        				end
        			end)

        			-- Button click handler
        			button.MouseButton1Click:Connect(function()
        				if buttonCallback then
        					buttonCallback(textBox.Text, textBox) -- Pass current text and textBox reference
        				end
        			end)

        			table.insert(buttonObjects, {
        				Button = button,
        				Text = buttonText,
        				Callback = buttonCallback
        			})
        		end
        	end

        	-- Function to update character counter
        	local function updateCharCounter()
        		if charCounter then
        			local textLength = string.len(textBox.Text)
        			charCounter.Text = textLength .. "/" .. maxLength

        			-- Change color based on limit
        			if textLength >= maxLength then
        				charCounter.TextColor3 = Colors.Status.Error
        			elseif textLength >= maxLength * 0.8 then
        				charCounter.TextColor3 = Colors.Status.Warning
        			else
        				charCounter.TextColor3 = Colors.Text.Tertiary
        			end
        		end
        	end

        	-- Text change handler
        	textBox.Changed:Connect(function(property)
        		if property == "Text" then
        			-- Enforce max length
        			if maxLength and maxLength > 0 and string.len(textBox.Text) > maxLength then
        				textBox.Text = string.sub(textBox.Text, 1, maxLength)
        			end

        			currentText = textBox.Text
        			updateCharCounter()

        			-- Save to configuration
        			if flag then
        				print("Saving TextBox value for flag:", flag, "Value:", currentText)
        				settings:SetValue(flag, currentText)
        			end

        			-- Call user callback
        			local success, errorMsg = pcall(function()
        				callback(currentText)
        			end)

        			if not success then
        				warn("TextBox callback error:", errorMsg)
        			end
        		end
        	end)

        	-- Focus effects (UMBRELLA CORP: Show red glow on focus, 0.15s Quad transition)
        	textBox.Focused:Connect(function()
        		isFocused = true
        		local TweenService = game:GetService("TweenService")
        		-- Hide default border, show focus glow
        		local borderTween = TweenService:Create(defaultBorder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
        		local glowTween = TweenService:Create(focusGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.7})
        		-- Slightly lighter background on focus
        		local bgTween = TweenService:Create(textBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Colors.Input.BackgroundFocus})
        		borderTween:Play()
        		glowTween:Play()
        		bgTween:Play()
        	end)

        	textBox.FocusLost:Connect(function()
        		isFocused = false
        		local TweenService = game:GetService("TweenService")
        		-- Show default border, hide focus glow
        		local borderTween = TweenService:Create(defaultBorder, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.6})
        		local glowTween = TweenService:Create(focusGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
        		-- Reset background color
        		local bgTween = TweenService:Create(textBox, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Colors.Input.Background})
        		borderTween:Play()
        		glowTween:Play()
        		bgTween:Play()
        	end)

        	-- Return TextBox API
        	local textBoxAPI = {
        		TextBox = textBoxContainer,
        		Buttons = buttonObjects
        	}

        	function textBoxAPI:GetText()
        		return currentText
        	end

        	function textBoxAPI:SetText(newText)
        		textBox.Text = tostring(newText or "")
        		currentText = textBox.Text
        		updateCharCounter()
        		-- Save to configuration
        		if flag then
        			settings:SetValue(flag, currentText)
        		end
        	end

        	function textBoxAPI:Clear()
        		textBox.Text = ""
        		currentText = ""
        		updateCharCounter()
        		-- Save to configuration
        		if flag then
        			-- Check if using custom config object
        			if EzUIConfig and type(EzUIConfig.SetValue) == "function" then
        				EzUIConfig.SetValue(flag, currentText)
        			-- Fallback to EzUI.Flags
        			elseif EzUI and EzUI.Flags then
        				EzUI.Flags[flag] = currentText
        				-- Auto-save if enabled
        				if EzUI.Configuration and EzUI.Configuration.AutoSave and saveConfiguration then
        					saveConfiguration(EzUI.Configuration.FileName)
        				end
        			end
        		end
        	end

        	function textBoxAPI:SetPlaceholder(newPlaceholder)
        		textBox.PlaceholderText = tostring(newPlaceholder or "")
        	end

        	function textBoxAPI:Focus()
        		textBox:CaptureFocus()
        	end

        	function textBoxAPI:Blur()
        		textBox:ReleaseFocus()
        	end

        	function textBoxAPI:SetCallback(newCallback)
        		callback = newCallback or function() end
        	end

        	function textBoxAPI:Set(newText)
        		textBox.Text = tostring(newText or "")
        		currentText = textBox.Text
        		updateCharCounter()
        	end

        	-- Button-related methods
        	function textBoxAPI:GetButton(index)
        		return buttonObjects[index]
        	end

        	function textBoxAPI:SetButtonText(index, newText)
        		if buttonObjects[index] then
        			buttonObjects[index].Button.Text = newText
        			buttonObjects[index].Text = newText
        		end
        	end

        	function textBoxAPI:SetButtonCallback(index, newCallback)
        		if buttonObjects[index] then
        			buttonObjects[index].Callback = newCallback or function() end
        			-- Note: We can't change the connected event, but we update the stored callback
        		end
        	end

        	function textBoxAPI:EnableButton(index)
        		if buttonObjects[index] then
        			buttonObjects[index].Button.BackgroundTransparency = 0
        			buttonObjects[index].Button.TextTransparency = 0
        		end
        	end

        	function textBoxAPI:DisableButton(index)
        		if buttonObjects[index] then
        			buttonObjects[index].Button.BackgroundTransparency = 0.5
        			buttonObjects[index].Button.TextTransparency = 0.5
        		end
        	end

        	-- Register component for flag-based updates
        	if registerComponent then
        		registerComponent(flag, textBoxAPI)
        	end

        	return textBoxAPI
        end

        return TextBox

    end

    -- Module: components/toggle
    EmbeddedModules["components/toggle"] = function()
        --[[
        	Toggle Component
        	EzUI Library - Modular Component

        	Creates a toggle/switch with on/off states
        ]]
        local Toggle = {}

        local Colors

        function Toggle:Init(_colors)
        	Colors = _colors
        end

        function Toggle:Create(config)
        	local text = config.Name or config.Text or "Toggle"
        	local defaultValue = config.Default or false
        	local callback = config.Callback or function() end
        	local flag = config.Flag
        	local parentContainer = config.Parent
        	local currentY = config.Y or 0
        	local isForAccordion = config.IsForAccordion or false
        	local EzUI = config.EzUI
        	local saveConfiguration = config.SaveConfiguration
        	local registerComponent = config.RegisterComponent
        	local settings = config.Settings

        	-- Handle case where Parent might be a component API object instead of Instance
        	if parentContainer and type(parentContainer) == "table" then
        		-- Look for common GUI object properties in component APIs
        		if parentContainer.Frame then
        			parentContainer = parentContainer.Frame
        		elseif parentContainer.Button then
        			parentContainer = parentContainer.Button
        		elseif parentContainer.Label then
        			parentContainer = parentContainer.Label
        		elseif parentContainer.Container then
        			parentContainer = parentContainer.Container
        		else
        			-- List available keys for debugging
        			local keys = {}
        			for k, v in pairs(parentContainer) do
        				table.insert(keys, tostring(k))
        			end
        			warn("Toggle:Create - Parent is a table but no GUI object found. Keys:", table.concat(keys, ", "))
        			parentContainer = nil
        		end
        	end

        	-- Validate parent is an Instance
        	if parentContainer and not typeof(parentContainer) == "Instance" then
        		warn("Toggle:Create - Parent must be an Instance, got:", typeof(parentContainer))
        		parentContainer = nil
        	end

        	-- Toggle state
        	local isToggled = defaultValue

        	-- Load from flag (supports both EzUI.Flags and custom config)
        	if flag then
        		local flagValue = nil

        		-- Check if using custom config object
        		if settings and type(settings.GetValue) == "function" then
        			flagValue = settings:GetValue(flag)
        		end

        		if flagValue ~= nil then
        			isToggled = flagValue
        		end
        	end

        	-- Main toggle container
        	local toggleContainer = Instance.new("Frame")
        	if isForAccordion then
        		toggleContainer.Size = UDim2.new(1, -10, 0, 25)
        		-- Don't set Position for accordion toggles - let UIListLayout handle it
        		toggleContainer.ZIndex = 6
        	else
        		toggleContainer.Size = UDim2.new(1, -20, 0, 30)
        		toggleContainer.Position = UDim2.new(0, 10, 0, currentY)
        		toggleContainer.ZIndex = 3
        		toggleContainer:SetAttribute("ComponentStartY", currentY)
        	end
        	toggleContainer.BackgroundTransparency = 1
        	toggleContainer.Parent = parentContainer

        	-- Toggle label
        	local toggleLabel = Instance.new("TextLabel")
        	if isForAccordion then
        		toggleLabel.Size = UDim2.new(1, -45, 1, 0)
        		toggleLabel.TextSize = 12
        		toggleLabel.ZIndex = 7
        	else
        		toggleLabel.Size = UDim2.new(1, -60, 1, 0)
        		toggleLabel.TextSize = 16
        		toggleLabel.ZIndex = 4
        	end
        	toggleLabel.Position = UDim2.new(0, 0, 0, 0)
        	toggleLabel.BackgroundTransparency = 1
        	toggleLabel.Text = text
        	toggleLabel.TextColor3 = Colors.Text.Primary
        	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        	toggleLabel.Font = Enum.Font.SourceSans
        	toggleLabel.Parent = toggleContainer

        	-- Toggle switch background (UMBRELLA CORP: 52x28px, 14px corner for perfect pill)
        	local toggleBg = Instance.new("Frame")
        	if isForAccordion then
        		toggleBg.Size = UDim2.new(0, 40, 0, 20)
        		toggleBg.Position = UDim2.new(1, -40, 0.5, -10)
        		toggleBg.ZIndex = 7
        	else
        		toggleBg.Size = UDim2.new(0, 52, 0, 28)
        		toggleBg.Position = UDim2.new(1, -52, 0.5, -14)
        		toggleBg.ZIndex = 4
        	end
        	toggleBg.BackgroundColor3 = isToggled and Colors.Toggle.On or Colors.Toggle.Off
        	toggleBg.BorderSizePixel = 0
        	toggleBg.Parent = toggleContainer

        	-- Round corners for toggle background (perfect pill shape)
        	local toggleBgCorner = Instance.new("UICorner")
        	toggleBgCorner.CornerRadius = UDim.new(0, isForAccordion and 10 or 14)
        	toggleBgCorner.Parent = toggleBg

        	-- Red glow for ON state (UMBRELLA CORP: pulsing 0.6 ↔ 0.4, 1.2s Sine)
        	local toggleGlow = Instance.new("UIStroke")
        	toggleGlow.Color = Colors.Umbrella.Red
        	toggleGlow.Thickness = 1
        	toggleGlow.Transparency = isToggled and 0.6 or 1
        	toggleGlow.Parent = toggleBg

        	-- Pulsing glow animation for ON state
        	task.spawn(function()
        		local TweenService = game:GetService("TweenService")
        		while toggleBg and toggleBg.Parent do
        			if isToggled then
        				local fadeIn = TweenService:Create(toggleGlow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.4})
        				local fadeOut = TweenService:Create(toggleGlow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.6})
        				fadeIn:Play()
        				fadeIn.Completed:Wait()
        				fadeOut:Play()
        				fadeOut.Completed:Wait()
        			else
        				toggleGlow.Transparency = 1
        				task.wait(0.1)
        			end
        		end
        	end)

        	-- Toggle switch button (circle) (UMBRELLA CORP: 24x24px)
        	local toggleButton = Instance.new("TextButton")
        	if isForAccordion then
        		toggleButton.Size = UDim2.new(0, 16, 0, 16)
        		toggleButton.Position = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        		toggleButton.ZIndex = 8
        	else
        		toggleButton.Size = UDim2.new(0, 24, 0, 24)
        		toggleButton.Position = isToggled and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
        		toggleButton.ZIndex = 5
        	end
        	toggleButton.BackgroundColor3 = Colors.Toggle.Handle
        	toggleButton.BorderSizePixel = 0
        	toggleButton.Text = ""
        	toggleButton.Parent = toggleBg

        	-- Round corners for toggle button (full circle)
        	local toggleButtonCorner = Instance.new("UICorner")
        	toggleButtonCorner.CornerRadius = UDim.new(1, 0)
        	toggleButtonCorner.Parent = toggleButton

        	-- Function to update toggle appearance (UMBRELLA CORP: 0.2s Quad, smooth professional)
        	local function updateToggleAppearance()
        		local targetBgColor = isToggled and Colors.Toggle.On or Colors.Toggle.Off
        		local targetPosition
        		local targetGlowTransparency = isToggled and 0.6 or 1

        		if isForAccordion then
        			targetPosition = isToggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        		else
        			targetPosition = isToggled and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
        		end

        		-- Animate background color
        		local bgTween = game:GetService("TweenService"):Create(
        			toggleBg,
        			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        			{BackgroundColor3 = targetBgColor}
        		)
        		bgTween:Play()

        		-- Animate button position
        		local buttonTween = game:GetService("TweenService"):Create(
        			toggleButton,
        			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        			{Position = targetPosition}
        		)
        		buttonTween:Play()

        		-- Animate glow transparency
        		local glowTween = game:GetService("TweenService"):Create(
        			toggleGlow,
        			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        			{Transparency = targetGlowTransparency}
        		)
        		glowTween:Play()
        	end

        	-- Toggle click handler
        	local function handleToggle()
        		isToggled = not isToggled
        		updateToggleAppearance()

        		-- Save to configuration
        		if flag then
        			settings:SetValue(flag, isToggled)
        		end

        		-- Call user callback
        		local success, errorMsg = pcall(function()
        			callback(isToggled)
        		end)

        		if not success then
        			warn("Toggle callback error:", errorMsg)
        		end
        	end

        	toggleButton.MouseButton1Click:Connect(handleToggle)

        	-- Also allow clicking the background to toggle
        	toggleBg.InputBegan:Connect(function(input)
        		if input.UserInputType == Enum.UserInputType.MouseButton1 then
        			handleToggle()
        		end
        	end)

        	-- Hover effects
        	toggleButton.MouseEnter:Connect(function()
        		toggleButton.BackgroundColor3 = Colors.Toggle.Handle
        	end)

        	toggleButton.MouseLeave:Connect(function()
        		toggleButton.BackgroundColor3 = Colors.Toggle.Handle
        	end)

        	-- Return Toggle API
        	local toggleAPI = {
        		Toggle = toggleContainer
        	}

        	function toggleAPI:SetValue(newValue, triggerCallback)
        		if type(newValue) ~= "boolean" and newValue == isToggled then
        			return
        		end

        		isToggled = newValue
        		updateToggleAppearance()

        		-- Save to configuration
        		if not flag then
        			return
        		end

        		settings:SetValue(flag, isToggled)

        		-- Trigger callback if requested (default true for backward compatibility)
        		if triggerCallback ~= false then
        			local success, errorMsg = pcall(function()
        				callback(isToggled)
        			end)

        			if not success then
        				warn("Toggle SetValue callback error:", errorMsg)
        			end
        		end
        	end

        	function toggleAPI:GetValue()
        		return isToggled
        	end

        	function toggleAPI:SetText(newText)
        		text = newText
        		toggleLabel.Text = newText
        	end

        	function toggleAPI:SetCallback(newCallback)
        		callback = newCallback or function() end
        	end

        	toggleAPI.Set = toggleAPI.SetValue

        	-- Register component for flag-based updates
        	if registerComponent then
        		registerComponent(flag, toggleAPI)
        	end

        	return toggleAPI
        end

        return Toggle

    end

    -- Module: utils/colors
    EmbeddedModules["utils/colors"] = function()
        --[[
        	EzUI Color Palette Module - UMBRELLA CORPORATION THEME
        	Pharmaceutical Corporation with High-Tech Medical Aesthetic

        	Author: EzUI Library
        	Version: 2.0.0 - Ultimate Umbrella Corp Edition

        	Theme Identity:
        	- Primary: Umbrella Crimson Red (Signature)
        	- Style: Corporate pharmaceutical with medical precision
        	- Mood: Professional, powerful, slightly sinister

        	Usage:
        		local m = require(path.to.color)
        		myFrame.BackgroundColor3 = Colors.Background.Primary
        		myButton.BackgroundColor3 = Colors.Button.Default
        ]]

        local Colors = {}

        -- ============================================
        -- UMBRELLA CORPORATION SIGNATURE COLORS
        -- ============================================
        Colors.Umbrella = {
        	Red = Color3.fromRGB(220, 20, 60),          -- Crimson signature
        	RedBright = Color3.fromRGB(240, 30, 70),    -- Hover/emphasis
        	RedDark = Color3.fromRGB(180, 15, 50),      -- Darker variant
        	CorporateWhite = Color3.fromRGB(245, 245, 250), -- Clean medical white
        	CorporateBlack = Color3.fromRGB(18, 18, 22),    -- Professional depth
        }

        -- ============================================
        -- BACKGROUND COLORS (Corporate Dark)
        -- ============================================
        Colors.Background = {
        	Primary = Color3.fromRGB(18, 18, 22),      -- Main background (corporate black)
        	Secondary = Color3.fromRGB(25, 25, 30),    -- Secondary panels (dark panel)
        	Tertiary = Color3.fromRGB(32, 32, 38),     -- Elevated elements
        	Overlay = Color3.fromRGB(0, 0, 0),         -- Modal overlays (use with transparency)
        	Transparent = Color3.fromRGB(0, 0, 0),     -- For transparent elements
        }

        -- ============================================
        -- SURFACE COLORS (Professional Panels)
        -- ============================================
        Colors.Surface = {
        	Default = Color3.fromRGB(25, 25, 30),      -- Default surface (dark panel)
        	Elevated = Color3.fromRGB(32, 32, 38),     -- Elevated surface
        	Hover = Color3.fromRGB(38, 38, 45),        -- Hover state
        	Active = Color3.fromRGB(40, 40, 48),       -- Active/Pressed state
        	Disabled = Color3.fromRGB(20, 20, 25),     -- Disabled state
        }

        -- ============================================
        -- TEXT COLORS (Corporate Hierarchy)
        -- ============================================
        Colors.Text = {
        	Primary = Color3.fromRGB(245, 245, 250),   -- Primary text (corporate white)
        	Secondary = Color3.fromRGB(200, 200, 210), -- Secondary text
        	Tertiary = Color3.fromRGB(150, 150, 160),  -- Tertiary text (gray)
        	Disabled = Color3.fromRGB(100, 100, 110),  -- Disabled text
        	Placeholder = Color3.fromRGB(120, 120, 130), -- Placeholder text
        	Link = Color3.fromRGB(220, 20, 60),        -- Link text (Umbrella Red)
        	LinkHover = Color3.fromRGB(240, 30, 70),   -- Link hover (brighter red)
        }

        -- ============================================
        -- BORDER COLORS (Subtle & Professional)
        -- ============================================
        Colors.Border = {
        	Default = Color3.fromRGB(40, 40, 48),      -- Default border (subtle)
        	Light = Color3.fromRGB(50, 50, 58),        -- Light border
        	Dark = Color3.fromRGB(30, 30, 35),         -- Dark border
        	Focus = Color3.fromRGB(220, 20, 60),       -- Focused border (Umbrella Red)
        	Error = Color3.fromRGB(220, 20, 60),       -- Error border (same as red)
        	Success = Color3.fromRGB(80, 200, 120),    -- Success border (medical green)
        }

        -- ============================================
        -- BUTTON COLORS (Premium Corporate)
        -- ============================================
        Colors.Button = {
        	-- Primary Button (UMBRELLA RED!)
        	Primary = Color3.fromRGB(220, 20, 60),
        	PrimaryHover = Color3.fromRGB(240, 30, 70),
        	PrimaryActive = Color3.fromRGB(200, 15, 50),
        	PrimaryDisabled = Color3.fromRGB(110, 10, 30),

        	-- Secondary Button (Dark with Red Border)
        	Secondary = Color3.fromRGB(25, 25, 30),
        	SecondaryHover = Color3.fromRGB(32, 32, 38),
        	SecondaryActive = Color3.fromRGB(20, 20, 25),
        	SecondaryDisabled = Color3.fromRGB(18, 18, 22),

        	-- Success Button (Medical Green)
        	Success = Color3.fromRGB(80, 200, 120),
        	SuccessHover = Color3.fromRGB(90, 220, 135),
        	SuccessActive = Color3.fromRGB(70, 180, 105),
        	SuccessDisabled = Color3.fromRGB(40, 100, 60),

        	-- Danger Button (Umbrella Red)
        	Danger = Color3.fromRGB(220, 20, 60),
        	DangerHover = Color3.fromRGB(240, 30, 70),
        	DangerActive = Color3.fromRGB(200, 15, 50),
        	DangerDisabled = Color3.fromRGB(110, 10, 30),

        	-- Warning Button (Medical Amber)
        	Warning = Color3.fromRGB(255, 160, 0),
        	WarningHover = Color3.fromRGB(255, 180, 30),
        	WarningActive = Color3.fromRGB(235, 140, 0),
        	WarningDisabled = Color3.fromRGB(130, 80, 0),
        }

        -- ============================================
        -- INPUT COLORS (User-Friendly)
        -- ============================================
        Colors.Input = {
        	Background = Color3.fromRGB(25, 25, 30),   -- Dark panel
        	BackgroundHover = Color3.fromRGB(28, 28, 33),
        	BackgroundFocus = Color3.fromRGB(30, 30, 35),
        	BackgroundDisabled = Color3.fromRGB(20, 20, 25),
        	Border = Color3.fromRGB(60, 60, 68),       -- Gray border (0.6 transparency)
        	BorderFocus = Color3.fromRGB(220, 20, 60), -- Umbrella Red on focus!
        	BorderError = Color3.fromRGB(220, 20, 60), -- Red for errors
        	Text = Color3.fromRGB(245, 245, 250),      -- Corporate white
        	Placeholder = Color3.fromRGB(120, 120, 130), -- Gray placeholder
        }

        -- ============================================
        -- TOGGLE/SWITCH COLORS (Satisfying!)
        -- ============================================
        Colors.Toggle = {
        	On = Color3.fromRGB(220, 20, 60),          -- Umbrella Red when ON!
        	Off = Color3.fromRGB(60, 60, 68),          -- Dark gray when OFF
        	Handle = Color3.fromRGB(245, 245, 250),    -- White circle handle
        	Disabled = Color3.fromRGB(40, 40, 48),     -- Disabled state
        }

        -- ============================================
        -- SLIDER COLORS
        -- ============================================
        Colors.Slider = {
        	Track = Color3.fromRGB(40, 40, 48),        -- Dark track
        	TrackFilled = Color3.fromRGB(220, 20, 60), -- Red filled portion
        	Handle = Color3.fromRGB(245, 245, 250),    -- White handle
        	HandleHover = Color3.fromRGB(240, 30, 70), -- Red glow on hover
        	HandleActive = Color3.fromRGB(220, 20, 60),
        	HandleDisabled = Color3.fromRGB(100, 100, 110),
        }

        -- ============================================
        -- DROPDOWN COLORS (Clean & Modern)
        -- ============================================
        Colors.Dropdown = {
        	Background = Color3.fromRGB(25, 25, 30),
        	Option = Color3.fromRGB(25, 25, 30),
        	OptionHover = Color3.fromRGB(32, 32, 38),
        	OptionSelected = Color3.fromRGB(32, 32, 38),
        	OptionActive = Color3.fromRGB(220, 20, 60), -- Red for active
        	Border = Color3.fromRGB(60, 60, 68),
        	Arrow = Color3.fromRGB(200, 200, 210),
        }

        -- ============================================
        -- SCROLLBAR COLORS (Subtle)
        -- ============================================
        Colors.Scrollbar = {
        	Background = Color3.fromRGB(18, 18, 22),
        	Thumb = Color3.fromRGB(80, 80, 90),
        	ThumbHover = Color3.fromRGB(100, 100, 110),
        	ThumbActive = Color3.fromRGB(120, 120, 130),
        }

        -- ============================================
        -- STATUS COLORS (Medical/Laboratory Theme)
        -- ============================================
        Colors.Status = {
        	Success = Color3.fromRGB(80, 200, 120),    -- Medical green (ECG monitor)
        	Warning = Color3.fromRGB(255, 160, 0),     -- Medical amber
        	Error = Color3.fromRGB(220, 20, 60),       -- Umbrella Red
        	Info = Color3.fromRGB(100, 150, 255),      -- Medical blue
        }

        -- ============================================
        -- ACCENT COLORS (Umbrella Signature)
        -- ============================================
        Colors.Accent = {
        	Primary = Color3.fromRGB(220, 20, 60),     -- Umbrella Red
        	Secondary = Color3.fromRGB(180, 15, 50),   -- Darker red
        	Success = Color3.fromRGB(80, 200, 120),    -- Medical green
        	Warning = Color3.fromRGB(255, 160, 0),     -- Medical amber
        	Danger = Color3.fromRGB(220, 20, 60),      -- Umbrella Red
        	Info = Color3.fromRGB(100, 150, 255),      -- Medical blue
        	Hover = Color3.fromRGB(240, 30, 70),       -- Brighter red for hover
        }

        -- ============================================
        -- SPECIAL COLORS (Effects & Glows)
        -- ============================================
        Colors.Special = {
        	Shadow = Color3.fromRGB(0, 0, 0),          -- For shadows
        	Highlight = Color3.fromRGB(245, 245, 250), -- Corporate white highlights
        	Overlay = Color3.fromRGB(0, 0, 0),         -- Modal overlays (use with transparency)
        	Divider = Color3.fromRGB(40, 40, 48),      -- Separators/dividers

        	-- Glow colors (use with transparency!)
        	RedGlowSubtle = Color3.fromRGB(220, 20, 60),   -- Base: 0.7-0.9 transparency
        	RedGlowBright = Color3.fromRGB(240, 30, 70),   -- Active: 0.4-0.6 transparency
        	GreenGlow = Color3.fromRGB(80, 200, 120),      -- Success glow
        	AmberGlow = Color3.fromRGB(255, 160, 0),       -- Warning glow
        	BlueGlow = Color3.fromRGB(100, 150, 255),      -- Info glow
        }

        -- ============================================
        -- TAB COLORS (Clean Navigation)
        -- ============================================
        Colors.Tab = {
        	Background = Color3.fromRGB(25, 25, 30),
        	BackgroundHover = Color3.fromRGB(28, 28, 33),
        	BackgroundActive = Color3.fromRGB(32, 32, 38), -- Subtle lift when active
        	Text = Color3.fromRGB(245, 245, 250),
        	TextInactive = Color3.fromRGB(150, 150, 160),
        	Indicator = Color3.fromRGB(220, 20, 60),       -- Red active indicator!
        }

        -- ============================================
        -- NOTIFICATION COLORS (Medical Alert Style)
        -- ============================================
        Colors.Notification = {
        	Success = {
        		Background = Color3.fromRGB(25, 25, 30),   -- Dark background
        		Text = Color3.fromRGB(245, 245, 250),
        		Border = Color3.fromRGB(80, 200, 120),     -- Medical green border
        		Accent = Color3.fromRGB(80, 200, 120),
        	},
        	Warning = {
        		Background = Color3.fromRGB(25, 25, 30),
        		Text = Color3.fromRGB(245, 245, 250),
        		Border = Color3.fromRGB(255, 160, 0),      -- Medical amber border
        		Accent = Color3.fromRGB(255, 160, 0),
        	},
        	Error = {
        		Background = Color3.fromRGB(25, 25, 30),
        		Text = Color3.fromRGB(245, 245, 250),
        		Border = Color3.fromRGB(220, 20, 60),      -- Umbrella Red border
        		Accent = Color3.fromRGB(220, 20, 60),
        	},
        	Info = {
        		Background = Color3.fromRGB(25, 25, 30),
        		Text = Color3.fromRGB(245, 245, 250),
        		Border = Color3.fromRGB(100, 150, 255),    -- Medical blue border
        		Accent = Color3.fromRGB(100, 150, 255),
        	},
        }

        -- ============================================
        -- UTILITY FUNCTIONS
        -- ============================================

        -- Convert Color3 to hex string
        function Colors:ToHex(color3)
        	local r = math.floor(color3.R * 255)
        	local g = math.floor(color3.G * 255)
        	local b = math.floor(color3.B * 255)
        	return string.format("#%02X%02X%02X", r, g, b)
        end

        -- Convert hex string to Color3
        function Colors:FromHex(hex)
        	hex = hex:gsub("#", "")
        	local r = tonumber("0x" .. hex:sub(1, 2)) / 255
        	local g = tonumber("0x" .. hex:sub(3, 4)) / 255
        	local b = tonumber("0x" .. hex:sub(5, 6)) / 255
        	return Color3.new(r, g, b)
        end

        -- Lighten a color by a percentage (0-1)
        function Colors:Lighten(color3, amount)
        	amount = math.clamp(amount, 0, 1)
        	local h, s, v = color3:ToHSV()
        	v = math.clamp(v + amount, 0, 1)
        	return Color3.fromHSV(h, s, v)
        end

        -- Darken a color by a percentage (0-1)
        function Colors:Darken(color3, amount)
        	amount = math.clamp(amount, 0, 1)
        	local h, s, v = color3:ToHSV()
        	v = math.clamp(v - amount, 0, 1)
        	return Color3.fromHSV(h, s, v)
        end

        -- Adjust saturation of a color
        function Colors:Saturate(color3, amount)
        	amount = math.clamp(amount, -1, 1)
        	local h, s, v = color3:ToHSV()
        	s = math.clamp(s + amount, 0, 1)
        	return Color3.fromHSV(h, s, v)
        end

        -- Mix two colors with a ratio (0 = color1, 1 = color2)
        function Colors:Mix(color1, color2, ratio)
        	ratio = math.clamp(ratio, 0, 1)
        	return Color3.new(
        		color1.R + (color2.R - color1.R) * ratio,
        		color1.G + (color2.G - color1.G) * ratio,
        		color1.B + (color2.B - color1.B) * ratio
        	)
        end

        -- Get contrasting text color (black or white) based on background
        function Colors:GetContrastText(backgroundColor)
        	local luminance = (0.299 * backgroundColor.R + 0.587 * backgroundColor.G + 0.114 * backgroundColor.B)
        	return luminance > 0.5 and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        end

        -- Apply alpha/transparency to a color (returns color and transparency value)
        function Colors:WithAlpha(color3, alpha)
        	alpha = math.clamp(alpha, 0, 1)
        	return color3, 1 - alpha
        end

        -- Create a gradient of colors
        function Colors:CreateGradient(startColor, endColor, steps)
        	local gradient = {}
        	for i = 0, steps - 1 do
        		local ratio = i / (steps - 1)
        		table.insert(gradient, self:Mix(startColor, endColor, ratio))
        	end
        	return gradient
        end

        -- ============================================
        -- PRESET THEMES
        -- ============================================
        Colors.Themes = {
        	-- Umbrella Corporation Theme (Default)
        	UmbrellaCorp = {
        		Name = "Umbrella Corporation",
        		Primary = Color3.fromRGB(220, 20, 60),
        		Background = Color3.fromRGB(18, 18, 22),
        		Surface = Color3.fromRGB(25, 25, 30),
        		Text = Color3.fromRGB(245, 245, 250),
        		Accent = Color3.fromRGB(220, 20, 60),
        	},

        	-- Medical Lab Theme
        	MedicalLab = {
        		Name = "Medical Laboratory",
        		Primary = Color3.fromRGB(80, 200, 120),
        		Background = Color3.fromRGB(18, 18, 22),
        		Surface = Color3.fromRGB(20, 30, 25),
        		Text = Color3.fromRGB(245, 245, 250),
        		Accent = Color3.fromRGB(80, 200, 120),
        	},

        	-- Umbrella Blue (Alternative)
        	UmbrellaBlue = {
        		Name = "Umbrella Blue",
        		Primary = Color3.fromRGB(100, 150, 255),
        		Background = Color3.fromRGB(15, 20, 30),
        		Surface = Color3.fromRGB(20, 25, 35),
        		Text = Color3.fromRGB(245, 245, 250),
        		Accent = Color3.fromRGB(100, 150, 255),
        	},
        }

        -- ============================================
        -- RETURN MODULE
        -- ============================================
        return Colors

    end

    -- Module: components/label
    EmbeddedModules["components/label"] = function()
        --[[
        	Label Component
        	EzUI Library - Modular Component

        	Creates a text label with optional dynamic function support
        ]]
        local Label = {}

        local Colors

        function Label:Init(_colors)
            Colors = _colors
        end

        function Label:Create(config)
        	local text = config.Text or ""
        	local parentContainer = config.Parent
        	local currentY = config.Y or 0
        	local isForAccordion = config.IsForAccordion or false
        	local textSize = config.Size or config.TextSize -- Support both Size and TextSize
        	local textColor = config.Color or config.TextColor -- Support both Color and TextColor

        	-- Handle case where Parent might be a component API object instead of Instance
        	if parentContainer and type(parentContainer) == "table" then
        		-- Look for common GUI object properties in component APIs
        		if parentContainer.Frame then
        			parentContainer = parentContainer.Frame
        		elseif parentContainer.Button then
        			parentContainer = parentContainer.Button
        		elseif parentContainer.Label then
        			parentContainer = parentContainer.Label
        		elseif parentContainer.Container then
        			parentContainer = parentContainer.Container
        		else
        			-- List available keys for debugging
        			local keys = {}
        			for k, v in pairs(parentContainer) do
        				table.insert(keys, tostring(k))
        			end
        			warn("Label:Create - Parent is a table but no GUI object found. Keys:", table.concat(keys, ", "))
        			parentContainer = nil
        		end
        	end

        	-- Validate parent is an Instance
        	if parentContainer and not typeof(parentContainer) == "Instance" then
        		warn("Label:Create - Parent must be an Instance, got:", typeof(parentContainer))
        		parentContainer = nil
        	end

        	-- Label (UMBRELLA CORP: 14px text, 20px height, Gotham Regular, 8px vertical padding)
        	local label = Instance.new("TextLabel")
        	if isForAccordion then
        		-- Calculate height based on text size with some padding
        		local calculatedTextSize = textSize or 14
        		local labelHeight = math.max(calculatedTextSize + 8, 20) -- Minimum 20px height
        		label.Size = UDim2.new(1, 0, 0, labelHeight)
        		-- Don't set Position for accordion labels - let UIListLayout handle it
        		label.TextSize = calculatedTextSize
        		label.ZIndex = 5
        		-- No debug background needed
        	else
        		label.Size = UDim2.new(1, -20, 0, 20)
        		label.Position = UDim2.new(0, 10, 0, currentY)
        		label.TextSize = textSize or 14
        		label.ZIndex = 3
        		label:SetAttribute("ComponentStartY", currentY)
        	end
        	label.BackgroundTransparency = 1
        	local labelText = type(text) == "function" and text() or text
        	label.Text = tostring(labelText or "")
        	label.TextColor3 = textColor or Colors.Text.Primary

        	-- Debug: Ensure text is visible by using a contrasting color for accordion labels
        	if isForAccordion and not textColor then
        		label.TextColor3 = Colors.Text.Primary
        	end
        	label.TextXAlignment = Enum.TextXAlignment.Left
        	label.TextYAlignment = Enum.TextYAlignment.Top
        	label.Font = Enum.Font.Gotham
        	label.Visible = true -- Ensure label is visible
        	label.Parent = parentContainer

        	-- Padding (UMBRELLA CORP: 8px vertical)
        	local labelPadding = Instance.new("UIPadding")
        	labelPadding.PaddingTop = UDim.new(0, 8)
        	labelPadding.PaddingBottom = UDim.new(0, 8)
        	labelPadding.Parent = label

        	-- Store the text source (function or string)
        	local textSource = text
        	local updateConnection = nil

        	-- Create Label API
        	local labelAPI = {
        		Label = label
        	}

        	-- Function to update text from source
        	local function updateText()
        		if type(textSource) == "function" then
        			local success, result = pcall(textSource)
        			if success then
        				label.Text = tostring(result)
        			else
        				warn("Label dynamic text error:", result)
        				label.Text = "[Error]"
        			end
        		else
        			label.Text = tostring(textSource or "")
        		end
        	end

        	function labelAPI:SetText(newText)
        		textSource = newText
        		updateText()
        	end

        	function labelAPI:GetText()
        		return label.Text
        	end

        	function labelAPI:SetTextColor(color)
        		label.TextColor3 = color
        	end

        	function labelAPI:SetTextSize(size)
        		label.TextSize = size
        		-- Update label height if in accordion
        		if isForAccordion then
        			local labelHeight = math.max(size + 8, 20)
        			label.Size = UDim2.new(1, 0, 0, labelHeight)
        		end
        	end

        	function labelAPI:GetHeight()
        		return label.AbsoluteSize.Y
        	end

        	-- Start auto-update if text is a function
        	function labelAPI:StartAutoUpdate(interval)
        		interval = interval or 1

        		if updateConnection then
        			updateConnection:Disconnect()
        		end

        		if type(textSource) == "function" then
        			local RunService = game:GetService("RunService")
        			local lastUpdate = 0

        			updateConnection = RunService.Heartbeat:Connect(function()
        				local currentTime = tick()
        				if currentTime - lastUpdate >= interval then
        					updateText()
        					lastUpdate = currentTime
        				end
        			end)
        		end
        	end

        	function labelAPI:StopAutoUpdate()
        		if updateConnection then
        			updateConnection:Disconnect()
        			updateConnection = nil
        		end
        	end

        	function labelAPI:Update()
        		updateText()
        	end

        	-- Cleanup when label is destroyed
        	label.AncestryChanged:Connect(function()
        		if not label.Parent then
        			labelAPI:StopAutoUpdate()
        		end
        	end)

        	-- If text is a function, start auto-update by default
        	if type(textSource) == "function" then
        		labelAPI:StartAutoUpdate(1)
        	end

        	return labelAPI
        end

        return Label

    end

    -- Module: components/notification
    EmbeddedModules["components/notification"] = function()
        --[[
        	Notification Component (Sonner-style)
        	EzUI Library - Modular Component

        	Creates toast notifications with stacking, animations, and different types
        	Similar to Sonner from shadcn/ui
        ]]

        local Notification = {}

        local Colors
        local TweenService = game:GetService("TweenService")

        -- Global notification container and state (UMBRELLA CORP: 340px width, 60px height)
        local NotificationContainer = nil
        local ActiveNotifications = {}
        local NotificationId = 0
        local MaxNotifications = 5
        local NotificationWidth = 340
        local NotificationHeight = 60
        local StackOffset = 8
        local AnimationDuration = 0.3

        function Notification:Init(_colors)
        	Colors = _colors
        end

        -- Initialize the global notification container
        local function initializeContainer(screenGui)
        	if NotificationContainer then return end

        	NotificationContainer = Instance.new("Frame")
        	NotificationContainer.Name = "NotificationContainer"
        	NotificationContainer.Size = UDim2.new(0, NotificationWidth + 20, 1, 0)
        	NotificationContainer.Position = UDim2.new(1, -NotificationWidth - 30, 0, 0) -- Top right
        	NotificationContainer.BackgroundTransparency = 1
        	NotificationContainer.ZIndex = 1000
        	NotificationContainer.Parent = screenGui
        end

        -- Create individual notification
        local function createNotification(config)
        	local notificationType = config.Type or "info" -- info, success, warning, error
        	local title = config.Title or ""
        	local message = config.Message or config.Description or ""
        	local duration = config.Duration or 4000 -- milliseconds
        	local action = config.Action -- {label, callback}
        	local onDismiss = config.OnDismiss

        	-- Generate unique ID
        	NotificationId = NotificationId + 1
        	local id = NotificationId

        	-- Create notification frame
        	local notification = Instance.new("Frame")
        	notification.Name = "Notification_" .. id
        	notification.Size = UDim2.new(0, NotificationWidth, 0, NotificationHeight)
        	notification.Position = UDim2.new(0, 10, 0, 20) -- Start position
        	notification.BackgroundColor3 = Colors.Surface.Elevated
        	notification.BorderSizePixel = 0
        	notification.ZIndex = 1001
        	notification.ClipsDescendants = false
        	notification.Parent = NotificationContainer

        	-- Notification corner radius
        	local corner = Instance.new("UICorner")
        	corner.CornerRadius = UDim.new(0, 8)
        	corner.Parent = notification

        	-- Notification border/stroke
        	local stroke = Instance.new("UIStroke")
        	stroke.Thickness = 1
        	stroke.Transparency = 0.8

        	-- Type-specific colors
        	if notificationType == "success" then
        		stroke.Color = Colors.Status.Success
        	elseif notificationType == "warning" then
        		stroke.Color = Colors.Status.Warning
        	elseif notificationType == "error" then
        		stroke.Color = Colors.Status.Error
        	else -- info
        		stroke.Color = Colors.Border.Default
        	end
        	stroke.Parent = notification

        	-- Subtle shadow effect
        	local shadow = Instance.new("Frame")
        	shadow.Size = UDim2.new(1, 4, 1, 4)
        	shadow.Position = UDim2.new(0, -2, 0, 2)
        	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        	shadow.BackgroundTransparency = 0.9
        	shadow.ZIndex = notification.ZIndex - 1
        	shadow.Parent = notification

        	local shadowCorner = Instance.new("UICorner")
        	shadowCorner.CornerRadius = UDim.new(0, 10)
        	shadowCorner.Parent = shadow

        	-- Status indicator (UMBRELLA CORP: 4px thick colored left border)
        	local indicator = Instance.new("Frame")
        	indicator.Size = UDim2.new(0, 4, 1, -16)
        	indicator.Position = UDim2.new(0, 8, 0, 8)
        	indicator.BorderSizePixel = 0
        	indicator.ZIndex = notification.ZIndex + 1
        	indicator.Parent = notification

        	if notificationType == "success" then
        		indicator.BackgroundColor3 = Colors.Status.Success
        	elseif notificationType == "warning" then
        		indicator.BackgroundColor3 = Colors.Status.Warning
        	elseif notificationType == "error" then
        		indicator.BackgroundColor3 = Colors.Umbrella.Red
        	else -- info
        		indicator.BackgroundColor3 = Colors.Status.Info
        	end

        	local indicatorCorner = Instance.new("UICorner")
        	indicatorCorner.CornerRadius = UDim.new(0, 2)
        	indicatorCorner.Parent = indicator

        	-- Glow matching indicator color (UMBRELLA CORP: subtle pulse)
        	local indicatorGlow = Instance.new("UIStroke")
        	indicatorGlow.Color = indicator.BackgroundColor3
        	indicatorGlow.Thickness = 1
        	indicatorGlow.Transparency = 0.7
        	indicatorGlow.Parent = indicator

        	-- Icon (UMBRELLA CORP: 22x22px medical alert style)
        	local icon = Instance.new("TextLabel")
        	icon.Size = UDim2.new(0, 22, 0, 22)
        	icon.Position = UDim2.new(0, 18, 0, 10)
        	icon.BackgroundTransparency = 1
        	icon.Font = Enum.Font.GothamBold
        	icon.TextSize = 16
        	icon.TextColor3 = Colors.Text.Primary
        	icon.TextXAlignment = Enum.TextXAlignment.Center
        	icon.TextYAlignment = Enum.TextYAlignment.Center
        	icon.ZIndex = notification.ZIndex + 1
        	icon.Parent = notification

        	if notificationType == "success" then
        		icon.Text = "✓"
        		icon.TextColor3 = Colors.Status.Success
        	elseif notificationType == "warning" then
        		icon.Text = "⚠"
        		icon.TextColor3 = Colors.Status.Warning
        	elseif notificationType == "error" then
        		icon.Text = "!"
        		icon.TextColor3 = Colors.Umbrella.Red
        		icon.TextSize = 18
        	else -- info
        		icon.Text = "i"
        		icon.TextColor3 = Colors.Status.Info
        	end

        	-- Content container (UMBRELLA CORP: 14px padding from icon)
        	local contentContainer = Instance.new("Frame")
        	contentContainer.Size = UDim2.new(1, action and -90 or -60, 1, -14)
        	contentContainer.Position = UDim2.new(0, 46, 0, 7)
        	contentContainer.BackgroundTransparency = 1
        	contentContainer.ZIndex = notification.ZIndex + 1
        	contentContainer.Parent = notification

        	-- Padding
        	local contentPadding = Instance.new("UIPadding")
        	contentPadding.PaddingLeft = UDim.new(0, 8)
        	contentPadding.PaddingRight = UDim.new(0, 8)
        	contentPadding.Parent = contentContainer

        	-- Title (UMBRELLA CORP: 14px Gotham Semibold)
        	local hasTitle = title and title ~= ""
        	local titleLabel = nil
        	if hasTitle then
        		titleLabel = Instance.new("TextLabel")
        		titleLabel.Size = UDim2.new(1, 0, 0, 18)
        		titleLabel.Position = UDim2.new(0, 0, 0, 2)
        		titleLabel.BackgroundTransparency = 1
        		titleLabel.Text = title
        		titleLabel.TextColor3 = Colors.Text.Primary
        		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        		titleLabel.TextYAlignment = Enum.TextYAlignment.Top
        		titleLabel.Font = Enum.Font.GothamBold
        		titleLabel.TextSize = 14
        		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        		titleLabel.ZIndex = contentContainer.ZIndex + 1
        		titleLabel.Parent = contentContainer
        	end

        	-- Message (UMBRELLA CORP: 13px Gotham Regular)
        	if message and message ~= "" then
        		local messageLabel = Instance.new("TextLabel")
        		messageLabel.Size = UDim2.new(1, 0, hasTitle and 0, 16 or 1, 0)
        		messageLabel.Position = UDim2.new(0, 0, hasTitle and 0, 20 or 0, 0)
        		messageLabel.BackgroundTransparency = 1
        		messageLabel.Text = message
        		messageLabel.TextColor3 = Colors.Text.Secondary
        		messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        		messageLabel.TextYAlignment = hasTitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        		messageLabel.Font = Enum.Font.Gotham
        		messageLabel.TextSize = 13
        		messageLabel.TextWrapped = true
        		messageLabel.ZIndex = contentContainer.ZIndex + 1
        		messageLabel.Parent = contentContainer
        	end

        	-- Action button (more compact)
        	if action then
        		local actionButton = Instance.new("TextButton")
        		actionButton.Size = UDim2.new(0, 50, 0, 20)  -- Reduced from 60x24
        		actionButton.Position = UDim2.new(1, -55, 0.5, -10)  -- Adjusted position
        		actionButton.BackgroundColor3 = Colors.Button.Primary
        		actionButton.BorderSizePixel = 0
        		actionButton.Text = action.label or "Action"
        		actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        		actionButton.Font = Enum.Font.Gotham
        		actionButton.TextSize = 10  -- Reduced from 11
        		actionButton.ZIndex = notification.ZIndex + 2
        		actionButton.Parent = notification

        		local actionCorner = Instance.new("UICorner")
        		actionCorner.CornerRadius = UDim.new(0, 4)
        		actionCorner.Parent = actionButton

        		-- Action button hover
        		actionButton.MouseEnter:Connect(function()
        			local tween = TweenService:Create(actionButton, TweenInfo.new(0.2), {
        				BackgroundColor3 = Colors.Button.PrimaryHover
        			})
        			tween:Play()
        		end)

        		actionButton.MouseLeave:Connect(function()
        			local tween = TweenService:Create(actionButton, TweenInfo.new(0.2), {
        				BackgroundColor3 = Colors.Button.Primary
        			})
        			tween:Play()
        		end)

        		actionButton.MouseButton1Click:Connect(function()
        			if action.callback then
        				action.callback()
        			end
        			Notification:Dismiss(id)
        		end)
        	end

        	-- Close button (moved to top-right corner)
        	local closeButton = Instance.new("TextButton")
        	closeButton.Size = UDim2.new(0, 20, 0, 20)
        	closeButton.Position = UDim2.new(1, -24, 0, 0)  -- Moved even closer to top edge
        	closeButton.BackgroundTransparency = 1
        	closeButton.Text = "×"
        	closeButton.TextColor3 = Colors.Text.Secondary
        	closeButton.TextSize = 16
        	closeButton.Font = Enum.Font.GothamBold
        	closeButton.ZIndex = notification.ZIndex + 2
        	closeButton.Parent = notification

        	-- Close button hover
        	closeButton.MouseEnter:Connect(function()
        		closeButton.TextColor3 = Colors.Text.Primary
        		closeButton.BackgroundTransparency = 0.9
        		closeButton.BackgroundColor3 = Colors.Surface.Hover
        	end)

        	closeButton.MouseLeave:Connect(function()
        		closeButton.TextColor3 = Colors.Text.Secondary
        		closeButton.BackgroundTransparency = 1
        	end)

        	closeButton.MouseButton1Click:Connect(function()
        		Notification:Dismiss(id)
        	end)

        	-- Progress bar (for duration, more compact)
        	local progressBar = Instance.new("Frame")
        	progressBar.Size = UDim2.new(1, -8, 0, 2)  -- Slightly wider (reduced margin from 12 to 8)
        	progressBar.Position = UDim2.new(0, 4, 1, -6)  -- Adjusted position (closer to bottom edge)
        	progressBar.BackgroundColor3 = indicator.BackgroundColor3
        	progressBar.BackgroundTransparency = 0.7
        	progressBar.BorderSizePixel = 0
        	progressBar.ZIndex = notification.ZIndex + 1
        	progressBar.Parent = notification

        	local progressCorner = Instance.new("UICorner")
        	progressCorner.CornerRadius = UDim.new(0, 1)
        	progressCorner.Parent = progressBar

        	-- Store notification data
        	local notificationData = {
        		id = id,
        		frame = notification,
        		duration = duration,
        		onDismiss = onDismiss,
        		startTime = tick() * 1000,
        		progressBar = progressBar
        	}

        	table.insert(ActiveNotifications, notificationData)

        	-- Calculate proper position for this notification
        	local notificationIndex = #ActiveNotifications
        	local yOffset = 20 + ((notificationIndex - 1) * (NotificationHeight + StackOffset))

        	-- Animate in from off-screen to proper stacked position
        	notification.Position = UDim2.new(1, 0, 0, yOffset) -- Start off-screen at correct Y
        	local slideIn = TweenService:Create(notification, 
        		TweenInfo.new(AnimationDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        		{Position = UDim2.new(0, 10, 0, yOffset)}
        	)
        	slideIn:Play()

        	-- Update positions for all other notifications (to apply stacking effects)
        	updateNotificationPositions()

        	-- Auto dismiss after duration
        	if duration > 0 then
        		task.spawn(function()
        			local startTime = tick() * 1000
        			while true do
        				task.wait(0.1)
        				local elapsed = (tick() * 1000) - startTime
        				local progress = elapsed / duration

        				if progress >= 1 then
        					Notification:Dismiss(id)
        					break
        				end

        				-- Update progress bar
        				progressBar.Size = UDim2.new(1 - progress, -12, 0, 2)
        			end
        		end)
        	end

        	-- Remove old notifications if exceeding max
        	if #ActiveNotifications > MaxNotifications then
        		Notification:Dismiss(ActiveNotifications[1].id)
        	end

        	return id
        end

        -- Update notification positions with stacking effect
        function updateNotificationPositions()
        	for i, notificationData in ipairs(ActiveNotifications) do
        		local yOffset = 20 + ((i - 1) * (NotificationHeight + StackOffset))
        		local scale = math.max(0.95, 1 - ((i - 1) * 0.02)) -- Slight scale reduction for stacked items
        		local transparency = math.min(0.3, (i - 1) * 0.1) -- Slight transparency for stacked items

        		local tween = TweenService:Create(notificationData.frame,
        			TweenInfo.new(AnimationDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        			{
        				Position = UDim2.new(0, 10, 0, yOffset),
        				Size = UDim2.new(0, NotificationWidth * scale, 0, NotificationHeight * scale)
        			}
        		)
        		tween:Play()

        		-- Apply transparency to stacked notifications
        		if i > 1 then
        			notificationData.frame.BackgroundTransparency = transparency
        		else
        			notificationData.frame.BackgroundTransparency = 0
        		end
        	end
        end

        -- Public API
        function Notification:Create(config)
        	if not config then
        		warn("Notification:Create requires a config table")
        		return nil
        	end

        	-- Initialize container if needed
        	local screenGui = config.ScreenGui or game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChildOfClass("ScreenGui")
        	initializeContainer(screenGui)

        	return createNotification(config)
        end

        -- Dismiss notification by ID
        function Notification:Dismiss(id)
        	for i, notificationData in ipairs(ActiveNotifications) do
        		if notificationData.id == id then
        			-- Animate out
        			local slideOut = TweenService:Create(notificationData.frame,
        				TweenInfo.new(AnimationDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        				{Position = UDim2.new(1, 0, notificationData.frame.Position.Y.Scale, notificationData.frame.Position.Y.Offset)}
        			)

        			slideOut:Play()
        			slideOut.Completed:Connect(function()
        				notificationData.frame:Destroy()
        			end)

        			-- Call dismiss callback
        			if notificationData.onDismiss then
        				notificationData.onDismiss()
        			end

        			-- Remove from active notifications
        			table.remove(ActiveNotifications, i)

        			-- Update positions
        			updateNotificationPositions()
        			break
        		end
        	end
        end

        -- Clear all notifications
        function Notification:Clear()
        	for _, notificationData in ipairs(ActiveNotifications) do
        		local slideOut = TweenService:Create(notificationData.frame,
        			TweenInfo.new(AnimationDuration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        			{Position = UDim2.new(1, 0, notificationData.frame.Position.Y.Scale, notificationData.frame.Position.Y.Offset)}
        		)
        		slideOut:Play()
        		slideOut.Completed:Connect(function()
        			notificationData.frame:Destroy()
        		end)
        	end
        	ActiveNotifications = {}
        end

        -- Convenience methods for different types
        function Notification:Success(config)
        	config = config or {}
        	config.Type = "success"
        	return self:Create(config)
        end

        function Notification:Warning(config)
        	config = config or {}
        	config.Type = "warning"
        	return self:Create(config)
        end

        function Notification:Error(config)
        	config = config or {}
        	config.Type = "error"
        	return self:Create(config)
        end

        function Notification:Info(config)
        	config = config or {}
        	config.Type = "info"
        	return self:Create(config)
        end

        return Notification
    end

    -- Module: components/separator
    EmbeddedModules["components/separator"] = function()
        --[[
        	Separator Component
        	EzUI Library - Modular Component

        	Creates a horizontal line separator
        ]]
        local Separator = {}

        local Colors

        function Separator:Init(_colors)
        	Colors = _colors
        end

        function Separator:Create(config)
        	local parentContainer = config.Parent
        	local currentY = config.Y or 0
        	local isForAccordion = config.IsForAccordion or false

        	-- Handle case where Parent might be a component API object instead of Instance
        	if parentContainer and type(parentContainer) == "table" then
        		-- Look for common GUI object properties in component APIs
        		if parentContainer.Frame then
        			parentContainer = parentContainer.Frame
        		elseif parentContainer.Button then
        			parentContainer = parentContainer.Button
        		elseif parentContainer.Label then
        			parentContainer = parentContainer.Label
        		elseif parentContainer.Container then
        			parentContainer = parentContainer.Container
        		else
        			-- List available keys for debugging
        			local keys = {}
        			for k, v in pairs(parentContainer) do
        				table.insert(keys, tostring(k))
        			end
        			warn("Separator:Create - Parent is a table but no GUI object found. Keys:", table.concat(keys, ", "))
        			parentContainer = nil
        		end
        	end

        	-- Validate parent is an Instance
        	if parentContainer and not typeof(parentContainer) == "Instance" then
        		warn("Separator:Create - Parent must be an Instance, got:", typeof(parentContainer))
        		parentContainer = nil
        	end

        	local separator = Instance.new("Frame")
        	if isForAccordion then
        		separator.Size = UDim2.new(1, 0, 0, 1)
        		-- Don't set Position for accordion separators - let UIListLayout handle it
        		separator.ZIndex = 5
        	else
        		separator.Size = UDim2.new(1, -20, 0, 1)
        		separator.Position = UDim2.new(0, 10, 0, currentY + 5)
        		separator.ZIndex = 3
        		separator:SetAttribute("ComponentStartY", currentY)
        	end
        	separator.BackgroundColor3 = Colors.Special.Divider
        	separator.BorderSizePixel = 0
        	separator.Parent = parentContainer

        	-- Create Separator API
        	local separatorAPI = {
        		Separator = separator
        	}

        	function separatorAPI:SetColor(color)
        		separator.BackgroundColor3 = color
        	end

        	return separatorAPI
        end

        return Separator

    end

    -- Module: components/tab
    EmbeddedModules["components/tab"] = function()
        --[[
        	Tab Component
        	EzUI Library - Modular Component

        	Creates a tab with icon, title, and content
        ]]
        -- Component modules (will be loaded by Window)

        local Tab = {}

        local Colors
        local Button
        local Toggle
        local TextBox
        local NumberBox
        local SelectBox
        local Label
        local Separator
        local Accordion

        -- Initialize component modules
        function Tab:Init(_colors, _accordion, _button, _toggle, _textbox, _numberbox, _selectbox, _label, _separator)
        	Colors = _colors
        	Accordion = _accordion
        	Button = _button
        	Toggle = _toggle
        	TextBox = _textbox
        	NumberBox = _numberbox
        	SelectBox = _selectbox
        	Label = _label
        	Separator = _separator
        end

        function Tab:Create(config)
        	local tabName = config.Name or config.Title or "New Tab"
        	local tabIcon = config.Icon or nil
        	local tabVisible = config.Visible ~= nil and config.Visible or true
        	local tabCallback = config.Callback or nil
        	local tabScrollFrame = config.TabScrollFrame
        	local tabContents = config.TabContents
        	local scrollFrame = config.ScrollFrame
        	local updateCanvasSize = config.UpdateCanvasSize

        	-- Create tab content frame for this specific tab
        	local tabContent = Instance.new("Frame")
        	tabContent.Size = UDim2.new(1, 0, 1, 0)
        	tabContent.Position = UDim2.new(0, 0, 0, 0)
        	tabContent.BackgroundTransparency = 1
        	tabContent.Visible = false
        	tabContent.ClipsDescendants = false -- Allow SelectBox dropdowns to show
        	tabContent.ZIndex = 2 -- Above scroll frame
        	tabContent.Parent = scrollFrame

        	-- Store tab content in the tabContents table if it exists
        	if tabContents then
        		tabContents[tabName] = tabContent
        	end

        	-- SpeedHub style colors with UMBRELLA RED accent
        	local SH_DarkAlt = Color3.fromRGB(50, 47, 55) -- Selected tab background (warmer)
        	local SH_ItemBg = Color3.fromRGB(65, 60, 70) -- Hover background (warmer)
        	local SH_Coral = Color3.fromRGB(220, 20, 60) -- UMBRELLA RED accent (changed from coral)
        	local SH_TextLight = Color3.fromRGB(245, 245, 245)

        	-- Tab button (SpeedHub style: 40px height, rounded corners)
        	local tabBtn = Instance.new("TextButton")
        	tabBtn.Size = UDim2.new(1, 0, 0, 40)
        	tabBtn.BackgroundColor3 = Color3.fromRGB(30, 28, 32) -- Default dark (warmer)
        	tabBtn.BackgroundTransparency = 1 -- Transparent by default
        	tabBtn.Text = ""
        	tabBtn.BorderSizePixel = 0
        	tabBtn.ZIndex = 4
        	tabBtn.Visible = tabVisible
        	tabBtn.Parent = tabScrollFrame

        	-- Rounded corners for tab button - TUMPUL (more rounded)
        	local tabCorner = Instance.new("UICorner")
        	tabCorner.CornerRadius = UDim.new(0, 12) -- Lebih tumpul/rounded
        	tabCorner.Parent = tabBtn

        	-- Active indicator (SpeedHub: left bar, coral color)
        	local activeIndicator = Instance.new("Frame")
        	activeIndicator.Size = UDim2.new(0, 3, 0, 26)
        	activeIndicator.Position = UDim2.new(0, 4, 0.5, -13)
        	activeIndicator.BackgroundColor3 = SH_Coral -- Coral accent
        	activeIndicator.BorderSizePixel = 0
        	activeIndicator.ZIndex = 6
        	activeIndicator.Visible = false
        	activeIndicator.Parent = tabBtn

        	local indicatorCorner = Instance.new("UICorner")
        	indicatorCorner.CornerRadius = UDim.new(0, 2)
        	indicatorCorner.Parent = activeIndicator

        	-- No glow animation for cleaner SpeedHub look

        	-- Icon label (SpeedHub style: left side with icon, compact spacing)
        	local iconLabel = Instance.new("TextLabel")
        	iconLabel.Size = UDim2.new(0, 24, 1, 0) -- Slightly smaller for compact look
        	iconLabel.Position = UDim2.new(0, 12, 0, 0) -- Closer to left edge
        	iconLabel.BackgroundTransparency = 1
        	iconLabel.Text = tabIcon or ""
        	iconLabel.TextColor3 = SH_TextLight -- Light text
        	iconLabel.Font = Enum.Font.GothamMedium
        	iconLabel.TextSize = 16
        	iconLabel.TextXAlignment = Enum.TextXAlignment.Left
        	iconLabel.ZIndex = 5
        	iconLabel.Parent = tabBtn

        	-- Title label (SpeedHub style: 14px, light text)
        	local titleLabel = Instance.new("TextLabel")
        	titleLabel.BackgroundTransparency = 1
        	titleLabel.Text = tabName
        	titleLabel.TextColor3 = SH_TextLight -- Light text
        	titleLabel.Font = Enum.Font.GothamMedium
        	titleLabel.TextSize = 14
        	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
        	titleLabel.ZIndex = 5
        	titleLabel.Parent = tabBtn

        	-- Function to update title alignment based on icon presence
        	local function updateTitleAlignment()
        		if tabIcon and tabIcon ~= "" then
        			-- Icon on left, title on right (compact spacing like Speed Hub X)
        			titleLabel.Size = UDim2.new(1, -48, 1, 0)
        			titleLabel.Position = UDim2.new(0, 40, 0, 0) -- Closer to icon (was 38, now 40 but with LEFT align)
        			titleLabel.TextXAlignment = Enum.TextXAlignment.Left -- Changed from Right to Left for compact look
        			iconLabel.Visible = true
        		else
        			-- No icon, title centered
        			titleLabel.Size = UDim2.new(1, -16, 1, 0)
        			titleLabel.Position = UDim2.new(0, 8, 0, 0)
        			titleLabel.TextXAlignment = Enum.TextXAlignment.Center
        			iconLabel.Visible = false
        		end
        	end

        	-- Initial alignment setup
        	updateTitleAlignment()

        	-- Track current Y position for components (reduced top spacing)
        	local currentY = 5

        	-- Helper function to update canvas size after adding components
        	local function updateTabCanvasSize()
        		if updateCanvasSize and tabContent.Visible then
        			-- Only update if this tab is currently active
        			task.spawn(function()
        				task.wait() -- Wait for component to be fully added
        				updateCanvasSize()
        			end)
        		end
        	end

        	-- Tab API
        	local tabAPI = {
        		Button = tabBtn,
        		Content = tabContent,
        		Name = tabName,
        	}

        	function tabAPI:SetIcon(newIcon)
        		tabIcon = newIcon
        		iconLabel.Text = newIcon or ""
        		updateTitleAlignment()
        	end

        	function tabAPI:SetTitle(newTitle)
        		tabName = newTitle
        		titleLabel.Text = newTitle
        	end

        	function tabAPI:SetVisible(visible)
        		tabBtn.Visible = visible
        	end

        	function tabAPI:Show()
        		tabContent.Visible = true
        	end

        	function tabAPI:Hide()
        		tabContent.Visible = false
        	end

        	function tabAPI:IsVisible()
        		return tabContent.Visible
        	end

        	function tabAPI:Select()
        		tabContent.Visible = true
        		tabBtn.BackgroundTransparency = 0
        		tabBtn.BackgroundColor3 = SH_DarkAlt -- SpeedHub selected background
        		activeIndicator.Visible = true
        		titleLabel.TextColor3 = SH_TextLight
        		iconLabel.TextColor3 = SH_TextLight

        		-- Update canvas size when tab becomes active
        		if updateCanvasSize then
        			-- Wait a frame to ensure visibility changes are processed
        			task.spawn(function()
        				task.wait()
        				updateCanvasSize()
        			end)
        		end

        		if tabCallback then
        			tabCallback()
        		end
        	end

        	function tabAPI:Deselect()
        		tabContent.Visible = false
        		tabBtn.BackgroundTransparency = 1
        		activeIndicator.Visible = false
        		titleLabel.TextColor3 = SH_TextLight
        		iconLabel.TextColor3 = SH_TextLight
        	end

        	-- Hover effects (SpeedHub style: slight background change)
        	tabBtn.MouseEnter:Connect(function()
        		if not tabContent.Visible then
        			tabBtn.BackgroundTransparency = 0
        			tabBtn.BackgroundColor3 = SH_ItemBg -- Hover background
        			local hoverGlow = tabBtn:FindFirstChild("HoverGlow")
        			if not hoverGlow then
        				hoverGlow = Instance.new("Frame")
        				hoverGlow.Name = "HoverGlow"
        				hoverGlow.Size = UDim2.new(1, 0, 1, 0)
        				hoverGlow.BackgroundColor3 = Colors.Umbrella.Red
        				hoverGlow.BackgroundTransparency = 0.9
        				hoverGlow.BorderSizePixel = 0
        				hoverGlow.ZIndex = 5
        				hoverGlow.Parent = tabBtn
        				local hoverCorner = Instance.new("UICorner")
        				hoverCorner.CornerRadius = UDim.new(0, 6)
        				hoverCorner.Parent = hoverGlow
        			end
        		end
        	end)

        	tabBtn.MouseLeave:Connect(function()
        		local hoverGlow = tabBtn:FindFirstChild("HoverGlow")
        		if hoverGlow then
        			hoverGlow:Destroy()
        		end
        		if not tabContent.Visible then
        			tabBtn.BackgroundTransparency = 1
        		else
        			tabBtn.BackgroundTransparency = 0
        			tabBtn.BackgroundColor3 = Colors.Tab.BackgroundActive
        		end
        	end)

        	-- Add Button Component
        	function tabAPI:AddButton(buttonConfig)
        		if not Button then
        			warn("Tab.AddButton: Button module not initialized")
        			return nil
        		end

        		local btnConfig
        		if type(buttonConfig) == "string" then
        			btnConfig = {Text = buttonConfig}
        		elseif type(buttonConfig) == "table" then
        			btnConfig = buttonConfig
        		else
        			btnConfig = {}
        		end

        		btnConfig.Parent = tabContent
        		btnConfig.Y = currentY
        		btnConfig.EzUI = config.EzUI
        		btnConfig.SaveConfiguration = config.SaveConfiguration
        		btnConfig.RegisterComponent = config.RegisterComponent

        		local buttonAPI = Button:Create(btnConfig)
        		currentY = currentY + 35
        		updateTabCanvasSize()

        		return buttonAPI
        	end

        	-- Add Toggle Component
        	function tabAPI:AddToggle(toggleConfig)
        		if not Toggle then
        			warn("Tab.AddToggle: Toggle module not initialized")
        			return nil
        		end

        		toggleConfig = toggleConfig or {}
        		toggleConfig.Parent = tabContent
        		toggleConfig.Y = currentY
        		toggleConfig.EzUI = config.EzUI
        		toggleConfig.SaveConfiguration = config.SaveConfiguration
        		toggleConfig.RegisterComponent = config.RegisterComponent
        		toggleConfig.Settings= config.Settings

        		local toggleAPI = Toggle:Create(toggleConfig)
        		currentY = currentY + 35
        		updateTabCanvasSize()

        		return toggleAPI
        	end

        	-- Add TextBox Component
        	function tabAPI:AddTextBox(textboxConfig)
        		if not TextBox then
        			warn("Tab.AddTextBox: TextBox module not initialized")
        			return nil
        		end

        		textboxConfig = textboxConfig or {}
        		textboxConfig.Parent = tabContent
        		textboxConfig.Y = currentY
        		textboxConfig.EzUI = config.EzUI
        		textboxConfig.SaveConfiguration = config.SaveConfiguration
        		textboxConfig.RegisterComponent = config.RegisterComponent
        		textboxConfig.Settings= config.Settings

        		local textboxAPI = TextBox:Create(textboxConfig)

        		-- Calculate height based on TextBox configuration
        		local hasTitle = (textboxConfig.Name and textboxConfig.Name ~= "") or (textboxConfig.Title and textboxConfig.Title ~= "")
        		local multiline = textboxConfig.Multiline or false
        		local labelHeight = hasTitle and 18 or 0
        		local inputHeight = multiline and 80 or 30
        		local spacing = hasTitle and 2 or 0
        		local totalHeight = labelHeight + inputHeight + spacing + 5 -- +5 for component spacing

        		currentY = currentY + totalHeight
        		updateTabCanvasSize()

        		return textboxAPI
        	end

        	-- Add NumberBox Component
        	function tabAPI:AddNumberBox(numberboxConfig)
        		if not NumberBox then
        			warn("Tab.AddNumberBox: NumberBox module not initialized")
        			return nil
        		end

        		numberboxConfig = numberboxConfig or {}
        		numberboxConfig.Parent = tabContent
        		numberboxConfig.Y = currentY
        		numberboxConfig.EzUI = config.EzUI
        		numberboxConfig.SaveConfiguration = config.SaveConfiguration
        		numberboxConfig.RegisterComponent = config.RegisterComponent
        		numberboxConfig.Settings= config.Settings

        		local numberboxAPI = NumberBox:Create(numberboxConfig)
        		currentY = currentY + 35
        		updateTabCanvasSize()

        		return numberboxAPI
        	end

        	-- Add SelectBox Component
        	function tabAPI:AddSelectBox(selectboxConfig)
        		if not SelectBox then
        			warn("Tab.AddSelectBox: SelectBox module not initialized")
        			return nil
        		end

        		selectboxConfig = selectboxConfig or {}
        		selectboxConfig.Parent = tabContent
        		selectboxConfig.Y = currentY
        		selectboxConfig.ScreenGui = config.ScreenGui
        		selectboxConfig.EzUI = config.EzUI
        		selectboxConfig.SaveConfiguration = config.SaveConfiguration
        		selectboxConfig.RegisterComponent = config.RegisterComponent
        		selectboxConfig.Settings= config.Settings

        		local selectboxAPI = SelectBox:Create(selectboxConfig)
        		currentY = currentY + 30
        		updateTabCanvasSize()

        		return selectboxAPI
        	end

        	-- Add Label Component
        	function tabAPI:AddLabel(labelConfig)
        		if not Label then
        			warn("Tab.AddLabel: Label module not initialized")
        			return nil
        		end

        		local lblConfig
        		if type(labelConfig) == "string" then
        			lblConfig = {Text = labelConfig}
        		elseif type(labelConfig) == "function" then
        			lblConfig = {Text = labelConfig}
        		elseif type(labelConfig) == "table" then
        			lblConfig = labelConfig
        		else
        			lblConfig = {}
        		end

        		lblConfig.Parent = tabContent
        		lblConfig.Y = currentY
        		-- Size and Color are already passed through if they exist in labelConfig table

        		local labelAPI = Label:Create(lblConfig)
        		currentY = currentY + 25
        		updateTabCanvasSize()

        		return labelAPI
        	end

        	-- Add Separator Component
        	function tabAPI:AddSeparator(separatorConfig)
        		if not Separator then
        			warn("Tab.AddSeparator: Separator module not initialized")
        			return nil
        		end

        		separatorConfig = separatorConfig or {}
        		separatorConfig.Parent = tabContent
        		separatorConfig.Y = currentY

        		local separatorAPI = Separator:Create(separatorConfig)
        		currentY = currentY + 15
        		updateTabCanvasSize()

        		return separatorAPI
        	end

        	-- Add Accordion Component (USING MODULAR ACCORDION)
        	function tabAPI:AddAccordion(accordionConfig)
        		if not Accordion then
        			warn("Tab.AddAccordion: Accordion module not initialized")
        			return nil
        		end

        		accordionConfig = accordionConfig or {}

        		-- Set parent and position
        		accordionConfig.Parent = tabContent
        		accordionConfig.Y = currentY

        		-- Pass through EzUI config
        		accordionConfig.EzUI = config.EzUI
        		accordionConfig.SaveConfiguration = config.SaveConfiguration
        		accordionConfig.RegisterComponent = config.RegisterComponent
        		accordionConfig.Settings= config.Settings
        		accordionConfig.ScreenGui = config.ScreenGui

        		-- Pass callback for height changes
        		accordionConfig.OnHeightChanged = function()
        			-- Recalculate tab height
        			local maxY = 10

        			for _, child in pairs(tabContent:GetChildren()) do
        				if child:IsA("GuiObject") and child.Visible then
        					local childBottom = child.Position.Y.Offset + child.AbsoluteSize.Y
        					maxY = math.max(maxY, childBottom)
        				end
        			end

        			-- Update currentY (reduced spacing)
        			currentY = maxY + 2

        			-- Use our unified canvas update function
        			updateTabCanvasSize()
        		end

        		-- Create accordion using module
        		local accordionAPI = Accordion:Create(accordionConfig)

        		-- Update currentY for next component based on actual container size (reduced spacing)
        		task.wait() -- Ensure size is rendered
        		local actualHeight = accordionAPI.Container.AbsoluteSize.Y
        		currentY = currentY + actualHeight + 2
        		updateTabCanvasSize()

        		return accordionAPI
        	end

        	return tabAPI
        end

        return Tab

    end

    -- Module: components/window
    EmbeddedModules["components/window"] = function()
        --[[
        	Window Component
        	EzUI Library - Modular Component

        	Creates main window with responsive sizing and dragging
        ]]

        local Window = {}
        local Colors
        local Accordion
        local Button
        local Label
        local NumberBox
        local Notification
        local SelectBox
        local Separator
        local Tab
        local TextBox
        local Toggle

        function Window:Init(_colors, _accordion, _button, _label, _numberbox, _notification, _selectbox, _separator, _tab, _textbox, _toggle)
            Colors = _colors
            Accordion = _accordion
            Button = _button
            Label = _label
            NumberBox = _numberbox
            Notification = _notification
            SelectBox = _selectbox
            Separator = _separator
            Tab = _tab
            TextBox = _textbox
            Toggle = _toggle

            -- Debug: Verify Colors module is loaded
            if not Colors then
                warn("Window:Init() - Colors module is nil!")
            elseif not Colors.Background then
                warn("Window:Init() - Colors module missing Background property!")
            end
        end

        function Window:GetViewportSize()
        	local camera = workspace.CurrentCamera
        	if not camera then
        		camera = workspace:WaitForChild("CurrentCamera", 5)
        	end

        	local viewportSize = camera.ViewportSize

        	if viewportSize.X <= 1 or viewportSize.Y <= 1 then
        		viewportSize = Vector2.new(1366, 768)
        		warn("EzUI: Using fallback viewport size:", viewportSize)
        	end

        	return viewportSize
        end

        function Window:CalculateDynamicSize(width, height)
        	local viewportSize = self:GetViewportSize()

        	local baseWidth = width or (viewportSize.X * 0.7)
        	local baseHeight = height or (viewportSize.Y * 0.4)

        	local scaleMultiplier = 1
        	if viewportSize.X >= 1920 then
        		scaleMultiplier = 1.2
        	elseif viewportSize.X >= 1366 then
        		scaleMultiplier = 1.0
        	elseif viewportSize.X >= 1024 then
        		scaleMultiplier = 0.9
        	else
        		scaleMultiplier = 0.8
        	end

        	local finalWidth = math.max(300, math.min(viewportSize.X * 0.8, baseWidth * scaleMultiplier))
        	local finalHeight = math.max(200, math.min(viewportSize.Y * 0.8, baseHeight * scaleMultiplier))

        	return finalWidth, finalHeight
        end

        function Window:CreateFloatingButton(screenGui, frame, toggleMinimizeCallback, autoShow)
        	-- Create floating button (visibility based on AutoShow parameter)
        	local floatingButton = Instance.new("Frame")
        	floatingButton.Size = UDim2.new(0, 80, 0, 80)
        	floatingButton.Position = UDim2.new(0, 0, 0.5, -40) -- Middle left by default
        	floatingButton.BackgroundTransparency = 1 -- Transparent background, no circular border
        	floatingButton.BorderSizePixel = 0
        	floatingButton.ZIndex = 100
        	floatingButton.Visible = not autoShow -- Show floating button if window starts hidden
        	floatingButton.Active = true
        	floatingButton.Parent = screenGui

        	-- No UICorner - we want just the icon without rounded border

        	-- Umbrella Corporation icon using ImageLabel
            local arrowIcon = Instance.new("ImageLabel")
        	arrowIcon.Size = UDim2.new(1, 0, 1, 0)
        	arrowIcon.BackgroundTransparency = 1
        	arrowIcon.Image = "rbxassetid://105703453649379"
        	arrowIcon.ScaleType = Enum.ScaleType.Fit
        	arrowIcon.ZIndex = 101
        	arrowIcon.Parent = floatingButton

        	local scale = Instance.new("UIScale")
        	scale.Scale = 1.4 
        	scale.Parent = arrowIcon

        	-- Click detector for floating button
        	local floatingClickButton = Instance.new("TextButton")
        	floatingClickButton.Size = UDim2.new(1, 0, 1, 0)
        	floatingClickButton.BackgroundTransparency = 1
        	floatingClickButton.Text = ""
        	floatingClickButton.ZIndex = 102
        	floatingClickButton.Parent = floatingButton

        	-- No shadow effect - clean icon only

        	-- Hover effects for icon (transparency change)
        	floatingClickButton.MouseEnter:Connect(function()
        		arrowIcon.ImageTransparency = 0.3
        	end)

        	floatingClickButton.MouseLeave:Connect(function()
        		arrowIcon.ImageTransparency = 0
        	end)

        	-- Dragging functionality for floating button (FREE PLACEMENT - NO SNAP)
        	local floatingDragging = false
        	local floatingDragInput, floatingDragStart, floatingStartPos

        	local function updateFloatingDrag(input)
        		local delta = input.Position - floatingDragStart
        		local newPos = UDim2.new(
        			floatingStartPos.X.Scale,
        			floatingStartPos.X.Offset + delta.X,
        			floatingStartPos.Y.Scale,
        			floatingStartPos.Y.Offset + delta.Y
        		)
        		floatingButton.Position = newPos
        	end

        	floatingClickButton.InputBegan:Connect(function(input)
        		if input.UserInputType == Enum.UserInputType.MouseButton1 or
        		   input.UserInputType == Enum.UserInputType.Touch then
        			floatingDragging = true
        			floatingDragStart = input.Position
        			floatingStartPos = floatingButton.Position

        			input.Changed:Connect(function()
        				if input.UserInputState == Enum.UserInputState.End then
        					floatingDragging = false
        					-- NO SNAP - button stays where dropped
        				end
        			end)
        		end
        	end)

        	floatingClickButton.InputChanged:Connect(function(input)
        		if input.UserInputType == Enum.UserInputType.MouseMovement or
        		   input.UserInputType == Enum.UserInputType.Touch then
        			floatingDragInput = input
        		end
        	end)

        	game:GetService("UserInputService").InputChanged:Connect(function(input)
        		if floatingDragging and input == floatingDragInput then
        			updateFloatingDrag(input)
        		end
        	end)

        	-- Click detection for restore window
        	local clickStartTime = 0
        	local clickStartPos = Vector2.new(0, 0)

        	floatingClickButton.MouseButton1Down:Connect(function()
        		clickStartTime = tick()
        		clickStartPos = Vector2.new(floatingButton.AbsolutePosition.X, floatingButton.AbsolutePosition.Y)
        	end)

        	floatingClickButton.MouseButton1Up:Connect(function()
        		local clickDuration = tick() - clickStartTime
        		local currentPos = Vector2.new(floatingButton.AbsolutePosition.X, floatingButton.AbsolutePosition.Y)
        		local dragDistance = (currentPos - clickStartPos).Magnitude

        		-- Only toggle if it was a quick click (< 0.2s) and minimal drag (< 5 pixels)
        		if clickDuration < 0.2 and dragDistance < 5 then
        			toggleMinimizeCallback()
        		end
        	end)

        	return {
        		Frame = floatingButton
        		-- NO SNAP FUNCTION - free placement enabled
        	}
        end

        function Window:SetupMinimizeToggle(frame, floatingButton, originalPosition)
        	local isMinimized = false

        	local function toggleMinimize()
        		isMinimized = not isMinimized

        		if isMinimized then
        			-- Minimize: hide window and show floating button
        			originalPosition = frame.Position
        			frame.Visible = false

        			-- Show floating button with animation
        			floatingButton.Frame.Visible = true
        			floatingButton.Frame.Size = UDim2.new(0, 0, 0, 80)
        			floatingButton.Frame:TweenSize(
        				UDim2.new(0, 80, 0, 80),
        				Enum.EasingDirection.Out,
        				Enum.EasingStyle.Quad,
        				0.3,
        				true
        				-- NO SNAP - button stays in place
        			)
        		else
        			-- Restore: hide floating button and show window
        			floatingButton.Frame:TweenSize(
        				UDim2.new(0, 0, 0, 80),
        				Enum.EasingDirection.In,
        				Enum.EasingStyle.Quad,
        				0.2,
        				true,
        				function()
        					floatingButton.Frame.Visible = false
        					frame.Visible = true
        					frame.Position = originalPosition
        				end
        			)
        		end
        	end

        	return {
        		Toggle = toggleMinimize,
        		IsMinimized = function() return isMinimized end
        	}
        end

        function Window:CreateResizeHandle(frame, minWidth, minHeight, maxWidth, maxHeight)
        	-- Create resize handle in bottom-right corner
        	local resizeHandle = Instance.new("ImageButton")
        	resizeHandle.Size = UDim2.new(0, 20, 0, 20)
        	resizeHandle.Position = UDim2.new(1, -20, 1, -20)
        	resizeHandle.BackgroundColor3 = Colors.Accent.Primary
        	resizeHandle.BackgroundTransparency = 0.7
        	resizeHandle.BorderSizePixel = 0
            resizeHandle.Image = "rbxassetid://16898613613"
            resizeHandle.ImageRectOffset = Vector2.new(820,196)
        	resizeHandle.ImageRectSize = Vector2.new(48, 48) 
        	resizeHandle.ZIndex = 10
        	resizeHandle.Active = true
        	resizeHandle.Parent = frame

        	-- Corner radius
        	local handleCorner = Instance.new("UICorner")
        	handleCorner.CornerRadius = UDim.new(0, 4)
        	handleCorner.Parent = resizeHandle

        	-- Hover effect
        	resizeHandle.MouseEnter:Connect(function()
        		resizeHandle.BackgroundTransparency = 0.3
        	end)

        	resizeHandle.MouseLeave:Connect(function()
        		resizeHandle.BackgroundTransparency = 0.7
        	end)

        	-- Resize functionality
        	local resizing = false
        	local resizeStart, startSize

        	resizeHandle.InputBegan:Connect(function(input)
        		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
        		   input.UserInputType == Enum.UserInputType.Touch then
        			resizing = true
        			resizeStart = input.Position
        			startSize = frame.AbsoluteSize

        			input.Changed:Connect(function()
        				if input.UserInputState == Enum.UserInputState.End then
        					resizing = false
        				end
        			end)
        		end
        	end)

        	game:GetService("UserInputService").InputChanged:Connect(function(input)
        		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or 
        		   input.UserInputType == Enum.UserInputType.Touch) then
        			local delta = input.Position - resizeStart

        			-- Calculate new size
        			local newWidth = startSize.X + delta.X
        			local newHeight = startSize.Y + delta.Y

        			-- Apply min/max constraints
        			newWidth = math.max(minWidth or 300, newWidth)
        			newHeight = math.max(minHeight or 200, newHeight)

        			if maxWidth then
        				newWidth = math.min(maxWidth, newWidth)
        			end

        			if maxHeight then
        				newHeight = math.min(maxHeight, newHeight)
        			end

        			-- Update frame size
        			frame.Size = UDim2.new(0, newWidth, 0, newHeight)
        		end
        	end)

        	return resizeHandle
        end

        function Window:CreateTabPanelResizer(tabPanel, scrollFrame, minTabWidth, maxTabWidth)
        	-- Create resize handle on right edge of tab panel
        	local resizer = Instance.new("Frame")
        	resizer.Size = UDim2.new(0, 4, 1, 0)
        	resizer.Position = UDim2.new(1, 0, 0, 0)
        	resizer.BackgroundColor3 = Colors.Accent.Primary
        	resizer.BackgroundTransparency = 0.9
        	resizer.BorderSizePixel = 0
        	resizer.ZIndex = 10
        	resizer.Active = true
        	resizer.Parent = tabPanel

        	-- Visual indicator (appears on hover)
        	local indicator = Instance.new("Frame")
        	indicator.Size = UDim2.new(0, 2, 1, 0)
        	indicator.Position = UDim2.new(0, 1, 0, 0)
        	indicator.BackgroundColor3 = Colors.Accent.Primary
        	indicator.BackgroundTransparency = 1
        	indicator.BorderSizePixel = 0
        	indicator.ZIndex = 11
        	indicator.Parent = resizer

        	-- Hover effects
        	resizer.MouseEnter:Connect(function()
        		resizer.BackgroundTransparency = 0.7
        		indicator.BackgroundTransparency = 0
        	end)

        	resizer.MouseLeave:Connect(function()
        		resizer.BackgroundTransparency = 0.9
        		indicator.BackgroundTransparency = 1
        	end)

        	-- Resize functionality
        	local resizing = false
        	local resizeStart, startWidth

        	resizer.InputBegan:Connect(function(input)
        		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
        		   input.UserInputType == Enum.UserInputType.Touch then
        			resizing = true
        			resizeStart = input.Position
        			startWidth = tabPanel.AbsoluteSize.X

        			-- Show indicator while resizing
        			indicator.BackgroundTransparency = 0

        			input.Changed:Connect(function()
        				if input.UserInputState == Enum.UserInputState.End then
        					resizing = false
        					indicator.BackgroundTransparency = 1
        				end
        			end)
        		end
        	end)

        	game:GetService("UserInputService").InputChanged:Connect(function(input)
        		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or 
        		   input.UserInputType == Enum.UserInputType.Touch) then
        			local delta = input.Position - resizeStart

        			-- Calculate new width
        			local newWidth = startWidth + delta.X

        			-- Apply constraints
        			newWidth = math.max(minTabWidth or 80, newWidth)
        			newWidth = math.min(maxTabWidth or 300, newWidth)

        			-- Update tab panel width
        			tabPanel.Size = UDim2.new(0, newWidth, 1, -30)

        			-- Update scroll frame position and size
        			scrollFrame.Position = UDim2.new(0, newWidth, 0, 30)
        			scrollFrame.Size = UDim2.new(1, -newWidth, 1, -30)
        		end
        	end)

        	return resizer
        end

        function Window:Create(config)
        	-- Ensure Colors is initialized with detailed error
        	if not Colors then
        		error("Window:Create() - Colors module is nil. Window:Init() may not have been called or Colors parameter was nil.")
        	end

        	if not Colors.Background then
        		error("Window:Create() - Colors.Background is nil. The Colors module may not have loaded correctly.")
        	end

        	local title = config.Title or "EzUI Window"
        	local width = config.Width
        	local height = config.Height
        	local opacity = config.Opacity or 0.9
        	local autoShow = config.AutoShow ~= nil and config.AutoShow or true
        	local draggable = config.Draggable ~= nil and config.Draggable or true
        	local resizable = config.Resizable ~= nil and config.Resizable or true
        	local tabPanelResizable = config.TabPanelResizable ~= nil and config.TabPanelResizable or true
        	local backgroundColor = config.BackgroundColor or Colors.Background.Secondary
        	local cornerRadius = config.CornerRadius or 8
        	local minWidth = config.MinWidth or 300
        	local minHeight = config.MinHeight or 200
        	local maxWidth = config.MaxWidth
        	local maxHeight = config.MaxHeight
        	local tabPanelWidth = config.TabPanelWidth or 130
        	local minTabPanelWidth = config.MinTabPanelWidth or 80
        	local maxTabPanelWidth = config.MaxTabPanelWidth or 300
        	local settings = config.Settings or {}
        	local autoAdapt = config.AutoAdapt ~= nil and config.AutoAdapt or true

        	-- Close callback functionality
        	local onCloseCallback = config.OnClose or nil

        	opacity = math.max(0.1, math.min(1.0, opacity))

        	local screenGui = Instance.new("ScreenGui")
        	screenGui.Name = title
        	screenGui.ResetOnSpawn = false
        	screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

        	local windowWidth, windowHeight = self:CalculateDynamicSize(width, height)

        	-- SpeedHub X Style Colors with UMBRELLA RED accent
        	local SH_Dark = Color3.fromRGB(30, 28, 32) -- Main dark background (warmer)
        	local SH_DarkAlt = Color3.fromRGB(45, 42, 48) -- Slightly lighter (warmer)
        	local SH_ItemBg = Color3.fromRGB(60, 56, 64) -- Item background (warmer)
        	local SH_Coral = Color3.fromRGB(220, 20, 60) -- UMBRELLA RED accent (changed from coral)
        	local SH_TextLight = Color3.fromRGB(245, 245, 245) -- Light text
        	local SH_TextMuted = Color3.fromRGB(160, 155, 165) -- Muted text

        	-- Main window frame - SEMI-TRANSPARENT (like SpeedHub)
        	local frame = Instance.new("Frame")
        	frame.Size = UDim2.new(0, windowWidth, 0, windowHeight)
        	frame.Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2)
        	frame.BackgroundColor3 = SH_Dark
        	frame.BackgroundTransparency = 0.18 -- MORE TRANSPARENT (can see game behind)
        	frame.BorderSizePixel = 0
        	frame.Active = true
        	frame.ClipsDescendants = true
        	frame.ZIndex = 1
        	frame.Visible = autoShow
        	frame.Parent = screenGui

        	-- Rounded corners - VERY ROUNDED (like Speed Hub X)
        	local frameCorner = Instance.new("UICorner")
        	frameCorner.CornerRadius = UDim.new(0, 32) -- Much rounder for Speed Hub X style (increased from 24 to 32)
        	frameCorner.Parent = frame

        	-- Window shadow (UMBRELLA CORP: Subtle black shadow, rounded corners)
        	local frameShadow = Instance.new("Frame")
        	frameShadow.Size = UDim2.new(1, 8, 1, 8)
        	frameShadow.Position = UDim2.new(0, -4, 0, 4)
        	frameShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        	frameShadow.BackgroundTransparency = 0.7
        	frameShadow.BorderSizePixel = 0
        	frameShadow.ZIndex = frame.ZIndex - 1
        	frameShadow.Parent = frame

        	-- Rounded corners for shadow - match frame corner radius
        	local frameShadowCorner = Instance.new("UICorner")
        	frameShadowCorner.CornerRadius = UDim.new(0, 32)
        	frameShadowCorner.Parent = frameShadow

        	-- Title bar - Slightly transparent
        	local titleBar = Instance.new("Frame")
        	titleBar.Size = UDim2.new(1, 0, 0, 45) -- Taller title bar
        	titleBar.Position = UDim2.new(0, 0, 0, 0)
        	titleBar.BackgroundColor3 = SH_Dark
        	titleBar.BackgroundTransparency = 0.1 -- Slight transparency
        	titleBar.BorderSizePixel = 0
        	titleBar.ZIndex = 2
        	titleBar.Parent = frame

        	-- Title bar NO rounded corners - main frame will clip it naturally at top for seamless connection
        	-- Bottom stays square to merge perfectly with body

        	-- Separator line between title bar and body (like Speed Hub X)
        	local titleSeparator = Instance.new("Frame")
        	titleSeparator.Size = UDim2.new(1, 0, 0, 1) -- 1px height
        	titleSeparator.Position = UDim2.new(0, 0, 1, -1) -- Bottom of title bar
        	titleSeparator.BackgroundColor3 = Color3.fromRGB(60, 60, 70) -- Subtle separator
        	titleSeparator.BackgroundTransparency = 0.3
        	titleSeparator.BorderSizePixel = 0
        	titleSeparator.ZIndex = 3
        	titleSeparator.Parent = titleBar

        	-- Title text - UMBRELLA RED color
        	local titleLabel = Instance.new("TextLabel")
        	titleLabel.Size = UDim2.new(1, -80, 1, 0)
        	titleLabel.Position = UDim2.new(0, 20, 0, 0)
        	titleLabel.BackgroundTransparency = 1
        	titleLabel.Text = title
        	titleLabel.TextColor3 = SH_Coral -- Salmon/coral title
        	titleLabel.TextSize = 17
        	titleLabel.Font = Enum.Font.GothamBold
        	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        	titleLabel.ZIndex = 3
        	titleLabel.Parent = titleBar

        	-- Minimize button (SpeedHub style)
        	local minimizeBtn = Instance.new("TextButton")
        	minimizeBtn.Size = UDim2.new(0, 30, 0, 40)
        	minimizeBtn.Position = UDim2.new(1, -70, 0, 0)
        	minimizeBtn.BackgroundTransparency = 1
        	minimizeBtn.Text = "-"
        	minimizeBtn.TextColor3 = SH_TextMuted
        	minimizeBtn.TextSize = 22
        	minimizeBtn.Font = Enum.Font.GothamBold
        	minimizeBtn.ZIndex = 3
        	minimizeBtn.Parent = titleBar

        	minimizeBtn.MouseEnter:Connect(function()
        		minimizeBtn.TextColor3 = SH_TextLight
        	end)

        	minimizeBtn.MouseLeave:Connect(function()
        		minimizeBtn.TextColor3 = SH_TextMuted
        	end)

        	-- Close button (SpeedHub style)
        	local closeBtn = Instance.new("TextButton")
        	closeBtn.Size = UDim2.new(0, 30, 0, 40)
        	closeBtn.Position = UDim2.new(1, -35, 0, 0)
        	closeBtn.BackgroundTransparency = 1
        	closeBtn.Text = "X"
        	closeBtn.TextColor3 = SH_TextMuted
        	closeBtn.TextSize = 18
        	closeBtn.Font = Enum.Font.GothamBold
        	closeBtn.ZIndex = 3
        	closeBtn.Parent = titleBar

        	closeBtn.MouseEnter:Connect(function()
        		closeBtn.TextColor3 = SH_TextLight
        	end)

        	closeBtn.MouseLeave:Connect(function()
        		closeBtn.TextColor3 = SH_TextMuted
        	end)

        	-- Create confirmation dialog elements (hidden by default)
        	local confirmationOverlay = Instance.new("Frame")
        	confirmationOverlay.Size = UDim2.new(1, 0, 1, 0)
        	confirmationOverlay.Position = UDim2.new(0, 0, 0, 0)
        	confirmationOverlay.BackgroundColor3 = Colors.Special.Overlay
        	confirmationOverlay.BackgroundTransparency = 0.5
        	confirmationOverlay.BorderSizePixel = 0
        	confirmationOverlay.ZIndex = 100
        	confirmationOverlay.Visible = false
        	confirmationOverlay.Parent = frame

        	local confirmationDialog = Instance.new("Frame")
        	confirmationDialog.Size = UDim2.new(0, 300, 0, 130)
        	confirmationDialog.Position = UDim2.new(0.5, -150, 0.5, -65)
        	confirmationDialog.BackgroundColor3 = Colors.Surface.Elevated
        	confirmationDialog.BorderSizePixel = 0
        	confirmationDialog.ZIndex = 101
        	confirmationDialog.Parent = confirmationOverlay

        	local confirmDialogCorner = Instance.new("UICorner")
        	confirmDialogCorner.CornerRadius = UDim.new(0, 14) -- Lebih tumpul/rounded
        	confirmDialogCorner.Parent = confirmationDialog

        	-- Confirmation dialog title
        	local confirmTitle = Instance.new("TextLabel")
        	confirmTitle.Size = UDim2.new(1, -20, 0, 25)
        	confirmTitle.Position = UDim2.new(0, 10, 0, 8)
        	confirmTitle.BackgroundTransparency = 1
        	confirmTitle.Text = "⚠️ Confirm Close"
        	confirmTitle.TextColor3 = Colors.Text.Primary
        	confirmTitle.TextSize = 14
        	confirmTitle.Font = Enum.Font.GothamBold
        	confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
        	confirmTitle.ZIndex = 102
        	confirmTitle.Parent = confirmationDialog

        	-- Confirmation message
        	local confirmMessage = Instance.new("TextLabel")
        	confirmMessage.Size = UDim2.new(1, -20, 0, 35)
        	confirmMessage.Position = UDim2.new(0, 10, 0, 35)
        	confirmMessage.BackgroundTransparency = 1
        	confirmMessage.Text = "Are you sure you want to close?"
        	confirmMessage.TextColor3 = Colors.Text.Secondary
        	confirmMessage.TextSize = 12
        	confirmMessage.Font = Enum.Font.Gotham
        	confirmMessage.TextWrapped = true
        	confirmMessage.TextXAlignment = Enum.TextXAlignment.Left
        	confirmMessage.TextYAlignment = Enum.TextYAlignment.Top
        	confirmMessage.ZIndex = 102
        	confirmMessage.Parent = confirmationDialog

        	-- Button container
        	local buttonContainer = Instance.new("Frame")
        	buttonContainer.Size = UDim2.new(1, -20, 0, 32)
        	buttonContainer.Position = UDim2.new(0, 10, 1, -40)
        	buttonContainer.BackgroundTransparency = 1
        	buttonContainer.ZIndex = 102
        	buttonContainer.Parent = confirmationDialog

        	-- Cancel button
        	local cancelBtn = Instance.new("TextButton")
        	cancelBtn.Size = UDim2.new(0, 130, 0, 32)
        	cancelBtn.Position = UDim2.new(0, 0, 0, 0)
        	cancelBtn.BackgroundColor3 = Colors.Button.Secondary
        	cancelBtn.BorderSizePixel = 0
        	cancelBtn.Text = "Cancel"
        	cancelBtn.TextColor3 = Colors.Text.Primary
        	cancelBtn.TextSize = 13
        	cancelBtn.Font = Enum.Font.GothamBold
        	cancelBtn.ZIndex = 103
        	cancelBtn.Parent = buttonContainer

        	local cancelCorner = Instance.new("UICorner")
        	cancelCorner.CornerRadius = UDim.new(0, 10) -- Lebih tumpul
        	cancelCorner.Parent = cancelBtn

        	-- Confirm button
        	local confirmBtn = Instance.new("TextButton")
        	confirmBtn.Size = UDim2.new(0, 130, 0, 32)
        	confirmBtn.Position = UDim2.new(1, -130, 0, 0)
        	confirmBtn.BackgroundColor3 = Colors.Button.Danger
        	confirmBtn.BorderSizePixel = 0
        	confirmBtn.Text = "Close"
        	confirmBtn.TextColor3 = Colors.Text.Primary
        	confirmBtn.TextSize = 13
        	confirmBtn.Font = Enum.Font.GothamBold
        	confirmBtn.ZIndex = 103
        	confirmBtn.Parent = buttonContainer

        	local confirmCorner = Instance.new("UICorner")
        	confirmCorner.CornerRadius = UDim.new(0, 10) -- Lebih tumpul
        	confirmCorner.Parent = confirmBtn

        	-- Button hover effects
        	cancelBtn.MouseEnter:Connect(function()
        		cancelBtn.BackgroundColor3 = Colors.Button.SecondaryHover
        	end)

        	cancelBtn.MouseLeave:Connect(function()
        		cancelBtn.BackgroundColor3 = Colors.Button.Secondary
        	end)

        	confirmBtn.MouseEnter:Connect(function()
        		confirmBtn.BackgroundColor3 = Colors.Button.DangerHover
        	end)

        	confirmBtn.MouseLeave:Connect(function()
        		confirmBtn.BackgroundColor3 = Colors.Button.Danger
        	end)

        	-- Cancel button action
        	cancelBtn.MouseButton1Click:Connect(function()
        		confirmationOverlay.Visible = false
        	end)

        	-- Confirm button action
        	confirmBtn.MouseButton1Click:Connect(function()
        		confirmationOverlay.Visible = false

        		-- Call user close callback before destroying
        		if onCloseCallback then
        			local success, errorMsg = pcall(function()
        				onCloseCallback()
        			end)

        			if not success then
        				warn("Close callback error:", errorMsg)
        			end
        		end

        		screenGui:Destroy()
        	end)

        	-- Close button shows confirmation dialog
        	closeBtn.MouseButton1Click:Connect(function()
        		confirmationOverlay.Visible = true
        	end)

        	-- Tab panel (left side) - SpeedHub style TRANSPARENT
        	local tabPanel = Instance.new("Frame")
        	tabPanel.Size = UDim2.new(0, tabPanelWidth, 1, -45) -- Adjusted for taller title bar
        	tabPanel.Position = UDim2.new(0, 0, 0, 45)
        	tabPanel.BackgroundColor3 = SH_Dark
        	tabPanel.BackgroundTransparency = 0.15 -- Semi-transparent
        	tabPanel.BorderSizePixel = 0
        	tabPanel.ZIndex = 2
        	tabPanel.Parent = frame

        	-- Tab panel NO rounded corners - main frame will clip it naturally for seamless appearance
        	-- Stays square to merge perfectly with title bar and body

        	-- Tab panel padding
        	local tabPadding = Instance.new("UIPadding")
        	tabPadding.PaddingTop = UDim.new(0, 12)
        	tabPadding.PaddingLeft = UDim.new(0, 12)
        	tabPadding.PaddingRight = UDim.new(0, 8)
        	tabPadding.Parent = tabPanel

        	-- Tab scroll frame
        	local tabScrollFrame = Instance.new("ScrollingFrame")
        	tabScrollFrame.Size = UDim2.new(1, 0, 1, 0)
        	tabScrollFrame.Position = UDim2.new(0, 0, 0, 0)
        	tabScrollFrame.BackgroundTransparency = 1
        	tabScrollFrame.BorderSizePixel = 0
        	tabScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        	tabScrollFrame.ScrollBarThickness = 3
        	tabScrollFrame.ScrollBarImageColor3 = SH_ItemBg
        	tabScrollFrame.ZIndex = 3
        	tabScrollFrame.Parent = tabPanel

        	-- List layout for tabs (more spacing like SpeedHub)
        	local tabListLayout = Instance.new("UIListLayout")
        	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        	tabListLayout.Padding = UDim.new(0, 5) -- Spacing between tabs
        	tabListLayout.Parent = tabScrollFrame

        	-- Content scroll frame - SpeedHub style TRANSPARENT
        	local scrollFrame = Instance.new("ScrollingFrame")
        	scrollFrame.Size = UDim2.new(1, -tabPanelWidth, 1, -45) -- Adjusted for taller title bar
        	scrollFrame.Position = UDim2.new(0, tabPanelWidth, 0, 45)
        	scrollFrame.BackgroundColor3 = SH_DarkAlt
        	scrollFrame.BackgroundTransparency = 0.12 -- Semi-transparent content area
        	scrollFrame.BorderSizePixel = 0
        	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        	scrollFrame.ScrollBarThickness = 5
        	scrollFrame.ScrollBarImageColor3 = SH_ItemBg
        	scrollFrame.ClipsDescendants = true
        	scrollFrame.ZIndex = 2
        	scrollFrame.Parent = frame

        	-- ScrollFrame NO rounded corners - main frame will clip it naturally for seamless appearance
        	-- Stays square to merge perfectly with title bar and tab panel

        	-- Function to update canvas size (USING OLD UI.LUA LOGIC - Line ~692)
        	local updateCanvasSize  -- Forward declaration

        	updateCanvasSize = function()
        		-- Calculate actual content height for the active tab only
        		local maxY = 10

        		-- Find the currently visible tab content frame
        		local activeTabContent = nil
        		for _, child in ipairs(scrollFrame:GetChildren()) do
        			if child:IsA("Frame") and child.Visible then
        				activeTabContent = child
        				break
        			end
        		end

        		if activeTabContent then
        			-- Calculate content height within the active tab
        			for _, child in ipairs(activeTabContent:GetChildren()) do
        				if child:IsA("GuiObject") and child.Visible then
        					local childY = child.Position.Y.Offset
        					local childHeight = child.AbsoluteSize.Y
        					local childBottom = childY + childHeight

        					if childBottom > maxY then
        						maxY = childBottom
        					end
        				end
        			end
        		end

        		-- Set canvas size with padding
        		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, maxY + 20)
        	end

        	-- Dragging functionality
        	if draggable then
        		local dragging = false
        		local dragInput, dragStart, startPos

        		local function update(input)
        			local delta = input.Position - dragStart
        			frame.Position = UDim2.new(
        				startPos.X.Scale,
        				startPos.X.Offset + delta.X,
        				startPos.Y.Scale,
        				startPos.Y.Offset + delta.Y
        			)
        		end

        		titleBar.InputBegan:Connect(function(input)
        			if input.UserInputType == Enum.UserInputType.MouseButton1 or 
        			   input.UserInputType == Enum.UserInputType.Touch then
        				dragging = true
        				dragStart = input.Position
        				startPos = frame.Position

        				input.Changed:Connect(function()
        					if input.UserInputState == Enum.UserInputState.End then
        						dragging = false
        					end
        				end)
        			end
        		end)

        		titleBar.InputChanged:Connect(function(input)
        			if input.UserInputType == Enum.UserInputType.MouseMovement or
        			   input.UserInputType == Enum.UserInputType.Touch then
        				dragInput = input
        			end
        		end)

        		game:GetService("UserInputService").InputChanged:Connect(function(input)
        			if dragging and input == dragInput then
        				update(input)
        			end
        		end)
        	end

        	-- Resize functionality
        	local resizeHandle = nil
        	if resizable then
        		resizeHandle = self:CreateResizeHandle(frame, minWidth, minHeight, maxWidth, maxHeight)
        	end

        	-- Tab panel resize functionality
        	local tabPanelResizer = nil
        	if tabPanelResizable then
        		tabPanelResizer = self:CreateTabPanelResizer(tabPanel, scrollFrame, minTabPanelWidth, maxTabPanelWidth)
        	end

        	-- Monitor frame size changes and update canvas
        	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        		-- Update canvas size when window is resized
        		task.spawn(updateCanvasSize)
        	end)

        	-- Tab management
        	local tabs = {}
        	local tabContents = {}
        	local currentTab = nil
        	local tabCount = 0
        	local originalHeight = windowHeight
        	local originalPosition = frame.Position

        	-- Setup minimize/restore functionality (create control first)
        	local minimizeControl = {
        		Toggle = nil,
        		IsMinimized = nil
        	}

        	-- Create floating button with toggle callback
        	local floatingButton = self:CreateFloatingButton(screenGui, frame, function()
        		if minimizeControl.Toggle then
        			minimizeControl.Toggle()
        		end
        	end, autoShow)

        	-- Now create the actual minimize control
        	local actualMinimizeControl = self:SetupMinimizeToggle(frame, floatingButton, originalPosition)
        	minimizeControl.Toggle = actualMinimizeControl.Toggle
        	minimizeControl.IsMinimized = actualMinimizeControl.IsMinimized

        	-- Connect minimize button
        	minimizeBtn.MouseButton1Click:Connect(minimizeControl.Toggle)

        	-- Keyboard shortcut for toggle minimize (Ctrl + M or Ctrl + H)
        	local UserInputService = game:GetService("UserInputService")
        	UserInputService.InputBegan:Connect(function(input, gameProcessed)
        		-- Don't trigger if user is typing in a text box
        		if gameProcessed then return end

        		-- Check for Ctrl + M or Ctrl + H
        		if input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.H then
        			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or 
        			   UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
        				minimizeControl.Toggle()
        			end
        		end
        	end)

        	-- Initialize Notification component
        	if Notification then
        		Notification:Init(Colors)
        	end

        	-- Window API
        	local windowAPI = {
        		ScreenGui = screenGui,
        		Frame = frame,
        		TitleBar = titleBar,
        		TabScrollFrame = tabScrollFrame,
        		ScrollFrame = scrollFrame,
        		TabPanel = tabPanel,
        		FloatingButton = floatingButton.Frame,
        		ResizeHandle = resizeHandle,
        		TabPanelResizer = tabPanelResizer,
        		UpdateCanvasSize = updateCanvasSize,  -- Expose update function for accordion callbacks
        		Notification = Notification, -- Expose notification component
        	}

        	function windowAPI:Show()
        		-- Show the window
        		frame.Visible = true
        		-- Hide the floating button when window is shown
        		floatingButton.Frame.Visible = false
        		-- If window was minimized, restore it
        		if minimizeControl.IsMinimized() then
        			minimizeControl.Toggle()
        		end
        	end

        	function windowAPI:Hide()
        		-- Hide the window
        		frame.Visible = false
        		-- Show the floating button when window is hidden
        		floatingButton.Frame.Visible = true
        	end

        	function windowAPI:IsVisible()
        		-- Check if the window is currently visible (not minimized)
        		return frame.Visible and not minimizeControl.IsMinimized()
        	end

        	function windowAPI:ToggleVisibility()
        		-- Toggle window visibility
        		if self:IsVisible() then
        			self:Hide()
        		else
        			self:Show()
        		end
        		return self:IsVisible()
        	end

        	function windowAPI:Toggle()
        		return self:ToggleVisibility()
        	end

        	function windowAPI:Minimize()
        		if not minimizeControl.IsMinimized() then
        			minimizeControl.Toggle()
        		end
        	end

        	function windowAPI:Restore()
        		if minimizeControl.IsMinimized() then
        			minimizeControl.Toggle()
        		end
        	end

        	function windowAPI:ToggleMinimize()
        		minimizeControl.Toggle()
        	end

        	function windowAPI:IsMinimized()
        		return minimizeControl.IsMinimized()
        	end

        	function windowAPI:Destroy()
        		screenGui:Destroy()
        	end

        	function windowAPI:SetTitle(newTitle)
        		titleLabel.Text = newTitle
        		title = newTitle
        	end

        	function windowAPI:SetSize(newWidth, newHeight)
        		windowWidth = newWidth
        		originalHeight = newHeight
        		frame.Size = UDim2.new(0, newWidth, 0, newHeight)
        	end

        	function windowAPI:SetPosition(x, y)
        		frame.Position = UDim2.new(0, x, 0, y)
        	end

        	function windowAPI:Center()
        		local viewportSize = Window:GetViewportSize()
        		local size = frame.AbsoluteSize
        		frame.Position = UDim2.new(
        			0, (viewportSize.X - size.X) / 2,
        			0, (viewportSize.Y - size.Y) / 2
        		)
        	end

        	function windowAPI:SetResizable(enabled)
        		if resizeHandle then
        			resizeHandle.Visible = enabled
        		end
        	end

        	function windowAPI:GetSize()
        		return frame.AbsoluteSize
        	end

        	function windowAPI:SetTabPanelWidth(newWidth)
        		newWidth = math.max(minTabPanelWidth, math.min(maxTabPanelWidth, newWidth))
        		tabPanel.Size = UDim2.new(0, newWidth, 1, -30)
        		scrollFrame.Position = UDim2.new(0, newWidth, 0, 30)
        		scrollFrame.Size = UDim2.new(1, -newWidth, 1, -30)
        	end

        	function windowAPI:GetTabPanelWidth()
        		return tabPanel.AbsoluteSize.X
        	end

        	function windowAPI:SetTabPanelResizable(enabled)
        		if tabPanelResizer then
        			tabPanelResizer.Visible = enabled
        		end
        	end

        	function windowAPI:GetTabs()
        		return tabs
        	end

        	function windowAPI:GetCurrentTab()
        		return currentTab
        	end

        	function windowAPI:SelectTab(index)
        		if tabs[index] then
        			if currentTab then
        				currentTab:Deselect()
        			end
        			currentTab = tabs[index]
        			currentTab:Select()
        		end
        	end

        	function windowAPI:AddTab(config)
        		-- Handle string shortcut
        		if type(config) == "string" then
        			config = {Name = config}
        		end

        		-- Validate config
        		if type(config) ~= "table" then
        			warn("EzUI Window.AddTab: config must be a string or table")
        			return nil
        		end

        		local tabName = config.Name or "Tab " .. (tabCount + 1)
        		local icon = config.Icon or ""

        		-- Create the tab using Tab component
        		local tabConfig = {
        			Name = tabName,
        			Icon = icon,
        			TabScrollFrame = tabScrollFrame,
        			TabContents = tabContents,
        			ScrollFrame = scrollFrame,
        			ScreenGui = screenGui,
        			WindowAPI = windowAPI,  -- Pass window API reference for accordion canvas updates
        			UpdateCanvasSize = updateCanvasSize,  -- Pass canvas update function
        			Settings = settings  -- Optional settings for the tab
        		}

        		local tabAPI = Tab:Create(tabConfig)

        		if not tabAPI then
        			warn("EzUI Window.AddTab: Failed to create tab")
        			return nil
        		end

        		-- Add click handler to switch tabs
        		tabAPI.Button.MouseButton1Click:Connect(function()
        			if currentTab and currentTab ~= tabAPI then
        				currentTab:Deselect()
        			end
        			currentTab = tabAPI
        			tabAPI:Select()
        		end)

        		-- Store tab reference
        		tabCount = tabCount + 1
        		tabs[tabCount] = tabAPI

        		-- Auto-select first tab
        		if tabCount == 1 then
        			currentTab = tabAPI
        			tabAPI:Select()
        		end

        		-- Update tab scroll canvas size
        		tabScrollFrame.CanvasSize = UDim2.new(0, 0, 0, tabListLayout.AbsoluteContentSize.Y)

        		return tabAPI
        	end

        	-- Notification methods
        	function windowAPI:ShowNotification(config)
        		if not Notification then
        			warn("Notification component not initialized")
        			return nil
        		end
        		config = config or {}
        		config.ScreenGui = screenGui
        		return Notification:Create(config)
        	end

        	function windowAPI:ShowSuccess(title, message, duration, action)
        		return self:ShowNotification({
        			Type = "success",
        			Title = title,
        			Message = message,
        			Duration = duration,
        			Action = action
        		})
        	end

        	function windowAPI:ShowWarning(title, message, duration, action)
        		return self:ShowNotification({
        			Type = "warning",
        			Title = title,
        			Message = message,
        			Duration = duration,
        			Action = action
        		})
        	end

        	function windowAPI:ShowError(title, message, duration, action)
        		return self:ShowNotification({
        			Type = "error",
        			Title = title,
        			Message = message,
        			Duration = duration,
        			Action = action
        		})
        	end

        	function windowAPI:ShowInfo(title, message, duration, action)
        		return self:ShowNotification({
        			Type = "info",
        			Title = title,
        			Message = message,
        			Duration = duration,
        			Action = action
        		})
        	end

        	function windowAPI:DismissNotification(id)
        		if Notification then
        			Notification:Dismiss(id)
        		end
        	end

        	function windowAPI:ClearNotifications()
        		if Notification then
        			Notification:Clear()
        		end
        	end

        	function windowAPI:GetConfigValue(key)
        		return settings:GetValue(key)
        	end

        	function windowAPI:SetConfigValue(key, value)
        		settings:SetValue(key, value)
        	end

        	function windowAPI:GetAllConfigKeys()
        		return settings:GetAllKeys()
        	end

        	function windowAPI:DeleteConfigKey(key)
        		return settings:DeleteKey(key)
        	end

        	-- Viewport adaptation methods
        	function windowAPI:AdaptToViewport()
        		-- Recalculate window size based on current viewport
        		local currentViewport = self:GetViewportSize()
        		local baseWidth = config.Width or (currentViewport.X * 0.3)
        		local baseHeight = config.Height or (currentViewport.Y * 0.4)

        		-- Apply resolution-based scaling
        		local scaleMultiplier = 1
        		if currentViewport.X >= 1920 then -- 1080p+
        			scaleMultiplier = 1.2
        		elseif currentViewport.X >= 1366 then -- 720p-1080p
        			scaleMultiplier = 1.0
        		elseif currentViewport.X >= 1024 then -- Tablet size
        			scaleMultiplier = 0.9
        		else -- Mobile/small screens
        			scaleMultiplier = 0.8
        		end

        		-- Calculate new size with limits
        		local newWidth = math.max(250, math.min(currentViewport.X * 0.8, baseWidth * scaleMultiplier))
        		local newHeight = math.max(150, math.min(currentViewport.Y * 0.8, baseHeight * scaleMultiplier))

        		-- Apply new size and center the window
        		frame.Size = UDim2.new(0, newWidth, 0, newHeight)
        		frame.Position = UDim2.new(0.5, -newWidth / 2, 0.5, -newHeight / 2)
        	end

        	function windowAPI:GetDynamicSize()
        		local currentViewport = self:GetViewportSize()
        		return {
        			Width = frame.Size.X.Offset,
        			Height = frame.Size.Y.Offset,
        			ViewportWidth = currentViewport.X,
        			ViewportHeight = currentViewport.Y
        		}
        	end

        	function windowAPI:SetSize(width, height)
        		local viewportSize = self:GetViewportSize()

        		-- Apply constraints
        		width = math.max(300, math.min(width, viewportSize.X * 0.9))
        		height = math.max(200, math.min(height, viewportSize.Y * 0.9))

        		frame.Size = UDim2.new(0, width, 0, height)

        		return {Width = width, Height = height}
        	end

        	-- Close callback functionality
        	function windowAPI:SetCloseCallback(callback)
        		onCloseCallback = callback
        	end

        	function windowAPI:Close()
        		-- Call user callback before destroying
        		if onCloseCallback then
        			local success, errorMsg = pcall(function()
        				onCloseCallback()
        			end)

        			if not success then
        				warn("Close callback error:", errorMsg)
        			end
        		end

        		-- Destroy the UI
        		if screenGui then
        			screenGui:Destroy()
        		end
        	end

        	-- Auto-adapt to viewport changes (optional)
        	if autoAdapt then
        		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        			task.wait(0.1) -- Small delay to ensure viewport is stable
        			windowAPI:AdaptToViewport()
        		end)
        	end

        	return windowAPI
        end

        return Window

    end

    -- Load module helper function
    local function loadModule(url)
        -- Try embedded module first
        if EmbeddedModules[url] then
            return EmbeddedModules[url]()
        end

        -- Fallback to original require
        return require(url)
    end

    -- Main Script
    --[[
    	EzUI - Easy Roblox UI Library
    	Main Entry Point

    	A modern, modular UI library for Roblox with:
    	- Centralized color palette system
    	- Configuration management with auto-save/load
    	- 10+ UI components
    	- Tab system with icons
    	- Window management with drag & resize

    	Usage:
    		local EzUI = require(game.ReplicatedStorage.main)

    		local window = EzUI.({
    			Name = "My UI",
    			Size = {Width = 500, Height = 400}
    		})

    		local tab = window:AddTab("Home")
    		tab:AddButton("Click Me", function()
    			print("Button clicked!")
    		end)
    ]]

    local EzUI = {}

    -- Import utility modules
    local ColorsModule = loadModule("utils/colors")
    local ConfigModule = loadModule("utils/config")

    -- Debug: Verify Colors loaded
    if ColorsModule then
    	print("✅ Colors module loaded successfully")
    	if ColorsModule.Background then
    		print("✅ Colors.Background exists")
    	else
    		warn("❌ Colors.Background is nil!")
    	end
    else
    	warn("❌ Colors module is nil!")
    end

    -- Import components
    local Accordion = loadModule("components/accordion")
    local Button = loadModule("components/button")
    local Label = loadModule("components/label")
    local NumberBox = loadModule("components/numberbox")
    local Notification = loadModule("components/notification")
    local SelectBox = loadModule("components/selectbox")
    local Separator = loadModule("components/separator")
    local Tab = loadModule("components/tab")
    local TextBox = loadModule("components/textbox")
    local Toggle = loadModule("components/toggle")
    local Window = loadModule("components/window")

    -- Custom Configuration System
    function EzUI:NewConfig(config)
    	return ConfigModule:NewConfig(config)
    end

    -- Initialize Components
    print("🔧 Initializing components...")
    Accordion:Init(ColorsModule, Button, Toggle, TextBox, NumberBox, SelectBox, Label, Separator)
    Button:Init(ColorsModule)
    Label:Init(ColorsModule)
    NumberBox:Init(ColorsModule)
    SelectBox:Init(ColorsModule)
    Separator:Init(ColorsModule)
    Tab:Init(ColorsModule, Accordion, Button, Toggle, TextBox, NumberBox, SelectBox, Label, Separator)
    TextBox:Init(ColorsModule)
    Toggle:Init(ColorsModule)
    Window:Init(ColorsModule, Accordion, Button, Label, NumberBox, Notification, SelectBox, Separator, Tab, TextBox, Toggle)
    print("✅ All components initialized")

    -- Main Window Creation Function
    function EzUI:CreateNew(config)
    	if not config or type(config) ~= "table" then
    		config = {}
    		warn("EzUI:CreateNew - Config table is required, using defaults")
    	end

    	print("🪟 Creating window...")

    	-- Pass all required modules and config to Window component
    	local windowSetup = {
    		Title = config.Title or config.Name or "EzUI Window",
    		Width = config.Width or (config.Size and config.Size.Width) or 600,
    		Height = config.Height or (config.Size and config.Size.Height) or 400,
    		Opacity = config.Opacity or 0.9,
    		AutoShow = config.AutoShow or true,
    		AutoAdapt = config.AutoAdapt or true,
    		Draggable = config.Draggable,
    		BackgroundColor = config.BackgroundColor,
    		CornerRadius = config.CornerRadius,
    	}

    	-- Create config system
    	local configSystem = ConfigModule:NewConfig({
    		FolderName = config.FolderName or "EzUI",
    		FileName = config.FileName or "Settings",
    	})

    	configSystem:Load()

    	local allKeys = configSystem:GetAllKeys()
    	print("EzUI:CreateNew - Loaded config keys:", table.concat(allKeys, ", "))

    	-- Store config in EzUI for global access
    	windowSetup.Settings = configSystem

    	return Window:Create(windowSetup)
    end

    -- Expose version info
    EzUI.Version = "2.0.0"
    EzUI.Author = "EzUI Library"

    return EzUI
end

-- Module: quest/ascension.lua
EmbeddedModules["quest/ascension.lua"] = function()
    local m = {}

    local Window
    local Core
    local Plant
    local Player

    local DataService
    local RebirthConfigData
    local RebirthShared
    local MutationHandler

    function m:Init(_window, _core, _plant, _player)
        Window = _window
        Core = _core
        Plant = _plant
        Player = _player

        DataService = require(Core.ReplicatedStorage.Modules.DataService)
        RebirthConfigData = require(Core.ReplicatedStorage.Data.RebirthConfigData)
        RebirthShared = require(Core.ReplicatedStorage.Modules.RebirthShared)
        MutationHandler = require(Core.ReplicatedStorage.Modules.MutationHandler)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoAscend")
        end, function()
            self:AutoSubmitQuest()
        end)
    end

    function m:GetQuestDetail()
        local result = {
            Name = "",
            Amount = 0,
            Mutations = "",
            IsEligibleToSubmit = false,
            NextRebirthSubmitTime = 0
        }

        local rebirthData = DataService:GetData().RebirthData
        if not rebirthData then
            warn("Rebirth data not found")
            return result
        end

        result.NextRebirthSubmitTime = rebirthData.LastRebirthTime + RebirthConfigData.RESET_TIME - math.floor(workspace:GetServerTimeNow()) or 0
        result.IsEligibleToSubmit = result.NextRebirthSubmitTime <= 0

        if not rebirthData.RequiredPlants then
            return result
        end

        local mutationData = MutationHandler:GetMutations()
        for _, rebirthInfo in pairs(rebirthData.RequiredPlants) do
            result.Name = rebirthInfo.Name
            if rebirthInfo.Name then
                result.Amount = 1
            end

            for mutationName, mutationDetail in pairs(rebirthInfo.Mutations) do
                if mutationName ~= #rebirthInfo.Mutations then
                    continue
                end

                result.Mutations = mutationData[mutationName] or ""
                break
            end
        end

        return result
    end

    function m:IsQuestFruit(_fruit)
        local isEligible = false

        if not _fruit:IsA("Tool") then
            return isEligible
        end

        if _fruit:GetAttribute("b") ~= "j" then
            return isEligible
        end

        local quest = self:GetQuestDetail()
        if not quest then
            return isEligible
        end

        if _fruit:GetAttribute("f") ~= quest.Name then
            return isEligible
        end

        if not quest.Mutations or quest.Mutations == "" or quest.Mutations == "N/A" then
            return true
        end

        for attributeName, attributeValue in pairs(_fruit:GetAttributes()) do
            if attributeValue == true and attributeName == quest.Mutations then
                isEligible = true
                break
            end
        end

        return isEligible
    end

    function m:GetAllOwnedFruitsQuest()
        local myFruits = {}

        for _, fruit in pairs(Core:GetBackpack():GetChildren()) do
            if self:IsQuestFruit(fruit) then
                table.insert(myFruits, fruit)
            end
        end

        return myFruits
    end

    function m:SubmitRebirth(fruit)
        local quest = self:GetQuestDetail()
        if not quest or not quest.IsEligibleToSubmit then
            task.wait(quest.NextRebirthSubmitTime - tick() + 1)
        end

        local rebirthTask = function()
            local vulnCount = Window:GetConfigValue("AscensionVulnCountSubmit") or 100
            for i=1, vulnCount do
                coroutine.wrap(function()
                    Core.ReplicatedStorage.GameEvents.BuyRebirth:FireServer()
                end)()
            end

            wait(1)
        end

        Player:AddToQueue(fruit, 10, function()
            rebirthTask()
        end)
    end

    function m:AutoSubmitQuest()
        if not Window:GetConfigValue("AutoAscend") then
            return
        end

        local quest = self:GetQuestDetail()
        if not quest then
            Window:ShowWarning("Ascension", "Failed to retrieve ascension quest detail.")
            return
        end

        local questName = quest.Name or "N/A"
        local questAmount = quest.Amount or 0
        local questMutations = quest.Mutations or "N/A"

        if quest.NextRebirthSubmitTime > 0 then
            Window:ShowInfo("Ascension", "Next rebirth available in " .. Core:FormatTime(quest.NextRebirthSubmitTime))
            task.wait(quest.NextRebirthSubmitTime + 1)
            return
        end

        if questAmount <= 0 or questName == "N/A" or questName == "" then
            Window:ShowInfo("Ascension", "No ascension quest available, attempting to rebirth directly.")
            local vulnCount = Window:GetConfigValue("AscensionVulnCountSubmit") or 100
            for i=1, vulnCount do
                coroutine.wrap(function()
                    Core.ReplicatedStorage.GameEvents.BuyRebirth:FireServer()
                end)()
            end
            return
        end

        local ownedFruits = self:GetAllOwnedFruitsQuest()
        if ownedFruits and #ownedFruits >= questAmount then
            Window:ShowInfo("Ascension", string.format("Found %d fruits in backpack, submitting rebirth", #ownedFruits))
            self:SubmitRebirth(ownedFruits[1])
            return
        end

        local plants = Plant:FindPlants(questName) or {}
        if not plants or #plants < questAmount then
            local plantingPosition = Window:GetConfigValue("PlantingAscensionPosition") or "Random"
            local needToPlant = questAmount - #plants

            Window:ShowInfo("Ascension", string.format("Planting seeds for quest: %s x%d", questName, needToPlant))
            Plant:PlantSeed(questName, needToPlant, plantingPosition)
            return
        end

        local plantToHarvest = {}
        for _, plant in pairs(plants) do
            if #plantToHarvest >= questAmount then
                break
            end
            if plant.Name ~= questName then
                continue
            end

            local plantDetail = Plant:GetPlantDetail(plant)
            if not plantDetail or #plantDetail.fruits == 0 then
                continue
            end

            for _, fruit in pairs(plantDetail.fruits) do
                if not fruit.isEligibleToHarvest then
                    continue
                end

                if not questMutations or questMutations == "" or questMutations == "N/A" then
                    table.insert(plantToHarvest, fruit.model)
                    break
                end

                for _, mutation in pairs(fruit.mutations) do
                    if mutation == questMutations then
                        table.insert(plantToHarvest, fruit.model)
                        break
                    end
                end
            end
        end

        if not plantToHarvest or #plantToHarvest == 0 then
            Window:ShowWarning("Ascension", string.format("No eligible fruits to harvest: %s", questName))
            return
        end

        -- Harvesting fruits
        local harvestedCount = 0
        Window:ShowInfo("Ascension", string.format("Harvesting fruits for quest: %s x%d", questName, questAmount))
        for _, fruit in pairs(plantToHarvest) do
            if harvestedCount >= questAmount then
                break
            end

            local success = Plant:HarvestFruit(fruit)
            if success then
                harvestedCount = harvestedCount + 1
                Window:ShowInfo("Ascension", string.format("Harvested: %s (%d/%d)", questName, harvestedCount, questAmount))
                task.wait(0.15)
            end
        end
    end

    return m
end

-- Module: quest/season_pass.lua
EmbeddedModules["quest/season_pass.lua"] = function()
    local m ={}

    local Window
    local Core
    local DataService
    local QuestsController
    local SeasonPassData
    local SeasonPassStaticData
    local SeasonPassUtils

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        DataService = require(Core.ReplicatedStorage.Modules.DataService)
        QuestsController = require(Core.ReplicatedStorage.Modules.QuestsController)
        SeasonPassData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassData)
        SeasonPassStaticData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassStaticData)
        SeasonPassUtils = require(Core.ReplicatedStorage.Modules.SeasonPass.SeasonPassUtils)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoClaimSeasonPassQuest")
        end, function()
            self:StartAutoClaimCompletedQuests()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoClaimSeasonPassInfinityRewards")
        end, function()
            self:StartAutoClaimRewards()
        end)
    end

    function m:GetCompletedQuests()
        local questData = DataService:GetData()
        local questDetails = QuestsController:GetContainerFromId(questData.DailyQuests.ContainerId)
        if not questData then
            warn("No quest data found")
            return {}
        end

        if not questDetails then
            warn("No quest details found for container ID:", questData.DailyQuests.ContainerId)
            return {}
        end

        local completedQuests = {}
        for _, quest in pairs(questDetails.Quests) do
            local isClaimed = table.find(questData.SeasonPass[SeasonPassData.CurrentSeason].QuestsClaimed, quest.Id) and true or false

            if quest.Completed == true and not isClaimed then
                table.insert(completedQuests, quest.Id)
            end
        end

        return completedQuests
    end

    function m:StartAutoClaimCompletedQuests()
        if not Window:GetConfigValue("AutoClaimSeasonPassQuest") then
            return
        end

        for i, questId in ipairs(self:GetCompletedQuests()) do
            game:GetService("ReplicatedStorage").GameEvents.SeasonPass.ClaimSeasonPassQuest:FireServer(questId)
            task.wait(0.15) -- Wait for 0.15 seconds between claims to avoid spamming
        end
    end

    function m:StartAutoClaimRewards()
        if not Window:GetConfigValue("AutoClaimSeasonPassInfinityRewards") then
            return
        end

        local rewardData = DataService:GetData()
        local currentSeasonPassData = rewardData.SeasonPass[SeasonPassData.CurrentSeason]
        local totalXP = currentSeasonPassData.TotalExperience
        local infRewardsClaimed = currentSeasonPassData.InfRewardsClaimed
        -- local maxXP = SeasonPassStaticData.INF_REWARD_XP

        local currentXP = totalXP - SeasonPassUtils.CalculateXPForLevel(SeasonPassStaticData.MAX_LEVEL)
        local claimRewardCount = SeasonPassUtils.CalculateInfClaimCount(totalXP, infRewardsClaimed)

        if claimRewardCount <= 0 then
            return
        end

        for i = 1, claimRewardCount do
            game:GetService("ReplicatedStorage").GameEvents.SeasonPass.ClaimSeasonPassInfReward:FireServer(51, false)
            task.wait(0.15) -- Wait for 0.15 seconds between claims to avoid spamming
        end
    end

    return m
end

-- Module: quest/ui.lua
EmbeddedModules["quest/ui.lua"] = function()
    local m = {}
    local Window
    local Core
    local Ascension

    -- Store ALL numberbox references for config sync after reconnect
    m.NumberBoxReferences = {}

    function m:Init(_window, _core, _ascension)
        Window = _window
        Core = _core
        Ascension = _ascension

        AscensionItem = Ascension:GetQuestDetail()
        self:CreateQuestTab()
    end

    function m:CreateQuestTab()
        local tab = Window:AddTab({
            Name = "Quests",
            Icon = "📜",
        })

        self:AscensionSection(tab)
        self:SeasonPassSection(tab)
    end

    function m:AscensionSection(tab)
        local accordion = tab:AddAccordion({
            Name = "Ascension",
            Icon = "🔃",
            Expanded = false,
        })

        -- Current Quest Label
        accordion:AddLabel(function()
            local success, result = pcall(function()
                if AscensionItem then
                    local mutation = AscensionItem.Mutations ~= "" and AscensionItem.Mutations or "No Mutation"
                    return string.format("Current Quest: %d %s (%s)", AscensionItem.Amount or 0, AscensionItem.Name or "Unknown", mutation)
                end
                return "Current Quest: N/A"
            end)
            return success and result or "Error loading quest info"
        end)

        -- Next Rebirth Label
        accordion:AddLabel(function()
            local success, result = pcall(function()
                local ascensionItem = Ascension:GetQuestDetail()
                if ascensionItem and ascensionItem.NextRebirthSubmitTime then
                    if ascensionItem.IsEligibleToSubmit then
                        return "Next Rebirth: Ready to Submit!"
                    else
                        local formattedTime = Core:FormatTime(ascensionItem.NextRebirthSubmitTime)
                        return string.format("Next Rebirth: %s", formattedTime)
                    end
                end
                return "Next Rebirth: N/A"
            end)
            return success and result or "Error loading rebirth info"
        end)

        accordion:AddSelectBox({
            Name = "Position planting seeds",
            Flag = "PlantingAscensionPosition",
            Options = {"Random", "Front Right", "Front Left", "Back Right", "Back Left"},
            Default = "Random",
            MultiSelect = false,
            Placeholder = "Select position...",
        })

        local ascensionVulnCountSubmitNumberBox = accordion:AddNumberBox({
            Name = "Vuln Count Submit",
            Flag = "AscensionVulnCountSubmit",
            Default = 100,
            Min = 1,
            Max = 100000,
            Increment = 1,
        })


        m.NumberBoxReferences["AscensionVulnCountSubmit"] = ascensionVulnCountSubmitNumberBox

        accordion:AddToggle({
            Name = "Auto Ascend",
            Default = false,
            Flag = "AutoAscend",
            Tooltip = "Automatically ascend when the option is available.",
        })
    end

    function m:SeasonPassSection(tab)
        local accordion = tab:AddAccordion({
            Name = "Season Pass",
            Icon = "🎟️",
            Expanded = false,
        })

        accordion:AddToggle({
            Name = "Auto Claim Infinity Rewards",
            Default = false,
            Flag = "AutoClaimSeasonPassInfinityRewards",
            Tooltip = "Automatically claim season pass infinity rewards.",
        })

        accordion:AddToggle({
            Name = "Auto Claim Completed Quests",
            Default = false,
            Flag = "AutoClaimSeasonPassQuest",
            Tooltip = "Automatically claim completed season pass quests.",
        })
    end

    -- Function to refresh all numberbox UI states from config
    function m:RefreshNumberBoxStates()
        if not Window then
            warn("QuestUI:RefreshNumberBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, numberBoxAPI in pairs(self.NumberBoxReferences) do
            local success, err = pcall(function()
                if numberBoxAPI and numberBoxAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        numberBoxAPI:SetValue(configValue)
                        print(string.format("  ✓ [Quest] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Quest] %s - NumberBox API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Quest] %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("[QUEST] Refreshed %d numberboxes successfully", refreshedCount))
        return refreshedCount
    end

    return m
end

-- Module: shop/seed.lua
EmbeddedModules["shop/seed.lua"] = function()
    local m = {}

    local Window
    local Core

    local ShopData
    local DataService
    local DailyDealsData

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        DataService = require(Core.ReplicatedStorage.Modules.DataService)
        ShopData = require(Core.ReplicatedStorage.Data.SeedShopData)
        DailyDealsData = require(Core.ReplicatedStorage.Data.DailySeedShopData)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuySeeds")
        end, function()
            self:StartAutoBuySeeds()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuyDailyDeals")
        end, function()
            self:StartAutoBuyDailyDeals()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuySeedsTier2")
        end, function()
            self:StartAutoBuySeedsTier2()
        end)
    end

    function m:GetItemRepositoryTier1()
        local shopdata = ShopData or {}
        local tier1Items = {}

        for itemName, itemInfo in pairs(shopdata) do
            if not itemInfo.SpecialCurrencyType then
                tier1Items[itemName] = itemInfo
            end
        end

        return tier1Items
    end

    function m:GetItemRepositoryTier2()
        local shopdata = ShopData or {}
        local tier2Items = {}

        for itemName, itemInfo in pairs(shopdata) do
            if itemInfo.SpecialCurrencyType == "GardenCoins" then
                tier2Items[itemName] = itemInfo
            end
        end

        return tier2Items
    end

    function m:GetItemRepositoryDailyDeals()
        return DailyDealsData or {}
    end

    local function resolveSeedStockKey(shopName)

        if shopName == "Tier1" or shopName == "Tier2" then

            return "Shop"
        elseif shopName == "Daily Deals" then

            return "Daily Deals"
        end

        return shopName
    end

    function m:GetStock(shopName, itemName)
        local shopData = DataService:GetData()
        if not shopData or not shopData.SeedStocks then
            return 0
        end

        local internalShopKey = resolveSeedStockKey(shopName)
        local shopEntry = shopData.SeedStocks[internalShopKey]
        if not shopEntry or not shopEntry.Stocks then
            return 0
        end

        local stock = shopEntry.Stocks[itemName]
        if not stock then
            return 0
        end

        if type(stock) == "number" then
            return stock
        end

        if type(stock) == "table" then
            return stock.Stock or 0
        end

        return 0
    end

    function m:GetAvailableItems(shopName)
        local availableItems = {}
        local items = {}

        if shopName == "Tier1" then
            items = self:GetItemRepositoryTier1()
        elseif shopName == "Tier2" then
            items = self:GetItemRepositoryTier2()
        elseif shopName == "Daily Deals" then
            items = self:GetItemRepositoryDailyDeals()
        end

        for itemName, _ in pairs(items) do
            local stock = self:GetStock(shopName, itemName)
            availableItems[itemName] = stock
        end

        return availableItems
    end

    function m:StartAutoBuySeeds()
        if not Window:GetConfigValue("AutoBuySeeds") then
            return
        end

        local ignoreItems = Window:GetConfigValue("IgnoreSeedItems") or {}

        for itemName, stock in pairs(self:GetAvailableItems("Tier1")) do
            if stock <= 0 or table.find(ignoreItems, itemName) then
                continue
            end

            for i=1, stock do
                Core.ReplicatedStorage.GameEvents.BuySeedStock:FireServer("Shop", itemName)
            end
        end
    end

    function m:StartAutoBuySeedsTier2()
        if not Window:GetConfigValue("AutoBuySeedsTier2") then
            return
        end

        local selectedItems = Window:GetConfigValue("SelectedSeedItemsTier2") or {}

        for itemName, stock in pairs(self:GetAvailableItems("Tier2")) do
            if stock <= 0 then
                continue
            end

            if not table.find(selectedItems, itemName) then
                continue
            end

            for i=1, stock do
                Core.ReplicatedStorage.GameEvents.BuySeedStock:FireServer("Shop", itemName)
            end
        end
    end

    function m:StartAutoBuyDailyDeals()
        if not Window:GetConfigValue("AutoBuyDailyDeals") then
            return
        end

        for itemName, stock in pairs(self:GetAvailableItems("Daily Deals")) do
            if stock <= 0 then
                continue
            end

            for i=1, stock do
                Core.ReplicatedStorage.GameEvents.BuyDailySeedShopStock:FireServer(itemName)
                task.wait(0.15)
            end
        end
    end

    return m
end

-- Module: shop/gear.lua
EmbeddedModules["shop/gear.lua"] = function()
    local m = {}

    local Window
    local Core

    local ShopData
    local DataService

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        DataService = require(Core.ReplicatedStorage.Modules.DataService)
        ShopData = require(Core.ReplicatedStorage.Data.GearShopData)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuyGear")
        end, function()
            self:StartAutoBuyGear()
        end)
    end

    function m:GetItemRepository()
        return ShopData.Gear or {}
    end

    function m:GetStock(itemName)
        local shopData = DataService:GetData()
        local stock = 0
        if not shopData then
            return stock
        end

        stock = shopData.GearStock.Stocks[itemName] or 0

        if type(stock) ~= "number" then
            return stock.Stock or 0
        end

        return stock
    end

    function m:GetAvailableItems()
        local availableItems = {}
        local items = self:GetItemRepository()

        for itemName, _ in pairs(items) do
            local stock = self:GetStock(itemName)
            availableItems[itemName] = stock
        end

        return availableItems
    end

    function m:StartAutoBuyGear()
        if not Window:GetConfigValue("AutoBuyGear") then
            return
        end

        local ignoreItems = Window:GetConfigValue("IgnoreGearItems") or {}

        for gearName, stock in pairs(self:GetAvailableItems()) do
            if stock <= 0 or table.find(ignoreItems, gearName) then
                continue
            end

            for i=1, stock do
                Core.ReplicatedStorage.GameEvents.BuyGearStock:FireServer(gearName)
                task.wait(0.15)
            end
        end
    end

    return m
end

-- Module: shop/garden_coin.lua
EmbeddedModules["shop/garden_coin.lua"] = function()
    local m = {}

    local Window
    local Core

    local GardenCoinShopData
    local DataService

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        GardenCoinShopData = require(Core.ReplicatedStorage.Data.GardenCoinShopData)
        DataService = require(Core.ReplicatedStorage.Modules.DataService)
    end


    function m:GetGardenCoinItemRepository()
        local data = GardenCoinShopData or {}
        local items = {}
        local gardenCoinShopStock = DataService:GetData().GardenCoinShopStock.Stocks or {}

        for k, v in pairs(data) do
            table.insert(items, {
                Name = k,
                Price = v.Price,
                Rarity = v.SeedRarity,
                Stock = gardenCoinShopStock[k].Stock or 0,
                Order = v.LayoutOrder or 0,
            })
        end

        table.sort(items, function(a, b)
            return a.Order < b.Order
        end)

        return items
    end

    function m:Purchase()
        local selectedItem = Window:GetConfigValue("GardenCoinShopItemToPurchase")
        if not selectedItem then
            Window:ShowWarning("Garden Coin Shop", "Please select an item to purchase.")
            return
        end

        Window:ShowInfo("Garden Coin Shop", "Purchasing item: " .. selectedItem)
        pcall(function()
            Core.ReplicatedStorage.GameEvents.BuyGardenCoinShopStock:FireServer(selectedItem)
        end)
    end

    return m
end

-- Module: shop/premium.lua
EmbeddedModules["shop/premium.lua"] = function()
    local m ={}

    local Window
    local Core
    m.ListOfItems = {}

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        coroutine.wrap(function()
            self:GetListProducts()
        end)()
    end

    function m:BuyItemWithRobux()
        local premiumItem = Window:GetConfigValue("PremiumShopItem")

        if not premiumItem or premiumItem == "" then
            Window:ShowWarning("Premium Shop", "Please select a valid item to purchase.")
            return
        end

        local premiumProductID = tonumber(premiumItem)
        if not premiumProductID or premiumProductID <= 0 then
            Window:ShowWarning("Premium Shop", "Invalid Product ID.")
            return
        end

        if not Core.MarketplaceService then
            Window:ShowWarning("Premium Shop", "MarketplaceService not available.")
            return
        end
        local player = Core.LocalPlayer
        if not player then
            Window:ShowWarning("Premium Shop", "LocalPlayer not found.")
            return
        end

        Window:ShowInfo("Premium Shop", string.format("Purchasing product ID: %d for player: %s", premiumProductID, player.Name or "Unknown"))

        local success, err = pcall(function()
            Core.MarketplaceService:PromptProductPurchase(player, premiumProductID)
        end)

        if not success then
            Window:ShowWarning("Premium Shop", "Failed to prompt purchase: " .. tostring(err))
            warn("Purchase error details:", err)
        end
    end

    function m:BuyItemWithToken()
        local premiumItem = Window:GetConfigValue("PremiumShopItem")

        if not premiumItem or premiumItem == "" then
            Window:ShowWarning("Premium Shop", "Please select a valid item to purchase.")
            return
        end

        local premiumProductID = tonumber(premiumItem)
        if not premiumProductID or premiumProductID <= 0 then
            Window:ShowWarning("Premium Shop", "Invalid Product ID.")
            return
        end

        if not Core.ReplicatedStorage then
            Window:ShowWarning("Premium Shop", "ReplicatedStorage not available.")
            return
        end

        local player = Core.LocalPlayer
        if not player then
            Window:ShowWarning("Premium Shop", "LocalPlayer not found.")
            return
        end

        Window:ShowInfo("Premium Shop", string.format("Purchasing product ID: %d with Tokens for player: %s", premiumProductID, player.Name or "Unknown"))

        local success, err = pcall(function()
            local purchaseEvent = Core.ReplicatedStorage.GameEvents.TradeEvents.TradeTokens.Purchase
            purchaseEvent:InvokeServer(premiumProductID)
        end)

        if success then
            Window:ShowInfo("Premium Shop", "Token purchase request sent successfully!")
        else
            Window:ShowWarning("Premium Shop", "Failed to purchase with tokens: " .. tostring(err))
            warn("Token purchase error details:", err)
        end
    end

    function m:GiftItemWithRobux()
        local premiumItem = Window:GetConfigValue("PremiumShopItem")

        if not premiumItem or premiumItem == "" then
            Window:ShowWarning("Premium Shop", "Please select a valid item to gift.")
            return
        end

        local premiumProductID = tonumber(premiumItem)
        if not premiumProductID or premiumProductID <= 0 then
            Window:ShowWarning("Premium Shop", "Invalid Product ID.")
            return
        end

        if not Core.LocalPlayer then
            Window:ShowWarning("Premium Shop", "LocalPlayer not found.")
            return
        end

        if not Core.ReplicatedStorage then
            Window:ShowWarning("Premium Shop", "ReplicatedStorage not available.")
            return
        end

        local success, result = pcall(function()
            local giftController = require(Core.ReplicatedStorage.Modules.GiftController)
            local guiController = require(Core.ReplicatedStorage.Modules.GuiController)
            local giftPlayerList = Core.LocalPlayer.PlayerGui:WaitForChild("GiftPlayerList")

            giftController.CurrentProduct = premiumProductID

            for _, frame in giftPlayerList.Frame.ScrollingFrame:GetChildren() do
                if frame:IsA("Frame") and frame.Name ~= "UIListLayout" then
                    frame.Visible = true
                end
            end

            guiController:Open(giftPlayerList)

            return true
        end)

        if success then
            Window:ShowInfo("Premium Shop", string.format("Gift menu opened for product ID: %d", premiumProductID))
        else
            Window:ShowWarning("Premium Shop", "Failed to open gift menu: " .. tostring(result))
            warn("Gift error details:", result)
        end
    end

    function m:GetListProducts()
        local success, pages = pcall(function()
            return Core.MarketplaceService:GetDeveloperProductsAsync()
        end)

        if not success then
            warn("Failed to get developer products:", pages)
            return
        end

        while true do
            local products = pages:GetCurrentPage()

            for _, product in pairs(products) do
                table.insert(m.ListOfItems, product)
            end

            if pages.IsFinished then
                break
            end
            local success, err = pcall(function()
                pages:AdvanceToNextPageAsync()
            end)

            if not success then
                warn("Failed to advance to next page:", err)
                break
            end
        end
    end

    return m
end

-- Module: shop/ui.lua
EmbeddedModules["shop/ui.lua"] = function()
    local m = {}

    local Window
    local Core
    local EggShop
    local SeedShop
    local GearShop
    local SeasonPassShop
    local TravelingShop
    local PremiumShop
    local PetTeam
    local Rarity
    local CosmeticShop
    local GardenCoinShop


    -- Store ALL toggle references for config sync after reconnect
    m.ToggleReferences = {}
    m.SelectBoxReferences = {}

    function m:Init(_window, _core, _eggShop, _seedShop, _gearShop, _seasonPassShop, _travelingShop, _premiumShop, _petTeam, _rarity, _cosmeticShop, _gardenCoinShop)
        Window = _window
        Core = _core
        EggShop = _eggShop
        SeedShop = _seedShop
        GearShop = _gearShop
        SeasonPassShop = _seasonPassShop
        TravelingShop = _travelingShop
        PremiumShop = _premiumShop
        PetTeam = _petTeam
        Rarity = _rarity
        CosmeticShop = _cosmeticShop
        GardenCoinShop = _gardenCoinShop

        self:CreateShopTab()
    end

    function m:CreateShopTab()
        local tab = Window:AddTab({
            Name = "Shop",
            Icon = "🛍️",
        })

        local shopPetTeamSelectBox = tab:AddSelectBox({
            Name = "Pet Team to Use While Buying Pet Items",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "ShopPetTeam",
            OnInit = function(api, optionsData)
                    print("[DEBUG] ShopPetTeam OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("ShopPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "ShopPetTeam", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "ShopPetTeam", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end

                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if shopPetTeamSelectBox then
            m.SelectBoxReferences["ShopPetTeam"] = shopPetTeamSelectBox
            print("[DEBUG] Stored ShopPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("ShopPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    shopPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    shopPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        tab:AddLabel("")
        tab:AddSeparator()

        self:SeedShopSection(tab)
        self:CosmeticShopSection(tab)
        self:GearShopSection(tab)
        self:EggShopSection(tab)
        self:TravelingMerchantSection(tab)
        self:GardenCoinShopSection(tab)
        self:SeasonPassShopSection(tab)
        self:PremiumShopSection(tab)
    end

    function m:SeedShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Seed Shop",
            Icon = "🌱",
            Expanded = false,
        })

        local ignoreSeedItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Seeds to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Seeds",
            MultiSelect = true,
            Flag = "IgnoreSeedItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreSeedItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreSeedItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreSeedItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreSeedItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = SeedShop:GetItemRepositoryTier1()
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.Seed.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.Seed.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text = "[" .. data.Seed.SeedRarity .. "] " .. data._name, value = data._name})
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreSeedItemsSelectBox then
            m.SelectBoxReferences["IgnoreSeedItems"] = ignoreSeedItemsSelectBox
            print("[DEBUG] Stored IgnoreSeedItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreSeedItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreSeedItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreSeedItemsSelectBox:Set(savedValue)
                end
            end
        end

        local toggleBuyseeds = accordion:AddToggle({
            Name = "Auto Buy Seeds",
            Default = false,
            Flag = "AutoBuySeeds",
            Callback = function(Value)
                if Value then
                    SeedShop:StartAutoBuySeeds()
                end
            end,
        })


        m.ToggleReferences["AutoBuySeeds"] = toggleBuyseeds

        accordion:AddSeparator()

        local selectedSeedItemsTier2SelectBox = accordion:AddSelectBox({
            Name = "Select Seeds Tier 2 to Buying (Need GardenCoins And Tier 2 Unlocked)",
            Options = {"loading ..."},
            Placeholder = "Select Seeds Tier 2",
            MultiSelect = true,
            Flag = "SelectedSeedItemsTier2",
            OnInit = function(api, optionsData)
                    print("[DEBUG] SelectedSeedItemsTier2 OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("SelectedSeedItemsTier2")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "SelectedSeedItemsTier2", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "SelectedSeedItemsTier2", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = SeedShop:GetItemRepositoryTier2()
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.Seed.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.Seed.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text = "[" .. data.Seed.SeedRarity .. "] " .. data._name, value = data._name})
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if selectedSeedItemsTier2SelectBox then
            m.SelectBoxReferences["SelectedSeedItemsTier2"] = selectedSeedItemsTier2SelectBox
            print("[DEBUG] Stored SelectedSeedItemsTier2 SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("SelectedSeedItemsTier2")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    selectedSeedItemsTier2SelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    selectedSeedItemsTier2SelectBox:Set(savedValue)
                end
            end
        end

        local toggleBuyseedstier2 = accordion:AddToggle({
            Name = "Auto Buy Seeds Tier 2",
            Default = false,
            Flag = "AutoBuySeedsTier2",
            Callback = function(Value)
                if Value then
                    SeedShop:StartAutoBuySeedsTier2()
                end
            end,
        })


        m.ToggleReferences["AutoBuySeedsTier2"] = toggleBuyseedstier2

        accordion:AddSeparator()

        local toggleBuydailydeals = accordion:AddToggle({
            Name = "Auto Buy Daily Deals",
            Default = false,
            Flag = "AutoBuyDailyDeals",
            Callback = function(Value)
                if Value then
                    SeedShop:StartAutoBuyDailyDeals()
                end
            end,
        })


        m.ToggleReferences["AutoBuyDailyDeals"] = toggleBuydailydeals
    end

    function m:CosmeticShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Cosmetic Shop",
            Icon = "🎨",
            Expanded = false,
        })

        local ignoreCosmeticItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Cosmetic Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Cosmetic Items",
            MultiSelect = true,
            Flag = "IgnoreCosmeticItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreCosmeticItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreCosmeticItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreCosmeticItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreCosmeticItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = CosmeticShop:GetCosmeticItemRepository()
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    return a._name < b._name
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, data._name)
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreCosmeticItemsSelectBox then
            m.SelectBoxReferences["IgnoreCosmeticItems"] = ignoreCosmeticItemsSelectBox
            print("[DEBUG] Stored IgnoreCosmeticItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreCosmeticItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreCosmeticItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreCosmeticItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreCrateItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Crate Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Crate Items",
            MultiSelect = true,
            Flag = "IgnoreCrateItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreCrateItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreCrateItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreCrateItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreCrateItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = CosmeticShop:GetCrateItemRepository()
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    return a._name < b._name
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, data._name)
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreCrateItemsSelectBox then
            m.SelectBoxReferences["IgnoreCrateItems"] = ignoreCrateItemsSelectBox
            print("[DEBUG] Stored IgnoreCrateItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreCrateItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreCrateItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreCrateItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreFenceItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Fence Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Fence Items",
            MultiSelect = true,
            Flag = "IgnoreFenceItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreFenceItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreFenceItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreFenceItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreFenceItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = CosmeticShop:GetFenceItemRepository()

                updateOptions(items)
            end
        })

        -- Store reference immediately after creation
        if ignoreFenceItemsSelectBox then
            m.SelectBoxReferences["IgnoreFenceItems"] = ignoreFenceItemsSelectBox
            print("[DEBUG] Stored IgnoreFenceItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreFenceItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreFenceItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreFenceItemsSelectBox:Set(savedValue)
                end
            end
        end

        local toggleBuycosmeticitems = accordion:AddToggle({
            Name = "Auto Buy Cosmetic Items",
            Default = false,
            Flag = "AutoBuyCosmeticItems",
            Callback = function(Value)
                if Value then
                    CosmeticShop:StartAutoBuyCosmeticItems()
                end
            end,
        })


        m.ToggleReferences["AutoBuyCosmeticItems"] = toggleBuycosmeticitems
    end

    function m:GearShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Gear Shop",
            Icon = "🛠️",
            Expanded = false,
        })

        local ignoreGearItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Gear to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Gear",
            MultiSelect = true,
            Flag = "IgnoreGearItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreGearItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreGearItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreGearItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreGearItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = GearShop:GetItemRepository()
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.Gear.GearRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.Gear.GearRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a.Gear.GearName < b.Gear.GearName
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text = "[" .. data.Gear.GearRarity .. "] " .. data._name, value = data._name})
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreGearItemsSelectBox then
            m.SelectBoxReferences["IgnoreGearItems"] = ignoreGearItemsSelectBox
            print("[DEBUG] Stored IgnoreGearItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreGearItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreGearItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreGearItemsSelectBox:Set(savedValue)
                end
            end
        end

        local toggleBuygear = accordion:AddToggle({
            Name = "Auto Buy Gear",
            Default = false,
            Flag = "AutoBuyGear",
            Callback = function(Value)
                if Value then
                    GearShop:StartAutoBuyGear()
                end
            end,
        })


        m.ToggleReferences["AutoBuyGear"] = toggleBuygear
    end

    function m:EggShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Egg Shop",
            Icon = "🥚",
            Expanded = false,
        })

        local ignoreEggItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Eggs to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Eggs",
            MultiSelect = true,
            Flag = "IgnoreEggItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreEggItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreEggItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreEggItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreEggItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = EggShop:GetItemRepository()
                local sortedList = {}
                local itemNames = {}

                for _, data in pairs(items) do
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.EggRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.EggRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a.EggName < b.EggName
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.EggRarity .. "] " .. data.EggName, value=data.EggName})
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreEggItemsSelectBox then
            m.SelectBoxReferences["IgnoreEggItems"] = ignoreEggItemsSelectBox
            print("[DEBUG] Stored IgnoreEggItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreEggItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreEggItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreEggItemsSelectBox:Set(savedValue)
                end
            end
        end

        local toggleBuyeggs = accordion:AddToggle({
            Name = "Auto Buy Eggs",
            Default = false,
            Flag = "AutoBuyEggs",
            Callback = function(Value)
                if Value then
                    EggShop:StartBuyEgg()
                end
            end,
        })


        m.ToggleReferences["AutoBuyEggs"] = toggleBuyeggs
    end

    function m:TravelingMerchantSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Traveling Merchant Shop",
            Icon = "🧳",
            Expanded = false,
        })

        local ignoreFallMerchantItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Fall Merchant Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreFallMerchantItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreFallMerchantItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreFallMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreFallMerchantItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreFallMerchantItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = TravelingShop:GetItemRepository("FallMerchant")
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
                end
                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreFallMerchantItemsSelectBox then
            m.SelectBoxReferences["IgnoreFallMerchantItems"] = ignoreFallMerchantItemsSelectBox
            print("[DEBUG] Stored IgnoreFallMerchantItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreFallMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreFallMerchantItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreFallMerchantItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreGnomeMerchantItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Gnome Merchant Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreGnomeMerchantItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreGnomeMerchantItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreGnomeMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreGnomeMerchantItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreGnomeMerchantItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = TravelingShop:GetItemRepository("GnomeMerchant")
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
                end
                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreGnomeMerchantItemsSelectBox then
            m.SelectBoxReferences["IgnoreGnomeMerchantItems"] = ignoreGnomeMerchantItemsSelectBox
            print("[DEBUG] Stored IgnoreGnomeMerchantItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreGnomeMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreGnomeMerchantItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreGnomeMerchantItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreHoneyMerchantItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Honey Merchant Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreHoneyMerchantItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreHoneyMerchantItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreHoneyMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreHoneyMerchantItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreHoneyMerchantItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = TravelingShop:GetItemRepository("HoneyMerchant")
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
                end
                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreHoneyMerchantItemsSelectBox then
            m.SelectBoxReferences["IgnoreHoneyMerchantItems"] = ignoreHoneyMerchantItemsSelectBox
            print("[DEBUG] Stored IgnoreHoneyMerchantItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreHoneyMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreHoneyMerchantItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreHoneyMerchantItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreSkyMerchantItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Sky Merchant Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreSkyMerchantItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreSkyMerchantItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreSkyMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreSkyMerchantItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreSkyMerchantItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = TravelingShop:GetItemRepository("SkyMerchant")
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
                end
                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreSkyMerchantItemsSelectBox then
            m.SelectBoxReferences["IgnoreSkyMerchantItems"] = ignoreSkyMerchantItemsSelectBox
            print("[DEBUG] Stored IgnoreSkyMerchantItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreSkyMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreSkyMerchantItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreSkyMerchantItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreSprayMerchantItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Spray Merchant Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreSprayMerchantItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreSprayMerchantItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreSprayMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreSprayMerchantItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreSprayMerchantItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = TravelingShop:GetItemRepository("SprayMerchant")
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
                end
                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreSprayMerchantItemsSelectBox then
            m.SelectBoxReferences["IgnoreSprayMerchantItems"] = ignoreSprayMerchantItemsSelectBox
            print("[DEBUG] Stored IgnoreSprayMerchantItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreSprayMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreSprayMerchantItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreSprayMerchantItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreSprinklerMerchantItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Sprinkler Merchant Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreSprinklerMerchantItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreSprinklerMerchantItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreSprinklerMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreSprinklerMerchantItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreSprinklerMerchantItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = TravelingShop:GetItemRepository("SprinklerMerchant")
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
                end
                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreSprinklerMerchantItemsSelectBox then
            m.SelectBoxReferences["IgnoreSprinklerMerchantItems"] = ignoreSprinklerMerchantItemsSelectBox
            print("[DEBUG] Stored IgnoreSprinklerMerchantItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreSprinklerMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreSprinklerMerchantItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreSprinklerMerchantItemsSelectBox:Set(savedValue)
                end
            end
        end

        local ignoreSummerMerchantItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Summer Merchant Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreSummerMerchantItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreSummerMerchantItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreSummerMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreSummerMerchantItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreSummerMerchantItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = TravelingShop:GetItemRepository("SummerMerchant")
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.SeedRarity] or 99
                    local rarityB = Rarity.RarityOrder[b.SeedRarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    table.insert(itemNames, {text= "[" .. data.SeedRarity .. "] " .. data._name .. " (" .. data.ItemType .. ")", value=data._name})
                end
                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreSummerMerchantItemsSelectBox then
            m.SelectBoxReferences["IgnoreSummerMerchantItems"] = ignoreSummerMerchantItemsSelectBox
            print("[DEBUG] Stored IgnoreSummerMerchantItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreSummerMerchantItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreSummerMerchantItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreSummerMerchantItemsSelectBox:Set(savedValue)
                end
            end
        end

        local toggleBuytravelingmerchant = accordion:AddToggle({
            Name = "Auto Buy Traveling Merchant Items",
            Default = false,
            Flag = "AutoBuyTravelingMerchant",
            Callback = function(Value)
                if Value then
                    TravelingShop:StartBuyTravelingItems()
                end
            end,
        })


        m.ToggleReferences["AutoBuyTravelingMerchant"] = toggleBuytravelingmerchant
    end

    function m:GardenCoinShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Garden Coin Shop",
            Icon = "🌻",
            Expanded = false,
        })

        local gardenCoinShopItemToPurchaseSelectBox = accordion:AddSelectBox({
            Name = "Select Garden Coin Items to Buy",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = false,
            Flag = "GardenCoinShopItemToPurchase",
            OnInit = function(api, optionsData)
                    print("[DEBUG] GardenCoinShopItemToPurchase OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("GardenCoinShopItemToPurchase")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "GardenCoinShopItemToPurchase", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "GardenCoinShopItemToPurchase", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = GardenCoinShop:GetGardenCoinItemRepository()
                local itemNames = {}

                for _, data in pairs(items) do
                    table.insert(itemNames, {text= string.format("[%s] %s (Stock: %d) (Price: %d)", data.Rarity, data.Name, data.Stock, data.Price), value=data.Name})
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if gardenCoinShopItemToPurchaseSelectBox then
            m.SelectBoxReferences["GardenCoinShopItemToPurchase"] = gardenCoinShopItemToPurchaseSelectBox
            print("[DEBUG] Stored GardenCoinShopItemToPurchase SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("GardenCoinShopItemToPurchase")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    gardenCoinShopItemToPurchaseSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    gardenCoinShopItemToPurchaseSelectBox:Set(savedValue)
                end
            end
        end

        accordion:AddButton({
            Name = "Purchase Selected Garden Coin Items Now",
            Callback = function()
                GardenCoinShop:Purchase()
            end
        })
    end

    function m:SeasonPassShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Season Pass Shop",
            Icon = "🎟️",
            Expanded = false,
        })

        local ignoreSeasonPassItemsSelectBox = accordion:AddSelectBox({
            Name = "Select Season Pass Items to Ignore Buying",
            Options = {"loading ..."},
            Placeholder = "Select Items",
            MultiSelect = true,
            Flag = "IgnoreSeasonPassItems",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IgnoreSeasonPassItems OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("IgnoreSeasonPassItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "IgnoreSeasonPassItems", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "IgnoreSeasonPassItems", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = SeasonPassShop:GetItemRepository()
                local sortedList = {}
                local itemNames = {}

                for itemName, data in pairs(items) do
                    data._name = itemName
                    table.insert(sortedList, data)
                end

                table.sort(sortedList, function(a, b)
                    local rarityA = Rarity.RarityOrder[a.Rarity] or 99
                    local rarityB = Rarity.RarityOrder[b.Rarity] or 99

                    if rarityA == rarityB then
                        if a.LayoutOrder == b.LayoutOrder then
                            return a._name < b._name
                        else
                            return a.LayoutOrder < b.LayoutOrder
                        end
                    end

                    return rarityA < rarityB
                end)

                for _, data in pairs(sortedList) do
                    local rarity = data.Rarity or "Unknown"
                    local name = data._name or "Unnamed"
                    table.insert(itemNames, {text= "[" .. rarity .. "] " .. name, value=name})
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if ignoreSeasonPassItemsSelectBox then
            m.SelectBoxReferences["IgnoreSeasonPassItems"] = ignoreSeasonPassItemsSelectBox
            print("[DEBUG] Stored IgnoreSeasonPassItems SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IgnoreSeasonPassItems")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    ignoreSeasonPassItemsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    ignoreSeasonPassItemsSelectBox:Set(savedValue)
                end
            end
        end

        local toggleBuyseasonpasses = accordion:AddToggle({
            Name = "Auto Buy Season Pass Items",
            Default = false,
            Flag = "AutoBuySeasonPasses",
            Callback = function(Value)
                if Value then
                    SeasonPassShop:StartBuySeasonPassItems()
                end
            end,
        })


        m.ToggleReferences["AutoBuySeasonPasses"] = toggleBuyseasonpasses
    end

    function m:PremiumShopSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Premium Shop",
            Icon = "💎",
            Expanded = false,
        })

        local premiumShopItemSelectBox = accordion:AddSelectBox({
            Name = "Select Item to Buy 🛒",
            Options = {"Loading..."},
            Placeholder = "Select Item",
            MultiSelect = false,
            Flag = "PremiumShopItem",
            OnInit = function(api, optionsData)
                    print("[DEBUG] PremiumShopItem OnInit called")
            -- Load saved value from config immediately
            local savedValue = Window:GetConfigValue("PremiumShopItem")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %d items", "PremiumShopItem", #savedValue))
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    api:Set(savedValue)
                    print(string.format("[SelectBox] Restored %s: %s", "PremiumShopItem", savedValue))
                end
            end
                    end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local items = PremiumShop.ListOfItems or {}
                local itemNames = {}

                for _, data in pairs(items) do
                    table.insert(itemNames, {text = string.format("%s (Price: %d)", data.Name, data.PriceInRobux), value = data.ProductId})
                end

                updateOptions(itemNames)
            end
        })

        -- Store reference immediately after creation
        if premiumShopItemSelectBox then
            m.SelectBoxReferences["PremiumShopItem"] = premiumShopItemSelectBox
            print("[DEBUG] Stored PremiumShopItem SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("PremiumShopItem")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    premiumShopItemSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    premiumShopItemSelectBox:Set(savedValue)
                end
            end
        end

        local premiumShopPaymentMethodSelectBox = accordion:AddSelectBox({
            Name = "Payment Method 💳",
            Options = {
                {text = "Robux 🤑", value = "Robux"},
                {text = "Token 💎", value = "Token"}
            },
            Placeholder = "Select Payment Method",
            MultiSelect = false,
            Flag = "PremiumShopPaymentMethod",
            Default = "Robux"
        })

        -- Store reference immediately after creation
        if premiumShopPaymentMethodSelectBox then
            m.SelectBoxReferences["PremiumShopPaymentMethod"] = premiumShopPaymentMethodSelectBox
            print("[DEBUG] Stored PremiumShopPaymentMethod SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("PremiumShopPaymentMethod")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    premiumShopPaymentMethodSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    premiumShopPaymentMethodSelectBox:Set(savedValue)
                end
            end
        end

        accordion:AddButton({
            Name = "Purchase Item 🛒",
            Callback = function()
                local paymentMethod = Window:GetConfigValue("PremiumShopPaymentMethod")

                if paymentMethod == "Token" then
                    PremiumShop:BuyItemWithToken()
                else
                    PremiumShop:BuyItemWithRobux()
                end
            end
        })

        accordion:AddSeparator()

        accordion:AddButton({
            Name = "Gift Selected Player Premium Item 🎁",
            Callback = function()
                PremiumShop:GiftItemWithRobux()
            end
        })
    end



    -- Function to refresh all selectbox UI states from config
    function m:RefreshSelectBoxStates()
        if not Window then
            warn("[SHOP] RefreshSelectBoxStates - Window not initialized")
            return 0
        end

        -- Count entries properly (# operator doesn't work for dictionary tables)
        local totalRefs = 0
        for _ in pairs(self.SelectBoxReferences) do
            totalRefs = totalRefs + 1
        end

        print(string.format("[SHOP] RefreshSelectBoxStates called, found %d selectbox references", totalRefs))

        if totalRefs > 0 then
            print("[SHOP] SelectBoxReferences keys:")
            for k, v in pairs(self.SelectBoxReferences) do
                print("  - " .. k .. " : " .. tostring(v ~= nil and "API exists" or "nil"))
            end
        else
            warn("[SHOP] WARNING: SelectBoxReferences is empty! This means OnInit was not called or selectboxes were not stored properly.")
        end

        local refreshedCount = 0

        for flagName, selectBoxAPI in pairs(self.SelectBoxReferences) do
            local success, err = pcall(function()
                if selectBoxAPI and type(selectBoxAPI) == "table" and selectBoxAPI.Set then
                    local configValue = Window:GetConfigValue(flagName)

                    if configValue ~= nil and configValue ~= "" then
                        -- Check if it's a table with items or a non-empty string
                        local hasValue = false
                        if type(configValue) == "table" and #configValue > 0 then
                            hasValue = true
                        elseif type(configValue) == "string" and configValue ~= "" then
                            hasValue = true
                        end

                        if hasValue then
                            -- Use Set() method to update UI without triggering callbacks
                            selectBoxAPI:Set(configValue)
                            local valueStr = type(configValue) == "table" and (#configValue .. " items") or tostring(configValue)
                            print(string.format("  ✓ [SHOP SelectBox] %s = %s", flagName, valueStr))
                            refreshedCount = refreshedCount + 1
                        end
                    else
                        print(string.format("  ⊘ [SHOP SelectBox] %s - No saved value in config", flagName))
                    end
                else
                    warn(string.format("  ✗ [SHOP SelectBox] %s - API missing or invalid (type: %s, has Set: %s)",
                        flagName,
                        type(selectBoxAPI),
                        selectBoxAPI and type(selectBoxAPI.Set) or "nil"))
                end
            end)

            if not success then
                warn(string.format("  ✗ [SHOP SelectBox] %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("[SHOP] Refreshed %d selectboxes successfully", refreshedCount))
        return refreshedCount
    end

    -- Function to refresh all toggle UI states from config
    function m:RefreshToggleStates()
        if not Window then
            warn("ShopUI:RefreshToggleStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, toggleAPI in pairs(self.ToggleReferences) do
            local success, err = pcall(function()
                if toggleAPI and toggleAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        toggleAPI:SetValue(configValue, false)
                        print(string.format("  ✓ [Shop] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Shop] %s - Toggle API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Shop] %s - Error: %s", flagName, tostring(err)))
            end
        end

        return refreshedCount
    end

    return m
end

-- Module: pet/team.lua
EmbeddedModules["pet/team.lua"] = function()
    local m = {}

    local Core
    local Player
    local Window
    local PetConfig
    local Garden

    function m:Init(_core, _player, _window, _petConfig, _garden)
        Core = _core
        Player = _player
        Window = _window
        PetConfig = _petConfig
        Garden = _garden
    end

    function m:SaveTeamPets(_teamName, _listPets)
        PetConfig:SetValue(_teamName, _listPets)
    end

    function m:GetAllPetTeams()
        local allKeys = PetConfig:GetAllKeys()

        return allKeys
    end

    function m:FindPetTeam(_teamName)
        return PetConfig:GetValue(_teamName)
    end

    function m:DeleteTeamPets(_teamName)
        PetConfig:DeleteKey(_teamName)
    end

    return m
end

-- Module: inventory/inventory.lua
EmbeddedModules["inventory/inventory.lua"] = function()
    local m = {}

    local Core
    local Player
    local Window
    local Pet

    local InventoryConnection
    local IsAutoFavUnfavBoneBlossomActive = false
    local BoneBlossomGlitchRefCount = 0
    local IsAutoFavUnfavGearActive = false
    local GearGlitchRefCount = 0

    function m:Init(_core, _player, _window, _pet)
        Core = _core
        Player = _player
        Window = _window
        Pet = _pet

        if Window:GetConfigValue("AutoFavoritePets") then
            InventoryConnection = Core:GetBackpack().ChildAdded:Connect(function(tool)
                self:FavoritingPet(tool)
            end)
        end

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoFavoritePets")
        end, function()
            self:StartAutoFavoritePets()
        end)
    end

    function m:GetAllPets()
        local myPets = {}

        for _, tool in next, Player:GetAllTools() do
            local toolType = tool:GetAttribute("b")
            toolType = toolType and string.lower(toolType) or ""
            if toolType == "l" then
                table.insert(myPets, tool)
            end
        end

        return myPets
    end

    function m:FavoriteItem(item)
        Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(item)
        task.wait(0.15)
    end

    function m:UnfavoriteItem(item)
        Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(item)
        task.wait(0.15)
    end

    function m:UnfavoriteSelectedPets()
        local petNames = Window:GetConfigValue("AutoUnfavoritePetName") or {}
        if #petNames == 0 then
            Window:ShowWarning("Unfavorite Pets", "No pet names selected for unfavoriting.")
            return
        end

        Window:ShowInfo("Unfavorite Pets", "Starting unfavorite process for " .. #petNames .. " pet type(s)...")
        Player:UnequipTool()
        task.wait(0.2)

        local unfavoritedCount = 0
        local processedPets = {}

        for _, tool in pairs(Player:GetAllTools()) do
            local toolType = tool:GetAttribute("b")
            toolType = toolType and string.lower(toolType) or ""

            if toolType == "l" then
                local isFavorited = tool:GetAttribute("d") or false
                if not isFavorited then
                    continue
                end

                -- Get pet type from pet data (same method as SellPet function)
                local petID = tool:GetAttribute("PET_UUID")
                local petData = Pet:GetPetData(petID)

                if not petData then
                    warn("Pet data not found for UUID:" .. tostring(petID))
                    continue
                end

                local petName = petData.PetType or "Unknown"

                -- Debug: Track what we're checking
                if not processedPets[petName] then
                    processedPets[petName] = 0
                end

                for _, selectedPetName in ipairs(petNames) do
                    if petName == selectedPetName then
                        Window:ShowInfo("Unfavorite Pets", string.format("Unfavoriting: %s (Type: %s)", tool.Name, petName))
                        self:UnfavoriteItem(tool)
                        unfavoritedCount = unfavoritedCount + 1
                        processedPets[petName] = processedPets[petName] + 1
                        task.wait(0.15)
                        break
                    end
                end
            end
        end

        if unfavoritedCount > 0 then
            Window:ShowInfo("Unfavorite Pets", "Completed! Unfavorited " .. tostring(unfavoritedCount) .. " pet(s).")
        else
            Window:ShowWarning("Unfavorite Pets", "No matching favorited pets found. Make sure the pet names match exactly.")
        end
    end

    function m:FavoritingPet(item)
        if not item or not item:IsA("Tool") then
            return
        end

        local petType = item:GetAttribute("b")
        if not petType or string.lower(petType) ~= "l" then
            return
        end

        local isFavorited = item:GetAttribute("d") or false
        if isFavorited then
            return
        end

        local petNames = Window:GetConfigValue("AutoFavoritePetName") or {}
        local weightThreshold = Window:GetConfigValue("AutoFavoritePetWeight") or 0.0
        local ageThreshold = Window:GetConfigValue("AutoFavoritePetAge") or 0

        -- Get pet type from pet data (same method as SellPet and UnfavoriteSelectedPets)
        local petID = item:GetAttribute("PET_UUID")
        local petData = Pet:GetPetData(petID)

        if not petData then
            warn("Pet data not found for UUID:" .. tostring(petID))
            return
        end

        local petName = petData.PetType or "Unknown"
        local petDetail = petData.PetData
        local weight = petDetail.BaseWeight or 0
        local age = petDetail.Level or 0

        -- If specific pet names are selected
        if #petNames > 0 then
            -- Check if this pet matches one of the selected names
            local isPetNameMatched = false
            for _, name in ipairs(petNames) do
                if petName == name then
                    isPetNameMatched = true
                    break
                end
            end

            if isPetNameMatched then
                -- If both thresholds are 0, favorite all matching pets without filtering
                if weightThreshold == 0 and ageThreshold == 0 then
                    Window:ShowInfo("Favoriting Pet", string.format("%s | Weight: %.2f | Age: %d", petName, weight, age))
                    self:FavoriteItem(item)
                -- Otherwise, only favorite if meets weight/age criteria
                elseif weight >= weightThreshold or age >= ageThreshold then
                    Window:ShowInfo("Favoriting Pet", string.format("%s | Weight: %.2f | Age: %d", petName, weight, age))
                    self:FavoriteItem(item)
                end
            end
        else
            -- If no specific pet names selected, favorite based on weight/age only
            if weight >= weightThreshold or age >= ageThreshold then
                Window:ShowInfo("Favoriting Pet", string.format("%s | Weight: %.2f | Age: %d", petName, weight, age))
                self:FavoriteItem(item)
            end
        end
    end

    function m:StartAutoFavoritePets()
        if not Window:GetConfigValue("AutoFavoritePets") then return end

        self:FavoriteAllPets()

        if InventoryConnection then
            return
        end

        InventoryConnection = Core:GetBackpack().ChildAdded:Connect(function(tool)
            self:FavoritingPet(tool)
        end)
    end

    function m:StopAutoFavoritePets()
        if InventoryConnection then
            InventoryConnection:Disconnect()
            InventoryConnection = nil
        end
    end

    function m:FavoriteAllPets()
        for _, tool in pairs(self:GetAllPets()) do
            self:FavoritingPet(tool)
        end
    end

    -- ===== AUTO FAV/UNFAV BONE BLOSSOM (CONTINUOUS LOOP) =====
    function m:GetAllFruits()
        local myFruits = {}

        for _, tool in next, Player:GetAllTools() do
            local toolType = tool:GetAttribute("b")
            toolType = toolType and string.lower(toolType) or ""
            if toolType == "j" then -- "j" is for fruits
                table.insert(myFruits, tool)
            end
        end

        return myFruits
    end

    function m:StartAutoFavUnfavBoneBlossom()
        -- Check if feature is enabled
        if not Window:GetConfigValue("AutoFavUnfavBoneBlossom") then
            return false
        end

        -- Increment reference count
        BoneBlossomGlitchRefCount = BoneBlossomGlitchRefCount + 1

        -- If already running, just return (another caller is using it)
        if IsAutoFavUnfavBoneBlossomActive then
            return true
        end

        IsAutoFavUnfavBoneBlossomActive = true
        Window:ShowInfo("Bone Blossom Glitch", "Started")

        task.spawn(function()
            while IsAutoFavUnfavBoneBlossomActive do
                local allFruits = self:GetAllFruits()

                for _, tool in pairs(allFruits) do
                    if not IsAutoFavUnfavBoneBlossomActive then
                        break
                    end

                    local fruitName = tool:GetAttribute("f") or ""

                    if fruitName == "Bone Blossom" then
                        -- Fire favorite event (toggles favorite status)
                        Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(tool)
                        task.wait(0.01) -- 100 requests per second
                    end
                end

                task.wait(0.01) -- Small wait before rechecking fruits
            end

            Window:ShowInfo("Bone Blossom Glitch", "Stopped")
        end)

        return true
    end

    function m:StopAutoFavUnfavBoneBlossom()
        -- Decrement reference count
        BoneBlossomGlitchRefCount = math.max(0, BoneBlossomGlitchRefCount - 1)

        -- Only stop if no more callers are using it
        if BoneBlossomGlitchRefCount > 0 then
            return
        end

        if not IsAutoFavUnfavBoneBlossomActive then
            return
        end

        IsAutoFavUnfavBoneBlossomActive = false
    end

    -- ===== AUTO FAV/UNFAV GEAR (CONTINUOUS LOOP) =====

    -- Helper function to extract base gear name from tool name
    local function extractGearBaseName(toolName)
        local baseName = toolName

        -- Step 1: Remove all bracket contents like "[123x Uses]", "[Amber]", "[Destroy Plants]", etc.
        baseName = baseName:gsub("%s*%[.-%]", "")

        -- Step 2: Remove trailing quantity pattern " x123" or " x123456"
        baseName = baseName:gsub("%s+x%d+$", "")

        -- Step 3: Trim whitespace
        baseName = baseName:match("^%s*(.-)%s*$") or baseName

        return baseName
    end

    -- Item types that are NOT gear items (excluded from gear detection)
    local EXCLUDED_ITEM_TYPES = {
        ["l"] = true,  -- Pet
        ["a"] = true,  -- Seed Pack
    }

    function m:GetAllGears()
        local myGears = {}

        for _, tool in next, Player:GetAllTools() do
            if not tool:IsA("Tool") then
                continue
            end

            -- Skip excluded item types (pets, seed packs, etc.)
            local itemType = tool:GetAttribute("b")
            if itemType and EXCLUDED_ITEM_TYPES[string.lower(itemType)] then
                continue
            end

            local toolName = tool.Name or ""
            local baseName = extractGearBaseName(toolName)

            -- Skip empty names
            if baseName == "" then
                continue
            end

            table.insert(myGears, {
                tool = tool,
                name = baseName,
                fullName = toolName,
                displayName = tool:GetAttribute("u") or baseName,
                quantity = tool:GetAttribute("e") or 1,
            })
        end

        return myGears
    end

    function m:GetGearRegistry()
        local gears = self:GetAllGears()
        local gearRegistry = {}
        local seenNames = {}

        for _, gearInfo in pairs(gears) do
            -- gearInfo.name is already the base name (without "[X Uses]", "x123", etc.)
            if not seenNames[gearInfo.name] then
                seenNames[gearInfo.name] = true
                table.insert(gearRegistry, {
                    name = gearInfo.name,
                    fullName = gearInfo.fullName,
                    displayName = gearInfo.displayName,
                    quantity = gearInfo.quantity,
                })
            end
        end

        -- Sort alphabetically
        table.sort(gearRegistry, function(a, b)
            return a.name < b.name
        end)

        return gearRegistry
    end

    -- Helper function to check if player owns a specific gear
    function m:HasGear(gearName)
        local gears = self:GetAllGears()
        for _, gearInfo in pairs(gears) do
            if gearInfo.name == gearName then
                return true
            end
        end
        return false
    end

    -- Validate saved gear selections against current inventory
    function m:ValidateGearSelections(savedGears)
        if type(savedGears) ~= "table" then
            return {}
        end

        local validGears = {}
        for _, gearName in pairs(savedGears) do
            if self:HasGear(gearName) then
                table.insert(validGears, gearName)
            end
        end
        return validGears
    end

    function m:StartAutoFavUnfavGear()
        -- Check if feature is enabled
        if not Window:GetConfigValue("AutoFavUnfavGear") then
            return false
        end

        -- Increment reference count
        GearGlitchRefCount = GearGlitchRefCount + 1

        -- If already running, just return (another caller is using it)
        if IsAutoFavUnfavGearActive then
            return true
        end

        local selectedGears = Window:GetConfigValue("AutoFavUnfavGearSelect") or {}
        if #selectedGears == 0 then
            GearGlitchRefCount = math.max(0, GearGlitchRefCount - 1)
            return false
        end

        IsAutoFavUnfavGearActive = true
        Window:ShowInfo("Gear Glitch", "Started for " .. #selectedGears .. " gear(s)")

        task.spawn(function()
            while IsAutoFavUnfavGearActive do
                local backpack = Core:GetBackpack()
                if not backpack then
                    task.wait(0.1)
                    continue
                end

                for _, tool in pairs(backpack:GetChildren()) do
                    if not IsAutoFavUnfavGearActive then
                        break
                    end

                    if not tool:IsA("Tool") then
                        continue
                    end

                    local toolName = tool.Name or ""

                    -- Check jika tool name cocok dengan salah satu gear yang dipilih
                    for _, selectedGear in pairs(selectedGears) do
                        if string.find(toolName, selectedGear, 1, true) then
                            -- Fire favorite event (toggles favorite status)
                            Core.ReplicatedStorage.GameEvents.Favorite_Item:FireServer(tool)
                            task.wait(0.01) -- 100 requests per second
                            break
                        end
                    end
                end

                task.wait(0.01) -- Small wait before rechecking gears
            end

            Window:ShowInfo("Gear Glitch", "Stopped")
        end)

        return true
    end

    function m:StopAutoFavUnfavGear()
        -- Decrement reference count
        GearGlitchRefCount = math.max(0, GearGlitchRefCount - 1)

        -- Only stop if no more callers are using it
        if GearGlitchRefCount > 0 then
            return
        end

        if not IsAutoFavUnfavGearActive then
            return
        end

        IsAutoFavUnfavGearActive = false
    end

    return m
end

-- Module: inventory/ui.lua
EmbeddedModules["inventory/ui.lua"] = function()
    local m = {}

    local Window
    local Core
    local Inventory
    local Pet
    local Trade
    local SeedPack


    -- Store ALL toggle references for config sync after reconnect
    m.ToggleReferences = {}
    m.SelectBoxReferences = {}
    m.NumberBoxReferences = {}

    function m:Init(_window, _core, _inventory, _pet, _trade, _seedPack)
        Window = _window
        Core = _core
        Inventory = _inventory
        Pet = _pet
        Trade = _trade
        SeedPack = _seedPack

        self:CreateTab()
    end

    function m:CreateTab()
        local tab = Window:AddTab({
            Name = "Inventory",
            Icon = "🎒"
        })

        self:AddPetSection(tab)
        self:AddTradeSection(tab)
        self:SeedPackSection(tab)
    end

    function m:AddPetSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Pets",
            Icon = "🐶",
            Expanded = false,
        })

        local autoFavoritePetNameSelectBox = accordion:AddSelectBox({
            Name = "Select pet name for auto favorite",
            Options = {"Loading..."},
            Placeholder = "Select a pet",
            MultiSelect = true,
            Flag = "AutoFavoritePetName",
            OnInit = function(api, optionsData)
                print("[DEBUG] AutoFavoritePetName OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("AutoFavoritePetName")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "AutoFavoritePetName", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "AutoFavoritePetName", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                updateOptions(formattedPets)
            end
        })

        -- Store reference immediately after creation
        if autoFavoritePetNameSelectBox then
            m.SelectBoxReferences["AutoFavoritePetName"] = autoFavoritePetNameSelectBox
            print("[DEBUG] Stored AutoFavoritePetName SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("AutoFavoritePetName")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    autoFavoritePetNameSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    autoFavoritePetNameSelectBox:Set(savedValue)
                end
            end
        end

        local autoFavoritePetWeightNumberBox = accordion:AddNumberBox({
            Name = "Or If Weight Is Higher Than Or Equal To",
            Placeholder = "Enter weight...",
            Default = 0.0,
            Min = 0.0,
            Max = 20.0,
            Increment = 1.0,
            Decimals = 2,
            Flag = "AutoFavoritePetWeight",
        })


        m.NumberBoxReferences["AutoFavoritePetWeight"] = autoFavoritePetWeightNumberBox

        local autoFavoritePetAgeNumberBox = accordion:AddNumberBox({
            Name = "Or If Age Is Higher Than Or Equal To",
            Placeholder = "Enter age...",
            Default = 0,
            Min = 0,
            Max = 100,
            Increment = 1,
            Flag = "AutoFavoritePetAge",
        })


        m.NumberBoxReferences["AutoFavoritePetAge"] = autoFavoritePetAgeNumberBox

        local toggleFavoritepets = accordion:AddToggle({
            Name = "Auto Favorite Pets",
            Flag = "AutoFavoritePets",
            Default = false,
            Callback = function(value)
                if value then
                    Inventory:StartAutoFavoritePets()
                else
                    Inventory:StopAutoFavoritePets()
                end
            end
        })


        m.ToggleReferences["AutoFavoritePets"] = toggleFavoritepets

        accordion:AddButton({
            Name = "Favorite Now",
            Callback = function()
                Inventory:FavoriteAllPets()
            end
        })

        accordion:AddSeparator()

        local autoUnfavoritePetNameSelectBox = accordion:AddSelectBox({
            Name = "Select pet name for auto unfavorite",
            Options = {"Loading..."},
            Placeholder = "Select a pet",
            MultiSelect = true,
            Flag = "AutoUnfavoritePetName",
            OnInit = function(api, optionsData)
                print("[DEBUG] AutoUnfavoritePetName OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("AutoUnfavoritePetName")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "AutoUnfavoritePetName", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "AutoUnfavoritePetName", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                updateOptions(formattedPets)
            end
        })

        -- Store reference immediately after creation
        if autoUnfavoritePetNameSelectBox then
            m.SelectBoxReferences["AutoUnfavoritePetName"] = autoUnfavoritePetNameSelectBox
            print("[DEBUG] Stored AutoUnfavoritePetName SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("AutoUnfavoritePetName")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    autoUnfavoritePetNameSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    autoUnfavoritePetNameSelectBox:Set(savedValue)
                end
            end
        end

        accordion:AddButton({
            Name = "Unfavorite Now",
            Variant = "warning",
            Callback = function()
                Inventory:UnfavoriteSelectedPets()
            end
        })
    end

    function m:AddTradeSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Trade",
            Icon = "🎟️",
            Expanded = false,
        })

        local autoGiftPetTypeSelectBox = accordion:AddSelectBox({
            Name = "Select pet type for auto gift",
            Options = {"Loading..."},
            Placeholder = "Select a pet type",
            MultiSelect = true,
            Flag = "AutoGiftPetType",
            OnInit = function(api, optionsData)
                print("[DEBUG] AutoGiftPetType OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("AutoGiftPetType")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "AutoGiftPetType", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "AutoGiftPetType", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                updateOptions(formattedPets)
            end
        })

        -- Store reference immediately after creation
        if autoGiftPetTypeSelectBox then
            m.SelectBoxReferences["AutoGiftPetType"] = autoGiftPetTypeSelectBox
            print("[DEBUG] Stored AutoGiftPetType SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("AutoGiftPetType")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    autoGiftPetTypeSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    autoGiftPetTypeSelectBox:Set(savedValue)
                end
            end
        end

        accordion:AddSeparator()

        local autoGiftPetAgeModeSelectBox = accordion:AddSelectBox({
            Name = "Age Filter Mode",
            Placeholder = "Select mode",
            Options = {"None" , "Below", "Above"},
            Default = "None",
            MultiSelect = false,
            Flag = "AutoGiftPetAgeMode",
        })

        -- Store reference immediately after creation
        if autoGiftPetAgeModeSelectBox then
            m.SelectBoxReferences["AutoGiftPetAgeMode"] = autoGiftPetAgeModeSelectBox
            print("[DEBUG] Stored AutoGiftPetAgeMode SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("AutoGiftPetAgeMode")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    autoGiftPetAgeModeSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    autoGiftPetAgeModeSelectBox:Set(savedValue)
                end
            end
        end

        local autoGiftPetAgeNumberBox = accordion:AddNumberBox({
            Name = "Age Threshold",
            Placeholder = "Enter age...",
            Default = 1,
            Min = 1,
            Max = 100,
            Increment = 1,
            Flag = "AutoGiftPetAge",
        })


        m.NumberBoxReferences["AutoGiftPetAge"] = autoGiftPetAgeNumberBox

        accordion:AddSeparator()

        local autoGiftPetWeightModeSelectBox = accordion:AddSelectBox({
            Name = "Weight Filter Mode",
            Options = {"None" , "Below", "Above"},
            Default = "None",
            Placeholder = "Select mode",
            MultiSelect = false,
            Flag = "AutoGiftPetWeightMode",
        })

        -- Store reference immediately after creation
        if autoGiftPetWeightModeSelectBox then
            m.SelectBoxReferences["AutoGiftPetWeightMode"] = autoGiftPetWeightModeSelectBox
            print("[DEBUG] Stored AutoGiftPetWeightMode SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("AutoGiftPetWeightMode")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    autoGiftPetWeightModeSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    autoGiftPetWeightModeSelectBox:Set(savedValue)
                end
            end
        end

        local autoGiftPetWeightValueNumberBox = accordion:AddNumberBox({
            Name = "Weight Threshold",
            Placeholder = "Enter weight...",
            Default = 0.0,
            Min = 0.0,
            Max = 20.0,
            Increment = 1.0,
            Decimals = 2,
            Flag = "AutoGiftPetWeightValue",
        })


        m.NumberBoxReferences["AutoGiftPetWeightValue"] = autoGiftPetWeightValueNumberBox

        accordion:AddSeparator()

        local autoGiftPlayerSelectBox = accordion:AddSelectBox({
            Name = "Select Player to Give",
            Options = {"loading ..."},
            Placeholder = "Select Player...",
            MultiSelect = false,
            Flag = "AutoGiftPlayer",
            OnInit = function(api, optionsData)
                print("[DEBUG] AutoGiftPlayer OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("AutoGiftPlayer")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "AutoGiftPlayer", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "AutoGiftPlayer", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local players = Core.Players:GetChildren()
                local formattedPlayers = {}

                for _, playerData in pairs(players) do
                    if playerData == Core.LocalPlayer then
                        continue
                    end
                    table.insert(formattedPlayers, {text = playerData.Name, value = playerData.UserId})
                end

                table.sort(formattedPlayers, function(a, b)
                    return a.text < b.text
                end)

                updateOptions(formattedPlayers)
            end
        })

        -- Store reference immediately after creation
        if autoGiftPlayerSelectBox then
            m.SelectBoxReferences["AutoGiftPlayer"] = autoGiftPlayerSelectBox
            print("[DEBUG] Stored AutoGiftPlayer SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("AutoGiftPlayer")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    autoGiftPlayerSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    autoGiftPlayerSelectBox:Set(savedValue)
                end
            end
        end

        local toggleGiftforcefavoritedpets = accordion:AddToggle({
            Name = "Force Gift Favorited Pets",
            Flag = "AutoGiftForceFavoritedPets",
            Default = false,
        })


        m.ToggleReferences["AutoGiftForceFavoritedPets"] = toggleGiftforcefavoritedpets

        accordion:AddSeparator()

        -- Quantity limit for auto gift pets
        local autoGiftPetQuantityNumberBox = accordion:AddNumberBox({
            Name = "Pet Quantity Limit (0 = Unlimited)",
            Placeholder = "Enter quantity...",
            Default = 0,
            Min = 0,
            Max = 9999,
            Increment = 1,
            Flag = "AutoGiftPetQuantity",
        })

        m.NumberBoxReferences["AutoGiftPetQuantity"] = autoGiftPetQuantityNumberBox

        -- Delay between each auto gift (in seconds)
        local autoGiftPetsDelayNumberBox = accordion:AddNumberBox({
            Name = "Auto Gift Delay (sec)",
            Placeholder = "Enter delay...",
            Default = 5,
            Min = 0,
            Max = 60,
            Increment = 1,
            Flag = "AutoGiftPetsDelay",
        })

        m.NumberBoxReferences["AutoGiftPetsDelay"] = autoGiftPetsDelayNumberBox

        local toggleGiftpets = accordion:AddToggle({
            Name = "Auto Gift Pets",
            Flag = "AutoGiftPets",
            Default = false,
            Callback = function(value)
                if value then
                    Trade:AutoGiftPets()
                end
            end
        })


        m.ToggleReferences["AutoGiftPets"] = toggleGiftpets

        accordion:AddSeparator()
        local toggleAcceptgifts = accordion:AddToggle({
            Name = "Auto Accept Gifts",
            Flag = "AutoAcceptGifts",
            Default = false,
            Callback = function(value)
                if value then
                    Trade:StartAutoAcceptGifts()
                else
                    Trade:StopAutoAcceptGifts()
                end
            end
        })

        m.ToggleReferences["AutoAcceptGifts"] = toggleAcceptgifts
    end

    function m:SeedPackSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Seed Packs",
            Icon = "🎁",
            Expanded = false,
        })

        local autoOpenSeedPackSelectBox = accordion:AddSelectBox({
            Name = "Select Seed Pack to Open",
            Options = {"Loading..."},
            Placeholder = "Select a seed pack",
            MultiSelect = false,
            Flag = "AutoOpenSeedPack",
            OnInit = function(api, optionsData)
                print("[DEBUG] AutoOpenSeedPack OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("AutoOpenSeedPack")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "AutoOpenSeedPack", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "AutoOpenSeedPack", savedValue))
                    end
                end
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local seedPacks = SeedPack:GetListAllSeedPacks()
                local formattedSeedPacks = {}

                for _, seedPackInfo in pairs(seedPacks) do
                    if seedPackInfo.Count <= 0 then
                        continue
                    end

                    table.insert(formattedSeedPacks, {
                        text = string.format("%s (%d)", seedPackInfo.Name or "Unknown", seedPackInfo.Count or 0),
                        value = seedPackInfo.Name,
                    })
                end

                updateOptions(formattedSeedPacks)
            end
        })

        -- Store reference immediately after creation
        if autoOpenSeedPackSelectBox then
            m.SelectBoxReferences["AutoOpenSeedPack"] = autoOpenSeedPackSelectBox
            print("[DEBUG] Stored AutoOpenSeedPack SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("AutoOpenSeedPack")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    autoOpenSeedPackSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    autoOpenSeedPackSelectBox:Set(savedValue)
                end
            end
        end

        local autoOpenSeedPackTotalNumberBox = accordion:AddNumberBox({
            Name = "Total Seed Pack to Open",
            Placeholder = "Enter total...",
            Default = 1,
            Min = 1,
            Max = 9999999999999999999999,
            Increment = 1,
            Flag = "AutoOpenSeedPackTotal",
        })


        m.NumberBoxReferences["AutoOpenSeedPackTotal"] = autoOpenSeedPackTotalNumberBox

        accordion:AddButton({
            Name = "Open Seed Packs Now",
            Callback = function()
                SeedPack:OpenSeedPack()
            end
        })
    end


    -- Function to refresh all toggle UI states from config
    function m:RefreshToggleStates()
        if not Window then
            warn("InventoryUI:RefreshToggleStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, toggleAPI in pairs(self.ToggleReferences) do
            local success, err = pcall(function()
                if toggleAPI and toggleAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        toggleAPI:SetValue(configValue, false)
                        print(string.format("  ✓ [Inventory] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Inventory] %s - Toggle API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Inventory] %s - Error: %s", flagName, tostring(err)))
            end
        end

        return refreshedCount
    end

    -- Function to refresh all numberbox UI states from config
    function m:RefreshNumberBoxStates()
        if not Window then
            warn("UI:RefreshNumberBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, numberBoxAPI in pairs(self.NumberBoxReferences) do
            local success, err = pcall(function()
                if numberBoxAPI and numberBoxAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        numberBoxAPI:SetValue(configValue)
                        print(string.format("  ✓ %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ %s - NumberBox API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("Refreshed %d numberboxes successfully", refreshedCount))
        return refreshedCount
    end

    return m
end

-- Module: event/new_year/quest.lua
EmbeddedModules["event/new_year/quest.lua"] = function()
    local m = {}

    local Window
    local Core

    function m:Init(coreModule, window)
        Core = coreModule
        Window = window

        Core:MakeLoop(
            function()
                return Window:GetConfigValue("AutoClaimCalendarRewards")
            end,
            function()
                self:StartAutoClaimCalendarRewards()
            end
        )
    end

    function m:StartAutoClaimCalendarRewards()
        if not Window:GetConfigValue("AutoClaimCalendarRewards") then
            return
        end

        local CalendarEvent = Core.ReplicatedStorage.GameEvents.NewYearsEvent.ClaimAdventCalendarDay

        for day = 1, 7 do
            for i = 1, 1000 do
                coroutine.wrap(function()
                    CalendarEvent:FireServer(day)
                end)()
            end
            task.wait(0.1)
        end

        task.wait(3600) -- Wait an hour before claiming again
    end

    return m

end

-- Module: notification/webhook.lua
EmbeddedModules["notification/webhook.lua"] = function()
    local m = {}

    local Window
    local Core
    local Discord

    local WEBHOOK_USERNAME = "jordi_galer  Hub"
    local WEBHOOK_AVATAR = "https://i.ibb.co.com/5X81cGVH/pandorahub-removebg-preview.png"

    local PlayerName

    function m:Init(_window, _core, _discord)
        Window = _window
        Core = _core
        Discord = _discord

        PlayerName = Core.LocalPlayer.Name or "Unknown"
    end

    function m:TestWebhook()
        local url = Window:GetConfigValue("DiscordWebhookURL") or ""
        local pingId = Window:GetConfigValue("DiscordPingID") or ""
        if url == "" then
            return
        end

        local message = {

            username = WEBHOOK_USERNAME,       
            avatar_url = WEBHOOK_AVATAR,       

            content = pingId ~= "" and ("<@"..pingId..">") or ("@everyone"),
            embeds = {{
                title = "**jordi_galerHub**",
                type = 'rich',

                color = tonumber("0xFFFF00"), 
                fields = {{
                    name = '**Profile : ** \n',
                    value = '> Username : ||'..PlayerName.."||",
                    inline = false
                }, {
                    name = '**⚠️ Notification Test**',
                    value = '> This is a test notification from jordi_galerHub.',
                    inline = false
                }}
            }}
        }

        Discord:SendMessage(url, message)
    end

    return m
end

-- Module: ../module/player.lua
EmbeddedModules["../module/player.lua"] = function()
    local m = {}

    -- Load Core module with error handling
    local Window
    local Core
    local Webhook

    local AntiAFKConnection -- Store the connection reference
    local ReconnectConnection

    local IsAutoReconnect
    local IsHasHandledDisconnect = false
    local IsHasSendReconnectWebhook = false

    local BodyGyro = nil
    local BodyVelocity = nil
    local CollisionConnection = nil

    -- Desync system
    local IsDesyncActive = false
    local DesyncConnection = nil
    local OriginalCFrame = nil

    -- Movement system state
    local MovementState = {
        ActiveCoroutine = nil,
        LastTeleportTime = 0,
        LastTargetCFrame = nil,
        CooldownDuration = 1
    }

    -- Queue system for tool equipping
    local ToolQueue = {
        Queue = {},
        IsProcessing = false,
        CurrentTask = nil
    }

    function m:Init(_window, _core, _webhook)
        if not _core then
            error("Player:Init - Core module is required")
        end
        Window = _window
        Core = _core
        Webhook = _webhook

        -- Monitor character respawn to reset physics
        Core.LocalPlayer.CharacterAdded:Connect(function(character)
            task.wait(1) -- Wait for character to fully load

            -- Reset all physics objects
            self:StopMovement()
        end)

        -- Store the connection so we can disconnect it later
        AntiAFKConnection = Core.LocalPlayer.Idled:Connect(function()
            Core.VirtualUser:CaptureController()
            Core.VirtualUser:ClickButton2(Vector2.new())
        end)

        IsAutoReconnect = Window and Window:GetConfigValue("AutoRejoinIfDisconnected") or true

        ReconnectConnection = Core.GuiService.ErrorMessageChanged:Connect(function()
            IsAutoReconnect = Window and Window:GetConfigValue("AutoRejoinIfDisconnected") or true
            if not IsAutoReconnect then
                return
            end

            if not IsHasSendReconnectWebhook then
                task.spawn(function()
                    pcall(function()
                        Webhook:DisconnectWebhook()
                    end)
                end)

                IsHasSendReconnectWebhook = true
            end

            if IsHasHandledDisconnect then
                return
            end
            IsHasHandledDisconnect = true

            task.wait(0.5) -- Wait for error dialog to appear

            for _ = 1, 5 do  -- Try multiple times
                -- Try to click the Reconnect button first
                local success = false
                pcall(function()
                    local gui = Core:GetPlayerGui()
                    if gui then
                        -- Try common error prompt paths
                        local prompts = {
                            gui:FindFirstChild("ErrorPrompt"),
                            gui:FindFirstChild("PromptDialog"),
                            gui:FindFirstChild("RobloxPromptGui")
                        }

                        for _, prompt in ipairs(prompts) do
                            if prompt then
                                -- Look for Reconnect button in various possible locations
                                local reconnectButton = prompt:FindFirstChild("Reconnect", true) or
                                                    prompt:FindFirstChild("ReconnectButton", true)

                                if reconnectButton and reconnectButton:IsA("GuiButton") then
                                    print("Found Reconnect button, attempting to click...")

                                    -- Try multiple methods to click the button
                                    -- Method 1: Fire Activated event
                                    for _, connection in pairs(getconnections(reconnectButton.Activated)) do
                                        connection:Fire()
                                        success = true
                                    end

                                    -- Method 2: Fire MouseButton1Click event
                                    if not success then
                                        for _, connection in pairs(getconnections(reconnectButton.MouseButton1Click)) do
                                            connection:Fire()
                                            success = true
                                        end
                                    end

                                    if success then
                                        print("Reconnect button clicked successfully!")
                                        return
                                    end
                                end
                            end
                        end
                    end
                end)

                -- If button click failed or not found, use Core:Rejoin as fallback
                if not success then
                    print("Reconnect button not found or failed to click, using Core:Rejoin() fallback...")
                    task.wait(1)

                    Core:Rejoin()
                end

                print("Attempting to reconnect via Core:Rejoin()...")
                task.wait(30) -- Wait before trying again
            end
        end)

        -- Initialize queue system
        ToolQueue.Queue = {}
        ToolQueue.IsProcessing = false
        ToolQueue.CurrentTask = nil
    end

    function m:RemoveAntiAFK()
        -- Disconnect the stored connection
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
    end

    function m:RemoveReconnect()
        if ReconnectConnection then
            ReconnectConnection:Disconnect()
            ReconnectConnection = nil
        end
    end

    -- ===== QUEUE SYSTEM =====

    -- Add task to queue
    -- tool: Tool object to equip
    -- priority: Number (lower = higher priority, default = 5)
    -- taskFunction: Function to execute after tool is equipped (optional)
    -- callback: Function to call when task is complete (optional)
    function m:AddToQueue(_tool, _priority, _taskFunction, _callback)
        _priority = _priority or 5

        if not _tool or not _tool:IsA("Tool") then
            warn("Player:AddToQueue - Invalid tool provided")
            if _callback then _callback(false, "Invalid tool") end
            return false
        end

        local task = {
            Id = tick(), -- Unique identifier
            Tool = _tool,
            Priority = _priority,
            TaskFunction = _taskFunction,
            Callback = _callback,
            Timestamp = tick()
        }

        -- Insert task into queue
        table.insert(ToolQueue.Queue, task)

        -- Start processing if not already processing
        if not ToolQueue.IsProcessing then
            self:ProcessQueue()
        end

        return true
    end

    -- Reset queue if stuck (can be called externally)
    function m:ResetQueue()
        ToolQueue.IsProcessing = false
        ToolQueue.CurrentTask = nil
        -- Call callbacks for remaining tasks to prevent deadlocks
        for _, task in ipairs(ToolQueue.Queue) do
            if task.Callback then
                pcall(task.Callback, false, "Queue reset")
            end
        end
        ToolQueue.Queue = {}
        warn("Player:ResetQueue - Queue has been reset")
    end

    -- Process the queue
    function m:ProcessQueue()
        if ToolQueue.IsProcessing or #ToolQueue.Queue == 0 then
            return -- Already processing or queue is empty
        end

        ToolQueue.IsProcessing = true

        -- Wrap entire processing in pcall to ensure IsProcessing is reset on error
        local processSuccess, processErr = pcall(function()
            while #ToolQueue.Queue > 0 do
                -- Sort queue by priority and timestamp to ensure correct order
                table.sort(ToolQueue.Queue, function(a, b)
                    if a.Priority == b.Priority then
                        return a.Timestamp < b.Timestamp -- Earlier added first
                    end
                    return a.Priority < b.Priority -- Lower priority number first
                end)
                local currentTask = table.remove(ToolQueue.Queue, 1) -- Take first (highest priority) task
                ToolQueue.CurrentTask = currentTask

                -- Equip the tool, ensure it is equipped before proceeding
                if self:GetEquippedTool() ~= currentTask.Tool then
                    self:EquipTool(currentTask.Tool)
                    task.wait(0.5) -- Small delay to ensure tool is equipped
                end

                -- Execute task function if provided and wait for completion
                local success, result = pcall(function()
                    return currentTask.TaskFunction()
                end)

                if currentTask.Callback then
                    local callbackSuccess, callbackErr = pcall(currentTask.Callback, success, result)
                    if not callbackSuccess then
                        warn("Callback error for tool:", currentTask.Tool.Name, "Error:", callbackErr)
                    end
                end

                -- task.wait(0.5)
                self:UnequipTool() -- Unequip after task

                ToolQueue.CurrentTask = nil
                task.wait(0.1) -- Small delay between tasks
            end
        end)

        -- Always reset IsProcessing, even if there was an error
        ToolQueue.IsProcessing = false
        ToolQueue.CurrentTask = nil

        if not processSuccess then
            warn("Player:ProcessQueue - Error during processing:", processErr)
        end
    end

    -- Get current queue status
    function m:GetQueueStatus()
        return {
            queueSize = #ToolQueue.Queue,
            isProcessing = ToolQueue.IsProcessing,
            currentTask = ToolQueue.CurrentTask and ToolQueue.CurrentTask.Tool.Name or nil
        }
    end

    -- Clear the queue
    function m:ClearQueue()
        ToolQueue.Queue = {}
        ToolQueue.IsProcessing = false
        ToolQueue.CurrentTask = nil
    end

    -- Remove specific task from queue by tool name
    function m:RemoveFromQueue(_toolName)
        if not _toolName then return false end

        for i = #ToolQueue.Queue, 1, -1 do
            if ToolQueue.Queue[i].Tool.Name == _toolName then
                table.remove(ToolQueue.Queue, i)
                return true
            end
        end

        return false
    end

    function m:GetTaskByTool(_tool)
        local tasks = {}
        if not _tool then return nil end

        for _, task in ipairs(ToolQueue.Queue) do
            if task.Tool == _tool then
                table.insert(tasks, task)
            end
        end

        return #tasks > 0 and tasks or nil
    end

    function m:EquipTool(_tool)
        -- Validate inputs
        if not _tool or not _tool:IsA("Tool") then 
            warn("Player:EquipTool - Invalid tool provided")
            return false 
        end

        local humanoid = Core:GetHumanoid()
        local backpack = Core:GetBackpack()

        if not humanoid then
            warn("Player:EquipTool - Humanoid not found")
            return false
        end

        if not backpack then
            warn("Player:EquipTool - Backpack not found")
            return false
        end

        if _tool.Parent ~= backpack then
            warn("Player:EquipTool - Tool not in backpack")
            return false 
        end

        -- Try to equip with error handling
        local success, err = pcall(function()
            humanoid:EquipTool(_tool)
        end)

        if not success then
            warn("Player:EquipTool - Failed to equip:", err)
            return false
        end

        return true
    end

    function m:UnequipTool()
        local humanoid = Core:GetHumanoid()
        if not humanoid then
            warn("Player:UnequipTool - Humanoid not found")
            return false
        end

        -- Try to unequip with error handling
        local success, err = pcall(function()
            humanoid:UnequipTools()
        end)

        if not success then
            warn("Player:UnequipTool - Failed to unequip:", err)
            return false
        end

        return true
    end

    function m:GetEquippedTool()
        local character = Core:GetCharacter()
        if not character then 
            warn("Player:GetEquippedTool - Character not found")
            return nil 
        end

        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                return item
            end
        end

        return nil
    end

    function m:MoveToPosition(_position)
        local humanoid = Core:GetHumanoid()
        if humanoid then
            humanoid:MoveTo(_position)
        else
            warn("Player:MoveToPosition - Humanoid not found")
        end
    end

    function m:MoveToTarget(_target, _onStepCallback, _distanceMode, _distance, _speed)
        if not _target then
            return
        end

        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            return
        end

        local humanoid = Core:GetHumanoid()
        if not humanoid then
            return
        end

        _speed = _speed or 50 -- Default speed

        -- Setup continuous collision disable
        if not CollisionConnection or not CollisionConnection.Connected then
            CollisionConnection = Core.Heartbeat:Connect(function()
                local character = Core:GetCharacter()
                if character then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end

        -- Setup flying with BodyGyro and BodyVelocity
        if not BodyGyro or not BodyGyro.Parent then
            BodyGyro = Instance.new('BodyGyro')
            BodyGyro.P = 9e4
            BodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            BodyGyro.cframe = hrp.CFrame
            BodyGyro.Parent = hrp
        end

        if not BodyVelocity or not BodyVelocity.Parent then
            BodyVelocity = Instance.new('BodyVelocity')
            BodyVelocity.velocity = Vector3.new(0, 0, 0)
            BodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
            BodyVelocity.Parent = hrp
        end

        -- Enable flying mode
        humanoid.PlatformStand = true

        -- Apply distance mode
        _distanceMode = (_distanceMode and _distanceMode:lower()) or "exact" -- "exact", "below", "above"
        _distance = _distance or 0

        -- Get target position - try HumanoidRootPart first (for enemies), then use GetPivot (for rocks/models)
        local targetPos
        local targetHrp = _target:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            targetPos = targetHrp.Position
        else
            -- For models without HumanoidRootPart (like rocks)
            targetPos = _target:GetPivot().Position
        end

        local finalTargetPos = targetPos
        if _distanceMode == "below" then
            -- Move below target (decrease Y position)
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y - _distance, targetPos.Z)
        elseif _distanceMode == "above" then
            -- Move above target (increase Y position)
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y + _distance, targetPos.Z)
        end

        -- Use Humanoid:MoveTo() for pathfinding-based movement
        humanoid:MoveTo(finalTargetPos)

        -- Continuously update position to fly through obstacles
        local moveConnection
        moveConnection = Core.Heartbeat:Connect(function()
            if not _target or not _target.Parent then
                if moveConnection then moveConnection:Disconnect() end
                return
            end

            if _onStepCallback and not _onStepCallback() then
                if moveConnection then moveConnection:Disconnect() end
                return
            end

            local currentPos = hrp.Position
            local direction = (finalTargetPos - currentPos).Unit
            local distance = (finalTargetPos - currentPos).Magnitude

            -- Stop when close enough
            if distance < 2 then
                if moveConnection then moveConnection:Disconnect() end
                if BodyVelocity and BodyVelocity.Parent then
                    BodyVelocity.velocity = Vector3.new(0, 0, 0)
                end
                return
            end

            -- Calculate CFrame facing the enemy
            local lookCFrame = CFrame.lookAt(currentPos, targetPos)

            -- Update BodyGyro and BodyVelocity for smooth flying through obstacles
            if BodyGyro and BodyGyro.Parent then
                BodyGyro.cframe = lookCFrame
            end
            if BodyVelocity and BodyVelocity.Parent then
                BodyVelocity.velocity = direction * _speed
            end
        end)

        -- Wait for movement to complete
        local maxWaitTime = 10 -- Maximum 10 seconds
        local waitedTime = 0
        while waitedTime < maxWaitTime do
            if not _target or not _target.Parent then break end
            if _onStepCallback and not _onStepCallback() then break end

            local currentPos = hrp.Position
            local distance = (finalTargetPos - currentPos).Magnitude
            if distance < 2 then break end

            task.wait(0.1)
            waitedTime = waitedTime + 0.1
        end

        -- Cleanup
        if moveConnection then
            moveConnection:Disconnect()
        end

        -- Stop movement
        if BodyVelocity and BodyVelocity.Parent then
            BodyVelocity.velocity = Vector3.new(0, 0, 0)
        end
    end

    -- Tween-based movement system
    function m:TweenToPosition(_position, _duration, _easingStyle, _easingDirection)
        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            warn("Player:TweenToPosition - HumanoidRootPart not found")
            return false
        end

        -- Convert Vector3 to CFrame if needed
        local targetCFrame
        if typeof(_position) == "Vector3" then
            targetCFrame = CFrame.new(_position)
        elseif typeof(_position) == "CFrame" then
            targetCFrame = _position
        else
            warn("Player:TweenToPosition - Invalid position type")
            return false
        end

        -- Default tween settings
        _duration = _duration or 1
        _easingStyle = _easingStyle or Enum.EasingStyle.Linear
        _easingDirection = _easingDirection or Enum.EasingDirection.Out

        -- Disable collision during tween
        local collisionDisable = Core.Heartbeat:Connect(function()
            local character = Core:GetCharacter()
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)

        -- Create tween
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(
            _duration,
            _easingStyle,
            _easingDirection,
            0, -- Repeat count
            false, -- Reverse
            0 -- Delay
        )

        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})

        -- Play tween
        tween:Play()

        -- Wait for tween to complete
        tween.Completed:Wait()

        -- Cleanup
        if collisionDisable then
            collisionDisable:Disconnect()
        end

        return true
    end

    -- Tween to target with distance mode
    function m:TweenToTarget(_target, _duration, _distanceMode, _distance, _easingStyle, _easingDirection)
        if not _target then
            warn("Player:TweenToTarget - No target provided")
            return false
        end

        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            warn("Player:TweenToTarget - HumanoidRootPart not found")
            return false
        end

        -- Get target position
        local targetPos
        local targetHrp = _target:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            targetPos = targetHrp.Position
        else
            -- For models without HumanoidRootPart (like rocks)
            local success, pos = pcall(function() return _target:GetPivot().Position end)
            if success then
                targetPos = pos
            else
                warn("Player:TweenToTarget - Cannot get target position")
                return false
            end
        end

        -- Apply distance mode
        _distanceMode = (_distanceMode and _distanceMode:lower()) or "exact"
        _distance = _distance or 0

        local finalTargetPos = targetPos
        if _distanceMode == "below" then
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y - _distance, targetPos.Z)
        elseif _distanceMode == "above" then
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y + _distance, targetPos.Z)
        end

        -- Calculate look direction for CFrame
        local currentPos = hrp.Position
        local lookCFrame = CFrame.lookAt(finalTargetPos, targetPos)

        -- Tween to position
        return self:TweenToPosition(lookCFrame, _duration, _easingStyle, _easingDirection)
    end

    -- Tween with callback for each step
    function m:TweenToTargetWithCallback(_target, _duration, _distanceMode, _distance, _onStepCallback, _easingStyle, _easingDirection)
        if not _target then
            warn("Player:TweenToTargetWithCallback - No target provided")
            return false
        end

        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            warn("Player:TweenToTargetWithCallback - HumanoidRootPart not found")
            return false
        end

        -- Get target position
        local targetPos
        local targetHrp = _target:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            targetPos = targetHrp.Position
        else
            local success, pos = pcall(function() return _target:GetPivot().Position end)
            if success then
                targetPos = pos
            else
                warn("Player:TweenToTargetWithCallback - Cannot get target position")
                return false
            end
        end

        -- Apply distance mode
        _distanceMode = (_distanceMode and _distanceMode:lower()) or "exact"
        _distance = _distance or 0

        local finalTargetPos = targetPos
        if _distanceMode == "below" then
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y - _distance, targetPos.Z)
        elseif _distanceMode == "above" then
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y + _distance, targetPos.Z)
        end

        -- Calculate look direction for CFrame
        local lookCFrame = CFrame.lookAt(finalTargetPos, targetPos)

        -- Default settings
        _duration = _duration or 1
        _easingStyle = _easingStyle or Enum.EasingStyle.Linear
        _easingDirection = _easingDirection or Enum.EasingDirection.Out

        -- Disable collision during tween
        local collisionDisable = Core.Heartbeat:Connect(function()
            local character = Core:GetCharacter()
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)

        -- Create tween
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(
            _duration,
            _easingStyle,
            _easingDirection,
            0,
            false,
            0
        )

        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = lookCFrame})

        -- Monitor tween progress with callback
        local cancelTween = false
        local monitorConnection
        if _onStepCallback then
            monitorConnection = Core.Heartbeat:Connect(function()
                if not _onStepCallback() then
                    cancelTween = true
                    tween:Cancel()
                    if monitorConnection then
                        monitorConnection:Disconnect()
                    end
                end
            end)
        end

        -- Play tween
        tween:Play()

        -- Wait for tween to complete or cancel
        tween.Completed:Wait()

        -- Cleanup
        if monitorConnection then
            monitorConnection:Disconnect()
        end
        if collisionDisable then
            collisionDisable:Disconnect()
        end

        return not cancelTween
    end

    -- ===== HYBRID ASYNC TWEEN SYSTEM =====
    -- Advanced async tween-based movement with coroutines
    -- Returns: coroutine reference (can be cancelled with CancelMovement)
    -- Basic usage
    -- Player:AsyncTweenToTarget(rockInstance, {
    --     speed = 0.9,
    --     distanceMode = "below",
    --     distance = 7
    -- })
    -- Advanced dengan semua fitur
    -- local moveRef = Player:AsyncTweenToTarget(rockInstance, {
    --     speed = 1.2,
    --     distanceMode = "below",
    --     distance = 7,
    --     conditionCallback = function()
    --         return Window:GetConfigValue("AutoMineRocks") and rockInstance.Parent
    --     end,
    --     breakWhenReached = false,
    --     cooldown = 0.5,
    --     onComplete = function()
    --         Window:ShowInfo("Mining", "Arrived at rock!")
    --     end
    -- })
    -- Cancel manual jika perlu
    -- if someCondition then
    --     Player:CancelMovement()
    -- end
    function m:AsyncTweenToTarget(_target, _options)
        -- Validate target
        if not _target then
            warn("Player:AsyncTweenToTarget - No target provided")
            return nil
        end

        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            warn("Player:AsyncTweenToTarget - HumanoidRootPart not found")
            return nil
        end

        local character = Core:GetCharacter()
        if not character or not character.PrimaryPart then
            warn("Player:AsyncTweenToTarget - Invalid character")
            return nil
        end

        -- Parse options with defaults
        _options = _options or {}
        local speed = _options.speed or 0.9
        local distanceMode = (_options.distanceMode and _options.distanceMode:lower()) or "exact"
        local distance = _options.distance or 0
        local lookAt = _options.lookAt -- Optional lookAt position
        local conditionCallback = _options.conditionCallback -- Function that returns true to continue
        local breakWhenReached = _options.breakWhenReached or false
        local cooldown = _options.cooldown or 1
        local onComplete = _options.onComplete -- Callback when movement completes

        -- Get target position
        local targetPos
        local targetHrp = _target:FindFirstChild("HumanoidRootPart")
        if targetHrp then
            targetPos = targetHrp.Position
        else
            local success, pos = pcall(function() return _target:GetPivot().Position end)
            if success then
                targetPos = pos
            else
                warn("Player:AsyncTweenToTarget - Cannot get target position")
                return nil
            end
        end

        -- Apply distance mode
        local finalTargetPos = targetPos
        if distanceMode == "below" then
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y - distance, targetPos.Z)
        elseif distanceMode == "above" then
            finalTargetPos = Vector3.new(targetPos.X, targetPos.Y + distance, targetPos.Z)
        end

        local targetCFrame = CFrame.new(finalTargetPos)

        -- Cooldown check - prevent spam
        local currentTime = tick()
        if (currentTime - MovementState.LastTeleportTime) < cooldown and 
           targetCFrame == MovementState.LastTargetCFrame then
            warn("Player:AsyncTweenToTarget - Cooldown active")
            return nil
        end

        -- Cancel previous movement if active
        if MovementState.ActiveCoroutine then
            coroutine.close(MovementState.ActiveCoroutine)
            MovementState.ActiveCoroutine = nil
        end

        -- Update movement state
        MovementState.LastTeleportTime = currentTime
        MovementState.LastTargetCFrame = targetCFrame

        -- Create collision disable connection
        local collisionDisable = Core.Heartbeat:Connect(function()
            local char = Core:GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)

        -- Create coroutine for async movement
        local moveCoroutine = coroutine.create(function()
            local rootPart = character.PrimaryPart
            local currentPos = rootPart.Position
            local targetPosition = finalTargetPos
            local distanceRemaining = (targetPosition - currentPos).Magnitude

            while task.wait() do
                -- Validate character still exists
                if not rootPart or not rootPart.Parent then
                    break
                end

                -- Check condition callback
                if conditionCallback and type(conditionCallback) == "function" then
                    local success, shouldContinue = pcall(conditionCallback)
                    if not success or not shouldContinue then
                        break
                    end
                end

                -- Break if reached and configured to stop
                if breakWhenReached and distanceRemaining <= 0.5 then
                    break
                end

                -- Calculate movement step
                local step = math.min(speed, distanceRemaining)
                local direction = targetPosition - currentPos
                local directionNormal = direction / math.max(direction.Magnitude, 0.0001)

                currentPos = currentPos + (directionNormal * step)
                distanceRemaining = (targetPosition - currentPos).Magnitude

                -- Set position with optional lookAt
                if lookAt then
                    rootPart.CFrame = CFrame.new(currentPos, lookAt)
                else
                    -- Look at target by default
                    rootPart.CFrame = CFrame.new(currentPos, targetPosition)
                end

                -- Reset physics (modern Assembly properties)
                if rootPart:FindFirstChild("AssemblyLinearVelocity") ~= nil then
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                    rootPart.AssemblyAngularVelocity = Vector3.zero
                else
                    -- Fallback for older velocity properties
                    if rootPart:FindFirstChild("Velocity") then
                        rootPart.Velocity = Vector3.zero
                    end
                    if rootPart:FindFirstChild("RotVelocity") then
                        rootPart.RotVelocity = Vector3.zero
                    end
                end
            end

            -- Cleanup
            if collisionDisable then
                collisionDisable:Disconnect()
            end

            -- Call completion callback
            if onComplete and type(onComplete) == "function" then
                pcall(onComplete)
            end

            -- Clear active coroutine reference
            if MovementState.ActiveCoroutine == moveCoroutine then
                MovementState.ActiveCoroutine = nil
            end
        end)

        -- Store and start coroutine
        MovementState.ActiveCoroutine = moveCoroutine
        coroutine.resume(moveCoroutine)

        return moveCoroutine
    end

    -- Cancel active movement
    function m:CancelMovement()
        if MovementState.ActiveCoroutine then
            coroutine.close(MovementState.ActiveCoroutine)
            MovementState.ActiveCoroutine = nil
            return true
        end
        return false
    end

    -- Check if movement is active
    function m:IsMovementActive()
        return MovementState.ActiveCoroutine ~= nil
    end

    -- Set movement cooldown duration
    function m:SetMovementCooldown(_duration)
        if type(_duration) == "number" and _duration >= 0 then
            MovementState.CooldownDuration = _duration
            return true
        end
        return false
    end

    function m:StopMovement()
        -- Disable flying mode
        local humanoid = Core:GetHumanoid()
        if humanoid then
            humanoid.PlatformStand = false
        end

        -- Cleanup BodyGyro and BodyVelocity
        if BodyGyro then
            BodyGyro:Destroy()
            BodyGyro = nil
        end

        if BodyVelocity then
            BodyVelocity:Destroy()
            BodyVelocity = nil
        end

        -- Disconnect collision disable
        if CollisionConnection then
            CollisionConnection:Disconnect()
            CollisionConnection = nil
        end
    end

    function m:TeleportToPosition(_position)
        local hrp = Core:GetHumanoidRootPart()
        if hrp then
            if typeof(_position) == "Vector3" then
                hrp.CFrame = CFrame.new(_position)
            elseif typeof(_position) == "CFrame" then
                hrp.CFrame = _position
            else
                warn("Player:TeleportToPosition - Invalid position type")
                return false
            end
            return true
        end
        return false
    end

    function m:GetPosition()
        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            warn("Player:GetPosition - HumanoidRootPart not found")
            return CFrame.new(0, 0, 0)
        end

        return hrp.CFrame or CFrame.new(0, 0, 0)
    end

    function m:GetAllTools()
        local backpack = Core:GetBackpack()
        if not backpack then 
            warn("Player:GetAllTools - Backpack not found")
            return {} 
        end

        local tools = {}
        local success, err = pcall(function()
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then
                    table.insert(tools, item)
                end
            end
        end)

        if not success then
            warn("Player:GetAllTools - Error getting tools:", err)
            return {}
        end

        return tools
    end

    function m:GetTool(_toolName)
        if not _toolName or type(_toolName) ~= "string" then
            warn("Player:GetTool - Invalid tool name")
            return nil
        end

        local backpack = Core:GetBackpack()
        if not backpack then
            warn("Player:GetTool - Backpack not found")
            return nil 
        end

        local tool = nil
        local success, err = pcall(function()
            tool = backpack:FindFirstChild(_toolName)
            if tool and not tool:IsA("Tool") then
                tool = nil
            end
        end)

        if not success then
            warn("Player:GetTool - Error finding tool:", err)
            return nil
        end

        if not tool then
            warn("Player:GetTool - Tool not found:", _toolName)
        end

        return tool
    end

    -- ===== DESYNC SYSTEM =====

    -- Enable desync - makes player appear in a different position on client vs server
    -- offset: Vector3 offset from actual position (default: Vector3.new(0, -10, 0))
    function m:EnableDesync(_offset)
        if IsDesyncActive then
            warn("Player:EnableDesync - Desync already active")
            return false
        end

        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            warn("Player:EnableDesync - HumanoidRootPart not found")
            return false
        end

        _offset = _offset or Vector3.new(0, -10, 0)

        -- Store original CFrame
        OriginalCFrame = hrp.CFrame

        -- Create desync effect using RunService
        IsDesyncActive = true
        DesyncConnection = Core.Heartbeat:Connect(function()
            local currentHrp = Core:GetHumanoidRootPart()
            if not currentHrp then
                self:DisableDesync()
                return
            end

            -- Offset the visual position while keeping actual server position
            -- This only affects client-side rendering
            currentHrp.CFrame = currentHrp.CFrame + _offset
        end)

        return true
    end

    -- Disable desync and restore normal position
    function m:DisableDesync()
        if not IsDesyncActive then
            return false
        end

        -- Disconnect heartbeat connection
        if DesyncConnection then
            DesyncConnection:Disconnect()
            DesyncConnection = nil
        end

        -- Restore original CFrame if available
        if OriginalCFrame then
            local hrp = Core:GetHumanoidRootPart()
            if hrp then
                hrp.CFrame = OriginalCFrame
            end
            OriginalCFrame = nil
        end

        IsDesyncActive = false
        return true
    end

    -- Toggle desync on/off
    function m:ToggleDesync(_offset)
        if IsDesyncActive then
            return self:DisableDesync()
        else
            return self:EnableDesync(_offset)
        end
    end

    -- Check if desync is active
    function m:IsDesyncActive()
        return IsDesyncActive
    end

    -- Advanced desync with custom update function
    -- updateFunction: function(hrp) that returns new CFrame for hrp
    function m:EnableCustomDesync(_updateFunction)
        if IsDesyncActive then
            warn("Player:EnableCustomDesync - Desync already active")
            return false
        end

        if type(_updateFunction) ~= "function" then
            warn("Player:EnableCustomDesync - Invalid update function")
            return false
        end

        local hrp = Core:GetHumanoidRootPart()
        if not hrp then
            warn("Player:EnableCustomDesync - HumanoidRootPart not found")
            return false
        end

        IsDesyncActive = true
        DesyncConnection = Core.Heartbeat:Connect(function()
            local currentHrp = Core:GetHumanoidRootPart()
            if not currentHrp then
                self:DisableDesync()
                return
            end

            local success, newCFrame = pcall(_updateFunction, currentHrp)
            if success and newCFrame and typeof(newCFrame) == "CFrame" then
                currentHrp.CFrame = newCFrame
            end
        end)

        return true
    end

    return m
end

-- Module: ../module/discord.lua
EmbeddedModules["../module/discord.lua"] = function()
    local m = {}
    local HttpService = game:GetService("HttpService")

    function m:SendMessage(webhookUrl, data)
        -- Mencari fungsi request yang tersedia dari berbagai executor
        local requestFunction = request or
                               (syn and syn.request) or
                               (http and http.request) or
                               (fluxus and fluxus.request) or
                               http_request

        -- Jika tidak ada fungsi request yang tersedia, keluar dari fungsi
        if not requestFunction then
            return
        end

        -- Mengubah data menjadi format JSON
        local jsonData = HttpService:JSONEncode(data)

        -- Menyiapkan headers untuk request
        local headers = {
            ['Content-Type'] = "application/json"
        }

        -- Mengirim POST request ke webhook
        local success, err = pcall(function()
            task.spawn(requestFunction, {
                Url = webhookUrl,
                Body = jsonData,
                Method = 'POST',
                Headers = headers
            })
        end)

        if success then
            print("Discord webhook sent successfully.")
        else
            warn("Failed to send Discord webhook:", err)
        end
    end

    return m

end

-- Module: rarity.lua
EmbeddedModules["rarity.lua"] = function()
    local m = {}

    m.RarityOrder = {
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3,
        ["Legendary"] = 4,
        ["Mythical"] = 5,
        ["Divine"] = 6,
        ["Prismatic"] = 7,
        ["Transcendent"] = 8
    }

    return m
end

-- Module: misc/ui.lua
EmbeddedModules["misc/ui.lua"] = function()
    local m = {}
    local Window
    local Core
    local Player
    local Garden
    local Remove
    local ESP
    local Cosmetic
    local PlayerData
    local Teleport


    -- Store ALL toggle references for config sync after reconnect
    m.ToggleReferences = {}
    m.NumberBoxReferences = {}

    function m:Init(_window, _core, _player, _garden, _remove, _esp, _cosmetic, _playerData, _teleport)
        Window = _window
        Core = _core
        Player = _player
        Garden = _garden
        Remove = _remove
        ESP = _esp
        Cosmetic = _cosmetic
        PlayerData = _playerData
        Teleport = _teleport

        local tab = Window:AddTab({
            Name = "Misc",
            Icon = "⚙️",
        })

        self:ServerSection(tab)
        self:PerformanceSection(tab)
        self:ESPSection(tab)
        self:RemoveSections(tab)
        self:GameUpdateSection(tab)
        self:CosmeticSection(tab)
        self:TeleportSection(tab)
        self:FarmersMarketSection(tab)
        -- self:PlayerDataSection(tab)
    end

    function m:ServerSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Server",
            Icon = "🌐",
            Default = false,
        })

        local toggleRejoinifdisconnected = accordion:AddToggle({
            Name = "Auto Rejoin If Disconnected 🔄",
            Default = true,
            Flag = "AutoRejoinIfDisconnected",
        })


        m.ToggleReferences["AutoRejoinIfDisconnected"] = toggleRejoinifdisconnected

        local toggleExecutescriptsonjoin = accordion:AddToggle({
            Name = "Auto Execute Scripts On Join ⚡",
            Default = true,
            Flag = "AutoExecuteScriptsOnJoin",
        })


        m.ToggleReferences["AutoExecuteScriptsOnJoin"] = toggleExecutescriptsonjoin

        accordion:AddButton({Text = "Rejoin Server 🔄", Callback = function()
            Core:Rejoin()
        end})

        accordion:AddButton({Text = "Hop Server 🚀", Callback = function()
            Core:HopServer()
        end})
    end

    function m:GameUpdateSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Game Updates",
            Icon = "📰",
            Default = false,
        })

        accordion:AddSelectBox({
            Name = "Update Directory",
            Options = {"Root", "Update"},
            Flag = "UpdateDirectory",
            MultiSelect = false,
            Default = "Root",
        })

        accordion:AddButton({Text = "Force Update", Callback = function()
            local listUpdate = Core.ReplicatedStorage.Modules.UpdateService
            if not listUpdate then
                Window:ShowWarning("Force Update", "Can't Find Update Service. Update Aborted.")
                return
            end

            local workspace = game:GetService("Workspace")
            local Interaction = workspace:FindFirstChild("Interaction")
            if not Interaction then
                local folder = Instance.new("Folder")
                folder.Name = "Interaction"
                folder.Parent = workspace
                Window:ShowWarning("Force Update", "Can't Find Interaction Folder.")
            end

            local updateItems = Interaction:FindFirstChild("UpdateItems")
            if not updateItems then
                local folder = Instance.new("Folder")
                folder.Name = "UpdateItems"
                folder.Parent = Interaction
            end

            for _, v in pairs(listUpdate:GetChildren()) do
                local clonedItem = v:Clone()

                if Window:GetConfigValue("UpdateDirectory") == "Update" then
                    clonedItem.Parent = updateItems
                end

                if Window:GetConfigValue("UpdateDirectory") == "Root" then
                    clonedItem.Parent = workspace
                end

                -- Copy ProximityPrompt if exists
                local proximityPrompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                if proximityPrompt then
                    local clonedPrompt = proximityPrompt:Clone()
                    local targetPart = clonedItem:FindFirstChild(proximityPrompt.Parent.Name)
                    if targetPart then
                        clonedPrompt.Parent = targetPart
                    else
                        clonedPrompt.Parent = clonedItem
                    end
                end
            end
        end})
    end

    -- function m:ConfigSection(tab)
    --     local accordion = tab:AddAccordion({
    --         Title = "Config",
    --         Icon = "💾",
    --         Default = false,
    --     })

    --     accordion:AddButton({Text = "Reset Config 🔄", Callback = function()
    --         local configKeys = Window:GetAllConfigKeys()

    --         for _, key in ipairs(configKeys) do
    --             Window:DeleteConfigKey(key)
    --         end
    --     end})
    -- end

    function m:RemoveSections(tab)
        local accordion = tab:AddAccordion({
            Title = "Remove",
            Icon = "❌",
            Default = false,
        })

        local toggleRemovesystemnotifications = accordion:AddToggle({
            Name = "Remove System Notifications 🔕",
            Default = false,
            Flag = "RemoveSystemNotifications",
            Callback = function(value)
                Remove:RemoveSystemNotifications()
            end
        })


        m.ToggleReferences["RemoveSystemNotifications"] = toggleRemovesystemnotifications
    end

    function m:PerformanceSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Performance",
            Icon = "⚡",
            Default = false,
        })

        -- Hide My Garden Plants
        local toggleHideMyPlants = accordion:AddToggle({
            Name = "Hide My Garden Plants",
            Default = false,
            Flag = "HideMyGardenPlants",
            Callback = function(value)
                if value then
                    Garden:HideMyGardenPlants()
                else
                    Garden:ShowMyGardenPlants()
                end
            end
        })
        m.ToggleReferences["HideMyGardenPlants"] = toggleHideMyPlants

        -- Hide Other Gardens Plants
        local toggleHideOtherPlants = accordion:AddToggle({
            Name = "Hide Other Gardens Plants",
            Default = false,
            Flag = "HideOtherGardenPlants",
            Callback = function(value)
                if value then
                    Garden:HideOtherGardenPlants()
                else
                    Garden:ShowOtherGardenPlants()
                end
            end
        })
        m.ToggleReferences["HideOtherGardenPlants"] = toggleHideOtherPlants

        -- Hide My Garden Objects (sprinklers, etc)
        local toggleHideMyObjects = accordion:AddToggle({
            Name = "Hide My Garden Objects",
            Default = false,
            Flag = "HideMyGardenObjects",
            Callback = function(value)
                if value then
                    Garden:HideMyGardenObjects()
                else
                    Garden:ShowMyGardenObjects()
                end
            end
        })
        m.ToggleReferences["HideMyGardenObjects"] = toggleHideMyObjects

        -- Hide Other Gardens Objects
        local toggleHideOtherObjects = accordion:AddToggle({
            Name = "Hide Other Gardens Objects",
            Default = false,
            Flag = "HideOtherGardenObjects",
            Callback = function(value)
                if value then
                    Garden:HideOtherGardenObjects()
                else
                    Garden:ShowOtherGardenObjects()
                end
            end
        })
        m.ToggleReferences["HideOtherGardenObjects"] = toggleHideOtherObjects

        accordion:AddSeparator()

        -- Remove Spider Web FX (from spider pet skill)
        local toggleRemoveSpiderWebFX = accordion:AddToggle({
            Name = "Remove Spider Webs",
            Default = false,
            Flag = "RemoveSpiderWebFX",
            Callback = function(value)
                if value then
                    Remove:StartAutoRemoveSpiderWebFX()
                else
                    Remove:StopAutoRemoveSpiderWebFX()
                end
            end
        })
        m.ToggleReferences["RemoveSpiderWebFX"] = toggleRemoveSpiderWebFX

        -- Setup auto-remove for spider web FX
        Core:MakeLoop(function()
            return Window:GetConfigValue("RemoveSpiderWebFX")
        end, function()
            Remove:RemoveSpiderWebFX()
        end, 1) -- Run every 1 second to catch new spider webs

        accordion:AddSeparator()

        -- Button to refresh/reapply hiding
        accordion:AddButton({Text = "Refresh Plant Visibility", Callback = function()
            local hideMyPlants = Window:GetConfigValue("HideMyGardenPlants")
            local hideOtherPlants = Window:GetConfigValue("HideOtherGardenPlants")
            local hideMyObjects = Window:GetConfigValue("HideMyGardenObjects")
            local hideOtherObjects = Window:GetConfigValue("HideOtherGardenObjects")

            if hideMyPlants then
                Garden:HideMyGardenPlants()
            end
            if hideOtherPlants then
                Garden:HideOtherGardenPlants()
            end
            if hideMyObjects then
                Garden:HideMyGardenObjects()
            end
            if hideOtherObjects then
                Garden:HideOtherGardenObjects()
            end

            Window:ShowInfo("Performance", "Plant visibility refreshed!")
        end})

        -- Setup auto-hide for new plants
        Core:MakeLoop(function()
            return Window:GetConfigValue("HideMyGardenPlants") or
                   Window:GetConfigValue("HideOtherGardenPlants") or
                   Window:GetConfigValue("HideMyGardenObjects") or
                   Window:GetConfigValue("HideOtherGardenObjects")
        end, function()
            local hideMyPlants = Window:GetConfigValue("HideMyGardenPlants")
            local hideOtherPlants = Window:GetConfigValue("HideOtherGardenPlants")
            local hideMyObjects = Window:GetConfigValue("HideMyGardenObjects")
            local hideOtherObjects = Window:GetConfigValue("HideOtherGardenObjects")

            if hideMyPlants then
                Garden:HideMyGardenPlants()
            end
            if hideOtherPlants then
                Garden:HideOtherGardenPlants()
            end
            if hideMyObjects then
                Garden:HideMyGardenObjects()
            end
            if hideOtherObjects then
                Garden:HideOtherGardenObjects()
            end
        end, 5) -- Run every 5 seconds to catch new plants
    end

    function m:ESPSection(tab)
        local accordion = tab:AddAccordion({
            Title = "ESP",
            Icon = "👁️",
            Default = false,
        })

        local toggleEggesp = accordion:AddToggle({
            Name = "Egg ESP 🥚",
            Default = false,
            Flag = "EggESP",
            Callback = function(value)
                if value then
                    ESP:CreateEggESP()
                else
                    ESP:RemoveEggESP()
                end
            end
        })


        m.ToggleReferences["EggESP"] = toggleEggesp
    end

    function m:CosmeticSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Placing Cosmetic",
            Icon = "🎨",
            Default = false,
        })

        accordion:AddSelectBox({
            Name = "Select Cosmetic",
            Options = {"Loading..."},
            Flag = "CosmeticToPlace",
            MultiSelect = true,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local cosmetics = Cosmetic:GetAllCosmetics() or {}
                local formattedOptions = {}

                for cosmeticName, data in pairs(cosmetics) do
                    table.insert(formattedOptions, {text = string.format("[%s] On Inventory (%d) Equipped (%d)", cosmeticName, #data.OnInventory, #data.Equipped), value = cosmeticName})
                end

                updateOptions(formattedOptions)
            end
        })

        local totalEachCosmeticToPlaceNumberBox = accordion:AddNumberBox({
            Name = "Total Each Cosmetic",
            Default = 1,
            Min = 1,
            Max = 175,
            Flag = "TotalEachCosmeticToPlace"
        })


        m.NumberBoxReferences["TotalEachCosmeticToPlace"] = totalEachCosmeticToPlaceNumberBox

        local intervalCosmeticPlaceDelayNumberBox = accordion:AddNumberBox({
            Name = "Interval Place Delay (Seconds)",
            Default = 60,
            Min = 1,
            Max = 600,
            Flag = "IntervalCosmeticPlaceDelay"
        })


        m.NumberBoxReferences["IntervalCosmeticPlaceDelay"] = intervalCosmeticPlaceDelayNumberBox

        local togglePlacecosmetic = accordion:AddToggle({
            Name = "Auto Place Selected Cosmetic",
            Default = false,
            Flag = "AutoPlaceCosmetic"
        })


        m.ToggleReferences["AutoPlaceCosmetic"] = togglePlacecosmetic
    end

    function m:TeleportSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Teleport",
            Icon = "📡",
            Default = false,
        })

        local toggleLockoncenterofgarden = accordion:AddToggle({
            Name = "Lock On Center Of Garden",
            Default = false,
            Flag = "LockOnCenterOfGarden",
        })


        m.ToggleReferences["LockOnCenterOfGarden"] = toggleLockoncenterofgarden
    end

    function m:FarmersMarketSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Farmers Market",
            Icon = "🌾",
            Default = false,
        })

        local autoJoinToggle = accordion:AddToggle({
            Name = "Auto Join On Start",
            Default = false,
            Flag = "AutoJoinFarmersMarket",
        })
        if autoJoinToggle then
            m.ToggleReferences["AutoJoinFarmersMarket"] = autoJoinToggle
        end

        accordion:AddButton({Text = "Teleport to Portal 🚀", Callback = function()
            if Teleport then
                local success = Teleport:TeleportToFarmersMarket()
                if success then
                    Window:ShowInfo("Farmers Market", "Teleported to portal!")
                else
                    Window:ShowWarning("Farmers Market", "Failed to teleport to portal")
                end
            else
                Window:ShowWarning("Farmers Market", "Teleport module not initialized")
            end
        end})

        accordion:AddButton({Text = "Join Farmers Market 🌽", Callback = function()
            if Teleport then
                local success = Teleport:JoinFarmersMarket()
                if success then
                    Window:ShowInfo("Farmers Market", "Joining market...")
                else
                    Window:ShowWarning("Farmers Market", "Failed to join market")
                end
            else
                Window:ShowWarning("Farmers Market", "Teleport module not initialized")
            end
        end})
    end

    -- function m:PlayerDataSection(tab)
    --     local accordion = tab:AddAccordion({
    --         Title = "Player Data",
    --         Icon = "📊",
    --         Default = false,
    --     })

    --     accordion:AddButton({Text = "Print Player Data", Callback = function()
    --         PlayerData:GetPlayerData()
    --     end})
    -- end


    -- Function to refresh all toggle UI states from config
    function m:RefreshToggleStates()
        if not Window then
            warn("MiscUI:RefreshToggleStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, toggleAPI in pairs(self.ToggleReferences) do
            local success, err = pcall(function()
                if toggleAPI and toggleAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        toggleAPI:SetValue(configValue, false)
                        print(string.format("  ✓ [Misc] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Misc] %s - Toggle API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Misc] %s - Error: %s", flagName, tostring(err)))
            end
        end

        return refreshedCount
    end

    -- Function to refresh all numberbox UI states from config
    function m:RefreshNumberBoxStates()
        if not Window then
            warn("UI:RefreshNumberBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, numberBoxAPI in pairs(self.NumberBoxReferences) do
            local success, err = pcall(function()
                if numberBoxAPI and numberBoxAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        numberBoxAPI:SetValue(configValue)
                        print(string.format("  ✓ %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ %s - NumberBox API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("Refreshed %d numberboxes successfully", refreshedCount))
        return refreshedCount
    end

    return m
end

-- Module: special/special.lua
EmbeddedModules["special/special.lua"] = function()
    local m = {}

    local Core
    local Player
    local Window
    local Garden
    local PetTeam
    local PetModule  
    local Webhook
    local Rarity
    m.CurrentPetTeam = "core"

    local PetSkillConnection
    local AutoPickupLastTime = {}
    local LastAutoBulkingV2State = false
    local BulkingV2NotifiedPets = {} -- Track pets that have been notified via webhook
    local BulkingV2LastLogState = {} -- Track last logged state to avoid spam

    function m:Init(_core, _player, _window, _garden, _petTeam, _petModule, _webhook, _rarity)
        Core      = _core
        Player    = _player
        Window    = _window
        Garden    = _garden
        PetTeam   = _petTeam
        PetModule = _petModule 
        Webhook   = _webhook  
        Rarity    = _rarity

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBoostPets")
        end, function()
            self:AutoBoostSelectedPets()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoNightmareMutation")
                and not Window:GetConfigValue("AutoNightmareAndLeveling")
                and not Window:GetConfigValue("AutoIdleNightmareAndLeveling")
        end, function()
            self:AutoNightmareMutation()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoLevelingPets")
                and not Window:GetConfigValue("AutoNightmareAndLeveling")
                and not Window:GetConfigValue("AutoIdleNightmareAndLeveling")
        end, function()
            self:StartAutoLeveling()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoNightmareAndLeveling")
        end, function()
            self:AutoNightmareAndLeveling()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoIdleNightmareAndLeveling")
                and not Window:GetConfigValue("AutoNightmareAndLeveling")
        end, function()
            self:AutoIdleNightmareAndLeveling()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBulkingPets")
        end, function()
            self:StartAutoBulking()
        end)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBulkingPetsV2")
        end, function()
            self:StartAutoBulkingV2()
        end)

    end

    function m:GetPetReplicationData()
        local replicationClass = require(Core.ReplicatedStorage.Modules.ReplicationClass)
        local activePetsReplicator = replicationClass.new("ActivePetsService_Replicator")
        return activePetsReplicator:YieldUntilData().Table
    end

    function m:GetAllActivePets()
        local success, replicationData = pcall(function()
            return self:GetPetReplicationData()
        end)

        if not success then
            return nil
        end

        if not replicationData or not replicationData.ActivePetStates then
            return nil
        end

        local activePetStates = replicationData.ActivePetStates
        local playerName = Core.LocalPlayer.Name
        local playerId = tostring(Core.LocalPlayer.UserId)

        local playerPets = activePetStates[playerName] 
                        or activePetStates[playerId]
                        or activePetStates[tonumber(playerId)]

        if not playerPets then
            warn("No active pets found for player: " .. playerName)
            return nil
        end

        return playerPets
    end

    function m:GetPlayerPetData()
        local success, replicationData = pcall(self.GetPetReplicationData, self)
        if not success then
            warn("Failed to get replication data:" .. tostring(replicationData))
            return nil
        end

        if not replicationData or not replicationData.PlayerPetData then
            warn("Invalid PlayerPetData structure")
            return nil
        end

        local playerPetData = replicationData.PlayerPetData
        local playerName = Core.LocalPlayer.Name
        local playerId = tostring(Core.LocalPlayer.UserId)

        -- Try multiple ways to find player's data
        local playerData = playerPetData[playerName] 
                        or playerPetData[playerId]
                        or playerPetData[tonumber(playerId)]

        if not playerData then
            warn("No pet data found for player:" .. playerName)
            return nil
        end

        return playerData
    end

    function m:GetPetData(_petID)
        local playerData = self:GetPlayerPetData()
        if playerData and playerData.PetInventory then
            return playerData.PetInventory.Data[_petID]
        end
        return nil
    end

    function m:EquipPet(_petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return false
        end

        local success = pcall(function()
            local position = CFrame.new(Garden:GetFarmCenterPosition())
            if not position then
                Window:ShowWarning("Equip Pet","Failed to get farm center position")
            end

            Core.ReplicatedStorage.GameEvents.PetsService:FireServer(
                "EquipPet",
                _petID,
                position
            )
        end)

        if not success then
            Window:ShowWarning("Equip Pet","Failed to equip pet:" .. _petID)
            return false
        end

        -- Optional configurable delay after equipping a pet (default 2 seconds)
        local equipDelay = 0
        if Window and Window.GetConfigValue then
            local cfg = Window:GetConfigValue("EquipPetDelay")
            if type(cfg) == "number" then
                equipDelay = cfg
            end
        end
        if equipDelay > 0 then
            task.wait(equipDelay)
        end

        return true
    end

    function m:UnequipPet(_petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return false
        end

        local success = pcall(function()
            Core.ReplicatedStorage.GameEvents.PetsService:FireServer(
                "UnequipPet",
                _petID
            )
        end)

        if not success then
            Window:ShowWarning("Unequip Pet","Failed to unequip pet:" .. _petID)
            return false
        end

        -- Optional configurable delay after unequipping a pet (default 2 seconds)
        local unequipDelay = 0
        if Window and Window.GetConfigValue then
            local cfg = Window:GetConfigValue("UnequipPetDelay")
            if type(cfg) == "number" then
                unequipDelay = cfg
            end
        end
        if unequipDelay > 0 then
            task.wait(unequipDelay)
        end

        return true
    end

    function m:GetCurrentPetTeam()
        return self.CurrentPetTeam
    end

    function m:ChangeTeamPets(_teamName, _teamType)
        if not _teamName or _teamName == "" then
            return false
        end

        self.CurrentPetTeam = _teamType

        local pets = PetTeam:FindPetTeam(_teamName)

        if not pets or #pets == 0 then
            Window:ShowWarning("Change Team Pet","No pets found in the team:" .. _teamName)
            return false
        end

        -- Deactivate all current active pets
        local activePets = self:GetAllActivePets() or {}

        if not activePets then
            Window:ShowWarning("Change Team Pet","No active pets to unequip")
        end

        for petID, _ in pairs(activePets) do
            local success = pcall(function()
                self:UnequipPet(petID)
            end)

            if not success then
                Window:ShowWarning("Change Team Pet","Failed to unequip pet:" .. petID)
            end

            task.wait(0.25) -- Longer delay to ensure server processes
        end

        -- Wait for unequip to complete
        task.wait(1)

        -- Activate pets in the selected team (max 8)
        local maxPets = 8
        local equippedCount = 0

        for i, petID in ipairs(pets) do
            -- Stop if we've reached max pet limit
            if equippedCount >= maxPets then
                break
            end

            local success = pcall(function()
                self:EquipPet(petID)
            end)

            if not success then
                Window:ShowWarning("Change Team Pet","Failed to equip pet:" .. petID)
            else
                equippedCount = equippedCount + 1
            end

            task.wait(0.25) -- Longer delay between equips
        end

        -- Final wait to ensure all equips are processed
        task.wait(1)
        return equippedCount -- Return jumlah pet yang di-equip
    end


    function m:IsSafeChangeTeamPets()
        if m.CurrentPetTeam == "manual" or m.CurrentPetTeam == "core" then
            return true
        end

        return false
    end

    local function IsNightmareLevelingAutomationEnabled()
        if not Window then
            return false
        end

        return Window:GetConfigValue("AutoNightmareAndLeveling")
            or Window:GetConfigValue("AutoIdleNightmareAndLeveling")
    end

    function m:BoostPet(_petID)
        Core.ReplicatedStorage.GameEvents.PetBoostService:FireServer(
            "ApplyBoost",
            _petID
        )
    end

    function m:EligiblePetUseBoost(_petID, _boostType, _boostAmount)
        local petData = self:GetPetData(_petID)
        local isEligible = true

        if not petData or not petData.PetData then
            return false
        end

        for key, value in pairs(petData.PetData) do
            if type(value) ~= "table" then
                continue
            end
            if key ~= "Boosts" and #value < 1 then
                continue
            end

            for i, boostInfo in ipairs(value) do
                local currentBoostType = boostInfo.BoostType
                local currentBoostAmount = boostInfo.BoostAmount

                if currentBoostType == _boostType and currentBoostAmount == _boostAmount then
                    isEligible = false
                end
            end
        end
        return isEligible
    end

    function m:BoostSelectedPets()
        local petIDs = Window:GetConfigValue("BoostPets") or {}
        if #petIDs == 0 then
            Window:ShowWarning("Boost Pets","No pets selected for boosting.")
            return
        end

        local boostTypes = Window:GetConfigValue("BoostType") or {}
        if #boostTypes == 0 then
            Window:ShowWarning("Boost Pets", "No boost types selected.")
            return
        end

        for _, boostType in pairs(boostTypes) do
            local extractedType = {}
            for match in string.gmatch(boostType, "([^%-]+)") do
                table.insert(extractedType, match)
            end

            if #extractedType ~= 2 then
                Window:ShowWarning("Boost Pets", "Invalid boost type format:" .. boostType)
                continue
            end

            local toolType = extractedType[1]
            local toolAmount = tonumber(extractedType[2])
            local boostTool = nil

            for _, tool in next, Player:GetAllTools() do
                local tType = tool:GetAttribute("q")
                local tAmount = tool:GetAttribute("o")

                if tType == toolType and tAmount == toolAmount then
                    boostTool = tool or nil
                    break
                end
            end

            if not boostTool then
                Window:ShowWarning("Boost Pets", "No boost tool found for type:" .. boostType)
                return
            end

            local boostingPetTask = function(_petIDs, _boostType, _boostAmount, _boostTool)
                for _, petID in pairs(_petIDs) do
                    local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                    if not isEligible then
                        continue
                    end

                    self:BoostPet(petID)
                    task.wait(0.15)
                end
            end

            Player:AddToQueue(
                boostTool,               -- tool
                10,                  -- priority (high)
                function()
                    boostingPetTask(petIDs, toolType, toolAmount, boostTool)
                end    -- task function
            )
        end
    end

    function m:AutoBoostSelectedPets()
        local autoBoost = Window:GetConfigValue("AutoBoostPets") or false
        if not autoBoost then
            return
        end

        local petIDs = Window:GetConfigValue("BoostPets") or {}
        if #petIDs == 0 then
            Window:ShowWarning("Boost Pets", "No pets selected for boosting.")
            return
        end

        local boostTypes = Window:GetConfigValue("BoostType") or {}
        if #boostTypes == 0 then
            Window:ShowWarning("Boost Pets", "No boost types selected.")
            return
        end

        local hasEligiblePet = false
        for _, petID in pairs(petIDs) do
            for _, boostType in pairs(boostTypes) do
                local extractedType = {}
                for match in string.gmatch(boostType, "([^%-]+)") do
                    table.insert(extractedType, match)
                end
                if #extractedType ~= 2 then
                    continue
                end

                local toolType = extractedType[1]
                local toolAmount = tonumber(extractedType[2])
                local isEligible = self:EligiblePetUseBoost(petID, toolType, toolAmount)
                if isEligible then
                    hasEligiblePet = true
                    break
                end
            end
            if hasEligiblePet then
                break
            end
        end

        if not hasEligiblePet then
            return
        end

        self:BoostSelectedPets()
    end

    function m:BoostAllActivePets()
        local boostTool = {}

        for _, tool in next, Player:GetAllTools() do
            local toolType = tool:GetAttribute("q")

            if toolType == "PASSIVE_BOOST" then
                table.insert(boostTool, tool)
            end
        end

        if #boostTool == 0 then
            Window:ShowWarning("Boost Pets", "No boost tool found in inventory.")
            return
        end

        for _, tool in next, boostTool do
            local boostType = tool:GetAttribute("q")
            local boostAmount = tool:GetAttribute("o")
            local isTaskCompleted = false

            local boostingPetTask = function(_boostType, _boostAmount)
                Window:ShowInfo("Boost Pets", "Starting boost task for tool: " .. tool.Name)
                for petID, _ in pairs(self:GetAllActivePets()) do
                    local isEligible = self:EligiblePetUseBoost(petID, _boostType, _boostAmount)

                    if not isEligible then
                        continue
                    end

                    Window:ShowInfo("Boost Pets", "Boosting pet: " .. petID .. " with " .. _boostType .. " amount: " .. _boostAmount)
                    self:BoostPet(petID)
                    task.wait(0.15)
                end
            end

            local boostingPetCallback = function()
                isTaskCompleted = true
            end

            Player:AddToQueue(
                tool,               -- tool
                1,                  -- priority (high)
                function()
                    boostingPetTask(boostType, boostAmount)
                end,    -- task function
                function()
                    boostingPetCallback()
                end     -- callback function
            )

            -- Wait until task is completed
            while isTaskCompleted == false do
                task.wait(1)
            end
        end
    end

    function m:GetAllOwnedPets()
        local myPets = {}

        for _, tool in next, Player:GetAllTools() do
            local toolType = tool:GetAttribute("b")
            toolType = toolType or ""
            if toolType == "l" then
                table.insert(myPets, tool)
            end
        end

        return myPets
    end

    function m:GetPetDetail(_petID)
        local success, petMutationRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)
        end)

        if not success then
            Window:ShowWarning("Pet Details", "Failed to load PetMutationRegistry: " .. tostring(petMutationRegistry))
            petMutationRegistry = nil
        end

        local petData = self:GetPetData(_petID)
        if not petData then
            Window:ShowWarning("Pet Details", "Pet data not found for UUID:" .. _petID)
            return nil
        end

        local petDetail = petData.PetData

        if not petDetail then
            Window:ShowWarning("Pet Details", "Pet detail is nil for UUID:" .. _petID)
            return nil
        end

        local isActive = false
        local activePets = self:GetAllActivePets() or {}
        for petID, _ in pairs(activePets) do
            if petID == _petID then
                isActive = true
                break
            end
        end

        local mutationType = petDetail.MutationType or ""
        if mutationType == "Gold" then
            mutationType = "Golden"
        end
        local mutation = ""

        if petMutationRegistry and petMutationRegistry.EnumToPetMutation and mutationType ~= "" then
            mutation = petMutationRegistry.EnumToPetMutation[mutationType] or ""
        end

        return {
            ID = _petID,
            Name = petDetail.Name or "Unnamed",
            Type = petData.PetType or "Unknown",
            BaseWeight = petDetail.BaseWeight or 1,
            Age = petDetail.Level or 0,
            IsFavorited = petDetail.IsFavorite or false,
            IsActive = isActive,
            Mutation = mutation
        }
    end

    function m:GetAllMyPets()
        local myPets = {}
        local pets = {}

        for _, tool in pairs(self:GetAllOwnedPets()) do
            local petID = tool:GetAttribute("PET_UUID")
            if not petID then
                Window:ShowWarning("Pet Details", "Pet tool missing PET_UUID attribute:" .. tool.Name)
                continue
            end

            table.insert(pets, {
                ID = petID,
                IsActive = false
            })
        end

        for petID, _ in pairs(self:GetAllActivePets()) do
            if not petID then
                Window:ShowWarning("Pet Details", "Active pet entry missing PET_UUID")
                continue
            end

            table.insert(pets, {
                ID = petID,
                IsActive = true
            })
        end

        for _, pet in pairs(pets) do
            local petDetail = self:GetPetDetail(pet.ID)
            if not petDetail  then
                Window:ShowWarning("Pet Details", "Pet detail not found for UUID:" .. pet.ID)
                continue
            end

            table.insert(myPets, {
                ID = petDetail.ID,
                Name = petDetail.Name,
                Type = petDetail.Type,
                BaseWeight = petDetail.BaseWeight,
                Age = petDetail.Age,
                IsActive = pet.IsActive,
                IsFavorited = petDetail.IsFavorited,
                Mutation = petDetail.Mutation
            })
        end

        -- Sort by active status first, then by type, then by age descending
        table.sort(myPets, function(a, b)
            if a.IsActive ~= b.IsActive then
                return a.IsActive -- Active pets first
            elseif a.Type ~= b.Type then
                return a.Type < b.Type -- Alphabetical by type
            else
                return a.Age > b.Age -- Older pets first
            end
        end)

        return myPets
    end

    function m:SerializePet(pet)
        if not pet then return "" end
        local weight = tonumber(pet.BaseWeight) or 0
        local age = tonumber(pet.Age) or 0
        local mutationPrefix = (pet.Mutation and pet.Mutation ~= "") and ("[" .. pet.Mutation .. "] ") or ""
        local activeSuffix = pet.IsActive and " (Active)" or ""
        return string.format("%s%s %.2f KG (age %d) - %s%s",
            mutationPrefix,
            pet.Type or "Unknown",
            weight,
            age,
            pet.Name or "Unnamed",
            activeSuffix
        )
    end

    function m:FindEggByPetName(petName)
        local PetEggs = require(Core.ReplicatedStorage.Data.PetRegistry.PetEggs)

        -- List of eggs to exclude (fake/test eggs)
        local excludedEggs = {
            ["Fake Egg"] = true,
            -- Add other test/fake eggs here if needed
        }

        -- Iterate through all eggs
        for eggName, eggData in pairs(PetEggs) do
            -- Skip excluded eggs
            if excludedEggs[eggName] then
                continue
            end

            -- Check if RarityData and Items exist
            if eggData.RarityData and eggData.RarityData.Items then
                -- Check if the pet exists in this egg
                if eggData.RarityData.Items[petName] then
                    return eggName -- Return the egg name
                end
            end
        end

        return "Fake Egg" -- Pet not found in any egg
    end

    function m:GetPetRegistry()
        local success, petRegistry = pcall(function()
            return require(Core.ReplicatedStorage.Data.PetRegistry)
        end)

        if not success then
            Window:ShowWarning("Pet Registry", "Failed to get pet registry:" .. petRegistry)
            return {}
        end

        local petList = petRegistry.PetList
        if not petList then
            Window:ShowWarning("Pet Registry", "PetList is nil or not found")
            return {}
        end

        -- Convert PetList to UI format {text = ..., value = ...}
        local listPets = {}
        for petName, petData in pairs(petList) do
            local eggName = self:FindEggByPetName(petName)
            table.insert(listPets, {
                Name = petName,
                Rarity = petData.Rarity or "Unknown",
                Egg = eggName
            })
        end

        if #listPets < 1 then
            return {}
        end

        -- Sort pets alphabetically (ascending order)
        table.sort(listPets, function(a, b)
            local eggA = a.Egg or "Unknown"
            local eggB = b.Egg or "Unknown"
            if eggA ~= eggB then
                return string.lower(tostring(eggA)) < string.lower(tostring(eggB))
            end

            local rarityA = Rarity.RarityOrder[a.Rarity] or 99
            local rarityB = Rarity.RarityOrder[b.Rarity] or 99
            if rarityA ~= rarityB then
                return rarityA < rarityB
            end

            return string.lower(tostring(a.Name)) < string.lower(tostring(b.Name))
        end)

        return listPets
    end

    function m:GetModelPet(_petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return nil
        end

        -- Cari di semua descendant
        for _, petMover in ipairs(workspace.PetsPhysical:GetChildren()) do
            local modelPet = petMover:FindFirstChild(_petID)
            if modelPet then
                return modelPet
            end
        end

        Window:ShowWarning("Get Model Pet", "Model not found")
        return nil
    end

    function m:CleansingMutation(_petID)
        Window:ShowInfo("Cleansing Mutation", "Cleansing mutation for pet ID: " .. _petID)
        if not _petID then
            warn("Invalid pet ID provided")
            return false
        end

        -- Ensure the avatar is not currently holding any tool (including Cleansing Shard)
        if Player.UnequipTool then
            Player:UnequipTool()
            task.wait(0.2)
        end

        local cleansingTool
        for _, tool in next, Player:GetAllTools() do
            local toolName = tool:GetAttribute("u")

            if toolName == "Cleansing Pet Shard" then
                cleansingTool = tool or nil
                break
            end
        end

        if not cleansingTool then
            Window:ShowWarning("Cleansing Mutation", "No cleansing tool found")
            return false
        end

        local isTaskCompleted = false
        local cleansingTask = function(_petID)
            local petMover = self:GetModelPet(_petID)
            if not petMover then
                Window:ShowWarning("Cleansing Mutation", "PetMover not found for pet ID: " .. _petID)
                return
            end

            Window:ShowInfo("Cleansing Mutation", "Applying cleansing shard to pet ID: " .. _petID)
            local success, error = pcall(function()
                Core.ReplicatedStorage.GameEvents.PetShardService_RE:FireServer(
                    "ApplyShard",
                    petMover
                )
            end)

            if not success then
                Window:ShowWarning("Cleansing Mutation", "Failed to apply cleansing shard: " .. error)
            end
            task.wait(1) -- Wait to ensure server processes the shard application
        end

        local cleansingCallback = function()
            isTaskCompleted = true
        end

        Player:AddToQueue(
            cleansingTool,               -- tool
            10,                  -- priority (high)
            function()
                cleansingTask(_petID)
            end,    -- task function
            function()
                cleansingCallback()
            end -- callback function
        )

        return true
    end

    function m:AutoNightmareMutation()
        local autoNightmare = Window:GetConfigValue("AutoNightmareMutation") or false
        local nightMarePetTeam = Window:GetConfigValue("NightmareMutationPetTeam") or nil
        local petIDs = Window:GetConfigValue("NightmareMutationPets") or {}

        if not autoNightmare then
            warn("Auto Nightmare Mutation is disabled.")
            return
        end

        if not nightMarePetTeam then
            Window:ShowWarning("Nightmare Mutation", "No Nightmare Mutation Pet Team selected.")
            return
        end

        if #petIDs == 0 then
            Window:ShowWarning("Nightmare Mutation","No pets selected for Nightmare Mutation.")
            return
        end

        local keepMutationList = Window:GetConfigValue("KeepMutationList") or {"Nightmare"}
        -- Default to Nightmare if list is empty or nil
        if type(keepMutationList) == "table" and #keepMutationList == 0 then
            keepMutationList = {"Nightmare"}
        elseif type(keepMutationList) == "string" then
             keepMutationList = {keepMutationList}
        end

        -- Create lookup set for faster checking
        local keepMutationSet = {}
        for _, mut in pairs(keepMutationList) do
            -- Handle both string array and object array (from SelectBox)
            if type(mut) == "table" and mut.value then
                 keepMutationSet[mut.value] = true
            else
                 keepMutationSet[tostring(mut)] = true
            end
        end

        local isPetIDAlreadyNightmare = ""
        local isNoActivePet = true

        for _, petID in pairs(petIDs) do
            local petDetail = self:GetPetDetail(petID)
            if not petDetail then
                Window:ShowWarning("Nightmare Mutation","Pet detail not found for UUID: " .. petID)
                continue
            end

            if not petDetail.IsActive then
                continue
            end

            isNoActivePet = false

            if petDetail.Mutation == "" then
                continue
            end

            if keepMutationSet[petDetail.Mutation] then
                Window:ShowInfo(petDetail.Mutation .. " Mutation", "Pet obtained desired mutation (" .. petDetail.Mutation .. "): " .. petDetail.Name)
                task.spawn(function() 
                    -- Pass the actual mutation type to webhook
                    if Webhook and Webhook.NightmareMutation then
                        Webhook:NightmareMutation(petDetail.Type, #petIDs - 1, petDetail.Mutation)
                    end
                end)

                isPetIDAlreadyNightmare = petID
                break
            end

            Window:ShowInfo("Nightmare Mutation","Starting Cleansing Mutation for pet: " .. petDetail.Name .. " (Current: " .. petDetail.Mutation .. ")")
            local success = self:CleansingMutation(petID)
            if not success then
                Window:ShowWarning("Nightmare Mutation","Failed to cleanse mutation for pet: " .. petDetail.Name)
                continue
            end
        end

        if isPetIDAlreadyNightmare ~= "" then
            self:UnequipPet(isPetIDAlreadyNightmare)
            task.wait(1)

            -- Remove from selected pets to avoid reprocessing
            for index, id in ipairs(petIDs) do
                if id == isPetIDAlreadyNightmare then
                    table.remove(petIDs, index)
                    break
                end
            end

            Window:SetConfigValue("NightmareMutationPets", petIDs)
            isNoActivePet = true
        end

        if not isNoActivePet then
            return
        end

        while not self:IsSafeChangeTeamPets() do
            Window:ShowInfo("Nightmare Mutation","Waiting to switch back to Core Pet Team...")
            task.wait(1)
        end

        Window:ShowInfo("Nightmare Mutation", "Starting Nightmare Mutation New Target Pet")

        Window:SetConfigValue("CorePetTeam", nightMarePetTeam)
        local equippedFromTeam = self:ChangeTeamPets(nightMarePetTeam, "core") or 0

        local maxPets = 8
        local availableSlots = maxPets - equippedFromTeam

        for i, petID in ipairs(petIDs) do
            if i > availableSlots then break end
            self:EquipPet(petID)
            task.wait(0.25)
        end
    end

    function m:AutoNightmareAndLeveling()
        -- Master controller for combined mode with 3 teams:
        -- Team 1: Nightmare, Team 2: Leveling 1-40, Team 3: Leveling 40-100
        local enabled = Window:GetConfigValue("AutoNightmareAndLeveling") or false
        if not enabled then
            return
        end

        local stage = Window:GetConfigValue("NightmareAndLevelingStage") or "nightmare"

        if stage == "nightmare" then
            local finishedNightmare = self:AutoNightmareMutation_Combo()
            if finishedNightmare then
                -- When Nightmare phase is complete, switch to Leveling Pet Team 1 (1-40)
                local levelingPetTeam1 = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam1") or nil
                if levelingPetTeam1 then
                    Window:ShowInfo("Auto Nightmare + Leveling", "Nightmare phase finished. Switching to Leveling Pet Team 1-40: " .. tostring(levelingPetTeam1))
                    Window:SetConfigValue("CorePetTeam", levelingPetTeam1)
                    self:ChangeTeamPets(levelingPetTeam1, "core")
                else
                    Window:ShowWarning("Auto Nightmare + Leveling", "Nightmare phase finished, but no Leveling Pet Team 1-40 is set. Remaining on current team.")
                end

                Window:SetConfigValue("NightmareAndLevelingStage", "leveling1")
                Window:ShowInfo("Auto Nightmare + Leveling", "Starting Auto Leveling phase 1 (1-40).")
            end
        elseif stage == "leveling1" then
            local finishedLeveling1 = self:StartAutoLeveling1_Combo()
            if finishedLeveling1 then
                -- Verify ALL pets have reached age 40 before proceeding to leveling2
                local levelingPets = Window:GetConfigValue("NightmareAndLevelingLevelingPets") or {}
                local allPetsReachedAge40 = true
                local targetAge = 40

                for _, petID in ipairs(levelingPets) do
                    local petDetail = self:GetPetDetail(petID)
                    if petDetail then
                        local petAge = tonumber(petDetail.Age) or 0
                        if petAge < targetAge then
                            allPetsReachedAge40 = false
                            break
                        end
                    end
                end

                -- Only proceed to leveling2 if all pets have reached age 40
                if allPetsReachedAge40 then
                    -- When Leveling 1-40 is complete, switch to Leveling Pet Team 2 (40-100)
                    local levelingPetTeam2 = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam2") or nil
                    if levelingPetTeam2 then
                        Window:ShowInfo("Auto Nightmare + Leveling", "All pets reached age 40. Switching to Leveling Pet Team 40-100: " .. tostring(levelingPetTeam2))
                        Window:SetConfigValue("CorePetTeam", levelingPetTeam2)
                        self:ChangeTeamPets(levelingPetTeam2, "core")
                    else
                        Window:ShowWarning("Auto Nightmare + Leveling", "All pets reached age 40, but no Leveling Pet Team 40-100 is set. Remaining on current team.")
                    end

                    Window:SetConfigValue("NightmareAndLevelingStage", "leveling2")
                    Window:ShowInfo("Auto Nightmare + Leveling", "Starting Auto Leveling phase 2 (40-100).")
                else
                    -- Not all pets have reached age 40 yet, stay in leveling1 stage
                    -- The function will continue leveling in the next cycle
                    return
                end
            end
        elseif stage == "leveling2" then
            local finishedLeveling2 = self:StartAutoLeveling2_Combo()
            if finishedLeveling2 then
                -- Check priority order to determine next stage
                local priority = Window:GetConfigValue("IdleNightmareLevelingPriority") or "MutationFirst"

                if priority == "LevelingFirst" then
                    -- Leveling First mode: Verify ALL pets have reached age 100 before proceeding to mutation
                    local nightmarePets = Window:GetConfigValue("NightmareAndLevelingNightmarePets") or {}
                    local allPetsReachedAge100 = true
                    local targetAge = 100

                    for _, petID in ipairs(nightmarePets) do
                        local petDetail = self:GetPetDetail(petID)
                        if petDetail then
                            local petAge = tonumber(petDetail.Age) or 0
                            if petAge < targetAge then
                                allPetsReachedAge100 = false
                                break
                            end
                        end
                    end

                    -- Only proceed to mutation phase if all pets have reached age 100
                    if allPetsReachedAge100 then
                        -- After leveling is complete, now do mutation phase
                        local nightmarePetTeam = Window:GetConfigValue("NightmareAndLevelingNightmarePetTeam") or nil
                        if nightmarePetTeam then
                            Window:ShowInfo("Auto Nightmare + Leveling", "All pets reached age 100. Switching to Mutation Team: " .. tostring(nightmarePetTeam))
                            Window:SetConfigValue("CorePetTeam", nightmarePetTeam)
                            self:ChangeTeamPets(nightmarePetTeam, "core")
                        else
                            Window:ShowWarning("Auto Nightmare + Leveling", "All pets reached age 100, but no Mutation Team is set. Remaining on current team.")
                        end

                        Window:SetConfigValue("NightmareAndLevelingStage", "nightmare")
                        Window:ShowInfo("Auto Nightmare + Leveling", "Starting Mutation phase (after all pets reached age 100).")
                    else
                        -- Not all pets have reached age 100 yet, stay in leveling2 stage
                        -- The function will continue leveling in the next cycle
                        return
                    end
                else
                    -- Mutation First mode (default): Leveling complete, combo is done
                    Window:SetConfigValue("NightmareAndLevelingStage", "done")
                end
            end
        elseif stage == "done" then
            -- When combo is finished:
            --  - If running under manual mode, keep showing repeated notification while toggle remains on.
            --  - If running under idle watcher, disable combo and reset stage to "idle" so watcher can wait for new pets.
            Window:ShowInfo("Auto Nightmare + Leveling", "All Nightmare + Leveling targets completed (Level 100).")

            if Window:GetConfigValue("AutoIdleNightmareAndLeveling") then
                -- Idle mode: stop the combo state machine and let the idle watcher decide when to start again.
                Window:SetConfigValue("AutoNightmareAndLeveling", false)
                Window:SetConfigValue("NightmareAndLevelingStage", "idle")
            end

            return
        else
            -- Unknown stage: do nothing
            return
        end
    end

    function m:AutoIdleNightmareAndLeveling()
        -- This watcher looks at inventory and, when target pets exist and are not fully processed,
        -- automatically starts a full Nightmare + Leveling combo run.
        local enabled = Window:GetConfigValue("AutoIdleNightmareAndLeveling") or false
        if not enabled then
            return
        end

        -- Read target pet types for idle mode (list of pet Type names, e.g., {"Mimic"})
        local targetTypes = Window:GetConfigValue("IdleNightmareLevelingPetTypes") or {}
        if #targetTypes == 0 then
            -- Nothing configured, remain idle
            return
        end

        -- Setup KeepMutationList logic for idle
        local keepMutationList = Window:GetConfigValue("IdleNightmareLevelingKeepMutationList") or {"Nightmare"}
        if type(keepMutationList) == "table" and #keepMutationList == 0 then
            keepMutationList = {"Nightmare"}
        elseif type(keepMutationList) == "string" then
             keepMutationList = {keepMutationList}
        end

        local keepMutationSet = {}
        for _, mut in pairs(keepMutationList) do
            if type(mut) == "table" and mut.value then
                 keepMutationSet[mut.value] = true
            else
                 keepMutationSet[tostring(mut)] = true
            end
        end

        -- Fixed level threshold: 100 (pets go through Nightmare → Level 1-40 → Level 40-100)
        local levelToReach = 100

        -- Collect all owned pets that match target types and still need processing
        local myPets = self:GetAllMyPets() or {}
        local candidateIDs = {}

        for _, pet in ipairs(myPets) do
            local isTargetType = false
            for _, t in ipairs(targetTypes) do
                if pet.Type == t then
                    isTargetType = true
                    break
                end
            end

            -- Only consider pets that are in inventory (not active) and not favorited
            if isTargetType and not pet.IsActive and not pet.IsFavorited then
                -- Pet still needs work if not in keep list yet, or in keep list but not yet at target level (100)
                -- Logic:
                -- If mutation is empty -> needs work
                -- If mutation is NOT in keep list -> needs work (needs cleansing/reroll)
                -- If mutation IS in keep list -> check level
                local needsMutation = false
                if pet.Mutation == "" then
                    needsMutation = true
                elseif not keepMutationSet[pet.Mutation] then
                    needsMutation = true
                end

                local needsLevel = (pet.Age or 0) < levelToReach

                if needsMutation or needsLevel then
                    table.insert(candidateIDs, pet.ID)
                end
            end
        end

        -- If there are no pets needing Nightmare/Leveling right now, stay idle
        if #candidateIDs == 0 then
            return
        end

        -- Check current combo state
        local currentStage = Window:GetConfigValue("NightmareAndLevelingStage") or "idle"
        local comboActive = Window:GetConfigValue("AutoNightmareAndLeveling") or false

        -- Case 1: No active combo, or last combo finished → start a fresh batch
        if (not comboActive) or currentStage == "idle" or currentStage == "done" then
            -- Initialize a new combo batch from the discovered candidate pets
            -- Save the raw target list for UI/reference if needed
            Window:SetConfigValue("NightmareAndLevelingTargetPets", candidateIDs)

            -- Create separate lists for Nightmare and Leveling phases (independent copies)
            local nightmareList = {}
            local levelingList = {}
            for i, id in ipairs(candidateIDs) do
                nightmareList[i] = id
                levelingList[i] = id
            end

            Window:SetConfigValue("NightmareAndLevelingNightmarePets", nightmareList)
            Window:SetConfigValue("NightmareAndLevelingLevelingPets", levelingList)

            -- Pass the idle keep list to the combo keep list so the combo respects it
            Window:SetConfigValue("NightmareAndLevelingKeepMutationList", keepMutationList)

            -- Check priority order setting
            local priority = Window:GetConfigValue("IdleNightmareLevelingPriority") or "MutationFirst"

            -- Set initial stage based on priority
            if priority == "LevelingFirst" then
                -- Start with leveling phase (skip mutation initially)
                Window:SetConfigValue("NightmareAndLevelingStage", "leveling1")
            else
                -- Default: Start with mutation phase (existing behavior)
                Window:SetConfigValue("NightmareAndLevelingStage", "nightmare")
            end

            -- Enable the combo controller; idle mode will turn it off again when done
            Window:SetConfigValue("AutoNightmareAndLeveling", true)

            Window:ShowInfo(
                "Auto Idle Nightmare + Leveling",
                "Detected " .. tostring(#candidateIDs) .. " target pets in inventory. Starting Nightmare + Leveling combo run."
            )
            return
        end

        -- Case 2: Combo is already running in nightmare/leveling stage → append new candidates to existing lists
        if comboActive and (currentStage == "nightmare" or currentStage == "leveling1" or currentStage == "leveling2") then
            local nightmareList = Window:GetConfigValue("NightmareAndLevelingNightmarePets") or {}
            local levelingList = Window:GetConfigValue("NightmareAndLevelingLevelingPets") or {}
            local targetList = Window:GetConfigValue("NightmareAndLevelingTargetPets") or {}

            -- Build a set of existing IDs to avoid duplicates
            local existing = {}
            for _, id in ipairs(nightmareList) do
                existing[id] = true
            end
            for _, id in ipairs(levelingList) do
                existing[id] = true
            end
            for _, id in ipairs(targetList) do
                existing[id] = true
            end

            local addedCount = 0
            for _, id in ipairs(candidateIDs) do
                if not existing[id] then
                    table.insert(nightmareList, id)
                    table.insert(levelingList, id)
                    table.insert(targetList, id)
                    existing[id] = true
                    addedCount = addedCount + 1
                end
            end

            if addedCount > 0 then
                Window:SetConfigValue("NightmareAndLevelingNightmarePets", nightmareList)
                Window:SetConfigValue("NightmareAndLevelingLevelingPets", levelingList)
                Window:SetConfigValue("NightmareAndLevelingTargetPets", targetList)

                Window:ShowInfo(
                    "Auto Idle Nightmare + Leveling",
                    "Added " .. tostring(addedCount) .. " new pets into current Nightmare + Leveling queue."
                )
            end
            return
        end
    end

    function m:AutoNightmareMutation_Combo()
        local nightMarePetTeam = Window:GetConfigValue("NightmareAndLevelingNightmarePetTeam") or nil
        local petIDs = Window:GetConfigValue("NightmareAndLevelingNightmarePets") or {}

        if not IsNightmareLevelingAutomationEnabled() then
            return false
        end

        if not nightMarePetTeam then
            Window:ShowWarning("Auto Nightmare + Leveling", "No Nightmare Pet Team selected for combo.")
            return true
        end

        if #petIDs == 0 then
            return true
        end

        -- Setup KeepMutationList logic for combo
        local keepMutationList = Window:GetConfigValue("NightmareAndLevelingKeepMutationList") or {"Nightmare"}
        if type(keepMutationList) == "table" and #keepMutationList == 0 then
            keepMutationList = {"Nightmare"}
        elseif type(keepMutationList) == "string" then
             keepMutationList = {keepMutationList}
        end

        local keepMutationSet = {}
        for _, mut in pairs(keepMutationList) do
            if type(mut) == "table" and mut.value then
                 keepMutationSet[mut.value] = true
            else
                 keepMutationSet[tostring(mut)] = true
            end
        end

        local isPetIDAlreadyNightmare = ""
        local isNoActivePet = true

        for _, petID in pairs(petIDs) do
            -- Allow user to stop the combo cleanly mid-cycle
            if not IsNightmareLevelingAutomationEnabled() then
                return false
            end

            local petDetail = self:GetPetDetail(petID)
            if not petDetail then
                Window:ShowWarning("Auto Nightmare + Leveling", "Pet detail not found for UUID: " .. petID)
                continue
            end

            if not petDetail.IsActive then
                continue
            end

            isNoActivePet = false

            -- Belum ada mutation sama sekali, tunggu sampai ada mutation (sama seperti mode single)
            if petDetail.Mutation == "" then
                continue
            end

            -- Sudah berhasil Nightmare/Desired Mutation: anggap selesai untuk pet ini, unequip dan buang dari list
            if keepMutationSet[petDetail.Mutation] then
                Window:ShowInfo(petDetail.Mutation .. " Mutation", "Pet obtained desired mutation (" .. petDetail.Mutation .. "): " .. petDetail.Name)
                task.spawn(function()
                    if Webhook and Webhook.NightmareMutation then
                        Webhook:NightmareMutation(petDetail.Type, #petIDs - 1, petDetail.Mutation)
                    end
                end)

                isPetIDAlreadyNightmare = petID
                break
            end

            -- Mutation lain (Dreadbound, dsb) → coba cleansing
            Window:ShowInfo("Auto Nightmare + Leveling", "Starting Cleansing Mutation for pet: " .. petDetail.Name)
            local success = self:CleansingMutation(petID)
            if not success then
                -- Jika cleansing gagal (tidak ada shard, dsb), skip pet ini permanen dari list combo
                Window:ShowWarning("Auto Nightmare + Leveling", "Failed to cleanse mutation for pet: " .. petDetail.Name .. ". Skipping this pet from combo Nightmare list.")

                for index, id in ipairs(petIDs) do
                    if id == petID then
                        table.remove(petIDs, index)
                        break
                    end
                end

                Window:SetConfigValue("NightmareAndLevelingNightmarePets", petIDs)

                -- Tidak ada target aktif yang bisa diproses di cycle ini, lanjut coba pet lain di loop berikutnya
                isNoActivePet = true
                break
            end
        end

        if isPetIDAlreadyNightmare ~= "" then
            -- Persis seperti mode single: unequip pet yang sudah Nightmare lalu keluarkan dari daftar target
            self:UnequipPet(isPetIDAlreadyNightmare)
            task.wait(1)

            for index, id in ipairs(petIDs) do
                if id == isPetIDAlreadyNightmare then
                    table.remove(petIDs, index)
                    break
                end
            end

            Window:SetConfigValue("NightmareAndLevelingNightmarePets", petIDs)
            isNoActivePet = true
        end

        -- Jika setelah update list sudah habis, maka fase Nightmare kombo selesai
        if #petIDs == 0 then
            Window:SetConfigValue("NightmareAndLevelingNightmarePets", petIDs)
            return true
        end

        -- Masih ada pet target dan masih ada yang aktif → tunggu sampai selesai Nightmare untuk mereka
        if not isNoActivePet then
            return false
        end

        -- Tidak ada target aktif → aman ganti tim kembali ke tim Nightmare untuk melanjutkan ke target berikutnya
        while not self:IsSafeChangeTeamPets() do
            -- If toggles are turned off while waiting, abort instead of forcing a team swap
            if not IsNightmareLevelingAutomationEnabled() then
                return false
            end

            Window:ShowInfo("Auto Nightmare + Leveling", "Waiting to switch back to Core Pet Team...")
            task.wait(1)
        end

        Window:ShowInfo("Auto Nightmare + Leveling", "Starting Nightmare Mutation (combo) for new target pet")

        Window:SetConfigValue("CorePetTeam", nightMarePetTeam)
        local equippedFromTeam = self:ChangeTeamPets(nightMarePetTeam, "core") or 0

        local maxPets = 8
        local availableSlots = maxPets - equippedFromTeam

        for i, petID in ipairs(petIDs) do
            if i > availableSlots then break end
            self:EquipPet(petID)
            task.wait(0.25)
        end

        return false
    end

    function m:StartAutoLeveling()
        local autoLeveling = Window:GetConfigValue("AutoLevelingPets") or false
        local levelToReach = Window:GetConfigValue("LevelToReach") or 100
        local levelingPetTeam = Window:GetConfigValue("LevelingPetTeam") or nil

        if not autoLeveling then
            return
        end

        if levelToReach < 1 then
            Window:ShowWarning("Auto Leveling", "Invalid level to reach for Auto Leveling: " .. levelToReach)
            return
        end

        if not levelingPetTeam then
            Window:ShowWarning("Auto Leveling", "No Leveling Pet Team selected.")
            return
        end

        local petIDs = Window:GetConfigValue("LevelingPets") or {}
        if #petIDs == 0 then
            Window:ShowWarning("Auto Leveling", "No pets selected for Auto Leveling.")
            return
        end

        local isPetIDAlreadyAtTargetLevel = ""
        local isNoActivePet = true

        for _, petID in pairs(petIDs) do
            local petDetail = self:GetPetDetail(petID)
            if not petDetail then
                Window:ShowWarning("Auto Leveling"," Pet detail not found for UUID: " .. petID)
                continue
            end

            if not petDetail.IsActive then
                continue
            end

            isNoActivePet = false
            if petDetail.Age >= levelToReach then
                Window:ShowInfo("Auto Leveling", "Pet already reached the target level: " .. petDetail.Name)
                task.spawn(function() 
                    Webhook:Leveling(petDetail.Type, petDetail.Age, #petIDs - 1)
                end)

                isPetIDAlreadyAtTargetLevel = petID
                break
            end
        end

        if isPetIDAlreadyAtTargetLevel ~= "" then
            self:UnequipPet(isPetIDAlreadyAtTargetLevel)
            task.wait(1)

            for index, id in ipairs(petIDs) do
                if id == isPetIDAlreadyAtTargetLevel then
                    table.remove(petIDs, index)
                    break
                end
            end

            Window:SetConfigValue("LevelingPets", petIDs)

            isNoActivePet = true
        end

        if not isNoActivePet then
            return
        end

        while not self:IsSafeChangeTeamPets() do
            print("Waiting to switch back to Core Pet Team...")
            task.wait(1)
        end

        Window:ShowInfo("Auto Leveling", "Starting Auto Leveling New Target Pet")

        Window:SetConfigValue("CorePetTeam", levelingPetTeam)
        local equippedFromTeam = self:ChangeTeamPets(levelingPetTeam, "core") or 0

        local maxPets = 8
        local availableSlots = maxPets - equippedFromTeam

        for i, petID in ipairs(petIDs) do
            if i > availableSlots then break end
            self:EquipPet(petID)
            task.wait(0.25)
        end
    end

    function m:StartAutoLeveling1_Combo()
        -- Leveling phase 1: from age 1 to 40
        -- IMPORTANT: Do NOT remove pets from list when they reach age 40
        -- They need to stay in the list for leveling2 (40-100)
        local levelToReach = 40
        local levelingPetTeam = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam1") or nil
        local petIDs = Window:GetConfigValue("NightmareAndLevelingLevelingPets") or {}

        if not IsNightmareLevelingAutomationEnabled() then
            return false
        end

        -- Check if we're in Leveling First mode
        local priority = Window:GetConfigValue("IdleNightmareLevelingPriority") or "MutationFirst"

        -- Filter to only Nightmare pets (but skip this filter in Leveling First mode)
        if priority ~= "LevelingFirst" and #petIDs > 0 then
            local filtered = {}

            for _, petID in ipairs(petIDs) do
                local petDetail = self:GetPetDetail(petID)
                if petDetail and petDetail.Mutation == "Nightmare" then
                    table.insert(filtered, petID)
                else
                    if petDetail then
                        Window:ShowInfo(
                            "Auto Nightmare + Leveling (1-40)",
                            "Skipping leveling for non-Nightmare pet: " .. tostring(petDetail.Name)
                        )
                    else
                        Window:ShowWarning(
                            "Auto Nightmare + Leveling (1-40)",
                            "Skipping leveling for pet with missing detail: " .. tostring(petID)
                        )
                    end
                end
            end

            petIDs = filtered
            Window:SetConfigValue("NightmareAndLevelingLevelingPets", petIDs)
        end

        if #petIDs == 0 then
            Window:ShowInfo("Auto Nightmare + Leveling (1-40)", "No pets remain for combo leveling 1-40; marking phase complete.")
            return true
        end

        if not levelingPetTeam then
            Window:ShowWarning("Auto Nightmare + Leveling (1-40)", "No Leveling Pet Team 1-40 selected for combo.")
            return true
        end

        -- Check if ALL pets have reached age 40 (phase 1 complete)
        local allPetsReachedLevel1 = true
        local petsStillNeedLeveling = {}

        for _, petID in ipairs(petIDs) do
            local petDetail = self:GetPetDetail(petID)
            if petDetail and petDetail.Age < levelToReach then
                allPetsReachedLevel1 = false
                table.insert(petsStillNeedLeveling, petID)
            end
        end

        -- If all pets have reached age 40, phase 1 is complete
        if allPetsReachedLevel1 then
            Window:ShowInfo("Auto Nightmare + Leveling (1-40)", "All pets have reached age 40. Moving to phase 2 (40-100).")
            return true
        end

        local isPetIDAlreadyAtTargetLevel = ""
        local isNoActivePet = true

        for _, petID in pairs(petIDs) do
            if not IsNightmareLevelingAutomationEnabled() then
                return false
            end

            local petDetail = self:GetPetDetail(petID)
            if not petDetail then
                Window:ShowWarning("Auto Nightmare + Leveling (1-40)", "Pet detail not found for UUID: " .. petID)
                continue
            end

            if not petDetail.IsActive then
                continue
            end

            isNoActivePet = false

            -- Pet reached age 40 - just unequip, don't remove from list
            if petDetail.Age >= levelToReach then
                Window:ShowInfo("Auto Nightmare + Leveling (1-40)", "Pet reached age 40 (combo): " .. petDetail.Name)
                task.spawn(function()
                    Webhook:Leveling(petDetail.Type, petDetail.Age, #petsStillNeedLeveling)
                end)

                isPetIDAlreadyAtTargetLevel = petID
                break
            end
        end

        if isPetIDAlreadyAtTargetLevel ~= "" then
            self:UnequipPet(isPetIDAlreadyAtTargetLevel)
            task.wait(1)
            -- NOTE: Do NOT remove from petIDs list - pet needs to continue to leveling2
            isNoActivePet = true
        end

        -- Check again if all pets now have age >= 40
        allPetsReachedLevel1 = true
        for _, petID in ipairs(petIDs) do
            local petDetail = self:GetPetDetail(petID)
            if petDetail and petDetail.Age < levelToReach then
                allPetsReachedLevel1 = false
                break
            end
        end

        if allPetsReachedLevel1 then
            Window:ShowInfo("Auto Nightmare + Leveling (1-40)", "All pets have reached age 40. Moving to phase 2 (40-100).")
            return true
        end

        if not isNoActivePet then
            return false
        end

        while not self:IsSafeChangeTeamPets() do
            if not IsNightmareLevelingAutomationEnabled() then
                return false
            end

            print("Waiting to switch back to Core Pet Team (combo leveling 1-40)...")
            task.wait(1)
        end

        Window:ShowInfo("Auto Nightmare + Leveling (1-40)", "Starting combo Auto Leveling 1-40 for new target pet")

        Window:SetConfigValue("CorePetTeam", levelingPetTeam)
        local equippedFromTeam = self:ChangeTeamPets(levelingPetTeam, "core") or 0

        local maxPets = 8
        local availableSlots = maxPets - equippedFromTeam

        -- Only equip pets that still need leveling (age < 40)
        local equippedCount = 0
        for _, petID in ipairs(petsStillNeedLeveling) do
            if equippedCount >= availableSlots then break end
            self:EquipPet(petID)
            equippedCount = equippedCount + 1
            task.wait(0.25)
        end

        return false
    end

    function m:StartAutoLeveling2_Combo()
        -- Leveling phase 2: from age 40 to 100
        local levelToReach = 100
        local levelingPetTeam = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam2") or nil
        local petIDs = Window:GetConfigValue("NightmareAndLevelingLevelingPets") or {}

        if not IsNightmareLevelingAutomationEnabled() then
            return false
        end

        -- Check if we're in Leveling First mode
        local priority = Window:GetConfigValue("IdleNightmareLevelingPriority") or "MutationFirst"

        -- Filter to only Nightmare pets (but skip this filter in Leveling First mode)
        if priority ~= "LevelingFirst" and #petIDs > 0 then
            local filtered = {}

            for _, petID in ipairs(petIDs) do
                local petDetail = self:GetPetDetail(petID)
                if petDetail and petDetail.Mutation == "Nightmare" then
                    table.insert(filtered, petID)
                else
                    if petDetail then
                        Window:ShowInfo(
                            "Auto Nightmare + Leveling (40-100)",
                            "Skipping leveling for non-Nightmare pet: " .. tostring(petDetail.Name)
                        )
                    else
                        Window:ShowWarning(
                            "Auto Nightmare + Leveling (40-100)",
                            "Skipping leveling for pet with missing detail: " .. tostring(petID)
                        )
                    end
                end
            end

            petIDs = filtered
            Window:SetConfigValue("NightmareAndLevelingLevelingPets", petIDs)
        end

        if #petIDs == 0 then
            Window:ShowInfo("Auto Nightmare + Leveling (40-100)", "No pets remain for combo leveling 40-100; marking phase complete.")
            return true
        end

        if not levelingPetTeam then
            Window:ShowWarning("Auto Nightmare + Leveling (40-100)", "No Leveling Pet Team 40-100 selected for combo.")
            return true
        end

        local isPetIDAlreadyAtTargetLevel = ""
        local isNoActivePet = true

        for _, petID in pairs(petIDs) do
            if not IsNightmareLevelingAutomationEnabled() then
                return false
            end

            local petDetail = self:GetPetDetail(petID)
            if not petDetail then
                Window:ShowWarning("Auto Nightmare + Leveling (40-100)", "Pet detail not found for UUID: " .. petID)
                continue
            end

            if not petDetail.IsActive then
                continue
            end

            isNoActivePet = false
            if petDetail.Age >= levelToReach then
                Window:ShowInfo("Auto Nightmare + Leveling (40-100)", "Pet already reached age 100 (combo): " .. petDetail.Name)
                task.spawn(function()
                    Webhook:Leveling(petDetail.Type, petDetail.Age, #petIDs - 1)
                end)

                isPetIDAlreadyAtTargetLevel = petID
                break
            end
        end

        if isPetIDAlreadyAtTargetLevel ~= "" then
            self:UnequipPet(isPetIDAlreadyAtTargetLevel)
            task.wait(1)

            for index, id in ipairs(petIDs) do
                if id == isPetIDAlreadyAtTargetLevel then
                    table.remove(petIDs, index)
                    break
                end
            end

            Window:SetConfigValue("NightmareAndLevelingLevelingPets", petIDs)
            isNoActivePet = true
        end

        if #petIDs == 0 then
            Window:SetConfigValue("NightmareAndLevelingLevelingPets", petIDs)
            return true
        end

        if not isNoActivePet then
            return false
        end

        while not self:IsSafeChangeTeamPets() do
            if not IsNightmareLevelingAutomationEnabled() then
                return false
            end

            print("Waiting to switch back to Core Pet Team (combo leveling 40-100)...")
            task.wait(1)
        end

        Window:ShowInfo("Auto Nightmare + Leveling (40-100)", "Starting combo Auto Leveling 40-100 for new target pet")

        Window:SetConfigValue("CorePetTeam", levelingPetTeam)
        local equippedFromTeam = self:ChangeTeamPets(levelingPetTeam, "core") or 0

        local maxPets = 8
        local availableSlots = maxPets - equippedFromTeam

        for i, petID in ipairs(petIDs) do
            if i > availableSlots then break end
            self:EquipPet(petID)
            task.wait(0.25)
        end

        return false
    end

    function m:StartAutoBulking()
        local autoBulking = Window:GetConfigValue("AutoBulkingPets") or false
        local bulkingPetTeam = Window:GetConfigValue("BulkingPetTeam") or nil
        local petIDs = Window:GetConfigValue("BulkingPets") or {}
        local bulkToReach = Window:GetConfigValue("BulkingToWeight") or 1

        if not autoBulking then
            return
        end

        if not bulkingPetTeam then
            Window:ShowWarning("Auto Bulking", "No Bulking Pet Team selected.")
            return
        end

        if #petIDs == 0 then
            Window:ShowWarning("Auto Bulking", "No pets selected for Auto Bulking.")
            return
        end

        local isPetIDAlreadyAtTargetWeight = ""
        local isNoActivePet = true

        for _, petID in pairs(petIDs) do
            local petDetail = self:GetPetDetail(petID)
            if not petDetail then
                Window:ShowWarning("Auto Bulking", "Pet detail not found for UUID: " .. petID)
                continue
            end

            if not petDetail.IsActive then
                continue
            end

            isNoActivePet = false
            if petDetail.BaseWeight >= bulkToReach then
                Window:ShowInfo("Auto Bulking", "Pet already reached the target weight: " .. petDetail.Name)
                -- Calculate weight at age 1 for webhook display
                local baseWeight = petDetail.BaseWeight or 1
                local weightAge1 = baseWeight * 1.1
                task.spawn(function()
                    Webhook:Bulking(petDetail.Type, weightAge1, #petIDs - 1)
                end)

                isPetIDAlreadyAtTargetWeight = petID
                break
            end
        end

        if isPetIDAlreadyAtTargetWeight ~= "" then
            self:UnequipPet(isPetIDAlreadyAtTargetWeight)
            task.wait(1)

            for index, id in ipairs(petIDs) do
                if id == isPetIDAlreadyAtTargetWeight then
                    table.remove(petIDs, index)
                    break
                end
            end

            Window:SetConfigValue("BulkingPets", petIDs)

            isNoActivePet = true
        end

        if not isNoActivePet then
            return
        end

        while not self:IsSafeChangeTeamPets() do
            task.wait(1)
        end

        Window:SetConfigValue("CorePetTeam", bulkingPetTeam)
        local equippedFromTeam = self:ChangeTeamPets(bulkingPetTeam, "core") or 0

        local maxPets = 8
        local availableSlots = maxPets - equippedFromTeam

        for i, petID in ipairs(petIDs) do
            if i > availableSlots then break end
            self:EquipPet(petID)
            task.wait(0.25)
        end
    end

    function m:StartAutoBulkingV2()
        local autoBulkingV2 = Window:GetConfigValue("AutoBulkingPetsV2") or false

        -- When the toggle is off, reset the internal state and exit.
        if not autoBulkingV2 then
            LastAutoBulkingV2State = false
            BulkingV2NotifiedPets = {} -- Reset webhook tracking
            BulkingV2LastLogState = {} -- Reset log state tracking
            return
        end

        -- Detect first tick after the user turns Auto Bulking V2 ON.
        -- On that transition, always reset the stage to "leveling" so the run
        -- starts from the Leveling Pet Team and does not immediately resume an old Elephant stage.
        if not LastAutoBulkingV2State then
            Window:SetConfigValue("BulkingStageV2", "leveling")
            BulkingV2NotifiedPets = {} -- Reset webhook tracking on fresh start
            BulkingV2LastLogState = {} -- Reset log state tracking on fresh start
        end
        LastAutoBulkingV2State = true

        local bulkToReach = Window:GetConfigValue("BulkingToWeightV2") or 1

        local levelingBulkingPetTeam = Window:GetConfigValue("LevelingBulkingPetTeam") or nil
        local elephantPetTeam = Window:GetConfigValue("BulkingPetTeamV2") or nil
        local levelToReachBeforeElephant = Window:GetConfigValue("LevelToReachBeforeElephantV2") or 50
        local configuredTargets = Window:GetConfigValue("BulkingPetsV2") or {}

        if not levelingBulkingPetTeam or levelingBulkingPetTeam == "" then
            Window:ShowWarning("Auto Bulking V2", "No Leveling Pet Team selected for Bulking V2.")
            return
        end

        if not elephantPetTeam or elephantPetTeam == "" then
            Window:ShowWarning("Auto Bulking V2", "No Elephant Pet Team selected for Bulking V2.")
            return
        end

        if #configuredTargets == 0 then
            Window:ShowWarning("Auto Bulking V2", "No target pets selected for Bulking V2.")
            return
        end

        local bulkingStage = Window:GetConfigValue("BulkingStageV2") or "leveling"

        local targetSet = {}
        for _, v in ipairs(configuredTargets) do
            targetSet[tostring(v)] = true
        end

        local allPets = self:GetAllMyPets() or {}
        local candidatePets = {}
        for _, pet in ipairs(allPets) do
            local isTarget = targetSet[tostring(pet.ID)]
                or targetSet[tostring(pet.Type)]
                or targetSet[tostring(pet.Name)]
            if isTarget then
                local currentWeight = tonumber(pet.BaseWeight) or 0
                local underTarget = currentWeight < bulkToReach

                if underTarget then
                    -- Pet still needs leveling/bulking
                    table.insert(candidatePets, pet)
                else
                    -- Pet has reached target weight - send webhook immediately if not notified
                    if not BulkingV2NotifiedPets[tostring(pet.ID)] then
                        BulkingV2NotifiedPets[tostring(pet.ID)] = true

                        -- Count remaining pets under target for webhook
                        local remainingCount = 0
                        for _, p in ipairs(allPets) do
                            local pIsTarget = targetSet[tostring(p.ID)]
                                or targetSet[tostring(p.Type)]
                                or targetSet[tostring(p.Name)]
                            if pIsTarget and p.ID ~= pet.ID then
                                local pWeight = tonumber(p.BaseWeight) or 0
                                if pWeight < bulkToReach then
                                    remainingCount = remainingCount + 1
                                end
                            end
                        end

                        -- Calculate weight at age 1 for webhook display
                        local weightAge1 = currentWeight * 1.1

                        Window:ShowInfo(
                            "Auto Bulking V2",
                            string.format(
                                "Pet %s reached target weight %.2f KG (Remaining: %d)",
                                tostring(pet.Type or pet.Name),
                                currentWeight,
                                remainingCount
                            )
                        )

                        -- Send webhook notification with age 1 weight
                        task.spawn(function()
                            Webhook:Bulking(pet.Type or pet.Name, weightAge1, remainingCount)
                        end)
                    end
                    -- Pet is excluded from candidatePets - no more leveling needed
                end
            end
        end

        -- Pre-check: if no pet has yet reached the Elephant age threshold, always start in LEVELING stage.
        -- This prevents the script from jumping to the Elephant team when nothing is ready.
        -- IMPORTANT: Use fresh pet data (GetPetDetail) instead of cached age to avoid race conditions
        local hasElephantReady = false
        for _, pet in ipairs(candidatePets) do
            local petDetail = self:GetPetDetail(pet.ID)
            if petDetail then
                local age = tonumber(petDetail.Age) or 0
                if age >= levelToReachBeforeElephant then
                    hasElephantReady = true
                    break
                end
            end
        end

        if not hasElephantReady and bulkingStage == "elephant" then
            bulkingStage = "leveling"
            Window:SetConfigValue("BulkingStageV2", "leveling")
        end

        if #candidatePets == 0 then
            Window:ShowInfo("Auto Bulking V2", "No target pets remain under the target base weight for Bulking V2.")
            Window:SetConfigValue("BulkingStageV2", "leveling")
            return
        end

        local function ensureTeam(targetTeamName, label)
            if not targetTeamName or targetTeamName == "" then
                Window:ShowWarning("Auto Bulking V2", "No " .. label .. " Pet Team selected for Bulking V2.")
                return false
            end

            local currentCoreTeam = Window:GetConfigValue("CorePetTeam")
            local activePets = self:GetAllActivePets() or {}
            local activeCount = 0
            for _, _ in pairs(activePets) do
                activeCount = activeCount + 1
            end

            if currentCoreTeam == targetTeamName and activeCount > 0 then
                return true
            end

            while not self:IsSafeChangeTeamPets() do
                task.wait(1)
            end

            -- Switch team (no UI spam)
            Window:SetConfigValue("CorePetTeam", targetTeamName)
            self:ChangeTeamPets(targetTeamName, "core")
            return true
        end

        if bulkingStage == "leveling" then
            local totalSlots = 8

            -- Get leveling team pets list first
            local levelingTeamPets = {}
            local successLT, resultLT = pcall(function()
                return PetTeam:FindPetTeam(levelingBulkingPetTeam)
            end)

            if successLT and resultLT then
                levelingTeamPets = resultLT
            end

            -- Build sets for quick lookup
            local targetPetIDSet = {}
            for _, pet in ipairs(candidatePets) do
                targetPetIDSet[pet.ID] = true
            end

            local levelingTeamIDSet = {}
            for _, petID in ipairs(levelingTeamPets) do
                levelingTeamIDSet[petID] = true
            end

            -- Get current active pets
            local activePetsMap = self:GetAllActivePets() or {}
            local activeCount = 0
            for _, _ in pairs(activePetsMap) do
                activeCount = activeCount + 1
            end

            -- STEP 0: Unequip target pets that have already reached target weight (free up slots)
            local unequippedCompleted = false
            for petID, _ in pairs(activePetsMap) do
                if targetPetIDSet[petID] then
                    -- Get fresh pet data to check current weight
                    local petDetail = self:GetPetDetail(petID)
                    if petDetail then
                        local currentWeight = tonumber(petDetail.BaseWeight) or 0
                        if currentWeight >= bulkToReach then
                            -- Pet has reached target weight - unequip it
                            self:UnequipPet(petID)
                            unequippedCompleted = true
                            task.wait(0.25)

                            -- Send webhook if not already notified (no UI spam)
                            if not BulkingV2NotifiedPets[tostring(petID)] then
                                BulkingV2NotifiedPets[tostring(petID)] = true
                                -- Calculate weight at age 1 for webhook display
                                local weightAge1 = currentWeight * 1.1
                                task.spawn(function()
                                    Webhook:Bulking(petDetail.Type or petDetail.Name, weightAge1, #candidatePets)
                                end)
                            end
                        end
                    end
                end
            end

            if unequippedCompleted then
                task.wait(0.5)
                activePetsMap = self:GetAllActivePets() or {}
                activeCount = 0
                for _, _ in pairs(activePetsMap) do
                    activeCount = activeCount + 1
                end
            end

            -- STEP 1: Unequip pets that are neither target pets nor leveling team pets
            local unequippedAny = false
            for petID, _ in pairs(activePetsMap) do
                if not targetPetIDSet[petID] and not levelingTeamIDSet[petID] then
                    self:UnequipPet(petID)
                    unequippedAny = true
                    task.wait(0.25)
                end
            end

            if unequippedAny then
                task.wait(0.5)
                activePetsMap = self:GetAllActivePets() or {}
                activeCount = 0
                for _, _ in pairs(activePetsMap) do
                    activeCount = activeCount + 1
                end
            end

            -- STEP 2: Equip ALL leveling team pets FIRST (team must be complete)
            for _, petID in ipairs(levelingTeamPets) do
                if activePetsMap[petID] then continue end

                if activeCount >= totalSlots then break end

                self:EquipPet(petID)
                task.wait(0.3)

                local verifyPets = self:GetAllActivePets() or {}
                if verifyPets[petID] then
                    activePetsMap[petID] = true
                    activeCount = activeCount + 1
                end
            end

            -- Refresh after equipping team
            task.wait(0.3)
            activePetsMap = self:GetAllActivePets() or {}
            activeCount = 0
            for _, _ in pairs(activePetsMap) do
                activeCount = activeCount + 1
            end

            local freeSlots = totalSlots - activeCount

            -- Get max target pets limit for Leveling Phase
            -- Use specific setting for Leveling Phase V2, default to 8 (fill all slots)
            local maxTargetPets = Window:GetConfigValue("MaxTargetPetsLevelingPhaseV2") or 8

            -- Count active targets
            local activeTargetCount = 0
            local activeTargetPetIDs = {}
            for _, pet in ipairs(candidatePets) do
                if activePetsMap[pet.ID] then
                    activeTargetCount = activeTargetCount + 1
                    table.insert(activeTargetPetIDs, pet.ID)
                end
            end

            -- STEP 2.5: Unequip EXTRA target pets if exceeding max limit
            if activeTargetCount > maxTargetPets then
                local excessCount = activeTargetCount - maxTargetPets

                -- Unequip excess target pets (from the end of the list)
                for i = #activeTargetPetIDs, 1, -1 do
                    if excessCount <= 0 then break end

                    local petID = activeTargetPetIDs[i]
                    self:UnequipPet(petID)
                    activePetsMap[petID] = nil
                    activeCount = activeCount - 1
                    activeTargetCount = activeTargetCount - 1
                    excessCount = excessCount - 1
                    task.wait(0.25)
                end

                task.wait(0.5)
                activePetsMap = self:GetAllActivePets() or {}
                activeCount = 0
                for _, _ in pairs(activePetsMap) do
                    activeCount = activeCount + 1
                end
                freeSlots = totalSlots - activeCount
            end

            -- Track state for internal logic (no UI spam)
            local levelingStateKey = string.format("leveling_%d_%d_%d_%d", activeCount, freeSlots, #candidatePets, activeTargetCount)
            BulkingV2LastLogState.leveling = levelingStateKey

            -- STEP 3: Fill remaining slots with target pets (limited by MaxTargetPetsLevelingPhaseV2)
            local targetPetsToEquip = maxTargetPets - activeTargetCount

            if freeSlots > 0 and targetPetsToEquip > 0 then
                for _, pet in ipairs(candidatePets) do
                    if freeSlots <= 0 or targetPetsToEquip <= 0 then break end

                    -- Get fresh pet detail to check IsActive status
                    local petDetail = self:GetPetDetail(pet.ID)
                    if not petDetail then continue end

                    -- Only equip if pet is NOT already active (prevent stacking)
                    if not petDetail.IsActive then
                        self:EquipPet(pet.ID)
                        task.wait(0.75) -- Match reference delay

                        -- Verify equip
                        local verifyDetail = self:GetPetDetail(pet.ID)
                        if verifyDetail and verifyDetail.IsActive then
                            activePetsMap[pet.ID] = true
                            activeCount = activeCount + 1
                            freeSlots = totalSlots - activeCount
                            activeTargetCount = activeTargetCount + 1
                            targetPetsToEquip = targetPetsToEquip - 1
                        end
                    else
                        -- Pet already active
                         -- Ensure we count it towards the limit so we don't over-equip
                        activeTargetCount = activeTargetCount + 1
                        targetPetsToEquip = targetPetsToEquip - 1
                    end
                end
            end

            -- Final refresh of active pets for the next checks
            task.wait(0.3)
            activePetsMap = self:GetAllActivePets() or {}

            local hasActiveTarget = false
            local petsReadyForElephant = {}

            -- Check if any target pets are active
            for _, pet in ipairs(candidatePets) do
                if activePetsMap[pet.ID] then
                    hasActiveTarget = true
                    break
                end
            end

            -- Scan ALL candidate pets (active or not) to check if any have reached age threshold
            -- This ensures pets in inventory that reached age are not forgotten
            for _, pet in ipairs(candidatePets) do
                -- Fetch fresh pet details to get current age
                local petDetail = self:GetPetDetail(pet.ID)
                if not petDetail then
                    -- Try using stored age from candidatePets as fallback
                    local storedAge = tonumber(pet.Age) or 0
                    if storedAge >= levelToReachBeforeElephant then
                        table.insert(petsReadyForElephant, pet.ID)
                    end
                    continue
                end

                local petAge = tonumber(petDetail.Age) or 0

                -- Switch to Elephant stage when pet reaches the configured age threshold
                if petAge >= levelToReachBeforeElephant then
                    -- Track ready state (no UI spam)
                    local readyLogKey = "ready_" .. tostring(pet.ID)
                    BulkingV2LastLogState[readyLogKey] = true

                    table.insert(petsReadyForElephant, pet.ID)
                end
            end

            -- If any pets are ready for elephant, switch to elephant stage
            -- Don't unequip here - let elephant stage handle the team switching
            if #petsReadyForElephant > 0 then
                -- Store the ready pet IDs for elephant stage to use
                BulkingV2LastLogState.readyForElephant = petsReadyForElephant

                -- Switch to elephant stage - team switching will be handled there
                Window:SetConfigValue("BulkingStageV2", "elephant")
                return
            end

            if not hasActiveTarget then
                return
            end

            return
        elseif bulkingStage == "elephant" then

            -- First, determine which candidate pets are actually ready for Elephant (age threshold)
            local leveledPets = {}

            -- Check if we have stored pet IDs from leveling stage transition
            local storedReadyPets = BulkingV2LastLogState.readyForElephant or {}

            for _, pet in ipairs(candidatePets) do
                -- Fetch fresh pet details to get current age (fix for stale age data bug)
                local petDetail = self:GetPetDetail(pet.ID)
                if not petDetail then
                    -- If pet detail not found but this pet was marked as ready, still include it
                    -- This handles race conditions after team switching
                    if table.find(storedReadyPets, pet.ID) then
                        -- Use the data from candidatePets as fallback
                        table.insert(leveledPets, {
                            ID = pet.ID,
                            Name = pet.Name or "Unknown",
                            Type = "Unknown",
                            BaseWeight = pet.BaseWeight or 0,
                            Age = pet.Age or 0
                        })
                    end
                    continue
                end

                local age = tonumber(petDetail.Age) or 0

                -- Check if pet meets age threshold OR was marked as ready from leveling stage
                local meetsAgeThreshold = age >= levelToReachBeforeElephant
                local wasMarkedReady = table.find(storedReadyPets, pet.ID) ~= nil

                if meetsAgeThreshold or wasMarkedReady then
                    table.insert(leveledPets, petDetail)
                end
            end

            -- Clear the stored ready pets after using them
            BulkingV2LastLogState.readyForElephant = nil

            -- If nothing is actually ready, go back to leveling
            -- But only if we've been in elephant stage for a while (not immediately after switching)
            if #leveledPets == 0 then
                -- Check if we just switched to elephant stage
                if #storedReadyPets > 0 then
                    -- We just switched but couldn't find the pets - wait and retry
                    return
                end

                -- No leveled pets detected - return to leveling stage (no UI spam)
                Window:SetConfigValue("BulkingStageV2", "leveling")
                -- Let leveling stage handle equipping on next cycle
                return
            end

            -- Calculate how many target pets we want to equip (limited by MaxTargetPetsElephantPhaseV2 to leave room for auto pickup pets)
            local maxTargetPets = Window:GetConfigValue("MaxTargetPetsElephantPhaseV2") or 3
            local targetPetCount = math.min(#leveledPets, maxTargetPets)
            local totalSlots = 8

            -- Get elephant team pets list first
            local elephantTeamPets = {}
            local success, result = pcall(function()
                return PetTeam:FindPetTeam(elephantPetTeam)
            end)

            if success and result then
                elephantTeamPets = result
            end

            -- Build sets for quick lookup
            local targetPetIDSet = {}
            for _, pet in ipairs(leveledPets) do
                targetPetIDSet[pet.ID] = true
            end

            local elephantTeamIDSet = {}
            for _, petID in ipairs(elephantTeamPets) do
                elephantTeamIDSet[petID] = true
            end

            -- Get current active pets
            local activePetsMap = self:GetAllActivePets() or {}
            local activeCount = 0
            for _, _ in pairs(activePetsMap) do
                activeCount = activeCount + 1
            end

            -- STEP 0: Unequip target pets that have already reached target weight (free up slots)
            local unequippedCompleted = false
            for petID, _ in pairs(activePetsMap) do
                if targetPetIDSet[petID] then
                    -- Get fresh pet data to check current weight
                    local petDetail = self:GetPetDetail(petID)
                    if petDetail then
                        local currentWeight = tonumber(petDetail.BaseWeight) or 0
                        if currentWeight >= bulkToReach then
                            -- Pet has reached target weight - unequip it
                            self:UnequipPet(petID)
                            unequippedCompleted = true
                            task.wait(0.25)

                            -- Send webhook if not already notified (no UI spam)
                            if not BulkingV2NotifiedPets[tostring(petID)] then
                                BulkingV2NotifiedPets[tostring(petID)] = true
                                -- Calculate weight at age 1 for webhook display
                                local weightAge1 = currentWeight * 1.1
                                task.spawn(function()
                                    Webhook:Bulking(petDetail.Type or petDetail.Name, weightAge1, #leveledPets - 1)
                                end)
                            end

                            -- Remove from leveledPets list
                            for i, pet in ipairs(leveledPets) do
                                if pet.ID == petID then
                                    table.remove(leveledPets, i)
                                    targetPetIDSet[petID] = nil
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if unequippedCompleted then
                task.wait(0.5)
                activePetsMap = self:GetAllActivePets() or {}
                activeCount = 0
                for _, _ in pairs(activePetsMap) do
                    activeCount = activeCount + 1
                end

                -- If no more leveled pets remain, go back to leveling stage (no UI spam)
                if #leveledPets == 0 then
                    Window:SetConfigValue("BulkingStageV2", "leveling")
                    return
                end

                -- Recalculate targetPetCount after removing completed pets
                targetPetCount = math.min(#leveledPets, maxTargetPets)
            end

            -- STEP 1: Unequip pets that are neither target pets nor elephant team pets
            local unequippedAny = false
            for petID, _ in pairs(activePetsMap) do
                if not targetPetIDSet[petID] and not elephantTeamIDSet[petID] then
                    self:UnequipPet(petID)
                    unequippedAny = true
                    task.wait(0.25)
                end
            end

            if unequippedAny then
                task.wait(0.5)
                activePetsMap = self:GetAllActivePets() or {}
                activeCount = 0
                for _, _ in pairs(activePetsMap) do
                    activeCount = activeCount + 1
                end
            end

            -- STEP 2: Count current state
            local activeTargetCount = 0
            local activeTargetPetIDs = {}
            for _, pet in ipairs(leveledPets) do
                if activePetsMap[pet.ID] then
                    activeTargetCount = activeTargetCount + 1
                    table.insert(activeTargetPetIDs, pet.ID)
                end
            end

            local freeSlots = totalSlots - activeCount

            -- STEP 2.5: Unequip EXTRA target pets if exceeding max limit
            if activeTargetCount > maxTargetPets then
                local excessCount = activeTargetCount - maxTargetPets

                -- Unequip excess target pets (from the end of the list)
                for i = #activeTargetPetIDs, 1, -1 do
                    if excessCount <= 0 then break end

                    local petID = activeTargetPetIDs[i]
                    self:UnequipPet(petID)
                    activePetsMap[petID] = nil
                    activeCount = activeCount - 1
                    activeTargetCount = activeTargetCount - 1
                    excessCount = excessCount - 1
                    task.wait(0.25)
                end

                task.wait(0.5)
                activePetsMap = self:GetAllActivePets() or {}
                activeCount = 0
                for _, _ in pairs(activePetsMap) do
                    activeCount = activeCount + 1
                end
                freeSlots = totalSlots - activeCount

                -- Recalculate targetPetCount after unequipping excess
                targetPetCount = math.min(#leveledPets, maxTargetPets)
            end

            -- STEP 3: If we need more slots for target pets, unequip some elephant team pets
            local targetPetsNeeded = targetPetCount - activeTargetCount
            if targetPetsNeeded > 0 and freeSlots < targetPetsNeeded then
                local slotsToFree = targetPetsNeeded - freeSlots

                for _, petID in ipairs(elephantTeamPets) do
                    if slotsToFree <= 0 then break end
                    if not targetPetIDSet[petID] and activePetsMap[petID] then
                        self:UnequipPet(petID)
                        activePetsMap[petID] = nil
                        activeCount = activeCount - 1
                        slotsToFree = slotsToFree - 1
                        task.wait(0.25)
                    end
                end

                task.wait(0.5)
                activePetsMap = self:GetAllActivePets() or {}
                activeCount = 0
                for _, _ in pairs(activePetsMap) do
                    activeCount = activeCount + 1
                end
            end

            freeSlots = totalSlots - activeCount

            -- Recount active targets after potential unequips
            activeTargetCount = 0
            for _, pet in ipairs(leveledPets) do
                if activePetsMap[pet.ID] then
                    activeTargetCount = activeTargetCount + 1
                end
            end

            -- Track state for internal logic (no UI spam)
            local elephantStateKey = string.format("elephant_%d_%d_%d_%d", activeCount, freeSlots, #leveledPets, activeTargetCount)
            BulkingV2LastLogState.elephant = elephantStateKey

            -- STEP 4: Equip TARGET PETS FIRST (priority)
            for i = 1, targetPetCount do
                local pet = leveledPets[i]
                if not pet then break end

                if freeSlots <= 0 then
                    -- No more slots available
                    break
                end

                -- Get fresh pet detail to check IsActive status
                local petDetail = self:GetPetDetail(pet.ID)
                if not petDetail then continue end

                -- Only equip if pet is NOT already active (prevent stacking)
                if not petDetail.IsActive then
                    self:EquipPet(pet.ID)
                    task.wait(0.75) -- Match reference delay

                    -- Verify equip
                    local verifyDetail = self:GetPetDetail(pet.ID)
                    if verifyDetail and verifyDetail.IsActive then
                        activePetsMap[pet.ID] = true
                        activeCount = activeCount + 1
                        freeSlots = totalSlots - activeCount
                        activeTargetCount = activeTargetCount + 1

                        -- Track equip state (no UI spam)
                        local equipLogKey = "equipped_elephant_" .. tostring(pet.ID)
                        BulkingV2LastLogState[equipLogKey] = true
                    end
                else
                    -- Pet already active, just count it
                    activeTargetCount = activeTargetCount + 1
                end
            end

            -- STEP 5: Fill remaining slots with elephant team pets
            if freeSlots > 0 then
                for _, petID in ipairs(elephantTeamPets) do
                    if freeSlots <= 0 then break end

                    -- Get fresh pet detail to check IsActive status
                    local petDetail = self:GetPetDetail(petID)
                    if not petDetail then continue end

                    -- Only equip if pet is NOT already active (prevent stacking)
                    if not petDetail.IsActive then
                        self:EquipPet(petID)
                        task.wait(0.75) -- Match reference delay

                        local verifyDetail = self:GetPetDetail(petID)
                        if verifyDetail and verifyDetail.IsActive then
                            activePetsMap[petID] = true
                            activeCount = activeCount + 1
                            freeSlots = totalSlots - activeCount
                        end
                    end
                end
            end

            -- Final refresh of active pets for the next checks
            task.wait(0.3)
            activePetsMap = self:GetAllActivePets() or {}

            local allFinished = true
            local needsElephant = false
            local remainingPets = 0

            -- Count total pets still under target weight from ALL candidate pets (not just leveled ones)
            -- This gives accurate "remaining in queue" count for webhook
            for _, pet in ipairs(candidatePets) do
                local petDetail = self:GetPetDetail(pet.ID)
                if not petDetail then
                    -- Can't verify - assume pet still needs processing
                    remainingPets = remainingPets + 1
                else
                    local weight = tonumber(petDetail.BaseWeight) or 0
                    -- Count pets that haven't reached target weight yet
                    if weight < bulkToReach then
                        remainingPets = remainingPets + 1
                    end
                end
            end

            -- Only consider leveled pets for the bulking completion logic
            for _, pet in ipairs(leveledPets) do
                -- Fetch fresh pet details to get current weight (fix for stale weight data bug)
                local petDetail = self:GetPetDetail(pet.ID)
                if not petDetail then
                    -- Can't verify pet status - assume it still needs elephant processing
                    -- This prevents premature switch to leveling due to race condition
                    allFinished = false
                    needsElephant = true
                    continue
                end

                local weight = tonumber(petDetail.BaseWeight) or 0

                if weight < bulkToReach then
                    allFinished = false
                    needsElephant = true
                else
                    -- Pet has reached target weight - send webhook if not already notified
                    if not BulkingV2NotifiedPets[tostring(pet.ID)] then
                        BulkingV2NotifiedPets[tostring(pet.ID)] = true

                        -- remainingPets counts ALL candidatePets that still have weight < bulkToReach
                        -- This pet is excluded because its weight >= bulkToReach
                        -- Calculate weight at age 1 for webhook display
                        local weightAge1 = weight * 1.1

                        -- Send webhook notification with age 1 weight (no UI spam)
                        task.spawn(function()
                            Webhook:Bulking(petDetail.Type, weightAge1, remainingPets)
                        end)
                    end
                end
            end

            if allFinished then
                Window:ShowInfo("Auto Bulking V2", "All Bulking V2 target pets have reached the target base weight.")
                Window:SetConfigValue("BulkingStageV2", "leveling")
                return
            end

            if not needsElephant then
                -- Elephant phase complete - return to leveling stage (no UI spam)
                Window:SetConfigValue("BulkingStageV2", "leveling")
                -- Let leveling stage handle equipping on next cycle
                return
            end

            return
        else

            Window:SetConfigValue("BulkingStageV2", "leveling")
            return
        end
    end

    return m
end

-- Module: special/ui.lua
EmbeddedModules["special/ui.lua"] = function()
    local m = {}
    local Window
    local PetTeam
    local Egg
    local Pet
    local Garden
    local Player

    -- Keep references to toggles so we can sync UI state
    m.ManualNightmareToggle = nil
    m.IdleNightmareToggle = nil

    -- Store ALL toggle references for config sync after reconnect
    m.ToggleReferences = {}
    m.SelectBoxReferences = {}
    m.NumberBoxReferences = {}

    function m:Init(_window, _petTeam, _egg, _pet, _garden, _player)
        Window = _window
        PetTeam = _petTeam
        Egg = _egg
        Pet = _pet
        Garden = _garden
        Player = _player

        -- Buat tab khusus untuk fitur Special (Nightmare/Leveling/Bulking)
        self:CreateSpecialTab()
    end

    function m:CreateSpecialTab()
        local tab = Window:AddTab({
            Name = "Special",
            Icon = "✨",
        })

        -- Tab Special hanya berisi fitur-fitur otomatis khusus
        self:AutoNightmareMutationSection(tab)        -- Auto Nightmare
        self:AutoLevelingSection(tab)                 -- Auto Leveling
        self:IdleNightmareAndLevelingSection(tab)     -- Idle Nightmare + Leveling
        self:AutoBulkingSection(tab)                  -- Bulking Weights V.1
        self:AutoBulkingSection2(tab)                 -- Bulking Weights V.2
        self:AgeBreakerSection(tab)                   -- Age Breaker
    end





    function m:AutoNightmareMutationSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Multi Mutation",
            Icon = "🌑",
            Expanded = false,
        })

        local nightmareMutationPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Pet Team for Mutation",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "NightmareMutationPetTeam",
            OnInit = function(api, optionsData)
                print("[DEBUG] NightmareMutationPetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("NightmareMutationPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "NightmareMutationPetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "NightmareMutationPetTeam", savedValue))
                    end
                end
                task.spawn(function()
                    local success, err = pcall(function()
                        local listTeamPet = PetTeam:GetAllPetTeams()
                        local currentOptionsSet = {}

                        for _, team in pairs(listTeamPet) do
                            table.insert(currentOptionsSet, {text = team, value = team})
                        end
                        optionsData.updateOptions(currentOptionsSet)
                    end)
                    if not success then
                        warn("[SelectBox OnInit Error]", tostring(err))
                        optionsData.updateOptions({})
                    end
                end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if nightmareMutationPetTeamSelectBox then
            m.SelectBoxReferences["NightmareMutationPetTeam"] = nightmareMutationPetTeamSelectBox
            print("[DEBUG] Stored NightmareMutationPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("NightmareMutationPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    nightmareMutationPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    nightmareMutationPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local nightmareMutationPetsSelectBox = accordion:AddSelectBox({
            Name = "Select Target Pets for Mutation",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "NightmareMutationPets",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareMutationPets OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("NightmareMutationPets")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "NightmareMutationPets", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "NightmareMutationPets", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local pets = Pet:GetAllMyPets()
                    local currentOptionsSet = {}

                    for _, pet in pairs(pets) do
                        table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if nightmareMutationPetsSelectBox then
            m.SelectBoxReferences["NightmareMutationPets"] = nightmareMutationPetsSelectBox
            print("[DEBUG] Stored NightmareMutationPets SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("NightmareMutationPets")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    nightmareMutationPetsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    nightmareMutationPetsSelectBox:Set(savedValue)
                end
            end
        end

        local keepMutationListSelectBox = accordion:AddSelectBox({
            Name = "Select Mutations to Keep",
            Options = {
                {text = "Nightmare", value = "Nightmare"},
                {text = "Venom", value = "Venom"},
            },
            Placeholder = "Select Mutations...",
            MultiSelect = true,
            Flag = "KeepMutationList",
            OnInit = function(api, optionsData)
                print("[DEBUG] KeepMutationList OnInit called")
                local savedValue = Window:GetConfigValue("KeepMutationList")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end
            end
        })
        m.SelectBoxReferences["KeepMutationList"] = keepMutationListSelectBox

        local toggleAutoNightmare = accordion:AddToggle({
            Name = "Auto Nightmare Mutation",
            Default = false,
            Flag = "AutoNightmareMutation"
        })
        m.ToggleReferences["AutoNightmareMutation"] = toggleAutoNightmare
    end

    function m:AutoLevelingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Multi Leveling Pets Age",
            Icon = "⬆️",
            Expanded = false,
        })

        local levelingPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Leveling",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "LevelingPetTeam",
            OnInit = function(api, optionsData)
                    print("[DEBUG] LevelingPetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("LevelingPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "LevelingPetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "LevelingPetTeam", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if levelingPetTeamSelectBox then
            m.SelectBoxReferences["LevelingPetTeam"] = levelingPetTeamSelectBox
            print("[DEBUG] Stored LevelingPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("LevelingPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    levelingPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    levelingPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local levelingPetsSelectBox = accordion:AddSelectBox({
            Name = "Select Target Pets for Leveling",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "LevelingPets",
            OnInit = function(api, optionsData)
                    print("[DEBUG] LevelingPets OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("LevelingPets")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "LevelingPets", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "LevelingPets", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local pets = Pet:GetAllMyPets()
                    local currentOptionsSet = {}

                    for _, pet in pairs(pets) do
                        table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if levelingPetsSelectBox then
            m.SelectBoxReferences["LevelingPets"] = levelingPetsSelectBox
            print("[DEBUG] Stored LevelingPets SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("LevelingPets")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    levelingPetsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    levelingPetsSelectBox:Set(savedValue)
                end
            end
        end

        local levelToReachNumberBox = accordion:AddNumberBox({
            Name = "Level To Reach",
            Placeholder = "Enter level...",
            Default = 100,
            Min = 1,
            Max = 100,
            Increment = 1,
            Flag = "LevelToReach",
        })


        m.NumberBoxReferences["LevelToReach"] = levelToReachNumberBox

        local toggleAutoLeveling = accordion:AddToggle({
            Name = "Auto Leveling Pets",
            Default = false,
            Flag = "AutoLevelingPets"
        })
        m.ToggleReferences["AutoLevelingPets"] = toggleAutoLeveling
    end

    --[[ REMOVED: Manual Multi Mutation + Leveling (replaced by Idle version)
    function m:AutoNightmareAndLevelingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Multi Mutation + Leveling",
            Icon = "🌗",
            Expanded = false,
        })

        local nightmareAndLevelingNightmarePetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Mutation (Combo)",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "NightmareAndLevelingNightmarePetTeam",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareAndLevelingNightmarePetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("NightmareAndLevelingNightmarePetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "NightmareAndLevelingNightmarePetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "NightmareAndLevelingNightmarePetTeam", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if nightmareAndLevelingNightmarePetTeamSelectBox then
            m.SelectBoxReferences["NightmareAndLevelingNightmarePetTeam"] = nightmareAndLevelingNightmarePetTeamSelectBox
            print("[DEBUG] Stored NightmareAndLevelingNightmarePetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("NightmareAndLevelingNightmarePetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    nightmareAndLevelingNightmarePetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    nightmareAndLevelingNightmarePetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local nightmareAndLevelingLevelingPetTeam1SelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Leveling 1-40 (Combo)",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "NightmareAndLevelingLevelingPetTeam1",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareAndLevelingLevelingPetTeam1 OnInit called")
                local savedValue = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam1")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end
                task.spawn(function()
                    local success, err = pcall(function()
                        local listTeamPet = PetTeam:GetAllPetTeams()
                        local currentOptionsSet = {}
                        for _, team in pairs(listTeamPet) do
                            table.insert(currentOptionsSet, {text = team, value = team})
                        end
                        optionsData.updateOptions(currentOptionsSet)
                    end)
                    if not success then
                        warn("[SelectBox OnInit Error]", tostring(err))
                        optionsData.updateOptions({})
                    end
                end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}
                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        if nightmareAndLevelingLevelingPetTeam1SelectBox then
            m.SelectBoxReferences["NightmareAndLevelingLevelingPetTeam1"] = nightmareAndLevelingLevelingPetTeam1SelectBox
        end

        local nightmareAndLevelingLevelingPetTeam2SelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Leveling 40-100 (Combo)",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "NightmareAndLevelingLevelingPetTeam2",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareAndLevelingLevelingPetTeam2 OnInit called")
                local savedValue = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam2")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end
                task.spawn(function()
                    local success, err = pcall(function()
                        local listTeamPet = PetTeam:GetAllPetTeams()
                        local currentOptionsSet = {}
                        for _, team in pairs(listTeamPet) do
                            table.insert(currentOptionsSet, {text = team, value = team})
                        end
                        optionsData.updateOptions(currentOptionsSet)
                    end)
                    if not success then
                        warn("[SelectBox OnInit Error]", tostring(err))
                        optionsData.updateOptions({})
                    end
                end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}
                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        if nightmareAndLevelingLevelingPetTeam2SelectBox then
            m.SelectBoxReferences["NightmareAndLevelingLevelingPetTeam2"] = nightmareAndLevelingLevelingPetTeam2SelectBox
        end

        local nightmareAndLevelingTargetPetsSelectBox = accordion:AddSelectBox({
            Name = "Select Target Pets (Combo)",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "NightmareAndLevelingTargetPets",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareAndLevelingTargetPets OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("NightmareAndLevelingTargetPets")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "NightmareAndLevelingTargetPets", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "NightmareAndLevelingTargetPets", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local pets = Pet:GetAllMyPets()
                    local currentOptionsSet = {}

                    for _, pet in pairs(pets) do
                        table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if nightmareAndLevelingTargetPetsSelectBox then
            m.SelectBoxReferences["NightmareAndLevelingTargetPets"] = nightmareAndLevelingTargetPetsSelectBox
            print("[DEBUG] Stored NightmareAndLevelingTargetPets SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("NightmareAndLevelingTargetPets")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    nightmareAndLevelingTargetPetsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    nightmareAndLevelingTargetPetsSelectBox:Set(savedValue)
                end
            end
        end

        local nightmareAndLevelingKeepMutationListSelectBox = accordion:AddSelectBox({
            Name = "Select Mutations to Keep (Combo)",
            Options = {
                {text = "Nightmare", value = "Nightmare"},
                {text = "Venom", value = "Venom"},
            },
            Placeholder = "Select Mutations...",
            MultiSelect = true,
            Flag = "NightmareAndLevelingKeepMutationList",
            OnInit = function(api, optionsData)
                print("[DEBUG] NightmareAndLevelingKeepMutationList OnInit called")
                local savedValue = Window:GetConfigValue("NightmareAndLevelingKeepMutationList")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end
            end
        })
        m.SelectBoxReferences["NightmareAndLevelingKeepMutationList"] = nightmareAndLevelingKeepMutationListSelectBox

        local nightmareAndLevelingLevelToReachNumberBox = accordion:AddNumberBox({
            Name = "Level To Reach (Combo)",
            Placeholder = "Enter level...",
            Default = 100,
            Min = 1,
            Max = 100,
            Increment = 1,
            Flag = "NightmareAndLevelingLevelToReach",
        })


        m.NumberBoxReferences["NightmareAndLevelingLevelToReach"] = nightmareAndLevelingLevelToReachNumberBox

        local manualToggle = accordion:AddToggle({
            Name = "Enable Auto Mutation + Leveling",
            Default = false,
            Flag = "AutoNightmareAndLeveling",
            Callback = function(value)
                if value then
                    -- Validasi: pastikan target pets sudah dipilih
                    local targetPets = Window:GetConfigValue("NightmareAndLevelingTargetPets") or {}
                    if #targetPets == 0 then
                        Window:ShowWarning("Auto Mutation + Leveling", "Pilih target pets terlebih dahulu!")
                        Window:SetConfigValue("AutoNightmareAndLeveling", false)
                        return
                    end

                    -- Matikan idle mode dari sisi config DULU
                    Window:SetConfigValue("AutoIdleNightmareAndLeveling", false)

                    -- Matikan toggle Idle di UI kalau ada
                    if m.IdleNightmareToggle then
                        pcall(function()
                            if m.IdleNightmareToggle.Set then
                                m.IdleNightmareToggle:Set(false)
                            elseif m.IdleNightmareToggle.SetValue then
                                m.IdleNightmareToggle:SetValue(false)
                            elseif m.IdleNightmareToggle.SetState then
                                m.IdleNightmareToggle:SetState(false)
                            end
                        end)
                    end

                    -- Set pet lists SEBELUM enable toggle (sama seperti idle mode)
                    local nightmareList = {}
                    local levelingList = {}
                    for i, id in ipairs(targetPets) do
                        nightmareList[i] = id
                        levelingList[i] = id
                    end

                    Window:SetConfigValue("NightmareAndLevelingNightmarePets", nightmareList)
                    Window:SetConfigValue("NightmareAndLevelingLevelingPets", levelingList)

                    -- Set stage SEBELUM enable toggle
                    Window:SetConfigValue("NightmareAndLevelingStage", "nightmare")

                    -- TERAKHIR: Enable toggle setelah semua data siap
                    Window:SetConfigValue("AutoNightmareAndLeveling", true)

                    Window:ShowInfo(
                        "Auto Nightmare + Leveling",
                        "Combo mode enabled dengan " .. #targetPets .. " target pets.\\n\\nPhase: Nightmare -> Leveling 1-40 -> Leveling 40-100"
                    )
                else
                    Window:SetConfigValue("AutoNightmareAndLeveling", false)
                    Window:SetConfigValue("NightmareAndLevelingStage", "done")
                end
            end
        })
        -- Simpan referensi toggle manual
        m.ManualNightmareToggle = manualToggle
        m.ToggleReferences["AutoNightmareAndLeveling"] = manualToggle
    end
    --]]

    function m:IdleNightmareAndLevelingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Idle Mutation + Leveling",
            Icon = "🌗",
            Expanded = false,
        })

        local nightmareAndLevelingNightmarePetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Mutation (Combo)",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "NightmareAndLevelingNightmarePetTeam",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareAndLevelingNightmarePetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("NightmareAndLevelingNightmarePetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "NightmareAndLevelingNightmarePetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "NightmareAndLevelingNightmarePetTeam", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if nightmareAndLevelingNightmarePetTeamSelectBox then
            m.SelectBoxReferences["NightmareAndLevelingNightmarePetTeam"] = nightmareAndLevelingNightmarePetTeamSelectBox
            print("[DEBUG] Stored NightmareAndLevelingNightmarePetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("NightmareAndLevelingNightmarePetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    nightmareAndLevelingNightmarePetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    nightmareAndLevelingNightmarePetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local nightmareAndLevelingLevelingPetTeam1SelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Leveling 1-40 (Combo)",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "NightmareAndLevelingLevelingPetTeam1",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareAndLevelingLevelingPetTeam1 OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam1")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "NightmareAndLevelingLevelingPetTeam1", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "NightmareAndLevelingLevelingPetTeam1", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if nightmareAndLevelingLevelingPetTeam1SelectBox then
            m.SelectBoxReferences["NightmareAndLevelingLevelingPetTeam1"] = nightmareAndLevelingLevelingPetTeam1SelectBox
            print("[DEBUG] Stored NightmareAndLevelingLevelingPetTeam1 SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam1")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    nightmareAndLevelingLevelingPetTeam1SelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    nightmareAndLevelingLevelingPetTeam1SelectBox:Set(savedValue)
                end
            end
        end

        local nightmareAndLevelingLevelingPetTeam2SelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Leveling 40-100 (Combo)",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "NightmareAndLevelingLevelingPetTeam2",
            OnInit = function(api, optionsData)
                    print("[DEBUG] NightmareAndLevelingLevelingPetTeam2 OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam2")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "NightmareAndLevelingLevelingPetTeam2", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "NightmareAndLevelingLevelingPetTeam2", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if nightmareAndLevelingLevelingPetTeam2SelectBox then
            m.SelectBoxReferences["NightmareAndLevelingLevelingPetTeam2"] = nightmareAndLevelingLevelingPetTeam2SelectBox
            print("[DEBUG] Stored NightmareAndLevelingLevelingPetTeam2 SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("NightmareAndLevelingLevelingPetTeam2")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    nightmareAndLevelingLevelingPetTeam2SelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    nightmareAndLevelingLevelingPetTeam2SelectBox:Set(savedValue)
                end
            end
        end

        local idleNightmareLevelingPetTypesSelectBox = accordion:AddSelectBox({
            Name = "Idle Target Pet Types",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "IdleNightmareLevelingPetTypes",
            OnInit = function(api, optionsData)
                    print("[DEBUG] IdleNightmareLevelingPetTypes OnInit called")
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                optionsData.updateOptions(formattedPets)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                updateOptions(formattedPets)
            end
        })

        if idleNightmareLevelingPetTypesSelectBox then
            m.SelectBoxReferences["IdleNightmareLevelingPetTypes"] = idleNightmareLevelingPetTypesSelectBox
            print("[DEBUG] Stored IdleNightmareLevelingPetTypes SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("IdleNightmareLevelingPetTypes")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    idleNightmareLevelingPetTypesSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    idleNightmareLevelingPetTypesSelectBox:Set(savedValue)
                end
            end
        end

        local idleNightmareLevelingKeepMutationListSelectBox = accordion:AddSelectBox({
            Name = "Select Mutations to Keep (Idle)",
            Options = {
                {text = "Nightmare", value = "Nightmare"},
                {text = "Venom", value = "Venom"},
            },
            Placeholder = "Select Mutations...",
            MultiSelect = true,
            Flag = "IdleNightmareLevelingKeepMutationList",
            OnInit = function(api, optionsData)
                print("[DEBUG] IdleNightmareLevelingKeepMutationList OnInit called")
                local savedValue = Window:GetConfigValue("IdleNightmareLevelingKeepMutationList")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                    end
                end
            end
        })
        m.SelectBoxReferences["IdleNightmareLevelingKeepMutationList"] = idleNightmareLevelingKeepMutationListSelectBox

        local idleNightmareLevelingPrioritySelectBox = accordion:AddSelectBox({
            Name = "Idle Priority Order",
            Options = {
                {text = "Mutation First", value = "MutationFirst"},
                {text = "Leveling First", value = "LevelingFirst"},
            },
            Placeholder = "Select Priority...",
            MultiSelect = false,
            Flag = "IdleNightmareLevelingPriority",
            OnInit = function(api, optionsData)
                print("[DEBUG] IdleNightmareLevelingPriority OnInit called")
                local savedValue = Window:GetConfigValue("IdleNightmareLevelingPriority")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "string" then
                        api:Set(savedValue)
                    end
                else
                    -- Default to MutationFirst
                    api:Set("MutationFirst")
                end
            end
        })
        m.SelectBoxReferences["IdleNightmareLevelingPriority"] = idleNightmareLevelingPrioritySelectBox

        local idleToggle = accordion:AddToggle({
            Name = "Auto Idle Nightmare + Leveling",
            Default = false,
            Flag = "AutoIdleNightmareAndLeveling",
            Callback = function(value)
                Window:SetConfigValue("AutoIdleNightmareAndLeveling", value)

                if value then
                    -- Matikan manual dari sisi config
                    Window:SetConfigValue("AutoNightmareAndLeveling", false)
                    Window:SetConfigValue("NightmareAndLevelingStage", "idle")

                    -- Matikan toggle Manual di UI kalau ada
                    if m.ManualNightmareToggle then
                        pcall(function()
                            if m.ManualNightmareToggle.Set then
                                m.ManualNightmareToggle:Set(false)
                            elseif m.ManualNightmareToggle.SetValue then
                                m.ManualNightmareToggle:SetValue(false)
                            elseif m.ManualNightmareToggle.SetState then
                                m.ManualNightmareToggle:SetState(false)
                            end
                        end)
                    end

                    Window:ShowInfo(
                        "Auto Idle Nightmare + Leveling",
                        "Idle mode enabled. Manual Auto Nightmare + Leveling has been disabled automatically.\nThe script will automatically start Nightmare + Leveling when matching pets are found in your inventory."
                    )
                else
                    Window:SetConfigValue("AutoNightmareAndLeveling", false)
                    Window:SetConfigValue("NightmareAndLevelingStage", "done")

                    Window:ShowInfo(
                        "Auto Idle Nightmare + Leveling",
                        "Idle mode disabled. The script will no longer start new Nightmare + Leveling runs automatically."
                    )
                end
            end
        })
        -- Simpan referensi toggle idle
        m.IdleNightmareToggle = idleToggle
        m.ToggleReferences["AutoIdleNightmareAndLeveling"] = idleToggle
    end

    function m:AutoBulkingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Multi Elephent V.1",
            Icon = "🐘",
            Expanded = false,
        })

        local bulkingPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Bulking",
            Options = {"Loading..."},
            Placeholder = "Select Pet Team...",
            MultiSelect = false,
            Flag = "BulkingPetTeam",
            OnInit = function(api, optionsData)
                    print("[DEBUG] BulkingPetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("BulkingPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "BulkingPetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "BulkingPetTeam", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if bulkingPetTeamSelectBox then
            m.SelectBoxReferences["BulkingPetTeam"] = bulkingPetTeamSelectBox
            print("[DEBUG] Stored BulkingPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("BulkingPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    bulkingPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    bulkingPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        local bulkingPetsSelectBox = accordion:AddSelectBox({
            Name = "Select Target Pets for Bulking",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "BulkingPets",
            OnInit = function(api, optionsData)
                    print("[DEBUG] BulkingPets OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("BulkingPets")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "BulkingPets", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "BulkingPets", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local pets = Pet:GetAllMyPets()
                    local currentOptionsSet = {}

                    for _, pet in pairs(pets) do
                        table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if bulkingPetsSelectBox then
            m.SelectBoxReferences["BulkingPets"] = bulkingPetsSelectBox
            print("[DEBUG] Stored BulkingPets SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("BulkingPets")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    bulkingPetsSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    bulkingPetsSelectBox:Set(savedValue)
                end
            end
        end

        local bulkingToWeightNumberBox = accordion:AddNumberBox({
            Name = "Bulk To Weight",
            Placeholder = "Enter weight...",
            Default = 1.0,
            Min = 0.5,
            Max = 20.0,
            Increment = 0.1,
            Decimals = 2,
            Flag = "BulkingToWeight",
        })


        m.NumberBoxReferences["BulkingToWeight"] = bulkingToWeightNumberBox

        local toggleAutoBulking = accordion:AddToggle({
            Name = "Auto Bulk Pets",
            Default = false,
            Flag = "AutoBulkingPets"
        })
        m.ToggleReferences["AutoBulkingPets"] = toggleAutoBulking
    end

    function m:AutoBulkingSection2(tab)
        local accordion = tab:AddAccordion({
            Title = "Multi Elephent V.2",
            Icon = "🐘",
            Expanded = false,
        })

        -- Leveling team select (V2)
        local levelingBulkingPetTeamSelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Leveling (V2)",
            Options = {"Loading..."},
            Placeholder = "Select Leveling Pet Team...",
            MultiSelect = false,
            Flag = "LevelingBulkingPetTeam",
            OnInit = function(api, optionsData)
                    print("[DEBUG] LevelingBulkingPetTeam OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("LevelingBulkingPetTeam")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "LevelingBulkingPetTeam", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "LevelingBulkingPetTeam", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if levelingBulkingPetTeamSelectBox then
            m.SelectBoxReferences["LevelingBulkingPetTeam"] = levelingBulkingPetTeamSelectBox
            print("[DEBUG] Stored LevelingBulkingPetTeam SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("LevelingBulkingPetTeam")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    levelingBulkingPetTeamSelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    levelingBulkingPetTeamSelectBox:Set(savedValue)
                end
            end
        end

        -- Elephant team select (V2) – FLAG BARU
        local bulkingPetTeamV2SelectBox = accordion:AddSelectBox({
            Name = "Select Team Pets for Elephant (V2)",
            Options = {"Loading..."},
            Placeholder = "Select Elephant Pet Team...",
            MultiSelect = false,
            Flag = "BulkingPetTeamV2",
            OnInit = function(api, optionsData)
                    print("[DEBUG] BulkingPetTeamV2 OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("BulkingPetTeamV2")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "BulkingPetTeamV2", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "BulkingPetTeamV2", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local listTeamPet = PetTeam:GetAllPetTeams()
                    local currentOptionsSet = {}

                    for _, team in pairs(listTeamPet) do
                        table.insert(currentOptionsSet, {text = team, value = team})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listTeamPet = PetTeam:GetAllPetTeams()
                local currentOptionsSet = {}

                for _, team in pairs(listTeamPet) do
                    table.insert(currentOptionsSet, {text = team, value = team})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if bulkingPetTeamV2SelectBox then
            m.SelectBoxReferences["BulkingPetTeamV2"] = bulkingPetTeamV2SelectBox
            print("[DEBUG] Stored BulkingPetTeamV2 SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("BulkingPetTeamV2")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    bulkingPetTeamV2SelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    bulkingPetTeamV2SelectBox:Set(savedValue)
                end
            end
        end

        -- Target pets from inventory for bulking (V2)
        local bulkingPetsV2SelectBox = accordion:AddSelectBox({
            Name = "Select Target Pets for Bulking (V2)",
            Options = {"Loading..."},
            Placeholder = "Select Pets...",
            MultiSelect = true,
            Flag = "BulkingPetsV2",
            OnInit = function(api, optionsData)
                    print("[DEBUG] BulkingPetsV2 OnInit called")
                -- Load saved value from config immediately
                local savedValue = Window:GetConfigValue("BulkingPetsV2")
                if savedValue ~= nil and savedValue ~= "" then
                    if type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %d items", "BulkingPetsV2", #savedValue))
                    elseif type(savedValue) == "string" and savedValue ~= "" then
                        api:Set(savedValue)
                        print(string.format("[SelectBox] Restored %s: %s", "BulkingPetsV2", savedValue))
                    end
                end
                            task.spawn(function()
        local success, err = pcall(function()
                    local pets = Pet:GetAllMyPets()
                    local currentOptionsSet = {}

                    for _, pet in pairs(pets) do
                        table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                    end
                    optionsData.updateOptions(currentOptionsSet)
        end)
        if not success then
            warn("[SelectBox OnInit Error]", tostring(err))
            optionsData.updateOptions({})  -- Clear loading state
        end
    end)
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local pets = Pet:GetAllMyPets()
                local currentOptionsSet = {}

                for _, pet in pairs(pets) do
                    table.insert(currentOptionsSet, {text = Pet:SerializePet(pet), value = pet.ID})
                end
                updateOptions(currentOptionsSet)
            end
        })

        -- Store reference immediately after creation
        if bulkingPetsV2SelectBox then
            m.SelectBoxReferences["BulkingPetsV2"] = bulkingPetsV2SelectBox
            print("[DEBUG] Stored BulkingPetsV2 SelectBox API reference (direct assignment)")
            -- Restore saved value
            local savedValue = Window:GetConfigValue("BulkingPetsV2")
            if savedValue ~= nil and savedValue ~= "" then
                if type(savedValue) == "table" and #savedValue > 0 then
                    bulkingPetsV2SelectBox:Set(savedValue)
                elseif type(savedValue) == "string" and savedValue ~= "" then
                    bulkingPetsV2SelectBox:Set(savedValue)
                end
            end
        end

        -- Level to reach before switching to Elephant phase
        local levelToReachBeforeElephantNumberBox = accordion:AddNumberBox({
            Name = "Level To Reach Before Elephant",
            Placeholder = "Enter level...",
            Default = 50,
            Min = 1,
            Max = 100,
            Increment = 1,
            Flag = "LevelToReachBeforeElephantV2",
        })

        m.NumberBoxReferences["LevelToReachBeforeElephantV2"] = levelToReachBeforeElephantNumberBox

        -- Target base weight V2 – FLAG BARU
        local bulkingToWeightV2NumberBox = accordion:AddNumberBox({
            Name = "Bulk To Base Weight (V2)",
            Placeholder = "Enter target base weight...",
            Default = Window:GetConfigValue("BulkingToWeightV2") or 1.0,
            Min = 0.5,
            Max = 20.0,
            Increment = 0.1,
            Decimals = 2,
            Flag = "BulkingToWeightV2",
        })

        m.NumberBoxReferences["BulkingToWeightV2"] = bulkingToWeightV2NumberBox

        -- Max target pets in team (Leveling Phase V2)
        local maxTargetPetsLevelingNumberBox = accordion:AddNumberBox({
            Name = "Max Target Pets In Team (Leveling Phase)",
            Placeholder = "Enter max target pets...",
            Default = 8,
            Min = 1,
            Max = 8,
            Increment = 1,
            Flag = "MaxTargetPetsLevelingPhaseV2",
        })
        m.NumberBoxReferences["MaxTargetPetsLevelingPhaseV2"] = maxTargetPetsLevelingNumberBox

        -- Max target pets in team (Elephant Phase V2)
        local maxTargetPetsElephantNumberBox = accordion:AddNumberBox({
            Name = "Max Target Pets In Team (Elephant Phase)",
            Placeholder = "Enter max target pets...",
            Default = 3,
            Min = 1,
            Max = 8,
            Increment = 1,
            Flag = "MaxTargetPetsElephantPhaseV2",
        })
        m.NumberBoxReferences["MaxTargetPetsElephantPhaseV2"] = maxTargetPetsElephantNumberBox

        local toggleAutoBulkingV2 = accordion:AddToggle({
            Name = "Auto Bulk Pets (V2)",
            Default = false,
            Flag = "AutoBulkingPetsV2",
            Callback = function(value)
                -- Sync config explicitly (UI lib usually does this via Flag, but we keep it consistent)
                Window:SetConfigValue("AutoBulkingPetsV2", value)

                if value then
                    Window:ShowInfo(
                        "Bulking Weights V.2",
                        "Auto Bulking V.2 started.\n\nThe script will:\n- Use the selected Leveling team to raise target pets.\n- Switch to the Elephant team when pets reach the required age.\n- Bulk them up to the target base weight."
                    )
                else
                    Window:ShowInfo(
                        "Bulking Weights V.2",
                        "Auto Bulking V.2 stopped.\n\nThe script will no longer process Bulking V.2 until you enable this toggle again."
                    )
                end
            end
        })
        m.ToggleReferences["AutoBulkingPetsV2"] = toggleAutoBulkingV2
    end


    -- Function to refresh all selectbox UI states from config
    function m:RefreshSelectBoxStates()
        if not Window then
            warn("[SPECIAL] RefreshSelectBoxStates - Window not initialized")
            return 0
        end

        -- Count entries properly (# operator doesn't work for dictionary tables)
        local totalRefs = 0
        for _ in pairs(self.SelectBoxReferences) do
            totalRefs = totalRefs + 1
        end

        print(string.format("[SPECIAL] RefreshSelectBoxStates called, found %d selectbox references", totalRefs))

        if totalRefs > 0 then
            print("[SPECIAL] SelectBoxReferences keys:")
            for k, v in pairs(self.SelectBoxReferences) do
                print("  - " .. k .. " : " .. tostring(v ~= nil and "API exists" or "nil"))
            end
        else
            warn("[SPECIAL] WARNING: SelectBoxReferences is empty! This means OnInit was not called or selectboxes were not stored properly.")
        end

        local refreshedCount = 0

        for flagName, selectBoxAPI in pairs(self.SelectBoxReferences) do
            local success, err = pcall(function()
                if selectBoxAPI and type(selectBoxAPI) == "table" and selectBoxAPI.Set then
                    local configValue = Window:GetConfigValue(flagName)

                    if configValue ~= nil and configValue ~= "" then
                        -- Check if it's a table with items or a non-empty string
                        local hasValue = false
                        if type(configValue) == "table" and #configValue > 0 then
                            hasValue = true
                        elseif type(configValue) == "string" and configValue ~= "" then
                            hasValue = true
                        end

                        if hasValue then
                            -- Use Set() method to update UI without triggering callbacks
                            selectBoxAPI:Set(configValue)
                            local valueStr = type(configValue) == "table" and (#configValue .. " items") or tostring(configValue)
                            print(string.format("  ✓ [SPECIAL SelectBox] %s = %s", flagName, valueStr))
                            refreshedCount = refreshedCount + 1
                        end
                    else
                        print(string.format("  ⊘ [SPECIAL SelectBox] %s - No saved value in config", flagName))
                    end
                else
                    warn(string.format("  ✗ [SPECIAL SelectBox] %s - API missing or invalid (type: %s, has Set: %s)",
                        flagName,
                        type(selectBoxAPI),
                        selectBoxAPI and type(selectBoxAPI.Set) or "nil"))
                end
            end)

            if not success then
                warn(string.format("  ✗ [SPECIAL SelectBox] %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("[SPECIAL] Refreshed %d selectboxes successfully", refreshedCount))
        return refreshedCount
    end

    -- Function to refresh all toggle UI states from config
    function m:RefreshToggleStates()
        if not Window then
            warn("SpecialUI:RefreshToggleStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, toggleAPI in pairs(self.ToggleReferences) do
            local success, err = pcall(function()
                if toggleAPI and toggleAPI.SetValue then
                    -- Get value from config
                    local configValue = Window:GetConfigValue(flagName)

                    if configValue ~= nil then
                        -- Force update toggle UI
                        toggleAPI:SetValue(configValue, false)
                        print(string.format("  ✓ [Special] %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ [Special] %s - Toggle API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ [Special] %s - Error: %s", flagName, tostring(err)))
            end
        end

        return refreshedCount
    end

    -- Function to refresh all numberbox UI states from config
    function m:RefreshNumberBoxStates()
        if not Window then
            warn("UI:RefreshNumberBoxStates - Window not initialized")
            return 0
        end

        local refreshedCount = 0

        for flagName, numberBoxAPI in pairs(self.NumberBoxReferences) do
            local success, err = pcall(function()
                if numberBoxAPI and numberBoxAPI.SetValue then
                    local configValue = Window:GetConfigValue(flagName)
                    if configValue ~= nil then
                        numberBoxAPI:SetValue(configValue)
                        print(string.format("  ✓ %s = %s", flagName, tostring(configValue)))
                        refreshedCount = refreshedCount + 1
                    end
                else
                    warn(string.format("  ✗ %s - NumberBox API missing SetValue method", flagName))
                end
            end)

            if not success then
                warn(string.format("  ✗ %s - Error: %s", flagName, tostring(err)))
            end
        end

        print(string.format("Refreshed %d numberboxes successfully", refreshedCount))
        return refreshedCount
    end

    function m:AgeBreakerSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Age Breaker",
            Icon = "⏳",
            Expanded = false,
        })

        -- Test: Add static label first to verify labels work
        accordion:AddLabel("📊 Age Breaker Information")

        -- Dynamic status label with error handling
        accordion:AddLabel(function()
            local success, result = pcall(function()
                if not Pet then
                    return "⚠️ Pet module not initialized"
                end
                local status = Pet:GetMachineAgeBreakerStatus()
                if not status then
                    return "⚠️ Unable to get status"
                end
                return "Status: " .. tostring(status.Status or "Unknown")
            end)
            return success and result or ("Error: " .. tostring(result))
        end)

        -- Dynamic time label with error handling
        accordion:AddLabel(function()
            local success, result = pcall(function()
                if not Pet then
                    return "⚠️ Pet module not initialized"
                end
                local status = Pet:GetMachineAgeBreakerStatus()
                if not status or not status.LastSubmitted or status.LastSubmitted == 0 then
                    return "Last Submit: Never"
                end
                local timeAgo = os.time() - status.LastSubmitted
                local mins = math.floor(timeAgo / 60)
                local secs = timeAgo % 60
                return string.format("Last Submit: %dm %ds ago", mins, secs)
            end)
            return success and result or ("Error: " .. tostring(result))
        end)

        accordion:AddSeparator()

        local ageBreakerPetTypesSelectBox = accordion:AddSelectBox({
            Name = "Select Target Pet Type for Age Breaker",
            Options = {"Loading..."},
            Placeholder = "Select Pet Type...",
            MultiSelect = true,
            Flag = "AgeBreakerTargetPetTypes",
            OnInit = function(api, optionsData)
                coroutine.wrap(function()
                    task.wait(0.3)
                    local listPets = Pet:GetPetRegistry()
                    local formattedPets = {}

                    for _, petInfo in pairs(listPets) do
                        table.insert(formattedPets, {
                            text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                            value = petInfo.Name or "Unknown",
                        })
                    end

                    optionsData.updateOptions(formattedPets)

                    -- Restore saved value
                    task.wait(0.1)
                    local savedValue = Window:GetConfigValue("AgeBreakerTargetPetTypes")
                    if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                        api:Set(savedValue)
                    end
                end)()
            end,
            OnDropdownOpen = function(currentOptions, updateOptions)
                local listPets = Pet:GetPetRegistry()
                local formattedPets = {}

                for _, petInfo in pairs(listPets) do
                    table.insert(formattedPets, {
                        text = string.format("[%s] %s (%s)", petInfo.Egg or "Unknown", petInfo.Name or "Unknown", petInfo.Rarity or "Unknown"),
                        value = petInfo.Name or "Unknown",
                    })
                end

                updateOptions(formattedPets)
            end
        })

        -- Store reference and restore saved value
        if ageBreakerPetTypesSelectBox then
            m.SelectBoxReferences["AgeBreakerTargetPetTypes"] = ageBreakerPetTypesSelectBox
            coroutine.wrap(function()
                task.wait(0.6)
                local savedValue = Window:GetConfigValue("AgeBreakerTargetPetTypes")
                if savedValue and type(savedValue) == "table" and #savedValue > 0 then
                    ageBreakerPetTypesSelectBox:Set(savedValue)
                end
            end)()
        end

        local targetAgeNumberBox = accordion:AddNumberBox({
            Name = "Target Age to Break",
            Placeholder = "Enter target age...",
            Default = 125,
            Min = 101,
            Max = 125,
            Increment = 1,
            Flag = "AgeBreakerTargetAge",
        })
        m.NumberBoxReferences["AgeBreakerTargetAge"] = targetAgeNumberBox

        local sacrificeAgeNumberBox = accordion:AddNumberBox({
            Name = "Sacrifice Age Threshold (Only Sacrifice Pets Above This Age)",
            Placeholder = "Enter sacrifice age threshold...",
            Default = 10,
            Min = 2,
            Max = 100,
            Increment = 1,
            Flag = "AgeBreakerSacrificeAgeThreshold",
        })
        m.NumberBoxReferences["AgeBreakerSacrificeAgeThreshold"] = sacrificeAgeNumberBox

        local sacrificeWeightNumberBox = accordion:AddNumberBox({
            Name = "Sacrifice Base Weight (Age 1) Threshold (Only Sacrifice Pets Above This Weight)",
            Placeholder = "Enter sacrifice weight threshold...",
            Default = 3.0,
            Min = 0.5,
            Max = 20.0,
            Increment = 0.5,
            Decimals = 2,
            Flag = "AgeBreakerSacrificeWeightThreshold",
        })
        m.NumberBoxReferences["AgeBreakerSacrificeWeightThreshold"] = sacrificeWeightNumberBox

        accordion:AddSeparator()

        local toggleForceUseFavorite = accordion:AddToggle({
            Name = "Force Use Favorite Pet Target and Sacrifice",
            Default = false,
            Flag = "AgeBreakerForceUseFavoriteTargetAndSacrifice"
        })
        m.ToggleReferences["AgeBreakerForceUseFavoriteTargetAndSacrifice"] = toggleForceUseFavorite

        local toggleAutoAgeBreaker = accordion:AddToggle({
            Name = "Auto Age Breaker",
            Default = false,
            Flag = "AutoUseMachineAgeBreaker"
        })
        m.ToggleReferences["AutoUseMachineAgeBreaker"] = toggleAutoAgeBreaker

        accordion:AddSeparator()

        local toggleSkipToken = accordion:AddToggle({
            Name = "Skip Use Token",
            Default = false,
            Flag = "AgeBreakerSkipUseToken"
        })
        m.ToggleReferences["AgeBreakerSkipUseToken"] = toggleSkipToken
    end

    return m
end

-- Module: shop/traveling.lua
EmbeddedModules["shop/traveling.lua"] = function()
    local m = {}

    local Window
    local Core
    local PetModule

    local DataService
    local FallMerchantShopData
    local GnomeMerchantShopData
    local HoneyMerchantShopData
    local SkyMerchantShopData
    local SprayMerchantShopData
    local SprinklerMerchantShopData
    local SummerMerchantShopData

    function m:Init(_window, _core, _petModule)
        Window = _window
        Core = _core
        PetModule = _petModule

        DataService = require(Core.ReplicatedStorage.Modules.DataService)
        FallMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.FallMerchantShopData)
        GnomeMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.GnomeMerchantShopData)
        HoneyMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.HoneyMerchantShopData)
        SkyMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SkyMerchantShopData)
        SprayMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SprayMerchantShopData)
        SprinklerMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SprinklerMerchantShopData)
        SummerMerchantShopData = require(Core.ReplicatedStorage.Data.TravelingMerchant.TravelingMerchantData.SummerMerchantShopData)

        _core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuyTravelingMerchant")
        end, function()
            self:StartBuyTravelingItems()
        end)
    end

    function m:GetItemRepository(shopName)
        if shopName == "FallMerchant" then
            return FallMerchantShopData or {}
        elseif shopName == "GnomeMerchant" then
            return GnomeMerchantShopData or {}
        elseif shopName == "HoneyMerchant" then
            return HoneyMerchantShopData or {}
        elseif shopName == "SkyMerchant" then
            return SkyMerchantShopData or {}
        elseif shopName == "SprayMerchant" then
            return SprayMerchantShopData or {}
        elseif shopName == "SprinklerMerchant" then
            return SprinklerMerchantShopData or {}
        elseif shopName == "SummerMerchant" then
            return SummerMerchantShopData or {}
        end

        return {}
    end

    function m:GetAllItemsRepository()
        local allItems = {}

        local shops = {
            "FallMerchant",
            "GnomeMerchant",
            "HoneyMerchant",
            "SkyMerchant",
            "SprayMerchant",
            "SprinklerMerchant",
            "SummerMerchant"
        }

        for _, shopName in pairs(shops) do
            local items = self:GetItemRepository(shopName)
            for itemName, _ in pairs(items) do
                allItems[itemName] = shopName
            end
        end

        return allItems
    end

    function m:GetDetailItem(itemName)
        local allItems = self:GetAllItemsRepository()
        local shopName = allItems[itemName]
        if not shopName then
            return nil
        end

        local items = self:GetItemRepository(shopName)
        return items[itemName] or nil
    end

    function m:GetStock(itemName)
        local shopData = DataService:GetData()
        local stock = 0
        if not shopData then
            return stock
        end

        stock = shopData.TravelingMerchantShopStock.Stocks[itemName] or 0

        if type(stock) ~= "number" then
            return stock.Stock or 0
        end

        return stock
    end

    function m:GetAvailableItems()
        local availableItems = {}
        local items = self:GetAllItemsRepository()

        for itemName, _ in pairs(items) do
            local stock = self:GetStock(itemName)
            availableItems[itemName] = stock
        end

        return availableItems
    end

    function m:GetAllIgnoreItems()
        local ignoreFallItems = Window:GetConfigValue("IgnoreFallMerchantItems") or {}
        local ignoreGnomeItems = Window:GetConfigValue("IgnoreGnomeMerchantItems") or {}
        local ignoreHoneyItems = Window:GetConfigValue("IgnoreHoneyMerchantItems") or {}
        local ignoreSkyItems = Window:GetConfigValue("IgnoreSkyMerchantItems") or {}
        local ignoreSprayItems = Window:GetConfigValue("IgnoreSprayMerchantItems") or {}
        local ignoreSprinklerItems = Window:GetConfigValue("IgnoreSprinklerMerchantItems") or {}
        local ignoreSummerItems = Window:GetConfigValue("IgnoreSummerMerchantItems") or {}

        local allIgnoreItems = {}
        for _, itemName in pairs(ignoreFallItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreGnomeItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreHoneyItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreSkyItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreSprayItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreSprinklerItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreSummerItems) do
            table.insert(allIgnoreItems, itemName)
        end

        return allIgnoreItems
    end

    function m:StartBuyTravelingItems()
        if not Window:GetConfigValue("AutoBuyTravelingMerchant") then
            return
        end

        local corePetTeam = Window:GetConfigValue("CorePetTeam") or ""
        local shopPetTeam = Window:GetConfigValue("ShopPetTeam") or ""
        local ignoreItems = self:GetAllIgnoreItems()
        local petItems = {}

        for itemName, stock in pairs(self:GetAvailableItems()) do
            if stock <= 0 or table.find(ignoreItems, itemName) then
                continue
            end

            local itemDetail = self:GetDetailItem(itemName)
            if itemDetail and itemDetail.ItemType == "Pet" and shopPetTeam ~= "" and corePetTeam ~= "" then
                petItems[itemName] = stock
                continue
            end

            for i=1, stock do
                Core.ReplicatedStorage.GameEvents.BuyTravelingMerchantShopStock:FireServer(itemName, 5)
                task.wait(0.15)
            end
        end

        if #petItems == 0 then
            return
        end

        while PetModule:GetCurrentPetTeam() ~= "core" do
            task.wait(1)
        end

        PetModule:ChangeTeamPets(shopPetTeam, "shop")

        for itemName, stock in pairs(petItems) do
            for i=1, stock do
                Core.ReplicatedStorage.GameEvents.BuyTravelingMerchantShopStock:FireServer(itemName, 5)
                task.wait(0.15)
            end
        end

        PetModule:ChangeTeamPets(corePetTeam, "core")
    end


    return m
end

-- Module: shop/cosmetic.lua
EmbeddedModules["shop/cosmetic.lua"] = function()
    local m = {}

    local Window
    local Core

    local DataService

    local CrateShopData
    local CosmeticShopData
    local CosmeticShopTabData

    function m:Init(_window, _core)
        Window = _window
        Core = _core

        DataService = require(Core.ReplicatedStorage.Modules.DataService)

        CrateShopData = require(Core.ReplicatedStorage.Data.CosmeticCrateShopData)
        CosmeticShopData = require(Core.ReplicatedStorage.Data.CosmeticItemShopData)
        CosmeticShopTabData = require(Core.ReplicatedStorage.Data.CosmeticShopTabData)

        Core:MakeLoop(function()
            return Window:GetConfigValue("AutoBuyCosmeticItems")
        end, function()
            self:StartAutoBuyCosmeticItems()
        end)
    end

    function m:GetCrateItemRepository()
        return CrateShopData or {}
    end

    function m:GetCosmeticItemRepository()
        return CosmeticShopData or {}
    end

    function m:GetFenceItemRepository()
        local items = CosmeticShopTabData.Tabs["Fences"].Items or {}
        local fences = CosmeticShopTabData.Tabs["Fences"].Fences or {}
        local data = {}

        for k, v in pairs(items) do
            if k ~= "_name" then
                table.insert(data, k)
            end
        end

        for k, v in pairs(fences) do
            if k ~= "_name" then
                table.insert(data, k)
            end
        end

        table.sort(data)

        return data or {}
    end

    function m:GetAvailableItems()
        local data = DataService:GetData()
        local tabs = {"Cosmetics", "Fences"}
        local availableItems = {}

        for _, tabName in pairs(tabs) do
            local tabConfig = CosmeticShopTabData.Tabs[tabName]
            local stocks = data.CosmeticStock.TabStocks[tabName]
            if not tabConfig or not stocks then
                continue
            end

            -- Crates
            for crateId, stock in pairs(stocks.CrateStocks) do
                local crateData = tabConfig.Crates[crateId]
                if crateData and crateData.CosmeticName then
                    availableItems[crateData.CosmeticName] = { Tab = tabName, Category= "Crates", Stock = stock.Stock }
                elseif crateData and crateData.CrateName then
                    availableItems[crateData.CrateName] = { Tab = tabName, Category= "Crates", Stock = stock.Stock }
                else
                    warn("Invalid crateData or missing CosmeticName for crateId:", crateId)
                    for k, v in pairs(crateData or {}) do
                        warn(" -", k, v)
                    end
                    warn("----")

                end
            end

            -- Items
            for itemId, stock in pairs(stocks.ItemStocks) do
                local itemData = tabConfig.Items[itemId]
                if itemData then
                    availableItems[itemData.CosmeticName] = { Tab = tabName, Category= "Items", Stock = stock.Stock }
                end
            end

            -- Fences
            for fenceId, stock in pairs(stocks.FenceStocks) do
                local fenceData = tabConfig.Fences[fenceId]
                if fenceData then
                    availableItems[fenceData.FenceName] = { Tab = tabName, Category= "Fences", Stock = stock.Stock }
                end
            end
        end

        return availableItems or {}
    end

    function m:GetAllIgnoreItems()
        local ignoreCosmeticItems = Window:GetConfigValue("IgnoreCosmeticItems") or {}
        local ignoreCrateItems = Window:GetConfigValue("IgnoreCrateItems") or {}
        local ignoreFenceItems = Window:GetConfigValue("IgnoreFenceItems") or {}

        local allIgnoreItems = {}
        for _, itemName in pairs(ignoreCrateItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreCosmeticItems) do
            table.insert(allIgnoreItems, itemName)
        end
        for _, itemName in pairs(ignoreFenceItems) do
            table.insert(allIgnoreItems, itemName)
        end

        return allIgnoreItems
    end

    function m:StartAutoBuyCosmeticItems()
        if not Window:GetConfigValue("AutoBuyCosmeticItems") then
            return
        end
        local ignoreItems = self:GetAllIgnoreItems()

        for itemName, details in pairs(self:GetAvailableItems()) do
            if stock <= 0 or table.find(ignoreItems, itemName) then
                continue
            end

            for i = 1, details.Stock do
                if details.Category == "Fences" then
                    Core.ReplicatedStorage.GameEvents.BuyCosmeticShopFence:FireServer(itemName, details.Tab)
                elseif details.Category == "Crates" then
                    Core.ReplicatedStorage.GameEvents.BuyCosmeticCrate:FireServer(itemName, details.Tab)
                else
                    Core.ReplicatedStorage.GameEvents.BuyCosmeticItem:FireServer(itemName, details.Tab)
                end
                task.wait(0.15)
            end
        end
    end

    return m
end

-- Module: ../module/webhook.lua
EmbeddedModules["../module/webhook.lua"] = function()
    local m = {}

    local Window
    local Core
    local Discord

    local PlayerName
    local WebhookURL
    local PingID

    function m:Init(_window, _core, _discord)
        Window = _window
        Core = _core
        Discord = _discord

        PlayerName = Core.LocalPlayer.Name or "Unknown"

        -- Debug: Check if Discord module is properly initialized
        if not Discord then
            warn("CoreWebhookModule:Init - Discord module is nil!")
        elseif type(Discord) ~= "table" then
            warn("CoreWebhookModule:Init - Discord module is not a table, type:", type(Discord))
        elseif not Discord.SendMessage then
            warn("CoreWebhookModule:Init - Discord module missing SendMessage function")
        else
            print("CoreWebhookModule:Init - Discord module initialized successfully")
        end

        -- Cache webhook settings
        if Window then
            WebhookURL = Window:GetConfigValue("DiscordWebhookURL") or ""
            PingID = Window:GetConfigValue("DiscordPingID") or ""
            print("CoreWebhookModule:Init - Cached webhook URL:", WebhookURL ~= "" and "SET" or "EMPTY")
        end
    end

    function m:DisconnectWebhook()
        print("DisconnectWebhook called - Discord module:", Discord and "initialized" or "nil")

        if not Discord then
            warn("DisconnectWebhook - Discord module not initialized")
            return
        end

        if not Discord.SendMessage or type(Discord.SendMessage) ~= "function" then
            warn("DisconnectWebhook - Discord.SendMessage is not a valid function")
            return
        end

        -- Use cached values or try to get from Window
        local url = WebhookURL
        local pingId = PingID

        if Window then
            local success, configUrl = pcall(function()
                return Window:GetConfigValue("DiscordWebhookURL")
            end)
            if success and configUrl then
                url = configUrl
            end

            local success2, configPingId = pcall(function()
                return Window:GetConfigValue("DiscordPingID")
            end)
            if success2 and configPingId then
                pingId = configPingId
            end
        end

        if not url or url == "" then
            print("DisconnectWebhook - No webhook URL configured, skipping")
            return
        end

        print("DisconnectWebhook - Sending webhook notification...")
        local success, err = pcall(function()
            local message = {
                content = (pingId and pingId ~= "") and ("<@"..pingId..">") or nil,
                embeds = {{
                    title = "**jordi_galerHub**",
                    type = 'rich',
                    color = tonumber("0xFF0000"),
                    fields = {{
                        name = '**Profile : ** \n',
                        value = '> Username : ||'..(PlayerName or "Unknown").."||",
                        inline = false
                    }, {
                        name = '**Disconnect**',
                        value = '> The user has disconnected.',
                        inline = false
                    }}
                }}
            }

            Discord:SendMessage(url, message)
        end)

        if not success then
            warn("DisconnectWebhook - Failed to send webhook:", err)
        else
            print("DisconnectWebhook - Webhook sent successfully")
        end
    end

    return m
end

-- Module: misc/teleport.lua
EmbeddedModules["misc/teleport.lua"] = function()
    local m = {}

    local Window
    local Core
    local Garden
    local Player

    function m:Init(_window, _core, _garden, _player)
        Core = _core
        Window = _window
        Garden = _garden
        Player = _player

        Core:MakeLoop(
            function()
                return Window:GetConfigValue("LockOnCenterOfGarden")
            end, 
            function()
                self:LockOnCenterOfGarden()
            end
        )

        -- Auto join Farmers Market on start
        task.spawn(function()
            self:StartAutoJoinFarmersMarket()
        end)
    end

    function m:LockOnCenterOfGarden()
        if not Window:GetConfigValue("LockOnCenterOfGarden") then
            return
        end

        local gardenCenter = Garden:GetFarmCenterPosition()
        if not gardenCenter then
            warn("Teleport:LockOnCenterOfGarden - Unable to get garden center position.")
            return
        end

        local currentPosition = Player:GetPosition().Position
        local normalizedPosition = Vector3.new(currentPosition.X, gardenCenter.Y, currentPosition.Z)
        if (normalizedPosition - gardenCenter).Magnitude ~= 0 then
            Window:ShowInfo("Teleport", "Teleporting to center of garden.")
            Player:TeleportToPosition(Vector3.new(gardenCenter.X, gardenCenter.Y, gardenCenter.Z))
        end
    end

    -- ========== FARMERS MARKET ==========

    function m:GetFarmersMarketPortal()
        -- Find PortalFX in workspace (based on game structure)
        local portalFX = Core.Workspace:FindFirstChild("PortalFX", true)
        if portalFX then
            local portal = portalFX:FindFirstChild("Portal")
            if portal then
                return portal
            end
        end

        -- Alternative: search for PortalPete (parent of PortalFX)
        local portalPete = Core.Workspace:FindFirstChild("PortalPete", true)
        if portalPete then
            local portalFXChild = portalPete:FindFirstChild("PortalFX")
            if portalFXChild then
                local portal = portalFXChild:FindFirstChild("Portal")
                if portal then
                    return portal
                end
            end
        end

        return nil
    end

    function m:TeleportToFarmersMarket()
        local portal = self:GetFarmersMarketPortal()
        if not portal then
            warn("Teleport:TeleportToFarmersMarket - Portal not found")
            return false
        end

        -- Get portal position
        local targetPos
        if portal:IsA("BasePart") then
            targetPos = portal.Position
        elseif portal:IsA("Model") then
            local primaryPart = portal.PrimaryPart or portal:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                targetPos = primaryPart.Position
            else
                warn("Teleport:TeleportToFarmersMarket - Cannot get portal position")
                return false
            end
        else
            warn("Teleport:TeleportToFarmersMarket - Invalid portal type")
            return false
        end

        -- Teleport player to portal
        if Player and Player.TeleportToPosition then
            return Player:TeleportToPosition(targetPos)
        end

        return false
    end

    function m:JoinFarmersMarket()
        -- Search for the correct ProximityPrompt (Travel to Farmers Market)
        local proximityPrompt = nil

        -- Helper function to check if prompt is for travel
        local function isTravelPrompt(prompt)
            if not prompt or not prompt:IsA("ProximityPrompt") then
                return false
            end

            local actionText = prompt.ActionText or ""
            local objectText = prompt.ObjectText or ""
            local combined = (actionText .. " " .. objectText):lower()

            -- Check if it's a travel/market prompt
            return combined:find("travel") or 
                   combined:find("farmers") or 
                   combined:find("market") or
                   combined:find("teleport") or
                   combined:find("go to")
        end

        -- 1. Search in PortalFX first (most likely location)
        local portalFX = Core.Workspace:FindFirstChild("PortalFX", true)
        if portalFX then
            for _, child in ipairs(portalFX:GetDescendants()) do
                if child:IsA("ProximityPrompt") and isTravelPrompt(child) then
                    proximityPrompt = child
                    break
                end
            end

            -- If no travel prompt found, get any prompt in PortalFX (not in PortalPete)
            if not proximityPrompt then
                for _, child in ipairs(portalFX:GetDescendants()) do
                    if child:IsA("ProximityPrompt") then
                        proximityPrompt = child
                        break
                    end
                end
            end
        end

        -- 2. Search in Portal object
        if not proximityPrompt then
            local portal = self:GetFarmersMarketPortal()
            if portal then
                for _, child in ipairs(portal:GetDescendants()) do
                    if child:IsA("ProximityPrompt") then
                        proximityPrompt = child
                        break
                    end
                end
            end
        end

        -- 3. Last resort: search entire workspace for travel prompt (avoid NPC prompts)
        if not proximityPrompt then
            for _, obj in ipairs(Core.Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and isTravelPrompt(obj) then
                    proximityPrompt = obj
                    break
                end
            end
        end

        if proximityPrompt then
            print("Teleport:JoinFarmersMarket - Found prompt:", proximityPrompt:GetFullName())

            -- Try fireproximityprompt first (most reliable)
            local success = pcall(function()
                fireproximityprompt(proximityPrompt)
            end)

            if success then
                print("Teleport:JoinFarmersMarket - ProximityPrompt fired successfully")
                return true
            end

            -- Fallback: Use keypress simulation
            local success2 = pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)

            if success2 then
                print("Teleport:JoinFarmersMarket - Keypress simulated")
                return true
            end

            -- Alternative fallback: Direct prompt trigger
            pcall(function()
                proximityPrompt:InputHoldBegin()
                task.wait(proximityPrompt.HoldDuration or 0.5)
                proximityPrompt:InputHoldEnd()
            end)

            return true
        end

        warn("Teleport:JoinFarmersMarket - No travel ProximityPrompt found")
        return false
    end

    function m:StartAutoJoinFarmersMarket()
        if not Window:GetConfigValue("AutoJoinFarmersMarket") then
            return
        end

        -- Wait a bit for game to load
        task.wait(3)

        -- Teleport to portal first
        self:TeleportToFarmersMarket()
        task.wait(0.5)

        -- Then join the market
        self:JoinFarmersMarket()
    end

    return m
end

-- Module: auto/cooking.lua
EmbeddedModules["auto/cooking.lua"] = function()
    local m = {}

    local Window
    local Core
    local Player
    local Plant

    local CookingPotUtils

    function m:Init(_window, _core, _player, _plant)
        Window = _window
        Core = _core
        Player = _player
        Plant = _plant

        CookingPotUtils = require(Core.ReplicatedStorage.Modules.CookingPotClientUtils)

        Core:MakeLoop(
            function()
                return Window:GetConfigValue("AutoCooking")
            end, 
            function()
                self:StartAutoCooking()
            end
        )
    end

    function m:CombineIngredientsConfig()
        local Ingredient1 = Window:GetConfigValue("CookingIngredient1") or ""
        local Ingredient2 = Window:GetConfigValue("CookingIngredient2") or ""
        local Ingredient3 = Window:GetConfigValue("CookingIngredient3") or ""
        local Ingredient4 = Window:GetConfigValue("CookingIngredient4") or ""
        local Ingredient5 = Window:GetConfigValue("CookingIngredient5") or ""

        local ingredients = {}
        if Ingredient1 ~= "" then table.insert(ingredients, Ingredient1) end
        if Ingredient2 ~= "" then table.insert(ingredients, Ingredient2) end
        if Ingredient3 ~= "" then table.insert(ingredients, Ingredient3) end
        if Ingredient4 ~= "" then table.insert(ingredients, Ingredient4) end
        if Ingredient5 ~= "" then table.insert(ingredients, Ingredient5) end

        return ingredients
    end

    function m:CompareIngredients(submittedIngredients)
        local configIngredients = self:CombineIngredientsConfig()
        local unsubmittedItems = {}
        local hasWrongItems = false

        -- Find unsubmitted ingredients
        for _, ingredient in ipairs(configIngredients) do
            if not table.find(submittedIngredients, ingredient) then
                table.insert(unsubmittedItems, ingredient)
            end
        end

        -- Check for wrong submitted ingredients
        for _, ingredient in ipairs(submittedIngredients) do
            if not table.find(configIngredients, ingredient) then
                hasWrongItems = true
                break
            end
        end

        return unsubmittedItems, hasWrongItems
    end

    function m:FindIngredientInInventory(ingredientName)
        local foundItem = nil

        for _, item in pairs(Core:GetBackpack():GetChildren()) do
            if not item:IsA("Tool") then
                continue
            end

            if item:GetAttribute("b") ~= "j" then
                continue
            end

            if item:GetAttribute("f") == ingredientName then
                foundItem = item
                break
            end
        end
        return foundItem
    end

    function m:FindIngredientInFarm(ingredientName)
        local foundItem = nil
        local plants = Plant:FindPlants(ingredientName) or {}
        local plantToHarvest = {}

        if not plants or #plants == 0 then
            return foundItem
        end

        for _, plant in pairs(plants) do
            local plantDetail = Plant:GetPlantDetail(plant)
            if not plantDetail or #plantDetail.fruits == 0 then
                continue
            end

            for _, fruit in pairs(plantDetail.fruits) do
                if fruit.isEligibleToHarvest then
                    table.insert(plantToHarvest, plant)
                    break
                end
            end
        end

        for _, plant in pairs(plantToHarvest) do
            local successHarvest = Plant:HarvestFruit(plant) or false

            if successHarvest then
                break
            end
        end

        -- After harvesting, check inventory for the ingredient
        foundItem = self:FindIngredientInInventory(ingredientName)
        return foundItem
    end

    function m:StartCooking(cookingPotUUID, ingredients)
        local taskCompleted = false

        local cookingTask = function(_cookingPotUUID, _ingredients)
            for _, ingredientTool in pairs(_ingredients) do
                local currentlyEquipped = Player:GetEquippedTool()

                warn("Currently Equipped Tool: " .. tostring(currentlyEquipped.Name))

                if currentlyEquipped == nil or currentlyEquipped ~= ingredientTool then
                    Player:EquipTool(ingredientTool)
                    task.wait(0.5)
                end

                -- Submit Ingredient
                Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("SubmitHeldPlant", _cookingPotUUID)
                task.wait(0.5)
            end

            -- Start Cooking
            Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("CookBest", _cookingPotUUID)
        end

        local cookingCallback = function()
            isTaskCompleted = true
        end

        Player:AddToQueue(
            ingredients[1],
            20,
            function()
                cookingTask(cookingPotUUID, ingredients)
            end,
            function()
                cookingCallback()
            end
        )

        while not taskCompleted do
            task.wait(1)
        end
    end

    function m:StartAutoCooking()
        if not Window:GetConfigValue("AutoCooking") then
            return
        end

        local cookingKit = CookingPotUtils:GetAllCookingPotUUIDs(Core.LocalPlayer)
        if #cookingKit == 0 then
            return
        end

        local cookingPotUUIDs = {}
        for _, v in ipairs(cookingKit) do
            local uuid = v.Parent:GetAttribute("CosmeticUUID")
            table.insert(cookingPotUUIDs, uuid)
        end

        local cookingPotData = CookingPotUtils:GetCookingPotData(Core.LocalPlayer, cookingPotUUIDs[1])
        if not cookingPotData then
            return
        end

        if cookingPotData.IsCooking then
            local totalTime = cookingPotData.CookTimeTotal or 0

            warn("AutoCooking: Cooking in progress. Waiting for " .. tostring(totalTime + 1) .. " seconds.")

            task.wait(totalTime + 1)
        end

        if cookingPotData.FinishedFoodRawData and not cookingPotData.CookingEndTime then
            Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("GetFoodFromPot", cookingPotUUIDs[1])
            return
        end

        local submittedIngredients = {}
        for _, ingredient in pairs(cookingPotData.SubmittedIngredients) do
            local itemName = ingredient.ItemData and ingredient.ItemData.ItemName or ""

            if itemName == "" then
                continue
            end

            table.insert(submittedIngredients, itemName)
        end

        local unsubmittedItems, hasWrongItems = self:CompareIngredients(submittedIngredients)
        if hasWrongItems then
            -- Clear Ingredients
            Core.ReplicatedStorage.GameEvents.CookingPotService_RE:FireServer("EmptyPot", cookingPotUUIDs[1])
            task.wait(1)

            unsubmittedItems = self:CombineIngredientsConfig()
        end

        local ingredientTools = {}
        for _, ingredientName in pairs(unsubmittedItems) do
            local ingredientTool = self:FindIngredientInInventory(ingredientName)
            if not ingredientTool then
                ingredientTool = self:FindIngredientInFarm(ingredientName)
            end
            if ingredientTool then
                table.insert(ingredientTools, ingredientTool)
            else
                warn("AutoCooking: Unable to find ingredient '" .. ingredientName .. "' in inventory or farm.")
            end
        end

        if #ingredientTools ~= #unsubmittedItems then
            warn("AutoCooking: Not all required ingredients are available. Aborting cooking process.")
            return
        end

        -- Start Cooking
        self:StartCooking(cookingPotUUIDs[1], ingredientTools)
    end

    return m
end

-- Module: auto/ui.lua
EmbeddedModules["auto/ui.lua"] = function()
    local m = {}

    local Window
    local Core
    local Crafting
    local Plant
    local Cooking


    function m:Init(_window, _core, _crafting, _plant, _cooking)
        Window = _window
        Core = _core
        Crafting = _crafting
        Plant = _plant
        Cooking = _cooking

        local tab = Window:AddTab({
            Name = "AutoMation",
            Icon = "🔧",
        })

        self:CraftingGearSection(tab)
        self:CraftingSeedSection(tab)
        self:CookingSection(tab)
    end

    function m:CraftingGearSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Crafting Gear",
            Icon = "⚙️",
            Default = false,
        })

        accordion:AddSelectBox({
            Name = "Crafting Item ⚙️",
            Options = {"loading ..."},
            Placeholder = "Select Crafting Item",
            Flag = "CraftingGearItem",
            OnDropdownOpen = function(currentOptions, updateOptions)
                local craftingItems = Crafting:GetAllCraftingItems(workspace.CraftingTables.EventCraftingWorkBench)

                updateOptions(craftingItems)
            end
        })

        accordion:AddToggle({
            Name = "Auto Crafting Gear ⚙️",
            Default = false,
            Flag = "AutoCraftingGear",
        })
    end

    function m:CraftingSeedSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Crafting Seeds",
            Icon = "🌱",
            Default = false,
        })

        accordion:AddSelectBox({
            Name = "Crafting Item 🌱",
            Options = {"loading ..."},
            Placeholder = "Select Crafting Item",
            Flag = "CraftingSeedItem",
            OnDropdownOpen = function(currentOptions, updateOptions)
                local craftingItems = Crafting:GetAllCraftingItems(workspace.CraftingTables.SeedEventCraftingWorkBench)

                updateOptions(craftingItems)
            end
        })

        accordion:AddToggle({
            Name = "Auto Crafting Seeds 🌱",
            Default = false,
            Flag = "AutoCraftingSeeds",
        })
    end

    function m:CookingSection(tab)
        local accordion = tab:AddAccordion({
            Title = "Cooking",
            Icon = "🍳",
            Default = false,
        })

        local plantOptions = {}
        local plants = Plant:GetPlantRegistry()
        for _, plantData in pairs(plants) do
            table.insert(plantOptions, {
                text = plantData.plant,
                value = plantData.plant,
            })
        end

        accordion:AddSelectBox({
            Name = "Ingredient 1",
            Options = plantOptions or {"loading ..."},
            Placeholder = "Select Ingredient 1",
            Flag = "CookingIngredient1"
        })

        accordion:AddSelectBox({
            Name = "Ingredient 2",
            Options = plantOptions or {"loading ..."},
            Placeholder = "Select Ingredient 2",
            Flag = "CookingIngredient2"
        })

        accordion:AddSelectBox({
            Name = "Ingredient 3",
            Options = plantOptions or {"loading ..."},
            Placeholder = "Select Ingredient 3",
            Flag = "CookingIngredient3"
        })

        accordion:AddSelectBox({
            Name = "Ingredient 4",
            Options = plantOptions or {"loading ..."},
            Placeholder = "Select Ingredient 4",
            Flag = "CookingIngredient4"
        })

        accordion:AddSelectBox({
            Name = "Ingredient 5",
            Options = plantOptions or {"loading ..."},
            Placeholder = "Select Ingredient 5",
            Flag = "CookingIngredient5"
        })

        accordion:AddToggle({
            Name = "Auto Cooking 🍳",
            Default = false,
            Flag = "AutoCooking",
        })
    end

    return m
end

-- Module: inventory/seedpack.lua
EmbeddedModules["inventory/seedpack.lua"] = function()
    local m = {}

    local Window
    local Core
    local Player

    function m:Init(_window, _core, _player)
        Window = _window
        Core = _core
        Player = _player

        self:GetListAllSeedPacks()
    end

    function m:GetListAllSeedPacks()
        local dataSeedPacks = require(Core.ReplicatedStorage.Data.SeedPackData)
        local seedPacks = {}

        for name, _ in pairs(dataSeedPacks.Packs) do
            local owned = self:FindOwnedSeedPacks(name)

            table.insert(seedPacks, {
                Id = owned.Id,
                Name = name,
                Count = owned.Count,
            })
        end

        table.sort(seedPacks, function(a, b)
            if a.Name == b.Name then
                return a.Count < b.Count
            end
            return a.Name < b.Name
        end)

        return seedPacks
    end

    function m:FindOwnedSeedPacks(seedPackName)
        local detail = {
            Id = nil,
            Count = 0,
            Tool = nil,
        }

        for _, tool in next, Player:GetAllTools() do
            if tool:GetAttribute("b") ~= "a" then
                continue
            end

            if tool:GetAttribute("n") == seedPackName then
                detail.Id = tool:GetAttribute("c")
                detail.Count = tool:GetAttribute("e") or 0
                detail.Tool = tool
                break
            end
        end

        return detail
    end

    function m:OpenSeedPack()
        local seedPackName = Window:GetConfigValue("AutoOpenSeedPack")
        local totalToOpen = Window:GetConfigValue("AutoOpenSeedPackTotal") or 1

        if not seedPackName or seedPackName == "Loading..." then
            Window:ShowError("Seed Pack", "Please select a valid seed pack to open.")
            return
        end

        local ownedSeedPack = self:FindOwnedSeedPacks(seedPackName)

        if not ownedSeedPack.Tool then
            Window:ShowError("Seed Pack", string.format("You do not own any %s.", seedPackName))
            return
        end

        local toOpen = math.min(ownedSeedPack.Count, totalToOpen)

        if toOpen <= 0 then
            Window:ShowError("Seed Pack", string.format("You do not have enough %s to open.", seedPackName))
            return
        end

        local rollerUI = Core.LocalPlayer.PlayerGui:WaitForChild("RollCrate_UI")
        local playerActivation = nil

        for _, model in pairs(Core.Workspace:GetChildren()) do
            if model.Name == Core.LocalPlayer.Name then
                playerActivation = model:FindFirstChild("InputGateway").Activation
                break
            end
        end

        Window:ShowInfo("Seed Pack", string.format("Starting to open %d %s...", toOpen, seedPackName))
        for i = 1, toOpen do
            local openSeedPackTask = function()
                Window:ShowInfo("Seed Pack", string.format("Opening %s (%d/%d)...", seedPackName, i, toOpen))

                while not rollerUI.Enabled and not rollerUI.Frame.Visible do
                    playerActivation:FireServer(
                        true,
                        CFrame.new()
                    )

                    task.wait(0.1)
                end

                task.wait(1)
                local result = nil

                while not result do
                    if rollerUI.Frame.Rolled.ImageTransparency == 0 then
                        result = rollerUI.Frame.Rolled.Label.Text
                        break
                    end

                    for _, connection in pairs(getconnections(rollerUI.Frame.Skip.Activated)) do
                        connection:Fire()
                    end

                    task.wait(0.01)
                end

                Window:ShowInfo("Seed Pack", string.format("Opened %s and received: %s", seedPackName, result))

                 while rollerUI.Enabled and rollerUI.Frame.Visible do
                    task.wait(0.1)
                end
            end

            local isTaskCompleted = false
            local openSeedPackCallback = function()
                isTaskCompleted = true
            end

            local queueResult = Player:AddToQueue(
                ownedSeedPack.Tool,
                80,
                function()
                    openSeedPackTask()
                end,
                function()
                    openSeedPackCallback()
                end
            )

            if not queueResult then
                Window:ShowWarning("Seed Pack", "Failed to add task to queue")
                break
            end

            -- Wait with timeout to prevent infinite blocking
            local timeout = 30
            local elapsed = 0
            while not isTaskCompleted and elapsed < timeout do
                task.wait(0.1)
                elapsed = elapsed + 0.1
            end

            if not isTaskCompleted then
                Window:ShowWarning("Seed Pack", "Task timed out, stopping...")
                break
            end
        end

        Window:ShowInfo("Seed Pack", string.format("Finished opening %d %s.", toOpen, seedPackName))
    end

    return m
end

-- Module: misc/esp.lua
EmbeddedModules["misc/esp.lua"] = function()
    local m = {}

    local Window
    local Core
    local Egg

    function m:Init(_window, _core, _egg)
        Window = _window
        Core = _core
        Egg = _egg

        Core:MakeLoop(function()
            return Window:GetConfigValue("EggESP")
        end, function()
            self:CreateEggESP()
        end, 1)
    end

    function m:CreateESP(object, options)
        if not object or not options then
            return
        end

        -- Find the main part to attach ESP to
        local mainPart = object:IsA("Model") and (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
        if not mainPart then
            return
        end

        -- Get or create ESP container folder
        local espFolder = object:FindFirstChild("ESP")
        if not espFolder then
            espFolder = Instance.new("Folder")
            espFolder.Name = "ESP"
            espFolder.Parent = object

            -- Create BoxHandleAdornment for visual outline
            local boxAdornment = Instance.new("BoxHandleAdornment")
            boxAdornment.Name = "ESP"
            boxAdornment.Size = Vector3.new(1, 0, 1)
            boxAdornment.Transparency = 1
            boxAdornment.AlwaysOnTop = false
            boxAdornment.ZIndex = 0
            boxAdornment.Adornee = mainPart
            boxAdornment.Parent = espFolder

            -- Set ESP color if provided
            local espColor = options.Color or Color3.fromRGB(255, 255, 255)

            -- Create BillboardGui for text display
            local billboardGui = Instance.new("BillboardGui")
            billboardGui.Name = "BillboardGui"
            billboardGui.Size = UDim2.new(0, 150, 0, 40)
            billboardGui.StudsOffset = Vector3.new(0, 3, 0)
            billboardGui.AlwaysOnTop = true
            billboardGui.Adornee = mainPart
            billboardGui.Parent = espFolder

            -- Create TextLabel for displaying information
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "TextLabel"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = options.Text or "ESP"
            textLabel.TextColor3 = espColor
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.Arial
            textLabel.RichText = true
            textLabel.Parent = billboardGui
        else
            -- Update existing ESP text
            local billboardGui = espFolder:FindFirstChild("BillboardGui")
            if billboardGui then
                local textLabel = billboardGui:FindFirstChild("TextLabel")
                if textLabel then
                    textLabel.Text = options.Text or "ESP"
                end
            end
        end

        return espFolder
    end

    function m:RemoveESP(object)
        if not object then
            return
        end

        local espFolder = object:FindFirstChild("ESP")
        if espFolder then
            espFolder:Destroy()
        end
    end

    function m:CreateEggESP()
        if not Window:GetConfigValue("EggESP") then
            return
        end

        local success, err = pcall(function()
            for _, eggObject in pairs(Egg:GetAllPlacedEggs()) do
                pcall(function()
                    local isReady = eggObject:GetAttribute("READY")
                    local timeToHatch = eggObject:GetAttribute("TimeToHatch") or 0
                    local eggUUID = eggObject:GetAttribute("OBJECT_UUID")
                    if not eggUUID then
                        return
                    end

                    local eggData = Egg:GetPlacedEggDetail(eggUUID)
                    if not eggData then
                        return
                    end

                    local eggName = eggData.EggName or "Unknown Egg"
                    local petType = eggData.Type or "Unknown Pet"
                    local baseWeight = eggData.BaseWeight or 1

                    -- Calculate weight increment per age (approximately 0.1 * baseWeight per age)
                    local weightIncrement = baseWeight * 0.1
                    local actualWeight = baseWeight + (1 * weightIncrement)

                    local formattedWreight = string.format("%.2f", actualWeight)

                    local weightStatus = (
                        (actualWeight >= 9 and "Godly") or
                        (actualWeight >= 8 and actualWeight < 9 and "Titanic") or
                        (actualWeight >= 3 and actualWeight < 8 and "Huge") or
                        "Small"
                    )

                    local espText = ""
                    if isReady and timeToHatch <= 0 then
                        espText = string.format(
                            "<font color='rgb(0,255,0)'>%s</font>\n<font color='rgb(255,165,0)'>%s</font>\n<font color='rgb(0,255,255)'>%s KG (%s)</font>",
                            eggName,
                            petType,
                            formattedWreight,
                            weightStatus
                        )
                    else
                        espText = string.format(
                            "<font color='rgb(0,255,0)'>%s</font>\n<font color='rgb(255,165,0)'>⏰ %s</font>",
                            eggName,
                            Core:FormatTime(timeToHatch)
                        )
                    end

                    self:CreateESP(eggObject, {
                        Text = espText,
                        Color = Color3.fromRGB(255, 255, 255),
                    })
                end)
            end
        end)

        if not success then
            warn("EggESP: Error creating ESP -", err)
        end
    end

    function m:RemoveEggESP()
        for _, eggObject in pairs(Egg:GetAllPlacedEggs()) do
            self:RemoveESP(eggObject)
        end
    end

    return m
end

-- Module: misc/player_data.lua
EmbeddedModules["misc/player_data.lua"] = function()
    local m = {}

    local Window
    local Core

    local DataService

    function m:Init(_window, _core)
        Core = _core
        Window = _window

        DataService = require(Core.ReplicatedStorage.Modules.DataService)
    end

    function m:GetPlayerData()
        local gameData = DataService:GetData()
        if not gameData then
            warn("Game data not found")
            return {}
        end

       for key, value in pairs(gameData) do
            warn(string.format("Player Data - %s: %s", key, tostring(value)))
        end

        for key, value in pairs(gameData.TraderEventData or {}) do
            warn(string.format("Inventory Item - %s: %s", key, tostring(value)))
        end

        return gameData
    end

    return m
end

-- Load module helper function
local function loadModule(url)
    -- Try embedded module first
    if EmbeddedModules[url] then
        return EmbeddedModules[url]()
    end
    
    -- Fallback to original require
    return require(url)
end

-- Main Script
repeat wait() until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

-- Prevent double execution
if game:GetService("Players").LocalPlayer:GetAttribute("IsPandoraHubRunning") then
    game.StarterGui:SetCore(
        "SendNotification",
        {
            Title = "jordi_galer  Hub",
            Text = "jordi_galer  Hub is already running!",
            Duration = 5
        }
    )
    return
end

game:GetService("Players").LocalPlayer:SetAttribute("IsPandoraHubRunning", true)

-- Main entry point
local EzUI = loadModule("https://raw.githubusercontent.com/k1r4-id/ez-rbx-ui-custome/refs/heads/main/release/ez-rbx-ui.lua")
-- Import local modules
local CoreModule = loadModule("../module/core.lua")
local PlayerModule = loadModule("../module/player.lua")
local Discord = loadModule("../module/discord.lua")
local CoreWebhookModule = loadModule("../module/webhook.lua")
local Rarity = loadModule("rarity.lua")

-- Misc modules
local RemoveModule = loadModule("misc/remove.lua")
local ESPModule = loadModule("misc/esp.lua")
local CosmeticModule = loadModule("misc/cosmetic.lua")
local TeleportModule = loadModule("misc/teleport.lua")
local PlayerDataModule = loadModule("misc/player_data.lua")
local MiscUI = loadModule("misc/ui.lua")

-- Farm modules
local GardenModule = loadModule("farm/garden.lua")
local PlantModule = loadModule("farm/plant.lua")
local FarmUI = loadModule("farm/ui.lua")

-- Special modules (Nightmare/Leveling/Bulking)
local SpecialModule = loadModule("special/special.lua")
local SpecialUI = loadModule("special/ui.lua")
local SpecialWebhook = loadModule("special/webhook.lua")

-- Quest module
local AscensionModule = loadModule("quest/ascension.lua")
local SeasonPassModule = loadModule("quest/season_pass.lua")
local QuestUI = loadModule("quest/ui.lua")

-- Shop modules
local ShopSeedModule = loadModule("shop/seed.lua")
local ShopGearModule = loadModule("shop/gear.lua")
local ShopEggModule = loadModule("shop/egg.lua")
local ShopSeasonPassModule = loadModule("shop/season_pass.lua")
local ShopTravelingModule = loadModule("shop/traveling.lua")
local ShopGardenCoinModule = loadModule("shop/garden_coin.lua")
local ShopPremiumModule = loadModule("shop/premium.lua")
local ShopCosmeticModule = loadModule("shop/cosmetic.lua")
local ShopUI = loadModule("shop/ui.lua")

-- -- Pet modules
local PetTeamModule = loadModule("pet/team.lua")
local PetWebhook = loadModule("pet/webhook.lua")
local EggModule = loadModule("pet/egg.lua")
local PetModule = loadModule("pet/pet.lua")
local PetUI = loadModule("pet/ui.lua")

-- Automation modules
local CraftingModule = loadModule("auto/crafting.lua")
local CookingModule = loadModule("auto/cooking.lua")
local AutoUI = loadModule("auto/ui.lua")

-- Inventory modules
local InventoryModule = loadModule("inventory/inventory.lua")
local TradeModule = loadModule("inventory/trade.lua")
local SeedPackModule = loadModule("inventory/seedpack.lua")
local InventoryUI = loadModule("inventory/ui.lua")

-- Event modules
local NewYearShopModule = loadModule("event/new_year/shop.lua")
local NewYearsQuestModule = loadModule("event/new_year/quest.lua")
local NewYearUI = loadModule("event/new_year/ui.lua")

-- Notification module
local NotificationUI = loadModule("notification/ui.lua")
local NotificationWebhookModule = loadModule("notification/webhook.lua")

local playerName = CoreModule.LocalPlayer.Name or "Unknown"
local configFolder = string.format("PandoraHub/%s/GrowaGarden", playerName)


-- Wait for player data to be fully loaded
local notificationActive = true
task.spawn(function()
    while notificationActive do
        game.StarterGui:SetCore(
            "SendNotification",
            {
                Title = "jordi_galer  Hub",
                Text = "Waiting for player data to be fully loaded...",
                Duration = 3
            }
        )
        task.wait(2.5) -- Show notification again before it disappears
    end
end)

while not CoreModule.LocalPlayer:GetAttribute("DataFullyLoaded") or not CoreModule.LocalPlayer:GetAttribute("FarmFullyLoaded") do
    task.wait(1)
end

notificationActive = false -- Stop the notification loop

-- Initialize window
local window = EzUI:CreateNew({
    Title = "jordi_galer  Hub - Grow a Garden",
    Width = 700,
    Height = 400,
    Opacity = 0.9,
    AutoAdapt = true,
    AutoShow = false,
    FolderName = configFolder,
    FileName = "settings",
})

-- Update window close callback
window:SetCloseCallback(function()
    CoreModule.IsWindowOpen = false
    CoreModule.LocalPlayer:SetAttribute("IsPandoraHubRunning", false)

    -- Remove Anti-AFK connections
    PlayerModule:RemoveAntiAFK()

    -- Remove Reconnect connections
    PlayerModule:RemoveReconnect()

    -- Stop all queued tasks
    PlayerModule:ClearQueue()

    -- Stop all active loops
    CoreModule:StopAllLoops()

    -- Remove Egg ESP
    ESPModule:RemoveEggESP()

    -- Inventory: Stop auto favorite pets
    InventoryModule:StopAutoFavoritePets()

    -- Inventory: Stop auto fav/unfav bone blossom
    InventoryModule:StopAutoFavUnfavBoneBlossom()

    -- Hatch Egg: Stop auto hatching
    EggModule:StopAutoHatching()

    -- Trade: Stop auto accept gifts
    TradeModule:StopAutoAcceptGifts()

    -- Pet: Stop auto pickup pets
    PetModule:StopAutoPickupPets()
end)

petTeamsConfig = EzUI:NewConfig({
    FolderName = configFolder,
    FileName = "PetTeams",
})

petTeamsConfig:Load()

-- Wait and verify config is fully loaded
local maxWait = 10 -- max 10 seconds
local startTime = tick()
local configReady = false

print("⏳ Waiting for config system to be fully loaded...")
while not configReady and (tick() - startTime) < maxWait do
    -- Try to get a config value to verify config system is ready
    local testValue = window:GetConfigValue("AutoLevelingPets")
    if testValue ~= nil or (tick() - startTime) > 2 then
        configReady = true
        print("✅ Config system ready!")
    else
        print("⏳ Waiting for config to load... (" .. math.floor(tick() - startTime) .. "s)")
        task.wait(0.5)
    end
end

if not configReady then
    warn("⚠️ Config loading timeout - using default values")
else
    print("✅ Config loaded successfully in " .. string.format("%.2f", tick() - startTime) .. " seconds")
end

-- Core
CoreModule:Init(window)
CoreModule.IsWindowOpen = true

-- Core Webhook
CoreWebhookModule:Init(window, CoreModule, Discord)

-- Player
PlayerModule:Init(window, CoreModule, CoreWebhookModule)

-- Farm
GardenModule:Init(window, CoreModule, PlayerModule)
PlantModule:Init(window, CoreModule, PlayerModule, GardenModule, Rarity)
FarmUI:init(window, CoreModule, PlayerModule, GardenModule, PlantModule)

-- -- Pet
PetTeamModule:Init(CoreModule, PlayerModule, window, petTeamsConfig, GardenModule)
PetWebhook:Init(window, CoreModule, Discord, Rarity)
PetModule:Init(CoreModule, PlayerModule, window, GardenModule, PetTeamModule, PetWebhook, Rarity, PlantModule)
EggModule:Init(CoreModule, PlayerModule, window, GardenModule, PetModule, PetWebhook)
PetUI:Init(window, PetTeamModule, EggModule, PetModule, GardenModule, PlayerModule, CoreModule, PlantModule)

-- Special (Auto Nightmare / Leveling / Bulking)
SpecialWebhook:Init(window, CoreModule, Discord)
SpecialModule:Init(CoreModule, PlayerModule, window, GardenModule, PetTeamModule, PetModule, SpecialWebhook, Rarity)
SpecialUI:Init(window, PetTeamModule, EggModule, PetModule, GardenModule, PlayerModule)

-- Automation
CraftingModule:Init(window, CoreModule, PlantModule)
CookingModule:Init(window, CoreModule, PlayerModule, PlantModule)
AutoUI:Init(window, CoreModule, CraftingModule, PlantModule, CookingModule)

-- Shop
ShopSeedModule:Init(window, CoreModule)
ShopCosmeticModule:Init(window, CoreModule)
ShopGearModule:Init(window, CoreModule)
ShopEggModule:Init(window, CoreModule)
ShopTravelingModule:Init(window, CoreModule, PetModule)
ShopGardenCoinModule:Init(window, CoreModule)
ShopSeasonPassModule:Init(window, CoreModule)
ShopPremiumModule:Init(window, CoreModule)
ShopUI:Init(window, CoreModule, ShopEggModule, ShopSeedModule, ShopGearModule, ShopSeasonPassModule, ShopTravelingModule, ShopPremiumModule, PetTeamModule, Rarity, ShopCosmeticModule, ShopGardenCoinModule)

-- Quest
AscensionModule:Init(window, CoreModule, PlantModule, PlayerModule)
SeasonPassModule:Init(window, CoreModule)
QuestUI:Init(window, CoreModule, AscensionModule)

-- Inventory
InventoryModule:Init(CoreModule, PlayerModule, window, PetModule)
TradeModule:Init(CoreModule, window, PlayerModule, PetModule)
SeedPackModule:Init(window, CoreModule, PlayerModule)
InventoryUI:Init(window, CoreModule, InventoryModule, PetModule, TradeModule, SeedPackModule)

-- Set Inventory Module for PetUI (for Auto Fav/Unfav Bone Blossom feature)
PetUI:SetInventoryModule(InventoryModule)

-- Set Inventory Module for EggModule and PetModule (for Gear Glitch feature)
EggModule:SetInventoryModule(InventoryModule)
PetModule:SetInventoryModule(InventoryModule)

-- Misc
RemoveModule:Init(window, CoreModule)
ESPModule:Init(window, CoreModule, EggModule)
CosmeticModule:Init(window, CoreModule)
TeleportModule:Init(window, CoreModule, GardenModule, PlayerModule)
PlayerDataModule:Init(window, CoreModule)
MiscUI:Init(window, CoreModule, PlayerModule, GardenModule, RemoveModule, ESPModule, CosmeticModule, PlayerDataModule, TeleportModule)

-- -- Notification
NotificationWebhookModule:Init(window, CoreModule, Discord)
NotificationUI:Init(window, NotificationWebhookModule)
NotificationUI:CreateNotificationTab()

-- ========================================
-- CRITICAL FIX: Refresh all toggle states from config
-- This ensures UI toggles sync with saved config values after reconnect
-- ========================================
task.wait(1) -- Extra safety wait to ensure all UI components are fully rendered

print("🔄 Refreshing UI states from config...")

-- Refresh Toggle states
local specialRefreshed = SpecialUI:RefreshToggleStates()
local petRefreshed = PetUI:RefreshToggleStates()
local farmRefreshed = FarmUI:RefreshToggleStates()
local shopRefreshed = ShopUI:RefreshToggleStates()
local miscRefreshed = MiscUI:RefreshToggleStates()
local inventoryRefreshed = InventoryUI:RefreshToggleStates()
local newYearRefreshed = NewYearUI:RefreshToggleStates() or 0

local totalToggles = specialRefreshed + petRefreshed + farmRefreshed + shopRefreshed + miscRefreshed + inventoryRefreshed + newYearRefreshed

-- Refresh SelectBox states (dropdowns/selections)
local specialSelectRefreshed = SpecialUI:RefreshSelectBoxStates() or 0
local petSelectRefreshed = PetUI:RefreshSelectBoxStates() or 0
local shopSelectRefreshed = ShopUI:RefreshSelectBoxStates() or 0
local newYearSelectRefreshed = NewYearUI:RefreshSelectBoxStates() or 0

local totalSelectBoxes = specialSelectRefreshed + petSelectRefreshed + shopSelectRefreshed + newYearSelectRefreshed

-- Refresh NumberBox states
local specialNumberRefreshed = SpecialUI:RefreshNumberBoxStates() or 0
local petNumberRefreshed = PetUI:RefreshNumberBoxStates() or 0
local inventoryNumberRefreshed = InventoryUI:RefreshNumberBoxStates() or 0
local miscNumberRefreshed = MiscUI:RefreshNumberBoxStates() or 0
local farmNumberRefreshed = FarmUI:RefreshNumberBoxStates() or 0
local questNumberRefreshed = QuestUI:RefreshNumberBoxStates() or 0

local totalNumberBoxes = specialNumberRefreshed + petNumberRefreshed + inventoryNumberRefreshed + miscNumberRefreshed + farmNumberRefreshed + questNumberRefreshed

-- Refresh TextBox states
local notificationTextRefreshed = NotificationUI:RefreshTextBoxStates() or 0

local totalTextBoxes = notificationTextRefreshed

print(string.format("✅ Refreshed %d toggles, %d selectboxes, %d numberboxes, and %d textboxes successfully!", totalToggles, totalSelectBoxes, totalNumberBoxes, totalTextBoxes))
print(string.format("   Toggles - Special: %d, Pet: %d, Farm: %d, Shop: %d, Misc: %d, Inventory: %d, NewYear: %d",
    specialRefreshed, petRefreshed, farmRefreshed, shopRefreshed, miscRefreshed, inventoryRefreshed, newYearRefreshed))
print(string.format("   SelectBoxes - Special: %d, Pet: %d, Shop: %d, NewYear: %d",
    specialSelectRefreshed, petSelectRefreshed, shopSelectRefreshed, newYearSelectRefreshed))
print(string.format("   NumberBoxes - Special: %d, Pet: %d, Inventory: %d, Misc: %d, Farm: %d, Quest: %d",
    specialNumberRefreshed, petNumberRefreshed, inventoryNumberRefreshed, miscNumberRefreshed, farmNumberRefreshed, questNumberRefreshed))
print(string.format("   TextBoxes - Notification: %d",
    notificationTextRefreshed))
print("🎉 Script initialization complete! All settings restored.")

-- ========================================
-- END OF CRITICAL FIX
-- ========================================
