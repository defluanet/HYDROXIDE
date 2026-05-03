-- // hydroxide.solutions PROPIETRARRY code?????

--[[
getgenv().stella_token = "the_token_here"
getgenv().stella_debug = false  -- optional, enables debug logging

pcall(function()
    loadstring(game:HttpGet("https://api.hydroxide.solutions/hello.lua",true))()
end)
--]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 1087859240 then
    return
end

local cloneref = cloneref or function(v) return v end
local req = http_request or request
local function generate_key()
    local players_service = cloneref(game:GetService("Players"))
    local str = game.PlaceId ..
        "_" .. game.JobId:sub(1, 5) .. "_" .. tostring(players_service.LocalPlayer.UserId):sub(-3)
    local chars = {}
    for i = 1, #str do
        local char = string.byte(str, i)
        chars[i] = string.char(bit32.bxor(char, 27 + (i % 7)))
    end
    return table.concat(chars)
end

local user_debug = getgenv().stella_debug or false
local user_webhook = getgenv().stella_webhook or getgenv().stella_webhook_url
local user_webhook_queue = getgenv().stella_webhook_queue
local user_alert_targets = getgenv().stella_alert_targets
local user_brand_name = getgenv().stella_brand_name
local user_brand_icon = getgenv().stella_brand_icon

if (not user_webhook or user_webhook == "") then
    warn("Stella | Set getgenv().stella_webhook before loading.")
    return
end

local _key = generate_key()
if getgenv()[_key] and type(getgenv()[_key]) == "table" then
    --warn("Stella | already running!")
    return
end

getgenv()[_key] = setmetatable({}, { __tostring = function() return "nil" end })
getgenv().stella_token = nil
getgenv().stella_debug = nil
getgenv().stella_webhook = nil
getgenv().stella_webhook_url = nil
getgenv().stella_webhook_queue = nil
getgenv().stella_alert_targets = nil
getgenv().stella_brand_name = nil
getgenv().stella_brand_icon = nil

local success, err = xpcall(function()
    local config = {
        webhook_url = user_webhook,
        webhook_use_queue = user_webhook_queue ~= false,
        alert_targets = type(user_alert_targets) == "table" and user_alert_targets or {},
        brand_name = (type(user_brand_name) == "string" and user_brand_name ~= "") and user_brand_name or "Hydroxide Intelligence",
        brand_icon = (type(user_brand_icon) == "string" and user_brand_icon ~= "") and user_brand_icon or nil,
        snapshot_cooldown = 45,

        send_interval = 35,
        api_fetch_interval = 300, -- seconds between Roblox API server list fetches

        debug = user_debug,
    }

    local function debug_info(level, ...)
        if not config.debug then return end
        if level == "warn" then
            warn("[Stella]", ...)
        else
            print("[Stella]", ...)
        end
    end

    local services = setmetatable({}, {
        __index = function(self, name)
            local success, result = pcall(game.GetService, game, name)
            if success then
                local service = cloneref(result)
                rawset(self, name, service)
                return service
            end
            debug_info("warn", "Invalid Service:", tostring(name))
        end
    })

    for _, v in pairs(getconnections(services.ScriptContext.Error)) do
        v:Disable()
    end

    local http_service = services.HttpService
    local players = services.Players
    local replicated_storage = services.ReplicatedStorage
    local workspace = services.Workspace

    local player_embed_cache = {}
    local server_embed_signature = nil

    if type(config.webhook_url) == "string" and config.webhook_url ~= "" and config.webhook_use_queue then
        if config.webhook_url:find("/api/webhooks/") and not config.webhook_url:find("/queue") then
            config.webhook_url = config.webhook_url .. "/queue"
        end
    end

    local race_colors = {}
    local race_eye_colors = {}
    local player_races = {}

    local race_tools = {
        ["Bloodline"] = "Haseldan",
        ["Awakened"] = "Dzin",
        ["Dissolve"] = "Fischeran",
        ["Flood"] = "Rigan",
        ["Tempest Soul"] = "Vind",
        ["Flock"] = "Morvid",
        ["Soul Rip"] = "Dinakeri",
        ["Shift"] = "Madrasian",
        ["Vagrant Soul"] = "Lich",
        ["Emulate"] = "LesserNavaran",
        ["Jack"] = "Navaran",
        ["Respirare"] = "Kasparan",
        ["Repair"] = "Gaian",
        ["Galvanize"] = "Construct",
        ["Pumpkin Grenade"] = "Dullahan",
        ["Biting Grenade"] = "Dullahan",
    }

    local function colors_match(c1, c2, tolerance)
        if not c1 or not c2 then return false end
        tolerance = tolerance or 0.01
        local success, result = pcall(function()
            return math.abs(c1.R - c2.R) <= tolerance
                and math.abs(c1.G - c2.G) <= tolerance
                and math.abs(c1.B - c2.B) <= tolerance
        end)
        return success and result
    end

    local function init_race_colors()
        local info = replicated_storage:FindFirstChild("Info")
        if not info then return end

        local races = info:FindFirstChild("Races")
        if not races then return end

        for _, race_category in next, races:GetChildren() do
            if not race_category:IsA("Folder") then continue end

            local direct_skin_color = race_category:FindFirstChild("SkinColor")
            if direct_skin_color and direct_skin_color:IsA("Color3Value") then
                table.insert(race_colors, {
                    direct_skin_color.Value,
                    race_category.Name
                })
            end

            local direct_eye_color = race_category:FindFirstChild("EyeColor")
            if direct_eye_color and direct_eye_color:IsA("Color3Value") then
                table.insert(race_eye_colors, {
                    direct_eye_color.Value,
                    race_category.Name
                })
            end

            for _, race_variant in next, race_category:GetChildren() do
                if not race_variant:IsA("Folder") then continue end

                local skin_color = race_variant:FindFirstChild("SkinColor")
                if skin_color and skin_color:IsA("Color3Value") then
                    table.insert(race_colors, {
                        skin_color.Value,
                        race_category.Name
                    })
                end

                local eye_color = race_variant:FindFirstChild("EyeColor")
                if eye_color and eye_color:IsA("Color3Value") then
                    table.insert(race_eye_colors, {
                        eye_color.Value,
                        race_variant.Name ~= race_category.Name and race_category.Name or race_category.Name
                    })
                end
            end
        end

        -- Cameo: unique eye color (111, 16, 158) in 0-255 scale
        table.insert(race_eye_colors, {
            Color3.fromRGB(111, 16, 158),
            "Cameo"
        })
    end

    local function get_player_tools(player)
        local tools = {}

        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            local success, children = pcall(function() return backpack:GetChildren() end)
            if success and children then
                for _, tool in ipairs(children) do
                    if tool:IsA("Tool") or tool:IsA("Folder") then
                        table.insert(tools, tool.Name)
                    end
                end
            end
        end

        local character = player.Character
        if character then
            local success, children = pcall(function() return character:GetChildren() end)
            if success and children then
                for _, tool in ipairs(children) do
                    if tool:IsA("Tool") then
                        table.insert(tools, tool.Name)
                    end
                end
            end
        end

        return tools
    end

    local function get_player_race(player)
        if player_races[player] and tick() - player_races[player].last_update_at <= 5 then
            return player_races[player].name
        end

        local race_found = "Unknown"
        local character = player.Character

        if not character then
            return race_found
        end

        local scroom_head = character:FindFirstChild("ScroomHead")
        local is_metascroom = scroom_head and pcall(function() return scroom_head.Material.Name end) and
            scroom_head.Material.Name == "DiamondPlate"

        if scroom_head then
            if is_metascroom then
                race_found = "Metascroom"
            else
                race_found = "Scroom"
            end
            player_races[player] = {
                last_update_at = tick(),
                name = race_found
            }
            return race_found
        end

        local player_tools = get_player_tools(player)

        local tool_set = {}
        for _, t in ipairs(player_tools) do
            tool_set[t] = true
        end

        for _, tool_name in ipairs(player_tools) do
            local race = race_tools[tool_name]
            if race then
                if tool_name == "Soul Rip" and (tool_set["Dark Charged Blow"] or tool_set["Mirror"]) then
                    continue
                end
                if tool_name == "Repair" and is_metascroom then
                    continue
                end
                if tool_name == "Emulate" and tool_set["Jack"] then
                    continue
                end
                race_found = race
                break
            end
        end

        if race_found == "Unknown" then
            local head = character:FindFirstChild("Head")
            if head then
                local rl_face = head:FindFirstChild("RLFace")
                if rl_face then
                    local ok, eye_color = pcall(function() return rl_face.Color3 end)
                    if ok and eye_color then
                        for _, v in next, race_eye_colors do
                            local ref_color, race_name = v[1], v[2]
                            if colors_match(eye_color, ref_color) then
                                race_found = race_name
                                break
                            end
                        end
                    end
                end

                if race_found == "Unknown" then
                    local success, head_color = pcall(function() return head.Color end)
                    if success and head_color then
                        for _, v in next, race_colors do
                            local skin_color, race_name = v[1], v[2]
                            if colors_match(head_color, skin_color) then
                                race_found = race_name
                                break
                            end
                        end
                    end
                end
            end
        end

        player_races[player] = {
            last_update_at = tick(),
            name = race_found
        }

        return race_found
    end

    local function get_player_artifact(player)
        local character = player.Character
        if not character then return nil end

        local artifacts_folder = character:FindFirstChild("Artifacts")
        if not artifacts_folder then return nil end

        local success, children = pcall(function() return artifacts_folder:GetChildren() end)
        if not success or not children then return nil end
        if #children == 0 then return "None" end

        for _, v in pairs(children) do
            if v.Name ~= " " and v.Name ~= "" then
                return v.Name
            end
        end

        return "None"
    end

    local function get_edict_hint(player)
        local character = player.Character
        if not character then return nil end

        local head = character:FindFirstChild("Head")
        if not head then return nil end

        local facial_marking = head:FindFirstChild("FacialMarking")
        if not facial_marking then return nil end

        local success, texture = pcall(function() return tostring(facial_marking.Texture) end)
        if not success or not texture then return nil end

        local base_url = "http://www.roblox.com/asset/?id="
        if texture == base_url .. "4072968006" then
            return "Healer"
        elseif texture == base_url .. "4072968656" then
            return "Blademaster"
        elseif texture == base_url .. "4072914434" then
            return "Seer"
        end

        return nil
    end

    local function get_player_dye(player)
        local character = player.Character
        if not character then return nil end

        local shirt = character:FindFirstChildOfClass("Shirt")
        if not shirt then return nil end

        local success, color = pcall(function() return tostring(shirt.Color3) end)
        if not success then return nil end

        return color
    end

    local function get_player_attr(player, attr_name)
        if game.PlaceId == 3541987450 then
            local success, result = pcall(function()
                return player.leaderstats[attr_name].Value
            end)
            if success then return result end
        else
            local success, result = pcall(function()
                return player:GetAttribute(attr_name)
            end)
            if success then return result end
        end
        return nil
    end

    local function get_player_name(player)
        local first_name = get_player_attr(player, "FirstName")
        if not first_name or first_name == "" then
            for _ = 1, 6 do -- check if attributes have not replicated yet -zyu
                task.wait(0.5)
                first_name = get_player_attr(player, "FirstName")
                if first_name and first_name ~= "" then break end
            end
        end
        if not first_name or first_name == "" then
            return "Unknown"
        end

        local uber_title = get_player_attr(player, "UberTitle")
        if uber_title and uber_title ~= "" then
            return first_name .. ", " .. uber_title
        end

        return first_name
    end

    local function get_player_house(player)
        local last_name = get_player_attr(player, "LastName")
        if last_name and last_name ~= "" then
            return last_name
        end
        return nil
    end

    local function get_lord_status(player)
        local house_rank = get_player_attr(player, "HouseRank")
        if not house_rank then return nil end

        if house_rank == "Owner" then
            local gender = get_player_attr(player, "Gender")
            if gender == "Female" then
                return "Lady"
            else
                return "Lord"
            end
        end
        return nil
    end

    local function get_player_gender(player)
        local gender = get_player_attr(player, "Gender")
        if not gender then return true end
        return gender == "Male"
    end

    local function get_location_name(player)
        local success, result = pcall(function()
            local pos = nil

            local recently_spawned = player:FindFirstChild("RecentlySpawned")
            if recently_spawned and recently_spawned:IsA("Vector3Value") then
                pos = recently_spawned.Value
            end

            if not pos and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pos = hrp.Position
                end
            end

            if not pos then return nil end
            local area_markers = workspace:FindFirstChild("AreaMarkers")
            if not area_markers then
                return string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
            end

            local location_name = nil
            local markers = area_markers:GetChildren()
            local ray_params = RaycastParams.new()
            ray_params.FilterType = Enum.RaycastFilterType.Include
            ray_params.FilterDescendantsInstances = { area_markers }

            local ray_result = workspace:Raycast(pos, Vector3.new(0, -1, 0) * 9999, ray_params)
            if ray_result and ray_result.Instance then
                local hit = ray_result.Instance
                if hit.Parent == area_markers then
                    location_name = hit.Name
                else
                    for _, marker in pairs(markers) do
                        if hit:IsDescendantOf(marker) then
                            location_name = marker.Name
                            break
                        end
                    end
                end
            end

            if not location_name then
                local closest_dist = math.huge
                for _, marker in pairs(markers) do
                    local dist = (marker.Position - pos).Magnitude
                    if dist < closest_dist then
                        closest_dist = dist
                        location_name = marker.Name
                    end
                end
            end

            if location_name then
                return string.format("%s (%.0f, %.0f, %.0f)", location_name, pos.X, pos.Y, pos.Z)
            end

            return string.format("(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
        end)

        return success and result or nil
    end

    local function get_player_blessings(player)
        if game.PlaceId ~= 3541987450 then
            return nil
        end

        local success, result = pcall(function()
            if not player.Character then return nil end
            local blessings_folder = player.Character:FindFirstChild("Blessings")
            if not blessings_folder then return nil end

            local blessing_names = {}
            for _, blessing in pairs(blessings_folder:GetChildren()) do
                table.insert(blessing_names, blessing.Name)
            end

            if #blessing_names > 0 then
                return table.concat(blessing_names, ", ")
            end
            return nil
        end)

        if success then
            return result
        end
        return nil
    end

    local function get_player_outfit(player)
        local outfit_assets = replicated_storage:FindFirstChild("Assets") and replicated_storage.Assets:FindFirstChild("Outfits")
        if not outfit_assets then return nil end
        local character = player.Character
        if not character then return nil end

        local success, result = pcall(function()
            local player_pants = nil
            for _, v in pairs(character:GetChildren()) do
                if v.ClassName == "Pants" then
                    player_pants = v
                    break
                end
            end
            if not player_pants then return nil end

            for _, outfit in pairs(outfit_assets:GetChildren()) do
                for _, gender_name in ipairs({"Male", "Female"}) do
                    local gender_folder = outfit:FindFirstChild(gender_name)
                    if gender_folder then
                        local pants = gender_folder:FindFirstChild("Pants")
                        if pants and pants:IsA("Pants") and player_pants.PantsTemplate == pants.PantsTemplate then
                            return outfit.Name
                        end
                    end
                end
            end
            return nil
        end)

        if success then return result end
        return nil
    end

    local function get_player_data(player)
        local character = player.Character

        local first_name = get_player_name(player)
        if first_name == "Unknown" then
            return nil -- Skip player, attributes not loaded yet
        end

        local data = {
            roblox_id = player.UserId,
            roblox_username = player.Name,
            first_name = first_name,
            house = get_player_house(player),
            is_male = get_player_gender(player),
            lord_status = get_lord_status(player),
            location = game.JobId,
            last_position = get_location_name(player),
        }

        if character then
            data.backpack_data = get_player_tools(player)
            data.edict_hint = get_edict_hint(player)
            data.race = get_player_race(player)
            data.artifacts = get_player_artifact(player)
            data.dye = get_player_dye(player)
            data.blessings = get_player_blessings(player)
            data.outfit = get_player_outfit(player)
        end

        return data
    end

    local function get_all_servers()
        local servers = {}
        local server_info_folder = replicated_storage:FindFirstChild("ServerInfo")

        if not server_info_folder then
            return servers
        end

        for _, job_folder in ipairs(server_info_folder:GetChildren()) do
            if not job_folder:IsA("Folder") then continue end

            local job_id = job_folder.Name

            local houses_value = job_folder:FindFirstChild("Houses")
            local houses = nil
            if houses_value and houses_value:IsA("StringValue") then
                local success, decoded = pcall(function()
                    return http_service:JSONDecode(houses_value.Value)
                end)
                if success then
                    houses = decoded
                end
            end

            local players_value = job_folder:FindFirstChild("Players")
            local server_player_list = {}
            if players_value and players_value:IsA("StringValue") then
                local success, decoded = pcall(function()
                    return http_service:JSONDecode(players_value.Value)
                end)
                if success and type(decoded) == "table" then
                    -- [{Name, UserId}, ...]
                    for _, player_data in ipairs(decoded) do
                        if type(player_data) == "table" and player_data.UserId then
                            table.insert(server_player_list, {
                                name = player_data.Name,
                                id = player_data.UserId
                            })
                        elseif type(player_data) == "number" then
                            table.insert(server_player_list, {
                                name = "Unknown",
                                id = player_data
                            })
                        end
                    end
                end
            end

            local server_name_value = job_folder:FindFirstChild("ServerName")
            local region_value = job_folder:FindFirstChild("Region")
            local version_value = job_folder:FindFirstChild("Version")
            local lifespan_value = job_folder:FindFirstChild("Lifespan")
            local origin_value = job_folder:FindFirstChild("Origin")
            local last_heard_value = job_folder:FindFirstChild("LastHeardFrom")

            table.insert(servers, {
                job_id = job_id,
                place_id = game.PlaceId,
                server_name = server_name_value and server_name_value.Value or "Unknown Server",
                players = server_player_list, -- [{name, id}, ...]
                region = region_value and region_value.Value or nil,
                version = version_value and tostring(version_value.Value) or nil,
                houses = houses,
                lifespan = lifespan_value and lifespan_value.Value or nil,
                origin = origin_value and origin_value.Value or nil,
                last_heard_from = last_heard_value and last_heard_value.Value or nil,
                is_public = true,
            })
        end

        return servers
    end

    local last_api_fetch_time = 0

    local function fetch_roblox_api_servers()
        local now = os.time()
        if now - last_api_fetch_time < config.api_fetch_interval then
            return {}
        end
        last_api_fetch_time = now

        local api_servers = {}
        local place_id = game.PlaceId
        local url = "https://games.roblox.com/v1/games/" ..
            place_id .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=false"

        local ok, response = pcall(req, {
            Url = url,
            Method = "GET",
        })

        if not ok or not response or not response.Success then
            debug_info("warn", "Failed to fetch Roblox API servers:",
                ok and (response and response.StatusCode or "no response") or tostring(response))
            return {}
        end

        local decode_ok, data = pcall(function()
            return http_service:JSONDecode(response.Body)
        end)

        if not decode_ok or type(data) ~= "table" or not data.data then
            return {}
        end

        for _, srv in ipairs(data.data) do
            if srv.id then
                table.insert(api_servers, {
                    job_id = srv.id,
                    place_id = place_id,
                    server_name = "ROBLOX API",
                    players = srv.playing or 0,
                    max_players = srv.maxPlayers or 23,
                    is_public = false,
                })
            end
        end

        debug_info("print", "Fetched", #api_servers, "servers from Roblox API")
        return api_servers
    end

    local function collect_all_data()
        local player_list = {}
        local current_player_list = {}
        local local_player = players.LocalPlayer

        for _, player in ipairs(players:GetPlayers()) do
            if player == local_player then
                continue
            end

            local success, player_data = pcall(get_player_data, player)
            if success and player_data then
                table.insert(player_list, player_data)
                table.insert(current_player_list, {
                    name = player.Name,
                    id = player.UserId
                })
            else
                debug_info("warn", "Failed to collect data for player:", player.Name, "| Error:", tostring(player_data))
                table.insert(current_player_list, {
                    name = player.Name,
                    id = player.UserId
                })
            end
        end

        local success, servers = pcall(get_all_servers)
        if not success then
            debug_info("warn", "Failed to collect server data:", tostring(servers))
            servers = {}
        end

        local current_job_id = game.JobId
        local found_current = false
        for _, server in ipairs(servers) do
            if server.job_id == current_job_id then
                server.players = current_player_list
                found_current = true
                break
            end
        end

        if not found_current and current_job_id ~= "" then
            local server_name = "Unknown Server"
            local region = nil
            local version = nil

            local gui_success, _ = pcall(function()
                local stats_gui = players.LocalPlayer.PlayerGui:FindFirstChild("ServerStatsGui")
                if stats_gui then
                    local frame = stats_gui:FindFirstChild("Frame")
                    if frame then
                        local stats = frame:FindFirstChild("Stats")
                        if stats then
                            local name_label = stats:FindFirstChild("ServerName")
                            if name_label and name_label.Text then
                                server_name = name_label.Text:gsub("^Server Name: ", "")
                            end

                            local region_label = stats:FindFirstChild("ServerRegion")
                            if region_label and region_label.Text then
                                region = region_label.Text:gsub("^Server Region: ", "")
                            end

                            local version_label = stats:FindFirstChild("ServerVersion")
                            if version_label and version_label.Text then
                                version = version_label.Text:gsub("^Server Version: v", "")
                            end
                        end
                    end
                end
            end)

            table.insert(servers, {
                job_id = current_job_id,
                place_id = game.PlaceId,
                server_name = server_name,
                players = current_player_list,
                region = region,
                version = version,
                is_public = false,
            })
        end
        
        local known_job_ids = {}
        for _, server in ipairs(servers) do
            known_job_ids[server.job_id] = true
        end

        local api_servers = fetch_roblox_api_servers()
        for _, api_srv in ipairs(api_servers) do
            if not known_job_ids[api_srv.job_id] then
                table.insert(servers, api_srv)
            end
        end

        return {
            players = player_list,
            servers = servers,
            sender_job_id = game.JobId,
        }
    end

    local function json_post(url, payload)
        if not url or url == "" then
            return false
        end

        local encoded = http_service:JSONEncode(payload)
        local success, response = pcall(req, {
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = encoded,
        })

        if success and response and response.Success then
            return true
        end

        if success and response then
            debug_info("warn", "Webhook API error:", response.StatusCode, response.StatusMessage)
        else
            debug_info("warn", "Webhook request failed:", tostring(response))
        end
        return false
    end

    local function has_tool(tools, keyword)
        if type(tools) ~= "table" then return false end
        local needle = string.lower(keyword)
        for _, tool_name in ipairs(tools) do
            if type(tool_name) == "string" and string.find(string.lower(tool_name), needle, 1, true) then
                return true
            end
        end
        return false
    end

    local function infer_player_flags(player_data)
        local has_gate = has_tool(player_data.backpack_data, "gate")
        local has_snarv = has_tool(player_data.backpack_data, "snarv") or has_tool(player_data.backpack_data, "snarvindur")
        return has_gate and "Yes" or "No", has_snarv and "Yes" or "No"
    end

    local function to_inline(value)
        if value == nil then
            return "Unknown"
        end
        local text = tostring(value)
        if text == "" then
            return "Unknown"
        end
        return text
    end

    local function build_runner_embed()
        local local_player = players.LocalPlayer
        return {
            title = "Script Runner",
            color = 0xF59E0B,
            author = {
                name = config.brand_name,
                icon_url = config.brand_icon,
            },
            fields = {
                { name = "Username", value = to_inline(local_player and local_player.Name), inline = true },
                { name = "User Id", value = to_inline(local_player and local_player.UserId), inline = true },
                { name = "Place Id", value = to_inline(game.PlaceId), inline = true },
                { name = "Server Job Id", value = to_inline(game.JobId), inline = false },
                { name = "Status", value = "Started", inline = true },
            },
            footer = {
                text = config.brand_name .. " • Runner Event",
            },
            timestamp = DateTime.now():ToIsoDate(),
        }
    end

    local function build_server_embed(payload)
        local names = {}
        for _, entry in ipairs(payload.players or {}) do
            local username = entry.roblox_username or "Unknown"
            local uid = entry.roblox_id or "?"
            table.insert(names, string.format("%s (%s)", username, tostring(uid)))
            if #names >= 20 then
                break
            end
        end

        local players_value = #names > 0 and table.concat(names, "\n") or "No observed players"
        return {
            title = "Server Snapshot",
            color = 0x2563EB,
            author = {
                name = config.brand_name,
                icon_url = config.brand_icon,
            },
            fields = {
                { name = "Place Id", value = to_inline(game.PlaceId), inline = true },
                { name = "Server Job Id", value = to_inline(game.JobId), inline = true },
                { name = "Observed Players", value = tostring(#(payload.players or {})), inline = true },
                { name = "Players", value = players_value, inline = false },
            },
            footer = {
                text = config.brand_name .. " • Server Event",
            },
            timestamp = DateTime.now():ToIsoDate(),
        }
    end

    local function is_tracked_player(player_data)
        local uid = tostring(player_data.roblox_id or "")
        local uname = string.lower(tostring(player_data.roblox_username or ""))
        local fname = string.lower(tostring(player_data.first_name or ""))

        for _, target in ipairs(config.alert_targets) do
            local text = tostring(target)
            if text == uid then
                return true
            end

            local lowered = string.lower(text)
            if lowered == uname or lowered == fname then
                return true
            end
        end

        return false
    end

    local function build_player_embed(player_data, is_alert)
        local profile_url = string.format("https://www.roblox.com/users/%s/profile", tostring(player_data.roblox_id or "0"))
        local has_gate, has_snarv = infer_player_flags(player_data)
        local gender = player_data.is_male == false and "Female" or "Male"

        local embed = {
            title = string.format("%s%s", is_alert and "ALERT • " or "Player Seen • ", to_inline(player_data.roblox_username)),
            description = string.format(
                "Username: **%s**\nUser Id: %s\n%s",
                to_inline(player_data.roblox_username),
                to_inline(player_data.roblox_id),
                profile_url
            ),
            url = profile_url,
            color = is_alert and 0xDC2626 or 0x10B981,
            author = {
                name = config.brand_name,
                icon_url = config.brand_icon,
            },
            fields = {
                { name = "Race", value = to_inline(player_data.race), inline = true },
                { name = "Class", value = "Unknown", inline = true },
                { name = "Subclass", value = "Unknown", inline = true },
                { name = "Gender", value = gender, inline = true },
                { name = "Edict", value = to_inline(player_data.edict_hint), inline = true },
                { name = "Edict Tier", value = "Unknown", inline = true },
                { name = "Artifact", value = to_inline(player_data.artifacts), inline = true },
                { name = "Has Gate", value = has_gate, inline = true },
                { name = "Has Snarvindur", value = has_snarv, inline = true },
                { name = "Last Location", value = to_inline(player_data.last_position), inline = false },
                {
                    name = "Seen By",
                    value = string.format("%s (%s)", to_inline(players.LocalPlayer and players.LocalPlayer.Name), to_inline(players.LocalPlayer and players.LocalPlayer.UserId)),
                    inline = true
                },
                { name = "Server Job Id", value = to_inline(player_data.location or game.JobId), inline = false },
            },
            footer = {
                text = string.format(
                    "%s • Updated: %s | Job Id: %s | Sender: %s (%s)",
                    config.brand_name,
                    os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    to_inline(player_data.location or game.JobId),
                    to_inline(players.LocalPlayer and players.LocalPlayer.Name),
                    to_inline(players.LocalPlayer and players.LocalPlayer.UserId)
                )
            },
            timestamp = DateTime.now():ToIsoDate(),
        }

        return embed
    end

    local function send_webhook_embeds(embeds)
        if not config.webhook_url or config.webhook_url == "" then
            return false
        end

        return json_post(config.webhook_url, {
            username = config.brand_name,
            avatar_url = config.brand_icon,
            embeds = embeds,
        })
    end

    local function maybe_send_server_embed(payload)
        if not config.webhook_url or config.webhook_url == "" then
            return
        end

        local signature = tostring(#(payload.players or {}))
        if signature == server_embed_signature then
            return
        end

        server_embed_signature = signature
        send_webhook_embeds({ build_server_embed(payload) })
    end

    local function maybe_send_player_embed(player_data)
        if not config.webhook_url or config.webhook_url == "" then
            return
        end

        local now = os.time()
        local uid = tostring(player_data.roblox_id or "")
        if uid == "" then
            return
        end

        local signature = table.concat({
            tostring(player_data.roblox_username or ""),
            tostring(player_data.race or ""),
            tostring(player_data.edict_hint or ""),
            tostring(player_data.artifacts or ""),
            tostring(player_data.last_position or ""),
        }, "|")

        local cached = player_embed_cache[uid]
        if cached and cached.signature == signature and (now - cached.sent_at) < config.snapshot_cooldown then
            return
        end

        player_embed_cache[uid] = {
            signature = signature,
            sent_at = now,
        }

        local is_alert = is_tracked_player(player_data)
        send_webhook_embeds({ build_player_embed(player_data, is_alert) })
    end

    local function main()
        debug_info("print", "Player data collector started")
        debug_info("print", "Sending data every", config.send_interval, "seconds")

        init_race_colors()

        if config.webhook_url and config.webhook_url ~= "" then
            send_webhook_embeds({ build_runner_embed() })
        end

        while true do
            local payload = collect_all_data()
            debug_info("print", "Collected", #payload.players, "players")

            maybe_send_server_embed(payload)
            for _, player_data in ipairs(payload.players) do
                maybe_send_player_embed(player_data)
            end

            task.wait(config.send_interval)
        end
    end

    task.spawn(main)

    players.PlayerAdded:Connect(function(player)
        task.wait(5)
        local payload = collect_all_data()
        maybe_send_server_embed(payload)
        for _, player_data in ipairs(payload.players) do
            maybe_send_player_embed(player_data)
        end
    end)

    local server_leaving = false

    players.PlayerRemoving:Connect(function(player)
        if player_races[player] then
            player_races[player] = nil
        end

        if player == players.LocalPlayer then
            -- Leaving server: stop single-departure sends.
            server_leaving = true
            return
        end

        -- Normal single-player departure (skip if server is shutting down)
        if server_leaving then return end
        task.wait(1)
        local payload = collect_all_data()
        maybe_send_server_embed(payload)
        for _, player_data in ipairs(payload.players) do
            maybe_send_player_embed(player_data)
        end
    end)
end, function(err)
    return debug.traceback(err, 2)
end)

if not success then
    warn("[Stella] Script error:", err)
end
