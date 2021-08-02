# Ruby on Rails Server Fingerprinter

Identify Ruby on Rails version on remote deployments without source code access.

This code was created as a proof of concept for a talk I gave at RubyConf Brazil 2021 ("Exploring vulnerabilities on Rails apps").

If you are interested in server fingerprinting or pentesting in general, check the [awesome-pentest](https://github.com/enaqx/awesome-pentest) repository for more tools.

## How to use

Install the required Ruby version documented on `.ruby-version` and execute:

```bash
$ ruby fingerprinter.rb https://whatever.com

```

## Contributing
I have no intention to update or maintain this script as it was created as a proof of concept only.
Feel free to fork and modify it. No need for credits.