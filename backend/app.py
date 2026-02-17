from flask import Flask, request, jsonify
import cv2
import numpy as np
import os
from deepface import DeepFace

app = Flask(__name__)

face_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
)

SAVE_DIR = "registered_faces"
os.makedirs(SAVE_DIR, exist_ok=True)


# ------------------------------
# REGISTER FACE ROUTE
# ------------------------------
@app.route("/register-face", methods=["POST"])
def register_face():
    file = request.files.get("image")
    username = request.form.get("username")

    if not file or not username:
        return jsonify({"error": "Missing data"}), 400

    img_array = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.3, 5)

    if len(faces) == 0:
        return jsonify({"error": "No face detected"}), 400

    (x, y, w, h) = faces[0]
    face = frame[y:y+h, x:x+w]

    save_path = os.path.join(SAVE_DIR, f"{username}.jpg")
    cv2.imwrite(save_path, face)

    return jsonify({"status": "registered"}), 200


# ------------------------------
# LOGIN FACE ROUTE  (THIS IS MISSING)
# ------------------------------
@app.route("/login-face", methods=["POST"])
def login_face():
    file = request.files.get("image")
    username = request.form.get("username")

    if not file or not username:
        return jsonify({"verified": False}), 400

    user_path = os.path.join(SAVE_DIR, f"{username}.jpg")

    if not os.path.exists(user_path):
        return jsonify({"verified": False})

    img_array = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.3, 5)

    if len(faces) == 0:
        return jsonify({"verified": False})

    (x, y, w, h) = faces[0]
    face = frame[y:y+h, x:x+w]

    login_face_path = "temp_login.jpg"
    cv2.imwrite(login_face_path, face)

    try:
        result = DeepFace.verify(
            img1_path=user_path,
            img2_path=login_face_path,
            model_name="ArcFace",
            enforce_detection=False
        )

        print("DeepFace result:", result)

        if result["verified"]:
            return jsonify({"verified": True, "username": username})
        else:
            return jsonify({"verified": False})

    except Exception as e:
        print("Verification error:", e)
        return jsonify({"verified": False})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
