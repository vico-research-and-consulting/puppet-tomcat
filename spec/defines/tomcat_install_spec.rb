# spec/classes/tomcat_spec.pp

require 'spec_helper'

describe 'tomcat::install', :type => :define do

  let(:title) { 'test_default' }
  let :pre_condition do
      'include tomcat'
  end

  context "All mandatory parameters specified" do
    let :params do
      {
        :source => 'testtomcatsource.tar.gz',
        :downloadurl  => 'http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/tomcat/tomcat-8/v8.0.23/bin/apache-tomcat-8.0.23.tar.gz',
        :adminuser => 'foobar',
        :adminpassword => 'foobar',
        :mysql_jndi => 'jdbc/foobar',
        :mysql_username => 'foobar',
        :mysql_password => 'foobar',
        :mysql_jdbcurl => 'jdbc:mysql://127.0.0.1:3306/foobar',
      }
    end
    it {
      should contain_class('tomcat')
      should contain_file('/usr/local/src/working-tomcat-test_default/testtomcatsource.tar.gz').with( { 
        'mode' => '0644'
      } )
    }
  end


end
