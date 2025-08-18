clear;

datasetFolder = 'License Plate Detection.v3i.voc';  
trainFolder = fullfile(datasetFolder, 'train');
validateFolder = fullfile(datasetFolder, 'validate');
testFolder = fullfile(datasetFolder, 'test');
function [imagePaths,  boundingBoxLabels] = parseVOCAnnotations(imageFolder, annotationFolder)
    imagePaths = {};
    boundingBoxLabels = {};

    xmlFiles = dir(fullfile(annotationFolder, '*.xml'));
    
    for i = 1:length(xmlFiles)
        xmlFile = fullfile(annotationFolder, xmlFiles(i).name);
        
        doc = xmlread(xmlFile);
        
        imageName = char(doc.getElementsByTagName('filename').item(0).getFirstChild.getData);
        imagePath = fullfile(imageFolder, imageName);
        

        objects = doc.getElementsByTagName('object');
        numObjects = objects.getLength;
        boundingBoxes = [];
        
        for j = 0:numObjects-1

            className = char(objects.item(j).getElementsByTagName('name').item(0).getFirstChild.getData);
            

            if strcmp(className, 'license')

                bndbox = objects.item(j).getElementsByTagName('bndbox').item(0);
                xmin = str2double(bndbox.getElementsByTagName('xmin').item(0).getFirstChild.getData);
                ymin = str2double(bndbox.getElementsByTagName('ymin').item(0).getFirstChild.getData);
                xmax = str2double(bndbox.getElementsByTagName('xmax').item(0).getFirstChild.getData);
                ymax = str2double(bndbox.getElementsByTagName('ymax').item(0).getFirstChild.getData);
                

                boundingBoxes = [boundingBoxes; xmin, ymin, xmax - xmin, ymax - ymin];
            end
        end
        

        if ~isempty(boundingBoxes)
            imagePaths{end+1} = imagePath;
            boundingBoxLabels{end+1} = boundingBoxes;
        end
    end
end
function datastore = createBoundingBoxDatastore(imageTable)
    imageFiles = imageTable.ImageFilename;
    boundingBoxes = imageTable.BoundingBoxes;

    boxTable = table(boundingBoxes, 'VariableNames', {'BoundingBoxes'});

    imds = imageDatastore(imageFiles);

    boxLabels = boxLabelDatastore(boxTable);


    datastore = combine(imds, boxLabels);
end

[trainImages, trainBboxes] = parseVOCAnnotations(trainFolder, trainFolder);


trainData = table(trainImages', trainBboxes', 'VariableNames', {'ImageFilename', 'BoundingBoxes'});


I = imread(trainData.ImageFilename{1});
bBox = trainData.BoundingBoxes{1};
I = insertShape(I, 'Rectangle', bBox, 'LineWidth', 5);
imshow(I);
title('First Image with Bounding Boxes');


trainDatastore = createBoundingBoxDatastore(trainData);

anchorBoxes = estimateAnchorBoxes(trainDatastore, 9);

layerGraph = yolov2Layers([416 416 3], 1, anchorBoxes, 'resnet50');

options = trainingOptions('sgdm', ...
    'MiniBatchSize', 16, ...
    'InitialLearnRate', 1e-3, ...
    'MaxEpochs', 30, ...
    'ValidationData', [], ...
    'VerboseFrequency', 10, ...
    'Plots', 'training-progress');

detector = trainYOLOv2ObjectDetector(trainDatastore, layerGraph, options);

save('licensePlateDetector.mat', 'detector');

testImage = imread('archive (1)\plate-license-5\test\has_license_plate\0_3_hr_png_jpg.rf.c679897f52689da139e29adc623291fd.jpg');
[boundingBoxes, scores, labels] = detect(detector, testImage);

detectedImg = insertObjectAnnotation(testImage, 'rectangle', boundingBoxes, scores);
imshow(detectedImg);
title('Detected License Plates');