
function WellsAndPlanesToBeUsed = identify_plane(myFolder)
searchpattern = 'r01c01*p01*sk1f*';
counter = 1;
%%
filePattern = fullfile(myFolder, searchpattern);                            % start at row 1, column 1, center tile, time point 1
theFiles = dir(filePattern);
L = length(theFiles);
row = extractBetween(searchpattern,1,3);
rowstr = string(row);
WellsAndPlanesToBeUsed = string.empty;
wellcount = 0;
%%
for r = 1:16                                                                % loop through rows (max. 348 well plate, otherwise adjust)
    poscounter = 1;
    if L == 0
        for cl = 1 : 24                                                     % loop through columns (max. 348 well plate, otherwise adjust)
            poscounter = 1;
            if L == 0
                col = extractBetween(searchpattern,4,6);
                colstr = sprintf('c%02d', cl);
                searchpattern = replace(searchpattern,col,colstr);
                filePattern2 = fullfile(myFolder, searchpattern);
                theFiles2 = dir(filePattern2);
                L = length(theFiles2);
            else display ('Found A Well!')
                %%
                timecounter = 1;
                planecounter = 1;
                wellcount = wellcount + 1;
                candrowstr = strcat(rowstr,colstr);
                position = sprintf('f%02d',poscounter);                     % identify number of planes
                planewildcard = sprintf('p*sk1f*');
                planetime = sprintf('p%02d*sk1f*', planecounter);
                posplanewildcard = strcat(position,planewildcard);
                poswildcardplane = strcat(candrowstr,'*',planetime);
                planepattern = strcat(candrowstr,posplanewildcard);
                planehit = fullfile(myFolder, planepattern);
                planefiles = dir(planehit);
                samplesfiles = planefiles;
                planeL = length(planefiles);                                % number of planes
                pospattern = poswildcardplane;
                poshit = fullfile(myFolder, pospattern);
                posfiles = dir(poshit);
                posL = length(posfiles);                                    % number of tiles
                sampleL = times(posL,1/3);                                  % cut tile number to 1/3 to speed up
                sampleL = round(sampleL);
                infocus_droplets = 0;
                planecounter = 1;
                for p = 1:length(planefiles)                               % loop through planes
                    planetime = sprintf('p%02d*sk1f*', planecounter);       % at time point 1
                    poswildcardplane = strcat(candrowstr,'*',planetime);
                    pospattern = poswildcardplane;                          % updating searchpattern
                    poshit = fullfile(myFolder, pospattern);                % getting files
                    posfiles = dir(poshit);
                    samplecounter = 1;
                    segmentedCells = 0;
                    founddroplets = 0;
                    while samplecounter <= posL
                        baseFileName = posfiles(samplecounter).name;
                        fullFileName = fullfile(posfiles(samplecounter).folder, baseFileName);
                        fprintf(1, 'Nowreading %s\n', fullFileName);
                        imageArray = imread(fullFileName);                  % read image file
                        img = imadjust(imageArray);                         % adjust contrast
                        rImg = rangefilt(img);                              % apply range filter
                        bImg = imbinarize(rImg);                            % binarize image
                        %                     imshow(BWsdil2);
                        %% Droplet segmentation (similar to segmentation in full script)
                        [centers,radii] = imfindcircles(bImg,[50 400],...   % apply Hough transform
                            'Sensitivity',0.8500,...
                            'EdgeThreshold',0.60,...
                            'Method','PhaseCode',...
                            'ObjectPolarity','Bright');
                        if length(centers) == 0
                            display('No droplets to segment!');             % if no droplets are found, error message is displayed
                            samplecounter = samplecounter + sampleL;
                            infocus_droplets = 0;
                        else
                            display('Success!');                                % if droplets are found, affirmative message is displayed
                            founddroplets = founddroplets + length(centers);    % numbers are added
                            samplecounter = samplecounter + sampleL;
                            allCircs = createCirclesMask(bImg,centers,radii);   % mask is created
                            mask = imclearborder(allCircs,4);                   % clear image-bordering circles
                            labeledImage = bwlabel(mask, 8);                     % create labeled mask
                            D = bwdist(~labeledImage);                                      % watershed transform to resolve close droplets
                            D = -D;
                            L = watershed(D);
                            L(~labeledImage) = 0;
                            seD = strel('disk',10,8);
                            BWfinal = imerode(L,seD);                                                   % erode circles
                            labeledImage3 = bwlabel(BWfinal);                                           % label eroded mask
                            blobMeasurements = regionprops(labeledImage3, img, 'all');                  % get region properties
                            numberOfBlobs = size(blobMeasurements, 1);                                  % get blob number
                            measurements = regionprops(labeledImage, 'Area', 'Perimeter');               % get area and perimeter of circles
                            allAreas = [measurements.Area];
                            allPerimeters = [measurements.Perimeter];
                            allCircularities = allPerimeters  .^ 2 ./ (4 * pi* allAreas);
                            roundObjectsIndexes = find(allCircularities > 0.9 & allCircularities < 1.1);
                            keeperBlobsImage = ismember(labeledImage, roundObjectsIndexes);                 % only keep circular blobs (if watershed didn't work)
                            labeledImage2 = bwlabel(keeperBlobsImage);
                            counter2 = 1;
                            counter2_max = max(labeledImage2, [], 'all');
                            segmentedCells = 0;
                            %% Droplet content segmentation
                            while counter2 <= counter2_max
                                counter2 = counter2 + 1;
                                binaryImage2 = ismember(labeledImage2, counter2) > 0;
                                maskedImageDroplet = imageArray;                            % Simply a copy at first.
                                maskedImageDroplet(~binaryImage2) = 15000;                  % Set all non-keeper pixels to 15000.
                                [~,threshold] = edge(maskedImageDroplet,'sobel');           % find edges
                                fudgeFactor = 3;
                                BWs = edge(maskedImageDroplet,'sobel',threshold * fudgeFactor); % binarize edges
                                se90 = strel('line',3,90);
                                se0 = strel('line',3,0);
                                BWsdil = imdilate(BWs,[se90 se0]);                              % dilate
                                BWdfill = imfill(BWsdil,'holes');                               % fill holes
                                seD = strel('disk',4,8);
                                BWfinal = imerode(BWdfill,seD);                                 % erode
                                BWsdil2 = imdilate(BWfinal,[se90 se0]);                         % dilate again
                                labeledImage = bwlabel(BWsdil2, 8);
                                blobMeasurements = regionprops(labeledImage, imageArray, 'all');    % get content region properties
                                numberOfBlobs = size(blobMeasurements, 1);                          % get number of blobs
                                allAreas = [blobMeasurements.Area];
                                allCircularities = [blobMeasurements.Circularity];
                                allSolidities = [blobMeasurements.Solidity];
                                CellIndexes = find(allAreas > 100 & allAreas < 10000 & allCircularities <0.95 & allCircularities >0.1 &  allSolidities >0.6 & allSolidities <0.98);
                                CellIndexes2 = find(allAreas > 100 & allAreas < 10000 & allCircularities >1.05 & allSolidities >0.6 & allSolidities <0.98);
                                AllIndexes = [CellIndexes,CellIndexes2];                                                                                                                    % filter for cell like structures
                                cutoff = (length(AllIndexes));
                                segmentedCells = segmentedCells + cutoff;                           % tabulate number of cells
                            end
                        end
                    end
                    noSegmentedCellsandDroplets = segmentedCells + founddroplets;
                    planeresults(planecounter) = noSegmentedCellsandDroplets;
                    planecounter = planecounter + 1;
                end
                maximum = max(max(planeresults));
                planeselect = find(planeresults==maximum);                          % find the plane with the highest number of segmented droplets and droplet contents
                WellStorage = string.empty;
                for ps = 1:length(planeselect)
                    splaneselect = planeselect(ps)
                    planeID = sprintf(';p%02d*', splaneselect);
                    wellID = candrowstr;
                    wellPlanes = strcat(wellID,planeID);
                    WellStorage(ps)=wellPlanes;
                end
                WellsAndPlanesToBeUsed = [WellsAndPlanesToBeUsed,WellStorage];
                wellcount = wellcount + length(planeselect);
                display('Looking for next well.');
                counter = counter + 1;
                col = extractBetween(searchpattern,4,6);
                colstr = string(col);
                colstr = sprintf('c%02d', cl);
                searchpattern = replace(searchpattern,col,colstr);
                filePattern2 = fullfile(myFolder, searchpattern);
                theFiles2 = dir(filePattern2);
                L = length(theFiles2);
            end
        end
        counter = counter + 1;
        row = extractBetween(searchpattern,1,3);
        rowstr = string(row);
        rowstr = sprintf('r%02d', r);
        searchpattern = replace(searchpattern,row,rowstr);
        filePattern2 = fullfile(myFolder, searchpattern); % Change to whatever pattern you need.
        theFiles2 = dir(filePattern2);
        L = length(theFiles2);
    end
end


