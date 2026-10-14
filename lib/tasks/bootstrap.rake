namespace :app do
  desc "Create the first user from ADMIN_EMAIL / ADMIN_PASSWORD / ADMIN_USERNAME (no-op if unset or it exists)"
  task create_first_user: :environment do
    email = ENV["ADMIN_EMAIL"].to_s.strip.downcase
    password = ENV["ADMIN_PASSWORD"].to_s
    next puts("ADMIN_EMAIL/ADMIN_PASSWORD not set: no user created") if email.empty? || password.empty?
    next puts("User #{email} already exists") if User.exists?(email: email)

    user = User.new(email: email, password: password, username: ENV.fetch("ADMIN_USERNAME", "admin"))
    if user.save
      puts "Created user #{email}"
    else
      abort "Could not create user: #{user.errors.full_messages.to_sentence}"
    end
  end
end
