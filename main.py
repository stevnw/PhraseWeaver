"""
	Proof of concept really... Its quite shitty at the moment, and will need some major reworks, or even complete rewrites to get to a better state.
	General idea is just make it Duo-like, but like not shit! (Even though this is quite shit haha)
"""
import wx
import csv
import random
import os
import pygame
import sys
import json

class TranslationGame(wx.Frame):
    def __init__(self, parent, title, csv_filename, start_screen_ref):
        super(TranslationGame, self).__init__(parent, title=title, size=(800, 600))
        pygame.mixer.init()
        
        self.start_screen_ref = start_screen_ref

        self.sentences = []
        self.shuffled_indices = []
        self.sentences_completed_count = 0
        self.correct_answers_count = 0
        self.current_sentence = None
        self.selected_words = []
        self.csv_filename = csv_filename 
        
        self.panel = wx.Panel(self)
        self.panel.SetBackgroundColour(wx.Colour(240, 245, 250))
        main_sizer = wx.BoxSizer(wx.VERTICAL)
        
        self.language_label = wx.StaticText(self.panel, label="", style=wx.ALIGN_CENTER)
        self.language_label.SetFont(wx.Font(24, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
        self.language_label.SetForegroundColour(wx.Colour(50, 50, 50))
        main_sizer.Add(self.language_label, 0, wx.EXPAND | wx.TOP | wx.LEFT | wx.RIGHT, 30)
        main_sizer.AddSpacer(30)
        
        self.translation_area = wx.ScrolledWindow(self.panel, style=wx.VSCROLL | wx.HSCROLL)
        self.translation_area.SetBackgroundColour(wx.Colour(255, 255, 255))
        self.translation_area.SetMinSize((-1, 120))
        self.translation_sizer = wx.BoxSizer(wx.HORIZONTAL)
        self.translation_area.SetSizer(self.translation_sizer)
        self.translation_area.SetScrollbars(20, 20, 50, 1)
        
        main_sizer.Add(self.translation_area, 0, wx.EXPAND | wx.LEFT | wx.RIGHT, 50)
        main_sizer.AddSpacer(30)
        
        self.word_bank_panel = wx.Panel(self.panel)
        self.word_sizer = wx.WrapSizer(wx.HORIZONTAL)
        self.word_bank_panel.SetSizer(self.word_sizer)
        main_sizer.Add(self.word_bank_panel, 1, wx.EXPAND | wx.LEFT | wx.RIGHT, 20)
        main_sizer.AddSpacer(20)
        
        button_sizer = wx.BoxSizer(wx.HORIZONTAL)
        
        self.check_btn = wx.Button(self.panel, label="CHECK", size=(150, 50))
        self.check_btn.SetFont(wx.Font(14, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
        self.check_btn.SetBackgroundColour(wx.Colour(230, 255, 230))
        
        self.next_btn = wx.Button(self.panel, label="NEXT", size=(150, 50))
        self.next_btn.SetFont(wx.Font(14, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
        self.next_btn.SetBackgroundColour(wx.Colour(255, 245, 230))
        
        button_sizer.Add(self.check_btn, 0, wx.ALL, 10)
        button_sizer.Add(self.next_btn, 0, wx.ALL, 10)
        main_sizer.Add(button_sizer, 0, wx.ALIGN_CENTER | wx.BOTTOM, 20)
        
        self.status_text = wx.StaticText(self.panel, label="")
        self.status_text.SetFont(wx.Font(12, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_ITALIC, wx.FONTWEIGHT_NORMAL))
        self.status_text.SetForegroundColour(wx.Colour(100, 100, 100))
        main_sizer.Add(self.status_text, 0, wx.ALIGN_CENTER | wx.BOTTOM, 10)
        
        self.panel.SetSizer(main_sizer)
        
        self.check_btn.Bind(wx.EVT_BUTTON, self.on_check)
        self.next_btn.Bind(wx.EVT_BUTTON, self.on_next)
        self.Bind(wx.EVT_CLOSE, self.on_close)
        
        self.load_data(self.csv_filename)
        if self.sentences:
            self.load_sentence()
        else:
            wx.MessageBox(f"No sentences found in {self.csv_filename}", "Error", wx.OK | wx.ICON_ERROR)
            self.on_close(None)
        
        self.Centre()
        self.Show()
    
    def load_data(self, filename):
        if os.path.exists(filename):
            try:
                with open(filename, 'r', encoding='utf-8') as f:
                    reader = csv.reader(f)
                    for row in reader:
                        if len(row) >= 4:
                            self.sentences.append({
                                'german': row[0],
                                'english': row[1],
                                'literal': row[2],
                                'audio': row[3]
                            })
                self.shuffled_indices = list(range(len(self.sentences)))
                random.shuffle(self.shuffled_indices)
            except Exception as e:
                wx.MessageBox(f"Error reading CSV file '{filename}': {e}", "Error", wx.OK | wx.ICON_ERROR)
        else:
            wx.MessageBox(f"CSV file not found: {filename}", "Error", wx.OK | wx.ICON_ERROR)
    
    def load_sentence(self):
        if self.sentences_completed_count >= len(self.sentences):
            self.show_completion_screen()
            return
            
        current_sentence_index = self.shuffled_indices[self.sentences_completed_count]
        self.current_sentence = self.sentences[current_sentence_index]
        self.selected_words = []
        
        self.language_label.SetLabel(self.current_sentence['german'])
        
        self.translation_sizer.Clear(True)
        self.translation_area.Layout()
        
        self.word_sizer.Clear(True)
        english_words = self.current_sentence['english'].split()
        random.shuffle(english_words)
        
        for word in english_words:
            btn = wx.Button(self.word_bank_panel, label=word, size=(120, 60))
            btn.SetFont(wx.Font(14, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
            btn.SetBackgroundColour(wx.Colour(255, 255, 255))
            btn.SetForegroundColour(wx.Colour(0, 0, 150))
            btn.Bind(wx.EVT_BUTTON, self.on_word_select)
            self.word_sizer.Add(btn, 0, wx.ALL, 8)
        
        #self.status_text.SetLabel("Click words to build your translation")
        #self.status_text.SetForegroundColour(wx.Colour(100, 100, 100))
        
        self.word_bank_panel.Layout()
        self.panel.Layout()
        self.translation_area.Scroll(0, 0) # Scroll to the beginning for new sentence
    
    def on_word_select(self, event):
        btn = event.GetEventObject()
        word = btn.GetLabel()
        self.selected_words.append(word)
        
        word_label = wx.StaticText(self.translation_area, label=word, style=wx.ALIGN_CENTER | wx.ALIGN_CENTER_VERTICAL)
        word_label.SetFont(wx.Font(18, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
        word_label.SetForegroundColour(wx.Colour(0, 0, 100))
        word_label.SetBackgroundColour(wx.Colour(255, 255, 200))
        word_label.SetMinSize((140, 70))
        
        self.translation_sizer.Add(word_label, 0, wx.ALL | wx.ALIGN_CENTER_VERTICAL, 8)
        self.translation_area.Layout()
        
        total_width = self.translation_sizer.GetMinSize().width
        current_width = self.translation_area.GetSize().width
        if total_width > current_width:
            self.translation_area.SetVirtualSize((total_width, -1))
            self.translation_area.Scroll(self.translation_area.GetScrollPageSize(wx.HORIZONTAL), 0)
        
        btn.Disable()
        
        #self.status_text.SetLabel("Build your translation then click CHECK")
        self.status_text.SetForegroundColour(wx.Colour(100, 100, 100))
    
    def on_check(self, event):
        if not self.current_sentence:
            return
        
        self.play_german_audio()
        
        user_translation = " ".join(self.selected_words)
        correct_translation = self.current_sentence['english']
        
        if user_translation == correct_translation:
            self.status_text.SetLabel("✓ CORRECT! Great job!")
            self.status_text.SetForegroundColour(wx.Colour(0, 150, 0))
            self.correct_answers_count += 1
        else:
            self.status_text.SetLabel(f"✗ INCORRECT. Correct: {correct_translation}")
            self.status_text.SetForegroundColour(wx.Colour(200, 0, 0))
        
        self.check_btn.Disable()
        self.next_btn.Enable()
        for child in self.word_sizer.GetChildren():
            widget = child.GetWindow()
            if widget:
                widget.Disable()

    def on_next(self, event):
        self.sentences_completed_count += 1
        self.check_btn.Enable()
        self.next_btn.Disable()
        self.load_sentence()
    
    def play_german_audio(self):
        if not self.current_sentence or 'audio' not in self.current_sentence:
            return
        
        audio_file = self.current_sentence['audio']
        if os.path.exists(audio_file):
            try:
                pygame.mixer.music.load(audio_file)
                pygame.mixer.music.play()
            except pygame.error as e:
                print(f"Error playing audio: {e}")
                try:
                    pygame.mixer.Sound(buffer=bytearray([128]*100)).play()
                except:
                    pass
        else:
            print(f"Audio file not found: {audio_file}")
            try:
                pygame.mixer.Sound(buffer=bytearray([128]*100)).play()
            except:
                pass
    
    def show_completion_screen(self):
        self.Hide()
        total_sentences = len(self.sentences)
        completion_dialog = LessonCompletionScreen(self, "Lesson Complete!", self.correct_answers_count, total_sentences)
        completion_dialog.ShowModal()

        self.on_close(None)
        self.start_screen_ref.Show()

    def on_close(self, event):
        pygame.mixer.quit()
        self.Destroy()

class LessonCompletionScreen(wx.Dialog):
    def __init__(self, parent, title, correct_count, total_count):
        super(LessonCompletionScreen, self).__init__(parent, title=title, size=(400, 250), style=wx.DEFAULT_DIALOG_STYLE | wx.RESIZE_BORDER)
        
        panel = wx.Panel(self)
        panel.SetBackgroundColour(wx.Colour(240, 245, 250))
        sizer = wx.BoxSizer(wx.VERTICAL)

        congrats_label = wx.StaticText(panel, label="Lesson Complete!")
        congrats_label.SetFont(wx.Font(24, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
        congrats_label.SetForegroundColour(wx.Colour(0, 100, 0))
        sizer.Add(congrats_label, 0, wx.ALIGN_CENTER | wx.TOP | wx.BOTTOM, 20)

        score_label = wx.StaticText(panel, label=f"You got {correct_count} out of {total_count} sentences correct!")
        score_label.SetFont(wx.Font(16, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_NORMAL))
        score_label.SetForegroundColour(wx.Colour(50, 50, 50))
        sizer.Add(score_label, 0, wx.ALIGN_CENTER | wx.BOTTOM, 30)

        back_button = wx.Button(panel, label="Back to Topics", size=(180, 50))
        back_button.SetFont(wx.Font(14, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
        back_button.SetBackgroundColour(wx.Colour(200, 220, 255))
        back_button.Bind(wx.EVT_BUTTON, self.on_back_to_topics)
        sizer.Add(back_button, 0, wx.ALIGN_CENTER | wx.BOTTOM, 20)

        panel.SetSizer(sizer)
        self.Centre()

    def on_back_to_topics(self, event):
        self.EndModal(wx.ID_OK)

class StartScreen(wx.Frame):
    def __init__(self, parent, title):
        super(StartScreen, self).__init__(parent, title=title, size=(400, 500))
        self.panel = wx.Panel(self)
        self.panel.SetBackgroundColour(wx.Colour(240, 245, 250))
        
        self.main_sizer = wx.BoxSizer(wx.VERTICAL)
        
        title_label = wx.StaticText(self.panel, label="wxLingoLearn", style=wx.ALIGN_CENTER)
        title_label.SetFont(wx.Font(36, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
        title_label.SetForegroundColour(wx.Colour(50, 50, 50))
        self.main_sizer.Add(title_label, 0, wx.EXPAND | wx.TOP | wx.BOTTOM, 40)
        
        self.lesson_sizer = wx.GridSizer(0, 1, 10, 10)
        
        self.load_lessons("lessons.json")
        
        self.main_sizer.Add(self.lesson_sizer, 1, wx.EXPAND | wx.ALL, 20)
        
        self.panel.SetSizer(self.main_sizer)
        self.Centre()
        self.Show()

    def load_lessons(self, filename):
        if os.path.exists(filename):
            try:
                with open(filename, 'r', encoding='utf-8') as f:
                    lessons_data = json.load(f)
                
                for lesson_name, csv_path in lessons_data.items():
                    btn = wx.Button(self.panel, label=lesson_name, size=(-1, 60))
                    btn.SetFont(wx.Font(16, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))
                    btn.SetBackgroundColour(wx.Colour(170, 200, 255))
                    btn.SetForegroundColour(wx.Colour(25, 25, 100))
                    btn.Bind(wx.EVT_BUTTON, lambda event, path=csv_path: self.on_lesson_select(event, path))
                    self.lesson_sizer.Add(btn, 0, wx.EXPAND)
                self.panel.Layout()
            except json.JSONDecodeError:
                wx.MessageBox(f"Error decoding JSON from {filename}. Please check the file format.", "Error", wx.OK | wx.ICON_ERROR)
            except Exception as e:
                wx.MessageBox(f"An error occurred loading lessons: {e}", "Error", wx.OK | wx.ICON_ERROR)
        else:
            wx.MessageBox(f"Lessons configuration file not found: {filename}", "Error", wx.OK | wx.ICON_ERROR)

    def on_lesson_select(self, event, csv_path):
        self.Hide()
        TranslationGame(self, "wxLingoLearn", csv_path, self) 

if __name__ == "__main__":
    app = wx.App(False)
    start_screen = StartScreen(None, "wxLingoLearn - Select Topic")
    app.MainLoop()
