function manualOCRTest()
    % Manual OCR Test
    % - Shows images from test/ has_license_plate folder
    % - selects license plate region(s)
    % - Saves cropped plate to cropped_plates folder  
    % - Runs OCR and shows detailed results
    % - you rate them
    % - generate a success rate report when done
    
    
    fprintf('manual OCR test\n');
    
    % Setup paths
    plateDataPath = 'C:\Users\billq\OneDrive\Documents\MATLAB\License Plates Detection\License-Plate-Detection\archive (1)\plate-license-5\test\has_license_plate';
    outputPath = 'C:\Users\billq\OneDrive\Documents\MATLAB\License Plates Detection\License-Plate-Detection\cropped_plates';
    
    % Check if input folder exists
    if ~exist(plateDataPath, 'dir')
        fprintf('ERROR: Input folder not found:\n%s\n', plateDataPath);
        return;
    end
    
    % Create output folder if it doesn't exist
    if ~exist(outputPath, 'dir')
        mkdir(outputPath);
        fprintf('Created output folder: %s\n', outputPath);
    end
    
    % Get all image files
    imageFiles = [dir(fullfile(plateDataPath, '*.jpg')); ...
                  dir(fullfile(plateDataPath, '*.png')); ...
                  dir(fullfile(plateDataPath, '*.jpeg'))];
    
    if isempty(imageFiles)
        fprintf('ERROR: No image files found in:\n%s\n', plateDataPath);
        return;
    end
    
    fprintf('Found %d images in has_license_plate folder\n', length(imageFiles));
    
    % Ask user how many to test
    numToTest = min(10, length(imageFiles));
    userInput = input(sprintf('How many images to test? (max %d, press Enter for %d): ', length(imageFiles), numToTest), 's');
    if ~isempty(userInput)
        numToTest = min(str2double(userInput), length(imageFiles));
    end
    
    fprintf('\nStarting manual OCR testing on %d images\n', numToTest);
    fprintf('For each image:\n');
    fprintf('1. Select license plate region by clicking and dragging\n');
    fprintf('2. Cropped plate will be saved to cropped_plates folder\n');
    fprintf('3. OCR will be performed and results displayed in a new tab \n\n');

    
    % Initialize results tracking with scoring system
    results = struct();
    results.totalTested = 0;
    results.successful = 0;
    results.failed = 0;
    results.totalPlatesDetected = 0;
    results.totalPlatesSuccessful = 0;
    results.details = {};
    results.scoringEnabled = true;
    
    % Check if Python OCR script exists
    if ~exist('fixed_ocr.py', 'file')
        fprintf('ERROR: fixed_ocr.py not found!\n');
        return;
    else
        fprintf('Using: fixed_ocr.py\n');
    end
    
    % Process each image
    for i = 1:numToTest
        imageFile = imageFiles(i);
        fullImagePath = fullfile(plateDataPath, imageFile.name);
        
        fprintf('\n Image %d/%d: %s \n', i, numToTest, imageFile.name);
        
        try
            % Load and display image
            originalImg = imread(fullImagePath);
            
            figure(1);
            clf;
            imshow(originalImg);
            title(sprintf('Image %d/%d: %s - Select License Plate Region(s)', i, numToTest, imageFile.name), 'Interpreter', 'none');
            
            fprintf('Select the license plate region(s) by \n');
            fprintf('- Click and drag to select each license plate\n');
            fprintf('- You can select multiple plates in one image\n');
            fprintf('- Press ESC or close the selection tool when finished\n');
            
            % Handle multiple license plates
            plateCount = 0;
            allOCRResults = {};
            
            while true
                plateCount = plateCount + 1;
                
                % Refresh the original image display for each new selection
                figure(1);
                clf;
                imshow(originalImg);
                title(sprintf('Image %d/%d: %s - Select Plate #%d', i, numToTest, imageFile.name, plateCount), 'Interpreter', 'none');
                
                % User selects license plate region
                fprintf('Select license plate #%d (or close the window if you finish this image)\n', plateCount);
                
                try
                    roi = drawrectangle('Color', 'red', 'LineWidth', 2);
                    wait(roi);
                    
                    % Check if user actually made a selection
                    if isempty(roi.Position) || any(roi.Position(3:4) <= 0)
                        fprintf('Invalid selection, finishing this image\n');
                        break;
                        
                % Ask if user wants to select another plate in this image
                moreChoice = input('Select another license plate in this image? (y/n, press Enter for no): ', 's');
                if ~strcmpi(moreChoice, 'y')
                    break;
                end
            end
                    
                catch
                    % User closed the rectangle
                    fprintf('Selection cancelled or finished\n');
                    break;
                end
                
                % Get coordinates and crop
                position = roi.Position;
                x = max(1, round(position(1)));
                y = max(1, round(position(2)));
                w = round(position(3));
                h = round(position(4));
                
                plateImg = originalImg(y:y+h-1, x:x+w-1, :);
                
                % Save cropped plate
                if plateCount == 1
                    croppedFileName = sprintf('manual_plate_%03d.jpg', i);
                else
                    croppedFileName = sprintf('manual_plate_%03d_%d.jpg', i, plateCount);
                end
                croppedFilePath = fullfile(outputPath, croppedFileName);
                imwrite(plateImg, croppedFilePath);
                
                fprintf('Cropped plate saved: %s\n', croppedFileName);
                fprintf('Size: %dx%d pixels\n', size(plateImg,2), size(plateImg,1));
                
                % Show cropped plate
                figure(2);
                clf;
                imshow(plateImg);
                title(sprintf('Cropped Plate %d-%d: %s', i, plateCount, croppedFileName), 'Interpreter', 'none');
                
                % Run OCR
                fprintf('Running OCR on plate #%d...\n', plateCount);
                ocrResult = runFixedPythonOCR(croppedFilePath);
                
                % Display results for this plate and ask for user rating
                fprintf('\n OCR RESULTS for Plate #%d \n', plateCount);
                fprintf('Detected Text: "%s"\n', ocrResult.text);
                fprintf('Confidence: %.3f (%.1f%%)\n', ocrResult.confidence, ocrResult.confidence * 100);
                
                % Show the cropped plate and ask user to rate it
                fprintf('\n Rate this OCR result:\n');
                fprintf('1 = Completely Correct (100%%)\n');
                fprintf('2 = Mostly Correct (75%%+)\n');
                fprintf('3 = Partially Correct (50%%)\n');
                fprintf('4 = Wrong/Bad (<=50%%)\n');
                
                validRating = false;
                while ~validRating
                    userRating = input('Enter rating (1-4): ');
                    if ismember(userRating, [1, 2, 3, 4])
                        validRating = true;
                    else
                        fprintf('Please enter a number between 1 and 4\n');
                    end
                end
                
                % Convert rating to success status and score
                switch userRating
                    case 1
                        plateSuccess = true;
                        scorePercentage = 100;
                        ratingText = 'Completely Correct';
                    case 2
                        plateSuccess = true;
                        scorePercentage = 75;
                        ratingText = 'Mostly Correct';
                    case 3
                        plateSuccess = false;
                        scorePercentage = 50;
                        ratingText = 'Partially Correct';
                    case 4
                        plateSuccess = false;
                        scorePercentage = 25;
                        ratingText = 'Wrong/Bad';
                end
                
                fprintf('Your rate: %s (%d%%)\n', ratingText, scorePercentage);
                
                % Store this result with user rating
                allOCRResults{end+1} = struct(...
                    'plateNumber', plateCount, ...
                    'croppedFile', croppedFileName, ...
                    'ocrResult', ocrResult, ...
                    'plateSize', [size(plateImg,2), size(plateImg,1)], ...
                    'isSuccessful', plateSuccess, ...
                    'userRating', userRating, ...
                    'scorePercentage', scorePercentage, ...
                    'ratingText', ratingText);
                
                % Update total plates counter
                results.totalPlatesDetected = results.totalPlatesDetected + 1;
                if plateSuccess
                    results.totalPlatesSuccessful = results.totalPlatesSuccessful + 1;
                end
                
                % Delete the ROI to prepare for next selection
                delete(roi);
            end
            
            % Process all OCR results for this image
            if ~isempty(allOCRResults)
                % Determine overall success for this image
                successfulPlates = 0;
                for p = 1:length(allOCRResults)
                    ocrRes = allOCRResults{p}.ocrResult;
                    if ~isempty(ocrRes.text) && ocrRes.confidence > 0.3
                        successfulPlates = successfulPlates + 1;
                    end
                end
                
                % Display overall results for this image
                fprintf('\nSUMMARY for Image %d\n', i);
                fprintf('Total plates selected: %d\n', length(allOCRResults));
                fprintf('Successful OCR: %d\n', successfulPlates);
                
                % Record results
                results.totalTested = results.totalTested + 1;
                
                if successfulPlates > 0
                    results.successful = results.successful + 1;
                    status = 'SUCCESS';
                    fprintf('Overall Status: %s (at least one plate read successfully)\n', status);
                else
                    results.failed = results.failed + 1;
                    status = 'FAILED';
                    fprintf('Overall Status: %s (no plates read successfully)\n', status);
                end
                
                % Store details for all plates in this image with user ratings
                for p = 1:length(allOCRResults)
                    plateData = allOCRResults{p};
                    results.details{end+1} = struct(...
                        'filename', imageFile.name, ...
                        'imageNumber', i, ...
                        'plateNumber', plateData.plateNumber, ...
                        'croppedFile', plateData.croppedFile, ...
                        'ocrText', plateData.ocrResult.text, ...
                        'confidence', plateData.ocrResult.confidence, ...
                        'status', status, ...
                        'plateSize', plateData.plateSize, ...
                        'isSuccessful', plateData.isSuccessful, ...
                        'userRating', plateData.userRating, ...
                        'scorePercentage', plateData.scorePercentage, ...
                        'ratingText', plateData.ratingText);
                end
            end
            
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
            results.failed = results.failed + 1;
            results.totalTested = results.totalTested + 1;
        end
    end
    
    % Display final summary
    displayFinalSummary(results);
    
    % Save results
    save('manual_ocr_results.mat', 'results');
    fprintf('\nResults saved to manual_ocr_results.mat\n');
    
    close all;
