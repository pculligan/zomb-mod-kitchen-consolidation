local FoodType = require "Domain/FoodType"

return {
    FoodType.new{ fullType = "Base.Rabbitmeat", prepTo = "KitchenConsolidation.MeatPieces" },
    FoodType.new{ fullType = "Base.SalamiHomemade", prepTo = "KitchenConsolidation.MeatPieces" },
    FoodType.new{ fullType = "Base.SaltedMeat", prepTo = "KitchenConsolidation.MeatPieces" },
    FoodType.new{ fullType = "Base.Smallanimalmeat", prepTo = "KitchenConsolidation.MeatPieces" },
    FoodType.new{ fullType = "Base.Smallbirdmeat", prepTo = "KitchenConsolidation.MeatPieces" },
    FoodType.new{ fullType = "Base.SmokedMeat", prepTo = "KitchenConsolidation.MeatPieces" },
}
