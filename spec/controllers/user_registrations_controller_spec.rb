# frozen_string_literal: true

require 'spec_helper'

describe UserRegistrationsController, type: :controller do
  include OpenFoodNetwork::EmailHelper

  before(:all) do
    setup_email
  end

  before do
    @request.env["devise.mapping"] = Devise.mappings[:spree_user]
  end

  describe "via ajax" do
    render_views

    let(:user_params) do
      {
        email: "test@test.com",
        password: "testy123",
        password_confirmation: "testy123"
      }
    end
    
    let(:user_params_too_short) do
      {
        email: "test@test.com",
        password: "123",
        password_confirmation: "123"
      }
    end
    
    let(:user_params_empty) do
      {
        email: "test@test.com",
        password: "123",
        password_confirmation: ""
      }
    end

    it "returns validation errors" do
      post :create, xhr: true, params: { spree_user: {}, use_route: :spree }
      expect(response.status).to eq(401)
      json = JSON.parse(response.body)
      expect(json).to eq("email" => ["can't be blank"], "password" => ["can't be blank"])
    end
    
    it "returns is too short errors" do
      post :create, xhr: true, params: { spree_user: user_params_too_short, use_route: :spree }
      expect(response.status).to eq(401)
      json = JSON.parse(response.body)
      expect(json).to eq("password" => ["is too short (minimum is 6 characters)"])
    end
      
    it "returns does not match errors" do
      post :create, xhr: true, params: { spree_user: user_param_empty, use_route: :spree }
      expect(response.status).to eq(401)
      json = JSON.parse(response.body)
      expect(json).to eq("password" => ["doesn't match"])
    end

    it "returns error when emailing fails" do
      allow(Spree::UserMailer).to receive(:confirmation_instructions).and_raise("Some error")
      expect(OpenFoodNetwork::ErrorLogger).to receive(:notify)

      post :create, xhr: true, params: { spree_user: user_params, use_route: :spree }

      expect(response.status).to eq(401)
      json = JSON.parse(response.body)
      expect(json).to eq("message" => I18n.t('devise.user_registrations.spree_user.unknown_error'))
    end

    it "returns 200 when registration succeeds" do
      post :create, xhr: true, params: { spree_user: user_params, use_route: :spree }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json).to eq("email" => "test@test.com")
      expect(controller.spree_current_user).to be_nil
    end

    it "sets user.locale from cookie on create" do
      original_i18n_locale = I18n.locale
      original_locale_cookie = cookies[:locale]

      cookies[:locale] = "pt"
      post :create, xhr: true, params: { spree_user: user_params, use_route: :spree }
      expect(assigns[:user].locale).to eq("pt")

      I18n.locale = original_i18n_locale
      cookies[:locale] = original_locale_cookie
    end
  end
end
