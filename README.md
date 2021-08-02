# Ruby on Rails Server Fingerprinter

Identify Ruby on Rails version on remote deployments without source code access.

This code was created as a proof of concept for a talk I gave at RubyConf Brazil 2021 ("Exploring vulnerabilities on Rails apps").

If you are interested in server fingerprinting or pentesting in general, check the [awesome-pentest](https://github.com/enaqx/awesome-pentest) repository for more tools.

## How to use

Install the required Ruby version documented on `.ruby-version` and execute on your terminal:

```bash
$ ruby fingerprinter.rb https://x.y.z

```

You'll get a list of checks and (hopefully) a list of predicted versions:

```
Asset pipeline JS with 32 chars  ❌
Asset pipeline CSS with 32 chars ❌
Asset pipeline JS with 64 chars  ✅ [">=5.1"]
Asset pipeline CSS with 64 chars ✅ [">=5.1"]
CSRF meta tag                    ✅ [">=3.0.20"]
Default session cookie name      ✅ [">0.0.0"]
404 error page v1                ❌
404 error page v2                ❌
404 error page v3                ✅ [">=4.1.0", "<5.2.0"]
404 error page v4                ❌
Phusion Passenger                ❌
Rails logo                       ❌

Retrieving cache (392 releases)
Predicted Rails versions (10 releases):
5.1.0, 5.1.1, 5.1.2, 5.1.3, 5.1.4, 5.1.5, 5.1.6, 5.1.6.1, 5.1.6.2, 5.1.7
```

Ruby on Rails version list is downloaded from [RubyGems API](https://guides.rubygems.org/rubygems-org-api/). Rate limiting or breaking changes may occur. A cache will be stored on `versions.tmp` file. Delete the file to refresh the list.

## About

This script was created by [Wagner Narde](https://github.com/wagner).

I have no intention to update or maintain this script as it was created only as a proof of concept.
Feel free to fork and modify it. No need for credits.