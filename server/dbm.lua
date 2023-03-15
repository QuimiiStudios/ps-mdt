-- Get CitizenIDs from Player License
function GetCitizenID(license)
    local result = MySQL.query.await("SELECT citizenid FROM users WHERE license = ?", {license,})
    if result ~= nil then
        return result
    else
        print("Cannot find a CitizenID for License: "..license)
        return nil
    end
end

-- (Start) Opening the MDT and sending data
function AddLog(text)
	--print(text)
    return MySQL.insert.await('INSERT INTO `mdt_logs` (`text`, `time`) VALUES (?,?)', {text, os.time() * 1000})
	-- return exports.oxmysql:execute('INSERT INTO `mdt_logs` (`text`, `time`) VALUES (:text, :time)', { text = text, time = os.time() * 1000 })
end

function GetNameFromId(cid)
	-- Should be a scalar?
	local result = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = @identifier', { ['@identifier'] = cid })
    if result ~= nil then
        --local charinfo = json.decode(result)
        local fullname = result[1].firstname..' '..result[1].lastname
        return fullname
    else
        --print('Player does not exist')
        return nil
    end
	-- return exports.oxmysql:executeSync('SELECT firstname, lastname FROM `users` WHERE id = :id LIMIT 1', { id = cid })
end

-- idk what this is used for either
function GetPersonInformation(cid, jobtype)
	local result = MySQL.query.await('SELECT information, tags, gallery, pfp, fingerprint FROM mdt_data WHERE cid = ? and jobtype = ?', { cid,  jobtype})
	return result[1]
	-- return exports.oxmysql:executeSync('SELECT information, tags, gallery FROM mdt WHERE cid= ? and type = ?', { cid, jobtype })
end

function GetPfpFingerPrintInformation(cid)
	local result = MySQL.query.await('SELECT pfp, fingerprint FROM mdt_data WHERE cid = ?', { cid })
	return result[1]
end

function GetIncidentName(id)
	-- Should also be a scalar
	local result = MySQL.query.await('SELECT title FROM `mdt_incidents` WHERE id = :id LIMIT 1', { id = id })
    return result[1]
	-- return exports.oxmysql:executeSync('SELECT title FROM `mdt_incidents` WHERE id = :id LIMIT 1', { id = id })
end

function GetConvictions(cids)
    print(cids[1])
    result = MySQL.query.await('SELECT * FROM `mdt_convictions` WHERE cid = ?', {cids[1]})
    print(ESX.DumpTable(result))
	return result
	-- return exports.oxmysql:executeSync('SELECT * FROM `mdt_convictions` WHERE `cid` IN(?)', { cids })
end

function GetLicenseInfo(cid)
	local result = MySQL.query.await('SELECT * FROM `licenses` WHERE `cid` = ?', { cid })
	return result
	-- return exports.oxmysql:executeSync('SELECT * FROM `licenses` WHERE `cid`=:cid', { cid = cid })
end

function CreateUser(cid, tableName)
	AddLog("A user was created with the CID: "..cid)
	-- return exports.oxmysql:insert("INSERT INTO `"..dbname.."` (cid) VALUES (:cid)", { cid = cid })
	return MySQL.insert.await("INSERT INTO `"..tableName.."` (cid) VALUES (:cid)", { cid = cid })
end

function GetPlayerVehicles(cid, cb)
    --print(cid)
	return MySQL.query.await('SELECT plate, vehicle FROM owned_vehicles WHERE owner = @cid', { cid = cid })
end

function GetBulletins(JobType)
	return MySQL.query.await('SELECT * FROM `mdt_bulletin` WHERE `jobtype` = ? LIMIT 10', { JobType })
	-- return exports.oxmysql:executeSync('SELECT * FROM `mdt_bulletin` WHERE `type`= ? LIMIT 10', { JobType })
end

function GetPlayerProperties(cid, cb)
	local result =  nil --TODO: Fix this MySQL.query.await('SELECT houselocations.label, houselocations.coords FROM player_houses INNER JOIN houselocations ON player_houses.house = houselocations.name where player_houses.citizenid = ?', {cid})
	return result
end

function GetPlayerDataById(id)
    --print(id)
    local Player = ESX.GetPlayerFromIdentifier(id)
    --print(ESX.DumpTable(Player))
    --print(Player.identifier)
    if Player ~= nil then
		local response = {identifier = Player.identifier, firstName = Player.variables.firstName, lastName = Player.variables.lastName, gender = Player.variables.sex, dateofbirth =  Player.variables.dateofbirth, job = Player.job}
        return response
    else
        return MySQL.single.await('SELECT identifier, firstname, lastname, dateofbirth, job, job_grade FROM users WHERE identifier = ? LIMIT 1', { id })
    end

	-- return exports.oxmysql:executeSync('SELECT citizenid, charinfo, job FROM users WHERE citizenid = ? LIMIT 1', { id })
