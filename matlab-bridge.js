const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const PORT = 8080;

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.static('public'));

const MATLAB_PROJECT_PATH = path.resolve('C:/Users/billq/OneDrive/Documents/Visual Studio 2017/Project/License plate detection/matlab_codes');
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const RESULTS_DIR = path.join(__dirname, 'results');

if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}
if (!fs.existsSync(RESULTS_DIR)) {
    fs.mkdirSync(RESULTS_DIR, { recursive: true });
}


app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/health', (req, res) => {
    const health = {
        status: 'Server is running',
        timestamp: new Date().toISOString(),
        paths: {
            matlab: fs.existsSync(MATLAB_PROJECT_PATH),
            uploads: fs.existsSync(UPLOAD_DIR),
            results: fs.existsSync(RESULTS_DIR)
        }
    };
    res.json(health);
});

app.post('/process-image', async (req, res) => {
    try {
        const { filename, imageData, originalName } = req.body;
        
        console.log(` Processing image: ${filename}`);
        console.log(` Original name: ${originalName}`);

        if (!filename || !imageData) {
            throw new Error('Missing filename or image data');
        }

        const imagePath = await saveImage(filename, imageData);
        console.log(` Image saved to: ${imagePath}`);

        const result = await processWithMATLAB(imagePath, originalName);
        

        try {
            fs.unlinkSync(imagePath);
            console.log(` Cleaned up: ${imagePath}`);
        } catch (cleanupError) {
            console.warn(` Could not clean up ${imagePath}:`, cleanupError.message);
        }

        if (!result.success || result.confidence < 0.3) {
            console.log(`Detection failed: ${result.status}`);
            res.status(422).json({
                error: 'No license plate detected',
                message: 'Unable to detect or read license plate in the provided image',
                details: result.status,
                success: false,
                confidence: result.confidence
            });
            return;
        }
        
        console.log(`Processing completed: ${result.plateNumber}`);
        res.json(result);
        
    } catch (error) {
        console.error('Error processing image:', error);
        res.status(500).json({ 
            error: 'Processing failed', 
            message: error.message,
            success: false
        });
    }
});

