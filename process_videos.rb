#!/usr/bin/env ruby

# ffmpeg processing inspired by http://h264.code-shop.com/trac/wiki/Encoding
# Resulting mp4 files work on iPhone
# ffmpeg installed via MacPorts
# to install qt-faststart, download the source for ffmpeg and find the src file then compile:
#    gcc qt-faststart.c -o qt-faststart

SRC_PATH="/Users/chrisfinne/Movies"
DST_PATH="#{SRC_PATH}/small"
IMG_PATH="#{DST_PATH}/images"
EXT=['.avi', '.wmv']


class VideoProcess
  class << self
    
    def go
      Dir["#{SRC_PATH}/*"].sort.reverse.each do |file_path|
        next unless EXT.include?(File.extname(file_path).downcase)
        next unless File.basename(file_path)=~/\A2/
        puts "\n\nExtract Images for #{file_path}\n\n"
        extract_images(file_path) unless has_images?(file_path)
        out_file_path=File.join(DST_PATH,File.basename(file_path, File.extname(file_path)).gsub(" ",'_') ) + ".mp4"
        puts "\n\nConvert to h264 MP4 #{file_path}\n\n"
        convert_to_h264(file_path,out_file_path) unless File.exists?(out_file_path)
      end
    end
    
    def go_html
      arr=[]
      Dir["#{DST_PATH}/*"].sort.reverse.each do |file_path|
        images = Dir[image_file_name_stub(f)+"*"].sort.collect{|f| File.basename(f)}
        arr << {:movie=>File.basename(file_path),  :images=>images}
      end
      
    end
    
    def has_images?(file_path)
      File.exists?(image_file_name_stub(file_path) + "_001.png") or File.exists?(image_file_name_stub(file_path) + "_000.png")
    end

    def extract_images(file_path)
      pattern = image_file_name_stub(file_path) + "_%03d.png"
      # Extract 1 image per second of a thumbnail size for the first 20 seconds of the video
      cmd = %Q!ffmpeg -i "#{file_path}" -r 1 -f image2 -s 120x96 -t 20 #{pattern}!
      `#{cmd}`
    end

    def image_file_name_stub(file_path)
      IMG_PATH + "/" + File.basename(file_path, File.extname(file_path)).gsub(" ",'_') 
    end
    
    def convert_to_h264(file_path,out_file_path)
      tmp_file='process_video_tmp_file.mp4'
      options="-vcodec libx264 -b 512k -flags +loop+mv4 -cmp 256 \
      	   -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 \
      	   -me_method hex -subq 7 -trellis 1 -refs 5 -bf 0 \
      	   -flags2 +mixed_refs -coder 0 -me_range 16 \
           -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10\
      	   -qmax 51 -qdiff 4 -threads 0"
      
      cmd = [%Q!ffmpeg -y -i "#{file_path}" -an -pass 1 #{options} "#{tmp_file}"!]
      cmd << %Q!ffmpeg -y -i "#{file_path}" -acodec libfaac -ar 44100 -ab 96k -pass 2 #{options} "#{tmp_file}"!
      cmd << %Q!qt-faststart "#{tmp_file}" "#{out_file_path}"!
      cmd << %Q!rm -f "#{tmp_file}" x264_2pass.log!
      cmd.each {|c| `#{c}`}
    end

  end
end

VideoProcess.go
