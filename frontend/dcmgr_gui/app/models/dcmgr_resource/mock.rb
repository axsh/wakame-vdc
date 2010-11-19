module DcmgrResource
  class Mock
    def self.load(load)
      root = File.expand_path('../')
      load = File::split(load)
      namespace = load[0]
      file = load[1] + '.json'
      dir = File.join(root,'common','data','mock',namespace)
      jsonfile = File.join(dir,file)
      json = ''
      open(jsonfile) {|f| json = f.read }
      json
    end
  end
end
