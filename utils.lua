-- Utility functions - i.e. User scores, preferences, etc.

string.trim = function(s)
    s = s:gsub("^%s*(.-)%s*$", "%1")
    s = s:gsub("%s+", " ")
    return s
end

function createButton(x, y, width, height, text, callback, initialColor, imagePath)
    local btnColor = initialColor or SCORE_COLOR_DEFAULT
    local image = nil
    if imagePath then
        local info = love.filesystem.getInfo(imagePath, "file")
        if info then
            image = love.graphics.newImage(imagePath)
        end
    end
    
    return {
        x = x, y = y, width = width, height = height,
        text = text,
        callback = callback,
        isHovered = false,
        enabled = true,
        color = btnColor,
        image = image,
        draw = function(self)
            local currentColor = self.color
            if self.isHovered and self.enabled then
                if currentColor[1] == SCORE_COLOR_GOOD[1] and currentColor[2] == SCORE_COLOR_GOOD[2] then
                     love.graphics.setColor(0.7, 1.0, 0.7, 1.0)
                elseif currentColor[1] == SCORE_COLOR_OKAY[1] and currentColor[2] == SCORE_COLOR_OKAY[2] then
                    love.graphics.setColor(1.0, 0.9, 0.6, 1.0)
                elseif currentColor[1] == SCORE_COLOR_BAD[1] and currentColor[2] == SCORE_COLOR_BAD[2] then
                    love.graphics.setColor(1.0, 0.7, 0.7, 1.0)
                else
                    love.graphics.setColor(0.8, 0.9, 1.0, 1.0)
                end
            elseif not self.enabled then
                love.graphics.setColor(0.4, 0.4, 0.6, 0.7)
            else
                love.graphics.setColor(currentColor)
            end

            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(0.1, 0.1, 0.4, 1.0)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

            if self.image then
                local scale = math.min(self.width / self.image:getWidth(), self.height / self.image:getHeight()) * 0.7
                local imgWidth = self.image:getWidth() * scale
                local imgHeight = self.image:getHeight() * scale
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(self.image, 
                    self.x + (self.width - imgWidth)/2, 
                    self.y + (self.height - imgHeight)/2,
                    0, scale, scale)
            elseif self.text then
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.setFont(font_button)
                love.graphics.printf(self.text, self.x, self.y + (self.height - font_button:getHeight()) / 2, self.width, "center")
            end
        end,
        hitTest = function(self, mx, my)
            return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
        end
    }
end

function parseCSV(filename)
    local sentences = {}
    local fileContent = love.filesystem.read(filename)
    if not fileContent then
        print("Error: CSV file not found or could not be read: '" .. filename .. "'")
        return {}
    end

    local line_count = 0
    for line in fileContent:gmatch("(.-)\n") do
        line_count = line_count + 1
        local parts = {}
        local temp_line = line .. ","
        for part in temp_line:gmatch("([^,]*),") do
            table.insert(parts, part)
        end

        if #parts >= 4 then
            table.insert(sentences, {
                german = parts[1]:trim(),
                english = parts[2]:trim(),
                literal = parts[3]:trim(),
                audio = parts[4]:trim()
            })
        else
            print("Warning: Skipping malformed line in '" .. filename .. "' at line " .. line_count .. ": '" .. line .. "'")
        end
    end
    if #sentences == 0 then
        print("Warning: No sentences found in CSV file: '" .. filename .. "'")
    end
    return sentences
end

function loadLessonsFromTxt(filename)
    local fileContent = love.filesystem.read(filename)
    if not fileContent then
        print("Error: Lesson list file not found or could not be read: '" .. filename .. "'")
        return {}
    end

    local lessons_data = {}
    local line_count = 0
    for line in fileContent:gmatch("(.-)\n") do
        line_count = line_count + 1
        local key, value = line:match("([^=]+)=(.*)")
        if key and value then
            table.insert(lessons_data, {name = key:trim(), path = value:trim()})
        else
            print("Warning: Skipping malformed line in '" .. filename .. "' at line " .. line_count .. ": '" .. line .. "'. Expected format 'Name=Path'.")
        end
    end
    if #lessons_data == 0 then
        print("Warning: No lessons found in lesson list file: '" .. filename .. "'")
    end
    return lessons_data
end

function loadLanguagesFromTxt(filename)
    local fileContent = love.filesystem.read(filename)
    if not fileContent then
        print("Error: Language list file not found or could not be read: '" .. filename .. "'")
        return {}
    end

    local languages_data = {}
    local line_count = 0
    for line in fileContent:gmatch("(.-)\n") do
        line_count = line_count + 1
        local key, value = line:match("([^=]+)=(.*)")
        if key and value then
            table.insert(languages_data, {name = key:trim(), path = value:trim()})
        else
            print("Warning: Skipping malformed line in '" .. filename .. "' at line " .. line_count .. ": '" .. line .. "'. Expected format 'Name=Path'.")
        end
    end
    if #languages_data == 0 then
        print("Warning: No languages found in language list file: '" .. filename .. "'")
    end
    return languages_data
end

function ensureUserDirectory()
    local info = love.filesystem.getInfo(customUserDataPath, "directory")
    if not info then
        print("Warning: User data directory does not exist: " .. customUserDataPath)
    end
end


function saveUserScore(lessonName, score)

    local currentScores = loadUserScores()
    
    local today = os.date("%Y-%m-%d")
    local yesterday = os.date("%Y-%m-%d", os.time() - 86400) -- Note for future me: 86400 seconds in a day...
    
    local streak = 1
    if currentScores[lessonName] then
        if currentScores[lessonName].date == yesterday then
            streak = (currentScores[lessonName].streak or 1) + 1
        elseif currentScores[lessonName].date ~= today then
            streak = 1 -- Reset streak if not consecutive - I assume this will work I haven't tested it...
        else
            streak = currentScores[lessonName].streak or 1
        end
    end
    
    currentScores[lessonName] = {
        score = score,
        date = today,
        streak = streak
    }
    
    local fileContent = ""
    for name, data in pairs(currentScores) do
        fileContent = fileContent .. string.format("%s:%d:%s:%d\n", name, data.score, data.date, data.streak or 1)
    end
    
    love.filesystem.write("scores.txt", fileContent)
end

function loadUserScores()
    local scores = {}
    if love.filesystem.getInfo("scores.txt") then
        for line in love.filesystem.lines("scores.txt") do
            local name, score, date, streak = line:match("([^:]+):(%d+):([^:]+):(%d+)")
            if name then
                scores[name] = {
                    score = tonumber(score),
                    date = date or "No date",
                    streak = tonumber(streak) or 1
                }
            end
        end
    end
    return scores
end

function getCurrentStreak()
    local scores = loadUserScores()
    local maxStreak = 0
    for _, data in pairs(scores) do
        if data.streak and data.streak > maxStreak then
            maxStreak = data.streak
        end
    end
    return maxStreak
end

function loadUserPreferences()
    local prefs = {
        showStreak = false
    }
    if love.filesystem.getInfo("user_prefs.txt") then
        for line in love.filesystem.lines("user_prefs.txt") do
            local key, value = line:match("([^=]+)=(.*)")
            if key and value then
                prefs[key] = value == "true"
            end
        end
    end
    return prefs
end

function saveUserPreferences(prefs)
    local fileContent = ""
    for key, value in pairs(prefs) do
        fileContent = fileContent .. string.format("%s=%s\n", key, tostring(value))
    end
    love.filesystem.write("user_prefs.txt", fileContent)
end
