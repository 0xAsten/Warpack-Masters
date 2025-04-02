# Warpack Masters Documentation

This directory contains the Jekyll-based documentation site for Warpack Masters.

## Local Development

To run this documentation site locally:

1. Make sure you have Ruby installed (version 2.7.0 or higher recommended)
2. Install Bundler if you don't have it: `gem install bundler`
3. Navigate to the `docs` directory
4. Run `bundle install` to install dependencies
5. Run `bundle exec jekyll serve` to start the local server
6. Visit `http://localhost:4000/Warpack-Masters/` in your browser

## Directory Structure

- `_config.yml`: Jekyll configuration
- `_layouts/`: Layout templates
- `_includes/`: Reusable components
- `assets/`: Static files (CSS, JS, images)
- `collections/`: Content organized by category
  - `tutorials/`: Step-by-step guides
  - `mechanics/`: Detailed game mechanics

## Adding Content

### Tutorials

To add a new tutorial:

1. Create a new Markdown file in `tutorials/`
2. Add front matter with title, description, and navigation links:
   ```yaml
   ---
   title: Your Tutorial Title
   description: Brief description of the tutorial
   prev_tutorial: previous-tutorial-file-name (without .md)
   next_tutorial: next-tutorial-file-name (without .md)
   order: 3  # Position in the tutorial sequence
   ---
   ```
3. Write your tutorial content in Markdown

### Game Mechanics

To add a new game mechanic:

1. Create a new Markdown file in `collections/mechanics/`
2. Add front matter:
   ```yaml
   ---
   title: Mechanic Name
   description: Brief description of the mechanic
   related_mechanics: [other-mechanic-names]
   ---
   ```
3. Write your mechanic documentation in Markdown

## Deployment

This documentation is automatically deployed to GitHub Pages when changes are pushed to the main branch.

## Contributing

Contributions to the documentation are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes
4. Submit a pull request

Please ensure your content is clear, concise, and follows the existing style conventions.