import skimage
from skimage import io, metrics
import glob
import os
import shutil

diff_threshold = 0.7

src_files = glob.glob('/mnt/vol/30fps-02/dst*.jpg')
dst_dir = '/mnt/vol/diff/'
img1 = None
keyframe_path = None

seq_count = 0

for f in sorted(src_files):
    img0 = img1
    img1 = skimage.io.imread(f)
    img1 = skimage.color.rgb2gray(img1[45:147,232:283])

    if img0 is None:
        continue
    if keyframe_path is None:
        keyframe_path = f

    (score, diff) = skimage.metrics.structural_similarity(img0, img1, full=True)

    if score <= diff_threshold:
        seq_count += 1
        if seq_count >= 4:
            basename = os.path.basename(keyframe_path)
            print(keyframe_path, score)
            dst_path = dst_dir + basename
            shutil.copy(keyframe_path, dst_path)
    else:
        seq_count = 0
        keyframe_path = f
