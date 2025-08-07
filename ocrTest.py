from paddleocr import PaddleOCR
import os



ocr = PaddleOCR(use_angle_cls=True, lang='en') 

trainImages = r"archive (1)\plate-license-5\train"
testImages = r"archive (1)\plate-license-5\test"
validImages = r"archive (1)\plate-license-5\valid"


def ocrImages(folderPath):
    for fileName in os.listdir(folderPath):
        results = ocr.predict(fileName)

        for res in results:
            print(res)

#ocrImages(trainImages)
