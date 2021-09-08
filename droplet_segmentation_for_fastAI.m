clear;
myFolder = uigetdir;                                                        % choose directory with image files
export = myFolder;
status = mkdir (export,'/droplet_expoert/');                                % make directory for single droplet image export
dropletfolder = '/droplet_export/';
dropletexport = strcat(export,dropletfolder);
output = identify_plane(myFolder);                                          % refer to focal plane identification function
for z = 1 : length(output)                                                  % loop over all identified wells & correct planes
    well = output(z);
    well = string(well);
    well = split(well,";");                                                 % well and plane are separated by semicolon, split
    allPos = "f*";                                                          % searchpattern for all tiles
    starttime = "sk1f*";                                                    % searchpattern for all images at t=0
    allPosInPlane = strcat(well(1),allPos,well(2),starttime);               % searchpattern for iteraring through each all tiles in identified well, in the focal plane, at start time
    NoOfPos = fullfile(myFolder,allPosInPlane);                             % identifying number of tiles
    PosIt = dir(NoOfPos);                                                   
    fixedPos = "f01";                                                       % fixing center tile
    plane = well(2)                                                         
    allTimes = strcat(well(1),fixedPos,well(2));                            % searchpattern for all time points for center tile and focal plane for one well
    NoOfTimepoints = fullfile(myFolder,allTimes);                           % identifying number of time points
    TimeIt = dir(NoOfTimepoints);
    timecounter = 1;                                                        % start at 1, t=0
    for y = 1 : length(TimeIt)                                              % iterating through all time points
        time = sprintf("sk%df*", timecounter);
        timecounter = timecounter + 1;
        poscounter = 1;                                                     % setting position to center tile
        for x = 1 : length(PosIt)                                           % iterating through all positions
            pos = sprintf("f%02d", poscounter);
            poscounter = poscounter + 1;
            PosItInPlane = strcat(well(1),pos,well(2),time);                % searchpattern for one position in one well in focal plane at one time point
            currentwell = fullfile(myFolder,PosItInPlane);                  % building whole file name
            fileaddress = dir(currentwell);                                 % getting file information
            filename = strcat(fileaddress.folder,'/',fileaddress.name);      
            rawImage = imread(filename);                                    % read file
            emptyLogical = false(1080,1080);                                % build empty binary matrix, size of input image
            fprintf(1, 'Now reading %s\n', filename);
            img = imadjust(rawImage);                                       % adjust contrast
            rfImg = rangefilt(img);                                         % apply range filter
            bImg = imbinarize(bImg);                                        % binarize image
            [centers,radii] = imfindcircles(bImg,[50 400],...               % apply Hough transform
                'Sensitivity',0.8500,...
                'EdgeThreshold',0.60,...
                'Method','PhaseCode',...
                'ObjectPolarity','Bright');
            if length(centers) > 0                                          % if circles found:
                allCircs = createCirclesMask(bImg,centers,radii);           % create a mask
                mask = imclearborder(allCircs,4);                           % get rid of droplets touching the image border
                labeledImage = bwlabel(mask, 8);                            % label the the mask
                D = bwdist(~labeledImage);                                  % watershed transformation to resolve close droplets
                D = -D;
                L = watershed(D);
                L(~labeledImage) = 0;                                       % single droplet 
                seD = strel('disk',10,8);                                  
                BWfinal = imerode(L,seD);                                    
                seD2 = strel('disk',15,8);
                noInterface = imerode(BWfinal,seD2);                        
                onlyInterface = BWfinal - noInterface;                              % only interface region separated
                labeledImage2 = bwlabel(L);                                         % label single droplet mask
                coloredLabels = label2rgb (labeledImage2, 'hsv', 'k', 'shuffle');
                blobMeasurements = regionprops(labeledImage2, img, 'all');          % get the blob properties
                numberOfBlobs = size(blobMeasurements, 1);                          % get the number of drops
                allAreas = [blobMeasurements.Area];                                 
                allPerimeters = [blobMeasurements.Perimeter];
                allCircularities = [blobMeasurements.Circularity];                  
                interfaceBlobMeasurements = regionprops(onlyInterface, img, 'MeanIntensity');     % get mean intensity for interface pixels
                interfaceMeanIntensities = [interfaceBlobMeasurements.MeanIntensity];
                roundObjectsIndexes = find(allCircularities > 0.9 & allCircularities < 1.1);      % filter for circular objects (in case watershed transform didn't resolve double droplets)
                keeperBlobsImage = ismember(labeledImage2, roundObjectsIndexes);                  % filtered
                labeledImage3 = bwlabel(keeperBlobsImage);                                        % label the filtered image
                counter2 = 1;
                counter2_max = max(labeledImage3, [], 'all');
                while counter2 <= counter2_max                                                    % loop through all blobs/single droplets
                    binaryImage2 = ismember(labeledImage3, counter2) > 0;
                    maskedImageDroplet = img;                                                     % original, contrast-adjusted image
                    maskingvalue =  interfaceMeanIntensities(counter2) ;
                    maskedImageDroplet(~binaryImage2) = maskingvalue;                             % Set all non-keeper pixels to mean intensity of interface.
                    subfolder_path = strcat(well(1),'/');                                         % create subfolders for each well and time point
                    timefolder = extractBefore(time,'*');
                    subfolder_path = strcat(dropletexport,subfolder_path);
                    if not(exist(subfolder_path))
                        mkdir(subfolder_path);
                    end
                    dropletfilename = sprintf('_Droplet_%02d.tiff', counter2);                    % creat filename for export
                    structBoundaries = bwboundaries(binaryImage2);                                % identify boundaries of droplet
                    xy=structBoundaries{1};                                                       % Get n by 2 array of x,y coordinates.
                    x = xy(:, 2);                                                                 % Columns
                    y = xy(:, 1);                                                                 % Rows
                    topLine = min(x);                                                             % Cropped image boundaries
                    bottomLine = max(x);
                    leftColumn = min(y);
                    rightColumn = max(y);
                    width = bottomLine - topLine + 1;
                    height = rightColumn - leftColumn + 1;
                    croppedDroplet = imcrop(maskedImageDroplet, [topLine, leftColumn, width, height]);      % crop the image
                    croppedDroplet = imadjust(croppedDroplet);                                              % adjust contrast
                    dropletImageID = strcat(subfolder_path,well(1),plane,pos,timefolder,dropletfilename);   % prepare export
                    imwrite(croppedDroplet,dropletImageID);                                                 % export
                    counter2 = counter2 + 1;
                end
            end
        end
    end
end
