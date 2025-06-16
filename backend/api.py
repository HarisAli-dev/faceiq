from fastapi import FastAPI, UploadFile, File, Query
from fastapi.responses import JSONResponse, Response
import cv2
import numpy as np
import os
from datetime import datetime
from deepface import DeepFace
from retinaface import RetinaFace
import io
from typing import Optional

app = FastAPI()

# 创建输出目录
OUTPUT_DIR = "./output"
# 服务器端口
SERVER_PORT = 8008

os.makedirs(OUTPUT_DIR, exist_ok=True)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# 定义颜色和边框设置
OUTER_COLOR = (255, 255, 255)  # 外层边框使用白色
INNER_COLOR = (0, 165, 255)    # 内层边框使用橙色
OUTER_THICKNESS = 6            # 外层边框粗细
INNER_THICKNESS = 3            # 内层边框粗细


def draw_detections_with_info(img, faces):
    """在图片上绘制检测结果和额外信息"""
    img_result = img.copy()

    for face in faces:
        # 获取人脸区域
        facial_area = face['facial_area']
        x = facial_area['x']
        y = facial_area['y']
        w = facial_area['w']
        h = facial_area['h']

        # 画双层边框
        cv2.rectangle(img_result,
                      (x, y),
                      (x + w, y + h),
                      OUTER_COLOR,
                      OUTER_THICKNESS)
        cv2.rectangle(img_result,
                      (x, y),
                      (x + w, y + h),
                      INNER_COLOR,
                      INNER_THICKNESS)

        # 准备显示的信息
        info_lines = []
        if face.get('score'):
            info_lines.append(f"Conf: {face['score']:.2f}")
        if face.get('age'):
            info_lines.append(f"Age: {face['age']}")
        if face.get('gender'):
            info_lines.append(f"Gender: {face['gender']}")
        if face.get('dominant_emotion'):
            info_lines.append(f"Emotion: {face['dominant_emotion']}")

        # 文本显示设置
        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 0.7
        text_thickness = 2
        line_height = 25
        padding = 5

        # 计算所有文本的总高度
        total_height = len(info_lines) * line_height

        # 确定文本起始位置（避免超出图像边界）
        start_y = max(total_height + padding, y)

        # 绘制信息
        for i, line in enumerate(info_lines):
            # 获取文本大小
            (text_width, text_height), _ = cv2.getTextSize(
                line, font, font_scale, text_thickness)

            # 计算文本位置
            text_y = start_y - (i * line_height)

            # 确保文本框不会超出图像边界
            text_x = min(x, img_result.shape[1] - text_width - padding)

            # 绘制文本背景（双层效果）
            cv2.rectangle(img_result,
                          (text_x - padding, text_y - text_height - padding),
                          (text_x + text_width + padding, text_y + padding),
                          OUTER_COLOR,
                          -1)
            cv2.rectangle(img_result,
                          (text_x - padding + 2, text_y -
                           text_height - padding + 2),
                          (text_x + text_width + padding - 2, text_y + padding - 2),
                          INNER_COLOR,
                          -1)

            # 绘制文本
            cv2.putText(img_result,
                        line,
                        (text_x, text_y),
                        font,
                        font_scale,
                        (255, 255, 255),
                        text_thickness)

    return img_result


def convert_to_native_types(obj):
    """将 numpy 类型转换为 Python 原生类型"""
    if isinstance(obj, dict):
        return {key: convert_to_native_types(value) for key, value in obj.items()}
    elif isinstance(obj, list):
        return [convert_to_native_types(item) for item in obj]
    elif isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    else:
        return obj


