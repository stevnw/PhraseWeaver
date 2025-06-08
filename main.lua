local currentScreen = nil
local screenWidth = 800
local screenHeight = 600

local font_h1 = love.graphics.newFont(36)
local font_h2 = love.graphics.newFont(24)
local font_button = love.graphics.newFont(16)
local font_normal = love.graphics.newFont(14)

local logoImage = nil

-- Score-based colors
local SCORE_COLOR_GOOD = {0.6, 0.9, 0.6, 1.0} -- Green
local SCORE_COLOR_OKAY = {0.98, 0.8, 0.5, 1.0} -- Amber
local SCORE_COLOR_BAD = {1.0, 0.6, 0.6, 1.0}  -- Red
local SCORE_COLOR_DEFAULT = {0.6, 0.7, 1.0, 1.0} -- Original

string.trim = function(s)
    s = s:gsub("^%s*(.-)%s*$", "%1")
    s = s:gsub("%s+", " ")
    return s
end

function createButton(x, y, width, height, text, callback, initialColor)
    local btnColor = initialColor or SCORE_COLOR_DEFAULT
    return {
        x = x, y = y, width = width, height = height,
        text = text,
        callback = callback,
        isHovered = false,
        enabled = true,
        color = btnColor,
        draw = function(self)
            local currentColor = self.color
            if self.isHovered and self.enabled then
                if currentColor[1] == SCORE_COLOR_GOOD[1] and currentColor[2] == SCORE_COLOR_GOOD[2] then
                     love.graphics.setColor(0.7, 1.0, 0.7, 1.0) -- Green
                elseif currentColor[1] == SCORE_COLOR_OKAY[1] and currentColor[2] == SCORE_COLOR_OKAY[2] then
                    love.graphics.setColor(1.0, 0.9, 0.6, 1.0) -- Amber
                elseif currentColor[1] == SCORE_COLOR_BAD[1] and currentColor[2] == SCORE_COLOR_BAD[2] then
                    love.graphics.setColor(1.0, 0.7, 0.7, 1.0) -- Red
                else -- Default or unknown color?
                    love.graphics.setColor(0.8, 0.9, 1.0, 1.0) -- Original
                end
            elseif not self.enabled then
                love.graphics.setColor(0.4, 0.4, 0.6, 0.7) -- Disabled appearance
            else
                love.graphics.setColor(currentColor)
            end

            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            love.graphics.setColor(0.1, 0.1, 0.4, 1.0)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setFont(font_button)
            love.graphics.printf(self.text, self.x, self.y + (self.height - font_button:getHeight()) / 2, self.width, "center")
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
        
        end
    end
    if #sentences == 0 then
    end
    return sentences
end

function loadLessonsFromTxt(filename)
    local fileContent = love.filesystem.read(filename)
    if not fileContent then
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

        end
    end
    return lessons_data
end

local userSavePathBase = nil

function ensureUserDirectory()
    local userDir = "user"
    local cmd = string.format("mkdir -p %q", userDir)
    os.execute(cmd)
end

function loadUserScores()
    ensureUserDirectory()
    local scores = {}
    local scoreFile = "user/scores.txt"
    
    local file = io.open(scoreFile, "r")
    if file then
        for line in file:lines() do
            local lessonName, score = line:match("([^:]+):(%d+)")
            if lessonName and score then
                scores[lessonName:trim()] = tonumber(score)
            end
        end
        file:close()
    else

    end
    return scores
end

function saveUserScore(lessonName, score)
    ensureUserDirectory()
    local currentScores = loadUserScores()
    local scoreFile = "user/scores.txt"

    if not currentScores[lessonName] or score > currentScores[lessonName] then
        currentScores[lessonName] = score
    end

    local file = io.open(scoreFile, "w")
    if file then
        for name, s in pairs(currentScores) do
            file:write(name..":"..s.."\n")
        end
        file:close()
    else

    end
end


local Screen = {}
Screen.__index = Screen

function Screen:new()
    local o = {}
    setmetatable(o, self)
    o.elements = {}
    o.centerOffsetX = 0
    o.centerOffsetY = 0
    return o
end

function Screen:load()

end

function Screen:update(dt)

end

function Screen:draw()
    for _, element in pairs(self.elements) do
        if element.draw then
            element.draw(element)
        end
    end
end

function Screen:mousepressed(x, y, button)
    for _, element in pairs(self.elements) do
        if element.hitTest and element.callback then
            if element.hitTest(element, x, y) then
                element.callback(element)
                return
            end
        end
    end
end

function Screen:mousereleased(x, y, button)

end

function Screen:keypressed(key)

end

function Screen:resize(w, h)
    screenWidth = w
    screenHeight = h
    self.centerOffsetX = (screenWidth - 800) / 2
    self.centerOffsetY = (screenHeight - 600) / 2
end

local TranslationGame = Screen:new()
TranslationGame.__index = TranslationGame

function TranslationGame:new(csv_filename, start_screen_ref, lesson_name)
    local o = Screen:new()
    setmetatable(o, self)
    o.start_screen_ref = start_screen_ref
    o.lesson_name = lesson_name
    o.sentences = {}
    o.all_english_words = {}
    o.shuffled_indices = {}
    o.sentences_completed_count = 0
    o.correct_answers_count = 0
    o.current_sentence = nil
    o.selected_words = {}
    o.csv_filename = csv_filename

    o.translationWordButtons = {}
    o.wordBankButtons = {}
    o.returningToStart = false
    o.isCompletionPopupVisible = false
    o.completionPopupElements = {}
    o.popupContinueButton = nil

    o.isStatusBannerVisible = false
    o.statusBannerMessage = ""
    o.statusBannerColor = {0,0,0,1}
    o.nextButton = nil

    o:load()
    return o
end

function TranslationGame:load()
    self.centerOffsetX = (screenWidth - 800) / 2
    self.centerOffsetY = (screenHeight - 600) / 2

    self.elements = {}

    self:loadData(self.csv_filename)
    local sentenceCount = #self.sentences
    if sentenceCount > 0 then
        self:loadSentence()
    else
        self.returningToStart = true
        self.returnToStartTimer = 2
    end

    local homeButton = createButton(
        20,
        20,
        100,
        40,
        "Home",
        function() self:onGoHome() end
    )
    table.insert(self.elements, homeButton)
end

function TranslationGame:loadData(filename)
    self.sentences = parseCSV(filename)
    self.shuffled_indices = {}
    self.all_english_words = {}

    local uniqueWords = {}
    for i = 1, #self.sentences do
        table.insert(self.shuffled_indices, i)
        local englishSentence = self.sentences[i].english
        for word in englishSentence:gmatch("%S+") do
            uniqueWords[word:trim()] = true
        end
    end

    for word, _ in pairs(uniqueWords) do
        table.insert(self.all_english_words, word)
    end

    for i = #self.shuffled_indices, 2, -1 do
        local j = math.random(i)
        self.shuffled_indices[i], self.shuffled_indices[j] = self.shuffled_indices[j], self.shuffled_indices[i]
    end
end

function TranslationGame:loadSentence()
    self.isStatusBannerVisible = false

    if self.sentences_completed_count >= #self.sentences then
        self.completionPopupElements = {}
        self:showCompletionPopup()
        return
    end

    local current_sentence_index = self.shuffled_indices[self.sentences_completed_count + 1]
    self.current_sentence = self.sentences[current_sentence_index]


    self.selected_words = {}
    self.translationWordButtons = {}
    self.wordBankButtons = {}

    local keptElements = {}
    for _, element in ipairs(self.elements) do
        if element.text == "Home" then
            table.insert(keptElements, element)
        end
    end
    self.elements = keptElements


    local langLabelX = self.centerOffsetX + 30
    local langLabelY = self.centerOffsetY + 30
    local langLabelWidth = 800 - 60
    local langLabelHeight = font_h2:getHeight()

    local function drawLanguageLabel()
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
        love.graphics.setFont(font_h2)
        love.graphics.printf(self.current_sentence.german, langLabelX, langLabelY, langLabelWidth, "center")
    end
    table.insert(self.elements, {draw = drawLanguageLabel})

    local transAreaX = self.centerOffsetX + 50
    local transAreaY = self.centerOffsetY + 30 + font_h2:getHeight() + 30
    local transAreaWidth = 800 - 100
    local transAreaHeight = 120
    local function drawTranslationArea()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", transAreaX, transAreaY, transAreaWidth, transAreaHeight)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", transAreaX, transAreaY, transAreaWidth, transAreaHeight)
    end
    table.insert(self.elements, {draw = drawTranslationArea})

    local wordBankX = self.centerOffsetX + 20
    local wordBankY = self.centerOffsetY + 30 + font_h2:getHeight() + 30 + 120 + 30
    local wordBankWidth = 800 - 40
    local wordBankHeight = 200

    local englishWords = {}
    for word in self.current_sentence.english:gmatch("%S+") do
        table.insert(englishWords, word:trim())
    end

    local combinedWordList = {}
    local correctWordsMap = {}
    for _, word in ipairs(englishWords) do
        table.insert(combinedWordList, word)
        correctWordsMap[word] = true
    end

    local numDistractors = math.min(5, #self.all_english_words - #englishWords)

    local potentialDistractors = {}
    for _, word in ipairs(self.all_english_words) do
        if not correctWordsMap[word] then
            table.insert(potentialDistractors, word)
        end
    end

    for i = #potentialDistractors, 2, -1 do
        local j = math.random(i)
        potentialDistractors[i], potentialDistractors[j] = potentialDistractors[j], potentialDistractors[i]
    end

    for i = 1, numDistractors do
        if potentialDistractors[i] then
            table.insert(combinedWordList, potentialDistractors[i])
        end
    end

    for i = #combinedWordList, 2, -1 do
        local j = math.random(i)
        combinedWordList[i], combinedWordList[j] = combinedWordList[j], combinedWordList[i]
    end

    self.wordBankButtons = {}
    local currentWordX = wordBankX
    local currentWordY = wordBankY
    local maxWordBankWidth = wordBankWidth - 16
    local buttonWidth = 120
    local buttonHeight = 60
    local horizontalPadding = 8
    local verticalPadding = 8

    for _, word in ipairs(combinedWordList) do
        local btn = createButton(
            currentWordX,
            currentWordY,
            buttonWidth,
            buttonHeight,
            word,
            function(clicked_button_element) self:onWordSelect(word, clicked_button_element) end
        )
        btn.originalX = currentWordX
        btn.originalY = currentWordY
        btn.originalParent = "word_bank"
        btn.enabled = true
        table.insert(self.elements, btn)
        table.insert(self.wordBankButtons, btn)

        currentWordX = currentWordX + buttonWidth + horizontalPadding
        if currentWordX + buttonWidth > wordBankX + maxWordBankWidth then
            currentWordX = wordBankX
            currentWordY = currentWordY + buttonHeight + verticalPadding
        end
    end

    local checkBtn = createButton(
        self.centerOffsetX + (800 - 150) / 2,
        self.centerOffsetY + 600 - 20 - 50,
        150, 50, "CHECK", function() self:onCheck() end
    )
    checkBtn.enabled = true
    self.checkButton = checkBtn
    table.insert(self.elements, checkBtn)
end

function TranslationGame:onWordSelect(word, btn)
    if not btn.enabled then return end

    table.insert(self.selected_words, word)

    btn.enabled = false

    local newBtn = createButton(0, 0, 120, 50, word, function() self:onRemoveWord(word) end)
    newBtn.isTranslationWord = true
    newBtn.word = word
    newBtn.enabled = true
    table.insert(self.translationWordButtons, newBtn)

    self:repositionTranslationWords()
end

function TranslationGame:onRemoveWord(word)
    for i, w in ipairs(self.selected_words) do
        if w == word then
            table.remove(self.selected_words, i)
            break
        end
    end

    for i, btn in ipairs(self.translationWordButtons) do
        if btn.word == word then
            table.remove(self.translationWordButtons, i)
            break
        end
    end

    for _, btn in ipairs(self.wordBankButtons) do
        if btn.text == word then
            btn.enabled = true
            break
        end
    end

    self:repositionTranslationWords()
end

function TranslationGame:repositionTranslationWords()
    local transAreaX = self.centerOffsetX + 50
    local transAreaY = self.centerOffsetY + 30 + font_h2:getHeight() + 30
    local horizontalPadding = 8
    local verticalPadding = 8
    local buttonWidth = 120
    local buttonHeight = 50

    local currentX = transAreaX + horizontalPadding
    local currentY = transAreaY + verticalPadding

    for _, btn in ipairs(self.translationWordButtons) do
        btn.x = currentX
        btn.y = currentY
        btn.width = buttonWidth
        btn.height = buttonHeight
        currentX = currentX + buttonWidth + horizontalPadding
        
        if currentX + buttonWidth > transAreaX + (800 - 100) - horizontalPadding then
            currentX = transAreaX + horizontalPadding
            currentY = currentY + buttonHeight + verticalPadding
        end
    end
end

function TranslationGame:onCheck()
    if not self.current_sentence then return end

    self:playGermanAudio()

    local user_translation = table.concat(self.selected_words, " "):trim()
    local correct_translation = self.current_sentence.english:trim()

    if user_translation == correct_translation then
        self.statusBannerMessage = "CORRECT! Great job!"
        self.statusBannerColor = {0.6, 0.9, 0.6, 0.9}
        self.correct_answers_count = self.correct_answers_count + 1
    else
        self.statusBannerMessage = "INCORRECT. Correct: " .. correct_translation
        self.statusBannerColor = {1.0, 0.6, 0.6, 0.9}
    end

    self.isStatusBannerVisible = true

    for _, btn in ipairs(self.wordBankButtons) do
        btn.enabled = false
    end
    for _, btn in ipairs(self.translationWordButtons) do
        btn.enabled = false
    end

    if self.checkButton then self.checkButton.enabled = false end
end

function TranslationGame:onNext()
    self.sentences_completed_count = self.sentences_completed_count + 1
    self:loadSentence()
end

function TranslationGame:onGoHome()
    love.audio.stop()
    
    local total = #self.sentences
    local correct = self.correct_answers_count
    local score = 0
    if total > 0 then
        score = math.floor((correct / total) * 100)
    end
    saveUserScore(self.lesson_name, score)

    currentScreen = self.start_screen_ref
    currentScreen:load()
end

function TranslationGame:playGermanAudio()
    if not self.current_sentence or not self.current_sentence.audio then
        return
    end

    local audio_file = self.current_sentence.audio
    if love.filesystem.getInfo(audio_file, "file") then
        local source = love.audio.newSource(audio_file, "static")
        source:play()
    else

    end
end

function TranslationGame:showCompletionPopup()
    self.isCompletionPopupVisible = true
    self.completionPopupElements = {}

    local total = #self.sentences
    local correct = self.correct_answers_count
    local percentage = (correct / total) * 100

    saveUserScore(self.lesson_name, math.floor(percentage))

    local feedbackText = ""
    local feedbackColor = {0.2, 0.2, 0.2, 1.0}

    if percentage >= 75 then
        feedbackText = "Well done!"
        feedbackColor = SCORE_COLOR_GOOD
    elseif percentage >= 50 then
        feedbackText = "Good attempt!"
        feedbackColor = SCORE_COLOR_OKAY
    else
        feedbackText = "Try again!"
        feedbackColor = SCORE_COLOR_BAD
    end

    local scoreText = string.format("You scored %d/%d (%.0f%%)", correct, total, percentage)

    local popupWidth = 400
    local popupHeight = 200
    local popupX = screenWidth / 2 - popupWidth / 2
    local popupY = screenHeight / 2 - popupHeight / 2

    table.insert(self.completionPopupElements, {
        draw = function()
            love.graphics.setColor(0.9, 0.95, 1.0, 0.95)
            love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight)
            love.graphics.setColor(0.1, 0.1, 0.4, 1.0)
            love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight)
        end
    })

    table.insert(self.completionPopupElements, {
        draw = function()
            love.graphics.setColor(feedbackColor)
            love.graphics.setFont(font_h2)
            love.graphics.printf(feedbackText, popupX, popupY + 30, popupWidth, "center")
        end
    })

    table.insert(self.completionPopupElements, {
        draw = function()
            love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
            love.graphics.setFont(font_normal)
            love.graphics.printf(scoreText, popupX, popupY + 30 + font_h2:getHeight() + 15, popupWidth, "center")
        end
    })

    local continueButton = createButton(
        popupX + (popupWidth - 150) / 2,
        popupY + popupHeight - 20 - 50,
        150, 50, "Continue",
        function() self:onPopupContinue() end
    )
    self.popupContinueButton = continueButton
    table.insert(self.completionPopupElements, continueButton)
