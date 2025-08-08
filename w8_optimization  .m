%% Parameter Optimization

if ~exist('trainDS', 'var')
    run('main.m');
end

if ~exist('detectionRate', 'var')
    run('w7_analysis');
end
    

% Building on existing detectPlates function and batch test results
fprintf('\n PARAMETER OPTIMIZATION \n');
% Create optimized detection function with tunable parameters


% Current baseline performance (using Mingjian's results)
baselineRate = detectionRate;
fprintf('Baseline detection rate: %.1f%%\n', baselineRate*100);

% Parameter experiments
paramSets = [];

% Original parameters
paramSets(1).name = 'Original';
paramSets(1).minArea = 500; paramSets(1).maxArea = Inf;
paramSets(1).maxCircularity = 0.5; paramSets(1).minEccentricity = 0.7;
paramSets(1).minAspectRatio = 2; paramSets(1).maxAspectRatio = 5;

% Try 2: area threshold
paramSets(2).name = 'Lower Area';
paramSets(2).minArea = 300; paramSets(2).maxArea = Inf;
paramSets(2).maxCircularity = 0.5; paramSets(2).minEccentricity = 0.7;
paramSets(2).minAspectRatio = 2; paramSets(2).maxAspectRatio = 5;

% Try 3: Wider aspect ratio
paramSets(3).name = 'Wider Aspect';
paramSets(3).minArea = 500; paramSets(3).maxArea = Inf;
paramSets(3).maxCircularity = 0.5; paramSets(3).minEccentricity = 0.7;
paramSets(3).minAspectRatio = 1.5; paramSets(3).maxAspectRatio = 6;

% Try 4: Combined optimization
paramSets(4).name = 'Combined';
paramSets(4).minArea = 300; paramSets(4).maxArea = 15000;
paramSets(4).maxCircularity = 0.6; paramSets(4).minEccentricity = 0.6;
paramSets(4).minAspectRatio = 1.5; paramSets(4).maxAspectRatio = 6;

% Try 5: Stricter area bounds
paramSets(5).name = 'Stricter Area';
paramSets(5).minArea = 600; paramSets(5).maxArea = 8000;
paramSets(5).maxCircularity = 0.45; paramSets(5).minEccentricity = 0.75;
paramSets(5).minAspectRatio = 2.2; paramSets(5).maxAspectRatio = 4.5;

% Try 6: Higher eccentricity 
paramSets(6).name = 'More Elongated';
paramSets(6).minArea = 500; paramSets(6).maxArea = 10000;
paramSets(6).maxCircularity = 0.4; paramSets(6).minEccentricity = 0.8;
paramSets(6).minAspectRatio = 2.5; paramSets(6).maxAspectRatio = 4.0;

% Try 7: Slightly lower area threshold
paramSets(7).name = 'Fine Area -100';
paramSets(7).minArea = 400; paramSets(7).maxArea = Inf;
paramSets(7).maxCircularity = 0.5; paramSets(7).minEccentricity = 0.7;
paramSets(7).minAspectRatio = 2; paramSets(7).maxAspectRatio = 5;  

% Try 8: Slightly wider aspect ratio
paramSets(8).name = 'Fine Aspect +0.5';
paramSets(8).minArea = 500; paramSets(8).maxArea = Inf;
paramSets(8).maxCircularity = 0.5; paramSets(8).minEccentricity = 0.7;
paramSets(8).minAspectRatio = 1.8; paramSets(8).maxAspectRatio = 5.5;

% Try 9: Slightly relaxed circularity
paramSets(9).name = 'Fine Circularity +0.05';
paramSets(9).minArea = 500; paramSets(9).maxArea = Inf;
paramSets(9).maxCircularity = 0.55; paramSets(9).minEccentricity = 0.7;
paramSets(9).minAspectRatio = 2; paramSets(9).maxAspectRatio = 5;

% Try 10: Slightly lower eccentricity
paramSets(10).name = 'Fine Eccentricity -0.05';
paramSets(10).minArea = 500; paramSets(10).maxArea = Inf;
paramSets(10).maxCircularity = 0.5; paramSets(10).minEccentricity = 0.65;
paramSets(10).minAspectRatio = 2; paramSets(10).maxAspectRatio = 5;

% Try 11: Combined fine adjustments
paramSets(11).name = 'Fine Combined';
paramSets(11).minArea = 450; paramSets(11).maxArea = Inf;
paramSets(11).maxCircularity = 0.52; paramSets(11).minEccentricity = 0.68;
paramSets(11).minAspectRatio = 1.9; paramSets(11).maxAspectRatio = 5.2;

% Area threshold sweep 
paramSets(12).name = 'Area 400';
paramSets(12).minArea = 400; paramSets(12).maxArea = Inf;
paramSets(12).maxCircularity = 0.5; paramSets(12).minEccentricity = 0.7;
paramSets(12).minAspectRatio = 2; paramSets(12).maxAspectRatio = 5;

paramSets(13).name = 'Area 450';
paramSets(13).minArea = 450; paramSets(13).maxArea = Inf;
paramSets(13).maxCircularity = 0.5; paramSets(13).minEccentricity = 0.7;
paramSets(13).minAspectRatio = 2; paramSets(13).maxAspectRatio = 5;

paramSets(14).name = 'Area 550';
paramSets(14).minArea = 550; paramSets(14).maxArea = Inf;
paramSets(14).maxCircularity = 0.5; paramSets(14).minEccentricity = 0.7;
paramSets(14).minAspectRatio = 2; paramSets(14).maxAspectRatio = 5;

paramSets(15).name = 'Area 600';
paramSets(15).minArea = 600; paramSets(15).maxArea = Inf;
paramSets(15).maxCircularity = 0.5; paramSets(15).minEccentricity = 0.7;
paramSets(15).minAspectRatio = 2; paramSets(15).maxAspectRatio = 5;

% Circularity sweep 
paramSets(16).name = 'Circularity 0.45';
paramSets(16).minArea = 500; paramSets(16).maxArea = Inf;
paramSets(16).maxCircularity = 0.45; paramSets(16).minEccentricity = 0.7;
paramSets(16).minAspectRatio = 2; paramSets(16).maxAspectRatio = 5;

paramSets(17).name = 'Circularity 0.55';
paramSets(17).minArea = 500; paramSets(17).maxArea = Inf;
paramSets(17).maxCircularity = 0.55; paramSets(17).minEccentricity = 0.7;
paramSets(17).minAspectRatio = 2; paramSets(17).maxAspectRatio = 5;

paramSets(18).name = 'Circularity 0.6';
paramSets(18).minArea = 500; paramSets(18).maxArea = Inf;
paramSets(18).maxCircularity = 0.6; paramSets(18).minEccentricity = 0.7;
paramSets(18).minAspectRatio = 2; paramSets(18).maxAspectRatio = 5;

% Eccentricity sweep 
paramSets(19).name = 'Eccentricity 0.65';
paramSets(19).minArea = 500; paramSets(19).maxArea = Inf;
paramSets(19).maxCircularity = 0.5; paramSets(19).minEccentricity = 0.65;
paramSets(19).minAspectRatio = 2; paramSets(19).maxAspectRatio = 5;

paramSets(20).name = 'Eccentricity 0.68';
paramSets(20).minArea = 500; paramSets(20).maxArea = Inf;
paramSets(20).maxCircularity = 0.5; paramSets(20).minEccentricity = 0.68;
paramSets(20).minAspectRatio = 2; paramSets(20).maxAspectRatio = 5;

paramSets(21).name = 'Eccentricity 0.75';
paramSets(21).minArea = 500; paramSets(21).maxArea = Inf;
paramSets(21).maxCircularity = 0.5; paramSets(21).minEccentricity = 0.75;
paramSets(21).minAspectRatio = 2; paramSets(21).maxAspectRatio = 5;

% Aspect ratio fine sweep
paramSets(22).name = 'Aspect 1.7-5.3';
paramSets(22).minArea = 500; paramSets(22).maxArea = Inf;
paramSets(22).maxCircularity = 0.5; paramSets(22).minEccentricity = 0.7;
paramSets(22).minAspectRatio = 1.7; paramSets(22).maxAspectRatio = 5.3;

paramSets(23).name = 'Aspect 1.9-5.7';
paramSets(23).minArea = 500; paramSets(23).maxArea = Inf;
paramSets(23).maxCircularity = 0.5; paramSets(23).minEccentricity = 0.7;
paramSets(23).minAspectRatio = 1.9; paramSets(23).maxAspectRatio = 5.7;

% Optimal combination based on parameter sweeps
paramSets(24).name = 'Optimal Combined';
paramSets(24).minArea = 600;          
paramSets(24).maxArea = Inf;
paramSets(24).maxCircularity = 0.5;   
paramSets(24).minEccentricity = 0.7;  
paramSets(24).minAspectRatio = 1.8;   
paramSets(24).maxAspectRatio = 5.5;

% Test each parameter set
fprintf('Testing parameter optimizations:\n');
bestScore = -Inf;
bestParams = paramSets(1);

for p = 1:length(paramSets)
    correctDetections = 0;  
% Images with exactly 1 detection
    overDetections = 0;     
% Images with >1 detection  
    noDetections = 0;       
% Images with 0 detections
    
    for i = 1:testImages
        img = readimage(trainDS, i);
        [plateCandidates_opt, ~] = detectPlates_Optimized(img, paramSets(p));
        
        numDetections = size(plateCandidates_opt, 1);
        
        if numDetections == 1
            correctDetections = correctDetections + 1;
        elseif numDetections > 1
            overDetections = overDetections + 1;
        else
            noDetections = noDetections + 1;
        end
    end
    
    correctRate = correctDetections / testImages;
    overRate = overDetections / testImages;
    missRate = noDetections / testImages;
    
    % Score
    score = correctRate - (0.5 * overRate) - (1.0 * missRate);
    
    fprintf('%s: %.1f%% correct (1 plate), %.1f%% over-detected, %.1f%% missed, Score: %.3f\n', ...
        paramSets(p).name, correctRate*100, overRate*100, missRate*100, score);
    
    if score > bestScore
        bestScore = score;
        bestParams = paramSets(p);
    end
end    
   
% Validation on validation set
validImages = min(15, numel(validDS.Files));
validCorrect = 0;
validOver = 0;
validMissed = 0;

for i = 1:validImages
    img = readimage(validDS, i);
    [plateCandidates_valid, ~] = detectPlates_Optimized(img, bestParams);
    
    numDetections = size(plateCandidates_valid, 1);
    
    if numDetections == 1
        validCorrect = validCorrect + 1;
    elseif numDetections > 1
        validOver = validOver + 1;
    else
        validMissed = validMissed + 1;
    end
end

validCorrectRate = validCorrect / validImages;
validOverRate = validOver / validImages;
validMissRate = validMissed / validImages;
finalScore = validCorrectRate - (0.5 * validOverRate) - (1.0 * validMissRate);
fprintf('Validation Results: %.1f%% correct, %.1f%% over-detected, %.1f%% missed, Score: %.3f\n', ...
    validCorrectRate*100, validOverRate*100, validMissRate*100, finalScore);
finalRate = validCorrectRate;  
improvement = finalScore - bestScore;  


fprintf('\nOPTIMIZATION RESULTS:\n');
fprintf('Best parameter set: %s\n', bestParams.name);
fprintf('Training score: %.3f\n', bestScore);
fprintf('Validation score: %.3f\n', finalScore);
fprintf('Score difference: %.3f\n', improvement);

% Save optimized parameters
save('optimized_params.mat', 'bestParams', 'baselineRate', 'finalRate');

% graph results
figure('Position', [100, 100, 1200, 400]);
sampleImg = readimage(validDS, 1);

% Original detection
[originalDetections, ~] = detectPlates(sampleImg);
subplot(1,2,1);
imshow(sampleImg);
title(sprintf('BEFORE: %d detections', size(originalDetections, 1)));
hold on;
for j = 1:size(originalDetections, 1)
    rectangle('Position', originalDetections(j, :), 'EdgeColor', 'r', 'LineWidth', 2);
end
hold off;

% Optimized detection
[optimizedDetections, ~] = detectPlates_Optimized(sampleImg, bestParams);
subplot(1,2,2);
imshow(sampleImg);
title(sprintf('AFTER: %d detections', size(optimizedDetections, 1)));
hold on;
for j = 1:size(optimizedDetections, 1)
    rectangle('Position', optimizedDetections(j, :), 'EdgeColor', 'g', 'LineWidth', 2);
end
hold off;

% Summary table
fprintf('\nPARAMETER COMPARISON:\n');
fprintf('                    Original    Optimized\n');
fprintf('Min Area:           500         %.0f\n', bestParams.minArea);
fprintf('Max Area:           Inf         %.0f\n', bestParams.maxArea);
fprintf('Max Circularity:    0.5         %.1f\n', bestParams.maxCircularity);
fprintf('Min Eccentricity:   0.7         %.1f\n', bestParams.minEccentricity);
fprintf('Aspect Ratio:       2-5         %.1f-%.1f\n', bestParams.minAspectRatio, bestParams.maxAspectRatio);

if improvement > 0
    fprintf('Improved detection rate by %.1f percentage \n', improvement*100);
    fprintf('Optimized parameters saved to optimized_params.mat\n');
else
    fprintf('No improvement found. baseline parameters are optimal\n');
end