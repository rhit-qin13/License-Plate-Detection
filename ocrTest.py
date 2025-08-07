from paddleocr import PaddleOCR



ocr = PaddleOCR(use_angle_cls=True, lang='en') 

imagePath = r"archive (1)\plate-license-5\test\0_3_hr_png_jpg.rf.c679897f52689da139e29adc623291fd.jpg"

results = ocr.predict(imagePath)

for res in results:
    print(res)