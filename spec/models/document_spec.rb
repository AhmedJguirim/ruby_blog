require 'rails_helper'

RSpec.describe Document, type: :model do
  PNG = "\x89PNG\r\n\x1A\n".b + ("\0".b * 32)

  def upload(content, name:, type:)
    io = StringIO.new(content)
    { io: io, filename: name, content_type: type }
  end

  def build_document(attachable)
    document = Document.new(documentable: create(:article))
    document.file.attach(attachable)
    document
  end

  it "accepts a real PNG and stores the verified type" do
    document = build_document(upload(PNG, name: "a.png", type: "image/png"))
    expect(document).to be_valid
    expect(document.file.blob.content_type).to eq("image/png")
  end

  it "decides by content, not by the declared type or the name" do
    document = build_document(upload(PNG, name: "a.html", type: "text/html"))
    expect(document).to be_valid
    expect(document.file.blob.content_type).to eq("image/png")
  end

  [
    ["PHP renamed to .jpg", "<?php system($_GET['c']); ?>", "evil.jpg", "image/jpeg"],
    ["HTML renamed to .jpg", "<html><script>alert(1)</script></html>", "evil.jpg", "image/jpeg"],
    ["SVG with script named .png", "<svg xmlns='http://www.w3.org/2000/svg' onload='alert(1)'/>", "x.png", "image/png"],
    ["an empty file", "", "empty.png", "image/png"]
  ].each do |label, content, name, type|
    it "rejects #{label}" do
      document = build_document(upload(content, name: name, type: type))
      expect(document).not_to be_valid
      expect(document.errors[:file]).to include("must be a JPEG, PNG, or GIF").or include("can't be blank")
    end
  end

  it "rejects files over 5 MB" do
    document = build_document(upload(PNG + ("\0".b * 5.megabytes), name: "big.png", type: "image/png"))
    expect(document).not_to be_valid
    expect(document.errors[:file].join).to include("too big")
  end
end
