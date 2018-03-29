// This macro asks for a folder to search for dm4 files.
// The first folder given is used as the base.  Each sub folder is give its own folder in the output.
// Each sub folder is then searched recursively to look for folders containing dm4 files.  
// All the dm4 files are opened and a small (200x200) gif is made.  
// Some useful information is collected from the file header.  THis is done for all files.
// For each folder the gifs are stacked into an animated gif with the folder name as the gif name.  
// The gif name is shown in the final information file so that the header information can be linked to the gif

// The concept here is that the gifs will allow quick searching when you vaguely remember what a data set looks like


// NOTE in its current form it does not check the base folder for dm4 files.  
// If you want this then remove the last line 
// scan1(dir1,out);
// then add the following 3 lines
// file1=File.open(out+"gif_info.txt");
// scan_folder(dir1,out,file1);
// File.close(file1);
// this wont make sub folders, but will include the first folder contents.

// I'm not totally sure if this will cope with file/folder names with spaces in them... I'll need to check this when I'm feeling brave


//Work in progress output gives a lots of exceptions.  Not sure if I need to catch these?



// To do/ideas
//make a tmp dir for individual gif frames and remove it at the end.

setBatchMode(true);  //stops it from showing images that open.  leave off for testing.
run("Bio-Formats Macro Extensions");
IJ.redirectErrorMessages();
var files_so_far=newArray("");  //need to declare one element so that the for loop in checknames finds it.

function make_small_get_info (file, previousbase, currentnum,savepath,data_file){
	//File.makeDirectory(RND_name)
	image=0;  //not sure what this is for
	basename="";
	Ext.openImagePlus(file);
	if (nImages>0){
		Ext.setId(file);
		Ext.getMetadataValue("Base file name",basename) //use to check if is series (ie don't add data)
		Ext.getMetadataValue("Formatted Voltage", volts);
		Ext.getMetadataValue("SEM Chamber Pressure (Torr)", pressure);
		Ext.getMetadataValue("Sample Time", dwell);
		Ext.getSizeX(sizeX);
		Ext.getSizeY(sizeY);
		//Ext.getImageCreationDate(creationDate);  //doesn't seem to work with dm4
		Ext.getMetadataValue("Acquisition Date",creationDate);  //I'd prefer to use a more standard approach than rely on Gatan consistency
		Ext.getPixelsPhysicalSizeX(voxX);
		Ext.getPixelsPhysicalSizeY(voxY);
		Ext.getPixelsPhysicalSizeZ(voxZ);
		if (basename != previousbase){
			folder=File.getParent(file);
			print (data_file,"Path to Data = "+folder);
			print (data_file,"created: "+ creationDate);
			print (data_file,"Image dimensions = "+sizeX+" x "+sizeY);
			print (data_file,"Voxel dimensions = "+ voxX*1000+" x "+voxY*1000+" x "+voxZ*1000+" nm");
	
			roundedpressure=round(pressure*100)/100;
			print(data_file,"Accelerating voltage = "+ volts+ "\nPressure= "+roundedpressure+" Torr");
	
			print (data_file,"---Extra info---\ndwell time ="+dwell+" µs\n\n");  //output these by adding a link to file name at start eg 
		
			}


		//  make small version (200x200, always square for ease of stacking)
		run("Scale...", "x=- y=- width=200 height=200 interpolation=Bilinear average create");
		saveAs("gif", savepath+currentnum+".tmpgif"); //save it as tif (gif?)
		//Ext.close();   //doesn't seem to actually work  may not be a problem in batch mode?
		close();
		close();
	}
	else{
		//if no images open there is an issue make a 200x200 black image and save as gif?
		newImage("Untitled", "16-bit ramp", 200, 200, 1);
		saveAs("gif", savepath+currentnum+".tmpgif");
		close();
	}
	
	return basename;
}
function make_gif_anim(input_path,file_name,frames){
	speed=frames/5;
	if (speed>1000){
		speed=1000;
	}
	if (speed<0.1){
		speed=0.1;
	}
	run("Image Sequence...", "open=input_path file=.tmpgif.gif sort");	
	run("Animation Options...", "speed="+speed+" start");  //this bit isn't working.  The number is picked up correctly, but speed is not set
	saveAs("Gif", file_name);
	close();	
}

