# The app never uses direct (browser -> storage) uploads, and the endpoint
# would let anyone with a CSRF token create blobs with a client-chosen
# content type and size. Uploads go through the validated Document model.
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.before_action { head :not_found }
end
