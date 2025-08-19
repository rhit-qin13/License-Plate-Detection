clear;
clc;

%% Load trained detector
S = load('yolo_license_plate_v2.mat'); 
detector = S.trainedDetector;  % <-- use the correct field name


%% Define test folder and class
testDir = 'C:/Users/sarmau/Image Recognition/License Plate Detection/License Plate Detection.v3i.voc/test';
classNames = {'license'};

%% Parse test VOC folder
testTbl = parseVOCFolder(testDir);
fprintf('Loaded %d test images\n', height(testTbl));

%% Create test datastores
imdsTest = imageDatastore(testTbl.imageFilename);
bldsTest = boxLabelDatastore(testTbl(:, "license"));
testData = combine(imdsTest, bldsTest);

%% Run detector on test set
detectionResults = detect(detector, imdsTest, 'MiniBatchSize', 10);

%% Evaluate detection precision (using IoU threshold 0.5)
[ap, recall, precision] = evaluateDetectionPrecision(detectionResults, bldsTest);

%% Print results
fprintf('Test Average Precision (AP) at IoU=0.5: %.2f%%\n', ap*100);

%% ---------------------------
%% Parser function for VOC folder
function T = parseVOCFolder(folderPath)
    xmlFiles = dir(fullfile(folderPath, '*.xml'));
    imageFilename = strings(0,1);
    license = {};

    for i = 1:numel(xmlFiles)
        xmlPath = fullfile(folderPath, xmlFiles(i).name);
        try
            doc = xmlread(xmlPath);
        catch
            continue;
        end

        fnameNode = doc.getElementsByTagName('filename').item(0);
        if isempty(fnameNode), continue; end
        fname = char(fnameNode.getFirstChild.getData);
        imgPath = fullfile(folderPath, fname);
        if ~isfile(imgPath)
            [stem,~] = fileparts(fname);
            alt = dir(fullfile(folderPath, [stem '.*']));
            if isempty(alt), continue; end
            imgPath = fullfile(folderPath, alt(1).name);
        end

        objects = doc.getElementsByTagName('object');
        boxes = [];
        for j = 0:objects.getLength-1
            obj = objects.item(j);
            name = char(obj.getElementsByTagName('name').item(0).getFirstChild.getData);
            if strcmpi(name,'license')
                bnd = obj.getElementsByTagName('bndbox').item(0);
                xmin = str2double(bnd.getElementsByTagName('xmin').item(0).getFirstChild.getData);
                ymin = str2double(bnd.getElementsByTagName('ymin').item(0).getFirstChild.getData);
                xmax = str2double(bnd.getElementsByTagName('xmax').item(0).getFirstChild.getData);
                ymax = str2double(bnd.getElementsByTagName('ymax').item(0).getFirstChild.getData);
                boxes = [boxes; xmin, ymin, xmax-xmin, ymax-ymin];
            end
        end

        if ~isempty(boxes)
            imageFilename(end+1,1) = string(imgPath);
            license{end+1,1} = boxes;
        end
    end

    T = table(imageFilename, license);
end
