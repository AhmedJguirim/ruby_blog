class TagsController < ApplicationController
    def index
        @tags = Tag.all.pluck(:name)
        render json: @tags
      end
  end