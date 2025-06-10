### To do
- [ ] Add completion dates & times to user saves - this will then allow me to add a review button which will make it easier to review content
- [ ] I think I should hide the reset button behind a menu of sorts - also add a confirmation to it...
- [ ] I want to add a streak counter in the bottom right possibly? I think some people won't like streaks so I think it should be something that is toggleable...
- [ ] I want to add a dark mode at some point.
- [ ] I think I should split the script up into smaller scripts possibly? The single one is kinda long now and its getting hard to find functions lol



![image](https://github.com/user-attachments/assets/2332854e-ed93-4cd3-82bd-8436bbecc0d8)


# PhraseWeaver
Love2D language learning game, translate sentences using a bank of words.

![image](https://github.com/user-attachments/assets/36eb9fdb-9b8b-410a-a021-b58a00fd1804)


### Note
- Currently I am working on German stuff, then I will do the Chinese dataset
- Other language packs will be put here: https://github.com/stevnw/PhraseWeaver-Language-Packs/


I have made it so that it is quite easy to add data, and it should have the featureset required to easily add languages with different scripts or language specific phonetic readings

Essentially just add a line like this to languages.text - the first one on this list is what yours will default to when the program is run

<pre>Japanese=lang/jp_lessons.txt </pre>

Then you need to have a text file named whatever you have set in the languages.txt - this will be where you put the lessons i.e. jp_lessons.txt

<pre>
  Basics=lang/jp_lessons/basics.csv
  About You=lang/jp_lessons/about_you.csv
  Food=lang/jp_lessons/food.csv
</pre>

Then these call the csvs located in jp_lessons, these csvs look like:

<pre>
  私の名前はひなです,My name is Hina,わたしのなまえはひなです,lang/jp_lessons/audio/私の名前はひなです.mp3
  私は20歳です,I am 20 years old,わたしはにじゅっさいです,lang/jp_lessons/audio/私は20歳です.mp3
</pre>

You need the folder names, or it will not be able to find them

![image](https://github.com/user-attachments/assets/6484f343-458a-4460-a23f-3fb9dc5caff0)

Change language with the drop down in the top right

It saves your progress and marks lessons with a score - this determines the boxes colour on the main menu -> hit reset in the bottom to clear this but it saves in:

<pre>~/.local/share/love$</pre>


Audio is generated using gTTS python library - there is a script in /res/ which I used to generate the audio. You may need to change some of the code - these bits have comments next to them. To run this code

<pre>python gen.py basics1.csv</pre>

Just replace basics1.csv with whatever your csv is 

This will make the audio and update the csv to include audio paths - automating that task because it is quite long.
