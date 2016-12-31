[![Cover](https://raw.githubusercontent.com/yasslab/coderdojo.jp/master/public/cover.png)](http://coderdojo.jp/)

# CoderDojo Japan

[![Build Status](https://travis-ci.org/yasslab/coderdojo.jp.svg?branch=master)](https://travis-ci.org/yasslab/coderdojo.jp#)

Official website of CoderDojo Japan integrated with Rails-based CMS ([Scrivito](https://scrivito.com/))

- Moving from: [Parse](http://parse.com/) that __will be shutdown on January 28, 2017__
  - GitHub: https://github.com/coderdojo-japan/web
- Migrated to: [Heroku](http://heroku.com/) (must be switched before the shutdown)
  - GitHub: https://github.com/yasslab/coderdojo.jp

## How to contribute

### Requirements

- [Ruby](http://ruby-lang.org/)
- [Ruby on Rails](http://rubyonrails.org/)
- [Scrivito](https://scrivito.com/)'s secret keys (ask @yasulab)

### Setup 

1. Fork and clone this repository.
2. Set Scrivito's secret keys to `SCRIVITO_TENANT` and `SCRIVITO_API_KEY`
3. `$ bundle install --without production`
4. `$ bundle exec rake db:migrate`
5. `$ bundle exec rake dojos:update_db_by_yaml`
6. `$ bundle exec rake test`
7. `$ rails server`
8. Access to [localhost:3000](http://localhost:3000).

If you successfully set up, you can see the same page as [coderdojo.jp](http://coderdojo.jp).

## Contributors

Initially designed by [@cognitom](https://github.com/cognitom) in 2015,   
replaced/developed by [YassLab](http://yasslab.jp/) team in 2016, and   
will be migrated to [CoderDojo Japan](http://github.com/coderdojo-japan) organization in 2017.

## License

Although [Scrivito gem](https://rubygems.org/gems/scrivito) is publishd under LGPL-3.0, the author allows us to put MIT license. 😆✨

> Sorry for the late reply, I wanted to confer with our team.   
> There is no conflict in the licenses and you are welcome to use the MIT license.  

So, this application can be used and modified under the MIT License! 🆗

### The MIT License (MIT)

Copyright &copy; 2016 [YassLab](http://yasslab.jp/)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

