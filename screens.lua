-- Screens - i.e. Main menu, settings, game screen, etc.

Screen = {}
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
    if type(self.elements) == "table" then
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


TranslationGame = {}
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
        print("No sentences found in lesson: '" .. self.csv_filename .. "'. Returning to Start Screen.")
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
    
    local mainPhraseHeight = font_foreign_main:getHeight()
    local readingHeight = font_foreign_reading:getHeight()

    local function drawLanguageLabel()
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
        
        love.graphics.setFont(font_foreign_main)
        love.graphics.printf(self.current_sentence.german, langLabelX, langLabelY, langLabelWidth, "center")

        love.graphics.setFont(font_foreign_reading)
        love.graphics.printf(self.current_sentence.literal, langLabelX, langLabelY + mainPhraseHeight + 10, langLabelWidth, "center")
    end
    table.insert(self.elements, {draw = drawLanguageLabel})

    local transAreaY = langLabelY + mainPhraseHeight + 10 + readingHeight + 30
    local transAreaX = self.centerOffsetX + 50
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
    local wordBankY = transAreaY + transAreaHeight + 30
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
    local mainPhraseHeight = font_foreign_main:getHeight()
    local readingHeight = font_foreign_reading:getHeight()
    local transAreaY = self.centerOffsetY + 30 + mainPhraseHeight + 10 + readingHeight + 30
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
        print("Error: No audio path for current sentence.")
        return
    end

    local audio_file = self.current_sentence.audio
    local info = love.filesystem.getInfo(audio_file, "file")
    if info then
        local source = love.audio.newSource(audio_file, "static")
        source:play()
    else
        print("Error: Audio file not found: '" .. audio_file .. "'")
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
            Screen.mousepressed(self, x, y, button)
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


StartScreen = Screen:new()
StartScreen.__index = StartScreen

function StartScreen:new()
    local o = Screen:new()
    setmetatable(o, self)
    o.lessons = {}
    o.userScores = {}
    o.languages = {}
    o.currentLanguage = nil
    o.languageDropdownVisible = false
    o.languageDropdownButtons = {}
    o.languageSelectionButton = nil
    o.lessonButtons = {}
    o.scrollOffset = 0
    o.scrollAreaY = 0
    o.scrollAreaHeight = 0
    o.contentHeight = 0
    o.maxScrollOffset = 0
    o.settingsVisible = false
    o.resetConfirmationVisible = false
    o.noReviewsPopupVisible = false
    o.settingsElements = {}
    o.confirmationElements = {}
    o.noReviewsPopupElements = {}
    o.cogImage = nil
    o.userPrefs = loadUserPreferences()
    o:load()
    return o
end

function StartScreen:load()
    self.centerOffsetX = (screenWidth - 400) / 2
    self.centerOffsetY = (screenHeight - 500) / 2

    self.elements = {}
    self.languageDropdownButtons = {}
    self.languageDropdownVisible = false
    self.lessonButtons = {}
    self.settingsVisible = false
    self.resetConfirmationVisible = false
    self.noReviewsPopupVisible = false
    self.settingsElements = {}
    self.confirmationElements = {}
    self.noReviewsPopupElements = {}

    if not self.cogImage then
        local info = love.filesystem.getInfo("res/cog.png", "file")
        if info then
            self.cogImage = love.graphics.newImage("res/cog.png")
        else
            print("Warning: cog.png not found at res.")
        end
    end

    if not logoImage then
        local info = love.filesystem.getInfo("res/logo.png", "file")
        if info then
            logoImage = love.graphics.newImage("res/logo.png")
        else
            print("Warning: logo.png not found at res. Using text fallback. Tried: 'res/logo.png'")
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
            love.graphics.printf("PhraseWeaver", self.centerOffsetX, self.centerOffsetY + 40, 400, "center")
        end
    end
    table.insert(self.elements, {draw = drawLogo})


    local settingsButton = createButton(
        screenWidth - 70,
        screenHeight -70,
        50,
        50,
        nil,
        function() self:toggleSettings() end,
        SCORE_COLOR_DEFAULT,
        "res/cog.png"
    )
    table.insert(self.elements, settingsButton)

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
    self:loadLanguages("languages.txt")
end

