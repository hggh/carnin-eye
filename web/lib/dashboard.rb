class Dashboard
  require 'dashboard/entry'
  require 'dashboard/graph'
  DBOARDS_PATH = 'dashboards/'
  attr_reader :dashboards

  def initialize
    @dashboards = Array.new
    Dir.entries(DBOARDS_PATH).each do |d|
      next if d =~ /^(\.|\.\.|.gitkeep|dash.yml|\.graph)$/
      board = File.join(DBOARDS_PATH, d)
      board_file = File.join(board, 'dash.yml')
      if File.exists?(board_file)
        yaml = YAML.load_file(board_file)
        entries = parse_entry(board)
        @dashboards << { :entries => entries, :entry => Dashboard::Entry.new(board) }
      end
    end
    @dashboards = @dashboards.sort! { |a,b| b[:entry].name <=> a[:entry].name }.reverse
  end

  private

  def parse_entry(entry)
    entries = Array.new
    Dir.entries(entry).each do |d|
      next if d =~ /^(\.|\.\.|.gitkeep|dash.yml)$/
      board = File.join(entry, d)
      board_file = File.join(board, 'dash.yml')
      if File.exists?(board_file)
        yaml = YAML.load_file(board_file)
        entries_sub = parse_entry(board)
        entries << { :entries => entries_sub, :entry => Dashboard::Entry.new(board) }
      end
    end
    return entries
  end

end
