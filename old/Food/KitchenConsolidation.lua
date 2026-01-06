local FoodType = require "core/domain/FoodType"

local KC_FOOD_TYPES = {
    -- Vegetable Pieces (authoritative from kitchenconsolidation_vegetable.txt)
    FoodType.new{ fullType = "KitchenConsolidation.AvocadoPieces",        maxHunger = 0.15, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.BellPepperPieces",     maxHunger = 0.08,  isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.BroccoliPieces",       maxHunger = 0.09,  isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.CabbagePieces",        maxHunger = 0.25, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.CarrotPieces",         maxHunger = 0.08,  isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.CornPieces",           maxHunger = 0.14, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.DaikonPieces",         maxHunger = 0.12, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.EggplantPieces",       maxHunger = 0.16, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.PepperHabaneroPieces", maxHunger = 0.02,  isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.PepperJalapenoPieces", maxHunger = 0.02,  isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.LeekPieces",           maxHunger = 0.12, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.LettucePieces",        maxHunger = 0.15, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.MushroomGenericPieces",maxHunger = 0.13, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.OnionPieces",          maxHunger = 0.10, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.PotatoPieces",         maxHunger = 0.18, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.RedRadishPieces",      maxHunger = 0.03,  isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.SeaweedPieces",        maxHunger = 0.03,  isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.TomatoPieces",         maxHunger = 0.12, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.ZucchiniPieces",       maxHunger = 0.10, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.TofuPieces",           maxHunger = 0.10, isContainerized = true },

    -- Protein Pieces
    FoodType.new{ fullType = "KitchenConsolidation.MeatPieces",           maxHunger = 0.23, isContainerized = true },
    FoodType.new{ fullType = "KitchenConsolidation.FishPieces",           maxHunger = 0.25, isContainerized = true },
}

return KC_FOOD_TYPES