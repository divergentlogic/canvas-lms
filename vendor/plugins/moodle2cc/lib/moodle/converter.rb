module Moodle
  class Converter < Canvas::Migration::Migrator
    def initialize(settings)
      super(settings, "moodle")
    end

    # This is called by the worker to
    def export(to_export = Canvas::Migration::Migrator::SCRAPE_ALL_HASH)
      #unzip_archive
      migrator = Moodle2CC::Migrator.new @archive_file.path, @unzipped_file_path
      migrator.migrate

      @settings[:archive_file] = File.open(migrator.imscc_path)
      cc_converter = CC::Importer::Canvas::Converter.new(@settings)
      cc_converter.export
      @course = cc_converter.course # the @course needs to be the return value

    ensure
      FileUtils.rm migrator.imscc_path if File.exists?(migrator.imscc_path)
    end

  end
end
