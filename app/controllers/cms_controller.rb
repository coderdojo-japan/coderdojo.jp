class CmsController < ApplicationController
  include Scrivito::ControllerActions

  LoginPage.create(title: 'ログイン')
end
