"""
	Better script for generating audio - to run: python gen.py <csvnamehere.csv>
		i.e. python gen.py basics1.csv
				will export the audio to lang/de_lessons/audio by default
	Change to suit your needs :)
	
				- made by stevnw
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

            sanitized_filename = re.sub(r'[^\w\s-]', '', german_text).strip()
            sanitized_filename = re.sub(r'\s+', '_', sanitized_filename)
            sanitized_filename = sanitized_filename[:50].lower()

            if not sanitized_filename:
                sanitized_filename = f"audio_row_{i+1}"

            audio_file_name = f"{sanitized_filename}.mp3"
            audio_file_path = os.path.join(base_output_folder, audio_file_name)
            
            audio_relative_path = os.path.join(base_output_folder, audio_file_name).replace(os.sep, '/')

            try:
                print(f"Generating audio for: '{german_text}'")
                tts = gTTS(text=german_text, lang='de', slow=False) # Change the de to the right language code, i.e. es = spanish, ja = japanese, zh = Chinese etc
                tts.save(audio_file_path)
                print(f"Saved: {audio_file_path}")

                while len(row) < 4:
                    row.append('')
                updated_rows[i][3] = audio_relative_path
            except Exception as e:
                print(f"Error generating audio for '{german_text}': {e}")

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
