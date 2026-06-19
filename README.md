# Symfony Weather Project

This repository contains a minimal Symfony project skeleton that fetches the weather for Grenoble.

## Structure

- `composer.json` defines project dependencies.
- `public/index.php` is the entry point.
- `src/` contains PHP source code including the default controller and kernel.
- `config/` stores basic service and route configuration files.
- `var/` is used for cache and logs (tracked with `.gitkeep`).

The application displays the current weather in Grenoble when visiting the root URL (`/`).

To install dependencies when you have internet access, run:

```bash
composer install
```

Then you can start the Symfony development server with:

```bash
php -S localhost:8000 -t public
```
