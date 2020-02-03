# commands
```sh
$ docker run -i --init --rm -v `pwd`/vol:/mnt/vol puyo /bin/bash
```

```sh
$ youtube-dl -o [filename] [url]
```

```sh
# create thumbnails:
# https://trac.ffmpeg.org/wiki/Create%20a%20thumbnail%20image%20every%20X%20seconds%20of%20the%20video
# Output one image every ten minutes:

$ ffmpeg -i src.mp4 -vf fps=1/600 dst%04d.jpg
$ ffmpeg -i src.mp4 -ss 00:00:00.000 -t 60 -q:v 1 -vf fps=30,scale=w=640:h=360:force_original_aspect_ratio=decrease dst%06d.jpg
```

```sh
$ jupyter lab --ip=0.0.0.0 --no-browser
```

```sh
$ opencv_createsamples -info pos/poslist.txt -vec vec/pos.vec -num 1000 -maxidev 40 -maxxangle 0.8 -maxyangle 0.8 -maxzangle 0.5
$ opencv_traincascade -data cascade -vec vec/pos_puyo.vec -bg neg/neg.list -numPos 150 -numNeg 140
```

# youtube examples
- リアルタイム解説付き！momoken vs くらうど30本先取+α【ぷよぷよeスポーツ】
  - https://www.youtube.com/watch?v=2CIiWb_HRhw

# memo
- 1280x720 -> 1/2 -> 640/360 -> 1/2 -> 320/180
- 1h -> 60m -> 3,600s -> 216,000f (60fps)
- 解析は 30fps もあれば十分っぽい
- 点数に x が出たら連鎖中
- 試合終了判定は やった！ ばたんきゅー 文字？
- ネクスト枠を固定で観測して変化が起こったら手が進む
- 連鎖エフェクトが数フレーム x にかぶることがあるので考慮したい
