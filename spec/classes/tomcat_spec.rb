# spec/classes/tomcat_spec.pp

require 'spec_helper'

describe 'tomcat' do

  it 'includes stdlib' do
    should contain_class('stdlib')
  end

  it { should contain_class('tomcat').with({'source' => 'UNSET'}) }

  describe "with defaults" do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/init.d/tomcat').with({'mode' => '0755'}) }
    it { is_expected.not_to contain_user('boing') }
    it { is_expected.not_to contain_group('doing') }
  end

  describe "manage user and group" do
     let(:params) {{ 
      :user => 'boing',
      :group => 'doing',
      :manage_usergroup => true,
      :deploymentdir => '/home/gnarf',
      :uid => '500',
      :gid => '500',
     }}
     it { is_expected.to contain_user('boing').with({'ensure' => 'present'}).with({'require' => 'Group[boing]'}) }
     it { is_expected.to contain_group('doing').with({'ensure' => 'present'}) }
  end

end

