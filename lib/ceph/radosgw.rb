module CEPH
  class Radosgw

    attr_reader :username, :ipaddress, :user_password, :uid


    def initialize(options)
      raise ArgumentError, "Missing :username." if !options[:username]
      raise ArgumentError, "Missing :ipaddress." if !options[:ipaddress]
      raise ArgumentError, "Missing :user_password." if !options[:user_password]

      @username = options.fetch(:username)
      @ipaddress = options.fetch(:ipaddress)
      @user_password = options.fetch(:user_password)
    end



    def user_create(uid)
Net::SSH.start( @ipaddress, @username, :password => @user_password ) do|ssh| 
	ceph_user_json = ssh.exec!('sudo radosgw-admin user create --uid="#{uid}"  --display-name="radosgw demo user from s3 gem"')
end

    ceph_user_hash = JSON.parse(ceph_user_json)
    secret_hash = {"access_key" => "#{ceph_user_hash['keys'][0]['access_key']}", "secret_key" => "#{ceph_user_hash['keys'][0]['secret_key']}" }
    secret_hash
    end

  end
end
