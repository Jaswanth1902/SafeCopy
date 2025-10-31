from flask import Flask, request, send_from_directory
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


@app.route('/files', methods=['GET'])
def list_files():
    # List files in the current working directory
    files = [f for f in os.listdir(os.getcwd()) if os.path.isfile(os.path.join(os.getcwd(), f))]
    # Return a simple JSON list
    return {"files": files}, 200


@app.route('/files/<path:filename>', methods=['GET'])
def get_file(filename):
    # Send the requested file as an attachment for download
    return send_from_directory(os.getcwd(), filename, as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)