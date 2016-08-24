# Uses hOCR to create a JSON word boundaries file.
class WordBoundariesCreator

  include DirectoryFileHelpers

  def initialize(id)
    @id = id
  end

  def create
    doc = File.open(final_hocr_filepath(@id)) { |f| Nokogiri::HTML(f) }
    json = {}
    doc.css('span.ocrx_word').each do |span|
      text = span.text
      # Filter out non-word characters
      word_match = text.match /\w+/
      next if word_match.nil?
      word = word_match[0]
      next if word.length < 3
      json[word] ||= []
      title = span['title']
      info = parse_hocr_title(title)
      json[word] << info
    end
    File.open(final_json_file_filepath(@id), 'w') do |fh|
      fh.puts json.to_json
    end
  end

  def hocr_exists?
    hocr_already_exists?(@id)
  end

  def json_exists?
    json_already_exists?(@id)
  end

  private

  def parse_hocr_title(title)
    parts = title.split(';').map(&:strip)
    info = {}
    parts.each do |part|
      sections = part.split(' ')
      sections.shift
      if /^bbox/.match(part)
        x0, y0, x1, y1 = sections
        info['x0'], info['y0'], info['x1'], info['y1'] = [x0.to_i, y0.to_i, x1.to_i, y1.to_i]
      elsif /^x_wconf/.match(part)
        c = sections.first
        info['c'] = c.to_i
      end
    end
    info
  end

end
