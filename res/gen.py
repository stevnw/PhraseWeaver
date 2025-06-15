"""
	Better script for generating audio - to run: python gen.py <csvnamehere.csv>
		i.e. python gen.py basics1.csv
				will export the audio to lang/de_lessons/audio by default
	Change to suit your needs :)
	
				- made by stevnw
	
	gen.py	changes:		
	I added conditions for ones where there is a slash in the words - so like gendered differences might be like masc/fem and you want both readings in the same one perhaps so this names the 
	file a valid thing really...
				
"""

import csv
import os
import re
import sys
from gtts import gTTS

def generate_german_audio():
    if len(sys.argv) < 2:
        print("Usage: python your_script_name.py <csv_file_path>") 
        sys.exit(1)

    csv_file_path = sys.argv[1]
    
    base_output_folder = "lang/de_lessons/audio" # Change de to the right path for your use case lol

    if not os.path.exists(base_output_folder):
        os.makedirs(base_output_folder)
        print(f"Created folder: {base_output_folder}")

    updated_rows = []

    try:
        with open(csv_file_path, 'r', encoding='utf-8') as file:
            reader = csv.reader(file)
            for row in reader:
                updated_rows.append(row)

        for i, row in enumerate(updated_rows):
            if not row:
                continue

            german_text = row[0]
            audio_file_paths_for_csv = [] 

            if '/' in german_text:
                parts = german_text.split('/')
                sanitized_parts_for_filename = []
                for part in parts:
                    clean_part = part.strip()
                    sanitized_part = re.sub(r'[^\w\s-]', '', clean_part).strip()
                    sanitized_part = re.sub(r'\s+', '_', sanitized_part)
                    sanitized_parts_for_filename.append(sanitized_part.lower())
                
                combined_sanitized_filename = "-".join(sanitized_parts_for_filename)
                if not combined_sanitized_filename:
                    combined_sanitized_filename = f"audio_row_{i+1}_combined"
                
                audio_file_name = f"{combined_sanitized_filename}.mp3"
                audio_file_path = os.path.join(base_output_folder, audio_file_name)
                audio_relative_path = os.path.join(base_output_folder, audio_file_name).replace(os.sep, '/')
                
                audio_file_paths_for_csv.append(audio_relative_path)

                try:
                    print(f"Generating combined audio for: '{german_text}'")
                    tts = gTTS(text=german_text, lang='de', slow=False)
                    tts.save(audio_file_path)
                    print(f"Saved: {audio_file_path}")
                except Exception as e:
                    print(f"Error generating combined audio for '{german_text}': {e}")
            else:
                sanitized_filename = re.sub(r'[^\w\s-]', '', german_text).strip()
                sanitized_filename = re.sub(r'\s+', '_', sanitized_filename)
                sanitized_filename = sanitized_filename[:50].lower()

                if not sanitized_filename:
                    sanitized_filename = f"audio_row_{i+1}"

                audio_file_name = f"{sanitized_filename}.mp3"
                audio_file_path = os.path.join(base_output_folder, audio_file_name)
                
                audio_relative_path = os.path.join(base_output_folder, audio_file_name).replace(os.sep, '/')
                audio_file_paths_for_csv.append(audio_relative_path)

                try:
                    print(f"Generating audio for: '{german_text}'")
                    tts = gTTS(text=german_text, lang='de', slow=False) # Change the de to the right language code, i.e. es = spanish, ja = japanese, zh = Chinese etc
                    tts.save(audio_file_path)
                    print(f"Saved: {audio_file_path}")
                except Exception as e:
                    print(f"Error generating audio for '{german_text}': {e}")
            
            while len(row) < 4:
                row.append('')
            updated_rows[i][3] = ", ".join(audio_file_paths_for_csv)

        with open(csv_file_path, 'w', encoding='utf-8', newline='') as file:
            writer = csv.writer(file)
            writer.writerows(updated_rows)
        print(f"CSV file '{csv_file_path}' updated successfully with audio paths.")

    except FileNotFoundError:
        print(f"Error: The file '{csv_file_path}' was not found.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    generate_german_audio()
