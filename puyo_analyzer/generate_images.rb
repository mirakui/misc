def main
  puyo_width = 42
  puyo_height = 39
  puyo_sozai_vnum = 5
  puyo_sozai_hnum = 5
  bg_width = 640
  bg_height = 360
  puyo_sozai_path = 'img/puyo_sozai.png'
  bg_path = 'img/bg2.png'
  dst_path_prefix = 'dst/puyo-'
  puyo_idx = 0

  0.step(255, 5) do |gray|
    puyo_sozai_hnum.times do |h|
      puyo_sozai_vnum.times do |v|
        puyo_sozai_x = h * puyo_width
        puyo_sozai_y = v * puyo_height
        dst_path = '%s%06d.png' % [dst_path_prefix, puyo_idx]

        cmd = %Q!convert -size #{puyo_width}x#{puyo_height} xc:'rgb(#{gray},#{gray},#{gray})'!
        cmd += %Q! -draw "image over #{-puyo_sozai_x},#{-puyo_sozai_y} 0,0 '#{puyo_sozai_path}'"!
        cmd += %Q! #{dst_path}!

        puts cmd
        system cmd

        puyo_idx += 1
      end
    end
  end

end

main
