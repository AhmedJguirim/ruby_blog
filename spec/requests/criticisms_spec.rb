require 'rails_helper'

RSpec.describe "Criticisms", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/criticisms/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/criticisms/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
