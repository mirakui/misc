import skimage
import skimage.io
import skimage.metrics
import skimage.feature
import skimage.transform
import numpy as np
import glob
import os
import shutil
from enum import Enum
import json

class Rect:
    def __init__(self, y1, y2, x1, x2):
        self.x1 = x1
        self.x2 = x2
        self.y1 = y1
        self.y2 = y2

    def crop(self, img):
        return img[self.y1:self.y2, self.x1:self.x2]

class Player(Enum):
    P1 = 0
    P2 = 1

class TsumoFrameDetector:
    def __init__(self, frame_ratio, player):
        self.player = player
        if player == Player.P1:
            self.mt_tsumo_rect = Rect(x1=232, x2=283, y1=45, y2=147)
        elif player == Player.P2:
            self.mt_tsumo_rect = Rect(x1=357, x2=408, y1=45, y2=147)
        else:
            raise ValueError('Unexpected player', player)

        self.img_field_prev = None

    # ネクスト領域で一定フレーム連続して前フレームとの差が大きかったらツモアニメーション中
    # おじゃまぷよが飛んでいくエフェクトがネクスト領域を横断することがあるが、ツモアニメーションよりフレーム数が少ない
    def detect_diff(self, img_field):
        if self.img_field_prev is None:
            self.img_field_prev = img_field
            return 0.0

        (score, diff) = skimage.metrics.structural_similarity(
            self.mt_tsumo_rect.crop(self.img_field_prev),
            self.mt_tsumo_rect.crop(img_field),
            full=True
        )
        self.img_field_prev = img_field
        return score


class RenFrameDetector:
    def __init__(self, player):
        self.img_x_path = 'img/x.png'
        self.player = player
        if player == Player.P1:
            self.mt_x_rect = Rect(x1=116, x2=225, y1=294, y2=314)
        elif player == Player.P2:
            self.mt_x_rect = Rect(x1=415, x2=524, y1=294, y2=314)
        else:
            raise ValueError('Unexpected player', player)

        self.img_x = skimage.color.rgb2gray(skimage.io.imread(self.img_x_path))

    # "x" が得点領域に表示されていたら連鎖アニメーション中
    def detect_x(self, img_field):
        result = skimage.feature.match_template(
            self.mt_x_rect.crop(img_field),
            self.img_x
        )
        score = np.max(result)
        return score


class YattaFrameDetector:
    def __init__(self):
        self.img_yatta_path = 'img/yatta.png'
        self.img_yatta = skimage.color.rgb2gray(skimage.io.imread(self.img_yatta_path))
        self.mt_yatta_rects = [
            Rect(x1=96, x2=210, y1=132, y2=160),
            Rect(x1=430, x2=544, y1=132, y2=160)
        ]

    # "やった！" が表示されていたらラウンド終了
    def detect_yatta(self, img_field):
        scores = []
        for rect in self.mt_yatta_rects:
            result = skimage.feature.match_template(
                rect.crop(img_field),
                self.img_yatta
            )
            result = skimage.feature.match_template(img_field, self.img_yatta)
            scores.append(np.max(result))
        return np.max(scores)


class WinFrameDetector:
    def __init__(self):
        self.img_win_path = 'img/win.png'
        self.img_win = skimage.color.rgb2gray(skimage.io.imread(self.img_win_path))
        self.mt_win_rect = Rect(x1=309, x2=332, y1=324, y2=335)

    # WIN の文字が画面中央下に表示されていたらゲーム中
    def detect_win(self, img_field):
        result = skimage.feature.match_template(
            self.mt_win_rect.crop(img_field),
            self.img_win
        )
        score = np.max(result)
        return score


class MemoCounter:
    def __init__(self, memo=None):
        self.reset(memo)

    def reset(self, memo=None):
        self.value = 0
        self.memo = memo
        self.frozen = False

    def inc(self):
        if not self.frozen:
            self.value += 1
        return self.value

    def freeze(self):
        self.value = 0
        self.frozen = True


