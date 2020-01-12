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
$ ffmpeg -i src.mp4 -ss 00:00:00.000 -t 60 -vf fps=30,scale=w=640:h=360:force_original_aspect_ratio=decrease dst%06d.jpg
```

# youtube examples
- リアルタイム解説付き！momoken vs くらうど30本先取+α【ぷよぷよeスポーツ】
  - https://www.youtube.com/watch?v=2CIiWb_HRhw

# memo
```
1280x720 -> 1/2 -> 640/360 -> 1/2 -> 320/180
1h -> 60m -> 3,600s -> 216,000f (60fps)
```