async function saveImage(filename, base64Data) {
    try {
        const base64Image = base64Data.includes(',') ? base64Data.split(',')[1] : base64Data;
        const imagePath = path.join(UPLOAD_DIR, filename);
        
        fs.writeFileSync(imagePath, base64Image, 'base64');
        return imagePath;
    } catch (error) {
        throw new Error(`Failed to save image: ${error.message}`);
    }
}
async function processWithMATLAB(imagePath, originalName) {
    return new Promise((resolve, reject) => {
        const timestamp = Date.now();
        const resultFilename = `result_${timestamp}.json`;
        const resultPath = path.join(RESULTS_DIR, resultFilename);
        const scriptFilename = `process_${timestamp}.m`;
        const scriptPath = path.join(RESULTS_DIR, scriptFilename);

        const normalizedImagePath = imagePath.replace(/\\/g, '/');
        const normalizedMatlabPath = MATLAB_PROJECT_PATH.replace(/\\/g, '/');
        const normalizedResultPath = resultPath.replace(/\\/g, '/');

        const matlabScript = `
try
    % Add your project path
    addpath('${normalizedMatlabPath}');
    
    % Check if OCR script exists
    if ~exist('fixed_ocr.py', 'file')
        error('fixed_ocr.py not found in MATLAB path');
    end
    
    % Load image
    img = imread('${normalizedImagePath}');
    fprintf(' Image loaded successfully\\n');
    fprintf(' Image size: %dx%d\\n', size(img,2), size(img,1));
    
    fprintf(' SKIPPING DETECTION - Running OCR directly on uploaded image\\n');
    
    % Save the original image for OCR (no cropping)
    ocrImagePath = '${normalizedResultPath.replace('.json', '_direct.jpg')}';
    imwrite(img, ocrImagePath);
    fprintf(' Original image saved for OCR: %s\\n', ocrImagePath);
    
    % Run PaddleOCR script directly on the original image
    ocrScriptPath = fullfile('${normalizedMatlabPath}', 'fixed_ocr.py');
    ocrCommand = sprintf('python "%s" "%s"', ocrScriptPath, ocrImagePath);
    fprintf(' Running OCR command: %s\\n', ocrCommand);
    [ocrStatus, ocrOutput] = system(ocrCommand);
    
    fprintf(' OCR Status: %d\\n', ocrStatus);
    fprintf(' OCR Output: %s\\n', ocrOutput);
    
    % Initialize result variables
    plateNumber = '';
    confidence = 0.0;
    status = '';
    ocrSuccess = false;
    
    if ocrStatus == 0
        % Parse OCR output
        ocrLines = strsplit(ocrOutput, '\\n');
        ocrText = '';
        ocrConf = 0.0;
        
        for i = 1:length(ocrLines)
            line = strtrim(ocrLines{i});
            if startsWith(line, 'TEXT:')
                ocrText = strtrim(line(6:end));
            elseif startsWith(line, 'CONFIDENCE:')
                try
                    ocrConf = str2double(strtrim(line(12:end)));
                catch
                    ocrConf = 0.0;
                end
            end
        end
        
        fprintf(' Parsed OCR text: "%s"\\n', ocrText);
        fprintf(' Parsed OCR confidence: %.3f\\n', ocrConf);
        
        % Accept any OCR result (even empty for debugging)
        plateNumber = ocrText;
        confidence = ocrConf;
        
        if ~isempty(ocrText) && ocrConf > 0.0
            status = 'Direct OCR successful';
            ocrSuccess = true;
            fprintf('OCR found text: "%s" (confidence: %.3f)\\n', plateNumber, confidence);
        else
            status = 'Direct OCR returned empty result';
            ocrSuccess = false;
            fprintf(' OCR returned empty text or zero confidence\\n');
        end
    else
        fprintf(' OCR command failed with status %d\\n', ocrStatus);
        fprintf(' OCR error output: %s\\n', ocrOutput);
        status = 'OCR command failed';
        confidence = 0.0;
        ocrSuccess = false;
    end
    
    % Create result structure
    result = struct();
    result.plateNumber = plateNumber;
    result.confidence = confidence;
    result.status = status;
    result.numCandidates = 0;  % No detection performed
    result.timestamp = datestr(now);
    result.success = ocrSuccess;
    result.detectionSuccess = false;  % No detection performed
    result.ocrSuccess = ocrSuccess;
    result.mode = 'DIRECT_OCR_ONLY';
    
    % Save result to json
    jsonStr = jsonencode(result);
    fid = fopen('${normalizedResultPath}', 'w');
    if fid == -1
        error('Could not open result file for writing');
    end
    fprintf(fid, '%s', jsonStr);
    fclose(fid);
    
    if ocrSuccess
        fprintf(' Direct OCR completed successfully\\n');
    else
        fprintf(' Direct OCR completed but no text found\\n');
    end
    
catch ME
    fprintf(' Error in direct OCR processing: %s\\n', ME.message);
    if ~isempty(ME.stack)
        fprintf(' Error location: %s (line %d)\\n', ME.stack(1).name, ME.stack(1).line);
    end
    
    % Create error result
    result = struct();
    result.plateNumber = '';
    result.confidence = 0.0;
    result.status = ['MATLAB Error: ' ME.message];
    result.numCandidates = 0;
    result.timestamp = datestr(now);
    result.success = false;
    result.detectionSuccess = false;
    result.ocrSuccess = false;
    result.mode = 'DIRECT_OCR_ERROR';
    
    % Save error result
    jsonStr = jsonencode(result);
    fid = fopen('${normalizedResultPath}', 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
end

exit;
`;
        
        try {
            fs.writeFileSync(scriptPath, matlabScript);
            console.log(` MATLAB script written to: ${scriptPath}`);

            const matlabExec = `matlab -batch "run('${scriptPath.replace(/\\/g, '/')}')"`;
            console.log(' Executing DIRECT OCR MATLAB script');
            
            exec(matlabExec, { 
                timeout: 60000,
                cwd: MATLAB_PROJECT_PATH
            }, (error, stdout, stderr) => {
                console.log('OCR complete');
                if (stdout) console.log('MATLAB stdout:', stdout);
                if (stderr) console.log('MATLAB stderr:', stderr);
                if (error) console.log('MATLAB error:', error.message);
 
                try {
                    fs.unlinkSync(scriptPath);
                } catch (cleanupError) {
                    console.log('Could not clean up script file:', cleanupError.message);
                }
                
                console.log(`🔍 Checking for result file: ${resultPath}`);
                if (fs.existsSync(resultPath)) {
                    try {
                        const resultData = fs.readFileSync(resultPath, 'utf8');
                        console.log(' Raw result data:', resultData);
                        
                        const result = JSON.parse(resultData);
                        console.log(' Parsed result:', result);
                        
                        try {
                            fs.unlinkSync(resultPath);
                        } catch (cleanupError) {
                            console.log('Could not clean up result file:', cleanupError.message);
                        }
                        
                        resolve(result);
                        
                    } catch (parseError) {
                        console.error(' Error parsing MATLAB result:', parseError);
                        reject(new Error('Failed to parse MATLAB result'));
                    }
                } else {
                    console.error(' MATLAB result file not created');
                    resolve({
                        plateNumber: '',
                        confidence: 0.0,
                        status: 'MATLAB execution failed - no result file created',
                        success: false,
                        detectionSuccess: false,
                        ocrSuccess: false,
                        mode: 'DIRECT_OCR_FAILED'
                    });
                }
            });
            
        } catch (fileError) {
            console.error(' Error writing MATLAB script file:', fileError);
            reject(new Error('Failed to write MATLAB script file'));
        }
    });
}

app.listen(PORT, () => {
    console.log(` MATLAB Bridge Server running on http://localhost:${PORT}`);
    console.log(` Server directory: ${__dirname}`);
});

process.on('SIGINT', () => {
    process.exit(0);
});