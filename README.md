# License-Plate-Detection

main.m is the Squeeze-Net code and running that will detect license plates

main2.m is the YOLO model code and will crop the license plate images.

Check video for code if code doesn't work and these setup tricks don't work. Bhargav could not run python inside MATLAB even with the same setup as Umesh.

These instructions worked for Umesh.

Use Python 3.12. Matlab 2025a. Not Python 3.13
Set MATLAB env to python 3.12 exe.
Python 3.12 should be in program files and not in the appdata/local. This makes no sense but I needed this to happen.
Add python 3.12 to 
Navigate to directory of project and run following comamands.
pip install paddlepaddle==3.0.0 -i https://pypi.tuna.tsinghua.edu.cn/simple/
py -m pip install paddleocr


Other notes:
is_plate_there generates the model used in main.m and yoloPlateDetection.m generates the model used in main2.m. The models that we have are too big to fit on Github.

High level overview.
Main2.m: It uses a pre-trained YOLOv2 model to find license plates, then crops each detected plate. An external Python script with OCR (Optical Character Recognition) is used to read the text from these crops.

Finally, it saves the cropped plate images and generates a CSV report summarizing the detection and OCR results for every image processed.

Main.m: This script is a license plate detection pipeline. It uses a CNN to first determine if a license plate is in an image. If a plate is likely present, it then uses an algorithm involving region props properties to find and crop the plate area. Finally, it uses a Python script for OCR to read the characters. The entire process is logged and summarized in a CSV report.


Main2.m is the superior choice as YOLO is superior to the other mehods we used.




