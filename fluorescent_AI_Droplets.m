clear;
myFolder = uigetdir;
export = myFolder;
status = mkdir (export,'/Fluorescent Droplets New/');
dropletfolder = '/Fluorescent Droplets New/';
dropletexport = strcat(export,dropletfolder);

output = identify_fluorescent_plane(myFolder);
tic
for z = 1 : length(output)
    well = output(z);
    well = string(well);
    well = split(well,";");
    allPos = "f*";
    starttime = "ch2sk1f*";
    allPosInPlane = strcat(well(1),allPos,well(2),starttime);
    NoOfPos = fullfile(myFolder,allPosInPlane);
    PosIt = dir(NoOfPos);
    fixedPos = "f01";
    plane = well(2)
    dropletcounter = 1;
    storage = table(0,0,0,0);
    storage = renamevars(storage,["Var1","Var2","Var3","Var4"], ...
                 ["Droplet ID","Cell Area","Dead Fraction","Dead Area"]);
    poscounter = 1;
    for x = 1 : length(PosIt)
        pos = sprintf("f%02d", poscounter); 
        poscounter = poscounter + 1;
        posCycle = strcat(well(1),pos,well(2),"ch2sk1f*");
        currentwell = fullfile(myFolder,posCycle);
        fileaddress = dir(currentwell);
        filename = strcat(fileaddress.folder,'/',fileaddress.name);
        rawImage = imread(filename);
        rawImage = imadjust(rawImage);
        emptyLogical = false(1080,1080);
        fprintf(1, 'Now reading %s\n', filename);
        img = imadjust(rawImage);
        BWsdil2 = rangefilt(img);
        BWsdil2 = imbinarize(BWsdil2);
        %                                     imshow(BWsdil2);
        [centers,radii] = imfindcircles(BWsdil2,[50 400],...
            'Sensitivity',0.8500,...
            'EdgeThreshold',0.60,...
            'Method','PhaseCode',...
            'ObjectPolarity','Bright');
        if length(centers) > 0
            allCircs = createCirclesMask(BWsdil2,centers,radii);
            mask = imclearborder(allCircs,4);
            %                 imshow(mask);
            labeledImage = bwlabel(mask, 8);
            D = bwdist(~labeledImage);
            D = -D;
            L = watershed(D);
            L(~labeledImage) = 0;
            seD = strel('disk',10,8);
            BWfinal = imerode(L,seD);
            seD2 = strel('disk',15,8);
            noInterface = imerode(BWfinal,seD2);
            onlyInterface = BWfinal - noInterface;
            labeledImage3 = bwlabel(L);
            coloredLabels = label2rgb (labeledImage3, 'hsv', 'k', 'shuffle');
            blobMeasurements = regionprops(labeledImage3, img, 'all');
            numberOfBlobs = size(blobMeasurements, 1);
            allAreas = [blobMeasurements.Area];
            allPerimeters = [blobMeasurements.Perimeter];
            allCircularities = [blobMeasurements.Circularity];
            interfaceMeanIntensities = [blobMeasurements.MeanIntensity];
            roundObjectsIndexes = find(allCircularities > 0.9 & allCircularities < 1.1);
            keeperBlobsImage = ismember(labeledImage3, roundObjectsIndexes);
            if length(keeperBlobsImage) > 0;
                labeledImage2 = bwlabel(keeperBlobsImage);
                counter2 = 1;
                counter2_max = max(labeledImage2, [], 'all');
                while counter2 <= counter2_max
                    binaryImage2 = ismember(labeledImage2, counter2) > 0;
                    maskedImageDroplet = img;
                    maskingvalue =  interfaceMeanIntensities(counter2) ;
                    maskedImageDroplet(~binaryImage2) = maskingvalue; % Set all non-keeper pixels to mean intensity of interface.
                    subfolder_path = strcat(well(1),'/');
                    subfolder_path = strcat(dropletexport,subfolder_path);
                    if not(exist(subfolder_path))
                        mkdir(subfolder_path);
                    end
                    dropletfilename = sprintf('Bright_Droplet_%02d.tiff', dropletcounter);
                    structBoundaries = bwboundaries(binaryImage2);
                    xy=structBoundaries{1}; % Get n by 2 array of x,y coordinates.
                    x = xy(:, 2); % Columns.
                    y = xy(:, 1); % Rows.
                    topLine = min(x);
                    bottomLine = max(x);
                    leftColumn = min(y);
                    rightColumn = max(y);
                    width = bottomLine - topLine + 1;
                    height = rightColumn - leftColumn + 1;
                    fluorescenceWellPos = extractBefore(fileaddress.name,'ch2');
                    fluorescenceFileEnd = extractAfter(fileaddress.name,'ch2');
                    channelOneID = 'ch1';
                    channelThreeID = 'ch3';
                    channelFourID = 'ch4';
                    channelFiveID = 'ch5';
                    ch1Filename = strcat(fluorescenceWellPos,channelOneID,fluorescenceFileEnd);
                    ch3Filename = strcat(fluorescenceWellPos,channelThreeID,fluorescenceFileEnd);
                    ch4Filename = strcat(fluorescenceWellPos,channelFourID,fluorescenceFileEnd);
                    ch5Filename = strcat(fluorescenceWellPos,channelFiveID,fluorescenceFileEnd);
                    ch1FullFile = strcat(fileaddress.folder,'/',ch1Filename);
                    ch3FullFile = strcat(fileaddress.folder,'/',ch3Filename);
                    ch4FullFile = strcat(fileaddress.folder,'/',ch4Filename);
                    ch5FullFile = strcat(fileaddress.folder,'/',ch5Filename);
                    
                    channelOne = imread(ch1FullFile);
                    channelThree = imread(ch3FullFile);
                    channelFour = imread(ch4FullFile);
                    channelFive = imread(ch5FullFile);
                    droplet1filename = sprintf('Ch1_Droplet_%02d.tiff', dropletcounter);
                    droplet3filename = sprintf('Ch3_Droplet_%02d.tiff', dropletcounter);
                    droplet4filename = sprintf('Ch4_Droplet_%02d.tiff', dropletcounter);
                    droplet5filename = sprintf('Ch5_Droplet_%02d.tiff', dropletcounter);
                    
                    croppedDroplet = imcrop(maskedImageDroplet, [topLine, leftColumn, width, height]);
                    croppedDroplet = imadjust(croppedDroplet);
                    
                    ch1CroppedDroplet = imcrop(channelOne, [topLine, leftColumn, width, height]);
                    ch3CroppedDroplet = imcrop(channelThree, [topLine, leftColumn, width, height]);
                    ch4CroppedDroplet = imcrop(channelFour, [topLine, leftColumn, width, height]);
                    ch5CroppedDroplet = imcrop(channelFive, [topLine, leftColumn, width, height]);
                    binaryImage2 = imcrop(binaryImage2, [topLine, leftColumn, width, height]);
                    
                    ch1CroppedDroplet(~binaryImage2) = 0;
                    ch3CroppedDroplet(~binaryImage2) = 0;
                    ch4CroppedDroplet(~binaryImage2) = 0;
                    ch5CroppedDroplet(~binaryImage2) = 0;
                    
                    dropletImageID = strcat(subfolder_path,well(1),dropletfilename);
                    droplet1ImageID = strcat(subfolder_path,well(1),droplet1filename);
                    droplet3ImageID = strcat(subfolder_path,well(1),droplet3filename);
                    droplet4ImageID = strcat(subfolder_path,well(1),droplet4filename);
                    droplet5ImageID = strcat(subfolder_path,well(1),droplet5filename);
                    imwrite(croppedDroplet,dropletImageID);
                    imwrite(ch1CroppedDroplet,droplet1ImageID);
                    imwrite(ch3CroppedDroplet,droplet3ImageID);
                    imwrite(ch4CroppedDroplet,droplet4ImageID);
                    imwrite(ch5CroppedDroplet,droplet5ImageID);

                    spheroidArea = imbinarize(ch5CroppedDroplet);
                    apoptosis = imbinarize(ch1CroppedDroplet);
                    apoptoticArea = spheroidArea .* apoptosis;
                    apoMeas = regionprops(apoptoticArea);
                    spheMeas = regionprops(spheroidArea);
                    allSpheAreas = [spheMeas.Area];
                    spheMeas = sum(allSpheAreas);
                    allApoAreas = [apoMeas.Area];
                    apoAreas = sum(allApoAreas);
                    deadFraction = apoAreas/spheMeas;
                    T = table(dropletcounter, spheMeas, deadFraction, apoAreas);
                    T = renamevars(T,["dropletcounter","spheMeas","deadFraction","apoAreas"], ...
                    ["Droplet ID","Cell Area","Dead Fraction","Dead Area"]);
                    storage = [storage ; T];
                    counter2 = counter2 + 1;
                    dropletcounter = dropletcounter + 1;
                end
            else
                display("No droplet left after filtering.");
            end
        else
            display("No droplets identified.");
        end
    end
    csvName = strcat(dropletexport,well(1),'_analysis.csv');
                writetable(storage,csvName);
end
