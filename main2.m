clear; clc; close all;

datasetRoot = fullfile("License Plate Detection.v3i.voc/");
testDir     = fullfile(datasetRoot,"test");
outputDir   = "cropped_plates";

if ~isfolder(testDir)
    error('Test folder not found: %s', testDir);
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

testDS = imageDatastore(testDir, 'IncludeSubfolders', true);

% Check for the existence of the YOLO model file.
if ~isfile("yolo_license_plate_v2.mat")
    error('yolo_license_plate_v2.mat not found in current folder. Please ensure the model file is in the current working directory.');
end

% Load the YOLO model from the .mat file.
S_yolo = load("yolo_license_plate_v2.mat");
yoloNet = [];

netFields = fieldnames(S_yolo);
for k = 1:numel(netFields)
    obj = S_yolo.(netFields{k});
    if isa(obj, 'yolov2ObjectDetector') || isa(obj, 'ssdObjectDetector')
        yoloNet = obj;
        break;
    end
end

if isempty(yoloNet)
    error('Could not find a valid yolov2ObjectDetector inside yolo_license_plate_v2.mat');
end

fprintf('Successfully loaded YOLOv2 license plate detector.\n');

% Check if the Python OCR script exists.
if ~isfile('fixed_ocr.py')
    error('fixed_ocr.py not found in current folder.');
end

% Get the total number of test images and initialize statistics.
N = numel(testDS.Files);
fprintf('Found %d test images.\n', N);

statsTotal.totalImages        = N;
statsTotal.predictedHasPlate  = 0;
statsTotal.totalCrops         = 0;
statsTotal.ocrReadWithAnyText = 0;

% Initialize a table to store the results.
resultsTable = table('Size', [N, 6], ...
    'VariableTypes', {'string', 'logical', 'double', 'double', 'string', 'double'}, ...
    'VariableNames', {'ImageFile', 'PredictedHasPlate', 'CropsFound', 'CropsWithText', 'OCRText', 'OCRConfidence'});

% Loop through each image in the datastore.
for i = 1:N
    imgPath = testDS.Files{i};
    img = imread(imgPath);

    % Initialize variables for the current image.
    predictedHasPlate = false;
    cropsFound = 0;
    cropsWithText = 0;
    ocrText = "N/A";
    ocrConfidence = 0;

    fprintf('\n[%d/%d] %s\n', i, N, imgPath);

    % Use the YOLO model to detect objects.
    [bboxes, scores, labels] = detect(yoloNet, img);

    % Filter detections < 0.5
    confidenceThreshold = 0.5;
    highConfIdx = scores >= confidenceThreshold;
    bboxes = bboxes(highConfIdx, :);
    scores = scores(highConfIdx);
    labels = labels(highConfIdx);

    % Get the bounding boxes for plate candidates.
    plateCandidates = bboxes;
    predictedHasPlate = ~isempty(plateCandidates);

    fprintf('  YOLO Detection -> %d candidate(s) kept (conf >= %.2f).\n', size(plateCandidates, 1), confidenceThreshold);

    if ~predictedHasPlate
        resultsTable(i, :) = {string(imgPath), false, 0, 0, ocrText, ocrConfidence};
        continue;
    end

    statsTotal.predictedHasPlate = statsTotal.predictedHasPlate + 1;
    cropsFound = size(plateCandidates,1);

    [~, baseName, ~] = fileparts(imgPath);
    anyTextThisImage = false;

    % Loop through each detected plate candidate.
    for j = 1:cropsFound
        % Get the bounding box and crop the image with a small border.
        bbox = plateCandidates(j, :);
        x = max(1, round(bbox(1)) - 5);
        y = max(1, round(bbox(2)) - 5);
        w = min(size(img,2) - x + 1, round(bbox(3)) + 10);
        h = min(size(img,1) - y + 1, round(bbox(4)) + 10);

        cropped = img(y:y+h-1, x:x+w-1, :);
        cropName = sprintf('%s_crop_%02d.jpg', baseName, j);
        cropPath = fullfile(outputDir, cropName);
        imwrite(cropped, cropPath);

        % Update total crop count and run OCR.
        statsTotal.totalCrops = statsTotal.totalCrops + 1;

        fprintf('    OCR on %s ... ', cropName);
        ocrRes = runFixedPythonOCR(cropPath);
        fprintf('text="%s"  conf=%.3f\n', ocrRes.text, ocrRes.confidence);

        if ~isempty(strtrim(ocrRes.text))
            anyTextThisImage = true;
            statsTotal.ocrReadWithAnyText = statsTotal.ocrReadWithAnyText + 1;
            cropsWithText = cropsWithText + 1;
            if j == 1
                ocrText = string(ocrRes.text);
                ocrConfidence = ocrRes.confidence;
            end
        end
    end

    if ~anyTextThisImage
        fprintf('  (No readable OCR text for this image.)\n');
    end

    resultsTable(i, :) = {string(imgPath), predictedHasPlate, cropsFound, cropsWithText, ocrText, ocrConfidence};
end

fprintf('\n========== PIPELINE SUMMARY ==========\n');
fprintf('Total images processed:       %d\n', statsTotal.totalImages);
fprintf('Predicted has_plate:          %d\n', statsTotal.predictedHasPlate);
fprintf('Total cropped candidates:     %d\n', statsTotal.totalCrops);
fprintf('Crops with any OCR text:      %d\n', statsTotal.ocrReadWithAnyText);
fprintf('Cropped images saved to:      %s\n', fullfile(pwd, outputDir));
fprintf('======================================\n');

% Save the results table to a CSV file.
csvFileName = 'license_plate_detection_results.csv';
writetable(resultsTable, csvFileName);
fprintf('Results saved to:      %s\n', fullfile(pwd, csvFileName));

% Helper functions
% Helper function to run a Python OCR script.
function ocrResult = runFixedPythonOCR(imagePath)
    try
        cmd = sprintf('python fixed_ocr.py "%s"', imagePath);
        [status, cmdout] = system(cmd);
        if status ~= 0
            error('Python OCR failed: %s', cmdout);
        end
        ocrResult = parseFixedPythonOCROutput(cmdout);
    catch ME
        ocrResult = struct();
        ocrResult.text = '';
        ocrResult.confidence = 0;
        ocrResult.method = 'failed';
        fprintf('OCR Error: %s\n', ME.message);
    end
end

% Helper function to parse the text and confidence from the Python script's output.
function ocrResult = parseFixedPythonOCROutput(cmdout)
    ocrResult = struct();
    ocrResult.text = '';
    ocrResult.confidence = 0;
    ocrResult.method = 'PaddleOCR';
    % Split the output into lines and process each one.
    lines = strsplit(cmdout, '\n');
    for i = 1:length(lines)
        line = strtrim(lines{i});
        if startsWith(line, 'TEXT:')
            ocrResult.text = strtrim(line(6:end));
        elseif startsWith(line, 'CONFIDENCE:')
            val = str2double(line(12:end));
            if ~isnan(val)
                ocrResult.confidence = val;
            end
        end
    end
end