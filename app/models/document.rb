class Document < ApplicationRecord
  belongs_to :documentable, polymorphic: true
  has_one_attached :file

  validates :file, presence: true
  validate :acceptable_image

  MAX_SIZE = 5.megabytes

  # The file name and the browser-sent Content-Type are chosen by the client,
  # so the type is decided from the first bytes of the upload instead.
  SIGNATURES = {
    "image/jpeg" => ["\xFF\xD8\xFF".b],
    "image/png"  => ["\x89PNG\r\n\x1A\n".b],
    "image/gif"  => ["GIF87a".b, "GIF89a".b]
  }.freeze

  private

  def acceptable_image
    # nothing to check unless a new file is being attached; stored ones were checked on the way in
    return unless attachment_changes["file"] && file.attached?

    io = uploaded_io
    unless io
      errors.add(:file, "could not be read")
      return
    end

    errors.add(:file, "is too big (should be at most 5MB)") if io.size > MAX_SIZE

    type = detect_type(io)
    if type.nil?
      errors.add(:file, "must be a JPEG, PNG, or GIF")
    else
      # store (and later serve) the verified type, not the declared one
      file.blob.content_type = type
    end
  end

  def uploaded_io
    attachable = attachment_changes["file"].attachable
    attachable = attachable[:io] if attachable.is_a?(Hash)
    attachable.respond_to?(:read) && attachable.respond_to?(:size) ? attachable : nil
  end

  def detect_type(io)
    return unless io.size.positive?

    io.rewind
    head = io.read(16).to_s.b
    io.rewind
    SIGNATURES.find { |_, prefixes| prefixes.any? { |p| head.start_with?(p) } }&.first
  end
end
