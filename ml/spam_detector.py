from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle

app = Flask(__name__)
CORS(app)

tokenizer = None
model = None
max_len = 100

def load_resources():
    global tokenizer, model
    if tokenizer is None or model is None:
        with open('tokenizer.pkl', 'rb') as f:
            tokenizer = pickle.load(f)
        with open('spam_nb_model.pkl', 'rb') as f:
            model = pickle.load(f)
        
@app.route('/')
def index():
    return 'Spam detection API is running'

@app.route('/predict', methods=['POST'])
def predict():
    load_resources() 
    data = request.get_json(force=True)
    message = data.get('message', '')

    vect_msg = tokenizer.transform([message])
    pred = model.predict(vect_msg)[0]
    proba = model.predict_proba(vect_msg)[0].max()

    return jsonify({
        'prediction': str(pred),
        'confidence': round(float(proba), 4)
    })

if __name__ == '__main__':
    app.run(debug=True)
