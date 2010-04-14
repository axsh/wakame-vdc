
require 'uri'
require 'fileutils'

class Wakame::Actor::Deploy
  include Wakame::Actor

  # Download the application from repo_uri using arbitrary SCM tool.
  def checkout(ticket, repo_type, repo_uri, deploy_rev, app_root, app_name, options={})
    
    case repo_type
    when 's3'
      tmp_dest = checkout_s3(repo_uri, deploy_rev, options)
    when 'curl'
      tmp_dest = checkout_curl(repo_uri, deploy_rev, options)
    else
      raise "Unsupported repository type: #{repo_type}"
    end

    dest = File.expand_path(File.join(app_name, ticket), app_root)
    
    begin
      FileUtils.mkpath(File.dirname(dest))
      Wakame.log.debug("FileUtils.move('#{tmp_dest}', '#{dest}')")
      FileUtils.move(tmp_dest, dest)

      FileUtils.rm_f(File.join(File.dirname(dest), 'latest'))
      FileUtils.symlink(File.basename(dest), File.join(File.dirname(dest), 'latest'))
    rescue
      FileUtils.rm_r(dest) rescue nil
    end
  end

  # Swap the symlink "current" in /app_root/app_name to point the location as same as
  # "latest" in the same folder.
  def swap_current_link(app_root, app_name)
    raise "Invalid application root path. Must be an absolute path: #{app_root}" unless app_root =~ /\A\//

    latest_lnk_path = File.join(app_root, app_name, 'latest')
    cur_lnk_path = File.join(app_root, app_name, 'current')
    raise "'latest' symlink does not exist in #{File.join(app_root, app_name)}" unless File.symlink?(latest_lnk_path)
    

    tgt = File.readlink(latest_lnk_path)
    raise "'latest' symlink may point the target in differnt folder: #{tgt}" if tgt =~ /[\/]/

    if File.symlink?(cur_lnk_path)
      FileUtils.rm_f(cur_lnk_path)
    end
    FileUtils.symlink(tgt, cur_lnk_path)
  end

  private

  def checkout_s3(repo_uri, deploy_rev, options)
    require 'right_aws'
    s3 = RightAws::S3Interface.new(options[:aws_access_key], options[:aws_secret_key])

    bucket = nil
    begin
      u = URI.parse(repo_uri)
      if u.host =~ /\A(.+)\.s3.amazonaws.com\Z/
        bucket = $1
        key = u.path.sub(/\A\//, '')
      else
        bucket, key = u.path.sub(/\A\//, '').split(/\//, 2)
      end

      key = key.nil? ? deploy_rev.dup : (key + deploy_rev)

    rescue URI::InvalidURIError
      # Assume that repo_uri has "bucket/key" syntax.
      bucket, key = repo_uri.sub(/\A\//, '').split(/\//, 2)
      key = key.nil? ? deploy_rev.dup : (key + deploy_rev)
    end

    tmp_dest = File.expand_path(File.basename(key), '/var/tmp')
    dest = File.join(File.dirname(tmp_dest), 'aaa')
    begin
      Wakame.log.debug("Fetching archive from: s3.get: #{bucket}/#{key}")
      tmp_f  = File.new(tmp_dest, "w")
      s3.get(bucket, key) { |buf|
        tmp_f.write(buf)
      }
      tmp_f.close

      Wakame::Util.exec('/usr/bin/unzip \'%s\' -d \'%s\'' % [tmp_dest, dest])
      return dest
    ensure 
      File.unlink(tmp_dest) rescue nil
    end

  end

  def checkout_curl(repo_uri, deploy_rev, options)
    src_uri = URI.parse(repo_uri + deploy_rev)
    tmp_dest = File.expand_path(File.basename(src_uri.path), '/var/tmp')
    dest = File.join(File.dirname(tmp_dest), 'aaa')

    begin 
      Wakame::Util.exec('/usr/bin/curl -o \'%s\' \'%s\'' % [tmp_dest, src_uri])
      raise "" unless File.exists?(tmp_dest)
      Wakame::Util.exec('/usr/bin/unzip \'%s\' -d \'%s\'' % [tmp_dest, dest])
      return dest
    ensure
      File.unlink(tmp_dest) rescue nil
    end
  end

end