function StartScreen:toggleSettings()
    self.settingsVisible = not self.settingsVisible
    self.settingsElements = {}

    if self.settingsVisible then
        local settingsWidth = 300
        local settingsHeight = 250
        local settingsX = screenWidth - settingsWidth - 20
        local settingsY = screenHeight - 70 - settingsHeight - 10

        table.insert(self.settingsElements, {
            draw = function()
                love.graphics.setColor(0.9, 0.95, 1.0, 0.95)
                love.graphics.rectangle("fill", settingsX, settingsY, settingsWidth, settingsHeight)
                love.graphics.setColor(0.1, 0.1, 0.4, 1.0)
                love.graphics.rectangle("line", settingsX, settingsY, settingsWidth, settingsHeight)
                 
                love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
                love.graphics.setFont(font_h2)
                love.graphics.printf("Settings", settingsX, settingsY + 20, settingsWidth, "center")
            end
        })

        local streakToggle = createButton(
            settingsX + (settingsWidth - 200) / 2,
            settingsY + 70,
            200,
            50,
            self.userPrefs.showStreak and "Hide Streak" or "Show Streak",
            function() 
                self.userPrefs.showStreak = not self.userPrefs.showStreak
                saveUserPreferences(self.userPrefs)
                self:toggleSettings()
            end
        )
        table.insert(self.settingsElements, streakToggle)

        local resetButton = createButton(
            settingsX + (settingsWidth - 200) / 2,
            settingsY + 130,
            200,
            50,
            "Reset Progress",
            function() self:showResetConfirmation() end
        )
        table.insert(self.settingsElements, resetButton)

        local closeButton = createButton(
            settingsX + (settingsWidth - 200) / 2,
            settingsY + 190,
            200,
            50,
            "Close",
            function() self:toggleSettings() end
        )
        table.insert(self.settingsElements, closeButton)
    end
end

function StartScreen:showResetConfirmation()
    self.resetConfirmationVisible = true
    self.confirmationElements = {}

    local popupWidth = 400
    local popupHeight = 200
    local popupX = screenWidth / 2 - popupWidth / 2
    local popupY = screenHeight / 2 - popupHeight / 2

    table.insert(self.confirmationElements, {
        draw = function()
            love.graphics.setColor(0.9, 0.95, 1.0, 0.95)
            love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight)
            love.graphics.setColor(0.1, 0.1, 0.4, 1.0)
            love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight)
             
            love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
            love.graphics.setFont(font_h2)
            love.graphics.printf("Reset Progress?", popupX, popupY + 30, popupWidth, "center")
            love.graphics.setFont(font_normal)
            love.graphics.printf("This will delete all your progress and cannot be undone.", popupX, popupY + 70, popupWidth, "center")
        end
    })

    local yesButton = createButton(
        popupX + 50,
        popupY + popupHeight - 70,
        120,
        50,
        "Yes",
        function() 
            self:onResetProgress() 
            self.resetConfirmationVisible = false
            self.settingsVisible = false
        end
    )
    table.insert(self.confirmationElements, yesButton)

    local noButton = createButton(
        popupX + popupWidth - 170,
        popupY + popupHeight - 70,
        120,
        50,
        "No",
        function() self.resetConfirmationVisible = false end
    )
    table.insert(self.confirmationElements, noButton)
end

function StartScreen:loadLanguages(filename)
    self.languages = loadLanguagesFromTxt(filename)

    if #self.languages > 0 then
        if not self.currentLanguage then
            self.currentLanguage = self.languages[1]
        end
    else
        print("Error: No languages loaded from '" .. filename .. "'. Cannot proceed. Check file content and path.")
        return
    end

    self.languageSelectionButton = createButton(
        screenWidth - 150,
        20,
        130,
        40,
        self.currentLanguage and self.currentLanguage.name or "Select Language",
        function() self:toggleLanguageDropdown() end
    )
    table.insert(self.elements, self.languageSelectionButton)

    self:loadLessons(self.currentLanguage.path)
end

