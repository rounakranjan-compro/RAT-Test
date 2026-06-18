class CloudinaryUploadService
  def self.upload_file(path, folder: "artifacts")
    return nil unless path.present? && File.exist?(path)

    result = Cloudinary::Uploader.upload(
      path,
      folder: folder,
      resource_type: "auto"
    )

    result["secure_url"]
  rescue => e
    Rails.logger.error("Cloudinary upload failed: #{e.message}")
    nil
  end
end
