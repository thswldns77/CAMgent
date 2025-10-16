# -*- coding: utf-8 -*-
"""
Created on Mon Jul 21 15:43:34 2025

@author: pc
"""

# enhance.py
from PIL import Image, ImageOps
import torch
from basicsr.archs.rrdbnet_arch import RRDBNet
from realesrgan import RealESRGANer
import sys
import os
import numpy as np


def enhance(image_path):

    model_path = 'fastapi_server/weights/RealESRGAN_x2plus.pth'
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=23, num_grow_ch=32, scale=2)

    upsampler = RealESRGANer(
        scale=4,
        model_path=model_path,
        model=model,
        tile=0,
        tile_pad=10,
        pre_pad=0,
        half=not device.type == 'cpu',  # CPU면 half 사용 X
        device=device
    )
    print(image_path)
    current_dir = os.path.dirname(os.path.abspath(__file__))  # 현재 파일의 경로
    image_path = os.path.join(current_dir, "..", image_path)  # 상위 폴더로 이동
    image_path = os.path.abspath(image_path)
    
    image = Image.open(image_path)
    
    # EXIF 정보를 읽어 이미지를 올바른 방향으로 회전
    image = ImageOps.exif_transpose(image)
    image = image.convert('RGB')
    
    img_np = np.array(image)
    
    
    sr_image, _ = upsampler.enhance(img_np)

    # numpy to PIL 변환
    if isinstance(sr_image, np.ndarray):
        sr_image = Image.fromarray(sr_image)

    # 결과 저장
    output_path = os.path.splitext(image_path)[0] + "_enhanced.png"
    sr_image.save(output_path)

    return output_path