function StartScreen:toggleLanguageDropdown()
    self.languageDropdownVisible = not self.languageDropdownVisible
    self.languageDropdownButtons = {}

    if self.languageDropdownVisible then
        local dropdownX = self.languageSelectionButton.x
        local dropdownY = self.languageSelectionButton.y + self.languageSelectionButton.height + 5
        local dropdownWidth = self.languageSelectionButton.width
        local buttonHeight = 40
        local verticalSpacing = 2

        for i, lang_data in ipairs(self.languages) do
            local btn = createButton(
                dropdownX,
                dropdownY + (i - 1) * (buttonHeight + verticalSpacing),
                dropdownWidth,
                buttonHeight,
                lang_data.name,
                function() self:onLanguageSelect(lang_data) end
            )
            table.insert(self.languageDropdownButtons, btn)
        end
    end
end

function StartScreen:onLanguageSelect(selected_language_data)
    self.currentLanguage = selected_language_data
    self.languageSelectionButton.text = selected_language_data.name
    self.languageDropdownVisible = false
    self:loadLessons(self.currentLanguage.path)
end

function StartScreen:onResetProgress()
    local scoreFilePath = customUserDataPath .. "/scores.txt"
    local success, err = love.filesystem.remove(scoreFilePath)
    if success then
        self.userScores = {}
        self:loadLessons(self.currentLanguage.path)
    else
        print("Error: Could not remove user scores file: '" .. scoreFilePath .. "'. Error: " .. tostring(err))
    end
end

function StartScreen:loadLessons(filename)
    self.lessons = loadLessonsFromTxt(filename)
    
    self.lessonButtons = {} 

    local actualLogoHeight = 72
    self.scrollAreaY = self.centerOffsetY + 40 + actualLogoHeight + 20
    self.scrollAreaHeight = screenHeight - self.scrollAreaY - 100
    self.scrollOffset = 0

	-- I might make it so the review button changes colour to indicate no more reviews, or reviews are due - I am too lazy to do this right this second, job for future me...
    local reviewButton = createButton(
        self.centerOffsetX + 20,
        self.scrollAreaY,
        360,
        60,
        "REVIEW",
        function() self:onReviewSelect() end,
        {0.8, 0.7, 1.0, 1.0}
    )
    table.insert(self.lessonButtons, 1, reviewButton)
    
    local yOffset = 60 + 10

    if #self.lessons > 0 then
        for _, lesson in ipairs(self.lessons) do
            local lessonScoreData = self.userScores[lesson.name]
            local lessonScore = lessonScoreData and lessonScoreData.score or nil
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
                self.scrollAreaY + yOffset,
                360,
                60,
                lesson.name,
                function() self:onLessonSelect(lesson.path, lesson.name) end,
                buttonColor
            )
            table.insert(self.lessonButtons, button)
            yOffset = yOffset + 60 + 10
        end
        self.contentHeight = yOffset
        self.maxScrollOffset = math.max(0, self.contentHeight - self.scrollAreaHeight)
    else
        print("Warning: No lessons found in '" .. filename .. "'. No lesson buttons created.")
        self.contentHeight = 0
        self.maxScrollOffset = 0
    end
end

function StartScreen:onReviewSelect()
    local scores = loadUserScores()
    local lessonsToReview = {}
    local today = os.date("%Y-%m-%d")
    
    for _, lesson in ipairs(self.lessons) do
        if scores[lesson.name] and scores[lesson.name].date ~= today then
            table.insert(lessonsToReview, {
                name = lesson.name,
                path = lesson.path,
                date = scores[lesson.name].date,
                score = scores[lesson.name].score
            })
        end
    end
    
    table.sort(lessonsToReview, function(a, b)
        return a.date < b.date
    end)
    
    if #lessonsToReview > 0 then
        local oldestLesson = lessonsToReview[1]
        
        for _, lesson in ipairs(self.lessons) do
            if lesson.name == oldestLesson.name then
                self:onLessonSelect(lesson.path, lesson.name)
                return
            end
        end
    else
        self:showNoReviewsPopup()
    end
end

