class Document < ApplicationRecord
  # files are stored privately and we only get an url of it, but if you wanna set it 
  # to public check https://edgeguides.rubyonrails.org/active_storage_overview.html#public-access
  belongs_to :documentable, polymorphic: true
  has_one_attached :file

  validates :file, presence: true
  validate :acceptable_image

  private

  def acceptable_image
    # return if no files attached
    return unless file.attached?

    unless file.blob.byte_size <= 5.megabyte
      errors.add(:file, "is too big (should be at most 5MB)")
    end

    acceptable_types = ["image/jpeg", "image/png", "image/gif"]
    unless acceptable_types.include?(file.content_type)
      errors.add(:file, "must be a JPEG, PNG, or GIF")
    end
  end
end