end

function TranslationGame:onPopupContinue()
    self.isCompletionPopupVisible = false
    currentScreen = self.start_screen_ref
    currentScreen:load()
end

function TranslationGame:mousepressed(x, y, button)
    if self.isCompletionPopupVisible then
        if self.popupContinueButton and self.popupContinueButton.hitTest and self.popupContinueButton.callback then
            if self.popupContinueButton.hitTest(self.popupContinueButton, x, y) then
                self.popupContinueButton.callback(self.popupContinueButton)
                return
            end
        end
    elseif self.isStatusBannerVisible then
        if self.nextButton and self.nextButton.hitTest and self.nextButton.callback then
            if self.nextButton.hitTest(self.nextButton, x, y) then
                self.nextButton.callback(self.nextButton)
                return
            end
        end
    else
        if not self.returningToStart then
            for _, element in ipairs(self.translationWordButtons) do
                if element.hitTest and element.callback and element.enabled then
                    if element.hitTest(element, x, y) then
                        element.callback(element)
                        return
                    end
                end
            end

            for _, element in ipairs(self.elements) do
                if element.hitTest and element.callback and element.enabled then
                    if element.hitTest(element, x, y) then
                        element.callback(element)
                        return
                    end
                end
            end
        end
    end
end

function TranslationGame:update(dt)
    if not self.isCompletionPopupVisible then
        local mx, my = love.mouse.getPosition()
        for _, element in ipairs(self.elements) do
            if element.hitTest and element.enabled then
                element.isHovered = element.hitTest(element, mx, my)
            end
        end

        for _, element in ipairs(self.translationWordButtons) do
            if element.hitTest and element.enabled then
                element.isHovered = element.hitTest(element, mx, my)
            end
        end

        if self.isStatusBannerVisible and self.nextButton then
            self.nextButton.isHovered = self.nextButton.hitTest(self.nextButton, mx, my)
        end

    else
        local mx, my = love.mouse.getPosition()
        if self.popupContinueButton then
            self.popupContinueButton.isHovered = self.popupContinueButton.hitTest(self.popupContinueButton, mx, my)
        end
    end

    if self.returningToStart then
        self.returnToStartTimer = self.returnToStartTimer - dt
        if self.returnToStartTimer <= 0 then
            self.returningToStart = false
            currentScreen = self.start_screen_ref
            currentScreen:load()
        end
    end