@app.post("/analyze")
async def detect(
    file: UploadFile = File(...),
    save_render: Optional[bool] = Query(
        default=False,
        description="Whether to save the rendered image with face detection markers"
    )
):
    try:
        # 读取图片
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            return JSONResponse(
                status_code=400,
                content={"error": "Invalid image"}
            )

        # 使用 RetinaFace 进行人脸检测
        faces = RetinaFace.detect_faces(img)

        # 转换检测结果格式
        face_list = []
        if isinstance(faces, dict):
            for face_key in faces:
                face_data = faces[face_key]
                facial_area = {
                    'x': int(face_data['facial_area'][0]),
                    'y': int(face_data['facial_area'][1]),
                    'w': int(face_data['facial_area'][2] - face_data['facial_area'][0]),
                    'h': int(face_data['facial_area'][3] - face_data['facial_area'][1])
                }

                face_img = img[
                    facial_area['y']:facial_area['y']+facial_area['h'],
                    facial_area['x']:facial_area['x']+facial_area['w']
                ]

                try:
                    analysis = DeepFace.analyze(
                        face_img,
                        actions=['age', 'gender', 'race', 'emotion'],
                        enforce_detection=False
                    )

                    if isinstance(analysis, list):
                        analysis = analysis[0]

                    gender = "Woman" if analysis['gender']['Woman'] > 50 else "Man"

                    face_info = {
                        'position': facial_area,
                        'confidence': float(face_data['score']) if 'score' in face_data else None,
                        'age': int(analysis['age']),
                        'gender': gender,
                        'dominant_race': str(analysis['dominant_race']),
                        'dominant_emotion': str(analysis['dominant_emotion']),
                        'emotion': {k: float(v) for k, v in analysis['emotion'].items()},
                        'race': {k: float(v) for k, v in analysis['race'].items()}
                    }

                except Exception as e:
                    print(f"Face analysis failed: {str(e)}")
                    face_info = {
                        'position': facial_area,
                        'confidence': float(face_data['score']) if 'score' in face_data else None
                    }

                face_list.append(face_info)

        output_path = None
        if save_render:
            # 准备绘制信息
            face_info_list = []
            for face in face_list:
                face_info = {
                    'facial_area': face['position'],
                    'score': face['confidence'],
                    'age': face.get('age'),
                    'gender': face.get('gender'),
                    'dominant_emotion': face.get('dominant_emotion')
                }
                face_info_list.append(face_info)

            # 绘制标记
            img_result = draw_detections_with_info(img, face_info_list)

            # 保存带标记的图片
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"result_{timestamp}.jpg"
            output_path = os.path.join(OUTPUT_DIR, output_filename)
            cv2.imwrite(output_path, img_result)

        # 准备响应数据
        response_data = {
            "status": "success",
            "faces_detected": len(face_list),
            "faces": convert_to_native_types(face_list),
        }
        print(response_data)
        # 只在保存了渲染图片时添加文件路径
        if output_path:
            response_data["output_file"] = output_path
            print(response_data)
        return response_data

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "message": str(e)
            }
        )

@app.post("/compare")
async def compare_faces(
    file1: UploadFile = File(..., description="First image file"),
    file2: UploadFile = File(..., description="Second image file")
):
    try:
        # Debug logging
        print(f"Received file1: {file1.filename if file1 else 'None'}")
        print(f"Received file2: {file2.filename if file2 else 'None'}")
        # Read both images
        contents1 = await file1.read()
        contents2 = await file2.read()

        nparr1 = np.frombuffer(contents1, np.uint8)
        nparr2 = np.frombuffer(contents2, np.uint8)

        img1 = cv2.imdecode(nparr1, cv2.IMREAD_COLOR)
        img2 = cv2.imdecode(nparr2, cv2.IMREAD_COLOR)

        if img1 is None or img2 is None:
            return JSONResponse(
                status_code=400,
                content={"error": "One or both images are invalid"}
            )

        # Convert BGR to RGB (OpenCV uses BGR, DeepFace expects RGB)
        img1_rgb = cv2.cvtColor(img1, cv2.COLOR_BGR2RGB)
        img2_rgb = cv2.cvtColor(img2, cv2.COLOR_BGR2RGB)

        # Perform face verification using DeepFace
        result = DeepFace.verify(
            img1_path=img1_rgb,
            img2_path=img2_rgb,
            enforce_detection=False,  # Set to False to handle cases where faces might not be clearly detected
            model_name='VGG-Face',  # You can specify the model explicitly
            distance_metric='cosine'  # You can specify the distance metric
        )

        # Calculate similarity percentage and confidence level
        distance = float(result["distance"])
        threshold = float(result["threshold"])
        
        # Calculate similarity percentage (lower distance = higher similarity)
        if result["similarity_metric"] == "cosine":
            similarity_percentage = max(0, (1 - distance) * 100)
        else:  # euclidean distances
            # For euclidean, we need to normalize differently
            similarity_percentage = max(0, (1 - min(distance / threshold, 1)) * 100)
        
        # Determine confidence level based on how far the distance is from threshold
        if distance <= threshold * 0.5:
            confidence_level = "Very High"
        elif distance <= threshold * 0.7:
            confidence_level = "High"
        elif distance <= threshold * 0.9:
            confidence_level = "Medium"
        elif distance <= threshold:
            confidence_level = "Low"
        else:
            confidence_level = "Very Low"
        
        # Create human-readable interpretation
        if result["verified"]:
            if similarity_percentage >= 90:
                interpretation = "The faces are very likely the same person"
            elif similarity_percentage >= 80:
                interpretation = "The faces are likely the same person"
            elif similarity_percentage >= 70:
                interpretation = "The faces are probably the same person"
            else:
                interpretation = "The faces might be the same person (low confidence)"
        else:
            interpretation = "The faces are likely different people"

        # Convert numpy types to native Python types for JSON serialization
        response_data = {
            "verified": bool(result["verified"]),
            "similarity_percentage": round(similarity_percentage, 2),
            "confidence_level": confidence_level,
            "interpretation": interpretation,
            "distance": distance,
            "threshold": threshold,
            "model": str(result["model"]),
            "similarity_metric": str(result["similarity_metric"]),
            "status": "success",
            "technical_details": {
                "raw_distance": distance,
                "model_threshold": threshold,
                "distance_from_threshold": round(abs(distance - threshold), 4),
                "verification_passed": bool(result["verified"])
            }
        }
        print(response_data)

        return response_data

    except Exception as e:
        error_message = str(e)
        print(f"Comparison failed: {error_message}")
        
        # Handle specific DeepFace errors
        if "Face could not be detected" in error_message:
            return JSONResponse(
                status_code=400,
                content={
                    "status": "error",
                    "message": "Could not detect faces in one or both images",
                    "error_type": "face_detection_failed"
                }
            )
        elif "Input image" in error_message and "not found" in error_message:
            return JSONResponse(
                status_code=400,
                content={
                    "status": "error", 
                    "message": "Invalid image format or corrupted image",
                    "error_type": "invalid_image"
                }
            )
        else:
            return JSONResponse(
                status_code=500,
                content={
                    "status": "error",
                    "message": error_message,
                    "error_type": "processing_error"
                }
            )


