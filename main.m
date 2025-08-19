%% CSSE463 License Plate Detection - License Plates Detection
% Dataset: Plate License Recognition Dataset by Mohamed Gobara (Kaggle)
% Date: August 03, 2025
clear;
%% Week 7 work below
%% Bhargav Nagalamadaka
% Dataset setup and basic preprocessing
%% Umesh Sarma 
% Detection algorithm with filtering
%% Mingjian Qin
% Batch testing, plate cropping, character extraction
%% Week 8 Plan Below:
%% Mingjian Qin
% Parameter Optimization Building on existing detectPlates function and batch test results
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
if ~isfile("trainedLicensePlateDetectionNet.mat")
    error('trainedLicensePlateDetectionNet.mat not found in current folder.');
end
S = load("trainedLicensePlateDetectionNet.mat");  
fn = fieldnames(S);
trainedNet = S.(fn{1});  
inputSize = [];
try
    inputSize = trainedNet.Layers(1).InputSize(1:2);
catch
    
    try
        inputSize = trainedNet.InputSize(1:2);
    catch
        inputSize = [];
    end
end
if isfile('optimized_params.mat')
    load('optimized_params.mat', 'bestParams');
    params = bestParams;
    fprintf('Using optimized detection parameters.\n');
else
    params = struct();
    params.minArea         = 600;
    params.maxArea         = Inf;
    params.maxCircularity  = 0.5;
    params.minEccentricity = 0.7;
    params.minAspectRatio  = 1.8;
    params.maxAspectRatio  = 5.5;
    fprintf('Using default detection parameters.\n');
end
whichDetect = which('detectPlates_Optimized.m');
if isempty(whichDetect)
    error('detectPlates_Optimized.m must be on the MATLAB path.');
end
if ~isfile('fixed_ocr.py')
    error('fixed_ocr.py not found in current folder.');
end
N = numel(testDS.Files);
fprintf('Found %d test images.\n', N);
statsTotal.totalImages           = N;
statsTotal.predictedHasPlate     = 0;
statsTotal.totalCrops            = 0;
statsTotal.ocrReadWithAnyText    = 0;

% Initialize a table to store the results
resultsTable = table('Size', [N, 6], ...
    'VariableTypes', {'string', 'logical', 'double', 'double', 'string', 'double'}, ...
    'VariableNames', {'ImageFile', 'PredictedHasPlate', 'CropsFound', 'CropsWithText', 'OCRText', 'OCRConfidence'});

for i = 1:2:N
    imgPath = testDS.Files{i};
    [img, ~] = readimage(testDS, i);
    imgForNet = img;
    if ~isempty(inputSize)
        imgForNet = imresize(img, inputSize);
    end

    predictedHasPlate = false;
    cropsFound = 0;
    cropsWithText = 0;
    ocrText = "N/A";
    ocrConfidence = 0;

    try
        [label, scores] = classify(trainedNet, imgForNet);
    catch ME
        warning('Classification failed for %s: %s', imgPath, ME.message);
        continue;
    end
    labelStr = string(label);
    predictedHasPlate = contains(lower(labelStr), "has");  
    fprintf('\n[%d/%d] %s\n', i, N, imgPath);
    fprintf('  Presence CNN -> %s  (max score = %.3f)\n', labelStr, max(scores));

    if ~predictedHasPlate
        resultsTable(i, :) = {string(imgPath), predictedHasPlate, cropsFound, cropsWithText, ocrText, ocrConfidence};
        continue;
    end
    statsTotal.predictedHasPlate = statsTotal.predictedHasPlate + 1;
    
    try
        [plateCandidates, ~] = detectPlates_Optimized(img, params);
    catch ME
        warning('detectPlates_Optimized failed for %s: %s', imgPath, ME.message);
        resultsTable(i, :) = {string(imgPath), predictedHasPlate, cropsFound, cropsWithText, ocrText, ocrConfidence};
        continue;
    end
    
    if isempty(plateCandidates)
        fprintf('  No plate candidates found.\n');
        resultsTable(i, :) = {string(imgPath), predictedHasPlate, cropsFound, cropsWithText, ocrText, ocrConfidence};
        continue;
    end
    
    cropsFound = size(plateCandidates,1);
    fprintf('  Found %d candidate region(s).\n', cropsFound);
    [~, baseName, ~] = fileparts(imgPath);
    anyTextThisImage = false;

    % Process all candidates, but only log the first one's OCR to the table
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
        fprintf('  (No readable text returned for this image.)\n');
    end

    % Add the final results for this image to the table
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
        try
            ocrResult.confidence = str2double(line(12:end));
        catch
            ocrResult.confidence = 0;
        end
    end
end
end