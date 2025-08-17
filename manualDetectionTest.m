function manualDetectionTest()
    % Manual Detection Scoring Test
    % Tests how well the automated detection crops license plates
    
    fprintf('MANUAL DETECTION TEST \n');
    
    % Setup paths
    plateDataPath = 'C:\Users\billq\OneDrive\Documents\MATLAB\License Plates Detection\License-Plate-Detection\archive (1)\plate-license-5\test\has_license_plate';
    outputPath = 'C:\Users\billq\OneDrive\Documents\MATLAB\License Plates Detection\License-Plate-Detection\cropped_plates';
    
    % Check if input folder exists
    if ~exist(plateDataPath, 'dir')
        fprintf('ERROR: Input folder not found\n');
        return;
    end
    
    % Create output folder if it doesn't exist
    if ~exist(outputPath, 'dir')
        mkdir(outputPath);
    end
    
    % Get all image files
    imageFiles = [dir(fullfile(plateDataPath, '*.jpg')); ...
                  dir(fullfile(plateDataPath, '*.png')); ...
                  dir(fullfile(plateDataPath, '*.jpeg'))];
    
    if isempty(imageFiles)
        fprintf('ERROR: No image files found\n');
        return;
    end
    
    fprintf('Found %d images\n', length(imageFiles));
    
    % Ask user how many to test
    numToTest = min(10, length(imageFiles));
    userInput = input(sprintf('How many images to test? (max %d, press Enter for %d): ', length(imageFiles), numToTest), 's');
    if ~isempty(userInput)
        numToTest = min(str2double(userInput), length(imageFiles));
    end
    
    % Load detection parameters
    if exist('optimized_params.mat', 'file')
        load('optimized_params.mat', 'bestParams');
        params = bestParams;
        fprintf('Using optimized detection parameters\n');
    else
        % Use default parameters
        params = struct();
        params.minArea = 600;
        params.maxArea = Inf;
        params.maxCircularity = 0.5;
        params.minEccentricity = 0.7;
        params.minAspectRatio = 1.8;
        params.maxAspectRatio = 5.5;
        fprintf('Using default detection parameters\n');
    end
    
    fprintf('\nStarting detection scoring on %d images\n', numToTest);
    
    % Initialize results tracking
    results = struct();
    results.totalTested = 0;
    results.totalDetections = 0;
    results.goodDetections = 0;
    results.details = {};
    
    % Process each image
    for i = 1:numToTest
        imageFile = imageFiles(i);
        fullImagePath = fullfile(plateDataPath, imageFile.name);
        
        fprintf('\nImage %d/%d: %s\n', i, numToTest, imageFile.name);
        
        try
            % Load image
            originalImg = imread(fullImagePath);
            
            % Run automated detection
            [candidates, ~] = detectPlates_Optimized(originalImg, params);
            numDetections = size(candidates, 1);
            
            fprintf('Automated detection found: %d candidates\n', numDetections);
            
            if numDetections == 0
                fprintf('No detections found - skipping\n');
                results.totalTested = results.totalTested + 1;
                continue;
            end
            
            % Show original image with detection boxes
            figure(1);
            clf;
            imshow(originalImg);
            title(sprintf('Image %d/%d: %s - %d detections', i, numToTest, imageFile.name, numDetections), 'Interpreter', 'none');
            hold on;
            
            % Draw detection boxes
            for j = 1:numDetections
                rectangle('Position', candidates(j, :), 'EdgeColor', 'red', 'LineWidth', 2);
                text(candidates(j, 1), candidates(j, 2)-10, sprintf('%d', j), 'Color', 'red', 'FontSize', 14, 'FontWeight', 'bold');
            end
            hold off;
            
            % Test each detection
            imageGoodDetections = 0;
            for j = 1:numDetections
                fprintf('\nTesting detection %d of %d\n', j, numDetections);
                
                % Extract detected region
                bbox = candidates(j, :);
                x = max(1, round(bbox(1)) - 5);
                y = max(1, round(bbox(2)) - 5);
                w = min(size(originalImg,2) - x + 1, round(bbox(3)) + 10);
                h = min(size(originalImg,1) - y + 1, round(bbox(4)) + 10);
                
                croppedPlate = originalImg(y:y+h-1, x:x+w-1, :);
                
                % Save cropped plate
                croppedFileName = sprintf('auto_detection_%03d_%d.jpg', i, j);
                croppedFilePath = fullfile(outputPath, croppedFileName);
                imwrite(croppedPlate, croppedFilePath);
                
                % Show cropped result
                figure(2);
                clf;
                imshow(croppedPlate);
                title(sprintf('Detection %d: %s (Size: %dx%d)', j, croppedFileName, size(croppedPlate,2), size(croppedPlate,1)), 'Interpreter', 'none');
                
                % Ask user to rate the detection quality
                fprintf('Rate this detection:\n');
                fprintf('1 = Perfect license plate crop\n');
                fprintf('2 = Good license plate crop\n');
                fprintf('3 = Partial license plate crop\n');
                fprintf('4 = Not a license plate\n');
                
                validRating = false;
                while ~validRating
                    userRating = input('Enter rating (1-4): ');
                    if ismember(userRating, [1, 2, 3, 4])
                        validRating = true;
                    else
                        fprintf('Please enter a number between 1 and 4\n');
                    end
                end
                
                % Convert rating to success status
                switch userRating
                    case 1
                        detectionSuccess = true;
                        ratingText = 'Perfect';
                    case 2
                        detectionSuccess = true;
                        ratingText = 'Good';
                    case 3
                        detectionSuccess = false;
                        ratingText = 'Partial';
                    case 4
                        detectionSuccess = false;
                        ratingText = 'Not a plate';
                end
                
                fprintf('You rated this as: %s\n', ratingText);
                
                % Update counters
                results.totalDetections = results.totalDetections + 1;
                if detectionSuccess
                    results.goodDetections = results.goodDetections + 1;
                    imageGoodDetections = imageGoodDetections + 1;
                end
                
                % Store details
                results.details{end+1} = struct(...
                    'filename', imageFile.name, ...
                    'imageNumber', i, ...
                    'detectionNumber', j, ...
                    'croppedFile', croppedFileName, ...
                    'userRating', userRating, ...
                    'ratingText', ratingText, ...
                    'isGood', detectionSuccess, ...
                    'plateSize', [size(croppedPlate,2), size(croppedPlate,1)]);
            end
            
            results.totalTested = results.totalTested + 1;
            fprintf('Image summary: %d good detections out of %d total\n', imageGoodDetections, numDetections);
            
            % Ask user if they want to continue
            if i < numToTest
                continueChoice = input('Continue to next image? (y/n, press Enter for yes): ', 's');
                if strcmpi(continueChoice, 'n')
                    fprintf('Stopping at user request\n');
                    break;
                end
            end
            
        catch ME
            fprintf('Error processing image %d: %s\n', i, ME.message);
            results.totalTested = results.totalTested + 1;
        end
    end
    
    % Display final summary
    displayDetectionSummary(results);
    
    % Save results
    save('detection_test_results.mat', 'results');
    fprintf('\nResults saved to detection_test_results.mat\n');
    
    close all;
