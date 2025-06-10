# Ruby Blog

A feature-rich blogging platform built with Ruby on Rails that allows users to create articles, comment on them, and engage with a vibrant community. This application includes user authentication, tagging, voting, commenting, file attachments, and a RESTful API.

![Ruby Blog](https://via.placeholder.com/800x400?text=Ruby+Blog)

## Features

- 👤 **User Authentication** - Secure signup and login system using Devise
- 📝 **Article Management** - Create, read, update, and delete blog articles
- 💬 **Commenting System** - Users can comment on articles and engage in discussions
- 🔍 **Tagging** - Categorize articles with tags for better organization
- 👍 **Voting System** - Upvote or downvote articles and comments
- 📷 **File Attachments** - Upload and attach images to articles (limit of 3 images per article)
- 🧐 **Criticism Feature** - Provide feedback on comments
- 📱 **RESTful API** - JSON API endpoints for mobile app integration
- 📊 **Pagination** - Efficient browsing of articles with Kaminari
- 🎨 **Modern UI** - Clean interface designed with Tailwind CSS

## Tech Stack

- **Ruby version**: 2.7.5
- **Rails version**: 6.1.7
- **Database**: SQLite 1.4
- **Frontend**: Tailwind CSS, JavaScript, jQuery
- **Authentication**: Devise, Devise-JWT
- **Testing**: RSpec, FactoryBot

## Installation

### Prerequisites

- Ruby 2.7.5
- Rails 6.1.7+
- Node.js and Yarn for JavaScript dependencies

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ruby_blog.git
   cd ruby_blog
   ```

2. Install dependencies:
   ```bash
   bundle install
   yarn install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed  # To load sample data (optional)
   ```

4. Start the development server:
   ```bash
   bin/dev
   ```

5. Visit `http://localhost:3000` in your web browser

## API Endpoints

The application provides a RESTful API for integration with other services:

- **Authentication**
  - `POST /api/v1/login` - Login and get JWT token
  - `DELETE /api/v1/logout` - Logout and invalidate JWT token

- **Articles**
  - `GET /api/v1/articles` - Get all articles
  - `GET /api/v1/articles/:id` - Get a specific article
  - `POST /api/v1/articles` - Create a new article
  - `PUT /api/v1/articles/:id` - Update an article
  - `DELETE /api/v1/articles/:id` - Delete an article

- **Comments**
  - `GET /api/v1/comments` - Get all comments
  - `GET /api/v1/comments/articles/:article_id` - Get comments for a specific article
  - `POST /api/v1/comments` - Create a new comment

- **Criticisms**
  - `GET /api/v1/criticisms/:comment_id` - Get criticisms for a specific comment
  - `POST /api/v1/criticisms` - Create a new criticism
  - `DELETE /api/v1/criticisms/:id` - Delete a criticism

## Database Schema

The application includes the following models:
- User
- Article
- Comment
- Criticism
- Tag
- Vote
- Document
- ElaborationRequest

## Testing

Run the test suite with:

```bash
bundle exec rspec
```

## Deployment

This application can be deployed to Heroku or any other Rails-compatible hosting service.

### Heroku Deployment

```bash
heroku create
git push heroku main
heroku run rails db:migrate
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Ruby on Rails team for the amazing framework
- Devise team for the authentication solution
- All contributors who have helped shape this project

## Contact
For any questions or feedback, please open an issue on GitHub or contact the project maintainer at jguirimahmed111@gmail.com.