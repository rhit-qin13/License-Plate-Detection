
if ~exist('trainDS', 'var')
    run('main.m');
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

% test:
detectionRate = detectionCount / testImages;
avgDetectionsPerImage = totalDetections / testImages;
fprintf('STATS\n');
fprintf('Tested on %d images\n', testImages);
fprintf('Images with detections: %d (%.1f%%)\n', detectionCount, detectionRate*100);
fprintf('Total detections found: %d\n', totalDetections);
fprintf('Average detections per image: %.2f\n', avgDetectionsPerImage);

nTotal = nTrain + nTest + nValid;
fprintf('\nDATASET STATS\n');
fprintf('Training: %d images (%.1f%%)\n', nTrain, 100*nTrain/nTotal);
fprintf('Testing: %d images (%.1f%%)\n', nTest, 100*nTest/nTotal);
fprintf('Validation: %d images (%.1f%%)\n', nValid, 100*nValid/nTotal);
fprintf('Total: %d images\n', nTotal);

fprintf('PLATE EXTRACTION STATS\n');
fprintf('Cropped plates saved: %d\n', plateCount);
fprintf('Plates saved to: cropped_plates/ folder\n');

plateFiles = dir('cropped_plates/*.jpg');
fprintf('Files in cropped_plates folder: %d\n', length(plateFiles));

fprintf('\nSUMMARY\n');
fprintf('Detection success rate: %.1f%%\n', (detectionCount/testImages)*100);
fprintf('Plates extracted and saved: %d\n', plateCount);
fprintf('Preprocessing analysis completed on: %d sample plates\n', sampleCount);