end

function TranslationGame:draw()
    for _, element in ipairs(self.elements) do
        if element.draw then
            element.draw(element)
        end
    end

    for _, element in ipairs(self.translationWordButtons) do
        if element.draw then
            element.draw(element)
        end
    end

    if self.isStatusBannerVisible then
        local bannerHeight = 80
        local bannerY = screenHeight - bannerHeight
        local bannerX = 0
        local bannerWidth = screenWidth

        love.graphics.setColor(self.statusBannerColor[1], self.statusBannerColor[2], self.statusBannerColor[3], 0.9)
        love.graphics.rectangle("fill", bannerX, bannerY, bannerWidth, bannerHeight)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(font_h2)
        love.graphics.printf(self.statusBannerMessage, bannerX, bannerY + (bannerHeight - font_h2:getHeight()) / 2, bannerWidth - 180, "center")

        local nextBtnX = bannerX + bannerWidth - 150 - 20
        local nextBtnY = bannerY + (bannerHeight - 50) / 2
        self.nextButton = createButton(nextBtnX, nextBtnY, 150, 50, "NEXT", function() self:onNext() end)
        self.nextButton.enabled = true
        self.nextButton:draw()
    end

    if self.isCompletionPopupVisible then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

        for _, element in ipairs(self.completionPopupElements) do
            if element.draw then
                element.draw(element)
            end
        end
    end
