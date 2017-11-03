[![Cover](https://raw.githubusercontent.com/coderdojo-japan/coderdojo.jp/master/public/cover.png)](https://coderdojo.jp/)

# CoderDojo Japan

[![Build Status](https://travis-ci.org/coderdojo-japan/coderdojo.jp.svg?branch=master)](https://travis-ci.org/coderdojo-japan/coderdojo.jp#)

Official website of CoderDojo Japan integrated with Rails-based CMS ([Scrivito](https://scrivito.com/))

- Moving from: [Parse](http://parse.com/) that __will be shutdown on January 28, 2017__
  - GitHub: https://github.com/coderdojo-japan/web
- Migrated to: [Heroku](http://heroku.com/) (must be switched before the shutdown)
  - GitHub: https://github.com/coderdojo-japan/coderdojo.jp

## How to contribute

Fulfill the requirements, setup by following the instructions, and send a pull request for anything you want to contribute.

### Requirements

- [Ruby](http://ruby-lang.org/)
- [Ruby on Rails](http://rubyonrails.org/)
- [Scrivito](https://scrivito.com/) (Option)

### Setup 

1. Fork and clone this repository.
1. `$ bundle install --without production`
1. `$ bundle exec rails db:migrate`
1. `$ bundle exec rails db:seed`
1. `$ bundle exec rails dojos:update_db_by_yaml`
1. `$ bundle exec rails dojo_event_services:upsert`
1. `$ bundle exec rails test`
1. `$ rails server`
1. Access to [localhost:3000](http://localhost:3000).

If you successfully set up, you can see the same page as [coderdojo.jp](http://coderdojo.jp).

### Scrivito

Some pages require [Scrivito](https://scrivito.com/), Professional Cloud-Based Rails CMS, such as:

- `/kata`
- `/docs/*`
- `/news/*`

CMS enables wider people to contribute to editing contents,   
but on the other hand, this requires Scrivito API Keys for    
engineers to join developing Scrivito-used pages like above.

If interested in developing them, contact [@yasulab](https://github.com/yasulab) to
get production keys (`SCRIVITO_TENANT` and `SCRIVITO_API_KEY`).


## Contributors

Initially designed by [@cognitom](https://github.com/cognitom) in 2015,   
being developed by [YassLab](https://yasslab.jp/) team since 2016, and   
had been migrated to [CoderDojo Japan](http://github.com/coderdojo-japan) organization in 2017.

[![YassLab Logo](https://yasslab.jp/img/logo_800x200.png)](https://yasslab.jp/)

## License

Although [Scrivito gem](https://rubygems.org/gems/scrivito) is publishd under LGPL-3.0, the author allows us to put MIT license. 😆✨

> Sorry for the late reply, I wanted to confer with our team.   
> There is no conflict in the licenses and you are welcome to use the MIT license.  

So, this application can be used and modified under the MIT License! 🆗

### The MIT License (MIT)

Copyright &copy; 2012-2017 [CoderDojo Japan](https://coderdojo.jp/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### About ICON

The icons used in the website are created by [Font Awesome](http://fontawesome.io/), licensed under SIL OFL 1.1.