function StartScreen:showNoReviewsPopup()
    self.noReviewsPopupVisible = true
    self.noReviewsPopupElements = {}

    local popupWidth = 400
    local popupHeight = 150
    local popupX = screenWidth / 2 - popupWidth / 2
    local popupY = screenHeight / 2 - popupHeight / 2

    table.insert(self.noReviewsPopupElements, {
        draw = function()
            love.graphics.setColor(0.9, 0.95, 1.0, 0.95)
            love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight)
            love.graphics.setColor(0.1, 0.1, 0.4, 1.0)
            love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight)
             
            love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
            love.graphics.setFont(font_h2)
            love.graphics.printf("No Reviews Today", popupX, popupY + 30, popupWidth, "center")
            love.graphics.setFont(font_normal)
            love.graphics.printf("You've completed all available reviews for today!", popupX, popupY + 70, popupWidth, "center")
        end
    })

    local closeButton = createButton(
        popupX + (popupWidth - 120) / 2,
        popupY + popupHeight - 50,
        120,
        40,
        "Close",
        function() self.noReviewsPopupVisible = false end
    )
    table.insert(self.noReviewsPopupElements, closeButton)
end

function StartScreen:onLessonSelect(csvPath, lessonName)
    love.audio.stop()
    currentScreen = TranslationGame:new(csvPath, self, lessonName)
end

function StartScreen:mousepressed(x, y, button)
    if self.noReviewsPopupVisible then
        for _, element in ipairs(self.noReviewsPopupElements) do
            if element.hitTest and element.callback then
                if element.hitTest(element, x, y) then
                    element.callback(element)
                    return
                end
            end
        end
        
        local popupWidth = 400
        local popupHeight = 150
        local popupX = screenWidth / 2 - popupWidth / 2
        local popupY = screenHeight / 2 - popupHeight / 2
        if not (x >= popupX and x <= popupX + popupWidth and y >= popupY and y <= popupY + popupHeight) then
            self.noReviewsPopupVisible = false
        end
        return
    end

    if self.resetConfirmationVisible then
        for _, element in ipairs(self.confirmationElements) do
            if element.hitTest and element.callback then
                if element.hitTest(element, x, y) then
                    element.callback(element)
                    return
                end
            end
        end
        
        local popupWidth = 400
        local popupHeight = 200
        local popupX = screenWidth / 2 - popupWidth / 2
        local popupY = screenHeight / 2 - popupHeight / 2
        if not (x >= popupX and x <= popupX + popupWidth and y >= popupY and y <= popupY + popupHeight) then
            self.resetConfirmationVisible = false
        end
        return
    end

    if self.settingsVisible then
        for _, element in ipairs(self.settingsElements) do
            if element.hitTest and element.callback then
                if element.hitTest(element, x, y) then
                    element.callback(element)
                    return
                end
            end
        end
        
        local settingsWidth = 300
        local settingsHeight = 250
        local settingsX = screenWidth - settingsWidth - 20
        local settingsY = screenHeight - 70 - settingsHeight - 10
        if not (x >= settingsX and x <= settingsX + settingsWidth and y >= settingsY and y <= settingsY + settingsHeight) then
            self.settingsVisible = false
        end
        return
    end

    if self.languageDropdownVisible then
        for _, element in ipairs(self.languageDropdownButtons) do
            if element.hitTest and element.callback then
                if element.hitTest(element, x, y) then
                    element.callback(element)
                    return
                end
            end
        end
        if not (self.languageSelectionButton and self.languageSelectionButton.hitTest(self.languageSelectionButton, x, y)) then
            local dropdownX = self.languageSelectionButton.x
            local dropdownY = self.languageSelectionButton.y + self.languageSelectionButton.height + 5
            local dropdownWidth = self.languageSelectionButton.width
            local dropdownHeight = #self.languages * (40 + 2)
            if not (x >= dropdownX and x <= dropdownX + dropdownWidth and y >= dropdownY and y <= dropdownY + dropdownHeight) then
                self.languageDropdownVisible = false
            end
        end
    end

    local clickedInScrollArea = x >= self.centerOffsetX + 20 and x <= self.centerOffsetX + 20 + 360 and 
                                y >= self.scrollAreaY and y <= self.scrollAreaY + self.scrollAreaHeight

    if clickedInScrollArea then
        for _, btn in ipairs(self.lessonButtons) do
            local adjustedBtnY = btn.y - self.scrollOffset
            if x >= btn.x and x <= btn.x + btn.width and
               y >= adjustedBtnY and y <= adjustedBtnY + btn.height and btn.enabled then
                btn.callback(btn)
                return
            end
        end
    end

    Screen.mousepressed(self, x, y, button)
