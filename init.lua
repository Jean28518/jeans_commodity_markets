-- jeans_commodity_markets = fmod.create()

jeans_commodity_markets = {}

jeans_commodity_markets.storage = core.get_mod_storage()


core.register_node("jeans_commodity_markets:market", {
    description = "Commodity Market",
    tiles = {"default_stone.png", "default_diamond_block.png"},
    groups = {cracky = 3},
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local player_name = clicker:get_player_name()
        -- Get wielded item
        local wielded_item = clicker:get_wielded_item():get_name()
        if not wielded_item then
            wielded_item = ""
        end
        show_market_formspec(player_name, pos, wielded_item)
    end,
})

core.register_craft({
    output = "jeans_commodity_markets:market",
    recipe = {
        {"default:diamondblock", "default:diamondblock", "default:diamondblock"},
        {"default:diamondblock", "default:chest_locked", "default:diamondblock"},
        {"default:diamondblock", "default:diamondblock", "default:diamondblock"},
    }
})

-- Define the market formspec
function show_market_formspec(player_name, pos, search_text)
    -- Dynamically generate a list of all registered items
    local item_list = {}
    for name, def in pairs(core.registered_items) do
        -- Exclude hidden or non-inventory items
        if not def.groups or not def.groups.not_in_creative_inventory then
            table.insert(item_list, name)
        end
    end

    -- Filter them by search text
    if search_text and search_text ~= "" then
        local filtered_items = {}
        for _, item in ipairs(item_list) do
            if string.find(item:lower(), search_text:lower(), 1, true) then
                table.insert(filtered_items, item)
            end
        end
        item_list = filtered_items
    end

    -- Sort the item list
    table.sort(item_list)

    -- Create a formspec inventory list with all items (as an image button grid)
    local formspec_items = ""
    local x, y = 0, 0
    local per_row = 11
    for i, item in ipairs(item_list) do
        formspec_items = formspec_items ..
            string.format('item_image_button[%d,%d;1,1;%s;item__%s;]', x, y, item, item:gsub(":", "_MAGIC_"))
        x = x + 1
        if x >= per_row then
            x = 0
            y = y + 1
        end
    end

    local max_scrollbar_items = math.ceil(#item_list / per_row) * 10
    local formspec = "size[12,9]" ..
                    "field[0.1,0.3;12,1;search;Search:;" .. minetest.formspec_escape(search_text or "") .. "]" ..
                    "scrollbaroptions[max=" .. max_scrollbar_items .. ";thumbsize=10]" ..
                    "scrollbar[11.5,1;0.2,8;vertical;item_scrollbar;0]" ..
                    "scroll_container[0,1.5;14,9;item_scrollbar;vertical]" ..
                    formspec_items ..
                    "scroll_container_end[]" 
                    -- "button[0,6;2,1;buy;Buy]" ..
                    -- "button[2,6;2,1;sell;Sell]" ..
                    --  "button[4,6;2,1;close;Close]"

    core.show_formspec(player_name, "jeans_commodity_markets:market", formspec)
end


-- Handle formspec button presses
core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "jeans_commodity_markets:market" then
        return false
    end
    -- if fields.close then
    --     -- Close the formspec by showing an empty one
    --     core.show_formspec(player:get_player_name(), "", "")
    --     return true
    -- end
    -- if fields.buy then
    --     -- Handle buying logic here
    --     local button_pressed_times = core.deserialize(jeans_commodity_markets.storage:get_string("button_pressed"))
    --     if not button_pressed_times then
    --         button_pressed_times = 0
    --     end
    --     button_pressed_times = button_pressed_times + 1
    --     jeans_commodity_markets.storage:set_string("button_pressed", core.serialize(button_pressed_times))
    --     core.chat_send_player(player:get_player_name(), "Buy button pressed " .. button_pressed_times .. " times")
    --     return true
    -- end
    if fields.search then
        local search_text = fields.search
        show_market_formspec(player:get_player_name(), player:get_pos(), search_text)
    end
    for key, _ in pairs(fields) do
        if key:sub(1, 6) == "item__" then
            local item_name = key:sub(7):gsub("_MAGIC_", ":")
            core.chat_send_player(player:get_player_name(), "Item button pressed: " .. item_name)
            show_detail_formspec(player:get_player_name(), player:get_pos(), item_name)
            return true
        end
    end
    return false
end)

