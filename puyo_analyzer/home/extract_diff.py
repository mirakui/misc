import skimage
import skimage.io
import skimage.metrics
import skimage.feature
import numpy as np
import glob
import os
import shutil

diff_threshold = 0.7
mt_x_threshold = 0.6
mt_yatta_threshold = 0.7

img_x = skimage.color.rgb2gray(skimage.io.imread('img/x.png'))
img_yatta = skimage.color.rgb2gray(skimage.io.imread('img/yatta.png'))
src_files = glob.glob('/mnt/vol/30fps-02/dst*.jpg')
dst_dir = '/mnt/vol/diff/'
img1 = None
keyframe_path = None
is_ren = False
is_yatta = False

seq_count = 0

for f in sorted(src_files):
    img0 = img1
    img1 = skimage.io.imread(f)
    img1 = skimage.color.rgb2gray(img1)

    if img0 is None:
        continue
    if keyframe_path is None:
        keyframe_path = f

    mt_x_result = skimage.feature.match_template(img1[294:314, 116:225], img_x)
    mt_x_score = np.max(mt_x_result)
    print('DEBUG [mt_x_score]', f, mt_x_score)
    if mt_x_score >= mt_x_threshold:
        if not is_ren:
            print('Ren:', f, mt_x_score)
            basename = os.path.basename(f)
            dst_path = dst_dir + basename
            shutil.copy(f, dst_path)
            is_ren = True
    else:
        is_ren = False

    mt_yatta_result = skimage.feature.match_template(img1, img_yatta)
    mt_yatta_score = np.max(mt_yatta_result)
    if mt_yatta_score >= mt_yatta_threshold:
        if not is_yatta:
            print('Yatta:', f, mt_yatta_score)
            basename = os.path.basename(f)
            dst_path = dst_dir + basename
            shutil.copy(f, dst_path)
            is_yatta = True
    else:
        is_yatta = False

    (score, diff) = skimage.metrics.structural_similarity(img0[45:147, 232:283], img1[45:147, 232:283], full=True)

    if score <= diff_threshold:
        seq_count += 1
        if seq_count >= 4:
            basename = os.path.basename(keyframe_path)
            print('Tsumo:', keyframe_path, score)
            dst_path = dst_dir + basename
            shutil.copy(keyframe_path, dst_path)
    else:
        seq_count = 0
        keyframe_path = f
