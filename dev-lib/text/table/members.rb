#!/usr/bin/ruby
# encoding: utf-8

module Text
class Table
class Member
  include Utils
  include Enumerable
  
  class << self
    attr_reader :member_name
    def define( member_name, sup = self, &body )
      klass = Class.new( sup ) do
        @member_name = member_name
        class_eval( &body )
      end
      
      define_method( "#{ member_name }!" ) do |*args|
        klass.new( @table, *args ) { |m| link(m) }.tail
      end
      return( klass )
    end
  end
  
  attr_reader :table
  attr_accessor :before, :after
  protected :before, :after
  
  def initialize( table, *args )
    @table = table
    @before = before
    @after = nil
    @disabled = false
    block_given? and yield( self )
    initialize!( *args )
  end
  
  def initialize!( * )
    # do nothing
  end
  
  def inspect( *args )
    content = args.map! { |a| a.inspect }.join(', ')
    "#{self.class.member_name}(#{content})"
  end
  
  def each
    block_given? or return( enum_for( __method__ ) )
    node = self
    begin
      yield( node )
      node = node.after
    end while( node )
  end
  
  def disable
    @disabled = true
  end
  
  def enable
    @disabled = false
  end
  
  def enabled?
    not disabled?
  end
  
  def disabled?
    @disabled
  end
  
  def first?
    @before.nil?
  end
  
  def last?
    @after.nil?
  end
  
  def link( item )
    after, @after, item.before = @after, item, self
    after ? item.link( after ) : item
  end
  
  def unlink
    @before and @before.after = nil
    @before = nil
    return( self )
  end
  
  def render( out )
    render!( out ) unless disabled?
  end
  
  def columns
    table.columns
  end
  
  def tail
    @after ? @after.tail : self
  end
end

Row = Member.define( 'row' ) do
  def initialize!( *content )
    @cells = [ content ].flatten!.map! { | c | c.to_s }
    table.expand_columns( @cells.length )
  end
  
  def []( index )
    @cells[ index ]
  end
  
  def []=(index, value)
    @cells[ index ] = value
  end
  
  def cells
    pad
    @table.columns.zip( @cells ).
      map! { | col, cell | col.prepare( cell ) }
  end
  
  def height
    cells.map! { | c | block_height( c ) }.max
  end
  
  def render!( out, type = :row )
    left_edge = @table.left_edge[ type ].to_s
    sides = @table.columns.map { | t | t.right_side[ type ].to_s }
    
    for line_cells in prepare.transpose
      out.print( left_edge )
      line_cells.zip( sides ) do | line_cell, side |
        out.print( line_cell )
        out.print( side )
      end
      out.puts( '' )
    end
    return out
  end
  


  def inspect
    super( *cells )
  end
private
  
  def prepare
    cell_lines = cells.map! { | cell | cell.split( $/, -1 ) }
    height = cell_lines.map { | lines | lines.length }.max
    if height > 1
      cell_lines.zip( @table.columns ) do | lines, col |
        if lines.length < height
          blank = col.fill_text( ' ' )
          lines.fill( blank, lines.length, height - lines.length )
        end
      end
    end
    return( cell_lines )
  end
  
  def pad
    n = @table.columns.length
    m = @cells.length
    if n > m
      @cells.fill( ' ', m, n - m )
    end
  end
  
end

TitleRow = Member.define( 'title_row', Row ) do
  def initialize!( *content )
    super
    divider!( :title_divider )
  end
  
  def render!( out )
    super( out, :title_row )
  end
end

Divider = Member.define( 'divider' ) do
  attr_accessor :type
  
  def initialize!( type )
    @type = type.to_sym
  end
  
  def render( out )
    super( out ) unless @after.is_a?( Divider )
  end
  
  def inspect( *args )
    super( @type, *args )
  end
  
  def render!( out )
    for c in columns
      out.print( c.left_side[ @type ] )
      out.print( c.fill_text( @type ) )
    end
    out.puts( @table.right_edge[ @type ] )
  end
end

SectionTitle = Member.define( 'section', Divider ) do
  attr_accessor :title, :alignment
  
  def initialize!( title, options = {} )
    @title = title.to_s
    @alignment = options.fetch( :align, :left )
  end
  
  def inspect
    super( @title, @alignment )
  end
  
  def render!( out )
    out.puts simulate( :foot )
    
    out.print( @table.left_edge[ :row ] )
    out.print( align( @title, @alignment, @table.inner_width ) )
    out.puts( @table.right_edge[ :row ] )
    
    out.puts simulate( :head )
  end
  
private
  
  def simulate( section )
    temp = StringIO.new
    Divider.new( @table, section ).render( temp )
    div = temp.string.chomp!
    a = @table.left_edge[ section ].length
    z = @table.right_edge[ section ].length
    
    div[  0, a ] = table.left_edge[ :row_divider ].to_s
    div[ -z, z ] = table.right_edge[ :row_divider ].to_s
    
    return( div )
  end
  
  
end

end
end
