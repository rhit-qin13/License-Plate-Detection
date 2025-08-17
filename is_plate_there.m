clear;
clc;

mainDataFolder = 'C:/Users/sarmau/Image Recognition/License Plate Detection/archive (1)/plate-license-5';

imdsTrain = imageDatastore(fullfile(mainDataFolder, 'train'), 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
imdsValidation = imageDatastore(fullfile(mainDataFolder, 'valid'), 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
imdsTest = imageDatastore(fullfile(mainDataFolder, 'test'), 'IncludeSubfolders', true, 'LabelSource', 'foldernames');

inputSize = [227 227 3];

imageAugmenter = imageDataAugmenter( ...
    'RandRotation', [-10 10], ...
    'RandXTranslation', [-5 5], ...
    'RandYTranslation', [-5 5], ...
    'RandXScale', [0.9 1.1], ...
    'RandYScale', [0.9 1.1], ...
    'RandXReflection', true);

augImdsTrain = augmentedImageDatastore(inputSize, imdsTrain, 'DataAugmentation', imageAugmenter);
augImdsValidation = augmentedImageDatastore(inputSize, imdsValidation);
augImdsTest = augmentedImageDatastore(inputSize, imdsTest);

net = squeezenet;

numClasses = numel(categories(imdsTrain.Labels));

lgraph = layerGraph(net);

layersToRemove = {
    'drop9', ...
    'conv10', ...
    'relu_conv10', ...
    'pool10', ...
    'prob', ...
    'ClassificationLayer_predictions'
};
lgraph = removeLayers(lgraph, layersToRemove);

newLayers = [
    convolution2dLayer(1, numClasses, 'Name', 'new_conv_for_plates', ...
        'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10)
    reluLayer('Name','new_relu')
    globalAveragePooling2dLayer('Name','gap')
    softmaxLayer('Name','softmax')
    classificationLayer('Name', 'new_classification_layer')
];

lgraph = addLayers(lgraph, newLayers);
lgraph = connectLayers(lgraph, 'fire9-concat', 'new_conv_for_plates');

options = trainingOptions('adam', ...
    'InitialLearnRate', 1e-4, ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 10, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', augImdsValidation, ...
    'ValidationFrequency', 50, ...
    'Verbose', false, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu');  

trainedNet = trainNetwork(augImdsTrain, lgraph, options);

[YPredTest, ~] = classify(trainedNet, augImdsTest);
accuracyTest = mean(YPredTest == imdsTest.Labels);

fprintf('Test Accuracy: %.2f%%\n', accuracyTest * 100);

save('trainedNet.mat', 'trainedNet');