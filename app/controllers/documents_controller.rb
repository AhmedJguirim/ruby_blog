class DocumentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_documentable
  
    def create
      @document = @documentable.documents.build
      @document.file.attach(params[:file])
  
      if @document.save
        render json: { 
          success: true, 
          message: 'Image uploaded successfully', 
          file: { 
            filename: @document.file.filename,
            url: url_for(@document.file)
          } 
        }, status: :ok
      else
        render json: { success: false, errors: @document.errors.full_messages }, status: :unprocessable_entity
      end
    end
  
    def destroy
      @document = @documentable.documents.find(params[:id])
      @document.destroy
      redirect_back fallback_location: root_path, notice: 'Image was successfully deleted.'
    end
  
    private
  
    def set_documentable
      if params[:article_id]
        @documentable = Article.find(params[:article_id])
      elsif params[:comment_id]
        @documentable = Comment.find(params[:comment_id])
      else
        raise "Unsupported documentable type"
      end
    end
  end