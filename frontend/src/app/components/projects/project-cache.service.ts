// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {MultiInputState} from 'reactivestates';
import {States} from '../states.service';
import {StateCacheService} from '../states/state-cache.service';
import {Injectable} from '@angular/core';
import {ProjectResource} from 'core-app/modules/hal/resources/project-resource';
import {ProjectDmService} from 'core-app/modules/hal/dm-services/project-dm.service';

@Injectable()
export class ProjectCacheService extends StateCacheService<ProjectResource> {

  constructor(readonly states:States,
              readonly projectDmService:ProjectDmService) {
    super();
  }

  protected loadAll(ids:string[]):Promise<undefined> {
    return Promise
      .all(ids.map(id => this.load(id)))
      .then(_ => undefined);
  }

  protected load(id:string):Promise<ProjectResource> {
    return this.projectDmService.one(parseInt(id));
  }

  protected get multiState():MultiInputState<ProjectResource> {
    return this.states.projects;
  }

}