function show_detail_formspec(player_name, pos, item_name)
    -- Image of the Icon, name, Button for price history at the right corner
    -- Sell orders with columns: Distance, Quantity, Price, Location, Expires in, sell button
    -- Buy orders with columns: Distance, Quantity, Price, Location, Expires in, buy button
    -- Button to return to market, Button to place a buy order, Button to place a sell order

    local item_def = core.registered_items[item_name]
    local item_image = item_def and item_def.inventory_image or "unknown_item.png"

    local item_display_name = item_def and item_def.description or "Unknown Item"

    local sell_orders = {
        {distance=10, quantity=200, price=15, location="Station C", expires="30m"},
        {distance=25, quantity=75, price=18, location="Station D", expires="1h"},
    }
    local table_sell_order_string = "Distance,Quantity,Price,Location,Expires,"
    for _, order in ipairs(sell_orders) do
        table_sell_order_string = table_sell_order_string ..
            string.format("%d,%d,%d,%s,%s,", order.distance, order.quantity, order.price, order.location, order.expires)
    end
    table_sell_order_string = table_sell_order_string:sub(1, -2) -- Remove trailing comma

    local buy_orders = {
        {distance=5, quantity=100, price=10, location="Station A", expires="1h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
        {distance=15, quantity=50, price=12, location="Station B", expires="2h"},
    }
    local table_buy_order_string = "Distance,Quantity,Price,Location,Expires,"
    for _, order in ipairs(buy_orders) do
        table_buy_order_string = table_buy_order_string ..
            string.format("%d,%d,%d,%s,%s,", order.distance, order.quantity, order.price, order.location, order.expires)
    end
    table_buy_order_string = table_buy_order_string:sub(1, -2) -- Remove trailing comma


    -- Documentation for table: 
    -- tableoptions[<opt 1>;<opt 2>;...]¶
    -- table[<X>,<Y>;<W>,<H>;<name>;<cell 1>,<cell 2>,...,<cell n>;<selected idx>]

    local formspec = "size[12,10]" ..
                    "image[0.1,0.1;1,1;" .. item_image .. "]" ..
                    "label[1.5,0.1;" .. core.formspec_escape(item_display_name) .. "]" ..
                    "label[1.5,0.4;" .. "(If you want to fulfill a specific order, double-click a row below.)" .. "]" ..
                    "button[10,0.2;2,0.5;price_history;Price History]" ..
                    "label[0,1.5;Sell Orders:]" ..
                    "tablecolumns[text;text;text;text;text]" ..
                    "tableoptions[border=true]" ..
                    "table[0,2;12,3;sell_orders;" .. table_sell_order_string .. ";0]" ..
                    "label[0,5;Buy Orders:]" ..
                    "tablecolumns[text;text;text;text;text]" ..
                    "tableoptions[border=true]" ..
                    "table[0,5.5;12,3;buy_orders;" .. table_buy_order_string .. ";0]" ..
                    "button[0,9;2,1;back;Back to Market]" ..
                    "button[2,9;3,1;buy;Buy]" ..
                    "button[5,9;3,1;sell;Sell]"

    core.show_formspec(player_name, "jeans_commodity_markets:detail", formspec)
end

-- Handle formspec button presses
core.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "jeans_commodity_markets:detail" then
        if fields.back then
            show_market_formspec(player:get_player_name(), player:get_pos(), "")
        elseif fields.place_buy then
            core.show_formspec(player:get_player_name(), "jeans_commodity_markets:place_buy", formspec)
        elseif fields.place_sell then
            core.show_formspec(player:get_player_name(), "jeans_commodity_markets:place_sell", formspec)
        end
        if fields.sell_orders then
            table_event = core.explode_table_event(fields.sell_orders)
            if table_event.type == "DCL" then
                -- core.chat_send_player(player:get_player_name(), "Double-clicked sell row: " .. table_event.row)
                -- TODO: We need to get the actual, item_name, quantity and sell price here.
                show_sell_formspec(player:get_player_name(), player:get_pos(), , nil, nil)
            end
        end
        -- Check if a table row was clicked
        if fields.buy_orders then
            table_event = core.explode_table_event(fields.buy_orders)
            if table_event.type == "DCL" then
                core.chat_send_player(player:get_player_name(), "Double-clicked buy row: " .. table_event.row)
            end
        end
    end

    return false
end)


-- Sell Screen
function show_sell_formspec(player_name, pos, item_name, sell_price, quantity)
    -- Image of the Icon, name
    -- Duration of the sell order (Dropdown between 1d, 3d, 7d, 14d, 30d, 90d)
    -- Sell price input field, Quantity input field
    -- Label for broker fee
    -- Label for sales tax
    -- Label for total cost
    -- Button to confirm placing the sell order, Button to go back to detail screen
    -- Show player inventory

    item_image = core.get_item_image(item_name)
    item_display_name = core.get_item_display_name(item_name)

    -- TODO Get the best sell price and quantity.
    if sell_price == nil then
        sell_price = 0
    end

    if quantity == nil then
        quantity = 0
    end

    formspec = "size[12,10]" ..
               "image[0.1,0.1;1,1;" .. item_image .. "]" ..
               "label[1.5,0.1;Sell " .. core.formspec_escape(item_display_name) .. "]" ..
               "dropdown[0.5,1;3;duration;1d,3d,7d,14d,30d,90d;0]" ..
               "field[0.5,2;3,1;price;Price;" .. sell_price .. "]" ..
               "field[0.5,3;3,1;quantity;Quantity;" .. quantity .. "]" ..
               "label[0,4;Broker Fee:]" ..
               "label[0,5;Sales Tax:]" ..
               "label[0,6;Total Cost:]" ..
               "button[0,8;2,1;confirm;Confirm]" ..
               "button[2,8;3,1;back;Back]"

               -- Show player inventory
    formspec = formspec .. "label[0,7;Your Inventory:]" ..
                "tablecolumns[text;text;text;text;text]" ..
                "tableoptions[border=true]" ..
                "list[current_player;main;0,8;12,1;]"

    core.show_formspec(player_name, "jeans_commodity_markets:sell", formspec)
end
