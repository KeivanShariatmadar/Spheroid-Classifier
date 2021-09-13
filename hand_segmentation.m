clear;  % Delete all variables.
close all;  % Close all figure windows except those created by imtool.
imtool close all;  % Close all figure windows created by imtool.
workspace;  % Make sure the workspace panel is showing.
fontSize = 16;
myFolder = uigetdir;
export = strcat(myFolder,'/');
status = mkdir (export,'/Droplets manual/');
dropletfolder = '/Droplets manual/';
dropletexport = strcat(export,dropletfolder);
status = mkdir (dropletexport,'apop export/');
apopfolder = 'apop export/';
labeledfolder = 'Labeled cells/';
status = mkdir (dropletexport,'Labeled cells/');
labeledexport = strcat(dropletexport,labeledfolder);
maskfolder = 'masks/'
status = mkdir (dropletexport,'masks/');
maskexport = strcat(dropletexport,maskfolder);
croppedfolder = 'graycells/'
status = mkdir (dropletexport,'graycells/');
grayexport = strcat(dropletexport,croppedfolder);
currentwell = fullfile(myFolder,'*Bright_Droplet*');
fileaddress = dir(currentwell);
dropletcounter = 1;
for z = 1 : length(fileaddress)
    maskname = sprintf('Binary_%02d.mat', dropletcounter);
    labeledname = sprintf('Labeled_%02d.mat', dropletcounter);
    graycellsname = sprintf('Masked_Gray_%02d.tiff', dropletcounter);
    close all;
    imtool close all;
    workspace;
    brightDropletIteration = sprintf('*Bright_Droplet_%02d.tiff', dropletcounter);
    currentFile = fullfile(myFolder,brightDropletIteration);
    fileaddress = dir(currentFile);
    brightFileName = strcat(fileaddress.folder,'/',fileaddress.name);
    I = imread(brightFileName);
    grayImage = I;
    figure('WindowState', 'maximized'); imshow(I, []);
    decision = menu('Can you work with this?','Yes','No');
    if decision==2 | decision==0
        dropletcounter = dropletcounter +1;
    else
    roi = images.roi.AssistedFreehand;
    draw(roi);
    combinedMask = createMask(roi);
    while(1)
        choice = menu('Any areas to add?','Yes','No');
        if choice==2 | choice==0
            break;
        end
        roi2 = images.roi.AssistedFreehand;
        draw(roi2);
        mask2 = createMask(roi2);
        combinedMask = imbinarize(imadd(mask2, combinedMask));
    end
    pause(1);
    imshow(combinedMask); title('Combined Mask');
    pause(1);
    labeledImage3 = bwlabel(combinedMask);
    measurements = regionprops(combinedMask, grayImage, ...
        'area', 'Centroid', 'WeightedCentroid', 'Perimeter');
    cellImage = grayImage;
    cellImage(~combinedMask) = 0;
    labeledfullname = strcat(labeledexport,labeledname);
    save(labeledfullname,'labeledImage3');
    maskfullname = strcat(maskexport,maskname);
    save(maskfullname,'combinedMask');
    grayfullname = strcat(grayexport,graycellsname);
    imwrite(cellImage,grayfullname);
    dropletcounter = dropletcounter + 1;
    end
end
