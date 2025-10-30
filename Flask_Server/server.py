from flask import Flask, request
import os

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return "No file part", 400

    file = request.files['file']
    if file.filename == '':
        return "No selected file", 400

    # Save the file in the same folder as this script
    save_path = os.path.join(os.getcwd(), file.filename)
    file.save(save_path)
    print(f"✅ Received file: {file.filename}")

    return "File uploaded successfully", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)