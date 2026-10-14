class DocumentsController < ApplicationController
    before_action :set_documentable
    before_action :ensure_owner

    def create
      unless params[:file].respond_to?(:tempfile)
        return render json: { success: false, errors: ['No file given'] }, status: :unprocessable_entity
      end
      if document_slots_full?
        return render json: { success: false, errors: ['Too many images'] }, status: :unprocessable_entity
      end

      @document = Document.new(documentable: @documentable)
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
      @document = Document.where(documentable: @documentable).find(params[:id])
      @document.destroy
      redirect_back fallback_location: root_path, notice: 'Image was successfully deleted.', allow_other_host: false
    end

    private

    def set_documentable
      if params[:comment_id]
        @documentable = Comment.find(params[:comment_id])
      elsif params[:article_id]
        @documentable = Article.find(params[:article_id])
      else
        raise "Unsupported documentable type"
      end
    end

    def ensure_owner
      head :forbidden unless @documentable.user_id == current_user.id
    end

    def document_slots_full?
      if @documentable.is_a?(Article)
        @documentable.documents.count >= 3
      else
        @documentable.document.present?
      end
    end
  end
