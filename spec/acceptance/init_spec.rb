require "spec_helper_acceptance"

def test_class(classname)
  describe classname do
    it "include #{classname} should work" do
      pp = <<-EOS
        # Other modules depend on puppet-enterprise on the master.  We can't 
        # just include it in our roles/profiles as this would cause a conflict
        # with the parameterised class in the NC
        class { "puppet_enterprise":
          certificate_authority_host    => "pe-puppet.localdomain",
          console_host                  => "pe-puppet.localdomain",
          puppet_master_host            => "pe-puppet.localdomain",
          puppetdb_host                 => "pe-puppet.localdomain",
          database_host                 => "pe-puppet.localdomain",
          mcollective_middleware_hosts  => [ "pe-puppet.localdomain" ],
        }

        #class { "puppet_enterprise::profile::master": }

        # the test itself
        include #{classname}
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
  end
end

def classnames(dir)
  classnames = []
  Dir.glob("#{dir}/manifests/**/*.pp") do |manifest|
    if manifest =~ /manifests\/init\.pp/
      # name of module
      classname = File.basename(dir)
    else
      # name of file
      classname = File.basename(dir) + manifest.gsub("#{dir}/manifests", "").gsub("/", "::").gsub("\.pp","")
    end
    classnames.push(classname)
  end
  return classnames
end

# test all roles - remember this scan is done on THIS computer not the beaker instance!
role_classes = classnames("site/role")
if role_classes then
  role_classes.each do |role_class|
    test_class(role_class)
  end
end

profile_classes = classnames("site/profile")
if profile_classes then
  profile_classes.each do |profile_class|
    test_class(profile_class)
  end
end

