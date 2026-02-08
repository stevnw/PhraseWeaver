### To do
- [ ] Rewrite this README properly, its very work in progress...
- [ ] I think the way in which saves work currently does not seem to work on windows (works on linux though - have not got the means to test on mac)
- [ ] Some kind of story or multi speaker dialogue mode? -> for now I have gone with an ordered/random mode - I feel like this might do the job? Sequential convos...
- [ ] I want to add a dark mode at some point.




![image](https://github.com/user-attachments/assets/2332854e-ed93-4cd3-82bd-8436bbecc0d8)


# PhraseWeaver
Love2D language learning game, translate sentences using a bank of words.

![image](https://github.com/user-attachments/assets/36eb9fdb-9b8b-410a-a021-b58a00fd1804)


### Note
- Currently I am ~~taking a break~~ BACK!!!! - I intend to ship this only with French stuff
- Other language packs I make will be put here: https://github.com/stevnw/PhraseWeaver-Language-Packs/


I have made it so that it is quite easy to add data, and it should have the featureset required to easily add languages with different scripts or language specific phonetic readings

Essentially just add a line like this to languages.text - the first one on this list is what yours will default to when the program is run

<pre>French=lang/fr_lessons.txt </pre>

Then you need to have a text file named whatever you have set in the languages.txt - this will be where you put the lessons i.e. fr_lessons.txt

<pre>
  Basics=lang/fr_lessons/basics.tsv
  About You=lang/fr_lessons/about_you.tsv
  Food=lang/fr_lessons/food.tsv
</pre>

You can either put it in Ordered or Random mode using R and O, Random is the assumed default so;

<pre>
  Basics=lang/fr_lessons/basics.tsv	# Random as assumed default
  About You=lang/fr_lessons/about_you.tsv,R # Random, lessons contents will be random
  Food=lang/fr_lessons/food.tsv,O # Ordered, lessons contents will be in the orderer of the .tsv
</pre>

Then these call the tsvs located in fr_lessons, these tsvs are in the format of:

<pre>
	phrase {tab} meaning {tab} reading (i.e. Kana for Japanese, just leave blank if not needed) {tab} audio_path
</pre>

i.e.

<pre>
  ça va bien	things are going well		lang/fr_lessons/audio/ça_va_bien.mp3
  merci	thank you		lang/fr_lessons/audio/merci.mp3
</pre>

You will need the folder names, or it will not be able to find them

![image](https://github.com/user-attachments/assets/6484f343-458a-4460-a23f-3fb9dc5caff0)

Change language with the drop down in the top right

It saves your progress and marks lessons with a score - this determines the boxes colour on the main menu -> hit reset in the bottom to clear this but it saves in:

<pre>~/.local/share/love$</pre>


Audio is generated using gTTS python library - there is a script in /res/ which I used to generate the audio. You may need to change some of the code - these bits have comments next to them. To run this code from the PhraseWeaver directory;

<pre>python res/gen.py lang/fr_lessons/basics1.tsv</pre>

Just replace basics1.tsv with whatever your tsv is. 

This will generate the audio and update the tsv to include audio paths.
