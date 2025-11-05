//	MIT License
//	Copyright (c) 2025 Adam Luff, a.luff@uq.edu.au
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.");

print("\\Clear");
roiManager("reset");
run("Clear Results");

dir = getDirectory("Choose a Directory ");
setBatchMode(true);
prog = 0; //Progress counter
count = 0;
countFiles(dir);
processFiles(dir);
print(count+" files processed"); //DEBUG
   
function countFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")) {
          	countFiles(""+dir+list[i]);
      	}
      	else {
      		count++;
      	}
  	}
}

function processFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")) {
			processFiles(""+dir+list[i]);
		}
		else {
			showProgress(prog++, count);
			path = dir+list[i];
			processFile(path);
		}
	}
}

function processFile(path) {
	if (endsWith(path, ".tif")) {
		image_name = File.getName(path);
		print("Found .tif: "+image_name);
		open(path);
		
		// Set filepaths and filenames
		image_title = getTitle();
		cellpose_rois = replace(path, ".tif", "_rois.zip");
		rois_name = File.getName(cellpose_rois);
		human_counts = replace(path, ".tif", ".roi");
		points_name = cellpose_name = File.getName(human_counts);
		
		run("Set Measurements...", "area mean min centroid center redirect=None decimal=3");
		
		// Check for and open human_counts file
		if (File.exists(human_counts)) {
			open(human_counts);
			run("Measure");
		} else {
			selectImage(image_title);
			print("File does not exist: "+points_name);
			print("-----");
			setOption("Changes",false);
			close("*");
			return;
		}
		
		// Check for and open cellpose_rois file
		if (File.exists(cellpose_rois)) {
			roiManager("Open", cellpose_rois);
		} else {
			selectImage(image_title);
			print("File does not exist: "+rois_name);
			print("-----");
			setOption("Changes",false);
			close("*");
			return;
		}
		
		// Init counts
		a = 0; // True positives (agreements)
		b = 0; // False positives (cellpose roi with no points)
		c = 0; // False negatives (extra human counts inside rois)
		d = 0; // False negatives (extra human counts outside rois)
		
		n = roiManager("count");
		for (i = 0; i < n; i++) {
			w = false; // Flag indicates any points in roi
    		roiManager("select", i);
    		run("Create Mask");
    		selectImage("Mask");
//    		a_debug = 0; //DEBUG
//    		b_debug = 0; //DEBUG
//    		c_debug = 0; //DEBUG
//    		print("Processing roi #: "+i); //DEBUG
    		for (j = 0; j < nResults(); j++) {
    			x = round(getResult("XM", j));
    			y = round(getResult("YM", j));
    			v = getValue(x, y);
//    			print(v); //DEBUG
    			if (v == 255) {
    				if (w == false) {
    					a++; // Increment a for first point in agreement with roi
    					w = true;
//    					a_debug++; //DEBUG
    				}
    				else {
						c++; // Increment c for extra points in roi
//						c_debug++; //DEBUG
    				}
    			}

    			if (j == nResults()-1 && w == false) {
    				b++; // Increment b if no points in roi
//    				b_debug++; //DEBUG
				}
    			
			}
//			print("a counted: "+a_debug); //DEBUG
//    		print("b counted: "+b_debug); //DEBUG
//    		print("c counted: "+c_debug); //DEBUG
    		print("w flag is: "+w);
			close("Mask");
		}
		d = nResults() - (a + c);
		specificity = a/(a+b);
		sensitivity = a/(a+c+d);
		agreement = a/nResults();
		print("Total human counts: "+nResults());
		print("tp: "+a);
		print("fp: "+c);
		print("fn: "+b);
		print("% agreement: "+agreement);
		print("sensitivity: "+sensitivity);
		print("specificity: "+specificity);
//		print("Agreements: "+a); //DEBUG
//		print("Cellpose extra: "+b); //DEBUG
//		print("Human extra (inside rois): "+c); //DEBUG
//		print("Human extra (outside rois): "+d); //DEBUG
		print("-----");
		// Clear changes so we can close image without prompt
		selectImage(image_title);
		setOption("Changes",false);
		close("*");
	}
	roiManager("reset");
	run("Clear Results");
}