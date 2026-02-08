"""
	Better script for generating audio - to run from main dir PhraseWeaver: python res/gen.py lang/fr_lessons/{tsv_name_here}.tsv
		i.e. python res/gen.py lang/fr_lessons/basics1.tsv
				will export the audio to lang/fr_lessons/audio by default
	Change to suit your needs :)
	
				- made by stevnw
	
	gen.py	changes:		
	Changed to tsv...
				
"""

import csv
import os
import re
import sys
from gtts import gTTS

def generate_french_audio():
    if len(sys.argv) < 2:
        print("Usage: python gen.py <tsv_file_path>") 
        sys.exit(1)

    tsv_file_path = sys.argv[1]
    base_output_folder = "lang/fr_lessons/audio"

    if not os.path.exists(base_output_folder):
        os.makedirs(base_output_folder)

    updated_rows = []

    try:
        with open(tsv_file_path, 'r', encoding='utf-8') as file:
            reader = csv.reader(file, delimiter='\t')
            updated_rows = list(reader)

        for i, row in enumerate(updated_rows):
            if not row or not row[0]:
                continue

            french_text = row[0]
            sanitized_filename = re.sub(r'[^\w\s-]', '', french_text).strip()
            sanitized_filename = re.sub(r'\s+', '_', sanitized_filename).lower()[:50] or f"audio_row_{i+1}"
            
            audio_file_path = os.path.join(base_output_folder, f"{sanitized_filename}.mp3")
            
            try:
                print(f"Generating French audio for: '{french_text}'")
                tts = gTTS(text=french_text, lang='fr', slow=False)
                tts.save(audio_file_path)
                
                while len(row) < 4:
                    row.append('')
                row[3] = audio_file_path.replace(os.sep, '/')
            except Exception as e:
                print(f"Error for '{french_text}': {e}")

        with open(tsv_file_path, 'w', encoding='utf-8', newline='') as file:
            writer = csv.writer(file, delimiter='\t')
            writer.writerows(updated_rows)
        print(f"TSV '{tsv_file_path}' updated successfully.")

    except FileNotFoundError:
        print(f"Error: File '{tsv_file_path}' not found.")

if __name__ == "__main__":
    generate_french_audio()
