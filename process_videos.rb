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
    
    def go_videos
      Dir["#{SRC_PATH}/*"].sort.reverse.each do |file_path|
        next unless EXT.include?(File.extname(file_path).downcase)
        next unless File.basename(file_path)=~/\A2/
        extract_images(file_path) unless has_images?(file_path)
        out_file_path=File.join(DST_PATH,File.basename(file_path, File.extname(file_path)).gsub(" ",'_') ) + ".mp4"
        convert_to_h264(file_path,out_file_path) unless File.exists?(out_file_path)
      end
    end
    
    TAG_START='START_MOVIES'
    TAG_END='END_MOVIES'
    TAG_REGEXP=Regexp.new('\n[^\n]+'+TAG_START+'.*'+TAG_END+'[^\n]+\n',Regexp::MULTILINE)
    def go_html
      arr=[]
      new_html=''
      (2003..Time.now.year).to_a.each do |year|
        new_html=''
        Dir["#{DST_PATH}/#{year}*"].sort.reverse.each do |file_path|
          next if file_path =~ /Alex_Born_Uncut/ # Skip the explicit video
          movie_path=File.basename(file_path).gsub(" ",'_') 
          file_name = base_name(file_path)
          nice_file_name = file_name.gsub('_',' ')
          puts nice_file_name
          images = Dir[image_file_name_stub(file_path)+"*"].sort.collect{|f| File.basename(f)}
          image_name=images.first

  new_html+=<<-EOT
  <div class="miniBox">
    <div class="photo">
      <a href="movies/#{movie_path}" class="jqModal">
        <img vspace="0" hspace="0" border="0"  alt="#{nice_file_name}" title="#{nice_file_name}"  width="100" height="100" src="movie_images/#{image_name}" class="imgBorder" />
      </a>
    </div>
    <p class="albumTitle" id="albumTitle_#{file_name}">
      <a href="movies/#{movie_path}" class="nav jqModal">#{nice_file_name}</a>
    </p>
  	<p class="description"></p>
  	<p class="updated"></p>
    <div class="spacer"></div>
  </div>
  EOT

        end
        html = File.read("template.html").gsub(TAG_REGEXP) { new_html}
        filename = year==Time.now.year ? 'videos.html' : "#{year}.html"
        File.open(filename,"w") {|f| f << html }
      end
    end
    
    def has_images?(file_path)
      File.exists?(image_file_name_stub(file_path) + "_001.png") or File.exists?(image_file_name_stub(file_path) + "_000.png")
    end

    def extract_images(file_path)
      puts "\n\nExtract Images for #{file_path}\n\n"
      pattern = image_file_name_stub(file_path) + "_%03d.png"
      # Extract 1 image per second of a thumbnail size for the first 20 seconds of the video
      cmd = %Q!ffmpeg -i "#{file_path}" -r 1 -f image2 -s 120x96 -t 20 #{pattern}!
      `#{cmd}`
    end

    def image_file_name_stub(file_path)
      IMG_PATH + "/" + base_name(file_path)
    end
    
    def base_name(file_path)
      File.basename(file_path, File.extname(file_path)).gsub(" ",'_') 
    end
    
    def convert_to_h264(file_path,out_file_path)
      puts "\n\nConvert to h264 MP4 #{file_path}\n\n"
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

valid_cmds = ['go_videos', 'go_html']
valid_cmds_str = "(#{valid_cmds.join('|')})"
if ARGV[0] =~ Regexp.new('\A'+valid_cmds_str+'\Z')
  VideoProcess.send(ARGV[0])
else
  puts "usage: process_videos.rb #{valid_cmds_str}"
end

