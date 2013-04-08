require 'rubygems'
require 'streamio-ffmpeg'
require 'open-uri'
require "digest/md5"

Transcoder::App.controller do
  
  get "/transcodeaudio" do
    
    src = params[:source]

    
    file = Tempfile.new("foo.caf") #change this to expected audio input format.
    file.binmode
    open(src) { |data| file.write data.read }

    movie = FFMPEG::Movie.new(file.path)
    puts movie.duration # 7.5 (duration of the movie in seconds)
    puts movie.bitrate # 481 (bitrate in kb/s)
    puts movie.size # 455546 (filesize in bytes)

    
    puts movie.audio_codec # "aac"
    puts movie.audio_sample_rate # 44100
    puts movie.audio_channels # 2

    out = Tempfile.new("out.#{format}")
    dest = "#{File.dirname(out.path)}/out.#{format}"
    
    if format == "ogg"
      options = {audio_codec: "libvorbis", audio_bitrate: 32, audio_sample_rate: 22050, audio_channels: 1,
           threads: 2}
    elsif format == "mp3"
      options = {custom: "--cbr 32kbps"}
    end






    movie.transcode(dest, options) if !options.nil?
    movie.transcode(dest) if options.nil?


    if format == "mp3"
      content_type 'audio/mpeg'
      filesize = File.size(dest)


      range = []

      startr=0
      endr=filesize-1

      if !request.env['HTTP_RANGE'].nil?
        status 206
        range = request.env['HTTP_RANGE'].scan(/bytes=\h*(\d+)-(\d*)[\D.*]?/i)
        startr = range[0][0].to_i
        endr = range[0][1].to_i if range[0][1].present?
        response.headers["Content-Length"] = "#{((endr - startr) + 1)}"
        response.headers["Content-Range"] = "bytes #{startr}-#{endr}/#{filesize}"
      end


      response.headers["Content-Disposition"] = "inline; filename=foo.mp3"
      response.headers["Content-Transfer-Encoding"] = "binary"
      response.headers["Last-Modified"] = Time.new.rfc2822

      headers['Cache-Control'] = 'public, must-revalidate, max-age=0'
      headers['Pragma'] = 'no-cache'
      response.headers['Accept-Ranges'] = "bytes"
    elsif format == "ogg"
      content_type 'audio/ogg'
      response.headers["X-Content-Duration"] = "#{movie.duration}"
    end

    if !request.env['HTTP_RANGE'].nil? && format == "mp3"
      buffer = ""
      f = File.open(dest)
      f.seek(startr, IO::SEEK_SET)
      cur = startr
      while(!f.eof? && cur <= endr)
        readto = [(1024 * 16), ((endr - cur) + 1)].min
        buffer += f.read(readto)
        cur += readto
      end
    else
      buffer = File.read(dest)
    end

    buffer

  end

end