end

function StartScreen:wheelmoved(x, y)
    if self.contentHeight > self.scrollAreaHeight then
        self.scrollOffset = self.scrollOffset - (y * 20)
        self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScrollOffset))
    end
end

function StartScreen:update(dt)
    Screen.update(self, dt)

    local mx, my = love.mouse.getPosition()

    for _, element in ipairs(self.elements) do
        if element.hitTest and element.enabled then
            element.isHovered = element.hitTest(element, mx, my)
        end
    end

    if self.settingsVisible then
        for _, element in ipairs(self.settingsElements) do
            if element.hitTest and element.enabled then
                element.isHovered = element.hitTest(element, mx, my)
            end
        end
    end

    if self.resetConfirmationVisible then
        for _, element in ipairs(self.confirmationElements) do
            if element.hitTest and element.enabled then
                element.isHovered = element.hitTest(element, mx, my)
            end
        end
    end

    if self.noReviewsPopupVisible then
        local mx, my = love.mouse.getPosition()
        for _, element in ipairs(self.noReviewsPopupElements) do
            if element.hitTest and element.enabled then
                element.isHovered = element.hitTest(element, mx, my)
            end
        end
    end

    if self.languageSelectionButton then
        self.languageSelectionButton.isHovered = self.languageSelectionButton.hitTest(self.languageSelectionButton, mx, my)
    end

    if self.languageDropdownVisible then
        for _, element in ipairs(self.languageDropdownButtons) do
            if element.hitTest and element.enabled then
                element.isHovered = element.hitTest(element, mx, my)
            end
        end
    end

    local hoveredInScrollArea = mx >= self.centerOffsetX + 20 and mx <= self.centerOffsetX + 20 + 360 and 
                                my >= self.scrollAreaY and my <= self.scrollAreaY + self.scrollAreaHeight

    for _, btn in ipairs(self.lessonButtons) do
        local adjustedBtnY = btn.y - self.scrollOffset
        btn.isHovered = (hoveredInScrollArea and mx >= btn.x and mx <= btn.x + btn.width and
                         my >= adjustedBtnY and my <= adjustedBtnY + btn.height and btn.enabled)
    end
end

function StartScreen:draw()
    for _, element in ipairs(self.elements) do
        if element.draw then
            element.draw(element)
        end
    end

    love.graphics.setScissor(self.centerOffsetX + 20, self.scrollAreaY, 360, self.scrollAreaHeight)

    for _, btn in ipairs(self.lessonButtons) do
        local originalY = btn.y
        btn.y = originalY - self.scrollOffset
        btn.draw(btn)
        btn.y = originalY
    end

    love.graphics.setScissor()

    if self.userPrefs.showStreak then
        local streak = getCurrentStreak()
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
        love.graphics.setFont(font_normal)
        love.graphics.printf("Current Streak: " .. streak, 20, screenHeight - 40, 200, "left")
    end

    if self.languageDropdownVisible then
        love.graphics.setColor(1, 1, 1, 1)
        local dropdownHeight = #self.languages * (40 + 2)
        love.graphics.rectangle("fill", self.languageSelectionButton.x, self.languageSelectionButton.y + self.languageSelectionButton.height + 5,
                                self.languageSelectionButton.width, dropdownHeight)
        love.graphics.setColor(0.1, 0.1, 0.4, 1.0)
        love.graphics.rectangle("line", self.languageSelectionButton.x, self.languageSelectionButton.y + self.languageSelectionButton.height + 5,
                                self.languageSelectionButton.width, dropdownHeight)

        for _, btn in ipairs(self.languageDropdownButtons) do
            btn.draw(btn)
        end
    end

    if self.settingsVisible then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
         
        for _, element in ipairs(self.settingsElements) do
            if element.draw then
                element.draw(element)
            end
        end
    end

    if self.resetConfirmationVisible then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
         
        for _, element in ipairs(self.confirmationElements) do
            if element.draw then
                element.draw(element)
            end
        end
    end

    if self.noReviewsPopupVisible then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
         
        for _, element in ipairs(self.noReviewsPopupElements) do
            if element.draw then
                element.draw(element)
            end
        end
    end
end