end

function displayDetectionSummary(results)
    % Display final summary of detection performance
    
    fprintf('\n DETECTION SCORING RESULTS \n');
    fprintf('Total images tested: %d\n', results.totalTested);
    fprintf('Total detections found: %d\n', results.totalDetections);
    fprintf('Good detections: %d\n', results.goodDetections);
    
    if results.totalDetections > 0
        % Calculate rating distribution
        perfect = 0;
        good = 0;
        partial = 0;
        notPlate = 0;
        
        for i = 1:length(results.details)
            switch results.details{i}.userRating
                case 1
                    perfect = perfect + 1;
                case 2
                    good = good + 1;
                case 3
                    partial = partial + 1;
                case 4
                    notPlate = notPlate + 1;
            end
        end
        
        fprintf('\nRating Distribution:\n');
        fprintf('Perfect crops: %d (%.1f%%)\n', perfect, (perfect/results.totalDetections)*100);
        fprintf('Good crops: %d (%.1f%%)\n', good, (good/results.totalDetections)*100);
        fprintf('Partial crops: %d (%.1f%%)\n', partial, (partial/results.totalDetections)*100);
        fprintf('Not license plates: %d (%.1f%%)\n', notPlate, (notPlate/results.totalDetections)*100);
        
        % Calculate success rate
        successRate = results.goodDetections / results.totalDetections;
        fprintf('\nDetection Success Rate: %.1f%% (%d/%d)\n', successRate*100, results.goodDetections, results.totalDetections);
        
        % Determine grade
        if successRate >= 0.9
            grade = 'EXCELLENT';
        elseif successRate >= 0.75
            grade = 'GOOD';
        elseif successRate >= 0.5
            grade = 'FAIR';
        else
            grade = 'NEEDS IMPROVEMENT';
        end
        
        fprintf('Detection Performance: %s\n', grade);
    end
    
    fprintf('\n Detailed Results \n');
    for i = 1:length(results.details)
        detail = results.details{i};
        if detail.detectionNumber == 1
            fprintf('%d. %s:\n', detail.imageNumber, detail.filename);
        end
        
        fprintf('   Detection %d -> %s (%s)\n', detail.detectionNumber, detail.croppedFile, detail.ratingText);
        fprintf('   Size: %dx%d\n', detail.plateSize(1), detail.plateSize(2));
    end
    
    fprintf('\nAll cropped detections saved to cropped_plates folder\n');
    
    % Final score
    if results.totalDetections > 0
        successRate = results.goodDetections / results.totalDetections;
        
        fprintf('\n FINAL SCORE \n');
        fprintf('Detection Success Rate: %.1f%%\n', successRate*100);
        fprintf('Performance Grade: %s\n', grade);
        
        if successRate >= 0.9
            letterGrade = 'A';
        elseif successRate >= 0.8
            letterGrade = 'B';
        elseif successRate >= 0.7
            letterGrade = 'C';
        elseif successRate >= 0.6
            letterGrade = 'D';
        else
            letterGrade = 'F';
        end
        
        fprintf('Letter Grade: %s\n', letterGrade);
    end
end