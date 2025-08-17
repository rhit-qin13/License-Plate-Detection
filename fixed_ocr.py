import sys
import os
from paddleocr import PaddleOCR

try:
    ocr = PaddleOCR(lang="en")
except Exception as e:
    print(f"ERROR: Could not initialize PaddleOCR: {e}")
    sys.exit(1)

def process_single_image(image_path):
    try:
        if not os.path.exists(image_path):
            print("ERROR: Image not found")
            return
        
        # Use predict method for new PaddleOCR versions
        try:
            results = ocr.predict(image_path)
        except:
            # Fallback to ocr method
            results = ocr.ocr(image_path)
        
        final_text = ""
        avg_conf = 0.0
        
        if results and len(results) > 0:
            result = results[0]  # Get first result
            
            # Check if new format (dictionary with rec_texts)
            if isinstance(result, dict) and "rec_texts" in result:
                texts = result.get("rec_texts", [])
                scores = result.get("rec_scores", [])
                
                if texts:
                    final_text = "".join(texts).replace(" ", "").upper()
                    if scores:
                        avg_conf = sum(scores) / len(scores)
                    else:
                        avg_conf = 0.8
            
            # Check if old format (list of detections)
            elif isinstance(result, list) and result:
                all_text = []
                all_conf = []
                
                for line in result:
                    if line and len(line) >= 2:
                        text = line[1][0]
                        conf = line[1][1]
                        all_text.append(text)
                        all_conf.append(conf)
                
                if all_text:
                    final_text = "".join(all_text).replace(" ", "").upper()
                    avg_conf = sum(all_conf) / len(all_conf) if all_conf else 0
        
        print(f"TEXT:{final_text}")
        print(f"CONFIDENCE:{avg_conf:.3f}")
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        print("TEXT:")
        print("CONFIDENCE:0.000")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python fixed_ocr.py <image_path>")
        sys.exit(1)
    
    image_path = sys.argv[1]
    process_single_image(image_path)