end


local StartScreen = Screen:new()
StartScreen.__index = StartScreen

function StartScreen:new()
    local o = Screen:new()
    setmetatable(o, self)
    o.lessons = {}
    o.userScores = {}
    o:load()
    return o
end

function StartScreen:load()
    self.centerOffsetX = (screenWidth - 400) / 2
    self.centerOffsetY = (screenHeight - 500) / 2

    self.elements = {}

    if not logoImage then
        if love.filesystem.getInfo("logo.png", "file") then
            logoImage = love.graphics.newImage("logo.png")
        else
        end
    end

    local logoWidth = 522
    local logoHeight = 72
    local logoX = self.centerOffsetX + (400 - logoWidth) / 2
    local logoY = self.centerOffsetY + 40

    local function drawLogo()
        if logoImage then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(logoImage, logoX, logoY)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
            love.graphics.setFont(font_h1)
            love.graphics.printf("PhraseWeaver", self.centerOffsetX, self.centerOffsetY + 40, 400, "center") -- What a shit name hahaha
        end
    end
    table.insert(self.elements, {draw = drawLogo})

    local quitButton = createButton(
        20,
        20,
        100,
        40,
        "Quit",
        function() love.event.quit() end
    )
    table.insert(self.elements, quitButton)

    self.userScores = loadUserScores()
    self:loadLessons("lessons.txt")
