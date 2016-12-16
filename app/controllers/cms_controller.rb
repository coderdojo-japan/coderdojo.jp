# -*- coding: utf-8 -*-
class CmsController < ApplicationController
  include Scrivito::ControllerActions

  Scrivito::Workspace.use(ENV["SCRIVITO_WORKSPACE"])
  LoginPage.create(title: 'ログイン')
end
