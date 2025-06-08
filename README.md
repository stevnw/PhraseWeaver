# PhraseWeaver
Love2D language learning game, translate sentences using a bank of words.

![image](https://github.com/user-attachments/assets/36eb9fdb-9b8b-410a-a021-b58a00fd1804)


### Note
- Currently I am working on German stuff, then I will do the Chinese datasets.


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

It saves your progress and makes lessons with a score - this determines the boxes colour -> hit reset in the bottom to clear this but it saves in:

<pre>~/.local/share/love$</pre>
