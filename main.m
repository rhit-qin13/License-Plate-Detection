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



trainDS = imageDatastore("archive (1)\plate-license-5\train\");
testDS = imageDatastore("archive (1)\plate-license-5\test\");
validDS = imageDatastore("archive (1)\plate-license-5\valid\");

function readImages(dataStore)
 nImages = numel(dataStore.Files);
for i = 1:nImages
 [img, fileInfo] = readimage(dataStore, i);
 grayImg = rgb2gray(img);
 smoothImg= imgaussfilt(grayImg,3);
%imtool(img);
%imtool(smoothImg);
end
end

readImages(trainDS);



function readImages_Advanced(dataStore)
    nImages = numel(dataStore.Files);
    %for i = 1:nImages
   for i = 1:1  
        img = readimage(dataStore, i);
        grayImg = rgb2gray(img);
        smoothImg = imgaussfilt(grayImg, 3);
        
        edges = edge(smoothImg, 'Canny');
        
        se = strel('rectangle', [5, 15]);
        closedEdges = imclose(edges, se);
        
        cc = bwconncomp(closedEdges);
        stats = regionprops(cc, 'BoundingBox', 'Area', 'Perimeter', 'Eccentricity');
        
        plateCandidates = [];
        
        % shape properties
        for k = 1:length(stats)
            area = stats(k).Area;
            perimeter = stats(k).Perimeter;
            bbox = stats(k).BoundingBox;
            eccentricity = stats(k).Eccentricity;
            
            circularity = 4 * pi * area / (perimeter^2);
            aspectRatio = bbox(3) / bbox(4);  
            
            if area > 500 && ...             
               circularity < 0.5 && ...       
               eccentricity > 0.7 && ...      
               aspectRatio > 2 && aspectRatio < 5   
                
                plateCandidates = [plateCandidates; bbox];
            end
        end
        
        % Show original image plus edges and stuff
        figure; imshow(img);
        title(['Detected License Plates in Image ', num2str(i)]);
        hold on;
        for j = 1:size(plateCandidates, 1)
            rectangle('Position', plateCandidates(j, :), 'EdgeColor', 'r', 'LineWidth', 2);
        end
        hold off;
        figure; imshow(closedEdges);
        title(['Edges after Morphological Closing - Image ', num2str(i)]);
    end
end

readImages_Advanced(trainDS);


function [plateCandidates, processedImages] = detectPlates(img)
    grayImg = rgb2gray(img);
    smoothImg = imgaussfilt(grayImg, 3);
    edges = edge(smoothImg, 'Canny');
    
    se = strel('rectangle', [5, 15]);
    closedEdges = imclose(edges, se);
    
    cc = bwconncomp(closedEdges);
    stats = regionprops(cc, 'BoundingBox', 'Area', 'Perimeter', 'Eccentricity');
    
    plateCandidates = [];
    for k = 1:length(stats)
        area = stats(k).Area;
        perimeter = stats(k).Perimeter;
        bbox = stats(k).BoundingBox;
        eccentricity = stats(k).Eccentricity;
        
        circularity = 4 * pi * area / (perimeter^2);
        aspectRatio = bbox(3) / bbox(4);
        
        if area > 500 && circularity < 0.5 && eccentricity > 0.7 && aspectRatio > 2 && aspectRatio < 5
            plateCandidates = [plateCandidates; bbox];
        end
    end
    
    processedImages.original = img;
    processedImages.gray = grayImg;
    processedImages.edges = edges;
    processedImages.closedEdges = closedEdges;
end

% Batch testing on multiple images
testImages = min(20, numel(trainDS.Files));
detectionCount = 0;
totalDetections = 0;

for i = 1:testImages
    img = readimage(trainDS, i);
    [plateCandidates, ~] = detectPlates(img);
    
    if size(plateCandidates, 1) > 0
        detectionCount = detectionCount + 1;
    end
    totalDetections = totalDetections + size(plateCandidates, 1);
end

% Crop and save detected plates
if ~exist('cropped_plates', 'dir')
    mkdir('cropped_plates');
end

plateCount = 0;
for i = 1:min(30, numel(trainDS.Files)) 
    img = readimage(trainDS, i);
    [plateCandidates, ~] = detectPlates(img);
    
    for j = 1:size(plateCandidates, 1)
        bbox = plateCandidates(j, :);
        
        % Extract plate with padding
        x = max(1, round(bbox(1)) - 5);
        y = max(1, round(bbox(2)) - 5);
        w = min(size(img,2) - x, round(bbox(3)) + 10);
        h = min(size(img,1) - y, round(bbox(4)) + 10);
        
        plateImg = img(y:y+h-1, x:x+w-1, :);
        
        plateCount = plateCount + 1;
        filename = sprintf('plate_%04d.jpg', plateCount);
        imwrite(plateImg, fullfile('cropped_plates', filename));
    end
end

% preprocessing analysis on sample plates
sampleCount = 0;
for i = 1:min(10, numel(trainDS.Files))
    if sampleCount >= 3; break; end
    
    img = readimage(trainDS, i);
    [plateCandidates, ~] = detectPlates(img);
    
    for j = 1:size(plateCandidates, 1)
        if sampleCount >= 3; break; end
        
        bbox = plateCandidates(j, :);
        x = max(1, round(bbox(1)) - 5);
        y = max(1, round(bbox(2)) - 5);
        w = min(size(img,2) - x, round(bbox(3)) + 10);
        h = min(size(img,1) - y, round(bbox(4)) + 10);
        plateImg = img(y:y+h-1, x:x+w-1, :);
        
        sampleCount = sampleCount + 1;
        
        grayPlate = rgb2gray(plateImg);
        hsvPlate = rgb2hsv(plateImg);
        cannyEdges = edge(grayPlate, 'Canny');
        sobelEdges = edge(grayPlate, 'Sobel');
        
        % MO 
        se_rect = strel('rectangle', [2, 6]);
        closedImg = imclose(cannyEdges, se_rect);
        
        % Character segmentation
        cc = bwconncomp(~closedImg);  
        charStats = regionprops(cc, 'BoundingBox', 'Area');
        
        % Display preprocessing results
        figure('Position', [100, 100, 1000, 600]);
        subplot(2,4,1); imshow(plateImg); title('Original Plate');
        subplot(2,4,2); imshow(hsvPlate(:,:,3)); title('HSV Value');
        subplot(2,4,3); imshow(cannyEdges); title('Canny Edges');
        subplot(2,4,4); imshow(sobelEdges); title('Sobel Edges');
        subplot(2,4,5); imshow(closedImg); title('Morphological Close');
        subplot(2,4,6); imshow(~closedImg); title('Character Regions');
        
        % Show character candidates
        subplot(2,4,7); imshow(plateImg); title('Character Candidates');
        hold on;
        for k = 1:length(charStats)
            if charStats(k).Area > 30 && charStats(k).Area < 1000
                rectangle('Position', charStats(k).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 1);
            end
        end
        hold off;
        
        subplot(2,4,8); histogram(grayPlate(:), 30); title('Intensity Distribution');
    end
end

% Dataset statistics
nTrain = numel(trainDS.Files);
nTest = numel(testDS.Files);
nValid = numel(validDS.Files);