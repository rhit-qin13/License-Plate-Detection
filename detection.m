%% Detection Functions 

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

% Optimized detection function (tunable parameters)
function [plateCandidates, processedImages] = detectPlates_Optimized(img, params)
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
        
        if area > params.minArea && area < params.maxArea && ...
           circularity < params.maxCircularity && ...
           eccentricity > params.minEccentricity && ...
           aspectRatio > params.minAspectRatio && aspectRatio < params.maxAspectRatio
            plateCandidates = [plateCandidates; bbox];
        end
    end
    
    processedImages.original = img;
    processedImages.gray = grayImg;
    processedImages.edges = edges;
    processedImages.closedEdges = closedEdges;
end

fprintf('Detection functions loaded\n');