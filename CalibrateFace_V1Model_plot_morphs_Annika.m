function CalibrateFace_V1Model_plot_morphs_Annika(ed,mds,path2stim)
% (c) Selim Onat

% ed is the output of CalibrateFace_V1Model.
% mds is the output of V1Model2MDS.

% modified by Annika Garlichs (2021) for 8 faces

% merge dimensions according perceptual weights of RGB channels
if ndims(ed) == 3
    w  = [0.229,0.587,0.114];
    ed = ed(:,:,1)*w(1) + ed(:,:,2)*w(2)+ed(:,:,3)*w(3);
end

figure('position',[3 321 1285 345])

% plot matrix of euclidian distances
subplot(1,2,1)
imagesc(ed);colorbar;colormap jet;
axis image
title('Norm of the Difference')

% plot the MDS results (for 8 faces)
label_names = {'F1'; 'F2'; 'F3'; 'F4'; 'F5'; 'F6'; 'F7'; 'F8'};
subplot(1,2,2)
timage = size(ed,1);
if size(mds,2) == 2
    % % 2d plot
    plot(mds(:,1),mds(:,2),'o')
    text(mds(:,1),mds(:,2),label_names,'fontsize',10)
    hold on
    axis square
    axis equal
else
    % 3d plot
    plot3(mds(:,1),mds(:,2),mds(:,3),'o-')
    text(mds(:,1),mds(:,2),label_names,'fontsize',8)
    axis square
    axis equal
end