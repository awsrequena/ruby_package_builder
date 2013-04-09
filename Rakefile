require 'bundler/setup'
Bundler.require
STDOUT.sync = true
CREDENTIALS_FILE = File.dirname(__FILE__) + '/../../upload-assets-credentials.yml'
PKG_BUILDER_BUCKET = 'opsworks-package-builder-tools'

# we need GNU tar to avoid warning when extracting the content on linux systems
def tar
  _tar = `which tar`.chomp
  # we must use GNU tar
  begin
    if `#{_tar} --version`.include?('bsd')
      # probably on a Mac
      _tar = `which gnutar`.chomp
      if _tar.empty?
        raise e
      end
    end
    _tar
  rescue
    puts 'The GNU tar utility was not found in this system. Please install GNU tar before trying to run this task.'
  end
end

desc 'Upload Package Builder Cookbooks into S3 Bucket; ENV[ASSETS] can point to a file or a directory, DRY_RUN lists files that would be uploaded'
task :upload_package_builder_cookbooks do

  bucket = PKG_BUILDER_BUCKET

  FileUtils.mkdir_p "#{File.dirname(__FILE__)}/pkg"
  package = "#{File.dirname(__FILE__)}/pkg/package_builder_cookbooks.tar.gz"

  system("cd #{File.dirname(__FILE__)} && git ls-files | xargs #{tar} cfz #{package} --exclude='.git*' \
         --exclude 'vendor' \
         --exclude 'pkg' \
         --exclude 'Rakefile' \
         --exclude 'config' \
         --exclude 'Gemfile' \
         --exclude 'vendor'"
   )

  puts 'Uploading Package Builder Cookbooks to S3 Bucket !!!'
  s3.buckets.create(bucket)
  object = s3.buckets[bucket].objects["#{File.basename(package)}"]
  content = File.read(package)
  puts "!! uploading #{package}"
  # enforce uploading as one part to keep the etag simple, it will be the md5sum of the file
  object.write(content, :acl => :public_read, :multipart_threshold => content.length * 2) unless dry_run?
  puts "Finished uploading assets into #{bucket}"
end

def s3
  upload_config = YAML.load(File.read(CREDENTIALS_FILE))
  @s3 = AWS::S3.new(
    :access_key_id => upload_config[:access_key_id],
    :secret_access_key => upload_config[:secret_access_key]
  )
end

def dry_run?
  @dry_run ||= ENV['DRY_RUN'].to_i == 1
end
