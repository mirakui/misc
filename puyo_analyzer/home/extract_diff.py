import skimage
import skimage.io
import skimage.metrics
import skimage.feature
import skimage.transform
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

class TsumoFrameDetector:
    def __init__(self, frame_ratio):
        self.mt_tsumo_threshold = 0.7
        self.tsumo_frames_threshold = 8 * frame_ratio
        self.mt_tsumo_rect = Rect(x1=232, x2=283, y1=45, y2=147)
        self.tsumo_seq_count = 0
        self.keyframe_path = None
        self.img_field_prev = None

    # ネクスト領域で一定フレーム連続して前フレームとの差が大きかったらツモアニメーション中
    # おじゃまぷよが飛んでいくエフェクトがネクスト領域を横断することがあるが、ツモアニメーションよりフレーム数が少ない
    def detect(self, img_field, f):
        if self.img_field_prev is None:
            self.img_field_prev = img_field
            return None

        (score, diff) = skimage.metrics.structural_similarity(
            self.mt_tsumo_rect.crop(self.img_field_prev),
            self.mt_tsumo_rect.crop(img_field),
            full=True
        )
        self.img_field_prev = img_field
        if score <= self.mt_tsumo_threshold:
            self.tsumo_seq_count += 1
            if self.tsumo_seq_count >= self.tsumo_frames_threshold:
                print('Tsumo:', self.keyframe_path, score)
                basename = os.path.basename(self.keyframe_path)
                return { 'file': basename, 'type': 'tsumo', 'player': 0 }
        else:
            self.tsumo_seq_count = 0
            self.keyframe_path = f
            return None


class RenFrameDetector:
    def __init__(self):
        self.mt_x_threshold = 0.6
        self.img_x_path = 'img/x.png'
        self.mt_x_rect = Rect(x1=116, x2=225, y1=294, y2=314)
        self.img_x = skimage.color.rgb2gray(skimage.io.imread(self.img_x_path))

    # "x" が得点領域に表示されていたら連鎖アニメーション中
    def detect(self, img_field, f):
        basename = os.path.basename(f)

        result = skimage.feature.match_template(
            self.mt_x_rect.crop(img_field),
            self.img_x
        )
        score = np.max(result)
        if score >= self.mt_x_threshold:
            print('Ren:', basename, score)
            return { 'file': basename, 'type': 'ren', 'player': 0 }


class YattaFrameDetector:
    def __init__(self):
        self.mt_yatta_threshold = 0.7
        self.img_yatta_path = 'img/yatta.png'
        self.img_yatta = skimage.color.rgb2gray(skimage.io.imread(self.img_yatta_path))

    # "やった！" が表示されていたらラウンド終了
    def detect(self, img_field, f):
        basename = os.path.basename(f)

        result = skimage.feature.match_template(img_field, self.img_yatta)
        score = np.max(result)
        if score >= self.mt_yatta_threshold:
            print('Yatta:', basename, score)
            return { 'file': basename, 'type': 'eor' }
        else:
            return None


class ThumbnailsAnalyzer:
    def __init__(self):
        pass

    def analyze(self, src_files, frame_ratio=1.0):
        is_ren = False
        is_yatta = False
        result = { 'frames': [] }

        tsumo_frame_detector = TsumoFrameDetector(frame_ratio=frame_ratio)
        ren_frame_detector = RenFrameDetector()
        yatta_frame_detector = YattaFrameDetector()

        for f in src_files:
            img_field = skimage.io.imread(f) # ツモ順分析のためにカラー版も残しておく
            # 640x360(原寸の半分)じゃないと今のところ動かない(テンプレがそのサイズのため)
            if img_field.shape[1] != 640:
                img_field = skimage.transform.resize(img_field, (360, 640))
            img_field_gray = skimage.color.rgb2gray(img_field)
            basename = os.path.basename(f)

            if not is_yatta:
                yatta_frame = yatta_frame_detector.detect(img_field_gray, f)
                if yatta_frame:
                    result['frames'].append(yatta_frame)
                    is_yatta = True
                    continue

            if not is_ren:
                ren_frame = ren_frame_detector.detect(img_field_gray, f)
                if ren_frame:
                    result['frames'].append(ren_frame)
                    is_ren = True
                    continue

            tsumo_frame = tsumo_frame_detector.detect(img_field_gray, f)
            if tsumo_frame:
                result['frames'].append(tsumo_frame)
                is_yatta = False
                is_ren = False
                continue

        return result

src_files = sorted(glob.glob('/mnt/vol/30fps-02/dst*.jpg'))
analyzer = ThumbnailsAnalyzer()
result = analyzer.analyze(src_files=src_files, frame_ratio=0.5)

print(result)
