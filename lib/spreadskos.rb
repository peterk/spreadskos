# encoding: UTF-8

module Spreadskos
  require 'linkeddata'
  require 'roo'
  require 'logger'

  # Creates SKOS files from vocabulary data in a spreadsheet template.
  class Converter

    def initialize(filepath=nil)

      @log = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @log.info("init")

      @filepath = filepath
      @default_lang = :en

      @skos_objs = []
      setup_skos

      # start new SKOS doc output
      @graph = RDF::Graph.new

      # Load spreadsheet data
      @spreadsheet = nil
      load_spreadsheet(filepath)

      # set up vocab basic info
      @namespace = "http://example.com/your_namespace/"

      setup_vocab_info

      # Add concepts and related information
      @concepts = []
      add_concepts

    end



    # Load SKOS itself to be able to render labels etc later.
    def setup_skos

      #skosfile = File.dirname(__FILE__) + ::File::SEPARATOR + "skos.rdf"
      skosfile = File.expand_path("skos.rdf", File.dirname(__FILE__))
      @log.info("Load SKOS itself to be able to render labels etc later. File: " + skosfile)

      RDF::Reader.open(skosfile) do |reader|
        reader.each_statement do |statement|
          if statement.predicate == "http://www.w3.org/2000/01/rdf-schema#label" then
            @skos_objs << {:obj => statement.subject.to_s.sub("http://www.w3.org/2004/02/skos/core#",""), :label => statement.object.to_s.downcase.strip}

            @log.info("Adding #{statement.object.to_s.downcase.strip}, #{statement.subject.to_s}")
          end
        end
      end

    end



    def load_spreadsheet(filepath)

      @log.info("Loading #{filepath}")

      if filepath then
        @spreadsheet = Roo::Spreadsheet.open(filepath)
      else
        raise "Spreadsheet not found."
      end
    end



    def setup_vocab_info

      # Build concept scheme info from first sheet
      info_sheet = @spreadsheet.sheet(0)

      title = ""
      description = ""
      version = ""
      creators = ""
      contributors = ""

      1.upto(info_sheet.last_row) do |row_no|
        case info_sheet.cell(row_no, 1)
        when "Title:"
          title = info_sheet.cell(row_no, 2)
        when "Description:"
          description = info_sheet.cell(row_no, 2)
        when "Version:"
          version = info_sheet.cell(row_no, 2)
        when "Vocabulary identifier:"
          @namespace = info_sheet.cell(row_no, 2)
        when "Default language:"
          @default_lang = info_sheet.cell(row_no, 2).strip
        when "Creators:"
          creators = info_sheet.cell(row_no, 2).strip.split(",")
        when "Contributors:"
          contributors = info_sheet.cell(row_no, 2).strip.split(",")
        else
          @log.info("Unknown property: " + info_sheet.cell(row_no, 1))
        end
      end

      # Write it
      @graph << [RDF::URI.intern(@namespace), RDF.type, RDF::SKOS.ConceptScheme]
      @graph << [RDF::URI.intern(@namespace), RDF::RDFS.label, RDF::Literal.new(title, :language => @default_lang)]
      @graph << [RDF::URI.intern(@namespace), RDF::DC.description, RDF::Literal.new(description, :language => @default_lang)]

      add_creators(creators)

      add_contributors(contributors)

    end



    def add_creators(creators)
      @log.info("adding creators")

      creators.each do |creator|
        @graph << [RDF::URI.new(@namespace), RDF::DC.creator, RDF::Literal.new(creator.strip)]
      end
    end



    def add_contributors(contributors)
      @log.info("adding contributors")

      contributors.each do |contributor|
        @graph << [RDF::URI.new(@namespace), RDF::DC.contributor, RDF::Literal.new(contributor.strip)]
      end
    end


    def add_concepts

      @log.info("adding concepts")

      # Add concepts and labels from second worksheet
      concept_sheet = @spreadsheet.sheet(1)

      columns = []

      # Build column model
      1.upto(concept_sheet.last_column) do |col_no|
        @log.info("\tcol: " + concept_sheet.cell(1, col_no))
        columns << concept_sheet.cell(1, col_no)
      end


      # Iterate rows
      2.upto(concept_sheet.last_row) do |row_no|

        # Concepts fragments are in the first column
        concept_fragment_id = concept_sheet.cell(row_no, 1)

        if concept_fragment_id.size > 0 then

          concept = uri_for_concept_fragment(concept_fragment_id)
          @log.info("concept: " + concept)

          # Add concept to graph
          @graph << [concept, RDF.type, RDF::SKOS.Concept]

          # Connect it to the concept scheme
          add_concept_to_scheme(concept)

          #loop columns for concept
          2.upto(concept_sheet.last_column) do |col_no|

            # What property is this?
            property, lang = skosname_and_lang_from_column_head(columns[col_no - 1])
            @log.info("Prop+lang: #{property}, #{lang}")

            #Value
            value = concept_sheet.cell(row_no, col_no)
            @log.info("Val: #{value}")

            # literal?
            if value and value.strip.size > 0
              if value.start_with?("#") or value.start_with?("http")
                # Add this property to the graph
                add_property_to_graph(concept, property, value)
              else
                value = RDF::Literal.new(value, :language => lang)
                add_property_to_graph(concept, property, value)
              end
            end

          end
        end

      end

    end



    def add_property_to_graph(concept, property, value)
      @graph << [concept, property, value]
    end



    def add_concept_to_scheme(concept)
      @graph << [concept, RDF::SKOS.inScheme, @namespace]
    end




    def uri_for_concept_fragment(fragment)
      if fragment.downcase.start_with?("http") then
        # user edited their own concept identifier
        return RDF::URI.new(fragment)
      else
        # make local identifier
        return RDF::URI.new(@namespace + fragment)
      end
    end



    def skosname_and_lang_from_column_head(column)

      @log.info("\t Mapping column #{column}")

      # find skos property from column header text (e.g. "Preferred label (en)")
      label, lang = column.split("(")
      if lang then
        lang = lang.sub(")","").to_sym
      else
        # Default lang
        lang = @default_lang
      end

      skosprop = skos_from_label(label)

      @log.info("skosprop: #{skosprop}")

      return skosprop, lang
    end



    def skos_from_label(label)
      @log.info("Looking up >#{label.downcase.strip}<")

      prop = @skos_objs.select {|o| o[:label] == label.downcase.strip }

      @log.info(prop)

      return eval("RDF::SKOS." + prop[0][:obj])
    end


    def write_graph(filename="result.rdf", format=:rdfxml)

      File.open(filename, 'w:UTF-8') { |file|
        file.write(@graph.dump(format))
      }

    end

  end


end
