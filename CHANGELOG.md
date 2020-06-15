# Changelog

All notable changes to Predoc will be documented in this file. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.2] - 2020-06-15

### Changed
- Update to Rails 5.2.4.3
- Update dependencies to fix security vulnerabilities

## [1.1.1] - 2019-05-31

### Changed
- Allow app to be embedded outside of the domain

## [1.1] - 2019-05-22

NOTE: This release requires `SECRET_KEY_BASE` to be set in the production environment.

### Changed
- Update to Ruby 2.6.3 and Rails 5.2.3
- Update Docsplit gem to 0.7.6
- Change application status page format to `text/plain` (JSON still available)

## [1.0.8] - 2015-10-29

### Changed
- Add details to log message for unreadable error

## [1.0.7] - 2014-10-17

### Added
- Add hostname to JSON status

## [1.0.6] - 2014-07-16

### Changed
- Update Docsplit gem to 0.7.5

## [1.0.5] - 2014-04-17

### Added
- Add Capistrano gem for deployment

### Fixed
- Eliminate zombie (defunct) processes

## [1.0.4] - 2014-08-29

### Added
- Add StatsD to send document conversion events

## [1.0.3] - 2013-07-22

### Added
- Implement timeout for document conversion process

## [1.0.2] - 2013-07-04

### Added
- Add application status page

### Changed
- Change default logger to use SyslogLogger 2.0

## [1.0.1] - 2013-06-11

### Fixed
- Skip videos files in tests

## [1.0] - 2013-06-04

Initial release of Predoc!

[1.1.1]: https://github.com/sfu/predoc/releases/tag/v1.1.1
[1.1]: https://github.com/sfu/predoc/releases/tag/v1.1
[1.0.8]: https://github.com/sfu/predoc/releases/tag/v1.0.8
[1.0.7]: https://github.com/sfu/predoc/releases/tag/v1.0.7
[1.0.6]: https://github.com/sfu/predoc/releases/tag/v1.0.6
[1.0.5]: https://github.com/sfu/predoc/releases/tag/v1.0.5
[1.0.4]: https://github.com/sfu/predoc/releases/tag/v1.0.4
[1.0.3]: https://github.com/sfu/predoc/releases/tag/v1.0.3
[1.0.2]: https://github.com/sfu/predoc/releases/tag/v1.0.2
[1.0.1]: https://github.com/sfu/predoc/releases/tag/v1.0.1
[1.0]: https://github.com/sfu/predoc/releases/tag/v1.0
