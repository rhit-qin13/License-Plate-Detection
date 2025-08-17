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


trainDS = imageDatastore("archive (1)\plate-license-5\train\", 'IncludeSubfolders', true);
testDS = imageDatastore("archive (1)\plate-license-5\test\", 'IncludeSubfolders', true);
validDS = imageDatastore("archive (1)\plate-license-5\valid\", 'IncludeSubfolders', true);

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