end

-- Probs also best not to use
--[[ function GetImpoundStatus(vehicleid, cb)
	cb( #(exports.oxmysql:executeSync('SELECT id FROM `impound` WHERE `vehicleid`=:vehicleid', {['vehicleid'] = vehicleid })) > 0 )
end ]]

function GetBoloStatus(plate)
	local result = MySQL.scalar.await('SELECT id FROM `mdt_bolos` WHERE LOWER(`plate`)=:plate', { plate = string.lower(plate)})
	return result
	-- return exports.oxmysql:scalarSync('SELECT id FROM `mdt_bolos` WHERE LOWER(`plate`)=:plate', { plate = string.lower(plate)})
end

function GetOwnerName(cid)
	local result = MySQL.scalar.await('SELECT charinfo FROM `players` WHERE LOWER(`citizenid`) = ? LIMIT 1', {cid})
	return result
	-- return exports.oxmysql:scalarSync('SELECT charinfo FROM `players` WHERE id=:cid LIMIT 1', { cid = cid})
end

function GetVehicleInformation(plate, cb)
    local result = MySQL.query.await('SELECT id, information FROM `mdt_vehicleinfo` WHERE plate=:plate', { plate = plate})
	cb(result)
end

function GetPlayerApartment(cid, cb)
    local result =  MySQL.query.await('SELECT name, type, label FROM apartments where citizenid = ?', {cid})
    return result
end

function GetPlayerLicenses(identifier)
    local response = false
    local Player = ESX.GetPlayerFromIdentifier(identifier)
        local result = MySQL.query.await('SELECT * FROM `user_licenses` WHERE `owner` = @identifier', {['@identifier'] = identifier})
        if result ~= nil then
            local metadata = {}--json.decode(result)
            for k, v in pairs(result) do
                if v.type == 'boat' then
                    metadata['boat'] = true
                elseif v.type == 'drive' then
                    metadata['driver'] = true
                elseif v.type == 'weapon' then
                    metadata['weapon'] = true
                --[[elseif v.type == 'license_cardealer' then
                    metadata['Car Dealer'] = true
                elseif v.type == 'license_shop_general' then
                    metadata['General Shop'] = true
                elseif v.type == 'license_shop_ammunation' then
                    metadata['Weapon Shop'] = true]]
                elseif v.type == 'hunting' then
                    metadata['hunting'] = true
                elseif v.type == 'pilot' then
                    metadata['pilot'] = true
                end
            end
            return metadata
        else
            return {
                ['driver'] = false,
                ['business'] = false,
                ['weapon'] = false,
                ['pilot'] = false
            }
         end
end

function ManageLicense(identifier, type, status)
    local Player = ESX.GetPlayerFromIdentifier(identifier)
    local licenseStatus = nil
    if status == "give" then licenseStatus = true elseif status == "revoke" then licenseStatus = false end
    if Player ~= nil then
        local licences = Player.metadata["licences"]
        local newLicenses = {}
        for k, v in pairs(licences) do
            local status = v
            if k == type then
                status = licenseStatus
            end
            newLicenses[k] = status
        end
        Player.Functions.SetMetaData("licences", newLicenses)
    else
        local licenseType = '$.licences.'..type
        local result = MySQL.query.await('UPDATE `players` SET `metadata` = JSON_REPLACE(`metadata`, ?, ?) WHERE `citizenid` = ?', {licenseType, licenseStatus, identifier}) --seems to not work on older MYSQL versions, think about alternative
    end
end

function ManageLicenses(identifier, incomingLicenses)
    local Player = ESX.GetPlayerFromIdentifier(identifier)
    if Player ~= nil then
        print(ESX.DumpTable(incomingLicenses))
        --Player.Functions.SetMetaData("licences", incomingLicenses)

    else
        local result = MySQL.scalar.await('SELECT * FROM `user_licenses` WHERE `owner` = @identifier', {['@identifier'] = identifier})
        print(ESX.DumpTable(result))
        result = json.decode(result)

        result.licences = result.licences or {
            ['driver'] = true,
            ['business'] = false,
            ['weapon'] = false,
            ['pilot'] = false
        }

        for k, _ in pairs(incomingLicenses) do
            result.licences[k] = incomingLicenses[k]
        end
        MySQL.query.await('UPDATE `players` SET `metadata` = @metadata WHERE citizenid = @citizenid', {['@metadata'] = json.encode(result), ['@citizenid'] = identifier})
    end
end
