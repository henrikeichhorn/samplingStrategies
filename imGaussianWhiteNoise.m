%% Generating random white noise
% because the built-in Matlab function imnoise.m only produces colourful
% noise to an RGB-image, this is a script which adds a defined percentage
% number of random noise (i.e., white pixels) to a RGB-image

% please note that this function only gives an approximate amount of
% desired noise due to the random number generation of a Gaussian normal
% distribution 

function im_noisy = imGaussianWhiteNoise(im, p) % p = % of noise you want (e.g., 10)

noise = randn(size(im, 1, 2)); % generate random numbers (matrix with the size of im's first two dimensions) of a normal Gaussian distribution with mean 0 and standard deviation 0.01
percentile = 100-p; % if you want to have 10% noise, this will give the percentile for 90% (the cut-off value for the upper 10% values of the random Gaussian distribution)
percentile_cutoff = prctile(noise, percentile,'all');

noisy_template = zeros(size(noise));  % in order to transform the 

% for-loop in order to transform the random numbers into a template for p%
% noise where entries with 255 equal to white noise pixels
for i = 1:size(noise,1) % number of rows
    for ii = 1:size(noise,2) % number of columns
        if noise(i,ii) >= percentile_cutoff % replace all values of the random number matrix that are >= percentile with 255 (= white)
           noisy_template(i,ii) = 255;
        else
           noisy_template(i,ii) = 0; % other with 0 (= black)
        end
    end
end

%% to check whether in the noisy_template approximately p% of the values are 255 (= white)
% figure;
% histogram(noisy_template); % visually check whether approximately 10% of the values are 255 (= white)

%% replace values in the image with noise according to the noisy_template
im_noisy = im; % duplicate image

for row = 1:size(noisy_template,1)
    for col = 1:size(noisy_template,2)
        if noisy_template(row,col) == 255
           for  RGB_dimensions = 1:3 % go through all three RGB-channels and replace pixels with white (= 255)
                im_noisy(row,col,RGB_dimensions) = 255;
           end
        end
    end
end


%%
% number_of_white_pixels = sum(im_noisy(:) == 255); % check whether it worked to replace pixels with 255

% figure to compare the original to the noisy image
% figure;
% subplot(2,2,1), imshow(im)
% subplot(2,2,2), imshow(im_noisy)


end
