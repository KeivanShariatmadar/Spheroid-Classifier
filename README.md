# Spheroid-Classifier
Containing scripts to segment single droplet images from PE Opera Phenix automated microscope, CNN based classification and fluorescence analysis

## Workflow
### droplet_segmentation_for_fastAI.m
MATLAB script that exports cropped single-droplet images for downstream CNN analysis. Uses identify_plane.m to find appropriate focal plane.
### training_fastAI.ipynb
Streamlined script to train a ResNet50 for image analysis. Uses folders with annotated single-droplet images as input. Exports a trained model and vocabulary. Jupyter Notebook.
### classification.ipynb
Script using trained CNN to classify an image dataset. Uses single-droplet images, the trained model and vocabulary. Exports predictions. Jupyter Notebook.
### fluorescent_droplet_cropping.m
MATLAB script segmenting fluorescent channels based on bright field imaging. Exports cropped single-droplet images in several channels.
### hand_segmentation.m
MATLAB script to segment cell area by using a stylus pen (we used a mirrored iPad Pro + pen).
