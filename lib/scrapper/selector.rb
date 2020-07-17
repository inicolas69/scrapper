# frozen_string_literal: true

class Scrapper::Selector
  attr_reader :parent_selector, :id
  attr_accessor :children

  def initialize(json, domain)
    @id              = json['id']
    @type            = json['type']
    @parent_selector = json['parentSelectors'].first
    @selector_css    = json['selector']
    @delay = json['delay']
    @multiple = json['multiple']
    @domain = domain
  end

  def data(element)
    @matches = element.css(@selector_css)
    @multiple ? data_multiple : data_simple
  end

  def data_multiple
    @matches.map do |m|
      @children.map { |c| [c.id, c.data(m)] }.to_h
    end
  end

  def data_simple
    @match = @matches.first

    case @type
    when 'SelectorText' then @match.text
    when 'SelectorLink' then selector_link_value
    else
      "error #{@type}"
    end
  end

  def self.from_json(json, domain)
    new(json, domain)
  end

  private

  def selector_link_value
    url = @match[:href].start_with?('/') ? "#{@domain}#{@match[:href]}" : @match[:href]
    return url if @children.empty?

    doc = Nokogiri::HTML(URI.open(url))
    @children.map { |c| [c.id, c.data(doc)] }.to_h
  end
end
