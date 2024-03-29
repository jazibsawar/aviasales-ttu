#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require File.expand_path('../../support/shared/become_member', __FILE__)

describe Project, type: :model do
  include BecomeMember

  let(:project) { FactoryBot.create(:project, is_public: false) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }

  describe Project::STATUS_ACTIVE do
    it 'equals 1' do
      # spec that STATUS_ACTIVE has the correct value
      expect(Project::STATUS_ACTIVE).to eq(1)
    end
  end

  describe '#active?' do
    it 'is active when :status equals STATUS_ACTIVE' do
      project = FactoryBot.build :project, status: :active
      expect(project).to be_active
    end

    it "is not active when :status doesn't equal STATUS_ACTIVE" do
      project = FactoryBot.build :project, status: :archived
      expect(project).not_to be_active
    end
  end

  context 'when the wiki module is enabled' do
    let(:project) { FactoryBot.create(:project, disable_modules: 'wiki') }

    before :each do
      project.enabled_module_names = project.enabled_module_names | ['wiki']
      project.save
      project.reload
    end

    it 'creates a wiki' do
      expect(project.wiki).to be_present
    end

    it 'creates a wiki menu item named like the default start page' do
      expect(project.wiki.wiki_menu_items).to be_one
      expect(project.wiki.wiki_menu_items.first.title).to eq(project.wiki.start_page)
    end
  end

  describe 'copy_allowed?' do
    let(:user) { FactoryBot.create(:user) }
    let(:role_add_subproject) { FactoryBot.create(:role, permissions: [:add_subprojects]) }
    let(:role_copy_projects) { FactoryBot.create(:role, permissions: [:edit_project, :copy_projects, :add_project]) }
    let(:parent_project) { FactoryBot.create(:project) }
    let(:project) { FactoryBot.create(:project, parent: parent_project) }
    let!(:subproject_member) do
      FactoryBot.create(:member,
                         user: user,
                         project: project,
                         roles: [role_copy_projects])
    end
    before do
      login_as(user)
    end

    context 'with permission to add subprojects' do
      let!(:member_add_subproject) do
        FactoryBot.create(:member,
                           user: user,
                           project: parent_project,
                           roles: [role_add_subproject])
      end

      it 'should allow copy' do
        expect(project.copy_allowed?).to eq(true)
      end
    end

    context 'with permission to add subprojects' do
      it 'should not allow copy' do
        expect(project.copy_allowed?).to eq(false)
      end
    end
  end

  describe 'available principles' do
    let(:user) { FactoryBot.create(:user) }
    let(:group) { FactoryBot.create(:group) }
    let(:role) { FactoryBot.create(:role) }
    let!(:user_member) do
      FactoryBot.create(:member,
                        principal: user,
                        project: project,
                        roles: [role])
    end
    let!(:group_member) do
      FactoryBot.create(:member,
                        principal: group,
                        project: project,
                        roles: [role])
    end

    shared_examples_for 'respecting group assignment settings' do
      context 'with group assignment' do
        before { allow(Setting).to receive(:work_package_group_assignment?).and_return(true) }

        it { is_expected.to match_array([user, group]) }
      end

      context 'w/o group assignment' do
        before { allow(Setting).to receive(:work_package_group_assignment?).and_return(false) }

        it { is_expected.to match_array([user]) }
      end
    end

    describe 'assignees' do
      subject { project.possible_assignees }

      it_behaves_like 'respecting group assignment settings'
    end

    describe 'responsibles' do
      subject { project.possible_responsibles }

      it_behaves_like 'respecting group assignment settings'
    end
  end

  describe '#types_used_by_work_packages' do
    let(:project) { FactoryBot.create(:project_with_types) }
    let(:type) { project.types.first }
    let(:other_type) { project.types.second }
    let(:project_work_package) { FactoryBot.create(:work_package, type: type, project: project) }
    let(:other_project) { FactoryBot.create(:project, no_types: true, types: [other_type, type]) }
    let(:other_project_work_package) { FactoryBot.create(:work_package, type: other_type, project: other_project) }

    it 'returns the type used by a work package of the project' do
      project_work_package
      other_project_work_package

      expect(project.types_used_by_work_packages).to match_array [project_work_package.type]
    end
  end

  describe '#allowed_parent?' do
    let(:project) { FactoryBot.build_stubbed(:project) }
    let(:other_project) { FactoryBot.build_stubbed(:project) }
    let(:another_project) { FactoryBot.build_stubbed(:project) }

    it 'is false for nil on a persisted project with no allowed parents' do
      allow(project)
        .to receive(:allowed_parents)
        .and_return([])

      expect(project.allowed_parent?(nil)).to be_falsey
    end

    it 'is true for nil on a persisted project with allowed parents' do
      allow(project)
        .to receive(:allowed_parents)
        .and_return(['something'])

      expect(project.allowed_parent?(nil)).to be_truthy
    end

    it 'is true for nil on an unpersisted project with no allowed parents' do
      project = FactoryBot.build(:project)

      allow(project)
        .to receive(:allowed_parents)
        .and_return([])

      expect(project.allowed_parent?(nil)).to be_truthy
    end

    it 'is false for blank on a persisted project with no allowed parents' do
      allow(project)
        .to receive(:allowed_parents)
        .and_return([])

      expect(project.allowed_parent?('')).to be_falsey
    end

    it 'is true for blank on a persisted project with allowed parents' do
      allow(project)
        .to receive(:allowed_parents)
        .and_return(['something'])

      expect(project.allowed_parent?('')).to be_truthy
    end

    it 'is true for blank on an unpersisted project with no allowed parents' do
      project = FactoryBot.build(:project)

      allow(project)
        .to receive(:allowed_parents)
        .and_return([])

      expect(project.allowed_parent?('')).to be_truthy
    end

    it 'is true for an id pointing to a project in allowed_parents' do
      allow(Project)
        .to receive(:find_by)
        .with(id: 1)
        .and_return(other_project)
      allow(project)
        .to receive(:allowed_parents)
        .and_return([other_project])

      expect(project.allowed_parent?(1)).to be_truthy
    end

    it 'is false for an id pointing to a project in allowed_parents' do
      allow(Project)
        .to receive(:find_by)
        .with(id: 1)
        .and_return(other_project)
      allow(project)
        .to receive(:allowed_parents)
        .and_return([another_project])

      expect(project.allowed_parent?(1)).to be_falsey
    end

    it 'is false for a non existing project id' do
      allow(Project)
        .to receive(:find_by)
        .with(id: 1)
        .and_return(nil)
      allow(project)
        .to receive(:allowed_parents)
        .and_return([other_project])

      expect(project.allowed_parent?(1)).to be_falsey
    end

    it 'is true for a project in allowed_projects' do
      allow(project)
        .to receive(:allowed_parents)
        .and_return([other_project])

      expect(project.allowed_parent?(other_project)).to be_truthy
    end

    it 'is false for a project not in allowed_projects' do
      allow(project)
        .to receive(:allowed_parents)
        .and_return([another_project])

      expect(project.allowed_parent?(other_project)).to be_falsey
    end
  end
end
