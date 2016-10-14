// CLARITY 3D neuron segmentation (sparse)
// 
// Macro for Fiji/ImageJ 
// Segments neurons in cleared mouse brain of sparse stains (like Thy1) in 3D 
// 
// (c) Maged Goubran, mgoubran@stanford.edu, 2016
//
// based on plugins from:
// 
// the 3D Segmentation plugins (3D ImageJ suite) 
// http://imagejdocu.tudor.lu/doku.php?id=plugin:stacks:3d_ij_suite:start
// 
// &
//
// the Mathematical Morphology plugins 
// http://imagej.net/MorphoLibJ
// 
// -----------------------------------

// Get files path
path = getArgument();
print("Files path is:" +path);

// Init Parameters:-

// num of CPUS
ncpus = 40;
// radius (px) for local maxima
radpx = 2;
radpz = 2;

// max object size
maxobjsz = 10000;

// convert to 8-bit
convert = 1;

// -----------------------------------

// Get files list
list = getFileList(path);
num = list.length;
print("Sequence contains " +num+ " images");

// Open stack
print("--Reading stack");

if (convert==1) {

	print("Converting input to 8-bit");

	run("Image Sequence...", "open=&path starting=&skip increment=1 scale=100 file=tif sort convert"); 

} else {

	print("Keeping input type unchanged");

	run("Image Sequence...", "open=&path starting=1 increment=1 scale=100 file=tif sort");

}

// Get ID
orgstack = getImageID();
// Get Title
orgtitle = getTitle();

// if needed run("16-bit");

// -----------------------------------

// Substract Background

outback = path + "norm.tif";

// Collect Garbage
call("java.lang.System.gc");

if (!File.exists(outback)) {

	// Duplicate image
	run("Duplicate...","duplicate");

	print("-- Subtracting Background");
	run("Subtract Background...", "rolling=50 sliding stack");	

	// Save Normalized int
	save(outback);

} else {

	print("Background-less image already computed .. skipping & openning it ");

	open(outback);

}

backstack = getImageID();
backtitle = getTitle();	

rename("BacklessStack");

// close org image
selectImage(orgstack);
close();

// -----------------------------------

// Enhance Contrast

outenhance = path + "backremov_enhance.tif";

if (!File.exists(outenhance)) {

	// Duplicate image
	run("Duplicate...","duplicate");

	print("-- Enhancing contrast & normalizing Histogram");
	run("Enhance Contrast...", "saturated=0.5 normalize process_all use");
		
	// Save enhanced 
	save(outback);

} else {

	print("Enhancing contrast already performed .. skipping & openning it ");
	
	open(outenhance);

}

enhancestack = getImageID();
enhancetitle = getTitle();		

rename("EnhanceStack");

// -----------------------------------

// Compute Median Filter

call("java.lang.System.gc");

outmed = path + "backremov_enhance_median.tif";

if (!File.exists(outmed)) {

	print("-- Computing Median image");
	print("using " +ncpus+ " CPUs for parallelization");

	// Create median image
	run("3D Fast Filters","filter=Median radius_x_pix=&radpx radius_y_pix=&radpx radius_z_pix=&radpz Nb_cpus=&ncpus");

	// Save Med
	save(outmed);

} else {

	print("Median filtering already computed .. skipping & openning it ");

	open(outmed);

}

medstack = getImageID();
medtitle = getTitle();

rename("MedianImg");

// -----------------------------------

// Compute Top Hat transform

//print("--Computing Top Hat transform ");
//print("disk radius " +radpx);

//run("3D Fast Filters","filter=TopHat radius_x_pix=&radpx radius_y_pix=&radpx radius_z_pix=&radpz Nb_cpus=&ncpus");

//tophatstack = getImageID();
//rename("TopHat");


// -----------------------------------

// Compute Local threshold 

outlocthr = path + "median_locthr.tif";

if (!File.exists(outlocthr)) {

	// Duplicate image
	run("Duplicate...","duplicate");

	print("-- Computing Local Threshold");

	run("Auto Local Threshold", "method=Phansalkar radius=15 parameter_1=0 parameter_2=0 white stack");

	// Save LocThr 
	save(outlocthr);


} else {

	print("Local Thresholded Median img already exists .. skipping & openning it ");
	
	open(outlocthr);

}


locthrstack = getImageID();
locthrtitle = getTitle();

rename("LocalThr");

// -----------------------------------

// Compute Minimum 

outmin = path + "median_locthr_min.tif";

if (!File.exists(outmin)) {

	print("-- Computing Minimum");

	run("3D Fast Filters","filter=Minimum radius_x_pix=&radpx radius_y_pix=&radpx radius_z_pix=&radpz Nb_cpus=ncpus");

	// Save min
	save(outmin);

} else {

	print("Minimum img already exists .. skipping & openning it ");
	
	open(outmin);

}

minstack = getImageID();
mintitle = getTitle();

// -----------------------------------

// Filter very large objects (like border artifacts)

outfil = path + "min_filtered.tif"

// Collect Garbage
call("java.lang.System.gc");

if (!File.exists(outfil)) {

	print("-- Filtering very large objects");

	run("3D Simple Segmentation", "low_threshold=128 min_size=0 max_size=&maxobjsz");

} else {

	print("Filtered Minimum img already exists .. skipping & openning it ");
	
	open(outmedthr);

}

// -----------------------------------

// Close rest of images

// close backless image
selectImage(backstack);
close();

// close enhance image
selectImage(enhancestack);
close();

// close min image
selectImage(minstack);
close();

// bin
selectImage("Bin");
close();

// -----------------------------------

// Compute Marker controlled Watershed 

outseg = path + "seg.tif";

// Collect Garbage
call("java.lang.System.gc");

if (!File.exists(outseg)) {

	print("-- Computing Marker-controlled Watershed segmentation... This might take a while");

	run("Marker-controlled Watershed", "input=MedianImg marker=Seg mask=LocalThr calculate use");

	// Duplicate image
	run("Duplicate...","duplicate");

	// Save segmentation
	save(outseg);

	// Save segmentation mhd
	run("MHD/MHA ...", "save=" +path+ "seg.mhd");

	print("-- Computing binary segmentation");

	// Make binary mask
	run("Make Binary", "method=Percentile background=Default calculate black");

	// Save segmentation bin
	save(path + "seg_bin.tif");

	// Save segmentation bin mhd
	run("MHD/MHA ...", "save=" +path+ "seg_bin.mhd");

} else {

	print ("Segmentation already computed .. skipping stack")

}

// save log file 
outlog = path + "log.txt";

f = File.open(outlog); 
content=getInfo("log");
print(f,content);
File.close(f); 

// Quit Fiji
run("Quit");