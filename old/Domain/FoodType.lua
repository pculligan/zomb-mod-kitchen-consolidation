
local FoodType = {}

function FoodType.new(args)
    return {
        fullType = args.fullType,
        maxHunger = args.maxHunger,
        prepTo = args.prepTo,
        isContainerized = args.isContainerized or false,
        byproductsOnEmpty = args.byproductsOnEmpty or {},
    }
end

return FoodType
