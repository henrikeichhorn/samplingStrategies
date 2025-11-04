function CalibrateFace_V1Model_plot_Annika(ed,mds,path2stim)
% (c) Selim Onat

% ed is the output of CalibrateFace_V1Model.
% mds is the output of V1Model2MDS.

% modified by Annika Garlichs (2021) for e.g. 8 faces 
% change line 35:  'xticks(1:10);' according to how many images you have (for labeling of
% the xaxis of the RDM).
% V1 names must contain 3-letter/digit description (e.g., 'F01').

% merge dimensions according perceptual weights of RGB channels
label_names = dir([path2stim '*.bmp'])

if ndims(ed) == 3
    w  = [0.229,0.587,0.114];
    ed = ed(:,:,1)*w(1) + ed(:,:,2)*w(2)+ed(:,:,3)*w(3);
end

figure('position',[3 321 1285 345])

% get picture names
timage = size(ed,1);
for n = 1:timage
    labels{n,1} = label_names(n).name(1:3);
end;

% plot matrix of euclidian distances
subplot(1,2,1)
imagesc(ed);
colorbar;
colormap jet;
axis image
title('RDM')
xticks(1:8);  % adjust according to RDM size
yticklabels(labels);
xticklabels(labels);

% plot the MDS results (for 8 faces)

subplot(1,2,2)
if size(mds,2) == 2
    % 2d plot
    plot(mds(:,1),mds(:,2),'o')
    text(mds(:,1),mds(:,2),labels,'fontsize',10)
    hold on
    axis square
    axis equal
    xlabel 'Dimension 1'
    ylabel 'Dimension 2'
else
    % 3d plot
    plot3(mds(:,1),mds(:,2),mds(:,3),'o-')
    text(mds(:,1),mds(:,2),mds(:,3),labels,'fontsize',8)
    axis square
    axis equal
    xlabel 'Dimension 1'
    ylabel 'Dimension 2'
    zlabel 'Dimension 3'
end