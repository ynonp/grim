module Grim
  class ImageMagickProcessor

    # ghostscript prints out a warning, this regex matches it
    WarningRegex = /\*\*\*\*.*\n/

    def initialize(options={})
      @imagemagick_path = options[:imagemagick_path] || 'convert'
      @ghostscript_path = options[:ghostscript_path]
      @original_path        = ENV['PATH']
    end

    def count(path)
      command = ["-dNODISPLAY", "-q",
                 "-sFile=#{Shellwords.shellescape(path)}",
                 File.expand_path('../../../lib/pdf_info.ps', __FILE__)]
      @ghostscript_path ? command.unshift(@ghostscript_path) : command.unshift('gs')
      result = `#{command.join(' ')}`
      result.gsub(WarningRegex, '').to_i
    end

    def save(pdf, index, path, options)
      command = _build_save_command(pdf, index, path, options)
      result = `#{command.join(' ')}`

      $? == 0 || raise(UnprocessablePage, result)
    end

    def _build_save_command(pdf, index, path, options)
      width   = options.fetch(:width,   Grim::WIDTH)
      density = options.fetch(:density, Grim::DENSITY)
      quality = options.fetch(:quality, Grim::QUALITY)
      colorspace = options.fetch(:colorspace, Grim::COLORSPACE)
      defines = options.fetch(:define, [])
      command = [@imagemagick_path, "-resize", width.to_s, "-antialias", "-render",
                 "-quality", quality.to_s, "-colorspace", colorspace,
                 "-interlace", "none", "-density", density.to_s,
                 *defines.map { |define| "-define #{define}" },
                 "#{Shellwords.shellescape(pdf.path)}[#{index}]", path]
      command.unshift("PATH=#{File.dirname(@ghostscript_path)}:#{ENV['PATH']}") if @ghostscript_path

      return command
    end

  end
end