end

function StartScreen:loadLessons(filename)
    self.lessons = loadLessonsFromTxt(filename)
    
    local actualLogoHeight = 72
    local yOffset = self.centerOffsetY + 40 + actualLogoHeight + 20

    for _, lesson in ipairs(self.lessons) do
        local lessonScore = self.userScores[lesson.name]
        local buttonColor = SCORE_COLOR_DEFAULT

        if lessonScore then
            if lessonScore >= 75 then
                buttonColor = SCORE_COLOR_GOOD
            elseif lessonScore >= 50 then
                buttonColor = SCORE_COLOR_OKAY
            else
                buttonColor = SCORE_COLOR_BAD
            end
        end

        local button = createButton(
            self.centerOffsetX + 20,
            yOffset,
            360,
            60,
            lesson.name,
            function() self:onLessonSelect(lesson.path, lesson.name) end,
            buttonColor
        )
        table.insert(self.elements, button)
        yOffset = yOffset + 60 + 10
    end
end

function StartScreen:onLessonSelect(csvPath, lessonName)
    love.audio.stop()
    currentScreen = TranslationGame:new(csvPath, self, lessonName)
end

function love.load()
    love.window.setMode(1920, 1080, { fullscreen = true, resizable = true })
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    userSavePathBase = love.filesystem.getSaveDirectory() .. "/"
    
    ensureUserDirectory()
    currentScreen = StartScreen:new()
end

function love.update(dt)
    if currentScreen and currentScreen.update then
        currentScreen:update(dt)
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.94, 0.96, 0.98, 1)

    if currentScreen and currentScreen.draw then
        currentScreen:draw()
    end
end

function love.mousepressed(x, y, button)
    if currentScreen and currentScreen.mousepressed then
        currentScreen:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if currentScreen and currentScreen.mousereleased then
        currentScreen:mousereleased(x, y, button)
    end
end

function love.keypressed(key)
    if currentScreen and currentScreen.keypressed then
        currentScreen:keypressed(key)
    end
end

function love.resize(w, h)
    screenWidth = w
    screenHeight = h
    if currentScreen and currentScreen.resize then
        currentScreen:resize(w, h)
    end
end
