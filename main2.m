
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


if ~isfile("yolo_license_plate_v2.mat")
    error('yolo_license_plate_v2.mat not found in current folder. Please ensure the model file is in the current working directory.');
end

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

if ~isfile('fixed_ocr.py')
    error('fixed_ocr.py not found in current folder.');
end

N = numel(testDS.Files);
fprintf('Found %d test images.\n', N);

statsTotal.totalImages        = N;
statsTotal.predictedHasPlate  = 0;
statsTotal.totalCrops         = 0;
statsTotal.ocrReadWithAnyText = 0;

resultsTable = table('Size', [N, 6], ...
    'VariableTypes', {'string', 'logical', 'double', 'double', 'string', 'double'}, ...
    'VariableNames', {'ImageFile', 'PredictedHasPlate', 'CropsFound', 'CropsWithText', 'OCRText', 'OCRConfidence'});

for i = 1:N
    imgPath = testDS.Files{i};
    img = imread(imgPath);

    predictedHasPlate = false;
    cropsFound = 0;
    cropsWithText = 0;
    ocrText = "N/A";
    ocrConfidence = 0;

    fprintf('\n[%d/%d] %s\n', i, N, imgPath);

    [bboxes, scores, labels] = detect(yoloNet, img);

    confidenceThreshold = 0.5;
    highConfIdx = scores >= confidenceThreshold;
    bboxes = bboxes(highConfIdx, :);
    scores = scores(highConfIdx);
    labels = labels(highConfIdx);

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

    for j = 1:cropsFound
        bbox = plateCandidates(j, :);
        x = max(1, round(bbox(1)) - 5);
        y = max(1, round(bbox(2)) - 5);
        w = min(size(img,2) - x + 1, round(bbox(3)) + 10);
        h = min(size(img,1) - y + 1, round(bbox(4)) + 10);

        cropped = img(y:y+h-1, x:x+w-1, :);
        cropName = sprintf('%s_crop_%02d.jpg', baseName, j);
        cropPath = fullfile(outputDir, cropName);
        imwrite(cropped, cropPath);

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

csvFileName = 'license_plate_detection_results.csv';
writetable(resultsTable, csvFileName);
fprintf('Results saved to:      %s\n', fullfile(pwd, csvFileName));

%% Helper functions
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

function ocrResult = parseFixedPythonOCROutput(cmdout)
    ocrResult = struct();
    ocrResult.text = '';
    ocrResult.confidence = 0;
    ocrResult.method = 'PaddleOCR';
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
