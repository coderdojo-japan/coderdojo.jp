# -*- coding: utf-8 -*-
class CmsController < ApplicationController
  include Scrivito::ControllerActions

  title ||= ENV['SCRIVITO_WORKSPACE'] || 'DEFAULT_WORKSPACE'
  Scrivito::Workspace.create(title: title) unless Scrivito::Workspace.find_by_title(title)
  Scrivito::Workspace.use(title)

  LoginPage.create(title: 'ログイン')
end
