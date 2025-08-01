clear;

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


