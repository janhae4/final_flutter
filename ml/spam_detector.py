from flask import Flask, request, jsonify
import pickle
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.sequence import pad_sequences

app = Flask(__name__)

tokenizer = None
model = None
max_len = 100

def load_resources():
    global tokenizer, model
    if tokenizer is None or model is None:
        with open('tokenizer.pkl', 'rb') as f:
            tokenizer = pickle.load(f)
        model = load_model('spam_classifier_model.keras')
        
@app.route('/')
def index():
    return 'Spam detection API is running'

@app.route('/predict', methods=['POST'])
def predict():
    load_resources() 
    data = request.get_json(force=True)
    message = data.get('message', '')

    sequences = tokenizer.texts_to_sequences([message])
    padded_seq = pad_sequences(sequences, maxlen=max_len, padding='post', truncating='post')

    pred_prob = model.predict(padded_seq)[0][0]
    label = 'spam' if pred_prob > 0.5 else 'ham'

    return jsonify({
        'prediction': label,
        'probability': float(pred_prob)
    })

if __name__ == '__main__':
    app.run(debug=True)
