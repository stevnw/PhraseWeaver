"""
	Dog shit script, but it gets the job done...
"""

import csv
import os
from gtts import gTTS
import re

def generate_german_audio(csv_file_path="basics.csv", output_folder="audio"): # Change the name each time hahahahahahahahaha 

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        print(f"Created folder: {output_folder}")

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

            audio_relative_path = os.path.join(output_folder, f"{sanitized_filename}.mp3").replace(os.sep, '/')
            audio_file_path = os.path.join(os.path.dirname(csv_file_path), audio_relative_path)


            try:
                print(f"Generating audio for: '{german_text}'") # Generate for German, can probably reuse this for another language at some point...
                tts = gTTS(text=german_text, lang='ja', slow=False)
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