class ThumbnailsAnalyzer:
    def __init__(self, frame_ratio=1.0):
        self.frame_ratio = frame_ratio
        pass

    def detect(self, src_files):
        players = (Player.P1, Player.P2)
        tsumo_frame_detectors = { p: TsumoFrameDetector(frame_ratio=self.frame_ratio, player=p) for p in players }
        ren_frame_detectors = { p: RenFrameDetector(player=p) for p in players }
        yatta_frame_detector = YattaFrameDetector()
        win_frame_detector = WinFrameDetector()

        result = { 'frames': [] }

        for f in src_files:
            frame = { 'file': os.path.basename(f) }
            img_field = skimage.io.imread(f) # ツモ順分析のためにカラー版も残しておく
            # 640x360(原寸の半分)じゃないと今のところ動かない(テンプレがそのサイズのため)
            if img_field.shape[1] != 640:
                img_field = skimage.transform.resize(img_field, (360, 640))
            img_field_gray = skimage.color.rgb2gray(img_field)

            frame['yatta'] = int(yatta_frame_detector.detect_yatta(img_field_gray) * 1000)

            frame['win'] = int(win_frame_detector.detect_win(img_field_gray) * 1000)

            frame['players'] = [
                {
                    'ren': int(ren_frame_detectors[p].detect_x(img_field_gray) * 1000),
                    'tsumo': int(tsumo_frame_detectors[p].detect_diff(img_field_gray) * 1000)
                } for p in players
            ]

            result['frames'].append(frame)
            print(frame)

        return result

    def analyze(self, detected_data):
        states = {
            'global': None,
            'ingame': False,
            Player.P1: None,
            Player.P2: None,
        }
        result = { 'frames': [] }
        players = (Player.P1, Player.P2)
        counters = {
            p: {
                'ren': MemoCounter(),
                'tsumo': MemoCounter()
            } for p in players
        }

        for frame in detected_data['frames']:
            if frame['win'] >= 800:
                if not states['ingame']:
                    # 試合開始
                    states['ingame'] = True
            else:
                if states['ingame']:
                    # 試合終了
                    states['ingame'] = False
                continue

            if frame['yatta'] >= 700:
                if states['global'] != 'yatta':
                    for p in players:
                        result['frames'].append({ 'file': frame['file'], 'type': 'eor', 'player': p.value })
                        states['global'] = 'yatta'
            else:
                states['global'] = None

            for p in players:
                f = frame['players'][p.value]

                tsumo_counter = counters[p]['tsumo']
                if f['tsumo'] <= 700 and states['ingame']:
                    tsumo_counter.inc()
                    if tsumo_counter.value >= int(8 * self.frame_ratio):
                        f_ = tsumo_counter.memo
                        result['frames'].append({ 'file': f_['file'], 'type': 'tsumo', 'player': p.value })
                        tsumo_counter.freeze()
                        states[p] = None
                else:
                    tsumo_counter.reset(memo=frame)

                # ren が終わった判定をするために、x 表示が終わった後のフレーム数を数える
                ren_counter = counters[p]['ren']
                if f['ren'] >= 600:
                    if states[p] != 'ren':
                        result['frames'].append({ 'file': frame['file'], 'type': 'ren', 'player': p.value })
                        ren_counter.reset()
                    states[p] = 'ren'
                else:
                    if states[p] == 'ren':
                        ren_counter.inc()
                        if ren_counter.value >= int(8 * self.frame_ratio):
                            states[p] = None


        return result


src_files = sorted(glob.glob('/mnt/vol/30fps-02/dst*.jpg'))
analyzer = ThumbnailsAnalyzer(frame_ratio=0.5)
#result = analyzer.analyze(src_files=src_files, frame_ratio=0.5)

detected_json_path = 'detected.json'
analyzed_json_path = 'analyzed.json'

detected_data = None
if os.path.exists(detected_json_path):
    with open(detected_json_path, 'r') as f:
        detected_data = json.load(f)
        print('Loaded', detected_json_path)
else:
    detected_data = analyzer.detect(src_files=src_files)
    with open(detected_json_path, 'w') as f:
        json.dump(detected_data, f)
        print('Saved', detected_json_path)

analyzed_data = analyzer.analyze(detected_data)
with open(analyzed_json_path, 'w') as f:
    json.dump(analyzed_data, f)
    print('Saved', analyzed_json_path)
for frame in analyzed_data['frames']:
    if 'player' in frame:
        shutil.copy(
            '/mnt/vol/30fps-02/{}'.format(frame['file']),
            '/mnt/vol/out/p{}-{}'.format(frame['player'], frame['file'])
        )