end


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
    
    % Split output into lines
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

function displayFinalSummary(results)
    % Display final summary 
    
    fprintf('\n User rating score \n');
    fprintf(' overall Performance:\n');
    fprintf('Total images tested: %d\n', results.totalTested);
    fprintf('Total license plates detected: %d\n', results.totalPlatesDetected);
    
    if results.totalPlatesDetected > 0
        % Calculate rating distribution
        completelyCorrect = 0;
        mostlyCorrect = 0;
        partiallyCorrect = 0;
        wrongBad = 0;
        
        for i = 1:length(results.details)
            switch results.details{i}.userRating
                case 1
                    completelyCorrect = completelyCorrect + 1;
                case 2
                    mostlyCorrect = mostlyCorrect + 1;
                case 3
                    partiallyCorrect = partiallyCorrect + 1;
                case 4
                    wrongBad = wrongBad + 1;
            end
        end
        
        fprintf('\n RATING DISTRIBUTION:\n');
        fprintf('Completely Correct (100%%): %d plates (%.1f%%)\n', completelyCorrect, (completelyCorrect/results.totalPlatesDetected)*100);
        fprintf('Mostly Correct (75%%+): %d plates (%.1f%%)\n', mostlyCorrect, (mostlyCorrect/results.totalPlatesDetected)*100);
        fprintf('Partially Correct (50%%): %d plates (%.1f%%)\n', partiallyCorrect, (partiallyCorrect/results.totalPlatesDetected)*100);
        fprintf('Wrong/Bad (≤50%%): %d plates (%.1f%%)\n', wrongBad, (wrongBad/results.totalPlatesDetected)*100);
        
        % Calculate overall success rate (1s and 2s are considered successful)
        goodResults = completelyCorrect + mostlyCorrect;
        successRate = goodResults / results.totalPlatesDetected;
        
        fprintf('\n OVERALL SUCCESS RATE: %.1f%% (%d/%d)\n', successRate*100, goodResults, results.totalPlatesDetected);
        
        % Determine overall grade
        if successRate >= 0.9
            grade = 'EXCELLENT';
        elseif successRate >= 0.75
            grade = 'GOOD';
        elseif successRate >= 0.5
            grade = 'FAIR';
        else
            grade = 'NEEDS IMPROVEMENT';
        end
        
        fprintf('%s %s: OCR performance\n', grade);
    end
    
    % Image-level success rate
    if results.totalTested > 0
        imageSuccessRate = results.successful / results.totalTested;
        fprintf('\n IMAGE SUCCESS RATE: %.1f%% (%d/%d images had at least one good reading)\n', ...
            imageSuccessRate*100, results.successful, results.totalTested);
    end
    
    fprintf('\n--- DETAILED RESULTS ---\n');
    for i = 1:length(results.details)
        detail = results.details{i};
        if detail.plateNumber == 1
            fprintf('%d. %s:\n', detail.imageNumber, detail.filename);
        end
        
        % Rating 
        switch detail.userRating
            case 1
                ratingIcon = '100% '; 
            case 2
                ratingIcon = '75%'; 
            case 3
                ratingIcon = '50%'; 
            case 4
                ratingIcon = '<=50%'; 
        end
        
        fprintf('   %s Plate %d -> %s\n', ratingIcon, detail.plateNumber, detail.croppedFile);
        fprintf('      OCR: "%s" (%.1f%% confidence)\n', detail.ocrText, detail.confidence*100);
        fprintf('      Your Rating: %s (%d%%)\n', detail.ratingText, detail.scorePercentage);
        fprintf('      Size: %dx%d\n', detail.plateSize(1), detail.plateSize(2));
    end
    
    fprintf('\n All cropped plates saved to:\n');
    fprintf('C:\\Users\\billq\\OneDrive\\Documents\\MATLAB\\License Plates Detection\\License-Plate-Detection\\cropped_plates\n');
    
    % Summary 
    if results.totalPlatesDetected > 0
        goodResults = 0;
        for i = 1:length(results.details)
            if results.details{i}.userRating <= 2
                goodResults = goodResults + 1;
            end
        end
        successRate = goodResults / results.totalPlatesDetected;
        
        fprintf('\n FINAL SCORE:\n');
        fprintf('Overall Success Rate: %.1f%%\n', successRate*100);
        fprintf('Rating: %s\n', grade);
        
        if successRate >= 0.9
            letterGrade = 'A+';
        elseif successRate >= 0.8
            letterGrade = 'A';
        elseif successRate >= 0.75
            letterGrade = 'B+';
        elseif successRate >= 0.7
            letterGrade = 'B';
        elseif successRate >= 0.6
            letterGrade = 'C';
        elseif successRate >= 0.5
            letterGrade = 'D';
        else
            letterGrade = 'F';
        end
        
        fprintf('Letter Grade: %s\n', letterGrade);
    end
end