function checknames(file_name){
	for (i=0; i<files_so_far.length; i++){
		print (file_name,files_so_far[i]);
		if (file_name == files_so_far[i]){
			file_name=checknames(file_name+"-0");
		}
	}
	files_so_far=Array.concat(file_name,files_so_far);  //this variable doesn't appear to be global
	return file_name;
}

function scan_folder (folder_path,outputDirectory,data_file){
	folder_name=replace(File.getName(folder_path),"/",""); //remove the final slash
	if(startsWith(folder_name,"ROI")){
		parent_folder=File.getParent(folder_path);
		folder_name=File.getName(parent_folder)+"_"+folder_name;
	}
	
	folder_name=checknames(folder_name); //has this name already been used? add 00 if it has.
	folder_list=newArray();  
	dm4_list=newArray();
	list = getFileList(folder_path); 
	for (i=0; i<list.length; i++) { 
		if(endsWith(list[i],"/")){
			folder_list=Array.concat(folder_list,list[i]); 
		}
		if(endsWith(list[i], ".dm4")) {
			dm4_list=Array.concat(dm4_list,list[i]);
		}
	}

	
	for (i=0; i<folder_list.length; i++){  
		new_path=folder_path+folder_list[i];
		scan_folder(new_path,outputDirectory,data_file);
		//print(folder_list[i]);	
	}

	previousbase="";
	count=0;
	for (i=0; i<dm4_list.length; i++){
		file_path=folder_path+dm4_list[i];
		//print(file_path);
		if(i==0){
			print(data_file,"-----\nGIF file= "+folder_name+".gif\n");
		}
		previousbase = make_small_get_info(file_path, previousbase, count,outputDirectory,data_file);  
		count++;
		
	}

	if(dm4_list.length>0){
		if(dm4_list.length>1){
			make_gif_anim(outputDirectory,outputDirectory+folder_name,dm4_list.length);  //crashed out if no gifs found (ie it went into an empty folder), so added check for count
			for (i=0; i<dm4_list.length; i++){
				delete_this=outputDirectory+i+".tmpgif.gif";
				num=File.delete(delete_this); //not sure why it outputs a number
			}
		}else{
		num=File.rename(outputDirectory+"0.tmpgif.gif",outputDirectory+folder_name+".gif");
		}
	}
}

function scan1(folder_path,outputDirectory){
	list = getFileList(folder_path); 
	for (i=0; i<list.length; i++) { 
		if(endsWith(list[i],"/")){
			folder_name=File.getName(list[i]);
			File.makeDirectory(outputDirectory+folder_name);
			file1=File.open(outputDirectory+folder_name+"/gif_info.txt");
			scan_folder(folder_path+list[i],outputDirectory+folder_name+"/",file1);
			File.close(file1);
			var files_so_far=newArray("");  //reset for when start next folder as lots of ROI_01s in test data.
		}
		
	}
}


// if running headless change these two lines so that they don't ask for input.
// eg
// dir1 = "/media/mqbssats/datastore_isilon/3view_data/";
// out = "/home/mqbssats/Desktop/test_script_gif/isilon/take2/";
// note quotation and semi colon at end of line
// comand to start headless is:
// path_to_Fiji_executable --headless -macro path_to_macro
// eg
// /home/mqbssats/Fiji.app/ImageJ-linux64 --headless -macro /home/mqbssats/Desktop/ImageJ_macros/IJ_macro_make_gifs_get_info_v5_headless.ijm



dir1 = getDirectory("Choose input directory :");
out = getDirectory("Choose Output Directory :"); 




scan1(dir1,out);


print("-----Finished!-----");