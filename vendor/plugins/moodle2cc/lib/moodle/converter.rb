module Moodle
  class Converter < Canvas::Migration::Migrator
    def initialize(settings)
      super(settings, "moodle")
    end

    # This is called by the worker to
    def export(to_export = Canvas::Migration::Migrator::SCRAPE_ALL_HASH)
      #You can completely ignore to_export

      #todo convert the uploaded .zip file from a moodle file to a canvas-cc file
      # there is a reference to the .zip file: @archive_file
      # or you can:
      #unzip_archive
      moodle_backup = Moodle2CC::Moodle::Backup.parse @archive_file
      converter = Moodle2CC::CC::CanvasConverter.new moodle_backup, export_dir
      converter.convert

      # and use @unzipped_file_path as a reference to the package unzipped
      # This all happens in the parent class Canvas::Migration::Migrator


      #todo now that you have a canvas-cc formatted .zip file...
      # It may be as simple as:
      # If not we'll think about it some more later. :)
      @settings[:archive_file] = converter.converted_file
      cc_converter = CC::Importer::Canvas::Converter.new(@settings)
      cc_converter.export
      @course = cc_converter.course # the @course needs to be the return value

    ensure
      # cleanup of processing files...
    end

  end
end