@app.post("/detect_and_return")
async def detect_and_return(file: UploadFile = File(...), info_display: Optional[bool] = Query(default=False)):
    try:
        # 读取图片
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            return JSONResponse(
                status_code=400,
                content={"error": "Invalid image"}
            )

        # 使用 RetinaFace 进行人脸检测
        faces = RetinaFace.detect_faces(img)

        # 转换检测结果格式
        face_list = []
        if isinstance(faces, dict):  # 检测到人脸
            for face_key in faces:
                face_data = faces[face_key]
                facial_area = {
                    'x': int(face_data['facial_area'][0]),
                    'y': int(face_data['facial_area'][1]),
                    'w': int(face_data['facial_area'][2] - face_data['facial_area'][0]),
                    'h': int(face_data['facial_area'][3] - face_data['facial_area'][1])
                }

                face_info = {
                    'facial_area': facial_area,
                    'score': float(face_data['score']) if 'score' in face_data else None
                }

                # 如果需要显示详细信息，则进行 DeepFace 分析
                if info_display:
                    try:
                        face_img = img[
                            facial_area['y']:facial_area['y']+facial_area['h'],
                            facial_area['x']:facial_area['x']+facial_area['w']
                        ]

                        analysis = DeepFace.analyze(
                            face_img,
                            actions=['age', 'gender', 'emotion'],
                            enforce_detection=False
                        )

                        if isinstance(analysis, list):
                            analysis = analysis[0]

                        gender = "Woman" if analysis['gender']['Woman'] > 50 else "Man"

                        face_info.update({
                            'age': int(analysis['age']),
                            'gender': gender,
                            'dominant_emotion': str(analysis['dominant_emotion'])
                        })
                    except Exception as e:
                        print(f"Face analysis failed: {str(e)}")

                face_list.append(face_info)

        # 在图片上绘制检测结果
        img_result = draw_detections_with_info(img, face_list)

        # 将图片编码为JPEG格式
        _, img_encoded = cv2.imencode('.jpg', img_result)

        # 返回处理后的图片
        return Response(
            content=img_encoded.tobytes(),
            media_type="image/jpeg",
            headers={
                "X-Faces-Detected": str(len(face_list)),
                "X-Detection-Status": "success" if face_list else "no_face"
            }
        )

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "message": str(e)
            }
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=SERVER_PORT)
