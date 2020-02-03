import skimage
import skimage.io
import skimage.metrics
import skimage.feature
import numpy as np
import glob
import os
import shutil

class Rect:
    def __init__(self, y1, y2, x1, x2):
        self.x1 = x1
        self.x2 = x2
        self.y1 = y1
        self.y2 = y2

    def crop(self, img):
        return img[self.y1:self.y2, self.x1:self.x2]

class ThumbnailsAnalyzer:
    def __init__(self):
        self.mt_tsumo_threshold = 0.7
        self.mt_x_threshold = 0.6
        self.mt_yatta_threshold = 0.7
        self.tsumo_frames_threshold = 4
        self.img_x_path = 'img/x.png'
        self.img_yatta_path = 'img/yatta.png'
        self.mt_x_rect = Rect(x1=116, x2=225, y1=294, y2=314)
        self.mt_tsumo_rect = Rect(x1=232, x2=283, y1=45, y2=147)

    def analyze(self, src_files, dst_dir):
        img_x = skimage.color.rgb2gray(skimage.io.imread(self.img_x_path))
        img_yatta = skimage.color.rgb2gray(skimage.io.imread(self.img_yatta_path))

        img1 = None
        is_ren = False
        is_yatta = False

        seq_count = 0

        for f in src_files:
            img0 = img1
            img1 = skimage.io.imread(f)
            img1 = skimage.color.rgb2gray(img1)
            basename = os.path.basename(f)

            if img0 is None:
                continue

            mt_x_result = skimage.feature.match_template(
                self.mt_x_rect.crop(img1),
                img_x
            )
            mt_x_score = np.max(mt_x_result)
            # print('DEBUG [mt_x_score]', f, mt_x_score)
            if mt_x_score >= self.mt_x_threshold:
                if not is_ren:
                    print('Ren:', basename, mt_x_score)
                    shutil.copy(f, dst_dir + basename)
                    is_ren = True
                    continue
            else:
                is_ren = False

            mt_yatta_result = skimage.feature.match_template(img1, img_yatta)
            mt_yatta_score = np.max(mt_yatta_result)
            if mt_yatta_score >= self.mt_yatta_threshold:
                if not is_yatta:
                    print('Yatta:', basename, mt_yatta_score)
                    shutil.copy(f, dst_dir + basename)
                    is_yatta = True
                    continue
            else:
                is_yatta = False

            # (score, diff) = skimage.metrics.structural_similarity(img0[45:147, 232:283], img1[45:147, 232:283], full=True)
            (score, diff) = skimage.metrics.structural_similarity(
                self.mt_tsumo_rect.crop(img0),
                self.mt_tsumo_rect.crop(img1),
                full=True
            )

            if score <= self.mt_tsumo_threshold:
                seq_count += 1
                if seq_count >= self.tsumo_frames_threshold:
                    print('Tsumo:', keyframe_path, score)
                    dst_path = dst_dir + os.path.basename(keyframe_path)
                    shutil.copy(keyframe_path, dst_path)
            else:
                seq_count = 0
                keyframe_path = f

src_files = sorted(glob.glob('/mnt/vol/30fps-02/dst*.jpg'))
dst_dir = '/mnt/vol/diff/'
analyzer = ThumbnailsAnalyzer()
analyzer.analyze(src_files=src_files, dst_dir=dst_dir)
