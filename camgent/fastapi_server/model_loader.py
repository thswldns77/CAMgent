# nima_model.py

import numpy as np
from PIL import Image
from keras.models import Model
from keras.layers import Dense, Dropout
from keras.applications.mobilenet import MobileNet, preprocess_input
from keras.preprocessing.image import img_to_array
import tensorflow as tf

# 평균/표준편차 계산 함수
def mean_score(scores):
    return sum([i * score for i, score in enumerate(scores, 1)])

def std_score(scores):
    mean = mean_score(scores)
    return (sum([score * ((i - mean) ** 2) for i, score in enumerate(scores, 1)])) ** 0.5

# 모델 로드 함수
def load_nima_model(weight_path='fastapi_server/weights/mobilenet_weights.h5', target_size=(224, 224)):
    with tf.device('/CPU:0'):
        base_model = MobileNet((None, None, 3), alpha=1, include_top=False, pooling='avg', weights=None)
        x = Dropout(0.75)(base_model.output)
        x = Dense(10, activation='softmax')(x)
        model = Model(base_model.input, x)
        model.load_weights(weight_path)
    return model, target_size

# PIL 이미지를 받아 점수 계산
def predict_score_from_pil(img: Image.Image, model, target_size=(224, 224)):
    img = img.resize(target_size)
    x = img_to_array(img)
    x = np.expand_dims(x, axis=0)
    x = preprocess_input(x)

    scores = model.predict(x, batch_size=1, verbose=0)[0]
    print("--------------")
    
    print(scores)
    mean = mean_score(scores)
    return mean  # std_score(scores)도 필요하면 같이 리턴 가능
