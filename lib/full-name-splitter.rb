# -*- coding: utf-8 -*-
# requires full accessable first_name and last_name attributes
module FullNameSplitter

  PREFIXES = %w(de da la du del dei vda. dello della degli delle van von der den heer ten ter vande vanden vander voor ver aan mc mac ben ibn bint al).freeze
  HONORIFICS = %w(mr mrs miss ms dr capt ofc rev prof sir cr hon).freeze

  attr_accessor :full_name_splitter_options
  def full_name_splitter_options
    @full_name_splitter_options ||= {
      :honorific  => :honorific,
      :first_name => :first_name,
      :last_name  => :last_name
    }
  end

  class Splitter
    
    def initialize(full_name)
      @full_name  = full_name
      @honorific = []
      @first_name = []
      @last_name  = []
      split!
    end

    def split!
      @units = @full_name.split(/\s+/)
      while @unit = @units.shift do
        if honorific?
          @honorific << @unit
        elsif prefix? or with_apostrophe? or (first_name? and last_unit? and not initial?) or (has_honorific? and last_unit? and not first_name?)
          @last_name << @unit and break
        else
          @first_name << @unit
        end
      end
      @last_name += @units

      adjust_exceptions!
    end

    def honorific
      @honorific.empty? ? nil : @honorific[0].gsub(/[^\w]/, '')
    end

    def first_name
      @first_name.empty? ? nil : @first_name.join(' ')
    end

    def last_name
      @last_name.empty? ? nil : @last_name.join(' ')
    end

    private

    def honorific?
      HONORIFICS.include?(@unit.downcase.gsub(/[^\w]/, '')) && @honorific.empty? && @first_name.empty? && @last_name.empty?
    end

    def has_honorific?
      not @honorific.empty?
    end

    def prefix?
      PREFIXES.include?(@unit.downcase)
    end

    # M or W.
    def initial?
      @unit =~ /^\w\.?$/
    end

    # O'Connor, d'Artagnan match
    # Noda' doesn't match
    def with_apostrophe?
      @unit =~ /\w{1}'\w+/
    end
    
    def last_unit?
      @units.empty?
    end
    
    def first_name?
      not @first_name.empty?
    end
    
    def adjust_exceptions!
      return if @first_name.size <= 1
      
      # Adjusting exceptions like 
      # "Ludwig Mies van der Rohe"      => ["Ludwig",         "Mies van der Rohe"   ]
      # "Juan Martín de la Cruz Gómez"  => ["Juan Martín",    "de la Cruz Gómez"    ]
      # "Javier Reyes de la Barrera"    => ["Javier",         "Reyes de la Barrera" ]
      # Rosa María Pérez Martínez Vda. de la Cruz 
      #                                 => ["Rosa María",     "Pérez Martínez Vda. de la Cruz"]
      if last_name =~ /^(van der|(vda\. )?de la \w+$)/i
        loop do
          @last_name.unshift @first_name.pop
          break if @first_name.size <= 2
        end
      end
    end
  end
  
  def full_name
    o = full_name_splitter_options
    ["#{__send__ o[:honorific]}.", __send__(o[:first_name]), __send__(o[:last_name])].compact.join(' ')
  end
  
  def full_name=(name)
    o = full_name_splitter_options
    parts = split name
    __send__ "#{o[:honorific]}=",  parts[0]
    __send__ "#{o[:first_name]}=", parts[1]
    __send__ "#{o[:last_name]}=",  parts[2]
  end
  
  private 
  
  def split(name)
    name = name.to_s.strip.gsub(/\s+/, ' ')
    
    if name.include?(',')
      name.
        split(/\s*,\s*/, 2).            # ",van  helsing" produces  ["", "van helsing"]
        map{ |u| u.empty? ? nil : u }   # but it should be [nil, "van helsing"] by lib convection
    else
      splitter = Splitter.new(name)
      [splitter.honorific, splitter.first_name, splitter.last_name]
    end
  end
  
  module_function :split
end
